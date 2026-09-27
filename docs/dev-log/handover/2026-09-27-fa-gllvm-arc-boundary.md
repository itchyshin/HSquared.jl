# Session Handoff: FA, genetic GLLVM, and source review

Meta: 2026-09-27 22:14 UTC; Codex to the next Codex, Claude, or Cursor lane. The approved programme goal remains active.

## Critical Context

The two draft PRs contain working, bounded opt-in R routes for four-trait Gaussian FA with one genetic factor and three-trait Poisson genetic GLLVM with two factors. Neither route is a broad capability or release candidate. Julia source-review waves and final panel signoff remain open. The public covered count remains seven; both package versions remain 0.9.0. The 0.9.0 CRAN submission is in a separate review lane. Do not submit, tag, or merge from this handoff.

Work only in the candidate worktrees below. The original Dropbox checkouts have independent dirty or diverged work. Run the lane preflight and `--file` ownership check before editing. Read `GATES.md` and the four `docs/dev-log/source-review/2026-09-27-wave*.md` packets before claiming a wave complete. The older `LOOP/GOAL.md` and September 7 handover describe earlier campaigns.

## What Was Accomplished

- Added the opt-in R FA and GLLVM routes, examples, status and validation-debt rows, symbolic contracts, invariant and independent tiny-model checks, and live R and Julia parity. The default R formula grammar and unsupported model cells remain fenced.
- Repaired a measured intercept-shift cancellation error in four Julia likelihood paths; rejected invalid relationship precision even when the marginal covariance is positive definite; and repaired bridge pedigree ordering, the maternal alias, and lone `iid` dispatch. Added an R FA pedigree-ID guard.
- Reviewed all 24 tracked Julia `src/` files in four packets. The packets distinguish complete spans, partial spans, fixed findings, and open findings. No CUDA execution occurred.
- Final local candidate evidence: Julia `Pkg.test()` passed on a content-matched writable copy; Julia docs built; R `rcmdcheck` ended `Status: OK`; both preamble caps passed. The exact commands, logs, and limits are in `GATES.md` and both check logs.

FINDING-OF-RECORD: mixed-model likelihood invariance and invalid-prior fixtures found defects that ordinary successful fits did not reveal; the canonical candidate is Julia PR #401 at the SHA below. vault-note: [[WHAT-WORKS]]

## Current Working State

- Working: the bounded FA and genetic GLLVM R fits and their checked local candidate branches.
- In progress: source-review closure, independent panel verdicts, and GitHub CI.
- Open: `GATES.md` A2, E1, and V3. No experimental-to-covered flip is justified by this evidence.
- Compute: Totoro is down per Shinichi. Short local tests used `OPENBLAS_NUM_THREADS=1` and `JULIA_NUM_THREADS=4`. Route a serious CPU campaign to DRAC with a queued job; estimate every run first, and seek approval after a pre-run for an estimate above three hours. No GPU work is in scope.

## Key Decisions and Rationale

The fixed K=1 FA and K=2 GLLVM cells are acceptance anchors. `d="auto"` is a separate, later usability validation task. GLLVM reports trait-level conditional modes on the link scale, not factor scores as breeding values. Its reported objective is the fixed-and-genetic-effect integrated Laplace objective. FA uniqueness estimates carry their local identification limits. These boundaries follow the approved plan and the two symbolic-contract documents; this session made no new vault decision.

## Landing State

The pre-handoff `NO_PR=1 tools/handoff_gate.sh` exited 1 because the active programme ledger has three open gates and shared Git metadata exposes 181 older unpushed Julia branches and 86 older unpushed R branches. The two current candidate branches are clean and pushed. Those older branches belong to other lanes and are **PROTECTED**; do not sweep or land them as part of this campaign.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| Julia `codex/hsquared-fa-gllvm-20260927` at `9b5f3a224c974f4f42fd525c04ba8743dc252a8a` | yes | yes | [#401](https://github.com/itchyshin/HSquared.jl/pull/401), draft | CARRIED-OVER: A2/E1/V3 and CI pending |
| R `codex/hsquared-fa-gllvm-20260927` at `ddc5155482695b086a982d4355f6abb2e8664217` | yes | yes | [#259](https://github.com/itchyshin/hsquared/pull/259), draft | CARRIED-OVER: coordinated review and CI pending |
| Original Dropbox checkouts and unrelated shared Git branches | mixed | mixed | outside this campaign | PROTECTED: preserve their owners' work |

Resume both carried branches with the commands below. Both draft PRs remain unmerged and unreleased.

## Next Immediate Steps

1. Check PR #401 and #259 CI. At 22:12 UTC Julia run `36354097983` had Windows Julia 1.10 running and other jobs queued; Julia docs run `36354098029` and R run `36354106911` were queued. Fix a failure in the owning branch and rerun affected local gates.
2. Close the source-review packets on a freshly pinned candidate. Wave 1 still owes W1-05 SIMD fit comparison, W1-07 final-score/stationarity validation, and unreviewed likelihood/genomic spans. Wave 2 carries W2-02/04/05/07/08/09 and independent whole-wave numerical verdict. Wave 3 carries W3-05 v2 result-shape reconciliation, unreviewed pedigree/data spans, and full bridge verdict. Wave 4 needs status-page integration and independent numerical/claims verdict. Read each packet for the precise source ranges and evidence limits.
3. Obtain Gauss/Karpinski/Noether, Hopper/Boole/Emmy, Curie/Fisher/Mrode, Kirkpatrick, and Rose panel verdicts for the relevant cells. Update capability/debt rows, check logs, and after-task reports against the final commits. Keep `GATES.md` open until its stated evidence is met.

## Blockers / Open Questions

There is no user-input blocker for the next read-only review or a short local verification. A simulation estimated above three hours needs its pre-run result and Shinichi's approval. CI and panel review may reveal further code work. Do not substitute an identity-relationship GLLVM reduction for a same-objective external comparator.

## Gotchas and Failed Approaches

- The sandbox cannot write Julia's shared `~/.julia/logs/manifest_usage.toml.pid`; escalated local-cache runs passed. The docs generator cannot write into the managed checkout, so the passing docs build used a writable content-matched copy. See `GATES.md` for the proof of source/test equality.
- Fixed-variance responses shifted by `1e8` broke the old sparse likelihood despite a stable dense reference. Preserve the new regression before changing quadratic forms.
- An indefinite precision can yield a positive-definite marginal covariance. Validate the prior precision directly.
- Do not take the old historical `AGENTS.md` phase snapshot or `LOOP` files as current programme state. `ROADMAP.md`, capability status, `GATES.md`, and the candidate source decide current claims.

## How to Resume

```sh
cd '/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl'
bash /Users/z3437171/shinichi-brain/tools/lane_preflight.sh .
git status --short --branch
gh pr checks 401 --json name,state,link
sed -n '1,180p' GATES.md
cd /private/tmp/hsquared-fa-gllvm-20260927
bash /Users/z3437171/shinichi-brain/tools/lane_preflight.sh .
git status --short --branch
gh pr checks 259 --json name,state,link
```

Before editing a file, run the preflight with `--file PATH` in its repo. Reconcile this dated handoff against current commits and classify work as OWED, DONE, RETRACTED, or PROTECTED.
