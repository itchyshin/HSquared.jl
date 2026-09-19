# After-task — 2026-09-19 cap-free clique scatter in `_selinv_zvals`, and the D-271 input

Handover #360, item 2 (the D-271 call on SelectedInversion.jl, #353), with the kernel
finding that changes its input. Lane: Julia engine (Szymek, with Claude).

## 1. Goal

S2b measured the `6bb10c97` kernel against SelectedInversion.jl at the D-271 banked point
(f0adv, q = 20,000, fill 474, Totoro) at 287x, and found the kernel's own gain over the
old one to be fill-dependent: 1.10x at fill 474 against the 6.65x–9.97x measured at fill
≤ 214. D-271 measures the package against *our* kernel, so the cause had to be understood
before the call.

## 2. Diagnosis (measured, not inferred)

`6bb10c97` materialises an `m × m` clique block only for `m ≤ DEFAULT_SELINV_BLOCK_CAP =
2000`; wider cliques keep the per-pair binary search. Clique-width profile of the MME factor,
same generator and seed as S2b, q = 20,000:

| `nfounder_frac` | fill | max clique | columns with m > 2000 | share of `Σⱼ|L[:,j]|²` in m > 2000 |
|---|---|---|---|---|
| 0.2 | 339.7 | 3,401 | 1,481 | 78.7% |
| 0.05 | 465.0 | 4,045 | 2,115 | 86.7% |
| 0.005 (banked point) | 471.1 | 4,072 | 2,136 | 86.8% |

Amdahl with ~8x on the remaining 13%: 0.87 + 0.13/8 ≈ 1.13x, the S2b 1.10x.

## 3. Implemented (branch `perf/selinv-capfree-scatter`, off `main` `63f44039`)

- `_selinv_zvals` walks each clique member's own column once and scatters both symmetric
  contributions (`L[i_q,j]·v` into `s_p`, `L[i_p,j]·v` into `s_q`) into a length-`m`
  accumulator. No search, no `m × m` block, no width cap; `O(maxm)` scratch.
- Every accumulator receives its terms in ascending clique order, exactly as the original
  per-pair recursion; skipped structural zeros are exact no-ops (an accumulator starting at
  `+0.0` never becomes `-0.0`). Output is bit-identical.
- The original recursion is kept as `_selinv_zvals(ch; per_pair = true)`, the test reference.
  `DEFAULT_SELINV_BLOCK_CAP` and the `block_cap` keyword are removed (internal, unexported).
- Fill-qualified the 6.6x–10.0x figure where it was quoted without a fill range: the kernel
  file header, `selinv_trace_against` docstring, `capability-status.md` (reliability/PEV
  row), `validation-debt-register.md` (`V1-REML`), `validation_status.jl`.

No public API change. Not user-visible except through speed; no example needed (internal
kernel; the public entry points `prediction_error_variance`, `reliability`, `fit_ai_reml`
are unchanged).

## 4. Tests

`test/runtests.jl`, testset "_selinv_zvals clique-scatter path == per-pair reference,
bitwise" (8 assertions): random SPD n = 40/150/300; the 8-animal `Ainv` and MME; a 600-animal
fully-random-mating pedigree (MME and `Ainv` factors, widest clique > 100, so the merge and
the per-entry-search branches both run). Prototype sweep before the rewrite: 33/33 cases
bitwise-equal to both the capped kernel and the capped kernel forced to small caps.

## 5. Measured (Mac Studio M1 Ultra, one thread, Julia 1.13.0)

Per selected-inverse pass, full MME, f0adv generator and seed from `bench/selinv_arms.jl`
(branch `claude/lane-speed2b-20260919`):

| fixture | fill | capped block (`main`) | cap-free scatter | ratio |
|---|---|---|---|---|
| q = 5,000, frac 0.2 | 107.3 | 0.310 s | 0.187 s | 1.66x |
| q = 5,000, frac 0.005 | 150.7 | 0.581 s | 0.320 s | 1.82x |
| q = 10,000, frac 0.005 | 262.4 | 8.257 s | 1.978 s | 4.17x |
| q = 20,000, frac 0.005 | 471.1 | 416.8 s (trace) | 14.9 s (trace) | 28.0x |

At q = 20,000 the Z values are bit-identical and the traces equal to the last bit.

## 6. D-271 input (the call itself is in the #353 comment)

Same machine and fixture (q = 20,000, fill 471, supernodal, factorise 0.53 s); package arm =
`SelectedInversion.selinv(F; depermute = false)` + `dot` with the permuted `Ainv`
(SelectedInversion 0.2.1, scratch environment; the package `Project.toml` is untouched):

| our kernel | trace pass | package (1.19 s) faster by | agreement |
|---|---|---|---|
| `main`, capped block | 416.8 s | 349x | — |
| cap-free scatter (this branch) | 14.9 s | 12.5x | package 2.75e-14 relative |
| + SIMD on the aligned clique tail (prototype, not on any branch) | 5.97 s | 4.8x | 1.3e-15 vs scatter |

The prototype reorders one sum (`@simd` over the tail when a clique member's column tail *is*
the clique tail), so it can only be gated at a stated rtol, not bitwise, and its fast path
assumes the Cholesky fill-path property of CHOLMOD's supernodal pattern. Its row was measured
while a test suite ran on other cores. Decision input only.

## 7. Rose claim-vs-evidence audit

- "bit-identical": tested (`reinterpret(UInt64, ·)` equality, 8 assertions + 33-case sweep;
  q = 20,000 bench equality). Holds.
- "28x at q = 20,000 fill 471": one timed pass per arm, one machine, one fixture; stated
  with machine, thread count, and fixture everywhere it appears. Not a general speed claim.
- 6.6x–10.0x: kept as measured, now fill-qualified everywhere it was quoted.
- No claim about end-to-end `fit_ai_reml` from this slice unless the check-log entry
  carries the measurement.
- No external comparator; no real pedigree (#359 stands).

## 8. Checks

See the check-log entry of the same date for `Pkg.test()`, validation-status page and
`preamble_cap.sh` results. CI: pending the push.

## 9. Residuals

1. SIMD aligned-tail kernel as its own PR, gated at rtol 1e-10 on Z and fit-level estimates,
   with a fill-path-property assertion on supernodal patterns.
2. Totoro re-run of the banked point against the kernel on `main` (Shinichi's machine;
   `bench/selinv_arms.jl --totoro-arm`, with `EXPECTED_KERNEL_SHA` bumped).
3. Close #353 on that number.
4. Handover items 4a–4c (AI-REML workspace, backend switch, allocation-free matrix-free path)
   not started in this slice; the backend switch only matters if D-271 admits the package.
