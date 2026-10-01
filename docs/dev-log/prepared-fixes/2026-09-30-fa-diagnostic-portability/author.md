# FA diagnostic test portability proposal

Signed by GPT-6.1 Sol High, author, 2026-10-01 UTC. Curie, Fisher and Kirkpatrick are review lenses. Independent review is pending.

## Bounded decision

AUTHOR PASS for the focused test correction. No live files were edited. Only `test/test_multivariate_fa_multistart.jl` is proposed for integration. Numerical source, optimizer, starts, budgets, scientific tolerances, Project, Manifest and frozen campaigns are unchanged. Fresh full package and hosted checks remain required after integration.

## Exact bytes

- Baseline HEAD: ec9414c35d7621c6bd4321a9d16067ac9a2ea2eb.
- Original test: e621d60892c9ec9ceab6a1b06d051495d2aa1b9d6c70346023129a993b2d9085.
- Prepared test: e340a84b71b6ae3b62ffa96591d5b576ba9c0d43c6fdb9e24382fa198ef942ea.
- Patch: ce51d97a34b485aaec7c963b7566e4d71fbda45e02ef28655606391e8644bada.
- Unchanged multivariate source: f975657ef43d86045171a9265e5536370043a46fc72880a3e80ee87fcad699c2.
- pins.json: 8df752af82c02c0956a681b92c8512df9354b180f897f4664898da42a41af0bd. It attests exact drivers, logs, Project, Manifest and helper bytes.

`git apply --check` passed against the exact original copy; replay equals prepared bytes (`patch-replay.txt`).

## Measured premise

`fixture_hashes.jl` generated the two original fixtures without fitting. Julia 1.10.0 and 1.13.1 produce different Y and raw normal draws for both seeds, while Ainv/G/R bytes agree. Thus a fixed seed does not fix these response matrices across these runtimes. This observation establishes data drift; it does not exclude additional optimizer differences.

| Seed | Julia 1.10.0 Y SHA256 | Julia 1.13.1 Y SHA256 |
|---|---|---|
| 20260927 | a3ec294ef2b6b480330e1f8abe31c9314fc67f20917f4db45d36285030b01fc0 | 8ef66aab2691a3d3279c18f805ba814c3dc02c7ee63bd1509cc26100057bd2a5 |
| 20260928 | 79ade3d5ef3b629ebfd277b0fac8b6073410104b81f35918ce9e8faeacc6394a | b5870e4ee11e3ed7f3d3f826a31790b21e2c64f3d760aa9765b8cb5f185c08cc |

Full hashes and executable paths are in the paired `logs/fixture-hashes-*` files. Runtime was 3.54/3.36 seconds, with a 30-second estimate/cap.

## Defect and narrow correction

The exact original Julia 1.13 replay reproduced all three hosted assertions: G disagreement 1.2723122385941212e-5 versus >0.1; R disagreement 1.0118114337605795e-5 versus >0.05; both second-fixture starts converged. Original target block: 25 PASS, 3 FAIL; 15.75 seconds including preceding tests (`logs/red-fa-diagnostics-1.13.*`). These outcomes are compatible with the estimator contract.

The proposal tests normalized Frobenius G/R differences against separate ordinary fits from the reported starts, and checks each start's convergence, iteration count and likelihood. The balanced reporting oracle matches the automatic initializer arithmetic, avoiding small rounding changes between mathematically equivalent initializers. The original explicitly supplied balanced fit and its existing selection comparisons stay intact. Three extra individual fits use the same two original response matrices.

Neighbor review found a fourth empirical assumption, `!better_nonconverged_start`; it is replaced by the actual finite-likelihood/nonconvergence comparison. Hard uniqueness floor, returned floor distance, and near-floor identity are added. Original near-floor and fitted information rank assertions, selected-start objective/covariance/status/iteration checks, one-iteration refusal, and all unit/order checks remain unchanged. The deterministic selector's mixed-status case retains a better nonconverged objective. `retained-contracts.txt` records byte/assertion preservation.

## Fresh verification and limits

All launches cap Julia and BLAS at one thread with an owned timeout. `run_owned.py` records commands, estimates, elapsed time and exit status. Focused `focused_prepared.jl` runs the changed block and preceding controls, excluding the unchanged large unit/order fits:

- Julia 1.10.0: 68 PASS, 0 FAIL; 15.30 seconds, 120-second cap.
- Julia 1.13.1: 68 PASS, 0 FAIL; 17.81 seconds, 120-second cap.
- Both totals comprise 46 changed-block assertions plus 22 unchanged selector, overflow, design and fixed-information controls.

An earlier prepared whole-file replay included the unchanged larger unit/order fit block, exceeded its 120-second estimate and was terminated at 120.14 seconds. Its failure log/result are retained as `logs/green-fa-1.13.*`; it supplies no completion claim. The focused replay was then used. No further fits or broad campaign are required from this author. Parent owns full-suite and hosted renewal.

## Runtime commands

Use `python3 run_owned.py EXE focused_prepared.jl LABEL 120` from this packet. Executables:

- 1.10.0: /Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia
- 1.13.1: /Users/z3437171/.julia/juliaup/julia-1.13.1+0.aarch64.apple.darwin14/Julia-1.13.app/Contents/Resources/julia/bin/julia

Project: /Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl. Depot: /private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia. No environment resolution is performed by the focused driver.
