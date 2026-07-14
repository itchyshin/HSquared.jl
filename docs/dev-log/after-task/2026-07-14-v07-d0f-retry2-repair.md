# After-task report — v0.7 D0F retry-2 blocker and prospective retry-3 repair

## 1. Goal

Preserve the second failed D0F root without post-hoc replay, prospectively
repair the Julia command-construction defect, and keep the R/Julia evidence
contract fail closed before any further seed is opened.

## 2. Implemented

The stage replay tool now returns concrete Git strings, constructs every
command with `String[...]`, and tests the exact `SubString` Git-root type that
failed on Totoro. It also exposes a zero-seed `--mode=preflight` that validates
the sealed tree and executes the exact Julia-side Git/blob checks before any
phenotype is generated. The R twin retires retry-2 seeds, reserves disjoint retry-3
bases `2034000000` / `2035000000`, and freezes exact downstream schemas,
histories, summaries, reviews, paths, and deployed Git provenance.

## 3a. Decisions and Rejected Alternatives

Post-hoc replay, seed reuse, pooling, threshold changes, and interpreting a
preflight exception as estimator evidence were rejected. A new D0F root may be
minted only after committed bytes, fresh exact reviews, and a live Julia 1.10
preflight.

## 4. Files Touched

The Julia D0F/D1 replay tool and sidecar, phase/check/coordination/checkpoint
evidence, and the R twin's doc 49, seed lock, downstream contract, and tests.
The untracked downstream Julia replay remains an incomplete scaffold and is
not landed or evidence.

## 5. Checks Run

- Julia stage-replay selftest: PASS.
- Updated Julia script/sidecar, Bash syntax, and launcher guard selftest: PASS
  locally; the actual zero-seed preflight remains a live Julia 1.10 retry-3
  admission gate.
- Full Julia `Pkg.test()`: PASS.
- Julia tool sidecar and `git diff --check`: PASS.
- R tooling 52/52, preseal 222/222, downstream 157/157: PASS.
- Built-package R `R CMD check --no-manual`: 0 errors, 0 warnings, 0 notes.
- R selftests and sidecar/diff checks: PASS.
- Earlier Fisher/Grace/Noether repair reviews: `CLEAN`; fresh exact preflight
  review was Grace `CLEAN`, Fisher/Noether `BLOCKED`, and exposed the two
  neighbouring defects above. Exact review renewal is pending the landed fix.

## 6. Tests of the Tests

The new exact regression passes a `SubString` root through Git-blob hashing.
Neighbouring R mutations reject retired-seed overlap, malformed sidecars,
symlink aliases, changed blobs/HEADs/implementation surfaces, substituted
reviewers, stale driver commits, broken counts, and skipped history.

## 7a. Issue Ledger

| Issue | Disposition |
| --- | --- |
| `Cmd(::Vector{AbstractString})` before replay row 1 | Force concrete `String` vectors and reproduce the live runtime type. |
| Retry-2 completed R work but no Julia replay | Retire the entire root; no partial admission. |
| A matching blob did not bind deployed state | R contract now requires HEAD, ancestry, clean trees, and unchanged fitted surfaces. |
| Downstream scaffold names differ from frozen R schema | Keep it untracked/non-evidence; reconcile before sidecar or commit. |
| Preflight admitted an existing base-R output subtree | Add a strict preseal-only tree validator and mutation-test every output subtree and summary. |
| D1 producer and downstream admission disagreed at 0–1 successful fits | Preserve `summary_nonfinite` as a secondary reason under low-convergence precedence and add a cross-layer regression. |

## 8. Consistency Audit

Both twins, Totoro counts, hashes, processes, two retired D0F roots, seed spaces,
D1/D2 consumption, public status, and adjacent provenance bypasses were swept.

## 9. What Did Not Go Smoothly

The live type defect appeared only after 576 official fits and 576 base-R
recomputations. Three independent review cycles were needed to close nearby
schema, low-convergence, reviewer, path, and Git-state gaps.

## 10. Known Residuals

Retry 3 has not been presealed or run. The R downstream recomputer and Julia
downstream replay are incomplete. D1-D4, adjudication, Rose, G10, and activation
remain outstanding.

## 11. Team Learning

Evidence tooling must test production runtime types and bind deployed state,
not just plausible hashes or commit strings.

## 12. Cross-Product Coverage

This is evidence-machinery repair only. It does NOT cover recovery, activation,
capability promotion, `public_covered_count` change, release, or G10.
