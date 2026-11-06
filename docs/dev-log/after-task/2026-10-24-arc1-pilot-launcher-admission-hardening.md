## 1. Goal

Build and independently review the source-bound launcher contract for the eight unrun Arc 1 FA-rank pilot cells. This slice covered launcher and admission engineering plus a no-fit plan. It carried no pilot execution authority.

## 2. Implemented

- The batch admission validator requires `Project.toml` and `Manifest.toml` pins, validates their lowercase 64-character SHA-256 format, and checks them against the source map.
- The full eight-cell batch validator rejects admissions carrying a single-attempt review scope.
- Two focused regression tests cover these contracts.
- A refreshed candidate copy of the eight admissions was created at `/private/tmp/arc1-pilot-admission-candidate-20261024-env-scope-fix/`. The earlier candidate remains unchanged.
- The current launcher generated a no-fit plan against the retained recovery tree. Curie independently reviewed the regenerated plan and source lock.

## 3a. Decisions and Rejected Alternatives

The batch retains its four-worker cap and one Julia and BLAS thread per job. Environment pins must be present and consistent at admission time. Single-attempt review scope cannot authorize a full batch. Candidate artifacts remain separate from execution authorization.

## 4. Files Touched

Changed in the retained recovery tree:

- `/private/tmp/HSquared.jl-arc1-recovery-20261015/tools/arc1_manifest.py`
- `/private/tmp/HSquared.jl-arc1-recovery-20261015/sim/arc1/run_pilot_cells.py`
- `/private/tmp/HSquared.jl-arc1-recovery-20261015/test/test_arc1_pilot_cells.py`

Created candidate artifacts:

- `/private/tmp/arc1-pilot-admission-candidate-20261024-env-scope-fix/batch.json` and its eight admissions
- `/private/tmp/arc1-pilot-current-launcher-dryrun-20261024-env-scope-fix/results/plan.json`

This report is the only file changed in the Codex worktree for this slice. All pre-existing dirty paths were preserved. Recovery Git metadata was left as found. No commit or push was made.

## 5. Checks Run

- In the recovery tree, `PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s test -p 'test_arc1_pilot_cells.py'` passed **27 tests**.
- The launcher returned `plan_validated_no_fits_started`. No Julia process or fit was launched.
- The plan contains eight jobs and 240 attempts, uses four concurrent workers, and records `execution_started=false`. Each job pins one Julia thread and one BLAS thread.
- Each admission contains 1,468 mapped paths. All eight share one map, and every mapped recovery file matches its recorded hash.
- Canonical source-lock digest: `a9f41d5dcb50598ece3894cc59ccac0ec89d7fa8c26703379ff48ae2019104b8`.
- Canonical batch digest: `0b46e5248ccb88c9def92136ea1a4de0e9163f07a328e9c940b0fa2a46939055`.
- Canonical plan digest, excluding its embedded digest field: `3b3d73d66c98d47563a1593f6eb0806c77a3ea86874a6fd3c417533e65aca05b`. Raw plan-file SHA-256: `ef2ea5dc562ee6ac25dc3dd351b73d36d51662cc1548469a0cd94ef1053be60f`.
- Curie review of the regenerated plan and lock: **PASS** for internal consistency and current source-byte agreement. The review was read-only.
- A separate launcher review also passed the plan structure, source pins, eight-cell scope, thread pins, and no-execute control-flow contract. It returned **HOLD before fits** because the scratch output root only detects prior attempts beneath that root; it does not establish that the proposed seeds are unused across other local or remote execution stores. It also noted that `execution_started=false` is a plan field, not a retained receipt proving which CLI path created the plan.
- A read-only exact-value scan checked all 240 proposed outer seeds against the retained Arc 1 evidence tree: 15,943 regular files, 345,905,350 bytes. The first scan found seed values only in eight retained `arc1_outer_seeds.csv` allocation-manifest copies. Repeating the scan while excluding those allocation manifests found zero matches. This is local evidence-tree coverage only; it does not cover other worktrees, Totoro stores, remote archives, or missing historical paths.
- The exact-value search covered all 20 local Codex HSquared worktrees and the isolated R checkout. Both worktrees with retained Arc 1 evidence contained the same `source-v13.tar` (SHA-256 `35d1a276e41166aea68e71f8f832ff130e7cd4edf8be25c17e1fd373ca6c1611`). A safe temporary unpack confirmed that all 240 matches in this archive were in `sim/arc1/manifests/arc1_outer_seeds.csv`. After excluding those allocation CSVs and the two identical source snapshots, the scan found zero matches in the 20 Codex worktrees. The isolated R branch also had zero matches outside allocation CSVs. These scans do not cover remote execution stores or missing historical paths.
- A fresh planning-only CLI invocation returned `plan_validated_no_fits_started`, exit 0, for the same canonical plan SHA. Its retained receipt is `/private/tmp/arc1-pilot-current-launcher-dryrun-20261024-env-scope-fix/results/no-fit-cli-receipt.json` (SHA-256 `18b13deb2bde9dfd9ee73d79d91485fe3e830c2098311b073c34e6b3b444fe76`). The receipt records the exact status output and stdout hash. All eight cell output directories were absent before and after invocation.
- Using existing Totoro ControlMaster sockets with fresh-connection fallback disabled, a read-only metadata walk covered all 112 Arc 1 directories in `~/hsq_work` (9,114 directory nodes; no traversal errors). It skipped 57 symlinks, none in output-like paths. The scan parsed 152 `.started.json` records; all had valid seed fields and none matched the 240 proposed seeds. It found 155 `.result.json` files. The three without sibling start records were byte-identical copies of outer 33's result (SHA-256 `b0da86cb3b854d5e3be212aa10ded52ef26e3a142188fe1180b42aeabbef1529`); parsing them found no proposed-seed matches. The three non-directory Arc 1 entries were also checked and had no matches. Three identified output/attempt archives and one source snapshot were inspected; their 19 JSON members had no proposed-seed matches. Other archive contents and remote stores outside `hsq_work` remain unexamined.
- A supplementary archive pass found 92 archive-like files under those roots. It enumerated 74 archives and inspected 146 admission, receipt, start, or result JSON members; none contained a proposed seed. Some archive entries and member JSON files failed to open or parse, so this pass does not certify every archive. The four output/attempt archives noted above were parsed cleanly.

