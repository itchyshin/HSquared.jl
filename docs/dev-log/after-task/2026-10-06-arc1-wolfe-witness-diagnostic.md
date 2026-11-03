## 1. Goal

Explain the retained outer7 and outer10 finite non-Wolfe K1 refusals under current Arc 1 source, while preserving the frozen selector, acceptance criteria, and study denominator.

## 2. Implemented

Added opt-in telemetry for a returned Hager-Zhang step that passes neither Wolfe condition. The telemetry retains origin, direction, requested and capped step, return step, restart number, objective values, slopes, Wolfe decisions, and callback counters. It does not change optimization or candidate eligibility.

Corrected the regression to use the actual LineSearches callbacks and inspect `xnew` and the raw `OnceDifferentiable` caches before any test-side refresh. The focused Julia optimizer-contract suite passed 465/465. A separate five-test Python supervisor suite passed 5/5.

The hash-pinned two-start replay completed in 17.125 seconds. Outer7 ended with gradient infinity norm `2.274052991968205e-5`; outer10 ended at `1.0459255365163801e-8`. Both returned a finite step equal to the domain cap (`0.03125`) after restart 5. A retained audit recomputed both Wolfe inequalities from terminal objective values and slopes. Each passed sufficient decrease and failed curvature, so ordinary and approximate Wolfe were false. Astra independently reviewed the exact projection and passed the arithmetic and frozen-refusal conclusion.

## 3a. Decisions and Rejected Alternatives

Kept the line-search refusal, convergence threshold, uniqueness floor, selector, and acceptance denominator unchanged. Did not treat either start as eligible or claim a numerical defect. This replay is diagnostic evidence only and cannot qualify G2.

## 4. Files Touched

- `src/arc1_fa.jl`: opt-in returned-step telemetry and retained terminal reason.
- `test/arc1_optimizer_contracts.jl`: regression for real callback state restoration and Wolfe-witness capture.
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-outer7-10-wolfe-witness-v1/`: reviewed candidate, source lock, replay/supervisor, focused tests, two serialized outputs, supervisor logs/status, arithmetic audit, portable projection, and evidence index.
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`.
- `docs/dev-log/after-task/2026-10-06-arc1-wolfe-witness-diagnostic.md`.

The run candidate is SHA-256 `d09906d1669b5a0c64b57b48e95b310f525930466cd2cf37ac6b9f9fe1276c3e`; its 200-line source lock is `8c9f8895898f232b9bf3de214259ad85e335ce7781ae6e339c7c3eb9a6b714bf`. Results are `wolfe-witness-outer0007.jls` (`37d77285fec247b9ae878cc50d1e621f45a3713a301477f269e941095324bf52`) and `wolfe-witness-outer0010.jls` (`fe1e60edd2ea7464b6412de18d845826170d231c4af8134363aee94bc6d7c414`). The corrected portable arithmetic projection is SHA-256 `fc39e8f755747564a6c3888b22009b146c71132c88db48c6098e15f88e3c426a`; Astra's review passed.

The exact 193-file execution source state is retained and checksum-verified in `execution-source-snapshot.tar.gz` (SHA-256 `6bfa1879d9ad4786a79042942c3f75a318171e47b71d2dc2f6072b8525d2efa2`). The checkpoint was restored to its post-run version after the snapshot; the admitted source copy preserves the exact checkpoint bytes used at execution.

## 5. Checks Run

- `julia --project=. test/arc1_optimizer_contracts.jl` : PASS, 465/465.
- `python3 -B evidence/.../test_supervise_wolfe_witness_v2.py` : PASS, 5/5. Initial red run failed because the new helpers did not yet exist; one subsequent assertion expectation was corrected before the final pass.
- Pinned two-start supervisor : PASS, two retained outputs, both child processes exit 0, total 17.125 seconds under the 120-second estimate and hard timeouts. No study seed or denominator was added.
- `audit_wolfe_witness_results.jl` : PASS for both retained output hashes, input identity, seed, balanced rank1 retry0 start, terminal status, cap/restart, and recomputed Wolfe decisions. Output and TOML projection are retained.
- `lane_preflight.sh` : source, test, evidence, and checkpoint paths report no conflicting foreign edits. Other cross-lane files remain untouched.
- Independent Astra review : PASS on exact v3 projection and the frozen-refusal interpretation.

