import Foundation

// MARK: - DER/ASN.1 Encoder for X.509 Certificate Construction

enum DEREncoder {

    // MARK: - ASN.1 Tag Constants

    private enum Tag: UInt8 {
        case integer = 0x02
        case bitString = 0x03
        case octetString = 0x04
        case null = 0x05
        case objectIdentifier = 0x06
        case utf8String = 0x0C
        case printableString = 0x13
        case utcTime = 0x17
        case sequence = 0x30
        case set = 0x31
        // Context-specific constructed
        case contextConstructed0 = 0xA0
        case contextConstructed3 = 0xA3
    }

    // MARK: - OID Constants

    /// P-256 curve OID: 1.2.840.10045.3.1.7
    static let oidPrime256v1: [UInt8] = [0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07]

    /// ecPublicKey OID: 1.2.840.10045.2.1
    static let oidEcPublicKey: [UInt8] = [0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01]

    /// ECDSA with SHA-256 OID: 1.2.840.10045.4.3.2
    static let oidEcdsaWithSHA256: [UInt8] = [0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x04, 0x03, 0x02]

    /// commonName OID: 2.5.4.3
    static let oidCommonName: [UInt8] = [0x06, 0x03, 0x55, 0x04, 0x03]

    /// organizationName OID: 2.5.4.10
    static let oidOrganizationName: [UInt8] = [0x06, 0x03, 0x55, 0x04, 0x0A]

    /// basicConstraints OID: 2.5.29.19
    static let oidBasicConstraints: [UInt8] = [0x06, 0x03, 0x55, 0x1D, 0x13]

    /// subjectKeyIdentifier OID: 2.5.29.14
    static let oidSubjectKeyIdentifier: [UInt8] = [0x06, 0x03, 0x55, 0x1D, 0x0E]

    // MARK: - Primitive Encoding

    /// Encode a DER length field.
    static func encodeLength(_ length: Int) -> [UInt8] {
        if length < 0x80 {
            return [UInt8(length)]
        } else if length <= 0xFF {
            return [0x81, UInt8(length)]
        } else {
            return [0x82, UInt8((length >> 8) & 0xFF), UInt8(length & 0xFF)]
        }
    }

    /// Wrap payload bytes in a DER TLV with the given tag.
    static func wrapTLV(tag: UInt8, _ payload: [UInt8]) -> [UInt8] {
        [tag] + encodeLength(payload.count) + payload
    }

    /// DER SEQUENCE
    static func sequence(_ contents: [UInt8]) -> [UInt8] {
        wrapTLV(tag: Tag.sequence.rawValue, contents)
    }

    /// DER SET
    static func set(_ contents: [UInt8]) -> [UInt8] {
        wrapTLV(tag: Tag.set.rawValue, contents)
    }

    /// DER INTEGER (unsigned, strips leading zeros but keeps sign byte).
    static func integer(_ value: [UInt8]) -> [UInt8] {
        var bytes = value
        // Strip leading zeros but keep at least one byte
        while bytes.count > 1 && bytes.first == 0x00 {
            bytes.removeFirst()
        }
        // Add leading 0x00 if high bit set (positive integer)
        if let first = bytes.first, first & 0x80 != 0 {
            bytes.insert(0x00, at: 0)
        }
        return wrapTLV(tag: Tag.integer.rawValue, bytes)
    }

    /// DER INTEGER from a Swift Int.
    static func integer(_ value: Int) -> [UInt8] {
        var result: [UInt8] = []
        var v = value
        repeat {
            result.insert(UInt8(v & 0xFF), at: 0)
            v >>= 8
        } while v > 0
        // Add leading 0x00 if high bit set
        if let first = result.first, first & 0x80 != 0 {
            result.insert(0x00, at: 0)
        }
        return wrapTLV(tag: Tag.integer.rawValue, result)
    }

    /// DER BIT STRING (prepends unused-bits byte = 0x00).
    static func bitString(_ bytes: [UInt8]) -> [UInt8] {
        wrapTLV(tag: Tag.bitString.rawValue, [0x00] + bytes)
    }

    /// DER OCTET STRING.
    static func octetString(_ bytes: [UInt8]) -> [UInt8] {
        wrapTLV(tag: Tag.octetString.rawValue, bytes)
    }

    /// DER UTF8String.
    static func utf8String(_ string: String) -> [UInt8] {
        wrapTLV(tag: Tag.utf8String.rawValue, Array(string.utf8))
    }

    /// DER PrintableString.
    static func printableString(_ string: String) -> [UInt8] {
        wrapTLV(tag: Tag.printableString.rawValue, Array(string.utf8))
    }

    /// DER UTCTime (format: YYMMDDHHMMSSZ).
    static func utcTime(_ date: Date) -> [UInt8] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMddHHmmss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let s = formatter.string(from: date) + "Z"
        return wrapTLV(tag: Tag.utcTime.rawValue, Array(s.utf8))
    }

    /// DER NULL.
    static func null() -> [UInt8] {
        [Tag.null.rawValue, 0x00]
    }

    /// Context-specific constructed wrapper (e.g. [0] EXPLICIT).
    static func contextConstructed(_ tagNumber: UInt8, _ contents: [UInt8]) -> [UInt8] {
        wrapTLV(tag: 0xA0 | tagNumber, contents)
    }

    // MARK: - X.509 Helpers

    /// Build an X.500 Name with CN and O fields.
    static func x500Name(commonName: String, organization: String) -> [UInt8] {
        let cnAttr = set(sequence(oidCommonName + utf8String(commonName)))
        let orgAttr = set(sequence(oidOrganizationName + utf8String(organization)))
        return sequence(cnAttr + orgAttr)
    }

    /// Build the AlgorithmIdentifier for ECDSA with SHA-256.
    static func ecdsaSHA256AlgorithmIdentifier() -> [UInt8] {
        sequence(oidEcdsaWithSHA256)
    }

    /// Build SubjectPublicKeyInfo for an EC P-256 uncompressed public key.
    static func ecPublicKeyInfo(uncompressedPoint: [UInt8]) -> [UInt8] {
        let algorithm = sequence(oidEcPublicKey + oidPrime256v1)
        return sequence(algorithm + bitString(uncompressedPoint))
    }

    /// Build Validity period.
    static func validity(notBefore: Date, notAfter: Date) -> [UInt8] {
        sequence(utcTime(notBefore) + utcTime(notAfter))
    }

    /// Build the TBSCertificate structure.
    static func tbsCertificate(
        serialNumber: Int,
        issuer: [UInt8],
        validity validityBytes: [UInt8],
        subject: [UInt8],
        publicKeyInfo: [UInt8]
    ) -> [UInt8] {
        let version = contextConstructed(0, integer(2)) // v3
        let serial = integer(serialNumber)
        let signatureAlgo = ecdsaSHA256AlgorithmIdentifier()

        return sequence(
            version + serial + signatureAlgo + issuer + validityBytes + subject + publicKeyInfo
        )
    }
}
