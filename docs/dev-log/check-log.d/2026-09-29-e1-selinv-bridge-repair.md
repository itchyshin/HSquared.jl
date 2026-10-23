# 2026-09-29 E1 selected-inverse and payload-parser repair

- The selected-inverse contract tests failed before guards: six missing expected errors. Final focused file: **25/25 passed**, including dense selected-entry checks with a nonidentity permutation.
- Final focused bridge parser checks: **8/8 passed**. The integrated test run also passed its response-shape and block-name sets.
- Julia 1.10 `Pkg.test()` log: `/private/tmp/hsq-e1-current-pkg-test.log`; ends `Testing HSquared tests passed`. The Project/Manifest mismatch warning remains; dependencies were not resolved.
- `git diff --check` passed. Exact final hashes and the bounded Gauss/Boole review findings are recorded in `docs/dev-log/source-review/2026-09-29-e1-selinv-bridge-repair.md`.
- Exact-current post-fix reviewer replay, whole-wave E1 signoff, A2, and V3 remain open. No claim or release status changed.
