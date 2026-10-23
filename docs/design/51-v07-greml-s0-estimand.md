# 51 — v0.7 GREML S0 public estimand freeze

> **Status: ESTIMAND FREEZE · Boole grammar/names RATIFIED 2026-09-02.**  
> Carries design-44 + design-43 honesty. **Not a covered flip.**  
> Count stays **6** until design-41 §3 + Rose CLEAN + owner #7 auto-flip.  
> Twin: `hsquared` `docs/design/51-v07-greml-s0-estimand.md`.  
> Recovery disposition: `docs/design/53-v07-greml-recovery-supersede.md`.

## Frozen claim sentence (candidate)

On the declared relationship scale

\[
K_\lambda = G + 0.01\,I,\qquad
G = WW'/k \text{ (VanRaden method 1, sample allele frequencies)},
\]

the public estimand is

\[
r_G = \frac{\sigma_g^2}{\sigma_g^2+\sigma_e^2}
= \texttt{genomic\_variance\_ratio}.
\]

**Human label:** genomic variance-component ratio on the declared relationship scale  
(`method = vanraden1`, sample \(p\), ridge `0.01`).

**Not:** pedigree narrow-sense \(h^2\); founder-base additive heritability; universal SNP heritability;
unregularized GBLUP≡SNP-BLUP identity; Mrode genomic-\(h^2\) pin.

**Textbook gate:** **explicit no-anchor disclosure** (no clean Mrode genomic-\(h^2\) anchor).

## Scale disclosures that must travel with the number

1. **Base population** — \(G\) centred by \(2p\) and scaled by \(k=2\sum p(1-p)\) (sample/allele-frequency base), vs pedigree \(A\) founder base (VanRaden 2008; Legarra 2016).
2. **No universal ordering** — genomic- and pedigree-scale ratios use different covariance bases.
3. **Ridge / \(K_\lambda\)** — ridge changes the kernel; \(r_G\) is **not** generally the fraction of average marginal phenotypic variance; `diag` scale of \(K_\lambda\) is not constrained to mean one.
4. **API continuity** — `heritability()` may remain the generic entry point, but genomic fits must return component+scale labels (`genomic_variance_ratio`), never a bare pedigree `h2`.

Sources: `docs/design/44-v07-genomic-public-activation.md` §2; `docs/design/43-genomic-greml-g0.md` §1 (honesty retained; recipes superseded).

## N1 / N2 / N3 identity obligations (before #7 flip)

| ID | Defect | Required before #7 flip |
|---|---|---|
| **N1** | One genomic additive variance, two names (`σ²_a` on GBLUP/`Ginv` vs `σ²_g` on SNP-BLUP; \(\sigma_g^2=\sigma_a^2\cdot k\) on the marker prior) | Within-package identity on the **unregularized** scale; unify surfaced label toward `genomic_variance_ratio`; ridge path does **not** claim GBLUP≡SNP-BLUP |
| **N2** | `heritability()` mislabels genomic ratio as pedigree narrow-sense | Genomic branch + disclosure; never bare pedigree `h2` (R already labels; engine numeric ratio must stay honest in docs) |
| **N3** | Silent `ridge = 0.01` | Freeze in estimand + disclose (Boole) |

Scaffolding: `test/test_genomic_greml_s0_identity.jl` (Julia) · `tests/testthat/test-genomic-greml-s0-identity.R` (R).

## Boole freeze (RATIFIED 2026-09-02)

> **Boole (formula/API freeze): RATIFIED 2026-09-02** under owner #7 gap-clear.
> Promotes the S0b “sketch” to the design-38-style bar for 0.7: auto-routing /
> argument names frozen **before** any covered flip. Maintainer accepts via
> overnight approvals #5–#10 (esp. #7). No new public names.

Frozen names and arguments (design-44 + this file; no additions):

| Surface | Frozen |
|---|---|
| Formula term | `genomic(1 \| id, …)` |
| Marker route | `markers = M` (builds VanRaden1 \(G\), then \(K_\lambda\)) |
| Supplied precision | `Ginv = Q` (user-supplied; construction unknown) |
| Public ratio label | `genomic_variance_ratio` (never bare pedigree `h2`) |
| Ridge | `0.01` (estimand knob; disclosed) |
| Family / method | `gaussian()`, `REML = TRUE` only for the 0.7 claim |

Accepted (0.7 covered-claim grammar):

```r
hsquared(y ~ fixed + genomic(1 | id, markers = M), family = gaussian(), REML = TRUE)
hsquared(y ~ fixed + genomic(1 | id, Ginv = Q),   family = gaussian(), REML = TRUE)
```

Opt-in dispatch for the 0.7 covered claim remains explicit
`engine = "julia", target = "genomic"` (default activation is **out of claim**;
design-44 G5 still owed before any default-route promotion).

- `markers = M` → GREML/GBLUP (engine builds \(G\)/\(K_\lambda\)), **not** SNP-BLUP.
- `single_step(...)` → **fenced to 0.8**, not auto-routed.
- REML-only Gaussian; SNP-BLUP / APY / production sparse / GPU = out of 0.7 covered claim.

## Darwin / Falconer note

Recovered quantity = **genomic-scale variance ratio on \(G\)/\(K_\lambda\)**, not silent pedigree \(h^2\).
Darwin SIGN recorded under owner #7 (`~/local-scratch/h2-07-darwin-sign-sheet.md`); closes design-41 §3 #5 only.

## Fence

- Engine supplied-`Ginv` Genomic REML **covered** ≠ R-public GREML covered until Rose CLEAN flip.
- Recovery §3 #1 for opt-in claim: **design-53 SUPERSEDE** (not a fresh R 48-seed run; design-44 G5 still owed for default activation).
- Do not execute design-43 §3 48→2000 recipe or unregularized SNP-BLUP framing as the covered claim.
- Cite DRAFT [#137](https://github.com/itchyshin/hsquared/pull/137) / [#274](https://github.com/itchyshin/HSquared.jl/pull/274) only — do not merge.
- Exact-`G` estimated-VC comparator: `docs/design/52-v07-exact-G-comparator-recipe.md`.
