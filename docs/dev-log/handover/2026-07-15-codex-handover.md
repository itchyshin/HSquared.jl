# Codex handoff — v0.7 genomic activation after Retry-4 negative endpoint

Meta: 2026-07-15 MDT · `TARGET = codex` · `AUTHOR = codex` · same-tool fresh-context handoff

This document is authoritative for resumption. It supersedes the live instructions in
`docs/dev-log/handover/2026-07-14-claude-handover.md`; historical evidence there remains
verbatim, but its live process, dirty-R-tree, and continuation instructions are stale.

## Critical Context

The v0.7 genomic public-activation arc is **not finished and not activated**. Retry 4 reached
an honest negative infrastructure endpoint:
`UNADJUDICATED — REPLAY_ENDPOINT_REPRESENTATION_BLOCKER`.

- The official R route completed 576/576 successful, converged fits.
- Independent base-R construction/recomputation completed 576/576.
- Exact Julia replay wrote 455/576 admitted rows, then four batches stopped fail-closed.
- The remaining 121 rows have no replay output; they are not 121 scientific failures.
- Five of 13 boundary packets expose a one-ULP difference between a component-derived
  ratio and the engine-declared numerical endpoint.
- No Julia summary or adjudication receipt exists. D1 and D2 never opened.
- This is not evidence of solver, KKT, gradient, convergence, or recovery failure.
- Default R routing remains held. `public_covered_count` remains **5**. Only the existing
  validation-scale supplied-`Ginv` estimator remains covered.

The immutable scientific record is
`docs/dev-log/recovery-checkpoints/2026-07-14-v07-d0f-retry4-boundary-parity-blocker.md`.
Do not repair, resume, subset, pool, or adjudicate the Retry-4 root.

## Goal and Plan

The original goal remains a merge-ready cross-twin 0.7 candidate in which the narrow
Gaussian-REML `genomic(1 | id, ...)` route is honest end-to-end: sample-frequency
VanRaden1, `K_lambda = G + 0.01I`, scale-labelled output, exact supplied-Q linkage,
independent construction, preregistered recovery, limitations, and independent audits.

The next executable plan is a **new prospective Retry-5 arc**, not a continuation of
Retry 4:

1. Preserve the engine-declared `boundary.numerical_ratio` in replay.
2. Compare the component-derived ratio separately under a frozen tolerance.
3. Classify replay-contract violations as infrastructure errors, not scientific
   `fit_error`.
4. Add lower/upper one-ULP acceptance tests and a genuine-disagreement mutation that
   remains red.
5. Run a diagnostic-only mechanism preflight over all 13 retired boundary packets plus
   representative interiors.
6. Obtain fresh exact-head reviews, deploy cleanly, preseal, and allocate disjoint seeds
   before creating any Retry-5 evidence root.
7. If Retry-5 D0F passes formally, execute the remaining preregistered D1-D4 chain,
   independent recomputation, Fisher/Darwin/Noether/Hopper/Grace reviews, and Rose audit.
8. Prepare—but do not merge—the final G10 activation/status candidate.

Estimated remaining elapsed time for a positive endpoint is **17-31 hours**: 3-5 hours
for the repair/reviews/preseal, 4-8 hours for fresh D0F and adjudication, and 10-18 hours
for downstream stages and audits if D0F passes. A scientifically clear negative endpoint
may stop earlier. Never relax a gate to meet the estimate.

## Mission Control

| Repo / surface | Main and active head | CI / live state | What shipped | Plan by leverage |
| --- | --- | --- | --- | --- |
| `HSquared.jl` | `origin/main` `ecddfa24`; branch `codex/2026-07-13-v07-performance-localization` `41219ce1` | Draft PR #274; Julia 1.10, Julia current, docs, and deploy green; opt-in live draw skipped as designed | Retry-4 negative endpoint, status sweep, checkpoint, audit; no promotion | Repair the replay endpoint contract prospectively; mutation-test it before new compute |
| `hsquared` | `origin/main` `ae6a93f2`; same branch `31befc0` | Draft PR #137; R-CMD-check green in 2m45s; working tree clean | Held public route, recovery harness, Retry-4 negative endpoint and wording; no activation | Mirror the repaired contract and validate the live R-to-Julia payload/result path |
| Totoro | immutable Retry-4 root below | No active v0.7 process at 2026-07-15 handoff; root exists | 576 official + 576 base-R diagnostics; 455 replay rows; no adjudication | Read-only diagnostic preflight only; create a new root only after prospective gates |
| DRAC / Fir | prior deployment exists but is not a Retry-5 seal | No active Retry-5 job | Earlier environment preparation only | Use only if Totoro is unavailable; never compute on a login node |
| Public activation | held | G10 absent; count 5 | supplied-`Ginv` coverage unchanged | Keep final activation/status PR separate and human-merge only |

