# Check receipt: exact-current genomic component review

- Candidate: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- Exact source pin: `src/genomic.jl` SHA-256 `72423bd1523dbcf25ef55081d89328c12004797637d8506e17e5ff574a87c021`.
- Reviewers and ranges: Gauss, lines 15-457 and 458-459; Karpinski, lines 639-1157. Henderson's 2417-2616 review was not run because the agent thread limit was reached.
- Deterministic local probes reproduced: weighted G/inverse exact-symmetry mismatch; APY acceptance of infinite ridge and matrix entries with singular Q; APY scale-dependent absolute conditional-variance cutoff; zero-ridge activation with inverse residual 2.4465 on the registered fixture; nonfinite G from finite subnormal allele frequency; and missing LOCO label accepted as the string key `missing`.
- Scan-core review found no GLS projection algebra defect against the existing dense oracle. It records unmeasured type, scale, allocation and conditioning risks only.
- `src/genomic.jl` has six missing-ref changes, including `origin/codex/handover-0910-20260907`, whose diff overlaps the symmetry guard and adjacent fit wrappers. No shared source or test files were edited pending lane ownership resolution.
- No model fits, benchmarks, GPU execution, hosted CI, capability promotion, release submission, or tag.
