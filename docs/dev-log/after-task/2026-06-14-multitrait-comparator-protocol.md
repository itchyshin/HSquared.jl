# 2026-06-14 Multi-Trait Comparator Protocol

## Task Goal

Make the shared Phase 4 multi-trait fixture easier and safer for the R lane to
use in future sommer/ASReml/BLUPF90/JWAS comparator work.

The fixture already existed. This slice adds an explicit comparator protocol and
syncs status surfaces so "a protocol exists" is not mistaken for "external
comparator parity exists".

## Active Lenses And Spawned Agents

- Shannon: R/Julia lane boundary and issue handoff.
- Curie/Fisher/Mrode: estimator target and comparator-evidence hygiene.
- Rose: claim-vs-evidence boundary.
- Grace: checks and audit trail.
- Spawned agents: none.

## Files Changed

- `test/fixtures/phase4_multitrait_parity/README.md`
- `docs/dev-log/decisions/2026-06-14-multitrait-comparator-protocol.md`
- `src/validation_status.jl`
- `test/runtests.jl`
- `docs/src/validation-status.md`
- `docs/src/multivariate-models.md`
- `docs/src/changelog.md`
- `ROADMAP.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/design/06-public-claims-register.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.md`
- this report

## What Landed

The fixture README now records:

- the exact bivariate Gaussian animal-model target;
- the REML covariance structure (`A x G0` for animal effects and
  record-independent `R0` residual blocks);
- the requirement to rebuild `A`/`Ainv` from `pedigree.csv`;
- the full REML likelihood-scale caveat;
- the comparator package/version/control/convergence reporting checklist;
- the rule that no external-comparator tolerance is committed by the fixture
  itself.

The decision note at
`docs/dev-log/decisions/2026-06-14-multitrait-comparator-protocol.md` gives the
same protocol as a durable handoff record for the R lane.

## Checks Run

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
  - Phase 0 scaffold/validation-status block is now 169 checks after adding
    the `comparator protocol` assertions for `V4-MV-REML`.
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: passed.
  - Known caveats remained: 8 docstrings not included in the manual; local
    deployment skipped outside CI; VitePress default config substitutions;
    missing local logo/favicon/package.json substitutions; 4 npm audit
    advisories in generated docs dependencies.
- `git diff --check`: passed.
- Protocol/boundary scan found the intended `comparator protocol` wording
  together with explicit `no external comparator parity` boundaries.

## Public Claim Audit

Allowed:

- a deterministic Julia target fixture exists for future R-lane multi-trait
  comparator work;
- a comparator protocol now exists for that fixture;
- `V4-MV-REML` remains partial.

Blocked:

- no sommer, ASReml, BLUPF90, JWAS, DMU, or WOMBAT parity exists yet;
- no external comparator tolerance is committed;
- no validation row moved to covered or covered_external;
- no R-facing multivariate syntax exists;
- no bridge payload or `result_payload()` change exists;
- no covariance SE/LRT, multi-seed calibration, production sparse
  multivariate fitting, or GPU execution is claimed.

## Tests Of The Tests

`test/runtests.jl` now requires `V4-MV-REML` evidence to mention
`comparator protocol`, making future validation-status rewrites preserve the
handoff artifact.

## Coordination Notes

No R repository code was edited. The intended R-lane next step is to run an
external comparator against the CSV fixture and report package versions,
commands, convergence, likelihood scale, observed differences, and a proposed
committed tolerance on the coordination issue.

## What Did Not Go Smoothly

Nothing material. The only mild friction is the usual local absence of `gh`,
so remote issue/PR coordination continues through the GitHub connector or the
credential-backed API path.

## Known Limitations

- This is not external comparator evidence.
- The fixture is balanced and two-trait; it does not cover missing-trait
  comparator behavior.
- The protocol does not choose a tolerance; tolerance belongs to the actual
  R-lane comparator run.

## Next Actions

1. Post a coordination note to the Julia PR / issues after the branch is pushed.
2. Ask the R lane to use this protocol for sommer/ASReml/BLUPF90/JWAS parity.
3. Keep `V4-MV-REML` partial until actual comparator evidence is recorded.
