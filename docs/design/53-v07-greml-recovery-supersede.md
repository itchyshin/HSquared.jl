# 53 — v0.7 R-public GREML recovery disposition (SUPERSEDE)

> **Status: SUPERSEDED (2026-09-02) — do not launch a fresh R 48-seed GREML
> recovery for the opt-in validation-scale covered claim.** Owner disposition
> under overnight approvals **#5–#10** (especially **#7** auto-flip when
> design-41 §3 + Rose CLEAN) plus the gap-clear tip that prefers SUPERSEDE when
> banked engine genomic evidence is valid. Twin:
> `hsquared` `docs/design/53-v07-greml-recovery-supersede.md`.
>
> **Not a covered flip.** R `public_covered_count` stays **6** until a separate
> Rose CLEAN tip audit and lockstep flip PR. Engine Genomic REML stays
> **covered** (unchanged). No General / CRAN / 1.0. D1 pause still binds. Cite
> DRAFT [#137](https://github.com/itchyshin/hsquared/pull/137) /
> [#274](https://github.com/itchyshin/HSquared.jl/pull/274) only.

## What this SUPERSEDES

A **fresh R-owned known-truth recovery campaign** as design-41 §3 item 1
prerequisite for promoting the **opt-in, validation-scale, explicit
`target = "genomic"`** R-public GREML surface from `partial` → `covered`.

That includes Progress S0d “48-seed recovery confirm” and any re-run of design-43
§3 recipes as a *covered-flip* recovery substitute. Those recipes stay
historical; honesty fences in design-43 §1 and design-51 remain binding.

## What this does NOT SUPERSEDE

| Still owed / still live | Why |
|---|---|
| **design-44 G5** nine-cell marker-route recovery | Gate for **default activation**, not for the opt-in validation-scale claim |
| Boundary performance localization + fresh holdout | `BOUNDARY_HOLDOUT_FAIL` (5.99× p95) still blocks default activation |
| D1 / ordinary_auto_genomic / recovery-v3 | Separate pause (D-68 / D-71) |
| Interval coverage (design-41 §3 #7) | Out of 0.7 point-estimate scope (same posture as 0.6) |
| Engine evidence ≠ automatic R covered flip | Twin discipline unchanged; Rose + Darwin + remaining §3 still required |

## Banked evidence that carries §3 #1 for the opt-in claim

| Leg | Pointer | Role |
|---|---|---|
| Engine supplied-`Ginv` Genomic REML 48-seed | `sim/phase2_genomic_reml_recovery.jl`; predeclaration `docs/dev-log/recovery-checkpoints/2026-06-30-v2-genomic-recovery-gate-predeclaration.md`; capability row **Genomic REML = covered** | Pre-declared bias/MCSE PASS on the estimator the R route calls |
| Engine same-`Ginv` `blupf90+` comparator | `…/2026-06-30-v2-genomic-blupf90-comparator.md` | Same-estimand REML isolation on supplied precision |
| Marker ≡ supplied-Q construction/fit identity | `test/test_genomic_greml_s0_identity.jl`; R `tests/testthat/test-genomic.R` “explicit marker and exact supplied-Q routes agree [live]”; activation fixture live gate | Maps marker route onto the covered supplied-`Ginv` estimator |
| Exact-`G` estimated-VC comparator | design-52 + Totoro job `0.7-S0b-exactG-20260902` **PASS** | Discharges §3 #2 (comparator), **not** this SUPERSEDE |

Reading rule (same as A25 / MV-5): banked engine recovery + identity that the
R public route is the same estimator **substitutes** for a fresh R 48-seed
campaign for the **narrow opt-in claim**. It does **not** invent default-route
performance, field-panel robustness, or nine-cell G5 PASS.

## Scope of the eventual covered claim this disposition supports

- Explicit `engine = "julia", target = "genomic"` (opt-in).
- Gaussian REML only; dense / validation-scale.
- Estimand: `genomic_variance_ratio` / \(r_G\) on \(K_\lambda = G + 0.01 I\)
  (design-51); never bare pedigree \(h^2\).
- **Not** default activation; **not** single-step / SNP-BLUP / APY / GPU;
  **not** calibrated intervals.

## Integrity

1. This file is the explicit owner/design ink Rose required before treating
   engine V2-GREML + marker≡Q identity as §3 #1 for R-public GREML.
2. No post-hoc widening of the engine 48-seed gate.
3. Re-opening a fresh R recovery for this claim needs a new pre-declaration SHA
   **and** owner compute-go (“Totoro or DRAC?”).
4. design-44 G5 remains the default-activation recovery contract; do not delete
   or silently rewrite it from this SUPERSEDE.

## Fence

No R `partial→covered` from this file alone · R count stays **6** · Version stays
**0.6.0** experimental until the lockstep flip PR under #7/#8/#10 after Rose
CLEAN. Engine Genomic REML covered status is unchanged by this disposition.
