# V2-GREML / V2-GBLUP — executed BLUPF90+ same-estimand REML genomic comparator (2026-06-30)

Discharges the **"BLUPF90 VC comparator parity"** clause owed by `V2-GREML` and `V2-GBLUP`
(`docs/design/validation-debt-register.md`) **for the GREML estimator on a supplied `Ginv`**.
This is the FIRST executed BLUPF90-family genomic run as evidence (the packet was previously
generated-not-run; the v0.2 genomic comparator the maintainer paused). Independent same-estimand
REML leg. **TRIAGE → promote-on-Rose.** Nothing promoted here; this is point-estimate evidence.

## Executable (provenance)

- `blupf90+` ver. **2.60**, Mac x86_64 (Mach-O), downloaded 2026-06-30 from
  `https://nce.ads.uga.edu/html/projects/programs/Mac_OSX/64bit/blupf90+` (the canonical UGA /
  Misztal-group distribution; same source as the 2026-06-29 multivariate leg).
- Run under **Rosetta 2** on the arm64 dev Mac. `otool -L blupf90+` → depends on **only**
  `/usr/lib/libSystem.B.dylib` — statically linked, **no Intel-MKL runtime dependency**.
- Binary kept OUT of the repo at `~/blupf90_bin/blupf90+` (re-download per `provenance` above).
- `renumf90` NOT needed: the genomic packet uses a **direct** `renf90.par` (integer animal codes
  1..N already in the data; `Ginv` supplied via `RANDOM_TYPE user_file`), so there is no
  renumbering step and none of the `renumf90.par`-emitter format traps of the multitrait leg.

## Model + estimand (same as HSquared.jl `fit_gblup_reml`)

Univariate Gaussian GBLUP on a simulated genomic fixture (`comparator/prepare_blupf90_genomic.jl`,
SEED 20260630, N=300 individuals, M=1000 biallelic markers): `y = μ + g + e`,
`g ~ N(0, G·σ²g)`, `e ~ N(0, I·σ²e)`. AI-REML via `OPTION method VCE`.

**Same-estimand ISOLATION (the design point).** The engine builds the VanRaden `G` and its
regularized inverse `Ginv = inv(G + 0.01·I)`; BLUPF90 is handed the SAME `Ginv` via
`RANDOM_TYPE user_file`. So this isolates the **REML estimator on a fixed `G`** — it does NOT
re-derive `G`, deliberately separating the REML comparison from G-construction conventions
(VanRaden scaling, centering, ridge). G-construction parity (`V2-GRM`: AGHmatrix/sommer) remains
a SEPARATE owed item, untouched by this run.

## Independent convergence (the key check)

BLUPF90 started from **neutral values** (`RANDOM_RESIDUAL VALUES 1.0`, `(CO)VARIANCES 1.0`) — NOT
the engine's answer. From there `blupf90+` read 300 records + 45 150 `g_usr_inv` elements and
AI-REML converged in **6 rounds** (round-1 convergence 0.888 → final 2.98e-13) to the same REML
optimum, i.e. it found the HSquared.jl solution WITHOUT being started there.

## Agreement vs the Julia REML target (`engine_target.csv`)

| Quantity | BLUPF90+ 2.60 (neutral start) | HSquared.jl `fit_gblup_reml` | abs diff |
|---|---|---|---|
| σ²g (genetic, effect 2) | 0.57592 | 0.575917978 | ~2e-6 |
| σ²e (residual) | 0.38924 | 0.389244488 | ~4e-6 |
| h² = σ²g/(σ²g+σ²e) | 0.59671 | 0.596705735 | ~3e-6 |

The ~1e-6–1e-5 floor is the BLUPF90 **5-significant-figure stdout printout**, not the true
agreement. Both programs converge to the same supplied-`Ginv` REML optimum. BLUPF90 SE(G)=0.14744,
SE(R)=0.12139 (AI-matrix sampling variances) — reported, not compared (the engine's interval path
is a separate surface, `V1-HERIT-CI`).

## Evidence boundary (honest)

- This is ONE deterministic fixture confirming the genomic REML **optimum / point estimate** on a
  **supplied `Ginv`** — NOT a multi-design recovery study, NOT coverage/calibration, NOT a
  G-construction comparison.
- It discharges the **`BLUPF90` same-estimand REML VC parity** clause of `V2-GREML`/`V2-GBLUP` as a
  POINT ESTIMATE (single fixture, same-`Ginv` isolation). It does NOT retire: the committed
  genomic recovery study (`V2-GREML`); `sommer`/`rrBLUP`/`JWAS` legs; the VanRaden G-construction
  comparator (`V2-GRM`: AGHmatrix/sommer); sparse/APY `G`; broader marker panels.
- `rrBLUP`/`BGLR` would be agreement-only (Bayesian/estimated-variance), NOT same-estimand REML;
  BLUPF90 AI-REML is the genuine same-estimand leg (cf. doc-18 §comparator inventory). `sommer`
  could add a second REML leg on the same `Ginv` (owed).
- **Nothing promoted.** Genomic stays `partial`; public-covered FITTING surface stays 1 (v0.1
  Gaussian). A covered move needs the recovery study + a Rose audit + maintainer G10 — not this
  point estimate alone.

## Reproduce

```sh
julia --project=. comparator/prepare_blupf90_genomic.jl          # regenerate packet + engine_target.csv
cd comparator/blupf90_genomic
echo renf90.par | arch -x86_64 ~/blupf90_bin/blupf90+            # AI-REML (Rosetta); reads ginv.txt
# compare "Final Estimates" → engine_target.csv
```

Generated packet (`comparator/blupf90_genomic/`: `genomic.dat`, `ginv.txt`, `renf90.par`,
`engine_target.csv`, `blupf90_run.log`, `solutions`, …) is git-ignored; the binary lives outside
the repo. The tracked artifact is `comparator/prepare_blupf90_genomic.jl`. Full run log:
`comparator/blupf90_genomic/blupf90_run.log`.
