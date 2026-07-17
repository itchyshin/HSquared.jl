# Retry-7 D0F campaign arc — ultra-plan (planning only; execution NOT yet authorized)

**Date:** 2026-07-17 · **Author:** Claude (planning lane) · **Status:** PLAN. The admission
gate closed PASS; the phenotype draw + 576-fit campaign need their **own express authorization**
before any slice below executes. Nothing here has been run; no phenotype has been drawn.

Built from a read-only 8-agent research+design+critique workflow (failure-history, Julia-harness
contract, R↔Julia handoff/covered-bar, brain/scout sweep; risk-first + throughput-first design;
Rose + Gauss/Curie adversarial critique). Consensus verdict: **APPROVE-WITH-REQUIRED-CHANGES /
CONDITIONAL GO** — corrections folded in below.

---

## 🎯 GOAL (paste-to-set the execution session's goal — AFTER you authorize the campaign)

```
Execute the Retry-7 D0F campaign on ONE platform — CODEX (live R/TMB + Julia + Totoro toolchain);
Claude plans and read-only-verifies. DELIVERABLE: a sealed, byte-identical D0F adjudication receipt
(schema v07-genomic-recovery-v3-adjudication-2) that survives its own validate-final — WHATEVER its
verdict — plus a repo-visible close-out. HEADLINE: DE-RISK THE ADJUDICATION TAIL BEFORE SPENDING ONE
OFFICIAL SEED. Four of the last attempts computed all 576 fits correctly and died in the R
adjudicator/receipt writer; compute is trivial (~0.73 s/fit, ~30-60 min end-to-end). The tail is
R-side and MAC-TESTABLE (the execution-context wall is Julia-only): extend the existing hsquared
testthat receipt/validate-final fixtures to 576-cardinality MULTI-ROUTE (boundary_lower/upper/
interior/interior_rescued/unsuccessful rows) in an isolated scratch root, add a logical-FALSE-vs-
text-'false' boolean regression + a route-tag-conservation property test, and confirm route-repair
commit b8096e5 is in the bound R head — ALL green before the draw. Then ONE Totoro-bound synthetic
seam (Julia bootstrap-variance summarize on the real 720000-row index feeding the R triple-compare).
DISCIPLINE: pre-register the contract + acceptance predicates + "what PASS does NOT license" with a
commit hash BEFORE the RNG draw; the phenotype draw (seed base 2042000000) is the point of no return
under the ROOT-FORFEIT rule (any tail failure retires the whole root + both seed spaces, no salvage);
OPENBLAS/JULIA threads=1, ≤90-96 Totoro workers, resume via complete-prefix only, bootstrap immutable;
a COMPLETE D0F receipt only OPENS D1/D2 — it does NOT move public_covered_count off 5, activate the
ordinary R route, or discharge V2-GRM/V2-GINV. Rose gates the close. Bank the negative if the tail fails.
```

---

## Context

The programme wants the ordinary no-control R genomic route (`ordinary_auto_genomic`: markers → auto
VanRaden G → ridge Ginv → REML) moved to public-covered. That route is **held**;
`public_covered_count` = 5 (only the validation-scale *supplied-`Ginv`* estimator is covered, on two
banked legs — a 48-seed recovery gate + a blupf90+ comparator). The D0F 576-fit bootstrap-variance
campaign produces the *accepted recovery evidence* that would let D1/D2 open and, eventually, the
route activate. **Six prior retries failed; every death is in the post-fit adjudication tail, not the
science.**

**The central, evidence-backed insight (this is the whole plan):** compute is trivial and the fits
close cleanly. The *only* unsolved problem is the **R adjudicator / receipt writer**. Four of the most
expensive attempts computed everything correctly and died there:

