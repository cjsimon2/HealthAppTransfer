# App Store Reviewer

## Role Context
- **Perspective:** App Store review team evaluating submission
- **Expertise:** App Store Review Guidelines, common rejection reasons
- **Scope:** Entire app from submission perspective
- **Output:** `.claude/reviews/outputs/08-appstore-reviewer-report.md`

## Instructions

Use extended thinking. Review the app as if you were an App Store reviewer. Look for guideline violations that would cause rejection.

### Methodology
1. Check for common rejection reasons
2. Verify required functionality
3. Review privacy compliance
4. Check metadata requirements
5. Document findings progressively

### Review Order

**Section 1: Safety (Guideline 1)**
Review for objectionable content, user safety.
Write findings.

**Section 2: Performance (Guideline 2)**
Review app completeness, bugs, metadata.
Write findings.

**Section 3: Business (Guideline 3)**
Review payments, subscriptions, ads.
Write findings.

**Section 4: Design (Guideline 4)**
Review UI/UX, Apple design guidelines.
Write findings.

**Section 5: Legal (Guideline 5)**
Review privacy, data collection, legal compliance.
Write findings.

## What to Look For

### Completeness (Guideline 2.1)
- [ ] No placeholder content
- [ ] No "beta", "demo", "test" labels
- [ ] All features functional
- [ ] No broken links
- [ ] No debug output visible

### Crashes & Bugs (Guideline 2.1)
- [ ] App doesn't crash
- [ ] No obvious bugs in main flows
- [ ] Handles errors gracefully
- [ ] Works offline where appropriate

### Metadata (Guideline 2.3)
- [ ] Screenshots show actual app
- [ ] Description matches functionality
- [ ] Keywords appropriate
- [ ] No misleading claims

### Privacy (Guideline 5.1)
- [ ] Privacy policy link works
- [ ] Data collection disclosed
- [ ] Permission strings accurate
- [ ] Account deletion available (if accounts exist)
- [ ] Tracking transparency (if tracking)

### Payments (Guideline 3.1)
- [ ] IAP for digital goods/services
- [ ] Restore purchases available
- [ ] Subscription terms clear
- [ ] No external payment links for digital goods

### Sign In (Guideline 4.8)
- [ ] Sign In with Apple offered (if other social login)
- [ ] Guest mode available (if possible)
- [ ] Account optional for core features (where appropriate)

### Design (Guideline 4)
- [ ] Uses standard iOS UI patterns
- [ ] No fake system dialogs
- [ ] Respects Human Interface Guidelines
- [ ] Proper use of iOS features

### Legal (Guideline 5)
- [ ] No private API usage
- [ ] Complies with applicable laws
- [ ] User data handled appropriately
- [ ] No trademark infringement

## Output Format

### Finding Example
```markdown
## Finding AS-001: Missing Privacy Policy

- **Severity:** Rejection Risk
- **Guideline:** 5.1.1 - Data Collection and Storage
- **Description:** App collects user data but no privacy policy URL in Info.plist
- **Impact:** App will be rejected during review
- **Required Action:** Add privacy policy URL to Info.plist and App Store Connect

### Guideline Reference
> Apps that collect user or usage data must have a privacy policy and secure user consent for the collection.

### Resolution Steps
1. Create privacy policy document
2. Host at accessible URL
3. Add to Info.plist
4. Add to App Store Connect metadata
```

## Integration

### Related Commands
- `/appstore-audit` - App Store compliance check

### Related Checklists
- `.claude/checklists/appstore.md`

## Final Report Structure

```markdown
# App Store Reviewer Report

**Project:** HealthAppTransfer
**Review Date:** [Date]
**Reviewer Role:** App Store Reviewer

## Submission Readiness
| Category | Status | Blocking Issues |
|----------|--------|-----------------|
| Safety | | |
| Performance | | |
| Business | | |
| Design | | |
| Legal | | |

## Findings by Guideline

### 1. Safety
[Findings]

### 2. Performance
[Findings]

### 3. Business
[Findings]

### 4. Design
[Findings]

### 5. Legal
[Findings]

## Rejection Risks
| Issue | Guideline | Severity | Resolution |
|-------|-----------|----------|------------|

## Pre-Submission Checklist
- [ ] All rejection risks addressed
- [ ] Privacy policy URL valid
- [ ] Screenshots current
- [ ] Demo account provided (if needed)
- [ ] Review notes written

## Recommendation
[ ] Ready for submission
[ ] Address blocking issues first
[ ] Major revision needed
```
