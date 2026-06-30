# V4-MV-REML — executed BLUPF90+ 2nd same-estimand REML comparator leg (2026-06-29)

Discharges the V4-MV-REML standing-debt item "an executed 2nd same-estimand REML comparator
(ASReml/BLUPF90/DMU/WOMBAT)". This is the FIRST executed BLUPF90-family run as evidence (the packet
was previously preflighted-not-run). Independent of the existing `sommer` leg. **TRIAGE → promote-on-Rose.**

## Executables (provenance)

- `renumf90` ver. **1.166** + `blupf90+` ver. **2.60**, Mac x86_64 (Mach-O), downloaded 2026-06-29 from
  `https://nce.ads.uga.edu/html/projects/programs/Mac_OSX/64bit/{renumf90,blupf90+}`.
- Run under **Rosetta 2** on the arm64 dev Mac. `otool -L blupf90+` → depends on **only**
  `/usr/lib/libSystem.B.dylib` — statically linked, **no Intel-MKL runtime dependency** (the MKL-free path;
  the `Linux/Test_static/` build is the fir equivalent if needed).

## Model + estimand (same as HSquared.jl / sommer)

Bivariate Gaussian animal model on `test/fixtures/phase4_multitrait_parity/`: `trait_k ~ intercept_k +
beta_x,k·x + animal_k + e_k`, `vec(animal) ~ N(0, A⊗G0)`, `vec(e) ~ N(0, I⊗R0)`. AI-REML via
`OPTION method VCE`. Same estimand as the Julia dense multivariate REML.

## Packet bug found (and worked around)

The committed `prepare_blupf90_multitrait.jl` writes `renumf90.par` with the datafile name INLINE
(`DATAFILE blupf90_multitrait.dat`); renumf90 requires the keyword and value on SEPARATE lines and read
`TRAITS` as the datafile name → hard fail. Also the EFFECT type was `numer` (should be `alpha`) and
`FILE_POS` was absent. Corrected starter = `comparator/blupf90_multitrait/renumf90_fixed.par` (DATAFILE on
its own line, `cross alpha`, `FILE_POS 1 2 3 0 0`). **FOLLOW-UP: fix the prepare script's `renumf90.par`
emitter** (separate-line keyword/value; `cross alpha`; FILE_POS). Independent of this comparator result.

**RESOLVED 2026-06-30:** the emitter now writes the correct format directly (`DATAFILE` keyword/value on
separate lines; blank `FIELDS_PASSED TO OUTPUT`/`WEIGHT(S)` value-lines; `cross alpha`; `FILE_POS 1 2 3 0 0`),
byte-identical to `renumf90_fixed.par` and to the sibling `prepare_blupf90_two_effect.jl`. The `#49` preflight
was updated to the new tokens and `Pkg.test()` passes (preflight 42/42). CONFIRMED end-to-end: `renumf90`
1.166 + `blupf90+` 2.60 (re-downloaded from UGA this session, Mac x86_64/Rosetta, MKL-free) were RUN on the
regenerated packet — `renumf90` accepts the emitted `renumf90.par` directly (exit 0; the `Data file is not
found. file=TRAITS` failure is gone), with NO manual `renumf90_fixed.par`, and `blupf90+` AI-REML converges
from a neutral start in 7 rounds to the fixture optimum (G0/R0 ~1e-5). See
`docs/dev-log/check-log.d/2026-06-30-blupf90-multitrait-emitter-fix.md`.

## Independent convergence (the key check)

A degenerate start with the off-diagonals at exactly 0 makes AI-REML keep them at 0 → it fits a CONSTRAINED
DIAGONAL model (G0 diag 0.584/0.265, no covariance) — the wrong estimand. The valid independent test uses a
**non-degenerate neutral start**: G0 = [0.3, 0.05; 0.05, 0.3], R0 = [0.5, 0.02; 0.02, 0.5]
(`renf90_neutral2.par`). From there `blupf90+` converged in **7 rounds** (final convergence 9.6e-13) to the
full unstructured optimum — i.e. it found the same REML solution as HSquared.jl WITHOUT being started there.

## Agreement vs the Julia REML target (`expected_*.csv`)

| Quantity | BLUPF90+ 2.60 | Julia REML target | max abs diff |
|---|---|---|---|
| G0[1,1] | 0.60362 | 0.6036285 | ~7e-6 |
| G0[1,2] | 0.11195 | 0.1119503 | ~3e-7 |
| G0[2,2] | 0.27036 | 0.2703534 | ~7e-6 |
| R0[1,1] | 0.26311 | 0.2631124 | ~2e-6 |
| R0[1,2] | 0.00030622 | 0.0003079 | ~2e-6 |
| R0[2,2] | 0.090660 | 0.0906582 | ~2e-6 |
| β intercept (t1/t2) | 4.00363915 / 7.06339959 | 4.00363863 / 7.06339960 | ~5e-7 |
| β x (t1/t2) | 0.45565802 / −0.31597772 | 0.45565800 / −0.31597774 | ~2e-8 |
| EBV trait1 | — | — | corr **1.000000**, max\|Δ\| 3.34e-6 |
| EBV trait2 | — | — | corr **1.000000**, max\|Δ\| 2.67e-7 |

EBVs aligned via `renadd03.ped` (renumbered → original) → `animal_id_map.csv` (original code → fixture
id), n=20. **The ~1e-5 floor on G0/R0 is the BLUPF90 5-significant-figure stdout printout, not the true
agreement** (β/EBV, printed to more digits, agree to ~1e-7).

## Evidence boundary (honest)

- This is ONE deterministic fixture (the two-trait parity target), confirming the REML **optimum / point
  estimate** — NOT a multi-design recovery study and NOT coverage/calibration. V4-MV-REML was already
  `covered`; this is additive hardening that discharges the 2nd-comparator owed item.
- Three independent programs (HSquared.jl, `sommer` 4.4.5, `blupf90+` 2.60) now converge to the SAME
  multivariate REML optimum on this fixture. `sommer` and BLUPF90 are same-estimand REML (not Bayesian).
- STILL OWED after this (covered does NOT retire): full-sib + 3+-trait recovery; the in-suite unstructured
  `sommer` skip-guarded test; the deep-inbreeding boundary. (The 2nd-comparator item is now DISCHARGED.)
- Binaries + generated `renf90.*`/`solutions` are git-ignored; `renadd03.ped`/`blupf90.log` and the
  documenting `renumf90_fixed.par`/`renf90_neutral2.par` are untracked-not-ignored — none are committed
  (extend `.gitignore` if a future run should auto-ignore them). Full log: scratchpad `blupf90_neutral_run.log`.