PRs:

- Julia: <https://github.com/itchyshin/HSquared.jl/pull/274>
- R: <https://github.com/itchyshin/hsquared/pull/137>

## What Was Accomplished

- Cross-twin candidate code, recovery-v3 harnesses, exact packet locks, preseal machinery,
  independent base-R recomputation, and fail-closed Julia replay are on the active branch.
- Four failed prospective roots were retired rather than post-hoc repaired.
- Retry 4 localized the remaining blocker to endpoint representation and validator error
  classification.
- The final cross-twin status sweep, capability/debt language, check logs, checkpoint,
  and after-task report are pushed in both twins.
- Full local Julia and R checks passed before the latest push; both draft PRs are green.
- Rose's final negative-endpoint claim audit was `CLEAN`.

## Current Working State

### Julia twin

```text
repo    /Users/z3437171/Dropbox/Github Local/HSquared.jl
branch  codex/2026-07-13-v07-performance-localization
head    41219ce18279196e5f9f7a04a1af2bc0cb57b45a
remote  origin/codex/2026-07-13-v07-performance-localization (matched before handoff edits)
PR      #274 draft
```

One untracked file is deliberately quarantined:

```text
sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl
SHA-256 30838979b9f3aad7d3442204fb4a4a30345f24950000d7ecb23a20d63cad6155
319 lines
```

It is an interrupted, unreviewed scaffold. It has no sidecar, tests, or evidentiary
standing. Do not stage it with this handoff and do not treat its existence as progress.

### R twin

```text
repo    /Users/z3437171/Dropbox/Github Local/hsquared
branch  codex/2026-07-13-v07-performance-localization
head    31befc036bc390cb8e7bff85c0a1bd753b198383
remote  origin/codex/2026-07-13-v07-performance-localization (matched)
PR      #137 draft
tree    clean
```

An unrelated worktree and stash predate this handoff and were not touched:

```text
/Users/z3437171/.config/superpowers/worktrees/hsquared/nongaussian-per-record-trials
  branch claude/nongaussian-per-record-trials @ dd28132
stash@{0}: WIP on docs/2026-07-11-release-model-decoupling @ 472a50c
```

### Compute and immutable evidence

```text
Totoro root  /home/snakagaw/hsq_work/v07-genomic-recovery-v3-d0f-retry-r4-83d19e8-e5d4a0aa
R deployed   83d19e8c781292a551f9fcb2149c011a37299691
Julia deploy e5d4a0aac7473a82655032717399a465d1a6635e
Julia cand.  fc9d39df650b20aa09d769d9f9528eed1b606f1e
seeds        2036000000 / 2037000000 (permanently retired)
```

At handoff, a Totoro process probe found no active `v07_genomic` or `phase2_v07`
worker; the only `pgrep` match was the probe shell itself. The root and its locked
manifests/summaries remain present. Raw outputs remain local.

Important hashes:

```text
doc49                 0bbad8420812865d599d30af85ccf0d2fd039eada4c4914542f54dee8a9d54f0
stage preseal          3f49e658d94cb3aa64d0afdf3cafe695faac0246fb509411607bd916c317f649
manifest               f80eb2dbe14b1eb5b2db3b41acbf31d2809cdebe5a5e4d4d791eb7bdc7ba4a8f
official corpus lock   0aceb685a657b415fc30b3876b8c1698ea4088551155b75f58d4cc72a48199ba
base-R summary         2fd74065d2d8eec028eb2677293eed00609bacffb5faa66d3b7950994ac6fc07
```

The 455 admitted replay rows have maximum official-versus-replay difference
`2.2453150450019166e-12`, inside the frozen `1e-10` route-parity tolerance. This
prefix is diagnostic, not a recovery result.

## Verification State

Latest local checks before the negative-endpoint push:

- Julia `Pkg.test()` passed.
- Julia Documenter/Vitepress build passed.
- `bash tools/preamble_cap.sh` passed at one live snapshot and 7,180 bytes.
- R `devtools::document()` regenerated the expected three Rd files.
- `pkgdown::check_pkgdown()` reported no problems.
- Built-package `R CMD check --no-manual` returned `Status: OK`; missing suggested
  `pedigreemm` was informational only.
- Both after-task validators and both diff checks passed.

Latest remote checks at the handoff sweep:

