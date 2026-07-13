# Handover — v0.7 boundary negative endpoint to performance arc

## Goal

Resume the still-open 0.7 genomic public-activation goal by making the
fail-closed boundary candidate output-equivalently faster, without reopening
the spent holdout or weakening any scientific gate. Only after a newly sealed
candidate passes a fresh untouched holdout may the nine-cell R-formula recovery
campaign resume.

## Start Here

1. `docs/dev-log/recovery-checkpoints/2026-07-13-v07-genomic-boundary-holdout.md`
2. `docs/design/46-v07-genomic-boundary-resolution.md`
3. `docs/dev-log/after-task/2026-07-13-v07-genomic-boundary-holdout.md`
4. Julia PR #273 and R PR #136.

Rehydrate both repositories before planning:

```sh
git -C "/Users/z3437171/Dropbox/Github Local/HSquared.jl" fetch origin
git -C "/Users/z3437171/Dropbox/Github Local/HSquared.jl" switch codex/2026-07-12-v07-optimizer-localization
git -C "/Users/z3437171/Dropbox/Github Local/HSquared.jl" pull --ff-only
git -C "/Users/z3437171/Dropbox/Github Local/hsquared" fetch origin
git -C "/Users/z3437171/Dropbox/Github Local/hsquared" switch codex/2026-07-12-v07-optimizer-localization
git -C "/Users/z3437171/Dropbox/Github Local/hsquared" pull --ff-only
```

## Frozen Result

- Julia scientific core: `ecc058f380be71058c9cfde373c345ab7a2f6aba`.
- Julia sealed execution: `d89100cd93a33d42cbaf50737d60a08f95e0658f`.
- Julia negative-endpoint evidence commit: `19127c3e`.
- R bridge/oracle frozen commit: `68e2bd06be0bcc85e9a832e3c0c327bcdc53d3a1`.
- R negative-endpoint evidence commit: `73b50dc`.
- Candidate seal: `66aadd1ec9482b8cbe874abc8f905967711f95704ebdbc956bac226fec4f70c7`.
- Manifest: `4ca4fecc8454ef5d9b79c63b87302213129a49c3c4e969b665343270eff614f3`.
- Summary gate: `4c280fcf424d0c9387ff85629e2ffac6e257c90146a6139b0864ccad3aec5bab`.
- Pair table: `8e3e7ea4214ea0230d1d1e2eef1ba8271215c71550092c000b1187b31fecc360`.
- Outcome: `BOUNDARY_HOLDOUT_FAIL`.
- Scientific subgate: 240/240 oracle agreement, 30 wins, 0 losses, net gain
  0.125, no invalid/unresolved fits.
- Runtime blocker: `n120_m600_r050` p95 ratio 5.99x versus the frozen 3x cap.
- The 240 holdout seeds are spent. Nine-cell recovery, default activation,
  public count change, G10, and release did not occur.

## Next Discriminating Arc

1. Use only already-open discovery inputs from
   `/home/snakagaw/hsq_work/v07_localization_20260712/results/discovery-5d14acd1023d`.
2. Profile wall time, allocations, and calls for Q-to-K canonicalization,
   eigendecomposition, 401-point profile evaluation, refinement, classification,
   and post-fit prediction assembly in each frozen cell.
3. Implement output-equivalent changes only: reuse decompositions/workspaces,
   remove repeated allocations, and batch/vectorize profile evaluation where
   exact dense/eigen and oracle contracts remain unchanged.
4. Re-run all 72 boundary tests, dense-versus-eigen checks, bridge parity,
   independent oracle, and deliberate mutations. Any changed classification,
   likelihood, tie/KKT rule, provenance, or fail-closed behavior blocks the arc.
5. Require the discovery timing target in every cell before preregistering a
   new candidate. Do not tune on the opened 240 holdouts.
6. Commit a new preregistration, choose a new disjoint seed block, create a new
   seal before materialization, and run the same conjunctive scientific/runtime
   gate on Totoro or DRAC—not GitHub Actions.
7. Resume end-to-end R-formula recovery only if the fresh holdout passes.

## Hard Guards

- No threshold relaxation, cell deletion, seed replacement, or reuse of the
  opened 240 holdouts.
- No default route, capability/count promotion, G10, or release while the gate
  is negative.
- Keep exact scientific endpoints separate from epsilon MME representation.
- Keep the result labelled as a genomic variance-component ratio on the
  declared `K_lambda` scale, never ordinary pedigree/population heritability.
- Keep raw campaign output local; Actions is package/docs checks only.

## Verification State

- Julia boundary tests 72/72 and full `Pkg.test()` green.
- R engine-free suite green; commit-pinned live genomic suite 265/0/0/0.
- R `R CMD check --no-manual` 0 errors / 0 warnings / 0 notes.
- Julia Documenter and R pkgdown green.
- Fisher/Darwin negative-endpoint audit: `CLEAN`.
- Rose final claim audit: `CLEAN`.
- R PR #136 CI: green.
- Julia PR #273 initially failed only on Julia 1.10/Linux because the platform's
  default `rank(X)` tolerance accepted an exactly duplicated X column. The
  precheck now freezes `rtol = sqrt(eps(Float64))`; full local Julia 1.10
  `Pkg.test()` is green. Confirm the pushed CI rerun before merge with
  `gh pr checks 273`.

## Landing State

The current arc is committed, pushed, and represented by open PRs #273 and
#136. The landing gate nevertheless fails because older local branches from
prior sessions contain commits on no remote. They were not created, switched,
edited, or interpreted in this arc. Treat them as **CARRIED-OVER / ownership
unknown**; do not delete or push them without a separate reconciliation:

```text
claude/adoring-germain-750929 (3)
codex/blupf90-packet-numeric-handoff (1)
codex/claude-cross-lane-handover (2)
codex/innovation-gate-issue-sync (1)
codex/metafounder-single-step-hgamma (1)
codex/mv-comparator-evidence (1)
codex/mv-second-comparator-target (1)
codex/mv-validation-comparator-gate (1)
codex/nongaussian-parity-fixture (3)
codex/parent-issue-ledger-sync (1)
codex/pev-reliability-ledger-closeout (1)
codex/r-extractor-status-sync (1)
feat/2026-07-01-v06-mcmcglmm-h2-comparator (3)
feat/2026-07-01-v06-ordinal-liability-h2 (3)
sim/2026-07-09-c8-mv-recovery-breadth (1)
```

Audit command:

```sh
git for-each-ref --format='%(refname:short)' refs/heads | while read -r b; do
  n=$(git rev-list --count "$b" --not --remotes 2>/dev/null || echo 0)
  [ "$n" -gt 0 ] && printf '%s\t%s\n' "$b" "$n"
done
```

## Stop Condition

If performance cannot meet the frozen runtime bar without changing scientific
output or policy, retain the negative endpoint and propose the next mechanism-
specific experiment. Do not broaden compute blindly.
