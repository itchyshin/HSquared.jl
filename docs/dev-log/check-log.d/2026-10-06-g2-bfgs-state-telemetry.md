# G2 optional BFGS-state telemetry

Date: 2026-10-06 (America/Edmonton)
Scope: engineering test of opt-in diagnostic telemetry only. No G2 scientific gate or denominator transition.

## Source review

Independent exact-source review: PASS. Reviewed `src/arc1_fa.jl` SHA-256 `937b6c3eee3513819f2115e21e1e0cdf52805b7396742c0957667662ba39316f` and `test/arc1_optimizer_contracts.jl` SHA-256 `09ce900ae3a41ccb77f1767c140e4477a1d6b3aa8bb31172ede4264ce3e15133`. Reviewer verified pinned Optim trace timing and the `alpha * direction` update displacement. The review and final implementation hashes are retained in the task transcript.

## Focused test

Command:

```sh
JULIA_DEPOT_PATH=/private/tmp/hsq-arc1-telemetry-depot-20261006:/Users/z3437171/.julia JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. test/arc1_optimizer_contracts.jl
```

Exit: 0. Result: 497 passed, 0 failed, 17.7 seconds. Raw stdout: `docs/dev-log/check-log.d/2026-10-06-g2-bfgs-state-telemetry.log`, SHA-256 `3c4fd0fdf86f6882727f8bbb0a755152c57bfae41e012e05c4251f71c1b361b0`.

## Additional checks

- `python3 -B tools/arc1_manifest.py --validate-only`: exit 0; 644,480 unique allocated seed values validated. Integrity only.
- `python3 ~/shinichi-brain/tools/arc_gate_lock.py verify LOOP/lanes/arc1-gaussian-reliability-20261002`: pass.
- `bash tools/preamble_cap.sh`: pass.
- `git diff --check -- src/arc1_fa.jl test/arc1_optimizer_contracts.jl`: pass.
- `node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --status --scope arc1-gaussian-reliability`: G2, G3, G4, G5, G8 unmet. Status did not execute checks.

No source mutation control, retained-seed replay, pilot, or confirmation was run. See `docs/dev-log/after-task/2026-10-06-g2-bfgs-state-telemetry.md`.

## Retained-seed diagnostic replay

Astra exact-source admission review: PASS for candidate SHA-256 `394de81765b260cf3c1ac24d1f81ca26bfc724edafb9cf2f0d1aab18cbd56927` and source-lock SHA-256 `d10a672f2d1a00c21be32ebe2a4d32330a656bbb36f3ad9746dd2bc03e458d82`. Both retained inputs passed their pinned hashes. The two original balanced K1 retry-0 starts were replayed with telemetry only. Supervisor result: complete, both child exit codes 0, elapsed 18.693 seconds, post-run sources matched. Raw stdout/stderr and `run-status.json` are retained under `/private/tmp/h2-g2-bfgs-state-telemetry-20261006/run-v1/`; result hashes are recorded in the lane checkpoint.

Outer7: 110 telemetry states, 109 BFGS updates, zero skips, zero resets, final gradient infinity norm 2.274052991968205e-5. Outer10: 167 states, 166 updates, zero skips, zero resets, final gradient infinity norm 1.0459255365163801e-8. Both terminate `line_search_failed`: the returned finite step met neither Wolfe condition. This rules out a missed BFGS skip/reset in these traces as the recorded reason, but does not explain the line-search failure. The replays use consumed seeds and do not count as allocated evidence or alter any gate or denominator.

Follow-up checks: five supervisor tests passed in 0.012 seconds; seed-manifest validation, lane-lock verification, preamble cap, and scoped `git diff --check` passed.

## Read-only terminal search audit

A second read-only deserialization audit found that both terminal trials lowered the objective and passed sufficient decrease but failed the exact and approximate Wolfe tests. Each terminal search had five rejected trials, five domain restarts, a step cap of 0.03125, and six objective evaluations. Outer7 terminal objective/slope/gradient infinity norm: 1.3919874985169745 / -2.6693399397935805e-8 / 2.274052991968205e-5. Outer10: 1.416875586089374 / -2.3670522965491872e-14 / 1.0459255365163801e-8. Stored trace gradient norms match the recorded fit summaries. This is arithmetic over retained fields only; no objective or gradient was evaluated. It does not verify gradient correctness or establish a source defect.

## Terminal directional diagnostic v8

Fresh Astra exact-source review passed for candidate SHA-256 `1102af5d6aba77f8c68eb8b8664f08ca7f00e5ebdcab17539d2b25a83fda515c` and source-lock SHA-256 `c1c9eaae0033fb9a420975d38de460d14e316a07bea83efc91081c72709cb82b`. The 63-entry lock pins all 30 current Julia source files, the project/manifest, v8 driver/supervisor/tests, the exact development-v1 outer10 full input (`9beb707328637f9a539362b7ed72da27907db599a17dbe0cecbbc7c0e9a6a4f8`), its input metadata, and the matching telemetry result (`560f5cf77f568960c55c116756b3bf60c286b3c095a49fde11742dcf755ccb40`).

Supervisor tests passed 2/2; preflight passed; Julia parse passed. The diagnostic ran in 69.946 seconds under its 300-second limit. Julia exited 0, its process group is gone, and source/candidate hashes matched after execution. Result TOML SHA-256 `70efe8d9bde2d5755f723ccdf22c894b4976fa615a18e73c745d53eebde7dce4`; supervisor receipt SHA-256 `fe7c00a8a46df2ad3510f2e6e238b7f8059eac1792c35ee165acf6c95b6560c5`.

At outer10's origin and rejected trial, stored directional slopes agree with 256-bit central differences to about `7e-25` or better at three step sizes. Float64 center objectives differ from the 256-bit reference by about `1e-16`. This supports local consistency of the recorded directional slopes for this one failure; it does not explain the Wolfe rejection, establish optimizer reliability, or qualify G2. No gate, denominator, seed, or source status changed. Full report: `docs/dev-log/after-task/2026-10-06-g2-terminal-directional-v8.md`.
