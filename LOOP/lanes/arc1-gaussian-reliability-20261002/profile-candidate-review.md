# Profile candidate review checkpoint

The exact paired-record core passed 76 deterministic tests. The real-package five-target diagnostic at source `70dd13a4eb40dfbc17e3af23649ebfb742d82db45f7934160c39b4a0dfbfb743` completed in 165.6 seconds. Only the repeatability interval formed. The heritability and three raw-variance intervals remain unverified.

| Target | Result | Target evaluations |
|---|---|---:|
| Additive variance | Search budget exhausted | 4097 |
| Permanent-environment variance | Search budget exhausted | 4097 |
| Residual variance | Search budget exhausted | 4097 |
| Heritability | Reported search-budget status requires correction | 1815 |
| Repeatability | Finite grid resolved; interval formed | 1847 |

The point fit was available, and no constrained fit exceeded its likelihood. The raw tail screens passed, but the returned scan domains omitted already-evaluated tail points. Astra identified a dimensional error: positive raw-variance gaps were measured in octaves and compared against a variance-scale root tolerance. Root tolerance had also been applied across an entire cutoff band. A depth-first refinement then replaced the complete grid with a visited prefix when its budget was exhausted. Separate nuisance, root, gap and budget failures must retain their actual causes.

The full serialized diagnostic occupies 71,271,562 bytes, SHA-256 `d10e9464b6afbed153ea3449aad394b4def3802902791f6272890e7cdebbab68`. It and the readable log are retained locally under `.unlazy/arc1-gaussian-reliability/evidence/profile-candidate-70dd13a4/`. This directory is ignored by Git. The diagnostics need bounded storage before a campaign, while preserving failure counts, selected fits and unresolved mechanisms.

Next: finish Astra's source review, implement the grid and status repairs with Luna, then rerun focused adversaries and the full wrapper within a measured bound. The approved resolution, likelihood-ratio cutoff and scientific acceptance criteria remain unchanged. G5 remains unmet.

## Brent repair and exact-zero boundary finding

The repaired Brent API allows the deterministic h² interval to form. The residual-variance interval remains refused under the current competitive-bound rule. At `Ve=2.8675896183586707e-6`, a positive permanent-environment nuisance estimate reaches its lower bound at about `1.0163e-13`, with log likelihood `-9707.895940510107`. The certified exact-zero permanent-environment face has log likelihood `-9707.895940508890`, equal to the accepted best and about `1.2169e-9` higher than the bound approximation. Its one-sided derivative of the minimized negative likelihood is positive, `0.0122399`, supporting the zero face locally. The other exact-zero face is worse.

This diagnosis comes from the Luna worker's retained deterministic fixture, pending parent verification and Astra review. The current refusal is preserved. Astra must decide whether an already certified exact-zero face can resolve its matching competitive positive lower-bound approximation, and specify any required likelihood, derivative, and component matching checks before the protocol changes. Upper bounds and unrelated uncertified competitors remain distinct.
# Review of profile source d990555f

The parent independently reproduced 179 profile assertions with zero exit status. The profile, test, module and interface hashes matched before and after that replay. The same process passed 33 independent DGP assertions. Its command, hashes and log are retained in `.unlazy/arc1-gaussian-reliability/evidence/parent-profile-d990555f/`.

The deterministic profile fixture is retained separately in `.unlazy/arc1-gaussian-reliability/evidence/profile-d990555f/`, including the exact replay, full serialized result and five-target summary. Va, Vpe and Ve remain unresolved; h2 and repeatability form. At the diagnosed Ve value, the exact-zero face likelihood agrees within 1.2169e-9, but the projected remaining gradient is 7.7955e-6 and fails the 1e-6 rule. No tolerance was relaxed.

Astra found two additional defects despite the passing tests. Certificate likelihood and gradient evaluations occur after the existing maximum accumulator is computed, so their valid likelihoods are omitted. Also, marking a candidate resolved can bypass a better likelihood visited earlier by that candidate. Repair both by recording every valid certificate evaluation and requiring the candidate's best-ever valid likelihood to remain compatible with the certified face. Add adversaries for a better intermediate interior point followed by a matching boundary endpoint, and for better valid points reached during certificate checks or before an exception.

