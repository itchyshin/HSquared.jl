# Automatic genetic FA-rank implementation checkpoint

Status: programme active. Julia and R focused, mandatory-live and full package checks pass; final programme acceptance is still open. Independent source review awaits explicit payload authorization. This report does not close the goal.

## 1. Goal

Complete the approved paired Julia/R automatic genetic FA factor-count programme with Ultra Plan and Unlazy. Users compare K0 and K1, inspect the complete evidence and receive a selected fit or an explicit refusal/unavailable outcome. The whole paired outcome governs completion across arcs.

## 2. Implemented

Added Julia `select_fa_rank` for complete four-trait Gaussian pedigree observations, trait intercepts and one record per observed animal. K0 is diagonal genetic covariance with a private matched floor; K1 is one shared genetic factor plus uniqueness. Both retain an unstructured residual covariance. The original public fixed-rank diagonal mapping stays intact.

Added the explicit R expert control `engine = "julia"`, `target = "multivariate"`, `rank_selection = "auto"`, a selection object, complete candidate/attempt tables, diagnostics and an ordinary nested `hsquared_fit`. The nested fit preserves the user's parsed specification and call. JuliaCall transport retains ragged parameter vectors, covariance matrices, missing values and failed starts. Cancellation propagates through a request-local ledger and the request Ref is cleared after return or interruption. Parent audit strengthened full plain-R partial-ledger transport: the production reader now serializes and normalizes the real engine snapshot before cleanup.

## 3a. Decisions and Rejected Alternatives

Retained the reviewed common-X REML covariance comparison: nominal parameter counts 14 and 18, D=C1-C0 and a 1e-6 numerical tie choosing K0. Both ranks require an eligible converged start. The maximum is one K0 start, two ordinary K1 starts and one specified nonzero diagonal-derived retry. No sole-survivor winner or hidden rank expansion. Independent same-covariance dense REML checks must agree within 1e-8. Genetic and residual kernels must be distinguishable after removing trait intercepts.

The uniqueness floor is 1e-4 in squared trait units. Admissible near-floor fits remain eligible and visibly flagged. Fixed-rank public defaults are preserved. Intervals remain conditional on the selected factor count. Selection reliability, broader ranks and designs, biological-rank probabilities and selection-adjusted interval calibration require separate evidence.

Rejected a seed or dataset search for an ordinary K1 winner. The first n8 ordinary witness selected K0 at 10000 iterations and was unavailable at 2000. One separately frozen n16 strong-factor witness also selected K0. Selected-K1 transport therefore uses a clearly controlled selection override around an actually eligible K1 fit, without claiming ordinary K1 selection or recovery.

## 4. Files Touched

Julia: `src/HSquared.jl`, new `src/fa_rank_selection.jl`; `test/runtests.jl`, new deterministic acceptance files and ordinary fixture; automatic-rank usage/programme docs; capability/debt rows; roadmap, loop checkpoint and retained check evidence. R isolated worktree: control/public dispatch, bridge/selection helpers, S3 registration, matching help files, automatic-rank tests and fixture, and the experimental usage note. Source hashes are retained in the linked check evidence.

Unrelated changes to `.claude/settings.json` and `.cursor/hooks.json` in the Julia checkout are excluded from task staging. The protected original R checkout is outside implementation ownership. Its 39 recorded dirty files and statuses match; additional untracked `docs/dev-log/inbox/`, `graft/` and `tests/graft/` folders are recorded and left untouched. Whole-status preservation is not claimed.

## 5. Checks Run

Current focused Julia acceptance passes 147 assertions across ten testsets. Parent fixed-rank regressions pass, including 107 multivariate contract assertions. The final current-source full Julia `Pkg.test()` passes. Final parent R expert/object and mandatory-live gates pass after the interruption repair. The final mandatory-live worker slice has 116 passing assertions with zero warnings, skips or failures; the no-live slice has 32 passes and one expected opt-in skip.

