# V4-DIRECT-MATERNAL covered evidence — gate PASS + sommer covm() comparator AGREE (2026-07-01)

Both doc-16 covered legs for the direct–maternal genetic-covariance REML estimator
(`fit_direct_maternal_reml`, `src/likelihood.jl:1311`) — the FIRST CORRELATED random-effect
structure (`σ_dm ≠ 0`, a 2×2 `G_dm` over `[a_d; a_m]`) — are satisfied. Banks the evidence for
the `partial → covered` flip (engine / validation-scale, opt-in) and, paired, the R public
surface (`target="direct_maternal"` / `maternal_genetic()`). This is the highest-overclaim-risk
flip in the plan because the estimand is correlated: the covered claim is fenced accordingly
(§Scope).

## Leg 1 — PRE-DECLARED 48-seed bias/MCSE recovery gate: PASS

- Predeclaration committed **before** the run: `76f6c67e`
  (`docs/dev-log/recovery-checkpoints/2026-07-01-direct-maternal-recovery-gate-predeclaration.md`),
  after a pre-run diagnostic right-sized the DGP to BREAK the direct–maternal confound (the
  load-bearing design point — see the predeclaration §"Breaking the direct–maternal confound":
  dams with both their own record AND ≥8 recorded offspring, 4 overlapping generations, shared
  sires). Harness `sim/phase4_direct_maternal_recovery_gate.jl` **byte-identical pre/post** the run
  (`git diff 76f6c67e HEAD -- sim/phase4_direct_maternal_recovery_gate.jl` empty → no relaxation).
- DGP: n=960 records, q=996 pedigree animals, 90 identifying dams (own record + recorded
  offspring), within the dense-oracle scale fence; truth σ²_ad=1.0, σ²_am=0.5, σ_dm≈−0.2121
  (r_am_truth=−0.3), σ²e=1.0; seeds fixed in the predeclaration; cold start.
- **Result: 48/48 converged; all four `|bias| ≤ 2·MCSE`:**

  | component | mean | truth | bias | MCSE | \|bias\|/MCSE |
  | --- | --- | --- | --- | --- | --- |
  | σ²_ad | 0.99328 | 1.00 | −0.00672 | 0.05235 | 0.13 |
  | σ²_am | 0.53987 | 0.50 | +0.03987 | 0.02411 | 1.65 |
  | σ_dm  | −0.23399 | −0.2121 | −0.02186 | 0.03052 | 0.72 |
  | σ²e   | 0.99398 | 1.00 | −0.00602 | 0.02535 | 0.24 |

  r_am REPORTED (not gated): mean −0.26568 vs truth −0.30. Read as **NO DETECTABLE across-seed
  bias** (the noisiest component, maternal variance σ²_am, at 1.65·MCSE), never "unbiased".
  Diagnostics: max condition number 157.17 (finite/well-conditioned across all 48 seeds), max
  |r_am| 0.80225 (no seed rode the ±1 boundary), mean walltime 61.964 s/seed. EBV accuracies:
  direct 0.6665, maternal 0.7588.

## Leg 2 — same-estimand external REML comparator (`sommer` 4.4.5 `covm()`): AGREE

- `comparator/prepare_sommer_dm.jl` reconstructs a direct–maternal dataset + records the engine
  optimum; `comparator/run_sommer_dm.R` fits the SAME model via sommer's IGE (indirect-genetic-
  effect) pattern
  `random = ~ covm( vsm(ism(animal), Gu=A), vsm(ism(dam_id), Gu=A) )`, `rcov = ~units`.
- **Construction trap (why the RR idiom does NOT transfer):** the k=2 RR comparator used
  `usm(leg())` because both basis functions load on the record's OWN id. Here the maternal
  coefficient loads on the **dam's** id, not the record's own animal — a different incidence
  matrix (`Z_m` = record→dam). sommer's `covm()` IGE construction merges two random terms with
  DIFFERENT incidence matrices (`ism(animal)` = `Z_d`, `ism(dam_id)` = `Z_m`) over the same
  pedigree `A` and estimates the unstructured 2×2 covariance between them — exactly `G_dm`. Using
  the RR `usm(leg())` idiom here would fit the WRONG model.
