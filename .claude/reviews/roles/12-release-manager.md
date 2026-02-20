# Release Manager Review

## Role Context
- **Perspective:** Release manager preparing for deployment
- **Expertise:** Release processes, versioning, distribution
- **Scope:** Build configuration, versioning, release readiness
- **Output:** `.claude/reviews/outputs/12-release-manager-report.md`

## Instructions

Use extended thinking. Review the project for release readiness. Check versioning, build configuration, and deployment setup.

### Methodology
1. Review version management
2. Check build configuration
3. Audit signing and provisioning
4. Review release processes
5. Document findings progressively

### Review Order

**Section 1: Versioning**
Review version numbering and changelog.
Write findings.

**Section 2: Build Configuration**
Review Xcode project settings.
Write findings.

**Section 3: Signing & Provisioning**
Review code signing setup.
Write findings.

**Section 4: Dependencies**
Review third-party dependency management.
Write findings.

**Section 5: CI/CD**
Review automation and pipelines.
Write findings.

## What to Look For

### Versioning (Category: Versioning)
- [ ] Version follows semantic versioning
- [ ] Build number incremented
- [ ] Changelog maintained
- [ ] Git tags for releases
- [ ] Version displayed in app

### Build Configuration (Category: Build)
- [ ] Debug/Release schemes correct
- [ ] Optimization settings appropriate
- [ ] No debug code in release
- [ ] Proper archive configuration
- [ ] Asset catalogs complete

### Signing (Category: Signing)
- [ ] Correct certificates used
- [ ] Provisioning profiles valid
- [ ] Capabilities match entitlements
- [ ] App ID correct
- [ ] Team selected appropriately

### Dependencies (Category: Dependencies)
- [ ] All dependencies up to date
- [ ] No security vulnerabilities
- [ ] Licenses compatible
- [ ] Package resolution stable
- [ ] No deprecated packages

### CI/CD (Category: Automation)
- [ ] Build automation configured
- [ ] Tests run on PR
- [ ] Code signing in CI
- [ ] Distribution automated
- [ ] Environment secrets secure

## Output Format

### Finding Example
```markdown
## Finding RM-001: Outdated Dependency

- **Severity:** Medium
- **Category:** Dependencies
- **Package:** Alamofire
- **Current:** 5.6.0
- **Latest:** 5.8.1
- **Issue:** 3 patch versions behind, includes security fixes
- **Recommendation:** Update to latest stable version

### Update Steps
1. Update Package.swift or Podfile
2. Run dependency resolution
3. Test main network flows
4. Verify no breaking changes
```

## Integration

### Related Checklists
- `.claude/checklists/release.md`
- `.claude/checklists/appstore.md`

## Final Report Structure

```markdown
# Release Manager Review Report

**Project:** HealthAppTransfer
**Review Date:** [Date]
**Reviewer Role:** Release Manager

## Release Readiness
| Category | Status |
|----------|--------|
| Versioning | |
| Build Config | |
| Signing | |
| Dependencies | |
| CI/CD | |

## Version Information
- Current Version: X.Y.Z
- Build Number: ###
- Last Release: [Date]

## Findings by Category

### Versioning
[Findings]

### Build Configuration
[Findings]

### Signing & Provisioning
[Findings]

### Dependencies
[Findings]

### CI/CD
[Findings]

## Dependency Audit
| Package | Current | Latest | Status |
|---------|---------|--------|--------|

## Pre-Release Checklist
- [ ] Version bumped
- [ ] Changelog updated
- [ ] Dependencies current
- [ ] Tests passing
- [ ] Archive builds successfully
- [ ] TestFlight tested

## Recommendations
[Prioritized release improvements]
```
