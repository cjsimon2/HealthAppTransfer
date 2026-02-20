import CryptoKit
import Foundation
import Security

// MARK: - Certificate Service

/// Generates and manages self-signed P-256 TLS certificates stored in Keychain.
actor CertificateService {

    private let keychain: KeychainStore

    private static let privateKeyTag = "com.caseysimon.HealthAppTransfer.tls.privateKey"
    private static let certificateLabel = "com.caseysimon.HealthAppTransfer.tls.certificate"

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    // MARK: - Public API

    /// Returns an existing TLS identity or generates a new one.
    /// The identity contains the private key and certificate needed for NWListener TLS.
    func getOrCreateIdentity() async throws -> SecIdentity {
        // Try to load existing identity
        if let identity = try await loadIdentity() {
            Loggers.security.info("Loaded existing TLS identity from Keychain")
            return identity
        }

        // Generate new key pair and certificate
        Loggers.security.info("Generating new TLS identity")
        return try await generateAndStoreIdentity()
    }

    /// Force-regenerate the TLS identity.
    func regenerateIdentity() async throws -> SecIdentity {
        try await cleanup()
        return try await generateAndStoreIdentity()
    }

    /// Remove all stored TLS materials.
    func cleanup() async throws {
        try await keychain.deleteKey(tag: Self.privateKeyTag)
        try await keychain.deleteCertificate(label: Self.certificateLabel)
        Loggers.security.info("Cleaned up TLS identity from Keychain")
    }

    // MARK: - Identity Generation

    private func generateAndStoreIdentity() async throws -> SecIdentity {
        // Generate P-256 key pair using CryptoKit
        let privateKey = P256.Signing.PrivateKey()

        // Convert to SecKey for Keychain storage
        let secPrivateKey = try secKeyFromP256(privateKey)

        // Build self-signed X.509 certificate
        let certDER = try buildSelfSignedCertificate(privateKey: privateKey)

        // Store in Keychain
        try await keychain.saveKey(secPrivateKey, tag: Self.privateKeyTag)
        try await keychain.saveCertificate(certDER, label: Self.certificateLabel)

        // Retrieve the identity (private key + certificate)
        guard let identity = try await loadIdentity() else {
            throw CertificateError.identityCreationFailed
        }

        Loggers.security.info("Generated and stored new TLS identity")
        return identity
    }

    // MARK: - Certificate Building

    private func buildSelfSignedCertificate(privateKey: P256.Signing.PrivateKey) throws -> Data {
        let now = Date()
        let oneYear: TimeInterval = 365 * 24 * 60 * 60
        let expiry = now.addingTimeInterval(oneYear)

        // Get the uncompressed public key point (04 || x || y)
        let publicKeyRaw = privateKey.publicKey.x963Representation

        let issuer = DEREncoder.x500Name(
            commonName: "HealthAppTransfer",
            organization: "HealthAppTransfer"
        )

        let validity = DEREncoder.validity(notBefore: now, notAfter: expiry)

        let publicKeyInfo = DEREncoder.ecPublicKeyInfo(
            uncompressedPoint: Array(publicKeyRaw)
        )

        let serialNumber = Int.random(in: 1...Int(Int32.max))

        let tbsCert = DEREncoder.tbsCertificate(
            serialNumber: serialNumber,
            issuer: issuer,
            validity: validity,
            subject: issuer, // Self-signed: subject == issuer
            publicKeyInfo: publicKeyInfo
        )

        // Sign the TBSCertificate
        let tbsData = Data(tbsCert)
        let signature = try privateKey.signature(for: tbsData)
        let signatureBytes = Array(signature.derRepresentation)

        // Build final certificate: SEQUENCE { tbsCert, signatureAlgorithm, signatureValue }
        let signatureAlgorithm = DEREncoder.ecdsaSHA256AlgorithmIdentifier()
        let signatureBitString = DEREncoder.bitString(signatureBytes)

        let certificate = DEREncoder.sequence(tbsCert + signatureAlgorithm + signatureBitString)

        return Data(certificate)
    }

    // MARK: - SecKey Conversion

    private func secKeyFromP256(_ privateKey: P256.Signing.PrivateKey) throws -> SecKey {
        let keyData = privateKey.x963Representation

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 256
        ]

        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            let cfError = error?.takeRetainedValue()
            throw CertificateError.keyConversionFailed(cfError as Error?)
        }

        return secKey
    }

    // MARK: - Identity Loading

    private func loadIdentity() async throws -> SecIdentity? {
        // Check if certificate exists
        guard try await keychain.loadCertificate(label: Self.certificateLabel) != nil else {
            return nil
        }

        // Check if private key exists
        guard try await keychain.loadKey(tag: Self.privateKeyTag) != nil else {
            return nil
        }

        // Use SecIdentityCreateWithCertificate (macOS) or query-based approach
        let query: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            return nil
        }

        return (result as! SecIdentity) // swiftlint:disable:this force_cast
    }
}

// MARK: - Certificate Error

enum CertificateError: LocalizedError {
    case identityCreationFailed
    case keyConversionFailed(Error?)
    case certificateCreationFailed

    var errorDescription: String? {
        switch self {
        case .identityCreationFailed:
            return "Failed to create TLS identity from stored key and certificate"
        case .keyConversionFailed(let error):
            return "Failed to convert P-256 key to SecKey: \(error?.localizedDescription ?? "unknown")"
        case .certificateCreationFailed:
            return "Failed to create self-signed certificate"
        }
    }
}
