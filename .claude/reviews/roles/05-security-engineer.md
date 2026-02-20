# Security Engineer Review

## Role Context
- **Perspective:** Security engineer auditing for vulnerabilities
- **Expertise:** iOS security, data protection, secure coding
- **Scope:** All code handling sensitive data, network, storage
- **Output:** `.claude/reviews/outputs/05-security-engineer-report.md`

## Instructions

Use extended thinking. Review code for security vulnerabilities and compliance with iOS security best practices. Focus on data handling, storage, and transmission.

### Methodology
1. Identify all sensitive data flows
2. Audit data storage mechanisms
3. Review network communication
4. Check authentication/authorization
5. Document findings progressively

### Review Order

**Section 1: Data Classification**
Identify what sensitive data the app handles.
Write initial assessment.

**Section 2: Data Storage**
Review how data is stored locally.
Write findings.

**Section 3: Network Security**
Review network communication.
Write findings.

**Section 4: Authentication**
Review authentication mechanisms (if applicable).
Write findings.

**Section 5: Third-Party Dependencies**
Review security of third-party code.
Write findings.

## What to Look For

### Data Storage (Category: Storage)
- [ ] Sensitive data encrypted at rest
- [ ] Keychain used for credentials/tokens
- [ ] UserDefaults not used for sensitive data
- [ ] File protection enabled for sensitive files
- [ ] No hardcoded secrets
- [ ] No sensitive data in logs
- [ ] Cache cleared for sensitive data

### Network Security (Category: Network)
- [ ] HTTPS used exclusively
- [ ] Certificate pinning (if applicable)
- [ ] No sensitive data in URL parameters
- [ ] Proper timeout handling
- [ ] No hardcoded API keys
- [ ] Request/response validation

### Authentication (Category: Auth)
- [ ] Secure token storage
- [ ] Token refresh handling
- [ ] Session timeout
- [ ] Biometric authentication (if applicable)
- [ ] Sign out clears sensitive data

### Input Validation (Category: Input)
- [ ] All user input validated
- [ ] No SQL injection risks (Core Data)
- [ ] No code injection risks
- [ ] Proper encoding/escaping
- [ ] File upload validation

### Privacy (Category: Privacy)
- [ ] Only necessary permissions requested
- [ ] Permission purpose strings accurate
- [ ] User consent obtained appropriately
- [ ] Data minimization practiced
- [ ] Privacy policy compliance

### Code Security (Category: Code)
- [ ] No debug code in production
- [ ] No test credentials
- [ ] Proper error handling (no info leakage)
- [ ] Secure random number generation
- [ ] No deprecated crypto APIs

## Output Format

### Finding Example
```markdown
## Finding SE-001: Sensitive Data in UserDefaults

- **Severity:** High
- **Category:** Storage
- **File:** `Services/AuthManager.swift`
- **Line(s):** 45
- **Description:** Access token stored in UserDefaults instead of Keychain
- **Risk:** Token accessible to other apps via backup, jailbreak
- **Recommendation:** Use Keychain for token storage

### Code Reference
```swift
// Current (insecure)
UserDefaults.standard.set(token, forKey: "accessToken")

// Recommended (secure)
try KeychainService.shared.save(token, forKey: "accessToken")
```

### References
- [iOS Security Guide](https://support.apple.com/guide/security/)
- OWASP Mobile Top 10: M2 - Insecure Data Storage
```

## Integration

### Related Commands
- `/appstore-audit` - App Store compliance

### Related Checklists
- `.claude/checklists/appstore.md`

## Final Report Structure

```markdown
# Security Engineer Review Report

**Project:** HealthAppTransfer
**Review Date:** [Date]
**Reviewer Role:** Security Engineer

## Executive Summary
[Overall security posture]

## Data Flow Diagram
[Sensitive data flows]

## Findings by Category

### Data Storage
[Findings]

### Network Security
[Findings]

### Authentication
[Findings]

### Input Validation
[Findings]

### Privacy
[Findings]

### Code Security
[Findings]

## Risk Matrix
| Finding | Severity | Likelihood | Impact |
|---------|----------|------------|--------|

## Recommendations
[Prioritized security improvements]
```
