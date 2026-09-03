# 52 — v0.7 exact-`G` estimated-VC comparator recipe (S0b)

> **Status: RECIPE · FISHER TOLS RATIFIED 2026-09-02 · one-shot launchable.**  
> **Not a covered flip.** Trap: do **not** reuse 2026-06-22 supplied-variance
> comparator as estimated-VC parity.  
> Twin: `hsquared` `docs/design/52-v07-exact-G-comparator-recipe.md`.  
> Driver: `sim/recipes/exact_G_estimated_vc_comparator.jl` +
> `sim/recipes/run_exact_G_estimated_vc.R`.

## Purpose

Satisfy design-41 §3 #2 for R-public genomic GREML: **same-estimand REML
comparator** on the **engine’s exact \(K_\lambda\)** (and \(G\) hashed alongside),
**estimated** VCs — not supplied-variance agreement.

| Role | Tool |
|---|---|
| Primary free leg | **sommer** (`mmes` / `vsm(ism(id), Gu = K_λ)`) |
| Secondary | **rrBLUP** (`mixed.solve(..., K = K_λ)`, EMMA REML) |
| Optional confirmatory | GCTA / blupf90+ (host-gated) |
| Forbidden as covered leg | Bayesian (BGLR/MCMCglmm/JWAS); **ASReml** (licence ABSENT) |

## Fixture contract (predeclared — Fisher ratified 2026-09-02)

Fisher perspective (not a spawned subagent). Precedent: design-23 gryphon
univariate band and the V4 direct–maternal sommer `rel.diff < 0.02` gate.
This job is an **optimizer comparison** on a **shared kernel**, so the pedigree
band is the right starting ceiling; do not tighten or loosen after seeing
numbers.

| Field | Frozen value |
|---|---|
| Relationship | Engine VanRaden-1 sample-\(p\) \(G\); **shared kernel is \(K_\lambda = G + 0.01\,I\)** (design-51 estimand). Hash **both** \(G\) and \(K_\lambda\). No G-vs-\(K_\lambda\) split. |
| Model | Univariate Gaussian REML · genomic animal · no second iid effect |
| DGP (recorded, not the gate) | \(\sigma_g^2=0.6\), \(\sigma_e^2=0.4\), \(r_G=0.6\), \(\mu=2\); \(u\sim N(0,K_\lambda\sigma_g^2)\) via `chol(K)` — same construction as `sim/phase2_genomic_reml_recovery.jl` |
| Scale | **Validation-scale one-shot:** \(n=300\), \(m=1000\) (V2-GREML recovery size) |
| Seed | **202609022** (new; disjoint from smoke 20260902, recovery 20260800–847, comparator 20260630, holdout 202713*) |
| sommer | `mmes` · `henderson=FALSE` · `Gu = K_λ` (raw covariance, not inverse) · `vsm(ism(id), Gu = K)` |
| rrBLUP | `mixed.solve(y, K = K_λ, X = 1)` |

### Ratified tolerances (no post-hoc)

| Leg | \(\sigma_g^2,\sigma_e^2\) | \(r_G\) | EBV \(r\) |
|---|---|---|---|
| **Primary (engine vs sommer)** | relative \(\lvert\Delta\rvert / \max(\lvert a\rvert,\lvert b\rvert,10^{-8}) \le 0.02\) | absolute \(\lvert\Delta r_G\rvert \le 0.02\) | target \(> 0.999\), **not** a FAIL bit for this VC one-shot |
| **Secondary (engine vs rrBLUP)** | same numeric band | same | same target |

rrBLUP uses EMMA, not AI-REML. If the secondary misses the band: label
`OPTIMISER_DISAGREEMENT` (Rose-visible). **Do not widen the band.** Primary
sommer miss = `FAIL`.

PASS (primary): engine converged AND sommer converged AND both VC relatives
\(\le 0.02\) AND \(\lvert\Delta r_G\rvert \le 0.02\).

### Explicit non-goals

- Supplied-variance rrBLUP/BGLR agreement (2026-06-22)
- Bayesian agreement as parity · ASReml genomic/S6 · D1 recovery-v3 / quarantine
- Merging DRAFT #137/#274 tooling as this fixture
- Known-truth recovery (this is comparator parity, not the 48-seed gate)

## Acceptance sketch

1. Engine and sommer agree within the ratified tols on \(\sigma_g^2,\sigma_e^2,r_G\) for shared \(K_\lambda\).
2. rrBLUP secondary agrees within the same tols, or documents optimiser disagreement with Rose-visible label.
3. Fixture + matrix hash + package versions (`sommer`, `rrBLUP`, Julia/R SHAs) recorded in scratch receipt (check-log when `docs/dev-log/` is free).
4. R twin honesty catch-up under owner #8 — **no claim flip in the comparator PR**.

## Host plan (owner #9 Totoro preferred)

| Phase | Host |
|---|---|
| Paper recipe + tiny local smoke | laptop OK |
| Validation-scale one-shot estimated-VC | **Totoro** (ControlMaster preferred) · ~15 min wall |
| Multi-seed recovery ladder | DRAC array — ask if >Totoro; no interactive Duo |

Named-job paste (D-139; Fisher-ratified):

> 0.7-S0b needs exact-`K_λ` sommer/rrBLUP estimated-VC at validation scale (n=300, m=1000, seed 202609022, ~15 min). Totoro preferred per #9.

## Delivery order

1. Freeze matrix export helper (engine → CSV of \(G\) and \(K_\lambda\)) — `sim/recipes/`.
2. Ratify tols (Fisher perspective, 2026-09-02) — **done**.
3. Totoro one-shot · record SHAs.
4. R catch-up honesty (no covered flip).
5. Feed S0d recovery disposition (banked 48-seed engine gate vs new confirm).

## Cite

- design-51 estimand · design-44 activation · design-43 honesty · design-23 bands
- Engine covered row: supplied-`Ginv` recovery — **not** this estimated-VC leg
- DRAFT [#137](https://github.com/itchyshin/hsquared/pull/137) / [#274](https://github.com/itchyshin/HSquared.jl/pull/274) — inventory only