- **Column-identification check (the load-bearing trap):** the run script explicitly identifies
  which varcomp is σ²_ad (direct, on `animal`/own id), which is σ²_am (maternal, on `dam_id`), and
  which is σ_dm (cross-covariance), and compares the ABSOLUTE variance entries (NOT correlation-
  only, which would be a false pass). Column-check passed: ran1 = direct/own, ran2 = maternal/dam.
- **Result: AGREE — all entries + σ²e match (seed 20264000):**

  | component | rel.diff |
  | --- | --- |
  | σ²_ad | 4.2e-3 |
  | σ²_am | 2.8e-3 |
  | σ_dm  | 1.1e-2 |
  | σ²e   | 2.2e-3 |

  Both maximize the same REML likelihood on the same data (single-seed point-estimate leg,
  complementary to the 48-seed gate). The larger residual (~1e-2 vs the RR/N-effect ~1e-5) is
  expected for the correlated off-diagonal σ_dm and still well inside same-estimand agreement.

## Engine correctness (G1/G2, `test/runtests.jl:5987`)

- **G1 reduction:** with a diagonal `G_dm` (`σ_dm = 0`), `_direct_maternal_dense` is byte-identical
  (~1e-9) to the two-independent-effect model `[(Zd,A),(Zm,A)]` — the correlated kernel collapses
  correctly to the independent case.
- **G2 oracle:** a full 2×2 `G_dm` (including a NEGATIVE off-diagonal) matches an independent
  marginal-GLS oracle for β and both BLUP vectors (~1e-9, observed ~1e-15); the fit returns a PD
  `G_dm` and `r_am ∈ [−1, 1]`, and on tiny/non-identified data honestly reports `converged=false`
  / boundary `r_am`.

## Scope of the covered claim (direct–maternal 2×2 `G_dm`)

`fit_direct_maternal_reml` correctly implements the direct–maternal 2×2 `G_dm` REML (correlated
`[a_d; a_m]` over one relationship `A`, + homogeneous σ²e) on the tested confound-broken identified
design (dense/validation-scale, n ≤ ~1000). Fences:

- **Validation-scale, OPT-IN** — this is `engine="julia", target="direct_maternal"`
  (`maternal_genetic()`), **NOT** the public default `engine="fit"` path (which is unchanged).
- **Direct h² ≠ total h² (Willham).** Direct h² (`σ²_ad/σ_P`) is NOT "the heritability"; the
  selection-relevant total additive variance involves `σ_dm`. `σ_P = σ²_ad + σ²_am + σ_dm + σ²e`
  (Willham). The R surface returns the labelled triple (direct h², m², Willham total h²_T), never a
  bare scalar. A negative `r_am` is real and expected.
- **`|r_am| → 1` rides on `converged`** — near-boundary fits self-report `converged=false`; the
  covered claim is on well-conditioned identified designs (max cond 157, max |r_am| 0.80 across the
  48 gate seeds).
- **Single relationship matrix `A`** — one pedigree `A` shared by both legs; NOT the maternal-A2
  (separate maternal-permanent-environment / metafounder) generalization.
- "Covered" = the engine correctly implements direct–maternal 2×2-`G` REML on the tested design,
  NOT small-sample accuracy of any single component.

**Standing debt (covered does NOT retire):** a 2nd independent same-estimand REML comparator on a
different lineage (`blupf90+` AIREMLF90 2×2-G is OPTIONAL/owed; WOMBAT not installed); broader-DGP /
larger-than-dense-scale recovery; the production sparse AI-REML path; a Mrode Ch.7 fitted textbook
anchor.

Maintainer G10 delegated ("flip autonomously once evidence passes"); real `rose-systems-auditor`
audit on the flip before promotion. `public_covered_count` 4 → 5 is the R-public surface (the 5th
public-covered model; engine-covered ≠ R-public-covered layering — see
`docs/design/06-public-claims-register.md`).

## Harness header note

`sim/phase4_direct_maternal_recovery_gate.jl` carries illustrative header comments
(NOFF=6, 3 overlapping generations, 3-seed example) that are SUPERSEDED by the locked
constants at L88–94 of the same file (NOFF=8, NGEN=4, the 48 actual seeds) and by the
predeclaration document
`docs/dev-log/recovery-checkpoints/2026-07-01-direct-maternal-recovery-gate-predeclaration.md`.
The harness itself MUST remain byte-identical to commit `76f6c67e` (the predeclared artifact);
the header text is informational only and does not affect the run results. The locked
constants and the predeclaration are the authoritative DGP specification.
