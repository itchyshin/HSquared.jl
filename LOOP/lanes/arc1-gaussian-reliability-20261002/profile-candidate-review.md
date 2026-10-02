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
