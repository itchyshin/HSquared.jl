## 1. Goal

Repair and validate the bounded runner for retained G2 outer7 and outer10 selector cases, then reconcile its expanded-reference evidence against the current selector. Record a bounded diagnostic path for the observed K0 miss without changing the active selector, G2 criteria, denominators, or gate status.

## 2. Implemented

Repaired the diagnostic runner and case writer: canonical source-lock path checks; top-level inclusion of the engine identity helper; `Base.invokelatest` around engine calls; a run-local writable Julia depot before the existing depot; receipts for depot setup failures; and recursive conversion of tuples and multidimensional arrays into TOML-compatible values. The final run completed both 19-start selectors. No production optimizer or model source changed. The independently audited expanded-reference join matched outer7 K0/K1 and outer10 K1 against current selector results within tolerance. Outer10 K0 missed the expanded reference by `0.16953374156236123`; Astra traced this to the ordinary default reproducing the reference split0.5 path while alternate splits found a materially different covariance solution. A bounded six-split K0 diagnostic candidate is now being prepared, with the active selector still unchanged.

The output validator passed independently. Both selectors chose K0. Outer7 retained 1 failed start among 19, and outer10 retained 8 failed starts among 19. Both K1 candidate summaries were eligible but near the uniqueness floor. These are diagnostic outcomes on already-consumed cases, not allocated G2 observations.

## 3a. Decisions and Rejected Alternatives

