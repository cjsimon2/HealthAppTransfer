Can't write to LEARNINGS.md (no write permission granted for this session). Two insights worth recording next time:

- **No shared Xcode schemes** — `xcshareddata/xcschemes/` is empty, so CI must run `xcodegen generate` to create the scheme before building.
- **No `.gitignore`** — repo has none; should add before CI to prevent committing derived data.