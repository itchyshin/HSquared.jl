# 2026-06-29 — v0.4 (multivariate-unstructured) scoped covered close (Rose-audited)

- Goal: finish v0.4 following doc-18. V4-MV-REML is already `covered` at validation scale; this slice
  is the SCOPED RATIFICATION — an explicit scope-of-validity + cross-surface reconciliation — not a flip.
- Established the W1-owed green foundation: `Pkg.test()` PASS + `docs/make.jl` exit 0.
- Ran a **real Rose audit** (`rose-systems-auditor` subagent) on the scoped finish — verdict
  **PROMOTE-WITH-CHANGES**: claim substantively honest (rests on the pre-declared 48-seed gate +
  one `sommer` same-estimand leg ≤8e-5; never "unbiased"; W1 5/8 is additive characterization with
  `base_inside` passing → R9-clean), two mechanical blockers — (A) no written scope-of-validity,
  (B) stale `experimental` on capability-status.md predating the #161 covered promotion.
- Applied Rose Edit A (scope-of-validity sentence) to `validation-debt-register.md` + the
  `validation_status()` function string; Edit B (`experimental`→`covered` + covered framing) to
  `capability-status.md`; optional Edit C (struck the now-characterized "larger-n" from the owed list).
  Left `06-public-claims-register.md` `partial` (Rose finding 3: correct public-vs-validation layering).

## Checks

- `Pkg.test()` (julia 1.10.0) re-run AFTER the `src/validation_status.jl` edit → `Testing HSquared tests
  passed` (exit 0). Count guard `test/runtests.jl:174 == 48` holds; status-set guard `:221` holds.
- `validation_status()` live → 48 rows, V4-MV-REML `covered`, counts 5/3/39/1 — UNCHANGED.
- `docs/make.jl` → exit 0 (benign warnings only).
- Cross-surface: validation_status() function + debt register + capability-status now all say `covered`;
  public-claims register stays `partial`. Public-covered FITTING = 1 (unchanged).
- `git diff --check` clean; the two foreign never-stage files untracked.

## Claim audit

Clean (Rose PROMOTE-WITH-CHANGES → both required edits applied verbatim). Scoped covered close on an
already-covered validation-scale row; no new covered flip, no count change, no public-default / API / R
change. BLUPF90 (2nd same-estimand comparator) pursued but download+execute classifier-blocked → remains
OWED hardening, not a v0.4 blocker. Maintainer **G10** sign-off requested to ratify the scoped claim.
