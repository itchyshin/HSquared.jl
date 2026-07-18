# D1 campaign — PRE-REGISTRATION (PRE-0)

**Committed BEFORE any official RNG draw.** The git commit that adds this file is the pre-declaration
stamp for the D1 576-fit interior-recovery pilot. No D1 phenotype or marker panel has been drawn. This
document is outcome-neutral and fixes every predicate in advance so no threshold can be relaxed post-hoc.
It follows the Retry-7/Retry-8 D0F PRE-0 template (`docs/dev-log/2026-07-17-retry7-d0f-campaign-preregistration.md`,
`…retry8-…md`), carried forward unchanged except where a D1-specific difference is noted.

**Authorization.** The phenotype+marker draw (§8, point of no return) requires a **separate fresh
in-session user GO** after a shown-GREEN adversarial pre-draw panel. This pre-registration authorizes only
the reversible pre-draw work (predecessor checkpoint, green-gate, preflight, panel).

**STATUS (2026-07-18): HELD at the S4 admission gate.** Julia-side pre-draw checks PASS on Totoro — env
`ok=TRUE` (global bridge env OrderedCollections 2.0.1), seed-lock `v07s_selftest` PASS (D1 `2028000000/101:148`
validates, disjoint), D0F predecessor receipt `04cc0740` present. Awaiting R-twin certification that hsquared
`d3835fe` is the sanctioned D1 R head and `code-d3835fe-1a538212` the intended deployment (user decision,
2026-07-18). No `prepare`/`preseal`/draw has run; no seed drawn.

**Bound heads — D1 runs on the D1-capable deployment, distinct from the D0F seal (verified 2026-07-18):**
Julia `1a538212` ("admit typed parity across R versions") + R `d3835fe` ("inject recovery compute guard"),
deployed git-clean at Totoro `v07-genomic-recovery-v3-code-d3835fe-1a538212`. Julia `1a538212` is a
reviewed ancestor of branch HEAD `27d5047d` (and a descendant of the D0F Julia seal `976814`). The **D0F
predecessor** was sealed under Julia `976814…` / R `a23b15b…` and is bound by receipt sha `04cc0740`,
**not** by head-equality. ⚠ OPEN: local `hsquared` HEAD is `a23b15b`, BEHIND the D1 R deployment
`d3835fe` (R twin advanced it for D1) — confirm `d3835fe` is the sanctioned D1 R head, and that
`code-d3835fe-1a538212` (vs a fresh clone at branch HEAD) is the sanctioned D1 deployment, before the draw.
The prior sealed-D0F heads were: Julia `976814393043d3a4af5ce343d8ac4b05c43eac41`; R `a23b15bc4dfc8c356cc41ac4e53ac2050a3edde0`
(route-repair `b8096e5` confirmed ancestor; driver aborts loud on wrong route). The Julia D1 replay driver
is the **tracked** `sim/phase2_v07_genomic_recovery_v3_stage_replay.jl` (NOT the untracked
`…downstream_replay.jl`, which is D2/D3/D4). Canonical D1 sealed root: assigned fresh at preseal, **distinct
and non-nested** from the D0F predecessor root and from every retired root.

## 0. What D1 is (vs D0F)

D0F held the marker kernel fixed and drew phenotypes to characterize replication variance — diagnostic
only, and its sole downstream job was to be the sequencing checkpoint that **opens** D1. D1 **redraws
everything fresh** (markers + phenotypes) across the full interior factorial and measures the interior
estimand's finite-sample behaviour + per-cell **eligibility** (`cell_status`/`cell_eligible`), whose
decisions feed D2 edge-pilot selection. **No D0F estimate enters the D1 analysis** (doc49 §D1).

Design (doc49 §D1): `r_G = 0.5`, 48 fresh pilot seeds per cell, full factorial
`n ∈ {120,300,600,1200} × m/n ∈ {0.5, 10/3, 5}` → the **12 exact `(n,m)` cells**
`(120,60) (120,400) (120,600) (300,150) (300,1000) (300,1500) (600,300) (600,2000) (600,3000)
(1200,600) (1200,4000) (1200,6000)` → **576 attempted fits**. Per-fit records add projected-spectrum CV,
effective rank, `SE_info(0.2/0.5/0.8)`, boundary status, fitted total variance, runtime, peak RSS.

## 1. Predecessor binding — fresh-D0F checkpoint (D1-specific, the load-bearing gate)

D1's preseal binds the canonical D0F root **and** its receipt SHA-256. The checkpoint is enforced by
`_validate_d0f_predecessor` (`sim/phase2_v07_genomic_recovery_v3_stage_replay.jl:432-450`) + doc49 §D1:

