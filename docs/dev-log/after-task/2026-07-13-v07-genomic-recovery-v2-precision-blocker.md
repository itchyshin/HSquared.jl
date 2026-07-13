# After-task report — Julia twin recovery-v2 precision blocker

## 1. Goal

Support the live R-to-Julia genomic recovery campaign, independently recompute
its summaries, and permit activation only behind every preregistered gate.

## 2. Implemented

- Ran the Julia recomputer against all 432 Totoro pilot attempts.
- Recorded the campaign-wide precision blocker and withheld confirmation.
- Retired offsets 7101:7148 and moved any future pilot contract to 7201:7248.
- Mutation-tested retired pilot membership and synchronized Julia status,
  capability, validation-debt, and genomic documentation.

## 3a. Decisions and Rejected Alternatives

- Did not treat 432 successful fits as recovery evidence because the formal
  receipt is absent and five cells exceed the frozen precision cap.
- Did not monkey-patch the sealed offset-7101 root or launch partial confirmation.
- Kept the supplied-precision engine row covered while holding the distinct R
  marker-route activation.

## 4. Files Touched

- `sim/phase2_v07_genomic_recovery_v2_recompute.jl`
- `ROADMAP.md`
- `docs/src/genomic-models.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/coordination-board.md`
- this report, the matching check-log fragment, and recovery checkpoint.

## 5. Checks Run

- Julia recomputer self-test: pass.
- Full `Pkg.test()`: pass.
- Documenter/Vitepress build: pass with pre-existing docstring/npm warnings.
- Totoro three-way summary comparison: Julia maximum absolute numeric
  difference `3.33e-16`, zero fields outside `1e-10`.
- `bash tools/preamble_cap.sh` and `git diff --check`: pass.

## 6. Tests of the Tests

The Julia recomputer self-test rejects the retired 7101 block and pilot versus
confirmation tier overlap. The R twin additionally proves logical write/read
round-trip, valid Boolean inversion, invalid/missing tokens, and retired
offset-7101 manifest rejection. The sealed offset-7101 adjudicator stayed red
and prevented confirmation.

## 7a. Issue Ledger

| Issue | Disposition |
| --- | --- |
| Lower-case Boolean serialization blocked adjudication | R comparators repaired and mutation-tested. |
| Old root sealed to defective driver | Preserved immutable; no post-hoc receipt. |
| Five cells require N above 2,000 | Campaign-wide precision blocker; no confirmation. |
| Stale Julia status said pilot had not run | Corrected across ROADMAP, manual, capability, and validation debt. |

## 8. Consistency Audit

The supplied-Q engine claim remains covered, while every neighbouring surface
now keeps the raw-marker R route partial/held and distinguishes diagnostic
summaries from accepted recovery. No status/count row moved.

Memory receipt: repo LOAD-FIRST, validation-harness, after-task audit, D-50
Totoro/DRAC compute, exact twin binding, and Rose negative-space rules shaped
the execution and closeout.

## 9. What Did Not Go Smoothly

The campaign first needed an upstream JuliaCall/libunwind repair on Totoro.
After all fits finished, the R adjudicator exposed a Boolean serialization
defect. A brief Totoro/DRAC disconnection recovered without corrupting outputs.

## 10. Known Residuals

- No accepted pilot adjudication receipt or confirmation manifest exists.
- A future design must reduce the precision burden; more compute under the
  failed rule is not justified.
- The DGP does not establish LD, structure, imputation, real-panel, or
  production-scale robustness.
- Rose/G10 and public activation remain held.

## 11. Team Learning

Independent recomputation must include type/serialization boundaries, not just
floating-point arithmetic. A preregistered precision stop is a valid negative
research outcome and should prevent a larger campaign.

Golden Set: not run because memory/routing code did not change. Exact hash,
manifest, tier, retired-seed, and independent-summary controls exercised the
in-scope recurring failures directly.

## 12. Cross-Product Coverage

- Julia recomputation covers the frozen nine-cell Gaussian-REML marker pilot;
  it does NOT cover accepted recovery, confirmation, or default activation.
- Engine evidence covers the validation-scale supplied-precision estimator; it
  does NOT cover production sparse genomic fitting, APY, calibrated intervals,
  or exact ridge-regularized SNP-BLUP equivalence.
- Compute covers local Totoro outputs; it does NOT cover GitHub Actions
  campaigns or artifacts.
- Status remains held; this work does NOT cover count promotion, G10, merge,
  release, or production claims.