| Attempt | Reached | Died on |
|---|---|---|
| recovery-v3 roots 1–3 | up to 576 fits + 576 base-R | replay admission *before row 1* (fixed-panel cardinality; concrete-`Cmd` typing; successful-gradient) — **all now guarded** |
| Retry-4 | 455/576 replay rows admitted | one-ULP endpoint-representation mis-classified as fit_error — **guarded** (component ratio split at 1e-12) |
| Retry-5 | 1 official fit | post-preseal pristine-tree predicate + non-contract-clean admission — **guarded**; Retry-7 re-proved L1–L5 + preflight |
| **offset-7101** | 432/432 fits agree | **tail:** receipt writer compared logical `FALSE` vs text `'false'` (serialization) + PRECISION_BLOCKER (cap 2,000; hit 16,325) |
| **Retry-6** | **ALL 576 fits + 576 base-R + 576 replays agree; 5 CLEAN verdicts** | **tail:** `v3r_expected_summary` silently rebound `julia_profile_replay` rows to `ordinary_auto_genomic` → receipt never minted |

So the failure locus has marched downstream into the receipt-minting seam, and the last two deaths
were *there* after perfect computation. **The receipt is the deliverable, not the fits** — a run that
completes all fits but dies in the tail buys nothing.

---

## Corrections the critics verified (folded into the plan)

1. **The tail is R-side and MAC-TESTABLE — not Totoro-bound.** `_assert_execution_context`
   (stage_replay.jl:392–397) walls only the *Julia* harness. The R adjudicator/receipt/validate-final
   path — the exact locus of every tail death — runs under R testthat on the Mac. An end-to-end
   synthetic adjudicate→receipt→validate-final test **already exists**
   (hsquared `tests/testthat/test-v07-genomic-recovery-v3-recompute.R:925-1111`). The headline
   de-risk is to *extend* those fixtures, off-Totoro — **not** an "only test / most-valuable Totoro
   spend" (that risk-first overclaim is struck).
2. **The route-repair IS in the bound head.** `b8096e5` ("Repair recovery summary route binding") is
   an ancestor of `9f7ed27`; it threads `expected_route` through `v3r_expected_summary` /
   `v3p_d0f_summary` / `v3p_d1_summary` and **aborts** on `route != expected_route` and wrong
   `driver_commit` (preseal.R:1704–1716), for **both D0F and D1**. So the residual risk is a *spurious
   loud abort*, not a silent wrong-route. (`562b93e` is "Retire Retry-6 seed spaces" — **not** the
   repair; do not conflate.)
3. **Only ONE genuinely Totoro-bound synthetic seam:** the Julia bootstrap-variance `summarize` on the
   real 720000-row `d0f_bootstrap_indices.tsv` feeding the R triple-compare. It gets its own slice.
4. **Strike the V2-GRM/V2-GINV discharge overclaim.** Base-R recompute reconstructs the estimator's
   *fits*, not G/Ginv construction; V2-GRM/V2-GINV stay `partial` (validation-debt-register.md:75-76).
5. **Outcome-neutral DoD.** A pre-registered gate must not bake in PASS. DoD = "an adjudicated receipt
   that re-derives byte-identical under validate-final, **whatever** the verdict." With 0 successful
   tails in 6 retries, a fail / PRECISION_BLOCKER is an admissible, must-be-bankable outcome.
6. **The S2 fixture MUST include boundary_lower/upper/interior/interior_rescued/unsuccessful rows** —
   the one-ULP endpoint check fires only on boundary rows; an all-interior fixture leaves the Retry-4
   class unexercised.

---

## Slices (merged: risk-first spine · throughput compute · critic corrections)

Owners are review **lenses**; live execution is **Codex** (R/Julia/Totoro). Claude plans + read-only
verifies. **All PRE-* slices must be green before any phenotype seed is drawn.**

