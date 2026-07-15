# Sovereign-OS Mistakes Ledger

This ledger tracks process failures, not just code defects. It records instances where the verification process itself failed (e.g., a fix was claimed but incomplete, or a decision record stated something false). 

> **Methodology**: Before closing any defect or claiming a capability works, read this ledger. Verify fixes by executing the code, and ensure a defect ID names a pattern, not a single file.

---

## M01: The Environment-Variable Pattern-vs-File Gap
* **What was claimed**: The `$env:USERPROFILE` Linux-crashing bug was resolved.
* **What was actually true**: It was fixed in one of four call sites, leaving the other three broken, while the defect was recorded as closed.
* **Why the check failed**: The fix was validated by reading the diff of the single file that was changed, without checking if the same root cause (the pattern) existed elsewhere in the codebase.
* **Verification Change**: A defect ID names a pattern, not a file. Grep the whole tree for the shape of the bug before writing "Resolved."

## M02: Config-Flag Fix with Incorrect Decision Record
* **What was claimed**: A config flag was fixed, and the decision record described the fix.
* **What was actually true**: The config flag was fixed in substance, but the decision record named the wrong underlying technology.
* **Why the check failed**: The decision record was written from assumption or memory rather than verified against the live source code of the fix.
* **Verification Change**: Re-verify architectural claims against the current source before writing decision records. Documentation must reflect the actual implemented technology.

## M03: Orphaned Git Artifacts Claimed Cleaned
* **What was claimed**: Orphaned git artifacts (e.g., gitlinks under `core-framework/`) were cleaned up.
* **What was actually true**: The artifacts were still present despite the claim.
* **Why the check failed**: The cleanup was assumed complete without verifying the git tree state.
* **Verification Change**: Always verify repository state using actual git commands before claiming artifacts are removed.

## M04: Unverified CI Matrix Expansion
* **What was claimed**: The CI matrix was expanded to catch cross-platform bugs automatically.
* **What was actually true**: The expanded CI matrix was very likely broken on the new platform it was expanded to cover.
* **Why the check failed**: The matrix was expanded in configuration but not actually tested or observed passing on the target platform. A source-only check was treated as equivalent to a runtime one.
* **Verification Change**: Prefer executing the affected code path over reading the diff. If a CI matrix is expanded to a new platform, a successful run on that platform must be observed and cited as evidence.
