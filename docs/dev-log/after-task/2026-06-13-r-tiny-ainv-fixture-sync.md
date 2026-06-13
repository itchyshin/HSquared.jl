# R Tiny Ainv Fixture Sync

Date: 2026-06-13

Active lenses: Ada, Henderson, Curie, Mrode, Grace, Rose.

Spawned subagents: none.

## Scope

Record the R twin's first tiny deterministic Ainv validation atom in the Julia
repo-visible memory.

## R Handoff

The R twin reports:

- `hsquared` commit `c161a7f`: added
  `hs_tiny_animal_validation_fixture()`;
- `hsquared` commit `fe7e346`: recorded CI evidence;
- fixture input is a three-animal calf/sire/dam pedigree, deliberately out of
  order;
- expected normalized IDs: `sire`, `dam`, `calf`;
- expected parent indices: sire `0, 0, 1`; dam `0, 0, 2`;
- expected Ainv:

```text
1.5   0.5  -1.0
0.5   1.5  -1.0
-1.0 -1.0   2.0
```

Reported evidence:

- local focused R test: 8 pass, 0 fail, 0 warnings, 0 skips;
- local full R test: 124 pass, 0 fail, 0 warnings, 0 skips;
- local `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- local `pkgdown::check_pkgdown()`: no problems;
- R-CMD-check `27457553099`: success;
- pkgdown `27457553093`: success;
- Pages `27457582221`: success.

## Julia Action

Updated:

- `docs/design/03-engine-contract.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/dev-log/check-log.md`;
- `docs/dev-log/coordination-board.md`.

No code changed. Julia already tests the same expected Ainv in
`test/runtests.jl`.

## Public Claim Audit

Allowed wording:

- shared tiny calf/sire/dam Ainv fixture exists in both twins;
- fixture covers ordering, parent indices, and the expected sparse Ainv.

Blocked wording:

- Mrode validation is complete;
- comparator validation is complete;
- production sparse fitting works;
- large-pedigree readiness is demonstrated;
- genomic/single-step validation exists.

## Next Actions

1. Add a true Mrode-style fixture with source, estimand, expected outputs, and
   row in the validation debt register.
2. Keep Ainv support marked covered only for the current tiny deterministic and
   dense-inverse checks.

Rose verdict: clean with limitations.
