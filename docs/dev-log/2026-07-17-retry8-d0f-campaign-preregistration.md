# Retry-8 D0F campaign — PRE-REGISTRATION (repaired-head successor)

**Committed before any phenotype draw.** Retry-8 is the repaired-head successor to Retry-7, whose
`-c` root was banked as a pre-draw blocker (the `v3d_validate_attempt` run-one defect). This doc
carries forward the Retry-7 pre-registration
(`docs/dev-log/2026-07-17-retry7-d0f-campaign-preregistration.md`) unchanged except where noted, and
records the two Retry-8-specific decisions. Authorization: the user authorized "start Retry-8" on
2026-07-17; the phenotype draw still requires a separate fresh in-session GO after the admission gate.

## What changed from Retry-7 (the repaired head)

- **Run-one fix** (`hsquared` `96529fd`): `v3d_validate_attempt` now passes `expected_route`
  (`= v3d_route = "ordinary_auto_genomic"`) to `v3p_validate_results` — the arg the route-repair
  `b8096e5` left missing at this call site. Rose PROMOTE.
- **Blind-spot regression** (`96529fd`): `tests/testthat/test-v07-recovery-v3-run-one-arity.R` drives
  `v3d_validate_attempt` (RED-before/GREEN-after) so a driver↔preseal arity mismatch fails on the Mac,
  not on the live draw.
- **Sidecar refresh** (`a23b15b`): regenerated the tracked `v07_genomic_recovery_v3.R.sha256` (the
  fix changed the driver but left its checksum sidecar stale; the preseal self-integrity check
  fail-closed on it). Driver *content* sha `d1a7d930…` unchanged.
- **Bound R head for Retry-8:** `a23b15bc4dfc8c356cc41ac4e53ac2050a3edde0`. Julia head unchanged
  (`976814393043…`). New sealed root built fresh under these heads.

## Decision 1 — seed reuse (2042000000 / 2043000000)

Retry-8 **reuses** the Retry-7 phenotype/bootstrap seed bases (2042000000 / 2043000000) on a fresh
output root. Rationale:
- The Retry-7 `-c` root is **provably pristine** — the run-one blocker struck at fit-entry validation
  *before* any persistent draw (preflight re-PASS, hashes unchanged, no attempts/packets, no
  seed-2042 artifact). The seed space was never consumed.
- The pre-registration's forfeit/retire clause is scoped to **post-draw** failures (tail /
  PRECISION_BLOCKER); Rose's close-out audit confirmed this blocker is a **pre-draw** defect, so the
  "retire the seed spaces" clause did **not** trigger.
- The seed-lock (`v07_genomic_recovery_v3_seed_lock.R`) registers 2042/2043 as the **current**
  `D0F_RETRY7` bases (not retired), so a fresh preseal proposing them validates.
Only the defective `-c` **output root** is set aside (a directory); the unspent seed space is reused.
Because the fix touched only attempt *validation* (not marker/phenotype draw code), the draws are
byte-identical to what Retry-7 would have produced.

## Decision 2 — executor + venue

Claude executes both lanes this session (user-authorized). Live on Totoro via the ControlMaster
socket; env pins: Julia 1.10.10, `OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=1`, **stable
`TMPDIR=/home/snakagaw/hsq_work/jltmp`** (required — R's ephemeral tmp breaks the JuliaCall precompile
worker), `host=totoro`, ≤96 workers, bootstrap immutable.

## Carried forward from Retry-7 PRE-0 (unchanged)

- **Acceptance predicates (outcome-neutral):** a COMPLETE receipt requires triple parity
  (attempt/summary max diff ≤1e-10), boundary component-ratio ≤1e-12, every `julia_profile_replay`
  row admitted under its own route, byte-identical create-once receipt surviving `validate-final`,
  5 bound review receipts, schema `v07-genomic-recovery-v3-adjudication-2`. **PASS is not
  presupposed.** The deliverable is an adjudicated receipt that re-derives byte-identical, whatever
  the verdict.
- **Admissible outcomes:** boundary_lower/upper + genuine non-convergence are valid fit statuses;
  PRECISION_BLOCKER is an admissible bankable negative.
- **What a PASS does NOT license:** no bias/coverage/recovery claim; does NOT move
  `public_covered_count` off **5**, activate/merge/release the `ordinary_auto_genomic` route, or
  discharge V2-GRM/V2-GINV (they stay partial). A COMPLETE D0F receipt only OPENS D1/D2.
- **Negative-outcome protocol (post-draw):** on a tail failure / PRECISION_BLOCKER, bank the negative,
  retire the root + both seed spaces (fresh allocation for any further successor), no
  activation/discharge claim.
- **Point of no return:** the phenotype draw (seed base 2042000000) stays LAST, behind a shown GREEN
  pre-draw assertion + a fresh in-session user GO.
