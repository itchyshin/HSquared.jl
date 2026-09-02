# 52 — v0.7 exact-`G` estimated-VC comparator recipe (S0b)

> **Status: RECIPE · NOT LAUNCHED · 2026-09-02 · post-0.6 tip.**  
> **Not a covered flip.** Trap: do **not** reuse 2026-06-22 supplied-variance
> comparator as estimated-VC parity.  
> Twin: `hsquared` `docs/design/52-v07-exact-G-comparator-recipe.md`.  
> Driver scaffold: `sim/recipes/exact_G_estimated_vc_comparator.jl`.

## Purpose

Satisfy design-41 §3 #2 for R-public genomic GREML: **same-estimand REML
comparator** on the **engine’s exact \(G\)** (and \(G^{-1}\) if used),
**estimated** VCs — not supplied-variance agreement.

| Role | Tool |
|---|---|
| Primary free leg | **sommer** |
| Secondary | **rrBLUP** |
| Optional confirmatory | GCTA / blupf90+ (host-gated) |
| Forbidden as covered leg | Bayesian (BGLR/MCMCglmm/JWAS); **ASReml** (licence ABSENT) |

## Fixture contract (predeclare before any run)

| Field | Draft value |
|---|---|
| Relationship | Engine exact \(G\) (VanRaden1 sample-\(p\)); if ridge in estimand, ship matching \(K_\lambda=G+0.01I\) to both sides **or** document G-vs-\(K_\lambda\) split; one shared matrix; hash recorded |
| Model | Univariate Gaussian REML · genomic animal · no second iid effect (match design-51) |
| Truth (if recovery) | Predeclared \(\sigma_g^2,\sigma_e^2,r_G\) — separate from comparator parity |
| sommer | `mmer`/`mmes` with `vsr(Gu = G)` (or current Gu API) |
| rrBLUP | `mixed.solve(..., K = G)` |
| Tolerances (**Fisher to ratify before run**) | \(\sigma_g^2/\sigma_e^2\) ~1–2% relative; \(r_G\) ~0.01–0.02 absolute (gryphon pedigree band as *starting* proposal) — **predeclare; no post-hoc** |
| Scale | Validation-scale first |
| Seeds | **New** allocation — never reuse spent 240 holdout seeds |

### Explicit non-goals

- Supplied-variance rrBLUP/BGLR agreement (2026-06-22)
- Bayesian agreement as parity · ASReml genomic/S6 · D1 recovery-v3 / quarantine
- Merging DRAFT #137/#274 tooling as this fixture

## Acceptance sketch

1. Engine and sommer agree within predeclared tols on \(\sigma_g^2,\sigma_e^2,r_G\) for shared \(G\).
2. rrBLUP secondary agrees within (possibly wider) predeclared tols, or documents optimiser disagreement with Rose-visible label.
3. Fixture + matrix hash + package versions (`sommer`, `rrBLUP`, Julia/R SHAs) recorded in check-log (when docs-quality lease frees `docs/dev-log/`, or scratch receipt until then).
4. R twin honesty catch-up under owner #8 — **no claim flip in the comparator PR**.

## Host plan (owner #9 Totoro preferred)

| Phase | Host |
|---|---|
| Paper recipe + tiny local smoke | laptop OK |
| Validation-scale one-shot estimated-VC | **Totoro** (ControlMaster preferred) |
| Multi-seed recovery ladder | DRAC array — ask if >Totoro; no interactive Duo |

Named-job paste (D-139; do not send until Fisher-ratified):

> 0.7-S0b needs exact-`G` sommer/rrBLUP estimated-VC at validation scale (~[TBD] min). Totoro preferred per #9.

## Delivery order

1. Freeze matrix export helper (engine → CSV/RDS of \(G\)) — scaffold in `sim/recipes/`.
2. Ratify tols (Fisher / owner).
3. Totoro one-shot · record SHAs.
4. R catch-up honesty (no covered flip).
5. Feed S0d recovery disposition (banked 48-seed engine gate vs new confirm).

## Cite

- design-51 estimand · design-44 activation · design-43 honesty
- Engine covered row: supplied-`Ginv` recovery — **not** this estimated-VC leg
- DRAFT [#137](https://github.com/itchyshin/hsquared/pull/137) / [#274](https://github.com/itchyshin/HSquared.jl/pull/274) — inventory only
