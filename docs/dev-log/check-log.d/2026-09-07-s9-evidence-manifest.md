# Check log — 2026-09-07 S9 source-inert evidence manifest

- **Julia base:** 1dbf8b97a3b28f814e3418239ac1658acbbc19bb.
- **R pair:** clean S7 candidate e6a1ce4e8a691795487420668b349fb9e2670059.
- **Scope:** machine-checkable provenance and inertness only. No scientific
  result, smoke, campaign, promotion, version/count change, or release action.

| Check or review | Outcome | Boundary retained |
| --- | --- | --- |
| Exact-pair validator | **PASS** — S9_MANIFEST_PAIR_OK | Exact-pins S8 base and proves Julia ancestry; exact-pins clean R S7 and eleven SHA-256 values |
| Inert-state validator | **PASS** — S9_MANIFEST_PAIR_OK, S9_INERT_OK | All action/result/release fields are false; no runtime action occurs |
| Dedicated negative controls | **PASS** — S9_NEGATIVE_CONTROLS_OK, 39/39 | Altered seed, denominator, eligibility, Julia/R SHA, hash, H0 authorization, schema, R root, unrelated base, and effective exit-78 refusal reject |
| Normal Julia suite | **PASS** — Pkg.test() completed with Testing HSquared tests passed under a 300-second Unlazy bound | The initial 120-second runner timeout is retained; no test was skipped or weakened |
| git diff --check | **PASS** | No whitespace error in declared S9 change |
| Fisher protocol review | **PASS with precision correction** | Separate H0/H1/H3, conditional denominator, realized MCSE, H1-t limit, and H3 initialization retained |
| Rose scope audit | Required change applied; final **APPROVE** | Replaced global H0 status assertion with S9-only authorization/status fields |
| Rose ancestry re-review | **APPROVE** | S8 ancestry and exact R S7 identity are distinct from G5's five-path scope proof |
| Standard after-task validator | **PASS** — acceptance ledger: 3 file(s), every gate satisfied | Independently reran the same full suite under the supported 300-second bound |

The scheduler template remains an active refusal, not an authorization to
submit. G6–G10, release, and compute remain held.
