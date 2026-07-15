# After-task report — v0.7 D0F retry-4 endpoint-representation blocker

## 1. Goal

Execute the preregistered retry-4 D0F chain, stop honestly on any failed gate,
and leave both twins with an exact, durable disposition that neither overclaims
diagnostic output nor permits post-hoc repair of a sealed evidence root.

## 2. Implemented

Retry 4 completed its official R route and independent base-R recomputation.
The exact Julia replay stopped fail-closed. The root, hashes, row counts, seed
spaces, localized one-ULP endpoint mechanism, admissible claims, and required
fresh-repair path are now recorded in a cross-twin recovery checkpoint. Active
AGENTS, ROADMAP, Documenter, capability/debt, coordination, check-log, and
phase-snapshot surfaces were synchronized to the negative endpoint without
changing engine behaviour or status rows.

## 3a. Decisions and Rejected Alternatives

The root is classified
`UNADJUDICATED — REPLAY_ENDPOINT_REPRESENTATION_BLOCKER`. Repairing its validator,
resuming its 121 missing replay rows, skipping affected boundary rows, treating
the base-R `COMPLETE` summaries as evidence, or calling the raw `fit_error` a
solver/KKT failure were rejected. The preseal binds the exact replay tool and
the complete attempted-seed denominator.

## 4. Files Touched

AGENTS and its verbatim snapshot archive, ROADMAP, genomic Documenter prose,
capability and validation-debt ledgers, the current coordination row, check
logs, the recovery checkpoint, and this after-task report. No Julia source,
test, fixture, or simulation implementation changed; the untracked replay
scaffold remains excluded.

## 5. Checks Run

The Totoro pre-run five-review set, clean deployment, preseal, zero-seed
preflight, n-ladder, and smoke were green. Official R fits were 576/576 and
base-R recomputations 576/576. Exact replay admitted 455 rows with maximum
official-versus-replay difference `2.2453150450019166e-12` before failing
closed. Full `Pkg.test()` passed; Documenter/Vitepress built; the preamble cap
passed at one snapshot and 7,180 bytes; and the after-task and diff checks
passed. Existing Documenter missing-docstring and npm-audit warnings were
unchanged and non-blocking.

## 6. Tests of the Tests

The live replay gate turned red on one-ULP boundary endpoint reconstruction
differences while retaining its admitted prefix. Prior mutation gates remained
red for changed attempts, packets, hashes, batch membership, partial output
pairs, non-prefix resume, and child-process failure. A fresh repair must add
explicit lower/upper one-ULP acceptance tests and a genuine disagreement
mutation that remains red.

## 7a. Issue Ledger

| Issue | Disposition |
| --- | --- |
| Retry-4 replay stopped after 455 rows | Retire the whole root; do not resume or salvage it. |
| Five boundary ratios differ by one ULP | Classify as endpoint-representation contract drift, not scientific fit failure. |
| Four batches stopped at first affected rows | Report 121 rows without replay output, never 121 failures. |
| Base-R summaries say `COMPLETE` | Treat as diagnostic only because no Julia summary/receipt exists. |
| Raw error says `boundary_kkt_representation_drift` / `fit_error` | Record it as validator error-classification drift, not KKT/solver evidence. |
| Activation goal remains open scientifically | Continue only through a new preregistration, repaired validator, fresh preflight/reviews/preseal, and disjoint Retry-5 seeds. |

## 8. Consistency Audit

The Rose sweep covered Julia AGENTS snapshot, ROADMAP passages, capability
status, validation debt, genomic Documenter prose, current coordination row,
check log, checkpoint, and after-task surfaces; the R twin performed its
corresponding API/public/article/doc-49 sweep. Historical retry-1–3 and
recovery-v2 records remain verbatim.

## 9. What Did Not Go Smoothly

The official and independent routes completed before a representation-level
validator assumption stopped the replay. The original exception label looked
scientific, but packet-level review showed a one-ULP reconstruction difference
with the engine-declared endpoint. The attempted first checkpoint write also
did not land after truncated tool output and was recreated explicitly.

## 10. Known Residuals

The ordinary genomic route remains held. A prospective replay repair, boundary
regression mutations, a diagnostic mechanism preflight across all 13 retired
boundary packets plus interiors, exact reviews/preseal, fresh Retry-5 D0F,
downstream stages, final Rose audit, and maintainer G10 remain. The quarantined
Julia downstream-replay scaffold remains non-evidence.

## 11. Team Learning

Numerical endpoint declarations are part of the cross-language result contract.
Replay should preserve the engine declaration and compare rederived quantities
under a frozen tolerance; infrastructure contract exceptions must not be
collapsed into scientific `fit_error`.

## 12. Cross-Product Coverage

This closes retry 4 as a clear negative infrastructure endpoint. It does NOT cover
recovery, bias, convergence performance, public activation, broad
genomic robustness, production scale, or any capability/count move. The
validation-scale supplied-`Ginv` estimator alone retains its existing covered
status and `public_covered_count` remains 5.