## 6. Tests of the Tests

The supervisor tests cover hash mismatch rejection, process-group termination on interruption, missing-output refusal, atomic status replacement, and the estimate-triggered stop limit. The Julia regression would fail if the real line-search callbacks left the rejected trial in `xnew` or the differentiated cache. The audit recomputes the Wolfe inequalities instead of trusting stored flags.

## 7a. Issue Ledger

- Open: outer7's better finite K1 point remains ineligible because the frozen final-gradient and line-search checks fail.
- Open: outer10's K1 starts remain ineligible even though this balanced start's final gradient is small; its final finite step fails curvature and the line-search contract.
- No optimizer repair, threshold change, denominator change, pilot, or confirmation run was made.

## 8. Consistency Audit

The run used only the exact retained outer7 and outer10 balanced K1 retry0 initial vectors. Its current-source pins, four input hashes, three diagnostic source files, and output hashes are retained. The archived source snapshot was rechecked against all 193 admitted file hashes after the checkpoint gained this entry. The source replay did not call automatic selection or simulate new data. Recomputed sufficient-decrease and curvature comparisons agree with both stored Wolfe booleans and the terminal refusal strings. The G2 study denominator and all acceptance rules remain unchanged.

## 9. What Did Not Go Smoothly

Independent review held two candidate versions for real execution defects. The final candidate fixed the admission, dependency, timeout, interruption, output-retention, and status-update issues before execution. A later projection review found reversed lower/upper labels; v3 corrected them and passed exact arithmetic review. Earlier candidate versions and projections remain retained as superseded evidence.

## 10. Known Residuals

This work explains two consumed diagnostic starts. It does not demonstrate ordinary-start reliability, rank-selection rates, interval calibration, R parity, or any confirmation gate. Arc 1 G2-G5 and G8 remain open. Capability remains experimental and the covered count remains seven. The wider non-GPU H2 project remains incomplete. No full package test, R test, or documentation build was run here. No commit was created.

## 11. Team Learning

Use the real callback pair when a test claims to verify mutable optimizer-state restoration. Check cache coordinates directly before refreshing them. Preserve exact estimates and run limits in the supervisor, and retain a portable arithmetic projection when independent reviewers cannot load native artifacts. No external package scout or new simulation was needed.

## 12. Cross-Product Coverage

Covers: opt-in Julia line-search telemetry, its focused restoration regression, diagnostic interpretation of two retained K1 attempts, and a full Julia package-test engineering revalidation. Does NOT cover: automatic rank-selection qualification, ordinary-start reliability gates, R integration or parity, any interval gate, other sample sizes or signal cells, confirmation, G2 completion, the remaining Arc 1 gates, or overall H2 completion.

## 13. Full Julia Package Test Revalidation

The bounded Julia-only `Pkg.test()` run completed in 808.311 seconds with Julia exit code 0, 329 test summaries, and the final package line `Testing HSquared tests passed`. The retained test log SHA-256 is `d4156447ccefc096ea7c3f38578f41618f9be45de18f5fcd8b67249969d8537a`. The runner's receipt says `failed` because its success-marker matcher expected `Pkg.test() tests passed`, while Julia emitted `Testing HSquared tests passed`. A read-only independent audit at `evidence/g7-julia-engineering-after-wolfe-v1/julia-pkg-test-attempt3-independent-audit-v1.json` passes: it checks the final marker, exit code, all 329 summaries, log hash, runner inventory result, current source/test inventory against the frozen inventory, and its own marker-classifier self-tests. Audit script SHA-256 `af6b28ba2c3c1928a3a41f77e95a731b2d42b812bdf34e43ad0b56b76dc4be3d`; audit JSON SHA-256 `d8f695ea4217856cf28dc094943521467fd210dc1036a1d37427cdf0c72a02e8`. This is Julia engineering evidence only, not the paired R/docs G7 acceptance gate.