The early point-fit failure result must carry the same likelihood convention and constant-offset metadata as the success result. The R bridge must preserve the global point-fit failure flag and avoid displaying convergence after a demonstrably better constrained fit.

## Next bounded numerical decision

Astra inspected the retained result without refitting it. Va and Vpe contain projected-gradient refusals after small-objective or small-step optimizer exits. Ve also has many missing matching-face certificates, plausibly because the valid zero endpoint of a reduced face is represented only by an unresolved positive log-bound endpoint.

The next engineering checks use existing retained fixture values only. First compare gradient-only BFGS stopping with f/x tolerances disabled, keeping the 2,000-iteration cap and 1e-8 optimizer gradient tolerance. Then inspect the first retained Ve value with a missing matching face. If the optimum is a valid exact-zero intersection, review an explicit endpoint certificate, including its one-sided derivative. Do not silently project additional components or relax gradient, formation or coverage requirements. These checks precede another full wrapper run or any allocated study.

## N=80 engineering refusal and saved-coordinate arithmetic

The first Totoro N=80 interior repeatability example used engineering seed 2026100204 and source `ab47c2ea`. Four targets formed; residual variance retained two positive-domain nuisance refusals. Astra verified that both refusals follow the frozen certificates. Diagnostic 3, candidate 24, failed forward derivative agreement by 5.10512e-6 against the 5e-6 threshold. Diagnostic 68, candidate 7, failed same-face raw likelihood agreement by 1.3387762e-8 against 1e-8. Neither qualified for the existing projected-gradient-only polish. The common maximum differed from the unrestricted point by only about 2.84e-14.

Luna high performed an optimizer-free saved-coordinate comparison in Float64, centered Float64, 256-bit and 512-bit arithmetic. For this intercept-only paired design, the transformed difference block of X is exactly zero. At fixed Ve the difference-record contribution `C(Ve)=80*log(Ve)+dot(z_difference,z_difference)/Ve` is constant in nuisance parameters, and `LL=LL_sum_modes-C(Ve)/2`. Computing the centered contribution before summation avoids subtracting large full likelihoods. The higher-precision values agree.

For diagnostic 3, the centered 256/512-bit h=1e-5 derivative is 0.007596111978048494 versus analytic 0.007596111699614222, a discrepancy of 2.78e-10. The saved full-likelihood difference produced 0.007591006578877567 and the refusal. Centered candidate-to-face likelihood spread is about 8.18e-12. For diagnostic 68 the centered spread remains -1.3393630342542925e-8, exceeding the unchanged threshold. That candidate remains unresolved; precision alone cannot accept it.

Evidence: `.unlazy/arc1-gaussian-reliability/evidence/profile80-arithmetic/measure.jl` hash `ec838e8e588cb88d0ea13fbd2bf1b20f5332566aeba527d686bf676b1b10512c`; measurement hash `140d05c9bc1a2cabb2ecef8a912596899be743959bbb34f9eb521b47080771da`. Runtime was about seven seconds, with no optimization or study execution.

Pending scientific review: center only fixed-Ve nuisance optimization and same-Ve certificate comparisons where the transformed difference-design block is exactly zero. Preserve full reported likelihoods, all historical maxima, thresholds, budgets, seeds and refusal rules. General X requires a separate derivation and retains its existing path. No source repair is authorized by this diagnostic record alone.


## Fixed-Ve centering implementation review candidate

Luna implemented the approved arithmetic change without changing optimizer budgets or acceptance tolerances. Source SHA-256: `d85d3d5e47f8ba280d6398b2719a6496f2dda3b6755f8780208563edb56164d5`; profile-test SHA-256: `d68e3c27ed550aa0fae3c8597e9ed41963192ce0e973f3615b2210ae2690e08d`. The parent independently passed 276 focused assertions in 26.68 seconds, with both hashes unchanged. Receipt: `.unlazy/arc1-gaussian-reliability/evidence/parent-centered-profile-focused/`.

The built-in agent tool reached its thread limit for both a new review and a previously used reviewer. The existing Ultra Plan read-only launcher is running a bounded independent Astra high review, with an eleven-minute cap and no source mutation or real profile fits. Its brief, dispatch, source hashes and result are retained under `.unlazy/arc1-gaussian-reliability/evidence/centering-astra-review/`. The N=80 replay remains pending that review.


