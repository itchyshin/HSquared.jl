# Isolated R current-live FA-rank parser diagnostic, 2026-10-08

Scratch clone: `/private/tmp/hsquared-arc1-r-active-20261008`, branch `codex/h2-arc1-r-v1-columnar-20261008`, base `a563ea88f3076819a4a5d8966e2644489efd1688`.

- Focused offline `devtools::test(filter = "auto-fa-rank-optin")`: exit 0; the live test skips by design.
- Focused mandatory-live JuliaCall `devtools::test(filter = "auto-fa-rank-optin")`: exit 0; Julia 1.10.0 initialized and the live bridge case passed.
- Red/green regressions cover unknown policies, v2 missing fields in columnar/row-list/data-frame shapes, zero-row length mismatch, and malformed or present-NULL legacy metadata.
- `git diff --check`: exit 0.
- Source SHA-256 `48dd81b39053a2e03f40123135c5a00bebc046cb6e86aec515ca9e0c39cc7dfa`; test SHA-256 `c4f1e6e61b9a248647e6a15553de6715d081dee1a507a7fe315febfc4f55a839`; patch SHA-256 `f57499bbf3a1339f9db879db2a634498bb39e2f2223744c1cadf551f0425e4f6`.
- Astra independently passed those exact hashes for parser compatibility/schema repair. Review does not certify NULL/NA identity semantics or every legacy row-list behavior.
- Full command, environment, exit codes and hashes: `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/r-current-live-20261008/receipt.json`.
- Evidence boundary: no paired current-source freeze, no canonical G6 credit, and no study attempt. Main R checkout and prior orphaned R lane untouched.