Kept the selector schedule, scoring, refusal rules, iteration limit, inputs, seeds, and denominator unchanged. Fixed the demonstrated script failures. Each changed candidate received a fresh exact-source review before launch. Kept all failed and successful run directories; no failed attempt or output was overwritten.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/retained_full_selector.jl`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/run_diagnostic.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/test_runner.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/safe_toml_regression.jl`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/source-lock.tsv`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/admission-candidate.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/astra-review*.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/offline-tests-*.log`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/offline-reference-test.log`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/output/run-20261008T022027Z-19b4f9d7/`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/output/run-20261008T022344Z-cf5b3ddb/`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/output/run-20261008T023051Z-cdd8a722/`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/output/run-20261008T023627Z-967c2990/`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/output/run-20261008T023900Z-1717ca34/`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/output/run-20261008T024259Z-2015b815/`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- `docs/dev-log/decisions/2026-10-08-g2-k0-multistart-diagnostic.md`
- `docs/dev-log/source-review/2026-10-08-g2-outer10-k0-reference-comparison.md`
- `docs/dev-log/source-review/2026-10-08-g2-outer10-k1-reference-status.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-08-g2-retained-selector-diagnostic.md`

The five failed output directories preserve their launch or serialization errors. The successful directory has both case records, the diagnostic, sidecar, supervisor receipt, logs, and run-local Julia depot. Julia-created compiled files remain inside each run depot.

## 5. Checks Run

- G2 diagnostic offline suite: 30/30 passed in 5.128 seconds; Python compilation passed. Log SHA-256: `a18aa783858e7ddaedc41c6ca8cb08ad535181183b097919289891034205d0e4`.
- Focused expanded-reference contract suite: 148/148 passed. Exact tested source hashes were `sim/arc1/reference.jl` `3fa05682b1dda61be259f21a8275a113337f39a3db007c41a69995bfe573b080` and `test/arc1_simulation_reference.jl` `8c197f1b922a89e92a7517ce2510b964af794bbca576dafcf9edf6070460ed7a`. Log SHA-256: `942660146580601cd9310b117f57ccbdec79613456a6cd71f04fd373c6f9bd89`. The test uses a fake engine and contains no scientific fit.
- Isolated Julia TOML regression extracted the exact production helpers and serialized a matrix plus nested tuple successfully. It did not load HSquared or run a selector.
- Final candidate SHA-256: `83a83d45d7a64ab851453949c375b67cc6f7509475c81abe3083bbe540acf776`; source lock SHA-256: `4648688fdfc58bc89aabd1e5f49d500a12e1f11cc307a972381531a85c5f85d8`; 62 locked inputs verified.
- Astra exact-source review passed for the final candidate and runtime bindings. Review receipt SHA-256: `c8fb599ff3e827071571e18bfca66304966570ed2e47fa887868e60d8217239e`.
- Final bounded run completed with exit 0. Independent post-run validation passed. Diagnostic SHA-256: `cbc8e4d498c36d5d3ef605d444c66f87205a1fdb31cadc5ec00fd897864e96b5`; supervisor receipt SHA-256: `6e363c85a5466df75719aaf6efcc6cb0ecb8998f67795cf15eee4417109c7063`.
- `python3 .../run_diagnostic.py --candidate-sha256 83a83d45d7a64ab851453949c375b67cc6f7509475c81abe3083bbe540acf776` passed offline preflight and reported `PREFLIGHT_PASS_NOT_ADMITTED` without starting Julia.
- Arc gate lock verification passed. G0, G1, G6, and G7 remain verified for their exact recorded scopes; G2, G3, G4, G5, and G8 remain open.
- Astra's independent audit of the v5 expanded-reference output passed artifact integrity and arithmetic checks, then joined it to the current retained selector using matching data/execution identities and 37 shared pins. The addendum is `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-reference-only-v5/current-selector-reference-addendum.json`, SHA-256 `e76c891514197b4ce07527f709d267cb931da2fe59cb74b2f3b0207f05587635`. Current-source shortfalls are outer7 K0 `4.55e-13`, outer7 K1 `2.84e-13`, outer10 K0 `0.16953374156`, and outer10 K1 `6.08e-12`; tolerance is `1e-4`. Astra's independent read-only review found that outer10 K1's `finite_unaccepted` best row is the earlier Nelder-Mead observation; a later final BFGS row has exactly the same parameters and likelihood and is admissible. The frozen earliest-observation tie rule explains the projected status. The K1 status concern is resolved; outer10 K0 remains a failed comparison. No G2 credit is earned. The original v5 output review is scoped to older admission-v1 baselines and is not the source for current-selector values.
- Astra's separate K0 review found the ordinary default and reference split0.5 have identical initial parameters, terminal parameters and 71 BFGS iterations. Five other reference splits reach a stronger split0.3 solution in 60 to 130 iterations. Covariances differ materially: relative Frobenius differences are 0.2195 for G and 0.1402 for R. Same input, ordering, objective and execution identities were confirmed. The retained evidence supports a start-dependent solution or boundary-stopping problem, but does not prove global optimality or exclude a shared numerical defect. Full review: `docs/dev-log/source-review/2026-10-08-g2-outer10-k0-reference-comparison.md`. The ordinary/reference K0 shortfall remains `0.16953374156236123`, above `0.0001`.
- Following Astra's method review, the driver approved a diagnostic-only candidate using the six existing K0 splits with the current 2,000-iteration cap and unchanged acceptance rules. The schedule is `0.05, 0.15, 0.3, 0.5, 0.7, 0.9`; preserve the two phenotypic K1 starts and regenerate only the 16 derived K1 starts from the best eligible K0. This raises the within-case planned ledger from 19 to 24; it does not change the outer-case denominator. The active selector and frozen G2 criteria remain unchanged. Candidate implementation and tests are in progress under `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-k0-multistart-v1/`; no fit has been launched.

## 6. Tests of the Tests

The offline suite included regressions for source-root containment, engine world-age use, exact source pins, receipt binding, depot setup failure, and TOML shape. The depot-failure test forced directory creation to fail and verified a review-bound failure receipt with no child spawn. The Julia serialization regression used the exact production helper and verified parsed matrix dimensions and nested tuple values. It reproduced and caught the matrix failure that the earlier Python-only structural test missed.

## 7a. Issue Ledger

- Fixed in the diagnostic tools: canonical path containment, Julia world-age failure, unwritable default depot, missing receipt on depot setup failure, tuple serialization, and matrix serialization.
- Deferred: ordinary K1 convergence and covariance failures on the two cases. They remain visible in the output for scientific diagnosis.
- Open: G2 development reliability and expanded-reference requirements; G3 rank-selection confirmation; G4 FA interval calibration; G5 repeatability interval calibration; G8 independent scientific review and reconciliation.

## 8. Consistency Audit

The final source lock covered all 62 locked inputs. The post-run checker verified the successful receipt, diagnostic and per-case hashes, exact outer indices and seeds, all 19 starts per case, preserved original ledgers, iteration totals, one-restart limit, and the zero G2 count. The K1 summaries record near-floor status and the failed attempts retain their covariance-validity reasons. No Julia production sources, R checkout, protected settings, public status, seed schedule, or acceptance ledger changed.

## 9. What Did Not Go Smoothly

Five reviewed diagnostic runs failed before producing a complete result. The retained causes were source-path containment, Julia world age, a write attempt in the protected default depot, tuple conversion, and matrix conversion. Each failure was preserved and followed by a narrowly tested, exact-source-reviewed repair. The last run completed. The first focused reference-test launch also stopped before loading tests because Julia tried to write a pidfile in the shared depot; the rerun used a disposable writable depot first and passed all 148 assertions.

## 10. Known Residuals

This diagnostic re-ran two already-consumed selectors and separately expanded the reference search on those same consumed inputs. It contributes zero allocated observations and does not qualify G2. The current-source join finds an outer10 K0 shortfall above tolerance, consistent with a start-dependent solution on these records. The apparent outer10 K1 status mismatch is resolved by a later admissible BFGS row with the same exact parameters and likelihood as the earlier finite-unaccepted Nelder-Mead row. Some K1 starts failed covariance validation, and accepted summaries remain near the uniqueness floor. No selection-rate evidence was produced. Pilot and confirmation remain held. GPU, release, and publication work remain outside this arc.

Independent numerical interpretation compared these outputs with the retained source-bound attempts. Outer7's eligible K1 starts increased from 12/18 to 17/18; outer10 increased from 0/18 to 10/18. The selectors now choose K0 on both cases, while eligible fits vary materially in G/R. The expanded-reference audit found outer7 K0/K1 within tolerance and outer10 K0 short by 0.16953374156. The apparent outer10 K1 status mismatch was resolved: the identical point was admissible in the later final BFGS stage. The two original source-bound refusals remain intact. These observations apply only to consumed inputs and provide no evidence of selector reliability or global optimality. The frozen G2 screen still requires 29/30 usable outcomes per cell and resolved expanded-reference comparisons before a pilot can qualify.

The after-task structure checker passed. The shared completion check refused promotion because the Arc 1, automatic-rank implementation and parent H2 ledgers still contain unmet gates. The scoped Unlazy status command reports G2, G3, G4, G5 and G8 unmet. This report records one diagnostic slice and leaves the Arc 1 and parent H2 goal active.

## 11. Team Learning

Memory receipt: the repository LOAD-FIRST route prioritized coverage calibration, validation-test discipline, and compute routing. These kept the work on a bounded diagnostic and away from the unqualified study campaign. The exact script repairs and source bindings are retained with this lane.

Golden Set: not run. This slice concerned diagnostic output retention and serialization. No production statistical source defect surfaced.

## 12. Cross-Product Coverage

Covers: Julia-only retained-input selector and expanded-reference diagnostics, output serialization, receipt validation, and the bounded K0 multistart diagnostic decision.

Does NOT cover: R controls or R-Julia parity; allocated G2 development qualification; expanded-reference optimization; pilot or confirmation; FA or repeatability intervals; capability promotion; GPU; release or publication.

## Naturalness assessment

Style: 2/10, low AI-like style, medium confidence. Genre/coverage: technical after-task record. Evidence: the report identifies specific artifacts, numeric outcomes, exact limitations, and the next bounded action; it avoids general claims about model reliability. Science: pass for describing retained inputs only; facts: pass against retained output, Astra addendum and reviews, frozen ledger, and test logs; references: not applicable because no external sources are used. Provenance: self-review after the 2026-10-08 updates.
