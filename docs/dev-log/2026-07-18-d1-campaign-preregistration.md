# D1 campaign — PRE-REGISTRATION (PRE-0)

**Committed BEFORE any official RNG draw.** The git commit that adds this file is the pre-declaration
stamp for the D1 576-fit interior-recovery pilot. No D1 phenotype or marker panel has been drawn. This
document is outcome-neutral and fixes every predicate in advance so no threshold can be relaxed post-hoc.
It follows the Retry-7/Retry-8 D0F PRE-0 template (`docs/dev-log/2026-07-17-retry7-d0f-campaign-preregistration.md`,
`…retry8-…md`), carried forward unchanged except where a D1-specific difference is noted.

**Authorization.** The phenotype+marker draw (§8, point of no return) requires a **separate fresh
in-session user GO** after a shown-GREEN adversarial pre-draw panel. This pre-registration authorizes only
the reversible pre-draw work (predecessor checkpoint, green-gate, zero-seed preflight, panel). **Smoke is
NOT pre-draw** — see §3/§8: the smoke tooling draws official seeds, so it sits AFTER the GO.

> **REVISION (2026-07-18, after adversarial pre-draw audit — 6 lenses, 25 agents, 3 blockers found).**
> An earlier draft of this pre-registration bound the WRONG deployment (`code-d3835fe-1a538212`, Julia
> `1a538212` / R `d3835fe`) and asserted those were *descendants* of the D0F seal. **`git merge-base`
> refutes that: they are older ANCESTORS** (Julia `1a538212` is an ancestor of `976814` by ~29 commits;
> R `d3835fe` is an ancestor of `a23b15b` by ~53 commits). At those heads the Julia driver LACKS
> `_validate_d0f_predecessor` + the adjudication-2 schema (the §1 gate), and the R side is schema
> `adjudication-1` with `admission.R`/`downstream_contract.R` absent. That deployment CANNOT run D1. The
> binding below is corrected to the sanctioned D0F-seal heads. No seed was ever drawn.

**STATUS (2026-07-18): HELD at the S4 admission gate; pre-registration REVISED after audit.** Julia-side
env `ok=TRUE`, seed-lock `v07s_selftest` PASS, D0F predecessor receipt `04cc0740` present. **The sanctioned
deployment ALREADY EXISTS and is certified by live repo evidence (2026-07-18):**
`~/hsq_work/retry8-prep/{hsquared@a23b15b, HSquared.jl@976814}` — the tree that produced the D0F PASS — is
git-clean; its Julia driver has `_validate_d0f_predecessor` (6 hits) + `adjudication-2` +
`COMPONENT_RATIO_TOLERANCE`; its R side has `admission.R`/`downstream_contract.R`/`preseal.R`/`recompute.R`
all at `adjudication-2`. **No re-deployment/clone needed.** The auto-discovered `code-d3835fe-1a538212`
remains stale pre-fix and must not be used. Remaining before the draw: PRE-1 dry `validate-final` (D0F
re-derives `04cc0740` byte-identical) + the live adversarial panel + explicit user GO. No
`prepare`/`preseal`/draw has run; no seed drawn.

**Bound heads — D1 runs on the sanctioned D0F-seal heads (or descendants that keep the gate + schema-2):**
- **R:** `a23b15bc4dfc8c356cc41ac4e53ac2050a3edde0` (`a23b15b`) — schema `adjudication-2`; `admission.R` +
  `downstream_contract.R` present; post route-repair `b8096e5` + fail-closed fix `96529fd`. This is the head
  that produced the D0F PASS (`r_driver_commit` in receipt `04cc0740`).
- **Julia:** `976814393043d3a4af5ce343d8ac4b05c43eac41` (`976814`, the D0F seal; == receipt `julia_replay_commit`)
  or branch HEAD `27d5047d` (driver byte-identical to `976814`; later commits are docs-only). Both are
  `≥ e45dbe0a` "enforce D0F predecessor before D1", so the driver CONTAINS `_validate_d0f_predecessor`
  (`sim/phase2_v07_genomic_recovery_v3_stage_replay.jl:432-450`) and `D0F_ADJUDICATION_SCHEMA="…adjudication-2"`
  (`:40`).
