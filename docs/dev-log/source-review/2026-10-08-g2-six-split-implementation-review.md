# G2 six-split implementation review

Status: PASS for the exact source and focused regression bundle below. This is a static implementation review, not G2 numerical evidence or run admission.

## Reviewed artifacts

- Adopted method decision: `docs/dev-log/decisions/2026-10-07-g2-k0-six-split-followup-candidate.md`, SHA-256 `9b7f6c3e0b4c482126258000b87e1cac3fb882669ec0064c648d3ff821573d14`.
- Julia `src/fa_rank_selection.jl`, SHA-256 `e7a937bf5bdb60fa1f607189672b9c7da0bc3915e4703a8add818978ed44c0d1`.
- Julia `test/arc1_optimizer_contracts.jl`, SHA-256 `c9004ba5f83d18554920a0dc97e417b23be0a969b2ab03289109de6849c5928b`.
- Isolated R `R/fa-rank-selection.R`, SHA-256 `b3916492ce71e94176c2bcc03986424bcc9dd798a7dbc1bcda2b633eee5deedb`.
- Isolated R `tests/testthat/test-fa-rank-g2-split-transport.R`, SHA-256 `23442d200f195f157c77c01661b66b0b7d60791789b7a02b1bb5f32e18f23dac`.

## Review findings

The six K0 starts retain the frozen order. The 0.5 start copies the existing production initializer directly. The other five compute sample variance from observed `Y`, use the required 1.0 fallback for nonfinite or nonpositive variance, then apply the uniqueness floors and existing transforms. Julia retains six K0 rows and eighteen K1 rows, their schedule indices, and the selected best eligible K0 anchor on K1 rows. If K0 is unavailable, K1 remains unattempted without an anchor. Existing refusal safeguards, score, eligibility, and opt-in behavior remain in place.

R preserves split, schedule index, K0 anchor, and initialization status. Those fields remain optional for older ledgers. The corrected fixture matches the Julia attempt counts and status values.

## Validation and limits

- Julia focused optimizer contracts passed: 668/668.
- R focused transport test passed: 21 assertions, zero failures, warnings, or skips.
- Full Julia `Pkg.test()` completed with `Testing HSquared tests passed` after the implementation change.
- An independent seed audit found all 270 allocated development indices consumed. The implementation review therefore grants no study admission or G2 credit. The reviewed allocation-extension candidate is a separate proposed decision.
- G1, G6, and G7 are reopened pending fresh paired-source receipts. The prior receipts remain historical evidence.

The independent Astra review checked the exact hashes and returned PASS. It did not run tests, fits, or studies. No gate status was advanced by this review.