- **Canonical D0F root:** `retry8-prep/d0f/` (Totoro). **Receipt** `stage_adjudication_receipt.tsv` sha256
  `04cc074071a02b58fa269f3a4b65a8455314bb40b97b2b9c7b6af91f485d7e80`.
- **Receipt must verify:** schema `v07-genomic-recovery-v3-adjudication-2` (the value pinned in code as
  `D0F_ADJUDICATION_SCHEMA`, `:40`), `stage == d0f`, `verdict == PASS`, `stage_decision == COMPLETE`,
  parity maxima ≤ `1e-10`, all provenance digests/commits valid, five post-run review paths present.
  *(Doc-level staleness flagged: doc49 §D1 prose still names schema `…adjudication-1`; the CODE and the
  actual D0F receipt are `…adjudication-2`. Follow the code. This is an R-twin doc reconciliation item,
  not a blocker.)*
- **Blocked root forbidden:** `d0f_adjudication_root` must NOT equal
  `D0F_BLOCKED_ROOT = …/v07-genomic-recovery-v3-d0f-official-0a9d882-1a538212` (`:39`), and must be
  distinct + non-nested vs the D1 root.
- **Full re-derivation preflight (not a hash shortcut):** the operational R adjudicator reconstructs the
  expected D0F receipt from the exact D0F preseal, corpus, attempts, packets, independent recomputations,
  Julia replays, summaries, and five reviews, and the whole D0F final tree must validate
  (`v3r_validate_final(root,'d0f')`). This runs as a centralized early-stop **before every D1 launcher
  fan-out**, and every worker revalidates the exact final tree **before consuming its seed**.

## 2. Seed-space isolation (declared disjoint)

- **D1 seed formula (enforced, `:365-366`):** `seed = 2_028_000_000 + 10_000·cell_index + offset`,
  `offset ∈ 101:148` (48 per cell) over the 12 interior cells = **576 seeds**. `_validate_manifest`
  errors on any "D1 membership/order/seed formula drift" (`:369`) or "D1 scientific contract drift"
  (`:370`, requires `stage=d1`, all truths `0.5`, `ridge=0.01`).
- **No bootstrap seed base** — bootstrap two-level resampling was a D0F-only feature; D1 is 576 fresh
  single-seed pilot fits.
- **Declared disjoint from:** every retired D0F ladder space (2029/2031 … 2042/2043), the historical
  doc-44/47/48 spaces (`20270701`, `2027120000`), the D0 official space, and the downstream D2/D3/D4
  offset bands *within* base `2028000000` (D1 = `101:148`; D2 = `1001+/2001+/5001+`) — disjoint by offset
  band. **Any collision voids the run.**
- **Pre-reserved, not freshly allocated:** unlike the D0F phenotype/bootstrap ladder (one fresh base pair
  per retry), D1's `2028000000/101:148` space was reserved from the start in doc49's downstream scheme and
  in `hsquared/tools/v07_genomic_recovery_v3_seed_lock.R`. The seed-lock `v07s_selftest` must validate
  green before draw (§3 PRE-3); it currently still labels the D0F bases `2042000000/2043000000` as
  "reserved D0F_RETRY7" though Retry-8 spent them — an **R-twin retirement amendment** owed, verified
  non-blocking (2042/2043 do not collide with `2028000000/101:148`).

## 3. Pre-seed GREEN-GATE (all pass BEFORE the draw)

- **PRE-1 — fresh-D0F checkpoint GREEN:** §1 full re-derivation preflight passes; the D0F receipt
  re-derives byte-identical and the whole D0F final tree validates; predecessor bound in the D1 preseal.
- **PRE-2 — D1 driver preflight PASS:** driver `preflight` mode validates sealed inputs, preseal key/order,
  predecessor, and seed-lock with **no official RNG consumed**.
- **PRE-3 — seed-lock green:** `v07s_selftest` validates the `2028000000/101:148` D1 space + disjointness;
  the 2042/2043 retirement is reconciled or verified non-blocking.
- **PRE-4 — smoke:** a 1-cell dry replay produces **non-empty, in-range** D1 summary output
  (`D1_SUMMARY_COLUMNS`, `:84`) with a valid invocation; runtime measured at smoke scale before production
  concurrency is set. Read the FIRST cell's output and abort on empty/NA/out-of-range.
- **PRE-5 — toolchain/env freeze + env-verify `ok=TRUE`:** OrderedCollections `2.0.1` in both the global
  JuliaCall bridge env and `julia_root` (project), `julia_root` git-clean at sealed `976814`, `TMPDIR`
  pinned to `/home/snakagaw/hsq_work/jltmp`, `OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=1`, `host=totoro`,
  ≤96 workers. Env verified by the exact `hs_julia_setup` path + negative control, not a proxy.

