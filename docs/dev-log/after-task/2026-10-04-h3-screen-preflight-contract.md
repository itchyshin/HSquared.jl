## 1. Goal

Add seed-free, non-executing preflight checks for the bounded H3 genetic-correlation screen and its separate timing manifest. Keep every fit and screen attempt held.

## 2. Implemented

The preflight module now validates screen manifests at exactly 48 attempts and timing manifests at exactly three slots, with bounded attempt and total time limits. Timing and screen seed declarations are shape-checked only. Their allocation and freshness flags remain false, and neither manifest is execution-eligible.

The bundle verifier checks the selected source-pin set and live process identity fields. Its receipt explicitly says that selected file pins do not establish complete loaded-code or dependency identity. It requires a later fresh-process check against an immutable bundle before any execution admission. Identity digests use a versioned recursive canonical encoding.

## 3a. Decisions and Rejected Alternatives

- Keep separate timing and screen manifest kinds so a three-attempt timing proposal cannot weaken the screen's fixed denominator of 48.
- Keep source inventory terminology at “selected file pin set.” The verifier does not claim that the selected paths prove every loaded method or dependency.
- Keep the independent seed audit and allocation outside this slice. A caller-provided seed list and checksum do not prove that seeds are fresh or disjoint from prior work.
- Keep `source_protocol_admission = HOLD` and `execution_authorized = false`. This validator is not a launcher.

## 4. Files Touched

- `sim/mv_h3_rg_screen_20261004.jl`
- `test/test_mv_h3_rg_screen_contract.jl`
- `docs/dev-log/source-review/2026-10-04-h3-screen-bundle-review.md`
- `docs/dev-log/check-log.d/2026-10-04-h3-screen-preflight-contract.md`
- `docs/dev-log/after-task/2026-10-04-h3-screen-preflight-contract.md`

No package fitting source, R source, public capability row, or covered count changed.

## 5. Checks Run

- `JULIA_DEPOT_PATH=/private/tmp/h3-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. test/test_mv_h3_rg_screen_contract.jl` passed **565/565** in 5.9 seconds. The command was rerun independently at the pinned hashes.
- SHA-256: harness `7aedf158ff736807459fede3c52bde434f380105420b7f54a6a8e38ae6756f7c`; contract tests `6e9f70b0ec751876a747d64b198be204674082874d0488d5293f5989988cc35f`.
- A direct whitespace scan found no trailing whitespace in either changed Julia file.
- Astra independently reviewed those exact hashes and admitted the source-only, non-executing preflight. The review did not authorize seed allocation, timing, fitting, or screening.
- The first normal-depot test attempt hit a sandbox `EPERM` while Julia tried to create a precompile lock. Rerunning with the task depot under `/private/tmp` passed.

## 6. Tests of the Tests

The contract suite mutates omitted source bytes and checks that the receipt still reports incomplete loaded-code verification. It reorders nested dictionaries and changes nested values to test canonical identity hashing. It rejects Boolean, zero, negative, non-finite, excessive, and internally inconsistent timing limits. It tests malformed and duplicate seed shapes, self-declared allocation, false allocation/freshness flags, and the execution hold.

These tests establish fail-closed preflight behavior for the stated fields. They do not independently verify loaded method identity, dependency closure, or seed freshness.

## 7a. Issue Ledger

- **Fixed in this slice:** overstatement of five selected source files as a complete source closure; unqualified `verified` receipt; order-dependent nested identity hashes; Boolean timing limits; seed declarations that could be mistaken for verified allocation.
- **Still open:** complete fresh-process source and dependency verification, historical seed exclusion audit, approved allocation, attempt runner, interruption/resume tests, measured timing, and separate execution admission.

## 8. Consistency Audit

The bounded scientific configuration and existing H3 simulation, fit, interval, and summary contracts remain unchanged. The selected source-pin check is distinguished from the broader runtime closure in the source review and receipt. The repository's non-GPU goal ledger remains H0 planning complete with H1-H9 open. The experimental status and public covered count remain unchanged. The repository load-first manifest still prioritizes the already-banked #366 coverage milestone before later MV+PE work.

## 9. What Did Not Go Smoothly

The first verifier design could have made disk hashes look like proof of loaded-code identity. Independent review found the gap and the receipt was narrowed. The first test launch also hit a sandbox write restriction in the default Julia depot; an isolated task depot resolved it.

## 10. Known Residuals

No seeds were allocated. No data were simulated. No real fit, interval, timing pilot, or screen run occurred. Source and dependency closure, historical seed freshness, durable per-attempt records, resume behavior, and runtime remain unverified. H3 and the full H2 non-GPU goal remain open.

The shared `docs/dev-log/check-log.md` and coordination board were left unchanged because path-specific lane preflight reported divergent work on those shared files. This slice's receipt is in `docs/dev-log/check-log.d/`; the project coordinator still needs to reconcile it into the shared records. The repository does not contain the prescribed `tools/closeout.py` or `tools/check-after-task.R`, so the report structure was checked manually and with the available style checker.

## 11. Team Learning

Record the scope of a checksum check in its result. Matching selected files on disk does not prove which methods a running Julia process loaded, what dependencies it loaded, or whether a seed is historically fresh.

The `HSquared.jl` load-first manifest was loaded through `python3 /Users/z3437171/shinichi-brain/tools/route.py HSquared.jl`. Its coverage-first sequencing constrained this work to preflight preparation. The Golden Set was not run; this slice did not touch a known numerical-mistake class.

## 12. Cross-Product Coverage

This change covers only the Julia H3 screen manifest and source-only preflight contract. It does NOT cover the R package, R-Julia live parity, a complete Julia dependency freeze, any model fit, statistical calibration, other route families, CPU/thread dispatch, or project completion.