| # | Slice | Lens | Venue | Detail |
|---|-------|------|-------|--------|
| **PRE-0** | Authorization + pre-registration gate | Rose | repo | Express user auth for phenotype draw; commit a NEW contract **before any RNG** with a predeclaration hash: isolated seed spaces (phenotype base 2042000000; bootstrap base 2043000000 sealed), the D0F acceptance predicates, an explicit **"what a PASS does NOT license"** clause, and **admissible boundary/non-convergence outcomes**. Outcome-neutral. |
| **PRE-1** | Confirm tail repair in bound R head | Hopper | repo (R twin) | Verify `b8096e5` ancestor of `9f7ed27`; `expected_route` threaded through D0F **and** D1 reconstruction; wrong-route/wrong-driver abort present (preseal.R:1704-1716). (Largely confirmed by research; formalize.) |
| **PRE-2 (HEADLINE)** | Extend R tail tests to 576-cardinality multi-route | Hopper + Fisher | **Mac** (R testthat) | Extend `test-v07-genomic-recovery-v3-recompute.R:925-1111` to a 576-row **multi-route** inventory (official + base_r + julia_profile_replay) incl. **boundary_lower/upper/interior/interior_rescued/unsuccessful** rows; drive route-lineage→5 reviews→R summary→(faked) Julia summary→adjudicate→receipt→validate-final in an **isolated scratch root**. Assert byte-identical create-once receipt survives its own validate-final; every julia row admitted as `julia_profile_replay`. Seedless. |
| **PRE-3** | Receipt-boundary regressions | Hopper (Julia) + Fisher (R) | Mac | (a) tag-conservation property test `count(summary, julia_profile_replay)==count(input,…)`; (b) **logical-FALSE-vs-text-'false'** boolean regression on the **R** receipt writer (owns the offset-7101 class); (c) wrong-route/wrong-driver rejection at full cardinality. Each RED-before / GREEN-after; sub-second, oracle-free. |
| **PRE-4** | One Totoro-bound synthetic seam | Gauss + Kirkpatrick | **Totoro** | Julia bootstrap-variance `summarize` on the **real** 720000-row `d0f_bootstrap_indices.tsv` (sha `f53967b5…`) feeding the R adjudicator triple-compare. The only genuinely Totoro-bound synthetic test. |
| **PRE-5** | Toolchain + env freeze | Grace | Totoro | juliaup 1.10.10 instantiated (done for `-c`), Rscript version + RNGkind pinned, `BLAS.get_num_threads()==1`, `host==totoro` clears the execution wall; re-PASS `--mode=preflight --stage=d0f`. Manifest.toml stays in the git-clean comparison even when absent. |
| **C1** | Phenotype draw + 576 official REML fits | Henderson + Mrode + Gauss | Totoro | R `v3d_run_one` per manifest row (3 designs × 24 panels × 8 phenotypes); phenotype base 2042000000; `ordinary_auto_genomic` **diagnostic precondition on the HELD route**. **Only official RNG draw — point of no return.** ≤90-96 workers. |
| **C2** | Corpus lock | Curie + Fisher | Totoro | `stage_corpus_lock.tsv`; run-one refuses afterward. |
| **C3 ∥ C4** | Base-R recompute (576) ∥ Julia exact replay (576) | Curie/Fisher/Mrode ∥ Gauss/Karpinski/Noether | Totoro | Parallel; share only the corpus lock. Replay via `replay-batch --resume-complete-prefix=true` (contiguous prefix only, never hand-delete into a gap); per-row official-vs-replay ≤1e-10; boundary component-ratio split ≤1e-12. |
| **C5** | Verify-replay (quiescent completeness) | Gauss + Grace | Totoro | Read-only; tree exactly complete, no summary/receipt yet, every row re-derived ≤1e-10. |
| **C6** | Route lineage + 5 postrun reviews | Hopper + Rose | Totoro | Weighted route conservation; tag-conservation invariant holds; 5 create-once review receipts. |
| **C7 → C8** | R authoritative summary → Julia bootstrap summary | Curie/Fisher → Gauss/Kirkpatrick | Totoro | **Strict order:** R summary first; Julia `summarize` requires base_r complete + summary_r present, accepts only the canonical bootstrap path, denominator 576, 10000 reps. |
| **C9 (TAIL)** | Sealed adjudication + receipt | Rose + Fisher | Totoro | R `v3r_adjudicate`: triple parity (attempt_max_diff & summary_max_diff finite ≤1e-10); julia rows admitted as `julia_profile_replay`; create-once byte-identical primary+sidecar; self-hashed `adjudication_key`; schema `v07-genomic-recovery-v3-adjudication-2` (31 cols). |
| **C10** | Final validation (byte-identity) | Rose + Grace | Totoro | `v3r_validate_final` re-derives byte-identical primary+sidecar; `v3r_verify_final_tree` exact membership; Julia `validate-final` correctly refuses ownership. |
| **Z-PASS** | Bank + honest close | Rose (mandatory) | repo | capability-status (D0F **adjudicated but diagnostic-precondition**), validation-debt-register row, check-log, after-task; explicit: `public_covered_count` stays **5**, D1/D2 not opened, route NOT activated, V2-GRM/V2-GINV still partial. Standalone Rose claim-vs-evidence audit. |
| **Z-FAIL** | Bank the negative (base-rate branch) | Rose | repo | On tail fail / PRECISION_BLOCKER: bank the negative in capability-status + validation-debt-register, retire the root **and both disjoint seed spaces**, record the exact defect for the next preregistered contract, make **no** activation/coverage/discharge claim. |