The first full R check failed. A retained-log rerun reproduced seven bridge failures because the subprocess activated an old default Julia checkout. Its signatures lacked current `trait_names` and `df` fields. The full R gate is being replayed with `HSQUARED_JULIA_PROJECT` bound to this exact current Julia worktree. This changes execution configuration, without weakening source or tests. The corrected current-project check has 3866 passing assertions and one failing older pinned warning expectation in test-multivariate.R532; an exact-fit reproduction confirms an unconverged fit and a surfaced earlier convergence refusal, with no SE fields. The narrow regression repair accepts only convergence or non-PD-information refusal, still requires the warning, confirms nonconvergence and forbids fabricated SE fields. Its focused multivariate slice passes 105 assertions, no failures or skips, with one expected heritability warning. Runtime and fixture are unchanged. The strengthened interruption slice and final parent replay pass. The final exact-project R package check returns Status OK with zero errors, warnings or notes. Its tests have 3871 passes, zero failures, 26 test warnings and 48 existing opt-in skips; the separate required live selector slice has no skips. The full R test phase takes 135.797 seconds. The devtools launcher emits a Quarto version-probe warning, separate from the zero R CMD check warnings.

Local deterministic Graft refresh passes, with 3015 nodes and 3934 edges. The preamble cap and whitespace checks pass. Fresh independent source review, final root replay and full after-task acceptance remain open. The checkpoint report structure passes, which does not establish completed programme acceptance. No hosted CI, deployment or external landing is claimed.

## 6. Tests of the Tests

The Julia suite uses independent dense REML, covariance/order and hand-score references. Deliberate wrong-floor, wrong-order, wrong-penalty/sign, tie-policy, sole-survivor and interruption controls distinguish malformed behavior from a passing optimizer. Manufactured retry witnesses include non-nesting and a better finite unconverged alternate start. Identity and all-half-sib pedigree kernels supply independent identification refusals.

Mandatory R live acceptance is required rather than accepted after skips. It compares ordinary same-input Julia/R candidate and attempt tables, covariance, score, labels and breeding values. The initial live interruption crossed the production catch boundary but only set a minimal synthetic Julia ledger and asserted a non-null result. Parent review found that this did not prove usable full-table transport. The repaired reader and strengthened witness interrupt the actual selector during its first optimizer start, retain both candidate rows and one interrupted attempted row, keep unfinished numeric/logical values missing, reject opaque row objects and confirm the captured R snapshot survives Ref cleanup. The final worker live slice passes 116 assertions. This tests a controlled actual engine interruption. Operating-system signal timing during optimization remains untested. Controlled K1 transport builds the engine fit from an actual eligible FA attempt and retains a failed alternate start with finite parameters and missing objective, convergence and iterations. Missing values remain missing and the failed start stays visible. This is serialization coverage, not evidence that an ordinary selector chose K1.

## 7a. Issue Ledger

Resolved during implementation: synthetic retry rows; stale interrupted candidate summaries; label validation; Optim API mismatch; ragged JuliaCall vector/matrix conversion; mixed missing/string columns; empty attempt tables; lost formula/call; retained request Ref payloads; selected-K1 nullable failed-start metadata; incorrect valid-start labeling. Every actual optimizer attempt remains visible.

Open: fresh numerical, bridge and claim review; final root ledger/report acceptance. Local candidate commits preserve the reviewable sources; they do not establish independent acceptance or external landing. Automatic approval review rejected the CLI source panel because it transmits private source and related artifacts to an external model service. Explicit user authorization is pending. The rejected action has not been retried or bypassed.

## 8. Consistency Audit