## 6. Tests of the Tests

Both regression cases failed against the earlier implementation and passed after the fixes. The focused suite then passed 27/27. The admission fixture bypasses only the historical Git seed-audit callback because the retained recovery tree has broken Git metadata. The contract checks under test still execute. No Git repair was attempted.

## 7a. Issue Ledger

No issue was opened in this slice. The stale v11 hash inventory remains a source-review limitation. No acceptance gate or public capability claim changed.

## 8. Consistency Audit

G0 and G1 remain met. G2 through G8 remain open. `public_covered_count` remains 7 and v7 remains HOLD. Candidate admissions and the no-fit plan provide no pilot outcome evidence.

The recovery tree remains the source under review. The Dropbox checkouts and protected handover, GATES file, freeze, checkpoint, coordination board, and AGENTS snapshot were not edited. The b9ae worktree contained substantial unrelated dirty state, including a dirty check log; it was preserved. No new SSH connection was opened; read-only commands used existing Totoro ControlMaster sockets, and neither SSH master was stopped. Curie reviewed both the code contract and the regenerated candidate plan.

## 9. What Did Not Go Smoothly

The first integrity script assumed admissions were referenced by paths, while this batch embeds them as objects. The check was corrected to follow the actual schema. The raw plan-file SHA differs from its embedded canonical digest because the launcher hashes canonical JSON with the digest field omitted. This rule was verified against the launcher and by Curie. A broad remote grep exceeded its 120-second cap; I verified and terminated only its Python/grep process tree, left both Totoro ControlMaster processes running, then completed a bounded metadata audit across all Arc 1 roots under `hsq_work`.

## 10. Known Residuals

- The refreshed source lock is a reviewed candidate awaiting formal source-freeze approval.
- The plan carries no execution authorization. No eight-cell pilot fits were started.
- The planning-only CLI status is now retained separately from the plan's `execution_started=false` field. This proves the no-fit planning path for this plan identity; it does not authorize execution.
- The local scans and Totoro metadata audit found no proposed seed values in identified attempt outputs across the retained evidence tree, the 20 Codex HSquared worktrees, the isolated R checkout, and retained Arc 1 start/result records under `hsq_work`. A complete seed-use audit remains unresolved because some archive contents, remote stores outside `hsq_work`, and missing historical paths were not covered. The plan is therefore not executable until remaining remote-history scope is resolved and the separate measured-pre-run and execution-authorization gates are satisfied.
- The missing K1 reference maximum for retained N80/null cases remains unresolved, and interval methods were not scored in this slice.
- The retained 20-replicate diagnostic was not rerun and provides no acceptance-gate credit.
- G2 through G8 remain open; covered count remains 7; v7 remains HOLD.
- The protected check log and coordination board were not updated under the recovery instructions.

Next owner step: authorize a measured pre-run for the eight-cell pilot, review its runtime and resource results, then decide separately on execution authorization. The frozen 29/30 threshold remains in force. The exploratory 24/30 screen grants no threshold change.

## 11. Team Learning

Memory receipt: `route.py` found no LOAD-FIRST manifest for this isolated worktree. Relevant repo instructions and Arc 1 recovery boundaries were loaded before editing. The recovery tree's broken Git metadata was preserved.

Golden Set: not checked. This slice changed pilot admission and launcher validation; it did not change the estimator or scientific likelihood.

## 12. Cross-Product Coverage

Covers the Julia-side FA-rank pilot batch admission, source-lock validation, and no-fit planning contract. It does NOT cover R access or parity, FA likelihood correctness, selector performance, interval calibration, pilot outcomes, the complete Arc 1 acceptance gates, GPU, or release readiness.

This report closes only the launcher and admission engineering slice. It does not close Arc 1 or establish G2, G3, or any later gate.
