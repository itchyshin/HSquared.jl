# V4-DIRECT-MATERNAL — independent BLUPF90+ 2nd same-estimand REML comparator (2026-07-02)

Discharges the explicitly-named "OPTIONAL/owed 2nd comparator" standing debt for
`fit_direct_maternal_reml` (V4-DIRECT-MATERNAL, covered since 2026-07-02 Phase 4). This is
**ADDITIVE** evidence: no status flip, `validation_status()` count stays 53, no R-repo edit,
no `src/` change.

**Three independent programs** (HSquared.jl, `sommer` 4.4.5 leg-1, `blupf90+` 2.60 leg-2)
now converge to the **same direct–maternal 2×2 G_dm + σ²e REML optimum** on this fixture.

---

## 1. Executables (provenance)

- **`renumf90` ver. 1.166** + **`blupf90+` ver. 2.60**, Mac x86_64 (Mach-O), downloaded
  2026-07-02 from `https://nce.ads.uga.edu/html/projects/programs/Mac_OSX/64bit/renumf90`
  and `https://nce.ads.uga.edu/html/projects/programs/Mac_OSX/64bit/blupf90+`.
- Run under **Rosetta 2** on the arm64 dev Mac. `file` output: `Mach-O 64-bit executable
  x86_64`. `otool -L blupf90+` → depends only on `/usr/lib/libSystem.B.dylib` —
  statically linked, **no Intel-MKL runtime dependency** (same MKL-free path as the
  V4-MV-REML and V2-GREML comparator runs).
- Binaries placed in `comparator/bin/` (git-ignored; not committed).

---

## 2. Fixture (same data = same estimand)

