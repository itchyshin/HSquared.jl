# Arc 1 handover back to Shinichi (from Szymek's machine)

Date: 2026-11-04
Written by: Claude (Szymek's session), with Szymek's authorization to touch both arms.
Responds to: the 2026-10-24 "HSquared Arc 1 handover to Szymek" note.

## Summary

The 2026-10-24 handover can't be executed from Szymek's Mac. All four of its "exact
next work" steps need state that exists only on your Mac or on Totoro: the
`LOOP/` evidence lanes (left out of the 2026-11-03 squash), `.unlazy/…/GATES.md`, the
`/private/tmp` recovery tree, the isolated R tree, the Dropbox checkouts,
`~/shinichi-brain`, and the Totoro ControlMaster. None of the archive inventory, the
consumed-seed set or the plan-only pilot check was attempted. G0/G1 met, G2–G8 open,
`public_covered_count = 7` and v7 HOLD are all unchanged.

Szymek's machine did the parts that only need GitHub-visible state:

1. Reproducibility check of `handover/arc1-backlog-2026-11-03` (`a4677305`) on a
   second machine (macOS aarch64, Julia 1.10.13 and 1.12.6, Python 3).
2. A trial merge of that branch with current `main`, with all conflicts resolved, on a
   **separate** branch. Your branch is untouched.
3. A git-history search that identifies the R source lineage behind the v8/v10/v11
   source maps. This was the "paired R source lineage unresolved" item.
4. This note, and a reconciliation strategy for both arms (section 5).

## 1. Where things are

| Item | Location | State |
| --- | --- | --- |
| Your squashed handover | `origin/handover/arc1-backlog-2026-11-03` @ `a4677305` | Untouched. Branched from `main` @ `570f49ba` (2026-10-01); `main` is now 168 commits ahead. |
| Merge trial + this note | `origin/claude/arc1-handover-merge-main-20261104` | `a4677305` + merge of `origin/main` @ `62ab7c8d` + docs/tools commit. Draft PR, **not for merging as-is**. |
| R-lineage search | `tools/arc1_r_lineage_git_search.py`, `docs/dev-log/after-task/2026-11-04-arc1-r-lineage-git-search.json` | On the merge-trial branch. Read-only on both repos. |
| R arm pointer | hsquared `docs/dev-log/after-task/2026-11-04-arc1-handover-to-shinichi.md` | Pushed to hsquared `main` (doc only). |
| `LOOP/` evidence, `.unlazy`, recovery tree, isolated R tree | Your Mac only | Not on GitHub. Nothing here could read them. |

## 2. Findings

### F1. The Arc 1 R arm has never been pushed (lineage resolved)

`tools/arc1_r_lineage_git_search.py` hashed (SHA-256) every blob that ever existed at a
mapped path across all hsquared refs (local + every `origin` branch, fetched
2026-11-04, R `main` @ `82d8d20`) and compared them with the expected hashes in
`2026-10-24-arc1-r-lineage-comparison.json`.

- **v10 and v11 (274 paths each):** 249 paths match hsquared **`5efe0ec4`** exactly
  ("feat: harden bounded FA and GLLVM twin candidate", merged as PR #259 at `e82f5c95`,
  2026-09-30). That is the same commit your own reference comparison named. The other
  **25 paths have never existed in any pushed hsquared ref**, so they aren't stale
  versions of pushed files:
  `.Rbuildignore`, `NAMESPACE`, `R/arc1-uncertainty.R`, `R/extractors.R`,
  `R/fa-rank-selection.R`, `R/hs_control.R`, `R/hsquared.R`, `R/julia-bridge.R`,
  `R/qg-effects.R`, `man/arc1_uncertainty.Rd`, `man/hs_control.Rd`, `man/hsquared.Rd`,
  `man/hsquared_fa_rank_selection.Rd`, `man/inference_blocks.Rd`,
  `man/qg_effect_markers.Rd`, `tests/testthat/fixtures/auto_fa_rank/ordinary_start.tsv`,
  `tests/testthat/test-arc1-controls.R`, `test-arc1-live-parity.R`,
  `test-arc1-profile-v4-controls.R`, `test-arc1-profile-v4-live.R`,
  `test-arc1-profile-v4-transport-isolation.R`, `test-arc1-uncertainty-controls.R`,
  `test-arc1-uncertainty-live.R`, `test-auto-fa-rank-optin.R`, `test-multivariate.R`.
- **v8 (289 paths):** the same 249 matches and the same 25 unpushed source paths, plus
  15 `evidence/recovery-20261018/…` log paths. The v8 map mixed evidence into the
  source map.
- v10 and v11 have identical never-pushed sets.

**Meaning:** the R half of the paired G6/G7 evidence is "PR #259 + a 25-file
unpushed Arc 1 R layer". That layer exists only in the isolated R tree or Dropbox
checkout on your Mac. Your 10-24 comparison was right that neither local tree
reproduces the maps exactly. The base is now pinned to `5efe0ec4`; only the 25-file
layer is unknown. No byte of it is on GitHub, and the Julia branch carries no R
source copies either.

### F2. The handover branch fails on Julia 1.12 (merge blocker)

`test/test_auto_fa_rank.jl:756`, testset "automatic FA better-unconverged retry
trigger and bounded refusal":

```
Expression: occursin("better finite unconverged FA attempt", result.reason)
Evaluated:  occursin("better finite unconverged FA attempt",
                     "FA likelihood remains non-nested below the diagonal fit")
```

| Source | Julia | Result |
| --- | --- | --- |
| `a4677305` (handover) | 1.12.6 | 248/249, this one fails |
| `7eca0286` (its parent, last pushed pre-squash) | 1.12.6 | 248/249, same failure |
| `a4677305` | 1.10.13 | 249/249 |

So the failure is older than the uncommitted layer and depends on the Julia version.
Under 1.12 the injected "nested diagonal" balanced start ends below K0 by more than
`τ/2`, so the earlier `elseif` in `_fa_rank_result` (`src/fa_rank_selection.jl`,
reason ordering around line 1388) fires first. Your recorded passes ran under Julia 1.10.
`main` CI runs 1.10 **and** 1.12+, so this blocks any merge. It also aborts
`Pkg.test()`, because a failing top-level `@testset` throws and stops the include
chain. The full 1.12 run therefore stops at this file, after 232 earlier testsets
passed.

This is a test-fixture problem, not a selector bug. The fixture assumes
`loading = 0.1·(±1)·sqrt(g − c)` keeps K1 within `τ/2` of K0 on every platform. Fix it
in the fixture (an exactly nested start, e.g. a loading at the floor), not by
reordering the refusal reasons. Reordering would change the declared selector
semantics, which are under the G-gates.

### F3. Python guardrail tests need your `LOOP/` evidence and a Manifest

`python3 -I -m unittest discover -s test -p 'test_arc1*.py'` on `a4677305`:
174 tests, **162 pass, 1 failure, 11 errors** (1,350 s, after
`Pkg.instantiate()`; before instantiating, 4 more failed with
"Package Optim … not installed"). Every failure traces to state that exists only on your
Mac:

| Count | Tests | Cause |
| --- | --- | --- |
| 3 | `test_arc1_manifest_amendment` (changed-consumed-receipt, changed-context-hash, duplicate-log-occurrence) | `FileNotFoundError` on `LOOP/…/evidence/g2-development-nine-cell-admission-v17/candidate.json` |
| 1 FAIL | `test_exact_outer33_consumption_is_pinned_and_validate_accepts_only_that_key` | `0 != 1`: the outer33 consumption record is read from the same `LOOP/` path |
| 6 | `test_arc1_receipt_adversaries` (run admission, attempt store, fresh Julia JSON, stored rows, v4 admission, cell-closure relabeling) | `validate()` raises "fresh seed collides with historical seed-context literal 18043834289602542821". That is the consumed v14 N80/null outer32 seed. Its documented-consumption exception is loaded from `LOOP/…` (`tools/arc1_manifest.py:850`). **This is the guard working correctly:** without the consumption record, it fails closed. |
| 1 | `test_profile_search_contract_admits_v4_without_changing_legacy_meanings` | "tracked historical seed audit paths or hashes changed": the audit's tracked paths include `LOOP/` files |
| 1 | `test_arc1_pilot_cells.test_source_configuration_loads_engine_modules_from_requested_root` | **Portability defect:** hard-codes `/private/tmp/HSquared.jl-arc1-recovery-20261015` (`test/test_arc1_pilot_cells.py:323`). Your 10-24 note says that tree may not survive a reboot. |

No logic defect showed up. Two fixes are needed before these tests can run in CI:
(a) push the `LOOP/` text evidence (Step A2), or have the tests `skipTest` with an
explicit reason when the evidence root is absent; (b) make the recovery-root test build
its own temporary source root.

`python3 -I -m unittest discover -s tools -p 'test_*.py'`: 26/26 pass.

### F4. Trial merge with `main`

`claude/arc1-handover-merge-main-20261104` merges `origin/main` @ `62ab7c8d` into
`a4677305`. There were four conflicts:

| File | Resolution |
| --- | --- |
| `src/multivariate.jl` | Keep both new kwargs: `optimizer_policy` (Arc 1) and `max_dense_cells` (main #354). The Arc 1 `Pedigree` method also takes `max_dense_cells` and forwards it on its default (non-Arc 1) path. |
| `AGENTS.md` | Keep your 2026-10-11 Live Phase Snapshot. Archive main's 2026-10-01 entry verbatim. *The snapshot is still stale (you said so); refresh it yourself.* |
| `docs/dev-log/check-log.md` | Both sides; main's 2026-10-23 entries first; `# Check Log` moved back to line 1 (Arc 1 entries had been prepended above the heading). |
| `docs/dev-log/phase-snapshot-archive.md` | Both sides. |

The merged package precompiles and loads; `select_fa_rank`/`arc1_confint` are
exported. Full suite on the merge (Julia 1.10.13): **passes**: `Testing HSquared tests passed`,
410 top-level testsets, 0 failures, 19 min 48 s.
Full suite on the merge (Julia 1.12.6): exit 1. 270 testsets pass, then the run stops at the
same F2 fixture (`test_auto_fa_rank.jl:756`) and nothing after it runs on 1.12.

`main`'s #424 (shared NelderMead convergence check) and #410/#413 touched
`multivariate.jl` near Arc 1's code. Git merged those hunks cleanly, but nobody has
reviewed them semantically against Arc 1's `_arc1_select_fa_rank` path. That review
needs Gauss/Henderson.

## 3. What was *not* done (and why)

- Archive reconciliation (115 vs 114 roots, 90 archive-name paths, 18 parse exceptions):
  needs Totoro and `LOOP/`.
- Independent review of root scope, consumed-seed set and collision screen: needs the
  candidate's 240 seeds and the attempt stores in `LOOP/`.
- Consumed-history bundle rebuild, plan-only pilot: blocked on the two above.
- No fits, pilot, confirmation, tag or release. No edit to your branch, `GATES.md`,
  the checkpoint, the freeze files or the coordination boards. No gate status was
  changed.

## 4. Environment notes for reproducing on another machine

- `Manifest.toml` is untracked. Run `julia --project=. -e 'using Pkg; Pkg.instantiate()'`
  first, or the Python tests that spawn Julia fail with "Package Optim … not installed".
- Test under **both** `julia +1.10` and `julia +1.12` before claiming G7-type
  package passes; F2 shows they can diverge.

## 5. Strategy: getting both arms to a reconciled state

The goal is one place on GitHub that is the source of truth for each arm. Your Mac
should become a cache, not the only copy. Order matters: preserve first, then merge
engine code, then reconcile evidence. Gate work resumes only after that.

### Step A. Preserve the unpushed bytes (you, on your Mac; about 1 hour, no science)

1. **R arm:** from whichever tree holds the 25-file layer (isolated R tree or Dropbox
   `hsquared`), copy those files onto a fresh clone of hsquared at `5efe0ec4`.
   Don't repair the broken `.git`. Commit as
   `arc1: preserve unpushed Arc 1 R layer (v10/v11 source map)` and push to
   `handover/arc1-r-layer-<date>`. Then run
   `python3 -I tools/arc1_r_lineage_git_search.py <HSquared.jl> <hsquared> out.json`
   again. v10/v11 should report **274/274** matching that commit. If not, the bytes
   you pushed aren't the ones the maps pin, and the mismatch list says which.
2. **Julia evidence:** push the `LOOP/lanes/arc1-gaussian-reliability-20261002/` text
   evidence (receipts, manifests, JSON, logs) and `.unlazy/arc1-gaussian-reliability/`
   to `handover/arc1-evidence-<date>`, without the Julia depots and the 194 MB `.jls`.
   Store those large binaries off-git (Totoro or OneDrive) with a SHA-256 manifest
   committed in their place.
3. The other ~189 unpushed commits on your other local branches: push each as
   `handover/<name>` so nothing exists only on one disk.

### Step B. Julia arm: get engine code onto `main` (small, reviewable PRs)

1. Fix F2 in the fixture and confirm it passes on 1.10 **and** 1.12.
2. Make the Python guardrail tests skip cleanly when `LOOP/` evidence is absent (F3).
3. Base the merge on `claude/arc1-handover-merge-main-20261104`, or redo it yourself.
   The resolutions in F4 are mechanical. Have Gauss/Henderson review the #424/#410
   interaction with `_arc1_select_fa_rank`.
4. Split for review rather than one 408-file PR:
   (i) engine `src/arc1_*.jl`, `src/fa_rank_selection.jl`, `multivariate.jl` hunk and
   exports, with `test/`; (ii) `sim/arc1/` and `tools/arc1_*`; (iii) `docs/dev-log/`.
   All keep `experimental` status. Covered count stays 7.

### Step C. R arm: rebase the 25-file layer onto current hsquared `main`

1. The layer was written against `5efe0ec4`; R `main` is 156 commits ahead (#354
   `max_dense_cells` Int cast, #266 pedigree diag routes, etc.). Rebase
   `handover/arc1-r-layer-<date>` onto `main`. Expect conflicts in `R/julia-bridge.R`,
   `R/hsquared.R`, `R/hs_control.R`, `NAMESPACE`, `tests/testthat/test-multivariate.R`.
2. R exposes the Arc 1 route only behind the explicit expert opt-in, as designed. Run
   `air format .`, `devtools::document()`, `devtools::test()` with
   `HSQUARED_REQUIRE_BRIDGE=true` against the Step-B Julia `main`, and
   `devtools::check()`.
3. Merge the R PR only after the Julia PR (i) is on `main`, so live parity tests run
   against a pushed engine.

### Step D. Re-establish evidence identity

After Steps A–C, the historical G6/G7 receipts still bind the **old** source identities
(the unpushed trees). Per your 10-24 decision, a rebuilt source is a **new** identity
and inherits no gate credit. So:

1. Record a mapping file: historical source-map hash → pushed commit SHA (R: the
   Step-A commit; Julia: `a4677305` or its parent). That proves the bytes are
   preserved. It does not transfer credit.
2. Re-run G6/G7 (paired R/Julia parity, package checks) on the merged `main` SHAs.
   Those are the identities future pilot and confirmation runs should pin.

### Step E. Resume the 10-24 next-work list

Only now, with `LOOP/` evidence pushed: the 115-vs-114 root reconciliation, the 18 parse
exceptions, independent review of the consumed-seed set, the consumed-history
rebuild, then a plan-only pilot. Any reviewer, Szymek included, can then work
from GitHub alone. The pilot stays stopped until separately authorized.

### Ownership

Until Step A is pushed, the Arc 1 lane stays yours. Szymek's machine can't see the
evidence. After Step A, either of you can do Steps B–C; claim them on the
coordination board first.

## Checks run here (2026-11-04, Szymek's Mac, macOS 25.5 aarch64)

- `julia +1.12 --project=. -e 'using Pkg; Pkg.test()'` on `a4677305`: exit 1. 232
  testsets pass, then F2 fails and aborts the run (6 min 19 s).
- Standalone `test/test_auto_fa_rank.jl`: `7eca0286` on 1.12.6 248/249; `a4677305` on
  1.12.6 248/249; `a4677305` on 1.10.13 249/249.
- `python3 -I -m unittest discover -s test -p 'test_arc1*.py'` on `a4677305`: 162/174
  (1 fail, 11 errors, all classified in F3). `-s tools -p 'test_*.py'`: 26/26.
- Merge trial: `julia +1.10 … Pkg.test()` passed (410 testsets, 19 min 48 s);
  `julia +1.12 … Pkg.test()` stopped at F2 after 270 testsets (7 min 0 s).
- R lineage search: JSON SHA-256 recorded in the hsquared check-log entry of the same
  date.

FINDINGS-OF-RECORD: F1 (R layer unpushed, base `5efe0ec4`), F2 (Julia 1.12 fixture
failure), F3 (tests need evidence/env), F4 (merge-trial resolutions).