Astra completed the independent centering review in 344.58 seconds with source hashes unchanged. Two controlled examples blocked acceptance: the final nuisance decision ignored a converged candidate's higher historical centered likelihood, and scalar-face/certificate adapters consumed a centered value before validating its fixed-Ve tag. The full judgment is retained in `centering-astra-review/review.md`; the events contain reproductions. Luna owns repairs and end-to-end regressions in the same two profile files. The prior candidate regressions used injected arithmetic and did not independently verify the real saved-coordinate engine calculation; an additional direct arithmetic regression is required. The N=80 fit remains held for the repaired-source review.


Astra v2 reviewed source `5a23f175` and test `a2fb8671`, confirmed both original repairs, and independently passed 50 centering assertions including 11 retained-N80 arithmetic assertions with no skips. Two neighboring tag paths remain blocked: a missing scalar tag produces a three-valued Boolean exception rather than a structured refusal, and BFGS/continuation maximum aggregation can ingest a centered maximum from another fixed Ve. Luna is auditing every tag/centered-maximum ingestion path and adding regressions. The same numerical thresholds, starts and budgets remain frozen. Review process duration was 284.92 seconds with unchanged reviewed source hashes. No real profile fit has run on the changed source.

## Third centering review: retained maxima on refusal

Astra completed a bounded read-only review in 493.781 seconds against source `26033c45ef68a580bb61bbfc934404eddf442ab8c8845c559afe1de4b91882fc` and test `e9f6377ab8e908fd2f8765eddbded70975e0a66c28dbe59268a721a6625597dc`. Both hashes remained unchanged. The parent made the authorized documentation-only checkpoint `1f5643ad` during review; the reviewer correctly limited its verdict to the inspected source hashes.

Verdict: BLOCKED. A continuation with invalid terminal score returned before ingesting valid same-Ve centered history. An end-to-end nuisance probe incorrectly accepted after losing an improvement of `2e-7`. Scalar refusal replaced a higher historical full maximum with a fresh terminal value; a valid tag with invalid terminal score also lost centered history. Luna owns repairs across all maximum-ingestion and refusal paths.

All 88 independent centering assertions passed, including 11 actual N80 arithmetic assertions without skips. Candidate 24 resolved and candidate 7 remained refused at centered spread `1.3393616882240167e-8`, preserving the `1e-8` threshold. These arithmetic checks do not override the two source defects. Report: `.unlazy/arc1-gaussian-reliability/evidence/centering-astra-review-v3/review.md`.

## Fourth candidate submitted for review

Source `5768e810b067ac02764b888fc65acc4dc1fe985cb8194f80c177100870883c70` and test `276420266e7a9e9fa0ee9090951063203dc6e0dc90f1c1064ff50d92e9a5998d` centralize history ingestion before terminal refusal. Worker focused tests passed 365 assertions; the expensive profile wrapper was excluded and no data fit was run. Astra review is retained under `centering-astra-review-v4`.

The arithmetic regression now generates the inspected N80 example from engineering seed 2026100204 and no longer skips when an ignored artifact is absent. It matches the retained 12-digit response fingerprint. Response values differ by at most `4.44e-16` and transformed responses by `8.88e-16`; X, Z, pedigree inverse, transformed design and eigenvalues are exactly equal. This is a portable same-seed/design regression with measured platform rounding, not byte-identical input reconstruction.

## Fifth centering repair awaiting independent review

Luna consolidated candidate, continuation, scalar and returned-certificate history ingestion. Focused arithmetic and controlled tests passed 835 assertions in 24.4 seconds, including a 192-case adapter matrix. Source SHA-256 is `5f1d7c1288b6a08b504c909ee855577648963c1e4932b5fde2bb8c2f2d6e85d3`; test SHA-256 is `9bd451799c736ecad250d2e38b63a857c87cdab03c0bcc8c5947ac5edf343de0`. The bounded Astra review is retained under `centering-astra-review-v5/`. No optimizer or real profile fit has been run on this candidate. The v4 defects remain open until independent review accepts the repairs.

## Fifth review remains blocked