**Sequencing:** PRE-0…PRE-5 all green → C1 (the seed) → C2 → {C3 ∥ C4} → C5 → C6 → C7 → C8 → C9 → C10
→ Z. Fan-out only *within* C1/C3/C4; the phase boundaries are strictly sequential and fail-closed.

---

## Compute (throughput lens; corrected)

- **Target: Totoro, not DRAC** — single-node, tiny, latency-bound on sequential phase gates; DRAC's
  queue is pure overhead. The sealed env pins `host` (almost certainly `totoro`).
- **Sizing:** ~0.73 s/fit (from the retired offset-7101 pilot — an *estimate*, not banked throughput)
  → ~7 min serial per 576-leg; ≤90-96 workers → single-digit minutes; summarize + receipt are
  single-process seconds. **End-to-end ~30-60 min**, no re-runs. Peak RSS ~0.5-1.0 GB/fit (n=300,
  m=1000 eigendecomp) × 90 ≈ ~90 GB (~9% of Totoro RAM).
- **Mandatory pins:** `OPENBLAS_NUM_THREADS=1`, JULIA threads=1 (preflight re-checks). Parallelism is
  across processes/cells, never within a fit. Bootstrap is **immutable** (720000 rows, sha `f53967b5…`).

---

## Scope fences (load-bearing — Rose gates these)

- A **COMPLETE D0F receipt only OPENS D1/D2** (which have never opened). It does **not** move
  `public_covered_count` off 5, activate/merge/release the ordinary route, "cover" genomic REML beyond
  the supplied-`Ginv` estimator, or discharge V2-GRM/V2-GINV.
- The 576 fits are a **diagnostic precondition on the HELD route**, not route activation.
- The synthetic dry-run (PRE-2) mints a **synthetic** receipt in a **throwaway** root — never bound,
  hashed into, or cited as real D0F evidence.
- **What a PASS licenses (pre-declare in PRE-0):** a three-implementation reproducibility/parity
  verdict (official vs base_r vs julia ≤1e-10) + a bootstrap-variance characterization. It licenses
  **no** bias / calibration / coverage / recovery / activation claim (those are D1/D2, never opened;
  the estimator's recovery + comparator legs are already banked separately).
- **Carried-over DO-NOT-TOUCH:** `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` (untracked)
  and the two modified retry5 docs are protected carryover in both twins — never inspect, stage, edit,
  or hash them in this arc.

## Cross-twin ownership

The tail fixes/tests (PRE-1/2/3b) and the R driver/adjudicator (C1, C2, C3, C7, C9, C10) live in
**hsquared (R lane)** — Claude does not edit the R repo from here; those are Codex/R-session work. The
Julia harness is **replay-only and already zero-seed-validated — reuse, do not rewrite.** Every
compute slice is a Codex/Totoro hand-off; Claude's lane is read-only planning + evidence verification.

## What is NOT in this arc

D1 (recovery: bias/MCSE known-truth gate) and D2 (same-estimand REML comparator, e.g. blupf90+
AIREMLF90) are the legs that actually move the count 5→6 — they open **only after** a clean D0F
adjudication and each need their own preregistration. Not planned here.
