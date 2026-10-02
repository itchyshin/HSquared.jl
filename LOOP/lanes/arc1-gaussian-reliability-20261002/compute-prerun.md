# Arc1 compute pre-run, 2026-10-02

Status: engineering measurements retained. No allocated development, pilot or confirmation study has run. Campaign admission remains held for code/checker reconciliation, the coverage-allocation decision and measured approval of any campaign above three hours.

## Frozen execution and results

Totoro source snapshot: `/home/snakagaw/hsq_work/arc1-engineering-20261002a`. Julia 1.10.0; engine identity `30989168d92cc25bf73fad62a1d089fb1aba248beda1d4fc688042f257f22765`. Four initial workers each used four Julia threads and BLAS one. The initial group finished in 73.53 seconds, below its five-minute cap. Source hashes matched before and after. All processes exited zero. Engineering seeds were separate from the allocated study partitions.

| Engineering operation | Fitting time | Retained outcome |
|---|---:|---|
| FA N=80, strong association | 9.12 s | Ordinary K1 selected; all selector guards passed |
| FA N=160, strong association | 10.02 s | Ordinary K1 selected; all selector guards passed |
| FA N=320, strong association | 12.70 s | Ordinary K1 selected; all selector guards passed |
| N=160 bootstrap, B=3 | 6.53 s | 3/3 usable; interval arithmetic formed |
| N=80 interior repeatability profile | 64.54 s | Va, Vpe, h2 and repeatability formed; Ve nuisance-unresolved |
| Expanded reference on retained N=80 data | 10.36 s | 86 rows; K0/K1 shortfalls 2.27e-13/1.71e-13 |
| N=160 bootstrap, B=19 | 38.78 s | 19/19 usable, all selected K1; interval arithmetic formed |

Peak resident memory was approximately 422 MiB for the reference and 638 MiB for the B=19 bootstrap. Timings include first-call compilation within each measured call. No timing establishes reliability, interval endpoint stability or coverage. Small B values serve runtime and execution checks only. The Ve refusal has a retained arithmetic diagnostic and remains a scientific-method implementation issue.

Full source manifests, resource logs, serialized inputs/results, process receipts and artifact hash inventories are in `.unlazy/arc1-gaussian-reliability/evidence/totoro-engineering-prerun/`, `totoro-engineering-reference/` and `totoro-bootstrap19-timing/`. All launched remote processes have completed; no job is running at this checkpoint.

## Preliminary projection, not a campaign authorization

The B=19 example averaged 2.0410 seconds per inner attempt including call overhead. Applying that one observed rate to 3 signals times 400 outer datasets times 499 inner attempts gives 598,800 selector calls and 339.49 worker-hours. Four fully occupied workers would need about 84.87 hours; three would need 113.16 hours. These projections exclude outer fits, storage, startup and any slower null/weak-signal behavior. They are conditional planning estimates from one successful strong-signal dataset.

The 90 B=199 primary FA interval pilots plus 20 extensions from 199 to 999 require 33,910 inner attempts. At the same rate, ideal four-worker time is 4.81 hours before overhead. This pilot therefore already crosses the three-hour approval line. The scheduler must account for cell-level storage locks: three FA interval cells may supply only three simultaneous owners unless a tested shard/claim design is introduced. Do not assume full four-worker use without that proof.

The full repeatability estimate remains unmeasured across sample size and signal. The single N=80 timing cannot establish a full campaign bound. Reference timing also needs representative difficult cases. Any future source repair requires matching rechecks before these measurements are used as an executable campaign forecast.

The confirmation count remains 400. The separate coverage-design review shows low joint acceptance probability under ideal 0.95 coverage; no count, margin, confidence level or seed partition has changed. Present the allocation choice and a complete measured campaign estimate together after the remaining engineering checks pass. No campaign approval is inferred from these pre-runs.

## Candidate scaling path for the run plan

The four-worker projection is not a fixed compute limit. A later measured comparison at 16 workers, each with four Julia threads and BLAS one, would reserve 64 threads within Totoro's 150-core ceiling. At unchanged throughput, the FA confirmation portion would take about 21.22 hours for 400 outer datasets or 84.87 hours for 1,600. These are untested scaling projections; no 16-worker launch is authorized by this note. Measure shared-host headroom and scaling before using them for approval.

A scheduler can avoid the three-cell bottleneck only after its ownership/resume behavior is tested. One candidate is deterministic outer-index assignment to separate worker output roots, retaining the same full immutable cell admission and global outer indices. Each worker then owns its cell store; reconciliation must reject duplicate/missing indices, source/seed mismatches and artifacts outside the shared result root before assembling the one canonical cell receipt. This would preserve all-attempt denominators and require no replacement seeds. It remains an implementation proposal, not a verified runner capability.

## Four versus sixteen workers, 2026-10-02

The existing-socket Totoro run completed in 86.552 seconds with unchanged source hashes. Four B19 engineering examples took 42.517 seconds and sixteen took 44.035 seconds. All 20 processes exited zero; all 80 retained artifact hashes matched on retrieval. Each worker used four Julia threads and BLAS one, with peak resident memory below 565 MiB. Results live in `.unlazy/arc1-gaussian-reliability/evidence/totoro-fa-scaling/retained/`; the parsed retained summary is `verified-summary.json` one directory above.

The first four examples were repeated for timing comparisons. They are not additional independent datasets. Seeds 202610040001 through 202610040016 generate engineering inputs; inner streams use 202610050000 + 100 * worker + (1:19). None belong to a study partition.

For the sixteen-worker batch, average seconds per inner attempt were 1.5913 null, 1.5931 weak, and 1.4544 strong. An equal-signal mean of 1.5463 seconds projects the 598,800 confirmation attempts to 257.20 worker hours, or 16.08 elapsed hours at sixteen concurrent workers before startup, reference audits, storage, and stragglers. This is a timing extrapolation from B19, not a qualified full-campaign estimate. A deterministic outer-index scheduler and final-source replay remain required.

Ten of sixteen examples returned `insufficient_usable_bootstrap`; six formed. Individual usable counts ranged from 16 to 19 of 19. These failures are retained and are being partitioned by numerical mechanism. The run demonstrates scaling only. It does not establish formation reliability or coverage, and it does not qualify confirmation. All G0 through G8 gates remain open.
