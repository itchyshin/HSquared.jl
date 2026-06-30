# 2026-06-30 · h² scale contract (doc-19) + genomic BLUPF90 same-estimand REML comparator

Two slices banked together (one session, `[JL]`/docs+evidence; no `src/` change, no public
default / API / R-wording change; nothing promoted to covered).

## Slice A — h² scale contract (doc-19), docs-only

- Goal: pin the cross-cutting, expensive-to-retrofit convention for how non-Gaussian
  heritability is defined/computed/**labelled**, before adding the v0.6 families — so every
  future family follows ONE scale convention.
- New `docs/design/19-h2-scale-contract.md`: the rule (never a bare `h²`; always scale-labelled
  latent/observation/liability; the family-uniform payload carries no `heritability`), the three
  scales, a per-family table (4 wired families + the convention for the owed probit/beta-binomial/
  NB2/Gamma/ordinal), the `V_fixed` asymmetry, the honesty fences. Accurate to the engine code
  (`src/nongaussian.jl:949–1092`), incl. the load-bearing trap that `π²/3` is NOT in the
  observation-scale integration variance.
- **Literature-verified** against the trusted-PDF NotebookLM source set (de Villemereuil 2016 /
  Nakagawa & Schielzeth 2017 / Dempster & Lerner 1950): confirmed (a) `π²/3` not in the
  integration variance; (b) the data-scale sampling term is `E[p(1−p)]` (engine `var_dist`),
  DISTINCT from NS's latent delta-method `1/[p(1−p)]`; (c) `h²_obs = h²_liab·z²/[p(1−p)]`;
  (d) probit latent = Gaussian liability, `V_link = 1`; (e) link variances logit π²/3, probit 1,
  cloglog π²/6. Two clarity nuances folded into doc-19.
- Not in the Documenter site (`docs/src/`), so the published-docs build is unaffected by design.

## Slice B — genomic BLUPF90+ same-estimand REML comparator (V2-GREML), evidence

- Goal: resume the paused v0.2 genomic comparator — run a same-estimand REML leg against
  `fit_gblup_reml`, the missing piece doc-18 §priority-3 flagged.
- `comparator/prepare_blupf90_genomic.jl` (tracked) generates the same-`Ginv` isolation packet
  (SEED 20260630, N=300, M=1000): `genomic.dat`, sparse `ginv.txt`, direct `renf90.par`,
  `engine_target.csv`. Generated dir git-ignored (`/comparator/blupf90_genomic/`).
- Ran `blupf90+` 2.60 (UGA download, Mac x86_64/Rosetta, `otool -L` → only libSystem; binary kept
  outside the repo at `~/blupf90_bin/`). From a NEUTRAL start (1.0, 1.0) → 6 rounds, convergence
  2.98e-13, to σ²g=0.57592 / σ²e=0.38924 / h²=0.59671 vs engine 0.575918 / 0.389244 / 0.596706 —
  agree to ~1e-5 (BLUPF90 5-sig-fig printout floor). Checkpoint
  `docs/dev-log/recovery-checkpoints/2026-06-30-v2-genomic-blupf90-comparator.md`.
- Funnel: NO new `validation_status()` row — APPENDED the executed-comparator clause to `V2-GREML`
  (point-estimate / single fixture / same-`Ginv` isolation); committed recovery study +
  `sommer`/`rrBLUP` 2nd leg + VanRaden G-construction parity (`V2-GRM`) still owed; **stays
  `partial`** (point parity does not promote). Count UNCHANGED at 48.

## Checks

- `julia comparator/prepare_blupf90_genomic.jl` → exit 0 (packet + engine target written).
- `blupf90+` 2.60 → converged, agreement ~1e-5 (above).
- `Pkg.test()` → **"Testing HSquared tests passed"** (exit 0); count-guard 48 + BLUPF90 multivariate preflight 42/42 green; no `src` edit.
- Documenter: unaffected (no `docs/src/` change; doc-19 lives in `docs/design/`).
- Real Rose claim-vs-evidence audit before PR.

## Honesty

Public-covered FITTING surface stays 1 (v0.1 Gaussian). `validation_status()` = 48 unchanged.
Nothing promoted; genomic stays `partial`. The 2 foreign never-stage files remain untracked.
