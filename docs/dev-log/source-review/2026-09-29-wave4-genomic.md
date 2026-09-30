# Wave 4 genomic utilities input-contract review

## Scope and pinned source

- Review source: `src/genomic.jl`, baseline HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- Original reviewed file SHA-256: `66403cf51622b813d9cf5a0362b708fbe4419cf9d425cd2ba5856b6e63522d60`.
- Post-fix file SHA-256 after reviewer follow-up: `d9ae83d623b84508d599950df8cb18cbd9102c295ee580868850f00a1ed2bcad`.
- Test file SHA-256: `f883378cfc6c8dd5bd4294e5ba98b8268da6945ded7e1b07435acaa49bd15f82`.
- Reviewed function regions: weighted VanRaden construction; relationship-precision lookup; direct marker scan; empirical null threshold; single-step precision assembly.

## Findings and disposition

The independent initial review reproduced five malformed-input defects: non-finite genomic weights yielded invalid kernels; LOCO relationship keys collided after string canonicalization; infinite residual variance passed the direct scan; non-finite supplied-null values yielded invalid thresholds; and single-step assembly silently symmetrized asymmetric inputs and accepted invalid knobs, duplicate rows, and non-positive-definite output. Re-review found that a finite `BigFloat` could overflow to `Inf` during the direct scan's `Float64` conversion. The scan now converts once, validates the converted value, and reuses it; a regression covers `big"1e1000"`.

All five finding classes now have explicit validation and registered regression tests. Single-step input matrices must be finite and symmetric, `A` and `Ainv` positive definite, rows unique, and knobs in their stated domains; the result must be positive definite. The valid `G = A[g,g]` reduction is retained in the test.

## Verification

- TDD focused test before first repair: 8 of 14 assertions failed as expected; duplicate genotyped rows raised the wrong exception class. The post-review BigFloat test then failed against the first repair as expected.
- Focused test after all fixes: 19/19 passed.
- Full Julia `Pkg.test()` on the final integrated candidate: exit 0, including the final new testset (19/19); log `/private/tmp/hsq-genomic-input-contracts-pkgtest-20260929-final.log`, ending `Testing HSquared tests passed`.
- Julia docs build passed from the synchronized candidate `/private/tmp/hsq-genomic-docs-copy` after attaching the worktree Git pointer. Existing missing-docstring, local deployment autodetection, and absent favicon/config warnings were emitted.
- `git diff --check` passed.
- After-task report structure validation passed. Integrated acceptance-ledger validation remains exit 1 with A2, E1, and V3 open (8 of 11 programme gates met).
- `bash tools/preamble_cap.sh` passed at 11,024/14,000 bytes with one snapshot entry.
- Julia version 1.10.0; `JULIA_NUM_THREADS=4`, `OPENBLAS_NUM_THREADS=1`.
- No simulation, fit campaign, hosted CI, GPU run, or external comparator was part of this slice.

## Independent review and limits

The initial and post-fix read-only numerical reviews found all five issues repaired, verified the valid single-step reduction and row reordering, and identified then closed the BigFloat conversion overflow. Whole Wave 4 and E1 remain open pending review of the other source spans.

Carried genomic requirements include sparse-provenance densification, dense SNP identity/APY/LOCO paths, metafounder raw-input ordering, scale-sensitive APY/scan cutoffs, scan conditioning from normal equations, and residual-permutation calibration. These remain open. This edit adds defensive validation and makes no broader genomic capability or calibration claim.
