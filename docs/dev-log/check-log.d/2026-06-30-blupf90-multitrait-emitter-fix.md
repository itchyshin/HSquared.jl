# 2026-06-30 — Fix the BLUPF90 multitrait `renumf90.par` emitter (the 2026-06-29 follow-up)

- Goal: discharge the FOLLOW-UP flagged in `docs/dev-log/recovery-checkpoints/2026-06-29-v4-blupf90-comparator.md`
  — `comparator/prepare_blupf90_multitrait.jl` emitted a `renumf90.par` that real `renumf90` 1.166 rejects,
  forcing the manual `renumf90_fixed.par` workaround. Make the committed packet run through renumf90 directly.
- Emitter (`renum_lines`): now byte-identical to the verified-working format and to the sibling
  `prepare_blupf90_two_effect.jl` (proven end-to-end 2026-06-30) —
  (1) `DATAFILE` keyword and value (`blupf90_multitrait.dat`) on SEPARATE lines (renumf90 reads the line
  after `DATAFILE` as the filename; the old inline `"DATAFILE blupf90_multitrait.dat"` made it read `TRAITS`
  as the datafile → hard fail);
  (2) `FIELDS_PASSED TO OUTPUT` followed by a blank value-line (was `"3 4 5"`) and a new `WEIGHT(S)` +
  blank value-line — empty value-lines are how renumf90 says "none";
  (3) effect type `cross alpha` (was the invalid `cross numer`, ×2 — intercept field 3 and animal field 5);
  (4) new `FILE_POS` / `1 2 3 0 0` block after the pedigree `FILE`.
- Validator (`validate_blupf90_multitrait_packet`): dropped the now-INCORRECT blanket "no blank records"
  rejection (it would reject the correct format; added an explanatory comment so it is not reverted), split
  the `DATAFILE` required-token into `"DATAFILE"` + `"blupf90_multitrait.dat"`, and added `"FILE_POS"`.
- `#49` preflight (`test/runtests.jl`): replaced the stale-token assertions (`"3 3 cross numer"`,
  `"5 5 cross numer"`, inline `"DATAFILE blupf90_multitrait.dat"`, `FIELDS_PASSED → "3 4 5"`, and the
  `!any(isempty(strip(line)))` no-blank assertion) with the new shape — `DATAFILE` split, `FIELDS_PASSED`/
  `WEIGHT(S)` value-lines `== ""`, `cross alpha` (×2), and `FILE_POS → "1 2 3 0 0"`.

## Checks

- `julia comparator/prepare_blupf90_multitrait.jl` (julia 1.10.0) → regenerated packet; validator PASS
  (`Validated packet: 80 phenotype rows, 20 pedigree rows`). Emitted `renumf90.par` confirmed (via `cat -e`)
  byte-for-byte the verified format: `DATAFILE`/value split, two blank value-lines, `cross alpha`, `FILE_POS`.
- **End-to-end (binaries downloaded + RUN this session)**: `renumf90` 1.166 + `blupf90+` 2.60 (UGA Mac
  x86_64, Rosetta, `otool -L` → only `libSystem`, MKL-free) on the regenerated packet — `renumf90` accepts the
  emitted `renumf90.par` DIRECTLY (exit 0; wrote `renf90.par`/`renf90.dat`/`renadd03.ped`; the old
  `Data file is not found. file=TRAITS` failure is GONE), with **no `renumf90_fixed.par`**. `blupf90+` AI-REML
  (`OPTION method VCE`) → G0 `[0.60362, 0.11195; ·, 0.27036]`, R0 `[0.26311, 3.06e-4; ·, 0.090660]` (~1e-5 vs
  target). An INDEPENDENT neutral start (G0=[0.3,0.05;·,0.3], R0=[0.5,0.02;·,0.5]) converges in 7 rounds
  (9.6e-13) to the SAME optimum — so recovery is not an artifact of optimum-seeding. (Raw logs: session
  scratchpad; binaries + generated `renf90.*`/`solutions`/`renadd*.ped` are git-ignored, not committed.)
- `Pkg.test()` (julia 1.10.0) → **"Testing HSquared tests passed"**; `BLUPF90 multivariate starter packet
  preflight (#49)` → **42/42**. Plus a targeted run of the changed assertions (incl. negative checks that the
  old tokens are gone) → 12/12.
- `git diff --stat`: 2 files (`comparator/prepare_blupf90_multitrait.jl`, `test/runtests.jl`), +23/−11.
  Generated packet files stay git-ignored (`git status` clean).

## Claim boundary

Tooling / evidence-hygiene fix ONLY. No capability-status row, no validation-debt row, NO `validation_status()`
change (stays 48 rows); nothing promoted. This is NOT a new V4-MV-REML covered claim — the executed comparator
leg remains the 2026-06-29 record, and its standing recovery debts (full-sib + 3+-trait recovery, the in-suite
unstructured `sommer` test, the deep-inbreeding boundary) are unchanged. What this slice establishes: the
committed packet now runs `renumf90` → `blupf90+` end-to-end WITHOUT the manual `renumf90_fixed.par` —
CONFIRMED this session on the downloaded binaries (point-estimate reproduction on the single parity fixture).
