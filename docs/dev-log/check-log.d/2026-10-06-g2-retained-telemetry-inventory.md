# G2 retained optimizer telemetry inventory

- Branch: `codex/arc1-gaussian-reliability-20261002`.
- Scope: read-only inventory of exact outer 7 and outer 10 retained full results and Wolfe witnesses; no fit, objective evaluation, source edit, seed use, or gate transition.
- Command: `JULIA_DEPOT_PATH=/private/tmp/arc1-g4-bootstrap-boundary-depot-20261006:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --startup-file=no --compiled-modules=no --project=. LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-v7-batch-driver-20261006/retained-telemetry-audit-20261006/inspect_retained_optimizer_telemetry.jl`.
- Result: exit 0; `PASS retained optimizer telemetry inventory; auditor invoked no fit or objective API`.
- Audit script SHA-256: `6cde043fe599329a8740f738b61a0ea46a1ff3e6daa085b35e2847ba621037f2`.
- Stdout SHA-256: `4f556eb94249bbdd55ef60366c6520b906dc124d380a88626f99de0fcf8082b4`; stderr SHA-256: `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` (empty).
- The first-pass stdout remains preserved at `audit.stdout.log` (SHA-256 `6a5047b71b7fdcfea319b75d64e912a74ec0e56e0d895d26a13c173e74d5677a`); its data were valid, but its opening wording was ambiguous about whether it referred to the saved fit or the inventory. The v2 log is the final presentation.
- Outer 7 input/witness SHA-256: `01648b0bb12e013449fc71013fd2d9057edde6fbeb1fffa7dee2f27b8bb76665` / `37d77285fec247b9ae878cc50d1e621f45a3713a301477f269e941095324bf52`. 110 events, 109 accepted, 1 rejected; final gradient infinity norm `2.274052991968205e-5`; no full gradient vector or Hessian/update history.
- Outer 10 input/witness SHA-256: `9beb707328637f9a539362b7ed72da27907db599a17dbe0cecbbc7c0e9a6a4f8` / `fe1e60edd2ea7464b6412de18d845826170d231c4af8134363aee94bc6d7c414`. 167 events, 166 accepted, 1 rejected; final gradient infinity norm `1.0459255365163801e-8`; no full gradient vector or Hessian/update history.
- Accepted event endpoint continuity: exact Float64 match for all 109 and 166 accepted events, respectively. This is arithmetic-only evidence and depends on the retained scalar slopes for Wolfe comparisons.
- Interpretation: the exact files used by the existing Wolfe audit do not contain the gradient/update vectors needed for a BFGS-state reconstruction. A new exact-source telemetry diagnostic needs independent review before further model/objective evaluation. G2-G5 and G8 remain open; G0, G1, G6 and G7 remain recorded as verified.
