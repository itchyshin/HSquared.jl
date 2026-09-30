# 2026-09-29 FA eigenaxis wording

## Goal

Clarify how `genetic_pca()` and `g_max()` should be read when the largest
genetic-covariance eigenvalue is repeated. The edit changes docstrings only.

## Commands

```sh
JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia JULIA_PKG_OFFLINE=true OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 julia --project=docs docs/make.jl
python3 ~/shinichi-brain/tools/slop_check.py /Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl/docs/dev-log/source-review/2026-09-29-supplemental-panel-findings.md
git diff --check
```

The first two documentation-build attempts stopped before rendering: the first
could not write Julia's default usage lock, and the second could not write a
generated status page inside the managed worktree. The command above succeeded
from `/private/tmp/hsquared-fa-gllvm-docs-copy-20260929-codex`, copied from the
exact candidate. The copy's HEAD was
`a7ca8ed557b23ec23c8486365e97a7bac4b71c16`; final `src/evolvability.jl`
SHA-256 was `9a0779335cafe208b3bb699a06df37fb13dc93e09fa128e750282fe8f75875df`.

## Outcome

- Documenter/VitePress build exited 0 and rendered all pages.
- Existing warnings: 46 docstrings are outside canonical manual blocks;
  deployment autodetection, VitePress configuration files and favicon are
  absent; one JavaScript bundle exceeds the advisory size threshold.
- Prose check passed with 0 findings; `git diff --check` exited 0.
- No package tests were run because behavior is unchanged.

## Claim boundary

The docstrings now state that a repeated leading eigenvalue identifies a
leading eigenspace rather than one unique `g_max` direction. This does not
establish fitted-axis stability, uncertainty calibration, or FA uniqueness
identification. The FA engine and full source-review gates remain open.
