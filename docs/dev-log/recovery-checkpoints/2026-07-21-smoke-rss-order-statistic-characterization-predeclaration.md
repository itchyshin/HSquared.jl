# Pre-declaration — smoke-RSS order-statistic characterization (Gauss risk)

**Date:** 2026-07-20 (scoped) · **Lane:** Julia engine RSS, gating an R-side launcher design constant ·
**Status:** SCOPE / PRE-DECLARATION. **Not yet run** — execution needs (a) an outbound-SSH permission
rule so Totoro is reachable from this harness, and (b) Shinichi's explicit go-ahead to run real fits.

## 0. What this is

A pre-declared resource measurement to **close the open risk Gauss raised in P5**: the 16-row smoke
layout (`attempts_per_rung = 4`) is expected, by order statistics, to raise the observed `max(rss)`
relative to the current 1-per-rung layout, which lowers `recommend_workers`'s output and increases
exposure to the `workers < 1` floor stop. That risk is currently **unquantified**
(`docs/design/50-recovery-v3-arity-contract.md`, "OPEN NUMERICAL RISK";
`docs/dev-log/recovery-checkpoints/2026-07-20-smoke-arity-contract-predeclaration.md`, item 6). This
measurement quantifies it and fixes, **before seeing data**, the rule by which the result decides
whether `attempts_per_rung = 4` stands.

This is **not** a D1 campaign, a recovery attempt, or a successor. It draws **no** official campaign
seed, touches **no** retired root, mints no receipt, and moves no capability.

## 1. The formula under test (sealed `hsquared@5325e95`)

`recommend_workers()` (`tools/run-v07-genomic-recovery-v3.sh:575`):

```
workers = min(96L, preseal_cap, floor(0.7 * available_mb / max(rss)))
```

where `max(rss)` (`:559`) is the maximum `peak_rss_mb` over **every** smoke attempt file. Under the
D1 cell design (`n ∈ {120, 300, 600, 1200}`):

- **1-per-rung (current):** 4 fits, one per `n`. `max(rss) ≈ RSS(n=1200)`, a single draw.
- **4-per-rung (proposed):** 16 fits, four per `n`. `max(rss) ≈ max of 4 draws at n=1200`.

The inflation is `E[max of 4 draws @ n=1200] − E[1 draw @ n=1200]`, driven by the **variance** of
RSS at the top rung — which is empirical and is what this measures.

## 2. Fixed design (frozen)