Astra completed the v5 review in 441.30 seconds with both frozen hashes unchanged. All four v4 reproductions now pass. Four neighboring failures remain: returned polish continuation histories can be dropped and permit false acceptance; missing bound-candidate maximum fields still throw in diagnostics; missing scalar coordinates still throw; and a scalar centered-callback exception loses already retained histories. The review passed 613 independent arithmetic assertions and preserved the model, starts, budgets and thresholds, but did not accept the source. Exact reproductions and limits are retained in `centering-astra-review-v5/review.md` and its events.

Luna owns a v6 repair that inventories every returned record and consuming path. Tests must exercise the actual wrappers and diagnostics, not only the shared history helper. No numerical fit or study is authorized by the prior 835-assertion pass.

## Sixth source review, 2026-10-03

Astra completed v6 in 601.95 seconds with both frozen hashes unchanged. It reproduced a native refusal-policy regression: a legitimate failed BFGS start without terminal centered likelihood was refused unconditionally, even when its retained history was noncompetitive. Baseline `00e14939` accepted the corresponding controlled nuisance result. Four additional partial-record failures concerned optimizer-status diagnostics, malformed contacts, returned centered history and incomplete resolved certificates. Native occurrence of the policy regression in N=80 remains untested; the other cases use injected adapters.

The 593 retained centering assertions passed. Full likelihood, free-Ve gradient, cache, LR score, ratio path, target scan, five-target guard, cutoff and starts matched the baseline. The changed refusal behavior prevents source acceptance. Luna owns the narrow repair in profile source/tests, with native producer schemas governing required and optional fields. No N=80 replay or allocated study ran. Evidence: `.unlazy/arc1-gaussian-reliability/evidence/centering-astra-review-v6/`.

## Seventh review stopped at its time bound, 2026-10-03

The v7 focused suite passed 898 assertions in 34.9 seconds at source `4abaed25…` and tests `25591bb5…`. Astra's review reached its 660-second bound before emitting a final report. Exit status is 124, both frozen hashes matched, and all visible test commands completed. The prepared prose in its final prose-check command is retained as `review-draft-recovered.txt`, explicitly separate from a completed review.

Its retained counterexamples establish four repair targets. A native candidate-24 certificate with difference responses scaled by 16 resolves at centered spread `9.251266419596504e-12`, but a validator incorrectly refuses its full-scale diagnostic spread `9.5367431640625e-7`. Three injected-adapter probes discard a higher terminal centered value, lose accumulated history/tag on malformed polish input, or let a post-run callback exception escape without a structured history record. Interruptions propagated. Luna owns these narrow repairs; a fresh completed review is required before any fit replay.


## V8 repair and independent review started, 2026-10-03 UTC

Luna repaired the four retained v7 findings and passed 915 focused assertions in 38.0 seconds. Frozen source SHA-256 is `d0dc1419b26526b23893e1d652b5f2e837549f5f17f5c981236521eadd9a1ff7`; test SHA-256 is `0dd638ec21c5607aa18f0aaf6eb820bd83b7c0abd440cf2a7540a7df11d29c5c`. The portable native certificate fixture did not reproduce the historical full-likelihood spread. A separate diagnostic-only override tests that centered proof governs the centered route while the noncentered route still refuses excessive full spread. This distinction is retained explicitly.

Astra's new read-only review has a 780-second cap, including a reserved report interval. Initial sandbox startup failed before review because Codex could not write its local state database; that receipt is retained separately. The authorized retry is running. No completed verdict exists yet, and the saved N80 fit remains unrun. Evidence is `.unlazy/arc1-gaussian-reliability/evidence/centering-astra-review-v8/`.


## V8 verdict and V9 narrow repair

The completed v8 Astra review took 537.10 seconds with both source hashes unchanged. It found two malformed injected-adapter failures: an optional non-Boolean diagnostic flag threw after validation, and an inconsistent bound/contact record concealed a terminal centered maximum. Neither shape is emitted by valid native producers. Native history controls passed; the review confirmed unchanged baseline full-likelihood, gradient, LR, cache and search functions. One independent test process used default Julia 1.12.6 and timed out; it supplies no passing evidence.

