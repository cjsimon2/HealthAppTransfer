# Verify Before Complete

Before marking any task complete, rigorously verify the following checklist:

## Acceptance Criteria
- Re-read every acceptance criterion from the task/issue description.
- Confirm each criterion is met with concrete evidence (test output, screenshot, manual verification).
- If any criterion is ambiguous, clarify before marking complete — do not assume.

## Tests Pass
- Run the full test suite (`Cmd+U` in Xcode or `xcodebuild test`), not just the tests you wrote.
- Confirm zero failures and zero unexpected skips.
- If a test is flaky, investigate — do not ignore.

## No Regressions Introduced
- Review `git diff` against the base branch for unintended changes.
- Verify related features still work (e.g., if you changed the export flow, test the import flow too).
- Check that no warnings were introduced in the build.

## STATE.md Updated
- Update the current phase, completed tasks, and any blockers in `STATE.md`.
- Move the task from "In Progress" to "Completed" with a brief summary of what was done.
- Note any follow-up work discovered during implementation.

## Final Sanity Check
- Would you be confident if someone reviewed this right now?
- Is there any "I'll fix this later" code that should be addressed now?
