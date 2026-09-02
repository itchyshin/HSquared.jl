# Opt-in external comparators (`comparator/`)

This directory holds **opt-in, outside-CI** external comparator runners. They use a
**separate Julia environment** (`comparator/Project.toml`) so their heavy/3rd-party
dependencies (e.g. JWAS) are **never** package dependencies of HSquared.jl and are
never imported by the engine or its test suite.

## JWAS animal-model comparator (#49)

`run_jwas_animal_model.jl` fits the same single-trait animal model as the serialized
target fixture (`test/fixtures/animal_model_fitted_target/`) with **JWAS.jl** and
reports **agreement** with the engine's REML target.

```sh
julia --project=comparator comparator/setup_jwas_env.jl
HSQUARED_RUN_JWAS=true julia --project=comparator comparator/run_jwas_animal_model.jl
```

Without `HSQUARED_RUN_JWAS=true` the runner prints a skip notice and exits 0 (and
does not import JWAS).

### Honesty

- JWAS is **MCMC/Bayesian**; HSquared.jl reports **REML**. These are different
  estimators, so agreement is expected only **approximately** (shrinkage, prior,
  Monte-Carlo error). The runner reports agreement (EBV correlation + max abs
  difference); it **never** claims "parity" or "validation".
- A comparator run does **not** by itself move any capability to `covered` — the
  evidence chain (tolerance, versions, design) must be recorded first.
- The JWAS public API has shifted across releases; confirm the
  `build_model`/`set_covariate`/`set_random`/`get_pedigree`/`runMCMC` names + output
  keys against your installed JWAS version (the runner flags this inline).
- JWAS is not registered in Julia General. `setup_jwas_env.jl` adds it from
  `https://github.com/reworkhow/JWAS.jl` and writes only the local git-ignored
  `comparator/Manifest.toml`.

`comparator/Manifest.toml` is git-ignored (instantiate locally); only
`Project.toml` is committed.

## Unified comparator harness (A11)

`run_targets.jl` reads `test/fixtures/comparator_targets.toml` and runs
**validate-only** adapters for all 7 targets, with **0 silent skips**. It writes
`comparator/results/manifest.json` (schema 2).

```sh
julia comparator/run_targets.jl              # validate-only (default)
julia comparator/run_targets.jl --strict     # nonzero exit if any target reports a gap
julia comparator/run_targets.jl --no-write   # print only
```

`--run` is **refused**: no external comparator runner is wired into the unified
harness. Use the per-model opt-in runners below, each of which gates on its own
environment variable.

What it actually checks, per target:

- **Fixture integrity, not just presence.** Every required file must exist, be
  non-empty, and — for CSVs — have a header, at least one data row, a constant
  column count, and no non-finite numeric cell. A fixture that has rotted into
  `NaN` or a ragged row reports `gap`, not `validated`.
- **Fixture digests.** SHA-256 per required file plus a rollup digest over the
  sorted `(file, digest)` pairs, both recorded in the manifest.
- **Cross-lane byte parity.** The R twin freezes its mirrored fixture bytes in
  `hsquared/tests/fixtures/comparator_fixture_shas.csv`. The harness compares that
  freeze against the Julia fixtures' own digests and reports `agree`, `drift`,
  `absent`, or `uncheckable`. **Drift outranks the adapter verdict and forces
  `gap`** — two lanes comparing different bytes would agree about the wrong thing.
  Point the harness at a specific R checkout with `HSQUARED_R_ROOT`; otherwise it
  resolves a sibling `hsquared` or `hsquared-*` worktree.
- **Evidence tier, carried from the TOML.** Each target's `capability_rows`,
  `evidence_type`, `required_comparator`, and `boundary` land in the manifest,
  along with a derived `external_comparator` tier of `none`, `one_leg`, or
  `complete`. **No target reaches `complete`** — the tier exists so the manifest
  can say that rather than imply otherwise.

The manifest `summary` block therefore reports both axes: status counts, external
comparator counts, and cross-lane mirror counts.

This remains a **fixture-integrity and evidence index**. It runs no external
comparator, replaces no per-model opt-in runner, and promotes no
validation-status row. BLUPF90 unavailability for `phase4_multitrait_parity` is
documented in the R lane at
`docs/dev-log/comparator-runs/2026-09-01-blupf90-tool-unavailability.md`.

## BLUPF90/AIREMLF90 multivariate starter packet

The currently serialized comparator and bridge targets are indexed in
`test/fixtures/comparator_targets.toml`. That TOML file is the machine-readable
handoff surface for R/external lanes: it names each target fixture, required
files, associated issue/status rows, and the claim boundary. It is an index
only, not comparator evidence.

The R twin now mirrors this index at `hsquared/tests/fixtures/comparator_targets.toml`
with `tests/fixtures/comparator_fixture_shas.csv` freezing mirrored CSV bytes;
see receipt `~/local-scratch/h2-a12-fixtures-receipt.md` (A12, 2026-09-01).

Current cross-lane status:

- hsquared PR #84 (`52507da`) mirrors and consumes the
  `genomic_gblup_snpblup_target` fixture with a Julia-free R recomputation of
  supplied-frequency VanRaden `G`, `Ginv`, the supplied-variance GBLUP MME
  solution, and SNP-BLUP route agreement. This is an internal consumer check,
  not an AGHmatrix / rrBLUP / sommer / JWAS / BLUPF90 comparator.
- hsquared PR #83 (`1c239ec`) records local marker-scan comparator and
  threshold-tool availability blockers. It is blocker evidence only, not a
  marker-scan comparator run or threshold calibration.

`prepare_blupf90_multitrait.jl` rewrites the deterministic two-trait fixture
(`test/fixtures/phase4_multitrait_parity/`) into a BLUPF90-family starter
packet under `comparator/blupf90_multitrait/`.

```sh
julia comparator/prepare_blupf90_multitrait.jl
```

The generated packet contains machine-oriented whitespace-delimited
data/pedigree files (no header/comment rows), an `animal_id_map.csv` file for
aligning integer BLUPF90 animal codes back to fixture IDs, a target-covariance
CSV, and a conservative starter `renumf90.par` template for a future
RENUMF90/AIREMLF90 run. The BLUPF90 data columns are:

```text
trait1 trait2 intercept x animal_code
```

The pedigree columns are:

```text
animal_code sire_code dam_code
```

The generator validates this packet shape, pins the target covariance matrices,
and probes for local BLUPF90-family executables.

```sh
cd comparator/blupf90_multitrait
renumf90 renumf90.par
airemlf90 renf90.par
```

There is also a skip-safe runner:

```sh
julia comparator/run_blupf90_multitrait.jl
HSQUARED_RUN_BLUPF90=true julia comparator/run_blupf90_multitrait.jl
```

Without `HSQUARED_RUN_BLUPF90=true`, the runner generates and validates the
packet, prints the opt-in instructions, and exits 0 without running external
software.

Generated BLUPF90 input/output files are git-ignored. This is **not** comparator
evidence until BLUPF90-family executables are actually run, versions and
generated `renf90.par` are recorded, outputs are aligned through
`animal_id_map.csv` to the fixture targets, and a Rose audit confirms the claim
boundary.