Luna repaired the two record checks and passed 922 assertions on explicitly verified Julia 1.10.0 in 38.6 seconds. Source SHA-256 is `4d7cbb6faac96d769af8229f19f9d92d28ad6107737e89d9df85c968a0abca1c`; test SHA-256 is `1a9374798f5eb6e3fc5f8d875fedf6d4a5766c80bdfc0fab96ae60999d9de1d7`. A seven-minute Astra delta review is running under `centering-astra-review-v9/`. No acceptance or actual N80 fit is claimed.


## V9 source acceptance and engineering replay

Astra accepted the bounded repair in 284.05 seconds with both reviewed hashes unchanged. Independent Julia 1.10.0 controls passed 626 assertions in 44.56 seconds of process time, within the 60-second cap. The reviewer verified the two malformed-record repairs and native producer compatibility. Fresh named-function comparisons found unchanged full-likelihood, gradient, LR, cache, point-fit, ratio-nuisance, target-search and five-target-guard bodies against the baseline. This is not whole-file equivalence or coverage evidence.

The saved N80 replay has now started on those exact profile hashes, using the exact Julia 1.10.0 executable and a 120-second process-group timeout. Its prior engineering runtime was about 65 seconds. The launcher also checks `VERSION` inside the process and retains the executable hash. No result is claimed until the receipt and all five target statuses are inspected. All scientific gates remain open.


The saved replay completed with exit zero in 68.54 seconds, including 63.12 seconds in the profile call. Point-fit status was `ok`; additive variance, permanent-environment variance, residual variance, heritability and repeatability all formed with status `ok`. Input, source and executable hashes were unchanged. The exported interval table was read back from the retained `profile.jls` and had finite ordered bounds for all five targets. This closes the saved engineering regression, not any study-level coverage or formation requirement. Local commit `361f77cb` retains the accepted profile source and tests.

## Six-case engineering follow-up, 2026-10-03

The accepted v9 source completed six Totoro engineering cases in 308.75 seconds, with every process exiting zero and all source/input/result hashes verified. These were separate engineering seeds. Twenty-eight of 30 target intervals formed. In the near-zero-additive cases, N160 residual variance and N320 permanent-environment variance remained unformed with `nuisance_unresolved`. No allocated study seed or gate result follows from these counts. Full records are retained under `.unlazy/arc1-gaussian-reliability/evidence/repeatability-size-prerun-totoro-20261003T032000Z/`.

Astra independently inspected the actual failed candidates and evaluated their fixed coordinates at 128 and 256 bits. The original candidate-to-face deficits remain approximately `1.69891308e-8`, `1.42095406e-8`, and `1.53685648e-8`, each above the frozen `1e-8` certificate limit. Most of each deficit persists after exact-zero projection. This supports remaining-coordinate optimization error under the retained transformed representation, not a Float64 cancellation explanation. The closely matching best-uncertified rows reported in the initial extraction belong to different candidates. Centered mode uses its centered spread as the active criterion; the full spread is diagnostic. The N320 exact-zero residual face is structurally singular and noncompetitive, not evidence of a separate finite unresolved optimum.

The v1 rule correctly preserves these refusals. Its original-inclusive spread cannot become compliant by replacing a terminal point after refinement. Broader continuation eligibility or a certificate that preserves earlier values as historical maxima rather than permanent equality constraints would be a new numerical policy. No such policy is adopted here. Scientific estimands, exact REML, LR cutoff, zero-reduced models, all historical maxima and every formation/coverage criterion remain unchanged.

Parent authorized only Astra's staged observational diagnostic: replay the three indicated ordinary starts, then at most one remaining-coordinate refinement per start within its unused 2,000-iteration allowance. Estimate 15 to 30 seconds after loading, stop at the estimate boundary and retain partial evidence, hard process-group cap 60 seconds, one Julia thread and BLAS one. No whole profile, new data, study seed, source change or acceptance change is authorized. Original certificate failures must remain failed. Luna prepares the script for parent inspection before launch.

Independent review and exact staged plan: `.unlazy/arc1-gaussian-reliability/evidence/profile-size-boundary-astra-review/review.md` and `candidate-refinement-plan.md`. Astra's arithmetic took 6.07 seconds and all ten frozen hashes remained unchanged. Proposed future policy identifiers in that review are proposals only. Any later adoption needs an explicit recorded numerical-policy decision, corresponding protocol/version changes, adversarial history/budget checks and independent review before study admission.
