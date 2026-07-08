# After-task: defect 5 — the `[0,1]` flag was anchored at the uncrossed end

**Date:** 2026-07-08 · **Agent:** Claude (Opus 4.8), second session · **Lane:** Julia
(`HSquared.jl`), entered from an R-lane session on explicit maintainer instruction; plus the
`shinichi-brain` hub lane
**Branch:** `feat/2026-07-08-plotting-aog` · PR
[#264](https://github.com/itchyshin/HSquared.jl/pull/264)
**Active lenses:** Rose (real subagent, 2nd audit), Florence (visual), Curie (tests of tests),
Grace (CI), Ada
**Spawned subagents:** yes — one `rose-systems-auditor` on the delta

## 1. Goal

Rehydrate from `handover/2026-07-08-claude-handover.md` and work its Next Immediate Steps: land
the hub `LESSONS.md` entry, bring PR #264 to a merge decision, update the coordination board. Do
not commit the parallel session's uncommitted file.

## 2. Implemented

**Hub (`shinichi-brain`, pushed to `origin/master`):**

- `d85299f` — root guard for `rose-pattern-scan.R`. The handover declared this gate fixed; the
  negative control showed it still exited 0 on a nonexistent root.
- `58a2936` — the `LESSONS.md` "gate that cannot fail" entry, **corrected before landing** to say
  that restoring the missing `main()` had not restored the gate.
- `bbc1c34` — locale-independent matching (`useBytes = TRUE`). 301 `grep()` warnings → 0.

**Julia lane (`HSquared.jl`, this branch):**

- `ext/HSquaredMakieExt.jl` — defect 5: the `[0,1] boundary` flag was anchored at `d.hi[i]` for
  every crossing, though the gate fires on `lo ≤ 0 || hi ≥ 1`. Now anchored at the crossed end,
  both ends when both cross; `xautolimitmargin` headroom on the flagged side(s) only.
- the live-draw driver — asserts anchor **position, row, and alignment** across three payloads
  (`vc` lo-crossing, `vc_hi`, `vc_both`); **rasterizes before asserting** so the figures exist on
  a failing run.
- `.github/workflows/CI.yml` — opt-in `plotting` job (`workflow_dispatch` input `run_plotting`,
  default `false`), runs the driver, uploads the PNGs, `timeout-minutes: 45`.
- claim surfaces reconciled: `13-plotting-layer.md`, `check-log.d/`, `AGENTS.md`, `runtests.jl`
  (comment only), plus a partial-supersession banner on the prior after-task report.

## 3a. Decisions and Rejected Alternatives

- **Did not merge PR #264.** `handoff.md` reserves the merge for the maintainer. Escalated instead.
- **Did not commit `Shinichi/methods/…Ayumi bird-data probe.md`.** Another session's uncommitted
  work. Every hub commit used an explicit pathspec; the file's hash was verified identical
  (`b863816832a9d5e3`) before and after all three commits, and it appears in none of them.
- **Did not fix the `lo = NaN, hi = 1.2` asymmetry** (Rose's non-blocking observation). The
  `isfinite(lo) && isfinite(hi)` conjunction means such a row is neither whiskered nor flagged.
  Consistent, arguably correct, and out of scope. Recorded as a residual.
- **Rejected "report only" for the locale warnings.** No false negative was demonstrated, but a
  scanner whose verdict can depend on `LANG` is not a gate. Maintainer chose hardening.
- **Mutations applied to a package *copy*,** never to the working tree, so no run could leave the
  repo dirty.

## 4. Files Touched

`shinichi-brain`: `tools/rose-pattern-scan.R`, `memory/LESSONS.md`.

`HSquared.jl`: `ext/HSquaredMakieExt.jl`, `docs/dev-log/scripts/2026-07-08-plotting-aog-livedraw.jl`,
`.github/workflows/CI.yml`, `docs/design/13-plotting-layer.md`,
`docs/dev-log/check-log.d/2026-07-08-plotting-aog.md`, `test/runtests.jl` (comment only),
`AGENTS.md`, `docs/dev-log/after-task/2026-07-08-plotting-aog.md` (banner), this report.

`hsquared`: **none.** R lane untouched, `main` clean and synced throughout.

## 5. Checks Run

| Command | Result |
| --- | --- |
| `julia --project=. .../2026-07-08-plotting-aog-livedraw.jl` | `ALL LIVE-DRAW CHECKS PASSED`; 9/9 kinds; `flag_placement = "ok (lo / hi / both)"` |
| `Pkg.status` | AoG 0.13.0 · Makie 0.24.13 · CairoMakie 0.15.13 · Julia 1.10.0 |
| `julia --project=. -e 'import Pkg; Pkg.test()'` | `Testing HSquared tests passed`, exit 0 (dependency-free posture intact) |
| opened `forest.png` / `caterpillar.png` | flag now at the crossed end, right-aligned, unclipped |
| `python3 -c "yaml.safe_load(...)"` on `CI.yml` | parses; `plotting.if = ${{ inputs.run_plotting }}`; `timeout-minutes: 45` |
| `Rscript tools/rose-pattern-scan.R` × 4 roots | violation→1, clean→0, nonexistent→1, typo'd→1 |
| `Rscript tools/check-after-task.R <this file>` | see below |
| `python3 tools/memory_delta_check.py` | `OK — no 'memory/*.md' file shrank > 25%` |

## 6. Tests of the Tests

Every gate touched was made to go red on purpose.

| Gate | Negative control | Result |
| --- | --- | --- |
| driver — marker layer | re-add the manual `scatter!` | exit 1, `axis[1] double-draws markers` |
| driver — annotation gate | replace the `lo ≤ 0` condition with `true` | exit 1, `annotation fired on the control payload` |
| driver — **anchor** (new) | regress the `lo` branch to anchor at `hi` | exit 1, `lo-crossing flag anchored at 0.72, not lo` |
| driver — PNGs on a red run | run a failing mutation, list `*.png` | both figures written (78,618 / 63,496 bytes) |
| `rose-pattern-scan.R` | nonexistent + typo'd root | exit 1 (was **0**) |
| `rose-pattern-scan.R` | `source()` must not auto-run | no auto-run, functions defined |
| `rose-pattern-scan.R` | verdicts under `LC_ALL` ∈ {`C`, `en_AU`, `en_US.UTF-8`} | identical |
| `check-after-task.R` | nonexistent path | exit 1 |

Mutations were applied to a copy of the package (`Project.toml` + `src/` + `ext/`) dev'd into a
scratch environment. The working tree was never dirtied.

## 7a. Issue Ledger

PR [#264](https://github.com/itchyshin/HSquared.jl/pull/264) — open, `MERGEABLE`, `CLEAN`, two
Rose audits (both PROMOTE-WITH-CHANGES, all required changes applied). Merge is the maintainer's,
per `handoff.md`. No new issues filed.

## 8. Consistency Audit

Patterns used: `grep -rn -i "four defect\|three of the four\|Four defect classes"`,
`grep -rn "CI cannot see this\|local-only\|only by a local live draw"`, both `--exclude-dir=.git`.

The defect count and the "not in CI" absolute each appeared on **five** surfaces. Rose named four;
the sweep found the rest. All live claim surfaces now say **five defect classes, two of them found
only by rendering**, and distinguish *default* CI from the opt-in `plotting` job. Remaining hits are
confined to dated historical records (`handover/2026-07-08-claude-handover.md`, and the prior
after-task report, which now carries a partial-supersession banner naming both overtaken claims).

Coverage pins re-checked, all **UNCHANGED**: `public_covered_count` **5**, rows **55**, covered
**13**, `validation_status.jl` untouched. **Nothing promoted.**

## 9. What Did Not Go Smoothly

The handover asserted that both hub R validators were "fixed and pushed." One was not: restoring
`rose-pattern-scan.R`'s missing `main()` made it *run*, while `list.files()` silently globbed a
missing root into zero files, so the gate still could not fail. I came within one command of
committing a `LESSONS.md` entry titled *"a gate that cannot fail is not a gate"* whose own claim to
have fixed one was false. It was caught only by running the negative control on the repaired gate
instead of reading its write-up.

Then the same shape recurred in my own work, twice. My live-draw driver counted the `[0,1]`
annotation and never asked where it sat — which is exactly how defect 5 survived a full Rose audit.
And my new CI job uploaded figures `if: always()` while the driver rasterized *last*, so a red run
would have had nothing to upload. Rose caught the second; the first I caught only by rendering the
PNG and looking at it, as the branch's own documentation instructs.

## 10. Known Residuals

- **Merge and coordination board.** PR #264 unmerged; the board still reads "Julia lane: this
  repository" and does not record that this slice ran from an R-lane session. The handover gates the
  board update on the merge landing. Both await the maintainer.
- **`lo = NaN, hi = 1.2`** is neither whiskered nor flagged (pre-existing; `isfinite` conjunction).
- **Facet-order assumption** (`sort(unique(panel))`) remains empirical on AoG 0.13.0. The shape guard
  sees a facet-*count* mismatch, not a re-ordering.
- **`julia-actions/cache@v2`** keys off the workspace project, not the scratch env in `RUNNER_TEMP`,
  so the `plotting` job re-downloads Makie/AoG each run.
- **`flags()`** does not assert the annotation *string*.
- One machine, one version set (Julia 1.10.0, macOS/arm64). No cross-version or cross-platform claim.
- **No false negative was demonstrated** for the pre-hardening locale behaviour, and none was proven
  absent. `useBytes = TRUE` removes the question rather than answering it. Patterns must stay ASCII.

## 11. Team Learning

**Fixing a gate is not testing it.** Three separate gates in this session were green because they
could not go red: `rose-pattern-scan.R` passed on a nonexistent root; the stub test passes precisely
when the extension fails to load; and the driver counted an annotation without checking its position.
Each was found by running the negative control *on the tool*, never by reading its output. Run the
negative control on the gate you just repaired — not only on the one you already distrust.

**A verifying agent authors the drift it verifies.** The prior session found four dead gates and, in
the same breath, wrote a fifth false claim. I found its false claim and then shipped a dangling
`(see below)` evidence pointer and a defect count that contradicted itself across five files — the
same class, one audit later. Finding the bugs is not evidence you did not add one. Rose is the
control, and Rose's own list was not exhaustive: she named four surfaces, the sweep found five.

**Counting is not checking** — the compact form of the plotting lesson, and the reason the driver now
asserts position, row, and alignment rather than `nplots(ax, Text) == 1`.

## 12. Cross-Product Coverage

Three cross-cutting changes. Each is a transformation, not a feature, so each is enumerated on the
product axis.

**A. The `[0,1]` boundary flag (anchor rule) — `ext/HSquaredMakieExt.jl`.** A rule applied to every
h² row of every `:variance_components` payload.

- **covers ✓** `lo ≤ 0` (flag at `lo`, right-aligned, left headroom); `hi ≥ 1` (flag at `hi`,
  left-aligned, right headroom); **both** ends crossed (two flags, headroom both sides); strictly
  interior (no flag, no headroom — the control payload); non-`heritability` panels (never flagged);
  `lo` and `hi` both non-finite (no flag, no whisker). Each is a driver assertion.
- **does NOT cover ✗** `lo` finite and `hi` non-finite, or vice versa — the `isfinite && isfinite`
  conjunction skips the row entirely, so a `lo = NaN, hi = 1.2` interval is neither whiskered nor
  flagged. Pre-existing, unchanged, untested. **✗** an h² panel carrying *multiple* rows: the
  per-row assertions use single-row payloads, and `flags()` checks the anchor row but no payload
  exercises two flagged rows on one panel. **✗** the annotation *string* is never asserted.

**B. The opt-in `plotting` CI job — `.github/workflows/CI.yml`.** A control switch on the whole
drawing layer's CI posture.

- **covers ✓** `workflow_dispatch` with `run_plotting = true` → job runs the driver, uploads PNGs.
  `pull_request` → `inputs` is empty → falsy → skipped, so the dependency-free `test` job and the
  default posture are unchanged (verified: `Pkg.test()` green, `test` job unconditioned). Red runs
  still upload figures (driver rasterizes before asserting; verified — 78,618 / 63,496 bytes).
- **does NOT cover ✗** the job has **never been executed on GitHub** — validated locally by YAML
  parse + schema inspection only. Ubuntu/CairoMakie headless rendering, the `upload-artifact@v4`
  glob outside the workspace, and the `julia-actions/cache@v2` miss on `RUNNER_TEMP` are all
  *unexercised*. **✗** it does not run on `push`, nor automatically on PRs touching
  `ext/HSquaredMakieExt.jl` — a human must remember to dispatch it. **✗** no cross-OS or
  cross-Julia-version matrix.

**C. `useBytes = TRUE` in `rose-pattern-scan.R` — `shinichi-brain`.** Applies to all four patterns
and every file the scanner reads.

- **covers ✓** all four current patterns are ASCII, so byte matching is semantically identical;
  identical verdicts verified under `LC_ALL` ∈ {`C`, `en_AU`, `en_US.UTF-8`}; `fixed = TRUE` and
  `fixed = FALSE` paths both exercised; 301 locale warnings → 0; the real vault still passes.
- **does NOT cover ✗** any **non-ASCII pattern** added later will silently match bytes, not
  characters — the guard is a comment, not a test. **✗** `perl = TRUE` is not used and not guarded
  against. **✗** no false negative was ever demonstrated pre-hardening, and none was proven absent:
  the change removes the question rather than answering it. **✗** the sibling `check-after-task.R`
  reads files with `readLines()` too but was not audited for the same locale exposure.
