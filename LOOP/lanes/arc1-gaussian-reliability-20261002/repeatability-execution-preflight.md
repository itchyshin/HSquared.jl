# Repeatability development execution preflight

Current status, 2026-10-03 06:37 UTC: explicit profile v2 passed independent source review, G1, required-live R parity, and the complete Julia/R/documentation package checks. The current source-bound ledger snapshot records G1/G6/G7 passed and six gates unmet. No allocated study seed has run. Contract metadata reconciliation is in progress because the previous scientific-contract object still described v1 while admission required v2. Regenerate and validate the complete freeze after reconciliation before any study admission. The bounded replay of two saved engineering inputs has separate authority and does not admit a study.

The timing, failures and projections below are retained v1 engineering history. Their old G7-failed and all-gates-open statements describe that earlier snapshot. They do not supersede the current package receipt `20261003T061429Z-1a5ef047d4`. Later source changes require appropriate renewed verification. Campaign approval above three hours, the pending FA representation decision, and the confirmation-allocation decision remain separate boundaries.

## Completed engineering size pre-run

The parent authorized a six-case engineering-only timing run after review of the accepted profile v9 source, the exact 42-file runtime inventory, and the completed Julia component in the G7 package-check run. G7 remains **failed overall** because its R CMD check reported a `confint.hsquared_fit` Rd/code documentation mismatch warning. Its Julia package-test component passed in 540.04 seconds, with exit status 0, no timeout or interruption, both required markers, and retained log SHA-256 `48c83a0f3da64ba152e08ed8a25f038750a0ed8d4f2e0cea19a3d41eebeab954`. This component evidence was used only as an engineering-run prerequisite. It does not close G7 or any other gate.

The Totoro run used Julia 1.10.0, the existing offline depot `/home/snakagaw/.julia`, four workers, four Julia threads per worker, and BLAS one. A one-thread offline `using HSquared` probe passed in 15.21 seconds before launch. The six cases finished in 308.75 seconds, inside the 360-second batch limit. Each case exited 0, the supervisor exited 0, reported no timeout or received signals, and waited for all child processes. All 42 source pins matched before and after. The receipt's `all_six_completed_successfully` means every case produced a complete retained result; it does not mean every target formed.

| Case | Case wall time (s) | Profile call (s) | Peak RSS (MiB) | Target result |
| --- | ---: | ---: | ---: | --- |
| N=160 interior | 175.68 | 173.36 | 663.4 | All five formed |
| N=160 near-zero PE | 107.64 | 105.34 | 645.4 | All five formed |
| N=160 near-zero additive | 130.26 | 127.89 | 595.7 | Residual variance unformed, `nuisance_unresolved` |
| N=320 interior | 169.87 | 167.46 | 545.1 | All five formed |
| N=320 near-zero PE | 168.48 | 166.14 | 579.9 | All five formed |
| N=320 near-zero additive | 178.28 | 176.06 | 621.1 | Permanent-environment variance unformed, `nuisance_unresolved` |

These are one generated dataset per N and signal, not a reliability sample. The six cases produced 28 formed targets of 30. The two unformed targets are retained with their complete `profile.jls` files. Do not infer coverage, pass/fail rates, or pilot qualification from these six outcomes. They support a hold recommendation before any larger repeatability run until the two near-zero additive refusals have been reviewed.

The run receipt is `.unlazy/arc1-gaussian-reliability/evidence/repeatability-size-prerun-totoro-20261003T032000Z/result/receipt.json`, SHA-256 `b4663aa59dbd2d8ed5c2b9fdd0cfe4d6698ba9ddf718c0965c32fcab0dc73180`. Full attempt inputs, profile objects, summaries, run logs, and resource logs are in that directory. The supervisor record is under `controls/launch-supervisor.json`, SHA-256 `6b319df6c9f0bc82c51aaa0402166e81a9b25b0b6962672bd73eafdedf12f3fc`; its log SHA-256 is `5ed217816efb5669c41b685d382151f73643fda476d46746ec36346e857121b5`. The collection verification is `collection-verification.json`, SHA-256 `aa6611a99dfc2c74b421dd4c1e12024c1ffeb3288fe5d9f3ca03ba8a224db4dc`. It verifies all case artifact hashes, the receipt's source-before/source-after equality, the supervisor and offline-load records, and the G7 status. The exact transport archive hash is `f0cba52f9a49dd9d76c1d4b2b2e0667918db1fd499f832f87e9b500801a2c595`; the external engineering-only authorization is retained under `controls/` and is bound to the archive inventory, cases, accepted review, G7 artifacts, Julia binary, and fresh output root.

### Provisional four-worker timing projection

For a transparent planning calculation, use the observed case wall times as per-attempt costs. The three N=160 cases averaged 137.86 seconds, with an observed signal range of 107.64 to 175.68 seconds. The three N=320 cases averaged 172.21 seconds, with an observed range of 168.48 to 178.28 seconds. For N=80, use the retained 68.54-second end-to-end interior result as a proxy for all three signals. That N=80 observation is one Mac case, not a Totoro-matched measurement. The N=80 estimate is therefore especially uncertain.