**The draw is forbidden until PRE-1…PRE-5 are green.**

## 4. Acceptance predicates (pre-declared; outcome-NEUTRAL)

A D1 receipt is **admissible/complete** iff ALL hold (schema
`v07-genomic-recovery-v3-adjudication-2`, columns `D0F_ADJUDICATION_COLUMNS`/D1 variant, `:79`, incl. the
D1-carried `route_lineage_sha256`, `adjudication_key_sha256`):

- `attempt_max_diff` AND `summary_max_diff` finite and ≤ `1e-10` (official R vs base-R vs Julia replay).
- Boundary component-ratio identity ≤ `1e-12` (`COMPONENT_RATIO_TOLERANCE`, `:25`).
- Every `julia_profile_replay` row admitted under its OWN route (never rebound to `ordinary_auto_genomic`);
  weighted route-lineage conserved.
- Receipt is create-once, byte-identical primary+sidecar, and **survives its own `validate-final`
  re-derivation**; self-hashed `adjudication_key` verifies.
- 5 bound review receipts (fisher, noether, hopper, grace, rose) present, each `verdict == CLEAN`.

**The deliverable is an adjudicated D1 receipt that re-derives byte-identical, WHATEVER the verdict.**
PASS is not presupposed. `stage_decision` for D1 is a per-cell **status tally** (e.g. `ELIGIBLE=n;…` over
the 12 cells), computed from the data — not a target.

## 5. Admissible outcomes (NOT contract breaches)

- Authenticated per-cell statuses `ELIGIBLE` / `PRECISION_BLOCKER` / `FUTILITY_STOP` /
  `STOP_LOW_PILOT_CONVERGENCE` are all valid D1 outcomes to be banked, not hidden.
- `boundary_lower` / `boundary_upper` and genuine non-convergence are ADMISSIBLE fit statuses.
- `RECOMPUTATION_BLOCKER` is NOT an authenticated pilot outcome: it prevents a PASS receipt and therefore
  cannot enter the ordered predecessor history.

## 6. What a D1 PASS MEANS — and does NOT license

- **Means:** a valid, independently reproducible D1 evidence tree (triple parity ≤ `1e-10`) yielding the
  per-cell interior finite-sample metrics (RMS `SE_info(0.5)`, empirical ratio SD, `C_c`, predicted vs
  observed boundary probabilities) and the per-cell eligibility decisions. It **only OPENS D2** (edge
  pilots) for the eligible cells. A PASS says the tree is valid + reproducible — **not** that any cell is
  eligible.
- **Does NOT license:** any public bias / calibration / coverage / recovery capability claim; moving
  `public_covered_count` off **5**; activating / merging / releasing the `ordinary_auto_genomic` route;
  "covering" genomic REML beyond the supplied-`Ginv` estimator; or discharging V2-GRM / V2-GINV (they stay
  `partial`). A count/route move requires the full D0→D4 ladder + G1–G7 + a **separate maintainer G10** +
  a prospective doc-44 amendment — none delivered by D1.

## 7. Negative-outcome protocol (post-draw only)

On any tail failure / `RECOMPUTATION_BLOCKER` that prevents a byte-reproducible receipt: bank the negative
in the capability-status row + validation-debt register, **retire the D1 root and the D1 seed space**
(`2028000000/101:148`; fresh allocation for any successor), record the exact defect for the next
preregistered contract, and make **no** activation / coverage / discharge claim. **A pre-draw blocker does
NOT retire the seed space** — root-forfeit is scoped to post-draw failures (this is exactly why Retry-8
could reuse the D0F 2042/2043 space after a pre-draw blocker). A completed-but-unadjudicated corpus is
diagnostic and moves no count.

## 8. Lane + point of no return

The R twin (`hsquared`) owns markers/phenotypes/official fits/base-R recompute/summarize-r/adjudication;
`HSquared.jl` replays + summarizes-julia + validate-final. **Executor: CLAUDE runs both lanes this session
under the user's express authorization** (sequential; no concurrent Codex). The **draw (official RNG over
`2028000000/101:148`) is the point of no return** under the root-forfeit rule and stays LAST, after the
green-gate and a shown-GREEN adversarial pre-draw panel + an explicit in-session user GO. Compute: Totoro,
`OPENBLAS_NUM_THREADS=1`, JULIA threads=1, `TMPDIR` pinned, ≤96 workers, every long stage detached with a
completion marker + log poll, resume via complete-prefix only, corpus immutable.

## Pipeline phase order (driver-enforced — do not reorder)

`official → locked → base_r → summarize-r → replay-julia → julia_summary → lineage → review →
final (adjudicate → validate-final)`. `summarize-r` MUST precede `replay-julia`.