- The **D0F predecessor** is bound by receipt sha `04cc0740`, **not** by head-equality; the D1 deployment
  heads are newer-or-equal to the receipt's commits and MUST contain the gate.
- **DO NOT USE** `code-d3835fe-1a538212` (Julia `1a538212` / R `d3835fe`): stale pre-fix ancestors, gate +
  schema-2 absent, `admission.R`/`downstream_contract.R` missing on the R side. A directory literally named
  `code-d3835fe-1a538212` must not run the campaign.

The Julia D1 replay driver is the **tracked** `sim/phase2_v07_genomic_recovery_v3_stage_replay.jl` (NOT the
untracked `…downstream_replay.jl`, which is D2/D3/D4). Canonical D1 sealed root: assigned fresh at preseal,
**distinct and non-nested** from the D0F predecessor root and from every retired root.

## 0. What D1 is (vs D0F)

D0F held the marker kernel fixed and drew phenotypes to characterize replication variance — diagnostic
only, and its sole downstream job was to be the sequencing checkpoint that **opens** D1. D1 **redraws
everything fresh** (markers + phenotypes) across the full interior factorial and measures the interior
estimand's finite-sample behaviour + per-cell **eligibility** (`cell_status`/`cell_eligible`), whose
decisions feed D2 edge-pilot selection. **No D0F estimate enters the D1 analysis** (doc49 §D1).

Design (doc49 §D1): `r_G = 0.5`, 48 fresh pilot seeds per cell, full factorial
`n ∈ {120,300,600,1200} × m/n ∈ {0.5, 10/3, 5}` → the **12 exact `(n,m)` cells**
`(120,60) (120,400) (120,600) (300,150) (300,1000) (300,1500) (600,300) (600,2000) (600,3000)
(1200,600) (1200,4000) (1200,6000)` → **576 attempted fits**. Cell-index set (verified identical in both
lanes — R `v07s_v3_cells`, Julia `_cell_table`): **`{2,5,8,11,14,17,20,23,26,29,32,35}`**. Per-fit records
add projected-spectrum CV, effective rank, `SE_info(0.2/0.5/0.8)`, boundary status, fitted total variance,
runtime, peak RSS.

## 1. Predecessor binding — fresh-D0F checkpoint (D1-specific, the load-bearing gate)

D1's preseal binds the canonical D0F root **and** its receipt SHA-256. The checkpoint is enforced by
`_validate_d0f_predecessor` (`sim/phase2_v07_genomic_recovery_v3_stage_replay.jl:432-450`) + doc49 §D1.
*(Line refs are to the sanctioned Julia head `976814`/HEAD `27d5047d`, which contain the gate — NOT the
stale `1a538212`, where it is absent.)*

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
  fan-out**, and every worker revalidates the exact final tree **before consuming its seed**. NOTE: this
  requires the deployed R recomputer to be schema `adjudication-2` (head `a23b15b`+); at the stale
  `d3835fe` it is `adjudication-1` and this preflight ABORTS — the reason the deployment must be re-pinned.

## 2. Seed-space isolation (declared disjoint)

- **D1 seed formula (enforced, `:365-366`):** `seed = 2_028_000_000 + 10_000·cell_index + offset`,
  `offset ∈ 101:148` (48 per cell) over the 12 interior cells = **576 seeds**. `_validate_manifest`
  errors on any "D1 membership/order/seed formula drift" (`:369`) or "D1 scientific contract drift"
  (`:370`, requires `stage=d1`, all truths `0.5`, `ridge=0.01`).
- **No bootstrap seed base** — bootstrap two-level resampling was a D0F-only feature; D1 is 576 fresh
  single-seed pilot fits (driver `:514` requires the three D0F-bootstrap keys == "NA").
- **Declared disjoint from:** every retired D0F ladder space (2029/2031 … 2042/2043), the historical
  doc-44/47/48 spaces (`20270701`, `2027120000`), the D0 official space, and the downstream D2/D3/D4
  offset bands *within* base `2028000000` (D1 = `101:148`; D2 = `1001+/2001+/5001+`) — disjoint by offset
  band. **Any collision voids the run.** (Verified: D1 window `2_028_020_101…2_028_350_148` < the D0F
  `2_042_*` space; `anyDuplicated` checks in `seed_lock.R`.)
