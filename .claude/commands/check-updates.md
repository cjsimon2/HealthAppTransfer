# Check Updates - Project Dependency & Library Checker

Check for updates to this project's dependencies and libraries using AI-assisted analysis.

## Usage

```
/check-updates
/check-updates security    # Focus on security updates only
/check-updates major       # Show only major version changes
```

## What This Checks

### Package Dependencies
- Compares installed versions against latest available
- Identifies security vulnerabilities
- Highlights breaking changes in major updates

### Library Documentation
- Uses Context7 to fetch current documentation
- Identifies new patterns or best practices
- Flags deprecated APIs still in use

### Framework Updates
- Checks for framework version updates (React, FastAPI, etc.)
- Links to migration guides when available
- Notes new features that could improve the codebase

## Steps

1. **Read Package Manifest**
   - Identify package manager (npm, pip, cargo, go, etc.)
   - Parse `package.json`, `requirements.txt`, `pyproject.toml`, `Cargo.toml`, or `go.mod`
   - List all dependencies with current versions

2. **For Each Major Dependency**
   Use Context7 to check:
   - Latest version vs installed version
   - Breaking changes in recent releases
   - Migration guides if major version behind
   - New best practices or patterns

3. **Check for Security Advisories**
   - Search for known vulnerabilities
   - Note CVE identifiers when available
   - Prioritize security patches

4. **Generate Update Report**
   Create a report with sections:
   - 🔴 Security patches (apply immediately)
   - 🟡 Breaking changes (review needed)
   - 🟢 Minor updates (safe to apply)
   - 📚 New patterns/practices to consider

5. **Update Project Files**
   - Save report to `.claude/updates/YYYY-MM-DD.md`
   - Update LEARNINGS.md with any new best practices discovered

## Output Format

```markdown
# Project Update Report - [Date]

## Summary
- Dependencies checked: N
- Updates available: N
- Security issues: N

## 🔴 Security (Action Required)

### [package-name] X.Y.Z → A.B.C
- **CVE:** CVE-XXXX-XXXXX
- **Severity:** Critical/High/Medium/Low
- **Action:** `[command to update]`

## 🟡 Breaking Changes (Review Needed)

### [package-name] X.Y.Z → A.B.C
- **Changes:** Brief description of breaking changes
- **Migration:** Link to migration guide if available
- **Affected files:** List of files that may need updates
- **Action:** Review migration guide before updating

## 🟢 Minor Updates (Safe)

### [package-name] X.Y.Z → A.B.C
- **Changes:** New features or bug fixes
- **Action:** `[command to update]`

## 📚 New Patterns to Consider

### [Pattern Name]
- **Source:** Documentation or best practice guide
- **Benefit:** Why this pattern is recommended
- **Apply to:** Files or modules that could benefit

## Commands to Run

```bash
# Apply all safe updates
[appropriate package manager commands]

# Apply security updates only
[security-focused commands]
```
```

## Package Manager Commands

For reference, common update commands:

| Manager | List Outdated | Update All | Update Single |
|---------|---------------|------------|---------------|
| npm | `npm outdated` | `npm update` | `npm update [pkg]` |
| pip | `pip list --outdated` | `pip install --upgrade -r requirements.txt` | `pip install --upgrade [pkg]` |
| cargo | `cargo outdated` | `cargo update` | `cargo update -p [pkg]` |
| go | `go list -m -u all` | `go get -u ./...` | `go get -u [pkg]` |

## Context7 Usage

When checking documentation, use Context7 like this:

1. First resolve the library ID:
   ```
   resolve-library-id: { libraryName: "react", query: "react hooks migration" }
   ```

2. Then query for specific information:
   ```
   query-docs: { libraryId: "/facebook/react", query: "migration from React 18 to 19 breaking changes" }
   ```

## Notes

- Run this periodically (weekly recommended)
- Always review breaking changes before applying
- Back up your work before major updates
- Test thoroughly after any updates
