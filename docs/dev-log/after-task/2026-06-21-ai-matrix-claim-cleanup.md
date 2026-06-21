# After-task — AI-matrix claim cleanup (#38)

Date: 2026-06-21. Lane: Julia engine (`HSquared.jl`). Branch:
`codex/ai-matrix-claim-cleanup`. Type: claim-hygiene documentation slice.

## Live Phase Snapshot

As of this report, Julia `main` is `b657464` after the BLUPF90 multivariate
preflight harness (#132), with post-merge CI and Documenter green. This slice
addresses the R-lane flagged stale AI-matrix wording in
`docs/design/03-engine-contract.md`. It does not change code, tests, or the R
repository.

## Goal

Remove ambiguity around the average-information REML validation claim and point
readers to the committed tiny-fixture gate instead of an uncommitted
250-animal/0.99 simulation note.

## Active Lenses

Rose checked claim-vs-evidence language. Fisher + Gauss checked that the
observed-information wording refers to the finite-difference REML Hessian of the
same log-likelihood. Shannon kept this as a Julia-repo response to an R-lane
request. No subagents were spawned.

## Files Changed

- `docs/design/03-engine-contract.md` — rewrites the AI-matrix sentence to say
  the matrix matches an independent finite-difference REML Hessian of the same
  log-likelihood to within ~8% on the committed tiny fixture
  (`test/runtests.jl`, `rtol = 0.12`).
- `docs/dev-log/check-log.d/2026-06-21-ai-matrix-claim-cleanup.md`

## Commands / Results

- `rg -n "250-animal|0\\.99|eigen-G|eigen G|AI matrix matches" docs/design/03-engine-contract.md`
  — passed for the stale-claim audit; no 250-animal, 0.99, or eigen-G wording
  remains in the design doc.
- `julia --project=docs docs/make.jl` — passed, with existing local-build
  warnings for omitted internal docstrings, skipped deployment detection,
  default Vitepress assets, and npm audit output.
- `git diff --check` — passed.

## Public Claim Audit

Clean with limitations. The claim remains limited to a committed tiny-fixture
information-matrix agreement check for the Gaussian two-component AI-REML path.
This is not a broad large-pedigree performance claim, not non-Gaussian AI-REML,
and not new validation evidence.
