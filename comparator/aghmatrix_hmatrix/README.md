# Single-step H / H⁻¹ — AGHmatrix::Hmatrix packet (v0.8 S1)

**Status: OPT-IN comparator packet. NOT a covered flip. `V2-SSHINV` stays partial.**  
Count stays **7**. Experimental **0.7.0**. Never 1.0 from this file.

Sibling FA lane (`cursor/08-fa-20260903`, HSquared.jl #292) owns the S0
construction probe (`G = A₂₂` reduction). This packet is the **next**
single-step evidence step: an external same-estimand construction leg.

## Estimand

Engine: `single_step_inverse` builds Aguilar / Christensen–Lund precision

```text
H⁻¹ = A⁻¹ + scatter(τ G⁻¹ − ω A₂₂⁻¹)
```

with defaults `τ = ω = 1`, `blend_weight = ridge = 0`.

AGHmatrix: `Hmatrix(A, G, method = "Martini", tau = 1, omega = 1)` returns the
**relationship** `H` (Legarra et al. 2009 when τ=ω=1). Compare
`solve(H_AGH)` to engine `H⁻¹` after **ID alignment** (AGHmatrix reorders).

Munoz shrinkage is a **different** estimand — do not use it as parity.

## Mrode Ch.11 — explicit NO-ANCHOR

Mrode (3rd ed.) Ch.11 discusses genomic prediction / single-step conceptually.
It does **not** publish a small pin-able numerical `H` / `H⁻¹` worked table
comparable to the pedigree examples in earlier chapters. This packet therefore
records **`mrode_ch11_anchor = NO_ANCHOR`** (design-41 §3 item 4) rather than
inventing a textbook target. Aguilar 2010 / Legarra 2009 remain the formula
citations. A later owner may replace this disclosure if a published numerical
target is identified.

## Run

```sh
# from the HSquared.jl root
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=. comparator/prepare_aghmatrix_hmatrix.jl
Rscript comparator/run_aghmatrix_hmatrix.R
```

- Missing `AGHmatrix`: runner prints `COMPARATOR: SKIP` and exits 0.
- Present: writes `result.txt` (`AGREE` / `DISAGREE`). Construction tolerance
  `1e-8` on `max|Hinv_agh − Hinv_engine|` and `max|H_agh − H_engine|`.

## Executed (2026-09-03, local, not Totoro)

AGHmatrix **3.0.1** (CRAN; R 4.6 arm64). Julia 1.10.0. Host
`w-kw3k3y6229.psych.ualberta.ca`.

```text
max|Hinv_agh - Hinv_engine| = 4.239720e-12
max|H_agh - H_engine|       = 3.140599e-12
COMPARATOR: AGREE
```

`docs/dev-log/` check-log / after-task / board updates are **deferred**: live
lease `cursor:g5-08-jl-20260903` holds `docs/` and `sim/`. This packet stays
under `comparator/` only. Receipt:
`~/local-scratch/h2-08-singlestep-2026-09-03.md`.

Install (local / Totoro user library only — **not** a package dependency):

```r
install.packages("AGHmatrix")
```

## Recovery smoke (not a gate)

`prepare_aghmatrix_hmatrix.jl` also writes `engine_recovery_smoke.csv`: one
n=6 seed from the packed `H`, then `fit_single_step_reml`. This is a
**dump**, not a predeclared bias/MCSE gate. Do not read it as recovery PASS.

## Explicit non-claims

- No `V2-SSHINV` covered flip.
- No comparator-validated `τ`/`ω`/`blend`/`ridge` defaults beyond τ=ω=1, c=0.
- No preGSf90 / BLUPF90 single-step run (not provisioned here).
- No metafounder `H^Γ` comparator.
- No sparse / APY scaling.
- No R `single_step()` public promotion.
- No experimental **0.8.0** / count 8.

## Next (still owed for §3)

1. Execute AGREE on a machine with AGHmatrix (this runner).
2. Predeclared multi-seed recovery gate (S2) — not this packet.
3. preGSf90 if provisioned, or disclose that second-tool gap.
4. Boole grammar freeze + Darwin SIGN + R catch-up + Rose CLEAN.