The contract, Julia implementation, R expert control and experimental usage agree on the T4 pedigree cell, K0/K1 comparison, floors, bounded starts, failure outcomes and conditional uncertainty. The new capability row is experimental under verification and the new validation-debt row remains partial. Six of eight technical/programme gates have passing child execution receipts; G7 and G8 remain open. Root receipt consolidation is distinct from the required final replay. The repository GATES.md now indexes the single active eight-gate ledger; earlier FA/GLLVM, V0 design and 0.5 planning records are preserved verbatim in a hashed archive. Completed child ledgers retain their original hashes and approval mappings, avoiding duplicate full-suite replay. Public covered count stays seven. The earlier fixed-rank FA campaign and bounded GLLVM records remain intact. Julia source and tests match the successful final checks. Seventeen Julia/R source, test, fixture and help hashes are frozen after the warning-regression and interruption repairs, and all still match the final passing checks.

## 9. What Did Not Go Smoothly

The default Julia depot could not write sandbox pidfiles. Checks use a writable temporary first depot and the installed dependency fallback, with one Julia and one BLAS thread. R launch paths needed an explicit Julia launcher. The old CLI 0.154.0 rejected the planned model IDs; a tiny compatibility probe passed with the bundled CLI 0.159.2. The actual source-review batch was then rejected by automatic approval review. Neither model compatibility nor a failed dispatch counts as source review.

JuliaCall reshaped nested rows and unequal vector lengths, requiring explicit per-cell plain encodings. The K1 branch exposed metadata gaps hidden by the ordinary K0 result. The gate checker abbreviates failure output; explicit R check directories now retain complete diagnostic logs. A regex replacement in parent receipt consolidation turned literal backslash-n strings into broken CHECK lines. All six consolidated commands now exactly match the passing child commands and pass shell parsing. Negative controls reproduce three malformed R commands from the prior snapshot; no optimizer or package source changed. A duplicate focused worker run finished before cancellation reached it; no duplicate process remains.

## 10. Known Residuals

This is bounded dense experimental mechanics. The ordinary execution fixtures do not establish selection reliability, a global maximum, biological rank, external-comparator agreement or selection-adjusted inference. Trait-unit changes can alter the feasible floor set. Larger trait/rank ranges, missingness, repeated records, genomic/custom providers, additional fixed effects and non-Gaussian models remain outside the selector.

The programme is incomplete while independent review or final acceptance is open. No push, merge, release, tag, registry action, submission, remote compute, campaign, GPU work or default activation occurred. Local source candidates remain reviewable in isolated branches.

## 11. Team Learning

Actual numerical producer: GPT-6 Sol high. Actual R and independent test producers: GPT-6 Luna medium. These were three native agents with disjoint ownership; the parent consolidated evidence and inspected neighboring failure paths. The proposed fresh completion panel is Sol high for numerical judgment plus two Luna medium reviewers for bridge and claim evidence. It has not run successfully. A Luna medium compatibility-only probe ran through the bundled CLI; it read no source. The exact parent runtime model identifier was not exposed by task tools and is not inferred from a configured default.

Ultra Plan owns programme decomposition and routing. Unlazy owns predeclared gates and replay. Systematic debugging isolated the full R failure to its stale Julia binding. The durable loop goal/checkpoint survives context compaction. Existing fixed-rank regressions provide the Golden Set. The Luna test worker also repaired and checked the acceptance-ledger consolidation during continuation, without a source-review claim. One older R warning expectation is being deliberately updated because its exact fit stops at the convergence guard before information formation; both specific refusal reasons remain guarded. No promotion or release evidence is borrowed from these tests. Operating-contract, route, prior design and relevant memory receipts were used for scope and release boundaries; no private memory files were written.

## 12. Cross-Product Coverage

This implementation covers complete T4 Gaussian pedigree K0/K1 selector mechanics and the explicit paired R expert route, with full candidate/attempt transport, ordinary selected-K0 execution, controlled selected-K1 transport. Full interrupted-ledger transport is covered by the strengthened controlled engine-interruption witness and final parent replay. It does NOT cover ordinary selected-K1 reliability, rank recovery, biological-rank probabilities, selection-adjusted interval coverage, other traits/ranks/families/providers, sparse production FA, public `cov=fa()` grammar, GLLVM expansion, remote campaigns, GPU, release, registry, submission or deployment. The highest current status is implementation under verification.
