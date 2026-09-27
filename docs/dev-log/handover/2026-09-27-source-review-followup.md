# Twin FA/GLLVM source-review follow-up handover

Date: 2026-09-27. Arc boundary in the approved 0.10/0.11 programme; programme work continues. The 0.9.0 CRAN submission remains with its own lane. No GPU, DRAC run, new release submission, tag, or merge occurred. Totoro was down; all fits and checks here were short local runs with four Julia threads and one BLAS thread.

## Landing state

The Julia candidate is `codex/hsquared-fa-gllvm-20260927` at `904fa98fd9af1f49808737cddc62627d16254b9a`, pushed to its existing draft PR [#401](https://github.com/itchyshin/HSquared.jl/pull/401). The R candidate is the same branch name at `e11f2675074fdbaf68d3aa2d56b5c624df70c229`, pushed to draft PR [#259](https://github.com/itchyshin/hsquared/pull/259). Both candidate worktrees were clean and zero commits ahead of their upstreams after push. Other local branches in the underlying Dropbox repositories have unrelated unpushed commits; leave them alone.

`handoff_gate.sh` was run before this note. It returned nonzero because the programme `GATES.md` remains open and because it inventories unrelated unpushed local branches. Do not mark this live programme abandoned to make that command green. CARRIED-OVER: the open E1/V3 source-review and CI gates on these two draft branches. Resume in the Julia managed worktree at `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl` and R worktree at `/private/tmp/hsquared-fa-gllvm-20260927`, after fresh lane preflight and ownership checks.

## Verified in this slice

- Julia exact content-matched copy passed full `Pkg.test()` and docs build: `/private/tmp/hsq-fa-gllvm-pkg-test-20260927-final-exact.log` and `/private/tmp/hsq-fa-gllvm-docs-20260927-final-exact.log`. The copy's `src/`, `test/`, and docs source matched the candidate by checksum; the frozen genomic fixture was retained.
- W1-07 final-point stationarity and W1-08 structural sparse support were repaired; W2-04 rejects repeatability in an animal-only covariance LRT; W3-05 adds structured result metadata and rejects structured ML dispatch. The exact red and green receipts are in the wave packets and paired after-task reports.
- R live three-block and direct-maternal bridge checks passed with no failures or skips: `/private/tmp/hsquared-fa-gllvm-final-live-bridge-escalated.log`. Synthetic tests cover multi-fit AIC conventions, malformed block shape, and integer-control rejection. Final R `rcmdcheck` after Rose's wording correction returned 0 errors, warnings, and notes: `/private/tmp/hsquared-fa-gllvm-rcmdcheck-20260927-final-rose.log`. Pkgdown reported no problems.
- Rose's bounded claim audit is clean with limitations. Four-trait Gaussian K=1 FA and three-trait Poisson-log K=2 genetic GLLVM remain partial opt-in R routes. The public covered count remains seven. The independent fitted FA comparator covers one near-boundary fixture; the broad FA calibration protocol did not pass, with 8 of 10 scenarios meeting its criterion.

## Open findings and next sequence

1. Check current CI on Julia #401 and R #259 for the pushed commits. At this handover, Julia's four package jobs and docs job, and R's Ubuntu/Windows checks, were pending. Record the exact final status in both check logs; diagnose failures on the draft branches without touching release lanes.
2. Continue E1 with W1-09: at additive variance about `3.2e-16`, sparse MME and independent dense scores had opposite signs. Establish a fixed-point variance ladder and stable score or clear refusal before signing off boundary behavior. W1-05 and unreviewed spans remain in the wave-1 packet. Use Gauss, Noether, and Karpinski lenses, with actual reviewers named when dispatched.
3. Finish waves 2–4 source spans and the bilateral public bridge contract, then obtain Hopper/Boole/Emmy, Curie/Fisher/Mrode, numerical, and Rose panel signoff. `GATES.md` A2, E1, and V3 stay open. The CUDA extension receives static disposition only; no GPU completion claim.
4. Keep the broader 0.10/0.11 programme's ordinary-start, independent-comparator, and calibration debt visible. No automatic rank selection, non-Gaussian FA uniqueness, missing records, or response-scale GLLVM heritability is part of these bounded routes.

The R and Julia after-task reports list exact files, tests of the tests, and negative space. A run estimated above three hours still needs a pre-run result and Shinichi's approval. Stop before CRAN, Julia registry, or public release actions.