- **Measurand:** `peak_rss_mb` of one genomic-fit `run-one` process at each `n ∈ {120,300,600,1200}`,
  with `m` per the frozen cell design, `OPENBLAS_NUM_THREADS=1` (matching the campaign's pinning).
- **Replication:** R = 12 reps per rung (48 fits total), each an isolated single process, so the
  measured RSS is the per-fit RSS the smoke step actually feeds the formula.
- **Seeds:** throwaway, from a fresh base **disjoint** from every retired/official space — base
  `20260721000 + rep`, explicitly NOT in `2028000000/101:148` and NOT `d1-reseal4`. Unseen at
  declaration.
- **Root:** a fresh scratch dir `~/hsq_work/rss-char-2026-07-21/`, unrelated to any campaign root.
- **Compute:** Totoro (Linux — has `/proc/meminfo`; the dev Mac cannot run this at all). ≤ a few
  cores; wall-clock small. **Smoke-first:** run ONE fit at `n=120`, confirm it writes a finite,
  positive `peak_rss_mb`, before the 48-fit grid.

## 3. Pre-declared decision rule (fixed here, not adjustable after seeing data)

Let `R_k` = the empirical max `peak_rss_mb` over `k` draws at the top rung (`k=1`, `k=4`). Define the
recommended workers at available RAM `A`: `W(k, A) = floor(0.7 · A / R_k)`.

1. Report `R_1`, `R_4`, the inflation `R_4 − R_1`, and the per-rung RSS distribution
   (mean, sd, min, max).
2. Compute `W(1, A)` and `W(4, A)` across a grid of `A` — including **Totoro's actual `available_mb`**
   and constrained values down to a DRAC-node scale.
3. **DECISION (predeclared):**
   - **SAFE-AS-IS** if, at Totoro's `available_mb`, `W(4, ·)` is still bounded by `preseal_cap`/96
     (i.e. RSS is not the binding term of the `min()`) — then `attempts_per_rung = 4` stands, and the
     result is recorded as the quantification the design owed.
   - **BOUNDED-MEMORY CAVEAT** — report the crossover `A*` below which `W(4,·) < W(1,·)` materially,
     or below which `W(4,·) < 1` trips the floor stop (`:576-578`). This becomes a documented memory
     floor for the layout (relevant on DRAC / loaded nodes), not a change to `attempts_per_rung`.
   - **UNSAFE** if even at Totoro's `available_mb` the 4-per-rung layout trips `workers < 1` or drops
     workers to an unusable level → `attempts_per_rung = 4` is **revisited** (fewer attempts at the
     top rung, or a different RSS-aggregation), and the P4 predeclaration's §1 constant is reopened.

## 4. Scope boundary (declared in advance)

This characterizes the **isolated single-fit** RSS that the smoke step feeds the formula — which is
the correct input to `recommend_workers`, since smoke fits are what it reads. It does **not** measure
peak RSS under N-way parallel co-residence during the official run; that is a separate quantity and a
separate question, out of scope here. A PASS here means "the layout does not starve the worker
recommendation," not "the parallel official run fits in memory."

## 5. What does not change

Planning/measurement only. No official seed, no retired root, no receipt, no capability move:
`public_covered_count = 5`, `ordinary_auto_genomic` held, V2-GRM/V2-GINV partial, D1 paused. A result
here informs one design constant; it authorizes no campaign.

---

## RESULT (run 2026-07-20 on Totoro, 384 cores / 415 GB avail) — **GATE: SAFE-AS-IS**

Executed the frozen design: 48 fits (12 reps × 4 rungs), fresh Julia process each,
`OPENBLAS_NUM_THREADS=1`, throwaway seeds `20260721000+k` (disjoint from every retired space),
fresh root `~/hsq_work/rss-char-2026-07-21/`. **48/48 completed, 0 errors.** Smoke (n=120) was
validated before the grid. Raw data:
`docs/dev-log/recovery-checkpoints/2026-07-21-smoke-rss-characterization-evidence.tsv`.

**Per-rung peak RSS (MB):**

| n | m | reps | mean | sd | min | max |
|---|---|---|---|---|---|---|
| 120 | 60 | 12 | 572.2 | 13.4 | 553.5 | 602.5 |
| 300 | 150 | 12 | 577.5 | 6.4 | 567.0 | 587.9 |
| 600 | 300 | 12 | 604.6 | 8.9 | 588.0 | 615.6 |
| 1200 | 600 | 12 | **783.0** | 11.2 | 751.1 | 802.6 |

RSS **does** scale with `n` (572 → 783 MB; the n=1200 GRM+REML adds ~210 MB over baseline — the
measurement was not trivially runtime-constant), but the **top-rung variance is small** (sd 11.2 MB).

**Order-statistic effect (the thing Gauss flagged), quantified:**
- `R_1` (max over 1 draw/rung, top rung dominates) ≈ **783 MB**; `R_4` (max over 4 draws at the top
  rung, E[max of 4] from N(783, 11.2)) ≈ **795 MB**; worst single observed = 802.6 MB.
- **Inflation `R_4 − R_1` ≈ 12 MB (1.5% of R_1).** Real, and in the predicted direction — just small.

**Decision-rule evaluation** (`W(k,A) = floor(0.7·A / R_k)`, `A = 415206 MB`):
- `W(1) = 371`, `W(4) = 365`, worst-observed `= 362` — all capped by `min(96, preseal_cap)`. **RSS is
  ~4× below the binding term**, so the worker recommendation is set by the cap, not by RSS. →
  **SAFE-AS-IS: `attempts_per_rung = 4` stands.**

**Bounded-memory caveat (predeclared reporting):**
- RSS only becomes the binding term (`W < 96`) below **~106 GB** available (4-per-rung) vs ~105 GB
  (1-per-rung) — the order-statistic effect shifts the threshold by **~2 GB**.
- The `workers < 1` floor stop (`:576-578`) only triggers below **~1.1 GB** available; the
  order-statistic effect shifts it by ~17 MB. No realistic node runs that low.
- **Conclusion:** on any node with more than ~110 GB available, the 16-row layout is safe regardless;
  between ~1 GB and ~110 GB the recommendation is RSS-limited but the 4-vs-1 difference is <2%; the
  floor stop is unreachable in practice.

**Scope caveat (as declared in §4):** this is the **Julia-side isolated single-fit** RSS. The
campaign's `run-one` is R invoking Julia, adding a roughly-constant R offset (~100–200 MB) that raises
all `R_k` uniformly — it lowers the ~106 GB crossover somewhat but changes neither the ~12 MB
order-statistic inflation nor the Totoro safety margin (still ~4× below binding). It does **not**
measure peak RSS under N-way parallel co-residence during the official run, which remains a separate
question.

**No capability moved.** `public_covered_count = 5`, `ordinary_auto_genomic` held, D1 paused. This
discharges the "OPEN NUMERICAL RISK" flag Gauss raised in P5; `attempts_per_rung = 4` is retained with
the bounded-memory note above attached for any future DRAC/constrained-node run.
