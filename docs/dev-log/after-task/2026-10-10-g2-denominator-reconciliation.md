## 1. Goal

Resume Arc 1 from its retained checkpoint and reconcile the conflicting outer31 development-denominator language without changing allocation or authorizing a run.

## 2. Implemented

Replaced the one-sided outer61 proposal with a review-only reconciliation that follows the owner-approved allocation: outer31 counts in the N=80/null 30-case denominator and reference subset; `gate_credit: false` means the pre-run alone cannot advance G2. Updated the checkpoint. Candidate v5 passed exact-source review and remains non-executable. A prior reference candidate failed current-source preflight, so I prepared a current-source, review-only timing pilot using only previously consumed outer7/10; its offline preflight and 19 tests pass. No Julia run, seed generation, manifest change, or Totoro contact occurred.

## 3a. Decisions and Rejected Alternatives

Followed the explicit denominator rule in the proposal and independent review, which the adoption record says the owner approved. No new assumption was needed. `gate_credit: false` is retained as a limit on gate advancement, not denominator membership. Rejected automatically excluding outer31 and adding outer61 because that would supersede the adopted plan. The separate 269-attempt execution approval remains outstanding.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-development-nine-cell-admission-v3/allocation-reconciliation-candidate.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-development-nine-cell-admission-v4/allocation-reconciliation-candidate.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-development-nine-cell-admission-v4/build_candidate.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-development-nine-cell-admission-v4/test_candidate.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-development-nine-cell-admission-v4/candidate.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-development-nine-cell-admission-v5/allocation-reconciliation-candidate.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-development-nine-cell-admission-v5/build_candidate.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-development-nine-cell-admission-v5/test_candidate.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-development-nine-cell-admission-v5/candidate.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-reference-time-pilot-v6/README.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-reference-time-pilot-v6/build_candidate.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-reference-time-pilot-v6/candidate-contract.toml`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-reference-time-pilot-v6/candidate.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-reference-time-pilot-v6/expanded_reference.jl`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-reference-time-pilot-v6/run_reference.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-reference-time-pilot-v6/source-lock.tsv`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-reference-time-pilot-v6/test_reference.py`
- `docs/dev-log/after-task/2026-10-10-g2-denominator-reconciliation.md`

## 5. Checks Run

- Repo `lane_preflight.sh`: one Codex lane listed; it says its handover records historical receipt and asks the current Codex owner to confirm. The user directly resumed this goal in this task.
- `node ~/.codex/skills/unlazy/scripts/gate-check.mjs --status .unlazy/arc1-gaussian-reliability/GATES.md`: 4 met, 5 open (G0/G1/G6/G7 met; G2–G5/G8 open).
- Inspected the approved proposal, independent review, adoption, outer31 receipt, current checkpoint, and independent Astra review. The source texts conflict in implication; they do not prove that seed61 is required.
- Candidate v4 was independently reviewed PASS as non-executable; its reviewer noted the note still called owner confirmation pending, so v5 was prepared to align with the adoption record.
- Candidate v5 builder and five tests pass; `py_compile` passes. The candidate pins nine cells, 269 remaining indices, existing sources and runtime paths, and has `execution_authorized: false`.
- Candidate-v5 test-of-tests passed: baseline 5/5; changing `execution_authorized` to true was caught by the review-only assertion.
- Current-source candidate v5 exact Astra review is requested and pending.
- The older `g2-reference-only-v5` preflight was refused because six input/source pins were stale, including `sim/arc1/engine_io.jl` and `src/fa_rank_selection.jl`; no Julia started. The new v6 lock refreshes 49 paths.
- Candidate `g2-reference-time-pilot-v6` preflight passed with `julia_started=false`; its 19 offline tests passed. Estimate is 180 seconds for two consumed cases, with a 1,800-second hard wall. Astra exact-source review is pending; no run has started.
- Preliminary full-tranche estimate, not a run authorization: 269 ordinary fits at the measured outer31 58.245-second case time across four workers is about 65 minutes. The preselected 180 reference audits at the prior uncertain estimate of 90 seconds each across four workers add about 68 minutes. Base estimate is about 2 hours 13 minutes before flagged-fit audits; each extra reference audit adds about 23 seconds. This can cross three hours if more than about 126 extra audits are needed, so the exact current reference timing pilot is needed before forecasting the full tranche.
- `Rscript .../check-after-task.R` passed; `git diff --check` passed; `slop_check.py` on the absolute report path returned 0 findings in 701 words.
- `route.py "$PWD"` returned no LOAD-FIRST manifest for this worktree; used the supplied repository instructions and the repo's own retained documents as technical truth.
- `closeout.py new` could not be used because that helper resolves its root to the brain checkout outside this writable workspace. A report was created in the authorized HSquared worktree; this environment limitation is recorded rather than bypassed.

## 6. Tests of the Tests

The G2 candidate tests exercise source pins, seed vectors, output paths, consumed outer31 binding, exact denominator counts, and non-executable status. A mutation that sets `execution_authorized=true` fails the review-only assertion. The timing-pilot harness passes its retained offline adversarial suite (19 tests), including bad candidate/review refusals, source drift, cleanup, and malformed child output. Astra passed exact v5 allocation-candidate review; Astra review of the timing pilot is pending.

## 7a. Issue Ledger

- Fixed in the candidate/checkpoint: prior text treated outer31's `gate_credit: false` as proof it must leave the development denominator, despite the approved proposal, review, and adoption record.
- Open: fresh exact-source review of v5 and current measured runtime estimate.
- Open: fresh exact-source admission and measured runtime estimate for the remaining allocation.
- Open: separate approval before any remaining development tranche run.

## 8. Consistency Audit

Compared the proposal, independent review, adoption, retained receipt, candidate, and checkpoint. The proposal and review explicitly keep outer31 in the denominator and reference subset; the adoption records owner approval; the receipt withholds standalone G2 credit. Candidate v5 covers indices 32–60 in N80/null and 31–60 in the other eight cells. No gate, manifest, production source, or capability-status file was changed.

## 9. What Did Not Go Smoothly

The previous reconciliation draft overstated the evidence for excluding outer31. Astra returned HOLD, correctly identifying that no-credit does not alone mean denominator exclusion. The brain `route.py` found no worktree manifest, and the brain closeout helper attempted to write into a different repository; no write occurred there.

## 10. Known Residuals

Candidate v5 is still a review-only draft because it lacks exhaustive manifest-verification evidence in each nested admission. The timing pilot has not been independently reviewed or run. The 269 remaining attempts are not approved to run; the full-tranche runtime estimate remains preliminary and depends on flagged-fit counts. G2–G5 and G8 remain open. Parent automatic-rank and complete non-GPU H2 goals remain incomplete. Capability remains experimental; covered count remains seven.

## 11. Team Learning

Do not infer denominator membership from a `gate_credit` flag when an approved protocol states the denominator separately. Apply the recorded owner-approved denominator and keep gate advancement distinct. Memory receipt: the repo LOAD-FIRST route was absent; the project instructions, current checkpoint, and source records shaped the work. Golden Set: not run; this was allocation-document reconciliation and admission-draft engineering, with no production estimator change.

## 12. Cross-Product Coverage

Covers: Julia Arc 1 allocation documentation and checkpoint only.

Does NOT cover: R behavior, Julia implementation correctness, pilot or confirmation evidence, FA uncertainty calibration, repeatability interval calibration, public grammar, releases, GPU, or capability promotion.