- Julia 1.10: pass, 5m21s.
- Julia current: pass, 8m14s.
- Documenter: pass, 2m24s; deploy success.
- R-CMD-check: pass, 2m45s.
- No simulation/recovery campaign ran on GitHub Actions.

## Key Decisions and Rationale

- Retry-4 is immutable and permanently retired because the preseal binds the exact replay
  tool and attempted-seed denominator.
- Endpoint declarations belong to the result contract. Replay must preserve the engine
  declaration and assess rederived values under a frozen numerical tolerance.
- Validator-contract exceptions are infrastructure errors. They must not be collapsed
  into scientific `fit_error`, KKT failure, or solver failure.
- Existing supplied-Q recovery and BLUPF90 evidence remain valid only for that covered
  supplied-precision estimator; they do not activate the raw-marker R route by themselves.
- R owns public language; Julia owns computation. No unilateral public-contract change.
- Compute runs on Totoro/DRAC only, with fresh preregistration and disjoint seeds; never
  GitHub Actions.

## Landing State

`handoff_gate.sh` was run for both repos before this document was written. It returned
nonzero because of the declared Julia scaffold and pre-existing unpushed local branches
outside this arc. The active R and Julia branches themselves were pushed and had open
draft PRs. This handoff commit will update PR #274; it must not be auto-merged.

| Artifact | State | Why / resume command |
| --- | --- | --- |
| Julia active branch through `41219ce1` | LANDED: committed, pushed, draft PR #274 | Continue on the same branch after rehydration |
| R active branch through `31befc0` | LANDED: committed, pushed, draft PR #137 | Do not merge default routing |
| Retry-4 Totoro root and retired seeds | LANDED AS LOCAL DIAGNOSTIC RECORD; not evidence | Read only; use the checkpoint, never resume the root |
| `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` | CARRIED-OVER, untracked | Interrupted non-evidence scaffold. Inspect with `cd '/Users/z3437171/Dropbox/Github Local/HSquared.jl' && shasum -a 256 sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl && sed -n '1,360p' sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` |
| Julia non-current unpushed branches reported by gate | CARRIED-OVER, pre-existing and out of scope | Do not delete/rebase. Re-enumerate with `git branch --no-merged --format='%(refname:short)'` and the gate before branch cleanup |
| R non-current unpushed branches, unrelated worktree, and stash | CARRIED-OVER, pre-existing and out of scope | Do not touch. Re-run the R gate and `git worktree list && git stash list` before cleanup |

Gate-reported Julia legacy branch names:

```text
claude/adoring-germain-750929
codex/blupf90-packet-numeric-handoff
codex/claude-cross-lane-handover
codex/innovation-gate-issue-sync
codex/metafounder-single-step-hgamma
codex/mv-comparator-evidence
codex/mv-second-comparator-target
codex/mv-validation-comparator-gate
codex/nongaussian-parity-fixture
codex/parent-issue-ledger-sync
codex/pev-reliability-ledger-closeout
codex/r-extractor-status-sync
feat/2026-07-01-v06-mcmcglmm-h2-comparator
feat/2026-07-01-v06-ordinal-liability-h2
sim/2026-07-09-c8-mv-recovery-breadth
```

Gate-reported R legacy branch names:

```text
codex/a3-fit-time-plot-data
codex/genomic-target-fixture-mirror
codex/hsdata-live-marshalling
codex/innovation-issues-24-25-sync
codex/issue-10-body-sync
codex/issue-22-body-sync
codex/issue-23-body-sync
codex/issue-23-scan-sync
codex/issue-5-6-body-sync
codex/issue-5-extractor-sync
codex/issue-6-bridge-parent-sync
codex/issue-7-body-sync
codex/issue-9-roadmap-sync
codex/issue-map-close-19
codex/issue-map-close-2
codex/issue-map-close-20
codex/issue-map-close-21
codex/issue-map-close-8
codex/julia-138-mrode-sync
codex/julia-139-mrode31-sync
codex/julia-140-genomic-target-sync
codex/julia-141-pev-map-sync
codex/julia-147-validation-sync
codex/julia-148-extractor-mirror-sync
codex/julia-149-parent-ledger-sync
codex/julia-150-innovation-gate-sync
codex/julia-151-blupf90-packet-sync
codex/marker-scan-payload-fixture
codex/marker-scan-tool-availability
codex/metafounder-animal-supplied-bridge
codex/metafounder-hgamma-payload-gate
codex/metafounder-single-step-contract
codex/mi-miss-control-contract
codex/mv-published-target-scout
codex/pev-reliability-standard-fields
codex/public-claims-gwas-reconcile
codex/status-ledger-sync-144-143
codex/structured-diagonal-doc-reconcile
docs/2026-07-09-claude-handover
```

