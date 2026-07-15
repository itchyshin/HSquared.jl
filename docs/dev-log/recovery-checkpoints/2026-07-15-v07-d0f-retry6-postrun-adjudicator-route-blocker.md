# Recovery checkpoint — Retry-6 post-run adjudicator route blocker

Date: 2026-07-15 MDT

## Classification

Retry 6 is permanently
`UNADJUDICATED_POSTRUN_ADJUDICATOR_ROUTE_BLOCKER`.

This is an infrastructure endpoint, not a solver, convergence, KKT, boundary,
recovery, or route-parity failure. No post-run review receipt or adjudication
receipt exists, so D1 and D2 never opened. The ordinary R marker route remains
held, `public_covered_count` remains 5, and only the existing validation-scale
supplied-`Ginv` estimator remains covered.

## Bound execution

- R deploy/driver/recomputer: `1766aeffe675cfed8547c3107ff1c7a32905210f`
- R candidate: `8dea0ad9fb9b56ea4457bf9d1f25c7fa64af1570`
- Julia deploy/replay: `c418f50c8ffff871677cac04fca39d737b8021ca`
- Julia candidate: `d19149514964ab58b26d4583ae170d477d8b3a45`
- Frozen doc-49 SHA-256:
  `9247d2ceed1d98f89767c367883cb899410e2b840a50dd2f8cc0cb9e3f75e00e`
- Evidence root:
  `/home/snakagaw/hsq_work/v07-genomic-recovery-v3-d0f-retry-r6-1766aef-c418f50`

Two durably separated exact-head review batches, clean hash-matched deployment,
the repeated retired-packet diagnostic preflight, historical seed lock, preseal,
create-once bootstrap materialization, deployed-Julia zero-seed preflight, and
an independent chronology audit all passed before the first phenotype.

## Completed evidence

- Official R route: 576/576 successful and converged.
- Independent base-R recomputation: 576/576 complete.
- Exact Julia replay: 576/576 complete.
- All three design summaries: 192/192 converged and `COMPLETE`.
- Boundary inventory: 567 interior, eight lower, one upper, zero unresolved.
- Mean genomic-variance ratios: `0.5185524`, `0.4911293`, `0.4867345`.
- Maximum official/base/Julia attempt difference:
  `3.1832314562052488e-12`, below the frozen `1e-10` tolerance.
- Maximum summary difference: `7.1054273576010019e-15`.
- Maximum component-ratio identity difference:
  `2.6469779601696886e-23`.
- Official corpus-lock SHA-256:
  `61237d7ea583866fe1b52579a2a86439aebf2186e0c09bda5a9dee910d59190a`.
- Base-R summary SHA-256:
  `a54f658d7e8981ea398b54e2827153d1f0c3f6610ffc38c5b4b36f51c1e3be9f`.
- Julia summary SHA-256:
  `33e1e81579c8b1d13fe6894b49f98eab15126361e704dbde1c5504eaffeaa749`.

Fisher, Noether, Hopper, Grace, and Rose independently returned narrow
`CLEAN/COMPLETE` post-run verdicts over the complete inventories. Those verdicts
are diagnostic observations only: the canonical receipt writer had not yet
bound them into the create-once evidence chain.

## Terminal failure

The first canonical command was the Fisher post-run receipt writer. It stopped
with `D0F successful result has malformed scientific output` before writing a
receipt. The failed log SHA-256 is
`e8d533d80ef5b8eb2d53b72e4c7d63b88c08d14ec822ca4c0a534936b2d9f1d1`.

`v3r_adjudicate_tables()` correctly admitted Julia rows as
`julia_profile_replay`, then `v3r_expected_summary()` reconstructed their
summary through helpers that silently defaulted back to
`ordinary_auto_genomic`. Correct Julia rows were therefore re-rejected under
the wrong route. The same latent path existed for D1. Clause-by-clause
diagnostics over official, base-R, and Julia rows found zero malformed
scientific, KKT, boundary, provenance, or finite-value fields.

## Freeze and seed retirement

The entire root was frozen, not repaired in place:

- 9,248 files, 598 directories, no links or special members;
- zero post-run receipt files and zero adjudication receipt files;
- sorted content digest before and after freeze:
  `148da8ef212bb4a303b6d4223cc63dae6142531370770a432283d852334d754f`;
- zero writable members and zero live root processes after freeze;
- freeze-log SHA-256:
  `f34da1d2c1906308967b9ff02527e8542ba0a06a9384bf83e837a5b6fe5a0255`.

Every Retry-6 phenotype seed under base `2040000000` and every bootstrap seed
under base `2041000000` is retired, including unused members. There is no
successor D0F seed allocation.

## Prospective seed-free repair

R commits `b8096e5` and `562b93e` prospectively:

1. thread `expected_route` through D0F and D1 summary reconstruction;
2. bind Julia summaries explicitly to `julia_profile_replay` while preserving
   the ordinary-R default;
3. test correct Julia route admission and wrong-route/wrong-driver rejection;
4. classify all Retry-6 phenotype/bootstrap seeds as historical and remove the
   proposed D0F retry stage.

This repair changes no attempt, packet, summary, receipt, payload, result
schema, estimator, estimand, ridge, tolerance, threshold, denominator, or
fitted output. It does not repair, replay, adjudicate, pool, or pass Retry 6.

## Next gate

Do not spend a fresh seed. A later successor requires a newly preregistered
contract and seed allocation, mutation controls, exact reviews, clean
deployment, preseal, and an explicit chronology audit. Compute remains
Totoro/DRAC only, never GitHub Actions.