- **Pre-reserved, not freshly allocated:** unlike the D0F phenotype/bootstrap ladder (one fresh base pair
  per retry), D1's `2028000000/101:148` space was reserved from the start in doc49's downstream scheme and
  in `hsquared/tools/v07_genomic_recovery_v3_seed_lock.R`. The seed-lock `v07s_selftest` validated green
  (PASS: 38593 historical; 92304 possible v3 seeds). It currently still labels the D0F bases
  `2042000000/2043000000` as "reserved D0F_RETRY7" though Retry-8 spent them — an **R-twin retirement
  amendment** owed, verified non-blocking (2042/2043 do not collide with `2028000000/101:148`).

## 3. Pre-seed GREEN-GATE (all pass BEFORE the draw; ALL zero-seed)

Every PRE-item below is executable with **no official RNG consumed**. Smoke is deliberately NOT here (§8).

- **PRE-1 — fresh-D0F checkpoint GREEN:** §1 full re-derivation preflight passes on the deployed R head; a
  dry `v3r_validate_final(retry8-prep/d0f,'d0f')` re-emits receipt sha `04cc0740…` **byte-identical** and
  the whole D0F final tree validates; predecessor bound in the D1 preseal. *(Attainable only on the
  sanctioned schema-2 R head; impossible at the stale `d3835fe`.)*
- **PRE-2 — D1 driver preflight PASS (the real zero-seed pre-draw gate):** driver `preflight` mode
  (`stage_replay.jl:547-552`) validates sealed inputs, preseal key/order, predecessor, and seed-lock with
  **no official RNG consumed** and produces no summary output.
- **PRE-3 — seed-lock green:** `v07s_selftest` validates the `2028000000/101:148` D1 space + disjointness
  (DONE — PASS); the 2042/2043 retirement is reconciled or verified non-blocking.
- **PRE-4 — deployment head sanctioned (the B-1/B-2 gate):** on the LIVE Totoro checkout,
  `git -C <deployed-hsquared> rev-parse HEAD` = `a23b15b` (or descendant, schema-2, files present) and
  `git -C <deployed-HSquared.jl> rev-parse HEAD` = `976814`/`27d5047d` (contains `_validate_d0f_predecessor`);
  the deployment directory is renamed/rebuilt to `code-<sanctioned-Rhead>-<sanctioned-Juliahead>`; both
  trees git-clean; driver/recomputer sidecar shas match the sanctioned heads. **NOT `code-d3835fe-1a538212`.**
- **PRE-5 — route-repair + adjudicator-tail regression GREEN for D1:** the D1-parametrized mutation/route
  suite (`hsquared/tests/testthat/test-v07-genomic-recovery-v3-retry7-mutations.R`, `stage='d1'` cases)
  passes on the deployed R head. *(D1 has no bootstrap, so the D0F Julia bootstrap-variance triple-compare
  has no pre-draw D1 analog — stated explicitly, not silently omitted.)*
