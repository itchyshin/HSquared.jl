# 2026-09-30 FA output validation and weak-direction regression

Candidate: `codex/hsquared-fa-gllvm-20260927`, HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16` plus preserved working-tree changes.

- Python stdlib validator tests after repair/integration: 22/22 pass, exit 0, 0.397 seconds. Independent Curie review passes on validator SHA-256 `2b2d7d60c313180b0a0668cb7d51929bdccb95d80d8f1279cbcd27c578420abb` and tests `f407ea0b46cdfe8b5226e1b03c879f227518b733f3955957dbef79ef61ec863f`.
- Real 19-row snapshot: partial, 11 recovered, 14 converged, 5 nonconverged, 2 G errors, 1 R error. Completed mode correctly exits 1 for missing primary rows. The numbers describe that prefix snapshot.
- Deterministic Julia weak-direction test: 36/36 new assertions plus 4/4 existing helper assertions pass, exit 0. One Julia/BLAS thread, estimate under one minute. New test SHA-256 `158ae089596b4c2bcf9e1fd889e0777771776d11c417359a9aba350fe6b82b5c`; registered runner SHA-256 `b2d77c7f0937f5fcf0ed8ec32913c816b2c942f27c83825c8424107a5bc58b24`.
- Frozen source SHA-256 unchanged: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`; driver unchanged: `2161449e2e320a6d56bf5b71b1927e18b3d3b4dd60704d30bae5aaafbf057e9b`.
- `git diff --check` passed. After-task structure passed; the combined checker exited 1 for unmet programme and child ledgers. Full Julia suite and hosted CI remain final-integration work.

The independent check caught and repaired an Inf/NaN-to-NA classification ambiguity. The validator cannot recompute complete matrix diagnostics from scalar output. All requested primary attempts remain in the denominator; no campaign-level pass cutoff is inferred. A2, E1 and V3 remain open. No source/driver change, GPU, submission or tag.

Details: `docs/dev-log/after-task/2026-09-30-fa-result-validator.md` and the current source-review receipts.