These branch lists are inventory, not authorization to mutate them.

## Files Created or Modified by This Handoff

```text
AGENTS.md
docs/dev-log/phase-snapshot-archive.md
docs/dev-log/handover/2026-07-15-codex-handover.md
docs/dev-log/after-task/2026-07-15-codex-handover.md
docs/dev-log/check-log.d/2026-07-15-codex-handover.md
docs/dev-log/coordination-board.md
```

The active branch's complete cross-twin delta remains reproducible with:

```sh
git -C '/Users/z3437171/Dropbox/Github Local/HSquared.jl' diff --name-only origin/main...HEAD
git -C '/Users/z3437171/Dropbox/Github Local/hsquared' diff --name-only origin/main...HEAD
```

## Next Immediate Steps

1. Run the `hsquared-rehydrate` skill and repeat the mandatory repo sweep in both twins.
2. Read this handoff, the Retry-4 checkpoint, doc 49 in the R twin, capability status,
   validation debt, and both draft PRs.
3. Verify that no newer commit or concurrent lane supersedes the heads recorded here.
4. Freeze a narrow Retry-5 endpoint-representation amendment before implementation.
5. Implement matching R/Julia contract changes with focused pure tests, live bridge tests,
   one-ULP acceptance controls, and a genuine-disagreement red mutation.
6. Run the 13-boundary-plus-interior diagnostic preflight against retired packets without
   modifying the root.
7. Obtain Hopper, Noether, Fisher, Grace, and Rose exact-head reviews; then clean-deploy,
   preseal, and allocate fresh disjoint seeds.
8. Run Retry-5 D0F on Totoro at no more than 96 single-threaded workers. Only a formal
   complete PASS admits D1-D4.
9. Keep activation, status promotion, and count changes held until the full chain and
   explicit maintainer G10.

## Blockers and Open Questions

- No user decision is required to start the prospective Retry-5 repair.
- The scientific blocker is the replay endpoint representation/error-classification
  contract. The compute blocker is intentionally self-imposed until the repair is sealed.
- If Retry-5 D0F fails, stop at the exact failed gate and package another honest negative
  endpoint. Do not widen compute or relax thresholds.

## Gotchas and Failed Approaches

- Green PR checks are package/docs evidence, not recovery evidence.
- Do not resume Retry-4's missing 121 replay rows.
- Do not report 121 failures; they were unattempted after batch fail-close.
- Do not recompute an engine-declared endpoint and demand bit equality across languages.
- Do not call infrastructure exceptions solver/KKT/recovery failures.
- Do not stage the untracked downstream scaffold accidentally.
- The live R bridge can be expensive; use focused filters before a full bridge-enabled run.
- `julia` may be off a non-interactive shell's `PATH`; it is installed under
  `~/.juliaup/bin`.
- Totoro's `pgrep` probe can match its own shell; inspect the command, not only the count.
- Never run simulations/recovery on GitHub Actions or store raw campaign artifacts there.

## Live Environment and Verification Recipe

Codex reads `AGENTS.md` natively and can load `.codex/agents/*.toml`; Rose is mandatory
before any public claim. From a local shell:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"
export HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl"
export NOT_CRAN=true
export JULIA_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export VECLIB_MAXIMUM_THREADS=1

cd "/Users/z3437171/Dropbox/Github Local/HSquared.jl"
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=docs docs/make.jl
bash tools/preamble_cap.sh

cd "/Users/z3437171/Dropbox/Github Local/hsquared"
Rscript -e 'devtools::test(filter="v07-genomic")'
Rscript -e 'pkgdown::check_pkgdown()'
```

For Totoro:

```sh
SOCK="$HOME/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22"
ssh -o ControlPath="$SOCK" -o ControlMaster=no totoro 'hostname; uptime'
```

Keep `OPENBLAS_NUM_THREADS=1`, Julia threads `=1`, and total Totoro concurrency at or
below 96. Use DRAC `sbatch`/`salloc`—never a login node—if Totoro is unavailable.

## How to Resume

One-command fresh Codex resume:

```sh
cd "/Users/z3437171/Dropbox/Github Local/HSquared.jl" && codex "Rehydrate from docs/dev-log/handover/2026-07-15-codex-handover.md + the AGENTS.md snapshot, then continue the Retry-5 Next Immediate Steps autonomously. Preserve the retired Retry-4 root and the quarantined untracked scaffold; do not spend a fresh seed before the repaired contract, mutation controls, exact reviews, clean deploy, and preseal are green."
```