The projection treats the nine N-by-signal cells as indivisible jobs. Each worker owns a whole cell and processes its outer attempts sequentially, consistent with the cell-level store lock. A cell's projected duration is its attempt count multiplied by its observed or proxy per-attempt wall time. For each phase, the four-worker elapsed estimate is the smallest possible maximum worker load when the nine cell jobs are assigned whole to four workers. For development and pilot, each of nine cells has 30 attempts, for 270 total. For confirmation, each cell has 400 attempts, for 3,600 total. The central estimate uses the observed signal-specific N=160 and N=320 times and the single N=80 proxy above:

| Phase | Workload | Central elapsed estimate | Empirical cell-time sensitivity |
| --- | ---: | ---: | ---: |
| Development | 270 attempts | 2.55 h | 2.30 to 2.95 h |
| Pilot | 270 attempts | 2.55 h | 2.30 to 2.95 h |
| Confirmation | 3,600 attempts | 33.95 h | 30.68 to 39.33 h |
| Exact-zero boundary diagnostics | 400 attempts, 200 in each of two N=160 cells | 7.24 h | Uses the two near-zero N=160 cases as proxies |
| All four phases, sequentially | 4,540 attempts | 46.28 h | 42.52 to 52.46 h |

The empirical sensitivity replaces all N=160 cells with the fastest or slowest observed N=160 case and does the same for N=320; it holds the single N=80 Mac time fixed. It is a scenario range, not an interval. Separately, changing the unmatched N=80 proxy from one-half to twice its observed value moves the combined estimate from about 45.41 to 55.15 hours. The confirmation-only estimate at 1,600 attempts per cell would be about four times the 400-attempt estimate, or 135.8 hours centrally. The approved confirmation allocation remains 400 per cell; no larger allocation is proposed or adopted here.

These projections are not stable campaign estimates. There is only one dataset per N and signal, the N=80 case is from a different host, and the two near-zero additive cases returned unresolved targets. Case wall time includes fresh-process launch, data generation, the profile call, and artifact writing. Summaries report `profile_seconds` separately, but do not split compilation from fitting or optimization. The four-worker projection assumes the observed case times transfer to repeated independent datasets, that four cell workers remain available, and that no extra refusal handling changes the workload. It excludes interruptions, retries, storage contention, and later reference or bootstrap work.

The combined programme projection is well above the three-hour approval boundary. Do not launch it or divide it into nominally smaller phases to avoid that boundary. Any development, pilot, confirmation, or diagnostic run still needs its own scientific prerequisites, current frozen-source admission, and applicable user approval. The 400 confirmation allocation and all acceptance rules remain unchanged. G0 through G8 remain open.

## Historical preparation record before the engineering timing run

The following preparation text records the state before the separate authorization and timing run above. It is retained to preserve the earlier planning history; its statements that the sizing run was pending have been superseded by the completed engineering-only result above.

### Package-check update and prepared sizing pre-run

The mandatory live G6 replay passed 219/219 assertions in 85.55 seconds with its recorded source and bootstrap hashes unchanged. Receipt: `oracles/runs/20261003T015734Z-f3e2c0b0c1dc`. The latest retained G7 receipt (`.unlazy/arc1-gaussian-reliability/evidence/package-checks/20261003T015948Z-5fbb56e73c/run.json`) is **failed**: test-only `Serialization` was not declared in the profile test, and the command exited 1. A docs/package worker is repairing and rerunning that check; the rerun is not yet a passing retained receipt. G7 must pass against the exact final source before this pre-run can be authorized. The parent verified Totoro's Python 3.12.3 without launching a workload.

A six-case engineering-only size pre-run is prepared under `.unlazy/arc1-gaussian-reliability/evidence/repeatability-size-prerun-prepared/`: `cases.json`, `profile_case.jl`, `launch.py`, `PREPARED.md`, and `source-hashes.json`. It crosses N=160 and 320 with the same three frozen repeatability truth triples, uses six direct UInt64 engineering seeds `9000000000000001`–`9000000000000006`, and does not call the study seed derivation function. All six exact values were checked against the current 10,060-row outer seed CSV and none matched. The prepared launcher requires an accepted profile review, a passing full G7 receipt, and a separate exact-hash authorization record before it can launch. A test or source change after the accepted review invalidates this prepared inventory and requires a fresh review and authorization.

The proposed bound is four concurrent Totoro workers, each with four Julia threads and BLAS one; at most one unique case directory is active per worker. Each child has a 180-second process-group timeout and the whole six-case batch a 360-second deadline. The older N=80 interior timing was 63.12 seconds inside the profile call (68.54 seconds end to end); larger-N runtime remains unknown. No prepared script was run or sent remotely. The preparation manifest and script hashes are in the evidence directory; parent review and G7 completion are still required before execution.

## Supported route after final-source checks

The repeatability branch is available through the existing one-attempt executor. For each cell, `tools/arc1_manifest.py` exposes `build_run_admission(...)`; it performs exhaustive seed-manifest verification and returns an `arc1-run-admission-v2` record. There is no admission-builder CLI. After the read-only manifest validation, the admission is created programmatically; for example:

