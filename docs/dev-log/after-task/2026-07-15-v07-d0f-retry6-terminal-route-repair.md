# After-task report — Retry-6 terminal route blocker and seed-free repair

## 1. Goal

Own Retry 6 sequentially, consume a phenotype only after every admission gate
was green, adjudicate D0F fail closed, and open D1 only after a formal D0F
`PASS/COMPLETE`.

## 2. Implemented

Retry 6 completed all official, independent base-R, and exact Julia D0F routes.
The first canonical post-run receipt writer exposed an adjudicator route-binding
defect before writing any receipt, so the full root and seed spaces were retired.
The R twin received a seed-free D0F/D1 route-threading repair plus explicit
Retry-6 seed retirement. Cross-twin status, checkpoint, check log, and handover
were updated without touching the retired root.

## 3a. Decisions and Rejected Alternatives

Repair-in-place, subset adjudication, pooling the three complete summaries,
manually minting receipts, opening D1, and reusing unused Retry-6 seeds were
rejected. The complete root is immutable diagnostic evidence. The prospective
repair is synthetic/test-only and cannot retroactively adjudicate Retry 6.

## 4. Files Touched

- Julia: `AGENTS.md`, `ROADMAP.md`, capability status, coordination board,
  phase-snapshot archive, this report, the terminal checkpoint, check receipt,
  handover, and `src/multivariate.jl` (deterministic covariance-boundary guard
  discovered by exact-head CI).
- R twin: route-aware preseal/recompute helpers and tests, recomputer sidecar,
  seed-lock registry and tests, doc 49, roadmap/capability/coordination status,
  and matching closeout documents.
- Preserved and untouched: two H2-2 Retry-5 drafts in each twin and the
  quarantined untracked Julia downstream scaffold.

## 5. Checks Run

- Retry-6 official/base-R/Julia inventories: 576/576/576 complete.
- Retry-6 parity: maximum attempt `3.1832314562052488e-12`; maximum summary
  `7.1054273576010019e-15`.
- R recovery-v3 test family: 822 pass, 0 fail, 0 warn, 0 skip.
- R seed-lock focused file: 60/60 pass; all relevant selftests and checksum
  verification passed; `git diff --check` passed.
- Totoro freeze audit: root digest unchanged, all members read-only, no live
  root worker.
- Cross-twin `handoff_gate.sh`: exit 1 only for the declared H2-2 drafts,
  quarantined scaffold, and pre-existing legacy branches; active heads pushed.
- Julia 1.10 full local `Pkg.test()`: pass after the explicit near-correlation
  boundary guard. The original exact-head CI was green on current Julia and
  red on Julia 1.10 at the existing boundary test; R CI and Julia Documenter
  were green. Final Julia exact-head CI is recorded when the repair commit is
  validated.

## 6. Tests of the Tests

The repaired D0F and D1 tests first show that Julia replay rows fail under the
ordinary default, then pass only with `julia_profile_replay`. Wrong-driver
mutations remain red. Seed-lock mutations reject collisions with each retired
phenotype/bootstrap space, including Retry 6, and assert that no proposed D0F
retry stage exists.

## 7a. Issue Ledger

| Issue | Disposition |
| --- | --- |
| Summary reconstruction discarded the admitted Julia route | Fixed prospectively for both D0F and D1; Retry 6 remains unadjudicated. |
| Retry-6 seeds were still labelled proposed after root retirement | All 576 phenotype and three bootstrap seeds moved to the historical lock; no successor base allocated. |
| H2-2 and this task briefly appeared concurrent | H2-2 archived; this task is the sole lane; lesson recorded in durable user memory. |
| One verification command used a stale driver filename | Corrected immediately to the live tool names; the preceding route-only suite was green. |
| Full-suite validation fixture lost its test-only helper | Added a defensive local helper load in the R twin; no package behavior changed. |
| Julia 1.10 Linux treated the nearly rank-one covariance fixture as finite-information | Made the already documented boundary rejection explicit and platform-independent; full local Julia 1.10 suite passes. |

## 8. Consistency Audit

The same route-default class was checked in D0F and D1, not only at the failing
call site. Both twin status surfaces, the phase snapshot/archive, seed registry,
Totoro root/process state, public count, and handover were swept. The retired
Retry-4/5 roots and the quarantined scaffold were not inspected or changed.

Memory receipt: `/ask-brain` was used for the lane-history question. Both
`route.py` calls reported no repo LOAD-FIRST manifest, so the repository's own
AGENTS/docs remained technical truth. The Golden Set was not run because this
slice did not diagnose a brain-retrieval regression.

## 9. What Did Not Go Smoothly

The route defect appeared only after all 1,728 evidence rows existed, because
admission was correct and the later summary helper silently rebound the route.
The canonical receipt writer therefore failed after a scientifically clean D0F
corpus. The stale selftest filename in one local chained command also caused a
non-product exit after the full test family had passed.

## 10. Known Residuals

Retry 6 has no formal adjudication and never can. D1-D4, final Rose activation
audit, G10, merge, release, and public activation remain outstanding. The
prospective repair and the Julia boundary hardening still require final CI at
their exact heads. No successor contract or seed base exists.

## 11. Team Learning

An admitted route is part of summary provenance and must be threaded through
every reconstruction layer. After any terminal evidence root, retire the full
reserved seed spaces in executable code, not only prose. Codex-created tasks
must also be named and announced explicitly so a handover cannot be mistaken
for a silent concurrent lane.

## 12. Cross-Product Coverage

This covers the D0F/D1 summary route-binding contract, exact negative controls,
and Retry-6 seed retirement. It does NOT cover Retry-6 adjudication, scientific
recovery, D1-D4 execution, the default R route, capability promotion, production
sparse genomic fitting, calibrated intervals, G10, merge, release, or a
`public_covered_count` change.