- **Source:** `comparator/sommer_dm/` — the committed fixture written by
  `comparator/prepare_sommer_dm.jl` using predeclared seed **20264000** (the same seed as
  `sim/phase4_direct_maternal_recovery_gate.jl`'s `_fit`).
- **Data file emitted:** `direct_maternal.dat` — `y intercept animal_id`, 960 records,
  where `animal_id` is the own-animal's integer pedigree row (1..996).
- **Pedigree file emitted:** `direct_maternal.ped` — `animal sire dam` (integer codes,
  0=unknown), 996 animals.
- **Emitter:** `comparator/prepare_blupf90_direct_maternal.jl` (committed).

### Dam-identification verification (CRITICAL for estimand alignment)

The pedigree dam of each recorded animal (column 3 of `direct_maternal.ped`) was verified
against the `dam_id` column in `comparator/sommer_dm/dm.csv` before writing the emitter:

```
Checked 960 records, 0 mismatches (pedigree dam vs dm.csv dam_id)
```

**Conclusion:** `OPTIONAL mat` in renumf90 (which derives the maternal identity from the
pedigree's dam column) addresses **the same individual** as the engine's Z_m incidence matrix
(record→dam_id). The estimand is identical: the BLUPF90 and engine maternal effects load on
the same dam for each record. No estimand drift.

---

## 3. renumf90.par (OPTIONAL mat recipe, neutral start)

```
DATAFILE
direct_maternal.dat
TRAITS
1
FIELDS_PASSED TO OUTPUT

WEIGHT(S)

RESIDUAL_VARIANCE
1.0
EFFECT
2 cross alpha
EFFECT
3 cross alpha
RANDOM
animal
OPTIONAL
mat
FILE
direct_maternal.ped
FILE_POS
1 2 3 0 0
(CO)VARIANCES
 1.0 -0.1
-0.1  0.5
OPTION method VCE
```

**Neutral start:** G_dm = [[1.0, -0.1], [-0.1, 0.5]], RESIDUAL = 1.0. Non-degenerate
off-diagonal (avoids trapping AI-REML at a constrained diagonal model — the same isolation
discipline used for the V4-MV-REML bivariate comparator).

---

## 4. renumf90 execution

```
$ echo "renumf90.par" | comparator/bin/renumf90
 RENUMF90 version 1.166 with zlib
...
 random effect   2
 type:animal
 Optional maternal effect
 pedigree file name  "direct_maternal.ped"
 positions of animal, sire, dam, alternate dam, yob, and group     1     2     3     0     0     0     0
 Reading (CO)VARIANCES:           2 x           2
...
 Number of animals with records                  =          960
 Number of parents without records               =           36
 Total number of animals                         =          996
 Wrote parameter file "renf90.par"
 Wrote renumbered data "renf90.dat" 960 records
```

Exit 0. Generated `renf90.par` structure (key section):

```
NUMBER_OF_EFFECTS
           3
EFFECTS: POSITIONS_IN_DATAFILE NUMBER_OF_LEVELS TYPE_OF_EFFECT
 2         1 cross
 3       996 cross
 4        996 cross
 RANDOM_GROUP
     2     3
 RANDOM_TYPE
 add_an_upginb
 FILE
renadd02.ped
(CO)VARIANCES
   1.0000     -0.10000
 -0.10000      0.50000
OPTION method VCE
```

Effects 2 and 3 form a **joint RANDOM_GROUP** with type `add_an_upginb` (additive animal
with unknown parent groups and inbreeding). Effect 2 = direct (own animal, position 3 in
data); Effect 3 = maternal (dam derived from pedigree, renumf90 fills position 4 from the
`OPTIONAL mat` expansion). This is the correct direct–maternal correlated model.

---

## 5. blupf90+ AIREML execution

```
$ echo "renf90.par" | comparator/bin/blupf90+
 BLUPF90+ ver. 2.60
...
 *** Statistical method from OPTION VCE
...
 In round  1  convergence=  4.21e-02  ...
 In round  2  convergence=  2.23e-03  ...
 ...
 In round 12  convergence=  1.35e-12  delta convergence=  6.44e-07
```

Converged in **12 rounds** from the neutral start (convergence 1.35e-12, delta 6.44e-07).

**Final estimates (blupf90+ stdout):**

```
Genetic variance(s) for effect  2
   1.1328     -0.22499
 -0.22499      0.46851
   correlations
   1.0000     -0.30883
 -0.30883       1.0000
Residual variance(s)
  0.95484
```

---

## 6. Column identification

renumf90 assigns effects in the order declared in `renumf90.par`:
- Effect 2 → direct genetic (own animal id, Z_d: record→own animal row)
- Effect 3 → maternal genetic (pedigree dam of own animal, Z_m: record→dam row)

The 2×2 G block is indexed [direct, maternal]:
- G[1,1] = **σ²_ad** (direct variance, effect 2 × effect 2) = 1.1328
- G[1,2] = G[2,1] = **σ_dm** (cross-covariance) = −0.22499
- G[2,2] = **σ²_am** (maternal variance, effect 3 × effect 3) = 0.46851
- R = **σ²e** = 0.95484

This is **ABSOLUTE variance-entry identification**, not correlation-only. The correlation
(−0.30883) agrees with the engine's r_am = −0.30885 but is REPORTED only, not the
pass criterion.

---

## 7. Agreement vs engine target (absolute variance entries)

Engine target from `comparator/sommer_dm/engine_target.csv` (seed 20264000):

| component | engine | blupf90+ 2.60 | rel.diff | AGREE? |
|---|---|---|---|---|
| sigma_ad | 1.132793 | 1.13280 | 6.05e-06 | YES |
| sigma_am | 0.468503 | 0.46851 | 1.45e-05 | YES |
| sigma_dm | −0.224997 | −0.22499 | 3.25e-05 | YES |
| sigma_e2 | 0.954815 | 0.95484 | 2.61e-05 | YES |
| r_am (reported) | −0.308849 | −0.30883 | 6.05e-05 | — |

**VERDICT: AGREE** (tolerance 0.02; all four absolute variance entries within ~3e-5).

Note: The agreement (~1e-5) is tighter than the sommer leg (~1.1e-2) because BLUPF90+
uses the same AI-REML update on the same MME, whereas sommer uses a different optimizer
(Nelder-Mead REML). The BLUPF90 5-sig-fig stdout floor limits resolution beyond 1e-5.

---

## 7b. Standard-error cross-check (delta-method vs BLUPF90 AI-matrix)

An INDEPENDENT check of the new `direct_maternal_interval` (V4 asymptotic delta-method SEs,
observed-information finite-difference Hessian) against BLUPF90's own asymptotic SEs
(`sqrt(diag(inverse-AI-matrix))`, from `blupf90.log`'s "SE for G" / "SE for R"). Both are
asymptotic estimators of the SAME quantities on the SAME fixture, computed by two DIFFERENT
methods (observed vs average information), so exact agreement is NOT expected — order-10%
agreement corroborates that the delta-method interval machinery is sound.

| component | engine SE (`direct_maternal_interval`) | BLUPF90 SE (sqrt-diag inv-AI) | rel.diff |
|---|---|---|---|
| σ²_ad | 0.28649 | 0.32373 | 11.5% |
| σ²_am | 0.15240 | 0.15846 | 3.8% |
| σ_dm  | 0.16805 | 0.18652 | 9.9% |
| σ²e   | 0.12729 | 0.14331 | 11.2% |

Agreement is **~4–12% (max 11.5%)** across the four components — the delta SEs run slightly
smaller (observed-information FD-Hessian) than BLUPF90's average-information AI SEs, as
expected. BOTH are asymptotic/uncalibrated; this is a corroboration, NOT a coverage claim.

---

## 8. Evidence boundary (honest)

- This is ONE deterministic fixture (seed 20264000), confirming the REML **optimum /
  point estimate** — NOT a multi-design recovery study and NOT coverage/calibration.
- V4-DIRECT-MATERNAL is already `covered`; this discharges the named 2nd-comparator
  owed item only.
- Three independent programs (HSquared.jl, `sommer` 4.4.5, `blupf90+` 2.60) now
  converge to the same direct–maternal 2×2 G_dm + σ²e on this fixture.
- STILL OWED after this (covered does NOT retire): broader-DGP / larger-scale
  recovery; maternal-A2/metafounder generalization; calibrated intervals;
  BLUPF90 `OPTIONAL mat` for well-conditioned designs at larger n.
- The 2nd-comparator item for V4-DIRECT-MATERNAL is now **DISCHARGED** (point-estimate,
  single fixture).

---

## 9. Regeneration commands

```sh
# Step 1: regenerate the packet (reads committed sommer_dm/ fixture)
~/.juliaup/bin/julia --project=. comparator/prepare_blupf90_direct_maternal.jl

# Step 2: run renumf90
cd comparator/blupf90_direct_maternal
echo "renumf90.par" | ../bin/renumf90

# Step 3: run blupf90+ (AI-REML)
echo "renf90.par" | ../bin/blupf90+
```

Binaries: `comparator/bin/renumf90` (ver. 1.166) + `comparator/bin/blupf90+` (ver. 2.60),
downloaded from `https://nce.ads.uga.edu/html/projects/programs/Mac_OSX/64bit/`. Not
committed (git-ignored in `comparator/bin/`). Packet files git-ignored in
`comparator/blupf90_direct_maternal/`.
