## 1. Goal

Resume Arc 1 by diagnosing the mandatory-live R automatic FA-rank bridge failure and retain exact evidence without changing the dirty R checkout or claiming an acceptance gate.

## 2. Implemented

In a disposable R clone, the parser now permits only ten known identity and matrix-diagnostic fields to be absent for legacy/default and `arc1_v1` payloads. Explicit `arc1_v2` remains strict. The focused offline and Julia-backed live test suites both pass. An independent Astra review passed the exact source/test/patch hashes for parser compatibility and schema repair only. Exact source, test, patch, logs, review receipt, and JSON test receipt are retained under `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/r-current-live-20261008/`.

## 3a. Decisions and Rejected Alternatives

The live default test route returned a legacy payload with no optimizer-policy marker. Allowing omissions only under explicit `arc1_v1` was therefore too narrow. The allowlist applies only to genuinely absent metadata in the default/legacy and v1 routes. Unknown policy strings fail. Explicit v2 requires fields in columnar, row-list, and data-frame payloads, and all present scalar columns are length-checked before iteration, including zero-row inputs. Required candidate and attempt fields remain mandatory for v2. No R source was copied into the user's main checkout or the older orphaned R lane.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint-archive-20261008-before-r-live-review.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/r-current-live-20261008/`
- `docs/dev-log/after-task/2026-10-08-r-current-live-diagnostic.md`
- `docs/dev-log/check-log.d/2026-10-08-r-current-live-diagnostic.md`
- `docs/dev-log/check-log.md`

The disposable candidate branch and scratch logs remain under `/private/tmp/hsquared-arc1-r-active-20261008`.

## 5. Checks Run

- `HSQUARED_AUTO_FA_REQUIRE_LIVE=false Rscript -e 'devtools::test(filter = "auto-fa-rank-optin", stop_on_failure = TRUE, reporter = "summary")'`: PASS, exit 0; mandatory live case intentionally skipped.
- Required-live equivalent with Julia 1.10.0, the retained HSquared.jl project, four Julia threads, and BLAS one: PASS, exit 0; all focused test expectations passed, including live selection and direct-Julia comparison.
- `git diff --check` in the scratch R clone: PASS, exit 0.
- Exact final candidate source SHA-256: `48dd81b39053a2e03f40123135c5a00bebc046cb6e86aec515ca9e0c39cc7dfa`.
- Exact final test SHA-256: `c4f1e6e61b9a248647e6a15553de6715d081dee1a507a7fe315febfc4f55a839`.
- Exact final live log SHA-256: `6a8a992a49d7f355e349fdda4660f6d0ba81dacab39c4e8f3e2c72be175e1575`.
- Astra source-review PASS is retained at `evidence/r-current-live-20261008/source-review.json` and is limited to parser/schema repair.

## 6. Tests of the Tests

The live regression failed before the fix, first exposing six missing policy fields and then four missing matrix diagnostics. The final focused tests verify typed absent metadata, required-field checks across columnar/row-list/data-frame v2 shapes, unknown-policy refusal, and scalar-column lengths including zero-row inputs. The zero-row and present-metadata length regressions failed before their repairs. Red and green logs are retained beside the patch.

## 7a. Issue Ledger

- Fixed in disposable candidate: legacy/default Julia payloads omit metadata introduced by the newer R schema.
- Open: transfer into the owned R lane, paired Julia/R source freeze, semantic identity-value validation, and canonical G1/G6/G7 receipt refresh.

## 8. Consistency Audit

Checked both candidate-summary and attempt-row parsing, the explicit v1 path, the default legacy live path, the explicit v2 policy marker test, and the main R checkout/older isolated lane boundary. Only the disposable clone changed. Astra passed the exact final parser/source hashes. Its review explicitly does not certify NULL/NA identity semantics or all legacy row-list behavior.

## 9. What Did Not Go Smoothly

The first policy fix assumed that the live test explicitly requested v1. The next live run revealed that the test uses the default legacy route, and a subsequent run exposed four additional absent diagnostic fields. Both failure stages were retained and narrowed the final allowlist.

## 10. Known Residuals

This is component evidence only. G6, G1, and G7 receive zero new credit. No study attempt ran. G2-G5 and G8 remain open. The overall Arc 1 and parent H2 goal remain active. The final source has an exact-hash parser review, but it must still be admitted through a paired current-source freeze before canonical parity claims.

## 11. Team Learning

When bridge schemas evolve, test the omitted-policy legacy payload as well as explicit policy versions. A passing offline parser test cannot substitute for the required live language-boundary test. Memory receipt: loaded the HSquared project routing manifest, validation-harness direction, repo AGENTS.md, and lane-preflight/lease guidance; these kept the patch isolated and gates fail-closed. Golden Set: not run; no applicable known-mistake class beyond bridge-schema compatibility was changed.

## 12. Cross-Product Coverage

Covers: legacy/default and `arc1_v1` columnar FA-rank metadata parsing in the isolated R candidate, plus the mandatory live bridge test.

Does NOT cover: canonical paired-source parity, semantic NULL/NA identity validation, full legacy row-list contract, explicit `arc1_v2` live execution, repeatability or interval models, simulation calibration, Julia source changes, package-wide R checks, or any acceptance gate closure.