```sh
PYTHONPATH=tools python3 - <<'PY'
import json
from pathlib import Path
import arc1_manifest

root = Path.cwd().resolve()
cell = {"programme": "repeatability", "phase": "development",
        "N": 80, "signal": "interior"}
admission = arc1_manifest.build_run_admission(
    root, cell, source_paths=[], julia_version="1.10.0",
    julia_threads=4, blas_threads=1, profile_method_version="arc1_profile_v2")
Path("/path/to/admissions/repeatability-development-N80-interior.json").write_text(
    json.dumps(admission, sort_keys=True, indent=2) + "\n", encoding="utf-8")
PY
```

The builder discovers engine includes, runner/protocol/test sources and lane Markdown, exhaustively verifies the seed manifest, and pins the environment. Development admission has no pilot/confirmation authorization requirement. It pins 30 outer seeds for that cell and no bootstrap seeds. The separate read-only manifest command is `python3 tools/arc1_manifest.py --validate-only`.

After writing that admission to a private run-control file, the supported executor invocation is:

```sh
python3 sim/arc1/run_cell.py \
  --source-root /path/to/frozen/HSquared.jl \
  --output-root /path/to/results \
  --admission /path/to/admissions/repeatability-development-N80-interior.json \
  --outer 1 \
  --julia /path/to/julia-1.10.0/bin/julia \
  --julia-threads 4 --blas-threads 1 --timeout 3600
```

`--outer` is one-based and required; invoke it once for each outer index 1–30. The source and output roots must be disjoint. Each attempt launches a fresh Julia process, loads the admitted source, writes a lossless result artifact and a durable receipt, and retains ordinary failures. After all 30 results exist, `runner.assemble_cell_receipt` can construct the ordered full-cell receipt; it rejects missing attempts and seed/order mismatches. Development is not a pilot or confirmation gate, and the scientific gate CLI does not emit a development qualification marker.

The repeatability profile implementation previously accepted by its bounded source review is SHA-256 `4d7cbb6faac96d769af8229f19f9d92d28ad6107737e89d9df85c968a0abca1c`; its test file is `1a9374798f5eb6e3fc5f8d875fedf6d4a5766c80bdfc0fab96ae60999d9de1d7`. These two hashes alone are not an executor source freeze. Admission discovers and pins the complete included Julia engine, Arc1 runner/protocol/test sources, project environment, and lane Markdown. The pending FA representation decision is not called by the repeatability execution branch, but the current monolithic `HSquared` source identity still includes the complete engine. Freeze and accept the complete transitive source set before building any development admission.

The lane checkpoint says the seed manifest has not been regenerated or admitted. G6 now has a passing unchanged-source replay, but the latest G7 receipt failed as described above. No current admission or clean package-check result should be assumed. First complete final local package checks on frozen sources without changing the base environment, validate the manifest, and only regenerate it if the canonical contract has changed. Then build and retain a fresh development admission with `build_run_admission`; any later source, test, protocol, manifest, or environment change invalidates it.

## Concurrency and resume boundary

`Arc1AttemptStore` takes a nonblocking exclusive lock at the per-cell output directory and keeps it for the store context. Attempt starts and results are published atomically. `rows()` only reads; explicit orphan recovery requires exclusive store ownership and proof that the recorded same-host PID is no longer alive. The executor CLI owns exactly one outer index per invocation.

With one shared output root, four workers may safely own four different cells because each maps to a distinct `programme/phase/N/signal` directory. Repeatability development has nine cells, so the approved four workers × four Julia threads × BLAS one can be used by assigning whole cells to workers and keeping each cell single-owner. Each owner runs its 30 outer indices sequentially and can resume completed rows with the same admission. Do not let two workers run the same cell concurrently: even disjoint outer indices contend on the cell lock.

Separate output roots would avoid the per-cell lock, but they do not provide cross-root claim protection, and there is no shard scheduler or shard reconciler in the current CLI. Running duplicate indices in separate roots could silently duplicate work. Do not split a cell across roots until a tested deterministic partition and reconciliation path rejects duplicate, missing, wrong-seed, wrong-source, and misplaced-artifact rows before the canonical 30-attempt receipt is assembled.

The lane record retains one N=80 interior engineering profile at about 63.12 seconds in the profile call (68.54 seconds end-to-end). This single point does not establish N scaling or near-zero signal runtimes. The prepared six cases measure both N values for all three declared signal triples, keeping those questions separate. They record fresh-process wall time, profile-call time, peak memory, statuses for all five targets, input/result hashes, and exact source hashes. They do not establish coverage or authorize a study. The proposed limit is 180 seconds per case and 360 seconds for the complete batch; if the size pilot exceeds either bound, retain the failure and re-estimate before proposing any further run.

## Current boundary

The bounded six-case engineering sizing run described above is complete. This note does not authorize another sizing run, a development or pilot run, confirmation, boundary diagnostics, or study admission. The G7 package check remains failed overall and G0 through G8 remain open. No development admission or canonical study receipt was created. The receipt store supports safe same-cell resume by one owner and safe parallelism across distinct cells, but not parallel outer sharding within a cell.
