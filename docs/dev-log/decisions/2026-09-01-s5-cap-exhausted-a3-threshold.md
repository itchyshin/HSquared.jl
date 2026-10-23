# S5 Leg A — A3 `CAP-EXHAUSTED` rate threshold (≤ 4/48)

**Date:** 2026-09-01  
**Status:** **ADOPTED (blind, pre-run)** — binds the frozen S5 gate when executed  
**Owner approval:** G0 Q2 (`~/local-scratch/h2-twin-g0-approval.md`)  
**Gate:** `sim/phase_s5_matfree_tail_recovery_gate.jl` Leg A criterion **A3**  
**Predeclaration:** `docs/dev-log/recovery-checkpoints/2026-08-04-f6-matfree-tail-recovery-predeclaration.md`  
**Promotes nothing.** `public_covered_count` stays 5 regardless of S5 outcome.

---

## Decision

The S5 tail-scale known-truth recovery gate (`fit_matrix_free_reml`, q=25,000, 48 seeds)
adopts the following **pre-run, blind** bound on bucket **(b) CAP-EXHAUSTED** fits:

> **A3:** `n_cap_exhausted ≤ 4` out of 48 (~8.3%).

This number is fixed **before** the 48-seed campaign runs. It must not be revised from
observed S5 output. If the bound is wrong in hindsight, the correct response is a new
predeclared gate at a new commit — not a post-hoc relaxation (see
`docs/dev-log/decisions/2026-06-14-calibration-failure-response.md`).

---

## Why a separate A3 bound exists

Leg A classifies each fit **three ways** (revised 2026-08-04 on Slice-B evidence):

| Bucket | Meaning | Gate |
|--------|---------|------|
| **(a) CONVERGED** | tolerance met within cap | contributes to A1 |
| **(b) CAP-EXHAUSTED** | graceful, finite, non-negative, `iterations == 200` exactly | **A3** |
| **(c) NON-GRACEFUL** | threw or non-finite/negative variance | **A2** (0/48) |

Bucket **(b)** is not a correctness failure like **(c)**. It is a **budget signal**: the
fitter returned a graceful estimate but did not verify convergence within the pre-declared
200-iteration default. A1 averages over graceful `(a)∪(b)`; without A3, a material cap-exhaustion
rate could be diluted into a passing mean (Slice B: one cap-exhausted draw at 5.45% rel.err
against a 5% A1 gate — exactly the failure mode this leg exists to surface).

A3 therefore gates **how often** the default iteration budget is insufficient, separately
from whether graceful estimates are accurate on average (A1) and whether the fitter throws
or returns garbage (A2).

---

## Fisher rationale for ≤ 4/48

### 1. Blind pre-registration (non-negotiable)

G0 Q2 (owner Shinichi, 2026-09-01): fix the threshold **before** S5 runs, on principle, not
from results. A threshold chosen after seeing output is not a gate; Fisher blocks that.
This decision is the in-repo precedent the frozen predeclaration's OWNER-REVISABLE clause
requested.

### 2. Anchoring relative to A2 (rule-of-three)

**A2** uses **0/48** non-graceful, anchored to Leg C's 100%-graceful standard and the
rule-of-three: at n=48, zero events → upper 95% CI ≈ **6.3%** for the true rate.

**A3** tolerates a **non-zero** cap-exhaustion rate because **(b) ≠ (c)**:
- **(c)** is a robustness/correctness failure — zero tolerance is appropriate.
- **(b)** is an iteration-budget question — a small number of hard stochastic draws at
  tail scale is plausible without implying the fitter is broken.

**4/48 ≈ 8.3%** is deliberately **slightly above** the rule-of-three ceiling for a zero
event at n=48 (6.3%). The extra headroom (~2 percentage points) buys tolerance for
Monte-Carlo EM variance and Hutchinson trace noise at q=25,000 without opening the gate
wide enough to hide a systematic default-cap failure.

### 3. What 4/48 is designed to catch vs tolerate

| Outcome | Interpretation |
|---------|----------------|
| **0–4 cap-exhausted** | Acceptable: a handful of hard draws; default cap may be tight but not systematically insufficient. Leg A may still pass if A1 and A2 hold. |
| **≥5 cap-exhausted** | **Finding, not tuning opportunity.** The 200-iteration default is measurably insufficient at tail scale. Leg A **FAIL**; do not average away inside A1. |

Slice B (n=400, one seed) showed cap exhaustion is real but not the dominant mode on an
"easy" draw at smaller scale. It does **not** supply a rate estimate at q=25,000 — hence
the judgment-call framing, not a fitted quantile.

### 4. Symmetry with existing repo gate culture

This repo's validation gates predeclare bounds before seeds run (MV REML gates, calibration
failure response, S5 freeze). A3 follows the same culture:

- **Conservative on correctness** (A2 = 0/48).
- **Explicit but bounded on budget** (A3 ≤ 4/48).
- **Fail closed on post-hoc relaxation.**

### 5. Owner revisability (before run only)

The number remains revisable **only** by re-freezing the predeclaration at a new commit
**before** any 48-seed campaign — not from S5 output. G0 Q2 selected ≤4/48; this document
records that choice as the precedent.

---

## Implementation binding

When the S5 script and predeclaration are present on the executing branch:

- `sim/phase_s5_matfree_tail_recovery_gate.jl`: `const A3_MAX_CAP_EXHAUSTED = 4`
- Predeclaration OWNER-REVISABLE banner: superseded for A3 by this decision (other clauses
  unchanged).
- Leg A GATE remains **A1 ∧ A2 ∧ A3**.

---

## Review lenses

| Lens | Sign-off |
|------|----------|
| **Fisher** | Blind pre-run bound adopted; anchored to rule-of-three logic; separate from A2 correctness gate. |
| **Gauss** | 200-iteration cap stays at function default; A3 surfaces systematic cap insufficiency without raising the cap to pass. |
| **Rose** | No capability promotion; threshold fixed before run per G0 Q2. |

---

## References

- G0 approval Q2: `~/local-scratch/h2-twin-g0-approval.md`
- S5 predeclaration: `docs/dev-log/recovery-checkpoints/2026-08-04-f6-matfree-tail-recovery-predeclaration.md`
- S5 freeze record: `docs/dev-log/decisions/2026-08-04-g10-not-delegated-and-s5-freeze-record.md`
- Calibration failure response: `docs/dev-log/decisions/2026-06-14-calibration-failure-response.md`
- B1 barrier: `~/local-scratch/h2-twin-b1-barrier.md`