- **PRE-6 — toolchain/env freeze + env-verify `ok=TRUE`:** OrderedCollections `2.0.1` in both the global
  JuliaCall bridge env and `julia_root` (project), with a **clean precompile (no "different version
  currently loaded" warning)** in the exact worker path and a byte-identical serialized receipt/summary
  across two independent precompiles; `julia_root` git-clean at the sanctioned head; `TMPDIR` pinned to
  `/home/snakagaw/hsq_work/jltmp`, `OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=1`, `host=totoro`,
  ≤96 workers. Env verified by the exact `hs_julia_setup` path + negative control, not a proxy.

**The draw is forbidden until PRE-1…PRE-6 are green AND a shown-GREEN adversarial pre-draw panel + explicit
in-session user GO.** No PRE-item draws a seed.

## 4. Acceptance predicates (pre-declared; outcome-NEUTRAL)

A D1 receipt is **admissible/complete** iff ALL hold (schema
`v07-genomic-recovery-v3-adjudication-2`, D1 columns incl. the D1-carried `route_lineage_sha256`,
`adjudication_key_sha256`):

- `attempt_max_diff` AND `summary_max_diff` finite and ≤ `1e-10` (official R vs base-R vs Julia replay).
- Boundary component-ratio identity ≤ `1e-12` (`COMPONENT_RATIO_TOLERANCE`, `:25`, present at HEAD).
- Every `julia_profile_replay` row admitted under its OWN route (never rebound to `ordinary_auto_genomic`);
  weighted route-lineage conserved. *(Type-level guarantee `EvidenceRow{R<:EvidenceRoute}` present at the
  sanctioned head; absent at the stale `1a538212` — another reason to re-pin.)*
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
could reuse the D0F 2042/2043 space after a pre-draw blocker; and why the deployment defect found by the
audit costs no seed). A completed-but-unadjudicated corpus is diagnostic and moves no count.

## 8. Lane + point of no return (smoke is INSIDE this, behind the GO)

The R twin (`hsquared`) owns markers/phenotypes/official fits/base-R recompute/summarize-r/adjudication;
`HSquared.jl` replays + summarizes-julia + validate-final. **Executor: CLAUDE runs both lanes this session
under the user's express authorization** (sequential; no concurrent Codex). The **draw (official RNG over
`2028000000/101:148`) is the point of no return** under the root-forfeit rule and stays LAST, after the
green-gate and a shown-GREEN adversarial pre-draw panel + an explicit in-session user GO.

**Smoke draws official seeds — it is part of the draw, not a pre-draw gate.** `smoke-n-ladder`/`smoke-16`
pipe manifest rows into the same `run-one` RNG path as `run-official` (`set.seed(row$seed); rnorm(...)` on
real `2028000000/101:148` seeds). Therefore the FIRST irreversible official-seed command is
`smoke-n-ladder` (a handful of pilot seeds), and it sits **AFTER the GO**, immediately before
`run-official`. The zero-seed `preflight` (PRE-2) is the pre-draw gate; smoke is a scale/RAM probe on
already-authorized seeds.

Post-GO irreversible order: `smoke-n-ladder` (first draw) → `run-official` (all 576). Compute: Totoro,
`OPENBLAS_NUM_THREADS=1`, JULIA threads=1, `TMPDIR` pinned, ≤96 workers, every long stage detached with a
completion marker + log poll, resume via complete-prefix only, corpus immutable.

## R-twin certification evidence pack (required before re-authorizing S4)

The audit's answer to the earlier OPEN question: **`d3835fe`/`1a538212` are NOT the sanctioned D1 heads.**
Before S4 the R twin (and the live Totoro checkout) must show:
1. Deployed R head = `a23b15b` (or descendant): `git merge-base --is-ancestor a23b15b <head>` = YES;
   `recompute.R` schema `adjudication-2`; `admission.R` + `downstream_contract.R` present; sidecar sha matches.
2. Deployed Julia head = `976814`/`27d5047d`: contains `_validate_d0f_predecessor` (`:432-450`) +
   `D0F_ADJUDICATION_SCHEMA="…adjudication-2"` (`:40`); sidecar sha matches.
3. Dry `v3r_validate_final(retry8-prep/d0f,'d0f')` under the deployed R head re-emits sha `04cc0740…`
   byte-identical (impossible under `d3835fe`).
4. Live `git -C <checkout> rev-parse HEAD` printed for both trees, matching the sanctioned SHAs; deployment
   directory renamed to `code-<sanctioned-Rhead>-<sanctioned-Juliahead>`.
5. OrderedCollections: clean precompile (no version-mismatch warning) + byte-identical serialized
   receipt/summary across two independent precompiles.

## Pipeline phase order (driver-enforced — do not reorder)

`official → locked → base_r → summarize-r → replay-julia → julia_summary → lineage → review →
final (adjudicate → validate-final)`. `summarize-r` precedes `replay-julia` in the sequence; the driver
strictly enforces `summarize-r` before `summarize-julia` (`stage_replay.jl:1152-1155`).
