# C1-ext / H1+H3 ADEMP predeclaration (committed BEFORE any confirm `sbatch`)

Date: 2026-09-03 · Lane: Julia engine (`cursor/09-h1-h3-harness-20260903`) ·
Status: **PREDECLARATION.** Smoke/path-proof only. Confirm array **not armed**.

Cites R-repo `docs/design/34-interval-recovery-pre-registration.md` §2–§4, §10
(C1-ext), §12. Design-36 H1/H3 = *interval-calibration campaigns*, not the
Julia-backlog non-Gaussian family IDs.

This file is the operational child of doc-34. It does **not** mutate the C1
harness or any committed C1 TSV (`--resume` stays valid there).

```
PLATFORM: cursor | LANE: cursor/09-h1-h3-harness-20260903
OTHER LANES: G5 #291 cite-only · 0.8 FA #292 cite-only · Codex DRAFT #274 cite-only
Active lenses: Ada · Shannon · Fisher · Curie · Rose fence
Spawned subagents: none
Current lane: Julia C1-ext scaffold
```

## Aim

Measure finite-sample coverage of the *already-shipped* delta / Fisher-z
intervals on covered-pillar two-effect and multi-effect ratios, plus Fisher-z
`r_g` / `r_am`. Repeatability `t` is run as **characterization only**.

No `covered` flip. No `public_covered_count` move. No `point` promotion.
A coverage result here is not a claim until Fisher maps the pooled 0.95
interior cells through doc-34 §4 and Rose + G10 sign.

## Symbolic alignment (design-36 §2.2; per-estimand, no inheritance)

| Campaign | Estimand | Interval | Scale | Covered today? | Role |
| --- | --- | --- | --- | --- | --- |
| H1-two | `ratio1` = σ1² / (σ1²+σ2²+σe²) | `two_effect_ratio_interval` | logit-delta | yes (opt-in) | covered-pillar bank |
| H1-two | `ratio2` = σ2² / total | same | logit-delta | yes (opt-in) | covered-pillar bank |
| H1-multi | `ratio1` (animal) | `multi_effect_ratio_interval` | logit-delta | yes (opt-in) | covered-pillar bank |
| H1-multi | `ratio2` (iid env) | same | logit-delta | yes (opt-in) | covered-pillar bank |
| H1-t | `t` = (σ²a+σ²pe)/total | `repeatability_interval` | logit-delta | **NO** — 2000-rep recovery FAIL | characterization only |
| H3-rg | `r_g` | `genetic_correlation_interval` `:delta` | Fisher-z | yes (t=2) | covered-pillar bank |
| H3-ram | `r_am` | `direct_maternal_interval` | Fisher-z | yes (opt-in) | covered-pillar bank |

`c²` does not inherit `h²`. `r_g` does not inherit G diagonals. Willham `h²_T`
does not inherit `r_am`. `t` does not inherit `σ²a`.

Out of this harness: genomic intervals (design-44 fence); FA / single-step
(0.8); RR `K_g` / h²(t) curve; NG `σ²a` (characterization TSV already exists).

## Data-generating mechanism

| Campaign | Smoke (path) | Screen / confirm interior | Boundary (characterization) |
| --- | --- | --- | --- |
| H1-two | half-sib 3:4:12, 4 iid groups | 8:16:96, 16 iid groups; (σ1,σ2,σe)=(1,0.5,1) | σ2=0.05 |
| H1-multi | K=2, same tiny pedigree | K=3, 8:16:96, 12+10 iid groups; (1,0.5,0.5,1) | — |
| H1-t | 2 records/id, tiny | 4 records/id, 8:16:96; (1,0.6,1.5) | records=1 not run (unidentified) |
| H3-rg | t=2, 2 records, tiny; G12=0.35 | 8:16:96, 2 records; r_g≈0.418 | G12=0.9 (`\|r\|→0.9`) |
| H3-ram | ND=3 NS=2 NOFF=4 NGEN=2 | **confirm only:** ND=30 NS=6 NOFF=8 NGEN=4 (n=960) | `|r_am|→0.9` throws → NON-INTERPRETABLE |

Groups / second environments are assigned **independently of the pedigree**
(same device as the two-effect / N-effect recovery gates). Direct–maternal
uses dams with own records + overlapping generations.

## Estimands / methods / levels

- Legs: **delta only** (logit for ratios/`t`; Fisher-z for `r_g`/`r_am`).
  No profile, no bootstrap in this driver (those legs are not shipped for
  these estimands).
- Levels: 0.95 is **promotable** after confirm + Fisher + Rose + G10.
  0.90 if emitted is **descriptive-only**.
- Coverage denominator: `interval_success`, not `reps`.
- Interpretable cell: `interval_success ≥ 0.9 · reps`. Else NON-INTERPRETABLE.
- Pooling: `coverage = Σ covered / Σ interval_success` across tasks.
  Never average per-task coverage.

## Decision rule (verbatim from doc-34; frozen)

```
measured coverage within 0.95 +/- 2*MC-SE   supports 'point' or 'directional-conservative'
[0.90, 0.94)                                 => 'directional-conservative' only
< 0.90                                       => 'experimental-only'
```

Over-coverage → `directional-conservative`, **never** `point`.
Coverage pinned at 1.000 is a simulator / clamp red flag, not a pass.
`h1_t` cannot become a covered-pillar claim whatever its coverage.

## Seeds / sample size

- Master seed default `20260903`.
- Rep seed: `master + 1_000_003·campaign_index + 10_007·cell_index + rep`.
- Future fir array stride: **40_009** (same class as C1 re-run; coprime to
  the offsets). `--reps` must stay `< 40_009`.
- Screening: 48 reps/cell (direction only; cannot set a claim).
- Confirm: ~2000 interpretable reps/cell, **not run in this slice**.
- Smoke: 1 rep, tiny interior cells. Path proof + `seff` only.

## Performance measures

Per cell: `reps / fit_success / interval_success / covered / coverage ± MC-SE /
mean_width / exclusion rate`. `claim_eligible` column is hard-false in this
scaffold. The authoritative smoke line is `GATE PATH_ONLY`.

## What a pass / fail means

- Smoke pass = the driver wrote a NEW TSV and printed `GATE PATH_ONLY`.
  It is not coverage evidence.
- Screen pass = direction. Bank a negative or schedule confirm.
- Confirm pass = a table Fisher can map. Still no silent `point`.
- Any `h1_t` result stays characterization. Do not rescue the recovery FAIL.

## Run discipline

- Driver: `sim/phase1_interval_coverage_ext.jl`
- NEW TSV only (`tmp/c1ext-<mode>.tsv` locally; `sim/drac/results/…_ext_<jobid>.tsv`
  on fir). Never append to a C1 TSV.
- `OPENBLAS_NUM_THREADS=1`. Smoke first. Confirm `sbatch` is **not armed**.
- Campaigns never run on GitHub Actions.
- Do not stage foreign untracked files. Never `git add -A`.

## Not armed

`sim/drac/phase1_interval_coverage_ext.sbatch` is a template. Do not submit
until a later G0 names a SHA, a `fir` window, and a `--time` from `seff`.
This week (2026-09-01–09-07) DRAC is in maintenance; Totoro smoke only.
