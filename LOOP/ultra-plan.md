# H² TWIN CAMPAIGN — ULTRA-PLAN FINAL G0 STOP ARTIFACT

**Written:** 2026-09-01 · **Author lens:** Ada (orchestrator) · **Surface:** Cursor · **Goal:** 41
**Status:** **FINAL G0 STOP — awaiting Shinichi's three decisions. No arc work has begun.**
**MC pointer:** http://127.0.0.1:8823/p/H2/
**Revision note:** this supersedes the prior draft at this same path. Integrated: the
20-arc draft, the 21-arc `/tmp/h2-twin-arc-plan-draft.md` ladder, the docs-site steal
list, the real-data validation scout, the parallel-dispatch/Kimi menu, the brain
"stand the world" quality brief, and the sister-CRAN pattern (grepped directly —
`/tmp/h2-sister-cran-scout.md` never materialized during this run; see §4).
**Routing correction applied (Shinichi, 2026-09-01):** Other Models bar does **not**
default to Opus. **New this revision:** parent-orchestration model is pinned (§7);
the CRAN `0.5.0` arc block is now explicitly separated from the longer `1.0` campaign
ladder (§5).

---

## 1. GOAL BLOCK

```
GOAL: Take the H² twin (hsquared R + HSquared.jl engine) from its current
      split state — R at v0.1.0.9000 with v0.1 covered and a 0.5.0 CRAN target,
      Julia at v0.0.1 with public_covered_count = 5 and the S5 gate frozen —
      to a coherent, honestly-claimed, comparator-anchored twin release pair.
      NEAR-TERM SCOPE: ship 0.5.0 CRAN-ready (both twins, one DOI, sister
      lifecycle discipline). LONGER SCOPE (separate, sequenced after): the
      0.6-through-1.0 maturity ladder (§5 Block 2).

END STATE (all four must be true and verified from repo state, not chat):
  E1. Every public claim on both bars matches a capability-status row backed by
      committed evidence; Rose records a clean audit or explicit blockers.
  E2. The R↔Julia bridge round-trips one real animal-model fit end-to-end, with
      a declared tolerance and a parity test in CI.
  E3. The comparator surface is 7 targets wide with BLUPF90 either wired or
      explicitly documented as unavailable-and-why (Jason's open gap).
  E4. hsquared 0.5.0 passes a CRAN-grade local gate carrying the sister lifecycle
      pattern (D-40/D-41/D-42: EXPERIMENTAL on all five channels, version 0.5.0
      not 1.0), the Julia engine registers to the General registry first (one
      twin DOI), and HSquared.jl's covered count moves only through the
      predeclared covered-flip gate.

NOT IN SCOPE (this G0's near-term block): D1 genomic (PAUSED, D-68/D-71) · TMB
      (deferred) · Phase 5+ QTL/GWAS · GPU/HPC (Phases 7-8) · any
      experimental→covered flip without predeclared evidence · the full 0.6-1.0
      ladder (tabled separately in §5 Block 2, not armed by this G0).

INVARIANTS:
  I1. No fitting/performance/genomics claim without the full evidence chain.
  I2. R owns public language; Julia owns engine reality. Never merge claim surfaces.
  I3. Never `git add -A`. Scope-stage by explicit path.
  I4. Foreign codex lanes (PR137 R, PR274 Julia) are NOT ours to touch.
  I5. A `partial` row must state what it does NOT cover.
  I6. Lab-package release honesty (D-41) is non-negotiable: EXPERIMENTAL until
      Shinichi personally declares maturity — CRAN-clean is not maturity.
```

---

## 2. PHASE 0.25 — SWEEP RECEIPT

Input artifacts confirmed present this run: `/tmp/h2-sweep-receipt.md`,
`/tmp/h2-twin-arc-plan-draft.md`, `/tmp/h2-docs-site-scout.md`,
`/tmp/h2-realdata-validation-scout.md`, `/tmp/h2-parallel-dispatch-playbook.md`,
`/tmp/h2-brain-quality-brief.md`. **Absent:** `/tmp/h2-sister-cran-scout.md` — did
not appear during this run; the sister-CRAN pattern below (§4) was grepped directly
against `~/shinichi-brain/memory/DECISIONS.md` and both sister repos as a substitute.

```
L1. BRAIN     grep -inE "H2|hsquared|goal 41" ~/shinichi-brain/memory/DECISIONS.md
              → 10 hits. Load-bearing: line 4877 "| H2 | — (suspended) | 17 d |
                correct because untouched |" and 4879 "only H2 is a true false
                positive". H2 was SUSPENDED and is exempt from the staleness
                warning. No decision authorises resuming it — this plan does.
L2. R REPO    hsquared @ codex/2026-07-13-v07-performance-localization, AHEAD 7,
              3 files dirty. Version 0.1.0.9000. 632 test_that across tests/testthat.
              23 files in R/. validation_status() lives in R/validation-status.R.
L3. JL REPO   HSquared.jl @ same codex/2026-07-13-v07-performance-localization,
              in sync 0/0, 1 modified + 2 untracked. capability-status.md has 97
              table rows. ROADMAP spans Phase -1 … Phase 8. main exists and is
              NOT the current checkout. ROADMAP's own Release Model section
              (read this run) already states the sister pattern: 0.5.0 first,
              Julia registers to General first, then R to CRAN, one DOI.
L4. LANES     ~/local-scratch/lanes/*h2-twin* → NO MATCHES. Neither worktree
              exists. Branch claude/lane-h2-twin-20260901 is unborn.
L5. SISTERS   gllvmTMB and drmTMB are both now at Version 0.7.0 (post-first-release,
              still `lifecycle-experimental` badge live in both READMEs) — proof
              the D-41 label survives past the first CRAN ship, not just at it.
```

**VERDICT: AMBER — proceed to G0, do not proceed to arcs.**

Two facts change the plan shape and are the reason this is a STOP and not a start:

1. **Both repos are parked on a foreign codex branch.** The v07 performance-localization
   branch is the same branch that carries the foreign PR137 (R) / PR274 (Julia) work.
   The R side is **7 commits ahead of its own remote, unpushed**. Whether those 7 commits
   are ours, Szymek's, or Codex's is **not established**, and no worktree should be cut
   from that branch until it is. → fog ticket **F1**.
2. **The worktrees named in the brief do not exist.** Nothing has been claimed. This is
   good — it means the campaign can still choose its base — but it means Arc A01 is real
   work, not a formality.

---

## 3. PHASE 0.6 — ROUTE CHECK + FOG TICKETS

**Route check (wayfinder):** the brief routes this campaign as *one ultra-plan + one
`/goal` + a LOOP in the Julia worktree, post-G0*. That routing is **sound but
over-subscribed at the start**: the LOOP has nothing safe to iterate on until the
branch-base question (F1) is answered, because a LOOP pointed at a foreign branch will
happily accumulate commits on someone else's lane. **Recommendation: arm the ultra-plan
and `/goal` at G0; arm the LOOP only after A01+A02 land, and scope it to the
`HSquared.jl` worktree** — that repo carries the compute-bearing arcs (S5, comparator
harness, registry registration) that most benefit from an unattended iteration loop,
while the R side's arcs (bridge, docs, CRAN gate) stay under direct batch dispatch.

| # | Fog ticket | Why it is fog | Resolved by | Blocking? |
|---|---|---|---|---|
| **F1** | What are the R repo's 7 unpushed commits, and is `main` or `v07` the correct base for `claude/lane-h2-twin-20260901`? | Both repos sit on a foreign codex branch; cutting a worktree from it entangles our lane with PR137/PR274. | A01 + A02 | **YES — blocks all arcs** |
| **F2** | Which 5 rows constitute `public_covered_count = 5`? | The number is asserted in the phase snapshot; the enumeration is not in hand. A count is a claim. | A04 | Blocks B2+ |
| **F3** | Does `validation_status()` in R agree row-for-row with Julia's capability-status? | Two claim surfaces, one truth. Drift here is exactly what I2 forbids. | A05 | Blocks B4 |
| **F4** | Is the frozen S5 gate's `CAP-EXHAUSTED ≤ 4/48` threshold defensible? | Snapshot records "no in-repo precedent; owner-revisable before any run". | A08 + **Q2** | Blocks A07 |
| **F5** | Is BLUPF90 obtainable on this hardware at all? | Jason flags it as a gap, not a failure. Unavailable-and-documented is an acceptable outcome. | A10 | Blocks E3 only |
| **F6** | Are the G10 S1/S2/S3 sign-offs delegable, or Shinichi-only? | Snapshot says delegation is resolved (NOT delegated) but the sign-off decisions are open. | **Q3** | Blocks B2 close |
| **F7** | Can Julia General-registry registration proceed independently of the frozen S5/G10 state, or does the twin-DOI sequencing require S5/G10 closed first? | ROADMAP says "Julia registers first, then R to CRAN, one DOI" but doesn't say relative to S5. | A19 | Blocks A19→A20 order |
| **F8** | Is it safe to flip the gryphon vignette from `eval=FALSE` to a live/executed chunk without CI Julia access (docs-scout finding)? | Docs-scout flags this as the one concrete "steal" that changes CI shape, not just prose. | A15 + A17 | Blocks A17's "live example" claim |

---

## 4. SISTER-CRAN PATTERN + COVERAGE SPINE (integrated this revision)

**Sister-CRAN pattern (grepped directly against `~/shinichi-brain/memory/DECISIONS.md`
and the two sister repos, since the scout file never appeared):**

- **D-40** (2026-07-10, accepted): drmTMB's first CRAN release is **`0.5.0`, not `1.0`**.
- **D-42** (2026-07-11, accepted): gllvmTMB's first CRAN release is **`0.5.0`, not `1.0`**,
  mirroring D-40.
- **D-41** (2026-07-10, accepted): every actively-developed lab package — **explicitly
  including `HSquared.jl`/`hsquared`** — carries an OBVIOUS, PROMINENT EXPERIMENTAL
  warning on first CRAN/pkgdown/Documenter, across **all five channels**: pkgdown/
  Documenter home-page callout, README badge/callout, `lifecycle` **experimental** badge
  on exported functions, a package startup message (`.onAttach`), and a line in the CRAN
  `Description`. Lifted **only** by Shinichi's explicit per-package maturity declaration —
  never autonomously. **CRAN-clean and a version tag are not maturity** — verified live
  this run: gllvmTMB and drmTMB are both now `Version: 0.7.0` and **still** carry the
  `lifecycle-experimental` badge in their READMEs, two minor releases past their first
  CRAN ship.
- `hsquared/ROADMAP.md`'s own Release Model section (already in-repo, confirmed this run)
  already commits to this: `0.5.0` ships on the current covered surface, the R+Julia twin
  registers as **one data-publication (one DOI)**, and **the Julia engine registers to
  the General registry first, then the R package to CRAN**. That registry step has **no
  arc in the prior 20-arc draft** — added as **A19** this revision.

**Coverage spine (from `/tmp/h2-twin-arc-plan-draft.md`, the 21-arc predecessor draft;
the near-term block below is the first rung, everything past it is Block 2):**

```
0.5 registration  →  0.6 multivariate  →  0.7 genomic GREML  →  0.8 FA + single-step
   (THIS G0's        (Arc A24, §5 Block2)  (Arc A25, §5 Block2)  (Arc A26, §5 Block2, part)
    scope: A01-A23)

                →  0.9 interval calibration + non-Gaussian approach  →  1.0 maturity
                       (Arc A26, §5 Block2, part)                        (Arc A26, close)
```

Route is evidence-gated, not phase-speed-gated (per the 21-arc draft's own route check):
each rung is armed only when its predecessor's promotion packet clears Rose + the
covered-flip gate. **This G0 arms the 0.5 rung only.** Block 2 (§5) is a pointer with
rolled-up hour bands, not a per-sub-arc breakdown — full breakdown for those rungs
already exists in `/tmp/h2-twin-arc-plan-draft.md` arcs 3-21 and should be re-read
in full before any Block-2 arc is armed for real dispatch.

**GLLVM/DRM excellence patterns folded into the near-term block (not deferred to
Block 2), because they are cheap relative to their honesty payoff:**

- pkgdown/Documenter navbar-by-job, not a flat article dump (A17).
- Status pages generated from `validation_status()` / `capability-status.md`, not
  hand-written prose that can drift from the ledger (A17, A18).
- CI split build/deploy, hidden internal pages, strict cross-reference/doctest
  (drop `warnonly = true`), Julia main-push Documenter deploy to match R's
  every-push pkgdown deploy (A18).
- "Many models via Julia where applicable" is the sister precedent for
  `engine="julia"` covering more of the model surface over time than the R-native
  path alone — this is the destination A14-A16 (bridge) and the whole Block-2 ladder
  point toward, not a new near-term arc.

---

## 5. ARC TABLE — 26 ARCS ACROSS TWO BLOCKS

**Compute legend:** `local` · `Totoro ≤30m` (no gate) · `Totoro >30m GATE` (ask first) ·
`DRAC GATE` (replicated/multi-seed, ask first) · `none` (pure judgment/doc work).
**Bar legend:** `CM` = Cursor Models · `OM` = Other Models.

### BLOCK 1 — 0.5.0 CRAN-READY ARC BLOCK (A01-A23, the scope this G0 actually arms)

| Arc# | Tag | Name | Hours | Compute | Dep | Bar | Model + effort | Lens |
|---|---|---|---|---|---|---|---|---|
| A01 | BOTH | Lane extraction: cut both worktrees from the *correct* base; branch `claude/lane-h2-twin-20260901` | 6 | local | — | **CM** | Grok 4.6 high-fast | Shannon, Ada |
| A02 | BOTH | v07 fog resolution: classify the 7 unpushed R commits; decide main-vs-v07 base; record | 5 | local | A01 | **CM** | composer-2.5-fast | Shannon, Rose |
| A03 | RESEARCH | Claim-surface sweep: capability-status ↔ README ↔ pkgdown ↔ Documenter home ↔ `validation_status()` ↔ ROADMAP | 9 | none | A02 | **OM** | gpt-5.6-terra-medium | Rose, Pat |
| A04 | JL | Enumerate and prove the 5 covered rows behind `public_covered_count = 5` (F2) | 10 | local | A03 | **OM** | Sonnet 5 thinking-high | Fisher, Rose |
| A05 | R | R `validation_status()` ↔ Julia capability-status parity table; drift list (F3) | 9 | local | A03 | **OM** | Sonnet 5 thinking-high | Hopper, Rose |
| A06 | BOTH | Test/runtime baseline: 632 `test_that` + `Pkg.test()` wall-clock, flake census, seed audit | 7 | local | A01 | **CM** | Grok 4.6 high-fast | Curie, Grace |
| A07 | JL | Run the FROZEN S5 tail-scale REML known-truth recovery gate at q=25,000 | 14 | **Totoro >30m GATE** | A04, A08 | **OM** | Sonnet 5 thinking-high | Gauss, Fisher |
| A08 | JL | Set the `CAP-EXHAUSTED ≤ 4/48` threshold with in-repo precedent + rationale (F4) | 8 | Totoro ≤30m | A04 | **OM** | Sonnet 5 thinking-high | Fisher, Gauss |
| A09 | JL | Prepare G10 S1/S2/S3 sign-off dossiers — evidence assembled, decision left to Shinichi | 10 | none | A07 | **OM** | Sonnet 5 thinking-high | Ada, Rose |
| A10 | RESEARCH | BLUPF90 gap: wire it, or document unavailable-and-why with provenance (F5) | 16 | local | A06 | **OM** | gpt-5.6-terra-medium | Jason, Mrode |
| A11 | JL | Comparator harness: one runner across all 7 targets, seeds pinned, outputs versioned | 18 | Totoro ≤30m | A10 | **OM** | Sonnet 5 thinking-high | Curie, Mrode |
| A12 | R | Freeze sommer/ASReml R-side comparator fixtures (Jason reports these already wired) | 12 | local | A11 | **OM** | Sonnet 5 thinking-high | Curie, Jason |
| **A13** | **BOTH** | **NEW — Real-data validation tier: manifest-backed 3-tier ladder (unit fixture / Mrode-gryphon published-anchor / optional large comparator) with a claim-boundary statement per tier; add the symmetric R fixture/comparator index to match Julia's `comparator_targets.toml`** | **16** | local | A11, A12 | **OM** | Sonnet 5 thinking-high | Curie, Mrode, Darwin |
| A14 | BOTH | Bridge payload contract v2: schema, argument names, round-trip fixtures both directions | 20 | local | A05, A12 | **OM** | Sonnet 5 thinking-high | Hopper, Boole, Emmy |
| A15 | R | `engine = "julia"` end-to-end smoke on one Mrode/gryphon example; resolve F8 (live chunk vs. no-Julia fixture) | 18 | local | A13, A14 | **OM** | Sonnet 5 thinking-high | Hopper, Lovelace |
| A16 | BOTH | Bridge parity test: R fit vs Julia fit, same estimand, declared tolerance, into CI | 14 | Totoro ≤30m | A15 | **OM** | Sonnet 5 thinking-high | Fisher, Hopper |
| **A17** | **BOTH** | **NEW — Docs IA rebuild both sites: navbar-by-job (Get started / Model guides / Status / Comparators & validation / Roadmap); promote current-limits + model-status pages to slot 2; Julia sidebar mirrors R navbar; steal drmTMB/gllvmTMB function-map + limitations pages** | **16** | none | A16 | **OM** | gpt-5.6-terra-medium | Pat, Darwin, Florence |
| **A18** | **BOTH** | **NEW — CI/deploy hygiene: split pkgdown build/deploy + hide internal pages (gllvmTMB pattern); Julia Documenter main-push deploy (currently tag/PR-only); drop `warnonly=true`, fail on broken doctests/cross-refs; generate both status pages from `validation_status()`/`capability-status.md`, not hand prose** | **14** | local | A17 | **OM** | Sonnet 5 thinking-high | Grace, Karpinski |
| **A19** | **JL** | **NEW — Julia engine registration to the General registry (twin-DOI prerequisite; resolve F7 sequencing against S5/G10)** | **10** | none | A09 | **OM** | Sonnet 5 thinking-high | Grace, Hopper |
| A20 | R | hsquared 0.5.0 CRAN gate: `--as-cran`, extrachecks, all-five D-41 channels (pkgdown callout, README badge, `lifecycle` badge on exports, startup message, DESCRIPTION line), URLs, spelling, examples, NEWS | 18 | local | A18, A19 | **OM** | gpt-5.6-terra-medium | Grace, Emmy |
| **A21** | **BOTH** | **Estimand + public-claim closing panel (merges former A17+A18): `h2_T`/`m2`/`r_am`/`R` identities + covered-flip gate re-read, AND the DESCRIPTION/README/vignette/pkgdown/Documenter claim scrub against A03's sweep** | **14** | none | A16, A20 | **OM** | **Opus 5 (CEILING)** | Fisher, Noether, Falconer, Kirkpatrick, Rose, Pat, Darwin |
| A22 | BOTH | unlazy 1.0 `--reverify` counts + Melissa plan-vs-actual reconcile for the 0.5.0 block | 10 | local | A21 | **CM**+OM | Grok 4.6 (counts) → Terra (reconcile) | Melissa, Rose |
| A23 | BOTH | D-43 completion panel for the 0.5.0 block: after-task, check-log, coordination board, issues | 9 | none | A22 | **OM** | **Opus 5 (CEILING, 1×)** | Ada, Rose, Melissa |

**Block 1 core sum: 283 h** (A01-A23).

### BLOCK 2 — 1.0 CAMPAIGN LADDER (A24-A26, separate, longer, sequenced AFTER 0.5.0 ships)

Rolled-up per rung of the coverage spine (§4). **Not armed by this G0.** Full per-sub-arc
breakdown for each rung already exists in `/tmp/h2-twin-arc-plan-draft.md` (its arcs
3-21) and must be re-read before any of these is dispatched for real. Listed here only
so the campaign's true shape — and the fact that it is *separate* from the CRAN block —
is visible at G0, per the brief's explicit ask.

| Arc# | Tag | Name | Hours | Compute | Dep | Bar | Model + effort | Lens |
|---|---|---|---|---|---|---|---|---|
| A24 | BOTH | 0.6 rung: MV-5 t=3 broadened multivariate recovery gate, R parity, derived-estimand identities, promotion packet | 24 | Totoro; DRAC only if confirm tier opens | A21 | **OM** | Sonnet 5 thinking-high → **Opus at G10 touch** | Fisher, Darwin, Hopper, Mrode |
| A25 | BOTH | 0.7 rung: genomic GREML grammar/estimand freeze, comparator-environment probe, at-scale recovery, R activation, bridge parity, promotion packet | 46 | Totoro screen → DRAC confirm array | A24 | **OM** | Sonnet 5 thinking-high → **Opus at G10 touch** | Gauss, Fisher, Boole, Hopper |
| A26 | BOTH | 0.8→1.0 rungs: FA S1-S4 + single-step Ch.11 anchor promotion; H0/H1/H3 interval-coverage harnesses + DRAC coverage campaigns per promoted pillar; non-Gaussian family widening (ordinal → Gamma/lognormal → zero-inflated); NG-10 production sparse kernel; API freeze + Shinichi's maturity declaration | 192 | Totoro prototype → DRAC arrays | A25 | **OM** | Sonnet 5 thinking-high build → **Opus ceiling at every G10** | Gauss, Karpinski, Kirkpatrick, Fisher, Curie, Pat, Rose |

**Block 2 rolled-up sum: 262 h** (A24-A26) — a lower bound; the 21-arc draft's own
per-arc sum for the equivalent rungs runs higher once review overhead is added per rung
rather than once at the end.

### Hour totals

| Band | Hours |
|---|---|
| **Block 1 — 0.5.0 CRAN arc block (A01-A23)** | **283 h** |
| Block 1 review barriers + Rose audits (≈12% overhead) | +34 h |
| Block 1 contingency: F1 base-change rework, S5 gate re-runs, CRAN round 2, registry rejection rework | +45-70 h |
| **Block 1 envelope — the near-term, actually-armed scope** | **≈ 360-390 h** |
| Block 2 — 1.0 campaign ladder (A24-A26, rolled-up, NOT armed) | 262 h (lower bound) |
| **Full campaign (Block 1 + Block 2), for visibility only** | **≈ 640-720 h+** |

By bar (Block 1 only, the armed scope): **CM = 23 h** (A01 6, A02 5, A06 7, A22a 5) ·
**OM = 260 h**, of which **the Opus ceiling is 23 h — under 9% of the Other bar**
(A21 14 + A23 9). The remaining ≈237 h of Other-bar work runs on Sonnet 5 / Terra,
with Kimi/Gemini/Luna cheap-tier reads embedded inside those arcs at no separate
top-line cost (§7). That is the shape Shinichi's correction asked for, held through
this revision's three new near-term arcs.

Phased over calendar weeks at a sustainable pace: **B0-B1 week 1 · B2-B3 weeks 2-3 ·
B4 week 4 · B5-B6 week 5 · B7 week 6 · B8-B9 week 7.** Roughly a **7-week campaign**
to 0.5.0 CRAN-ready. Block 2 is not scheduled — it starts only after 0.5.0 ships and
Shinichi decides to resume the ladder.

---

## 6. AGENT FAN-OUT PLAN — BATCHES B0-B9 (Block 1 only)

**Hard budget: 6 children per checkpoint.** Every batch ends at a review barrier;
no batch starts until the prior barrier is cleared and Rose has spoken.

### B0 — Unblock (3 children · 20 h · **blocks everything**)

| Child | Arc | Bar | Model | Charge |
|---|---|---|---|---|
| c1 | A01 | CM | Grok 4.6 high-fast | Cut worktrees; report exact base SHA and branch topology |
| c2 | A02 | CM | composer-2.5-fast | Classify the 7 unpushed R commits by author/lane; recommend base |
| c3 | A03 | OM | gpt-5.6-terra-medium | Claim-surface sweep (now includes pkgdown/Documenter home pages); produce the drift list |

> **Barrier B0:** Shannon confirms no foreign-lane entanglement; Rose signs the drift list.
> **If c2 finds the 7 commits are Codex's → STOP and return to Shinichi.** That is F1 firing.

### B1 — Truth baseline (3 children · 26 h · parallel)

| Child | Arc | Bar | Model | Charge |
|---|---|---|---|---|
| c1 | A04 | OM | Sonnet 5 thinking-high | Name the 5 covered rows; attach evidence to each |
| c2 | A05 | OM | Sonnet 5 thinking-high | Build the R↔Julia parity table; list every drift |
| c3 | A06 | CM | Grok 4.6 high-fast | Time both suites; census flaky/seeded tests |

> **Barrier B1:** Fisher + Rose. A count is a claim — if the 5 cannot be enumerated with
> evidence, `public_covered_count` is wrong and that is a finding, not a failure.

### B2 — G10 / S5 unblock (3 children · 32 h · **sequential, compute-gated**)

| Child | Arc | Bar | Model | Charge |
|---|---|---|---|---|
| c1 | A08 | OM | Sonnet 5 thinking-high | Justify the ≤4/48 threshold; **needs Q2 answered** |
| c2 | A07 | OM | Sonnet 5 thinking-high | Run S5 at q=25,000 — **Totoro >30m, needs Q1 answered** |
| c3 | A09 | OM | Sonnet 5 thinking-high | Assemble S1/S2/S3 dossiers; do NOT sign them |

> **Barrier B2:** Gauss + Fisher on numerics; Ada on whether sign-off can proceed (Q3).
> Measured precedent: q=25,000 converged in 59 iterations, 54.26 s single-core — so this
> is minutes at 48-way, not a DRAC job.

### B3 — Comparators + real-data (4 children · 62 h)

| Child | Arc | Bar | Model | Charge |
|---|---|---|---|---|
| c1 | A10 | OM | gpt-5.6-terra-medium | BLUPF90: wire or document-as-unavailable |
| c2 | A11 | OM | Sonnet 5 thinking-high | Single runner over 7 targets, seeds pinned |
| c3 | A12 | OM | Sonnet 5 thinking-high | Freeze sommer/ASReml R fixtures |
| c4 | **A13** | OM | Sonnet 5 thinking-high | **NEW:** build the 3-tier real-data manifest; write the symmetric R comparator/fixture index |

> **Barrier B3:** Curie + Mrode + Jason + Darwin (biology sign-off on the gryphon tier).
> Fixtures frozen means byte-stable, not "re-runs OK". Real-data claim boundary per tier
> must be explicit — no tier may silently claim more than unit/published/large-comparator.

### B4 — Bridge (3 children · 52 h · **the campaign's spine**)

| Child | Arc | Bar | Model | Charge |
|---|---|---|---|---|
| c1 | A14 | OM | Sonnet 5 thinking-high | Payload schema + round-trip fixtures |
| c2 | A15 | OM | Sonnet 5 thinking-high | `engine="julia"` on one Mrode/gryphon example; resolve F8 |
| c3 | A16 | OM | Sonnet 5 thinking-high | Parity test with declared tolerance into CI |

> **Barrier B4:** Hopper + Boole + Emmy on contract; Fisher on tolerance. Both twins update
> together or neither does (Development Rule 2).

### B5 — Docs excellence (2 children · 30 h · **NEW batch**)

| Child | Arc | Bar | Model | Charge |
|---|---|---|---|---|
| c1 | **A17** | OM | gpt-5.6-terra-medium | Rebuild both navbars by job; promote limits/status pages |
| c2 | **A18** | OM | Sonnet 5 thinking-high | CI split-deploy + hide-internals + strict cross-ref + generated status tables |

> **Barrier B5:** Grace + Karpinski on CI shape; Pat + Darwin + Florence on reader IA.
> This barrier is new and deliberately sits **before** the CRAN gate — a CRAN release
> with a stale or flat docs site is a worse first impression than a slightly later one.

### B6 — Registration + CRAN gate (2 children · 28 h · **NEW batch**)

| Child | Arc | Bar | Model | Charge |
|---|---|---|---|---|
| c1 | **A19** | OM | Sonnet 5 thinking-high | Julia General-registry registration; resolve F7 sequencing |
| c2 | A20 | OM | gpt-5.6-terra-medium | Full CRAN-grade local gate + all five D-41 experimental channels |

> **Barrier B6:** Grace on release hygiene for both registries; Rose **mandatory**
> (public claim / pre-publish). **Julia registers first — c1 gates c2's version claim.**

### B7 — Estimand + claim ceiling (1 child · 14 h · **the one deep call**)

| Child | Arc | Bar | Model | Charge |
|---|---|---|---|---|
| c1 | A21 | OM | **Opus 5 thinking-high — CEILING** | Estimand identities + covered-flip gate re-read + full claim-surface scrub |

> This is the arc that earns Opus: a genuine estimand/architecture dispute plus the
> final pre-CRAN claim audit, where being wrong is expensive and the reasoning is not
> mechanical.

### B8 — Reconcile (2 children · 10 h)

| Child | Arc | Bar | Model | Charge |
|---|---|---|---|---|
| c1 | A22a | CM | Grok 4.6 high-fast | `unlazy --reverify`; report raw counts only |
| c2 | A22b | OM | gpt-5.6-terra-medium | Melissa plan-vs-actual; tag adaptive/drift/unclear |

> **Barrier B8:** Melissa hands drift + unclear to Rose. Counting is cheap-bar work;
> judging what a deviation *means* is not.

### B9 — Close (1 child · 9 h)

| Child | Arc | Bar | Model | Charge |
|---|---|---|---|---|
| c1 | A23 | OM | **Opus 5 thinking-high — CEILING, 1× per milestone** | D-43 completion panel + all durable records for the 0.5.0 block |

**Cheap scouts, on call in any batch (never a separate top-line hour or a separate bar):**
`gpt-5.6-luna-medium` for read-only grep/inventory sweeps and mechanical verify passes
that need to run on the Other bar; `kimi-k3-max` for wide reads, fixture inventories,
docs-scaffolding drafts, and bilingual grep sweeps (Other bar, budget-Sonnet tier — draft
only, never load-bearing); `gemini-3.7-flash-high` and `composer-2.5-fast` for the same
class of work on the Cursor bar. None of the four ever write code, sign a gate, make a
public claim, or touch a covered-flip/G10 decision.

---

## 7. ROUTING RECEIPT

### Parent-orchestration model (NEW — separate from arc-child routing below)

```
THIS ORCHESTRATOR (Ada, running this ultra-plan / dispatching batches B0-B9) defaults
to COMPOSER (composer-2.5-fast) for routine coordination: reading batch results,
updating the arc table, writing barrier notes, sequencing the next batch.

Escalate the PARENT layer itself to claude-fable-5-thinking-high ONLY when a genuine
multi-arc INTEGRATION DISPUTE arises — e.g. A05's parity table and A14's bridge
contract disagree about a field name, or A13's real-data claim boundary conflicts
with A21's estimand panel. Fable is a synthesis/dispute-resolution escalation for
the orchestrator layer, not a default, and not the same slot as the per-arc Opus
ceiling below (which is a child-arc routing decision, not a parent one).

Shinichi's framing: "use Fable if necessary" — necessary means a dispute the
orchestrator cannot resolve by reading the artifacts once more, not routine batch
management.
```

### Two-bar discipline for arc children (revised per Shinichi, 2026-09-01; Kimi/Gemini/Luna added this revision)

```
CURSOR MODELS (cheap bar) — DEFAULT: Grok 4.6 high-fast; composer-2.5-fast for the
  smallest reads; gemini-3.7-flash-high for fast cheap-tier scout fan-out (lead only,
  never evidence). Scope: recon, grep, git state, worktree mechanics, mechanical
  gate-checks, status reads, `unlazy --reverify` counts, test-timing baselines.
  Arcs: A01, A02, A06, A22a. 23 h.

OTHER MODELS (judgment/build bar) — DEFAULT: Sonnet 5 thinking-high, or
  gpt-5.6-terra-medium for doc-and-tooling-heavy arcs. Scope: arc implementation,
  bounded reviews (Rose/Fisher/Gauss reading a plan), Melissa reconcile, bridge and
  fixture work, docs IA rebuild, CRAN gating, registry registration. Arcs: A03-A05,
  A07-A20, A22b. ≈237 h.
  Read-only verify slices that must run on this bar go to gpt-5.6-luna-medium.
  Wide-read/inventory/draft-only slices (fixture inventories, docs scaffolding
  drafts, bilingual comparator-literature sweeps for A10/A13/A17) go to
  `kimi-k3-max` — always a draft a named lens reviews before it reaches a commit,
  a claim, or a gate; Kimi never competes with the Cursor Models pacing bar.

OPUS 5 — CEILING ONLY, never a default. Exactly two Block-1 arcs: A21 (estimand +
  claim-scrub dispute) and A23 (D-43 completion panel, 1× per milestone). 23 h,
  under 9% of the Other bar. Block 2 (§5) reserves further Opus touches at each
  rung's G10 sign-off only — never on grep, git state, docs drafting, or routine
  build across either block.
```

**The rule, stated once:** shift the *kind* of work between bars, not the volume.
Recon, counting, and wide reads are cheap-bar work whichever bar they land on. Opus
is for disputes and maturity-adjacent sign-offs, not for throughput. Fable is for the
parent layer's disputes only, not a default anywhere.

### Scout suitability

| Task class | Suitable for a cheap scout? | Why |
|---|---|---|
| git/branch/worktree state | **Yes** | Deterministic, verifiable, no judgment |
| grep/inventory sweeps (A03 raw pass) | **Yes** | Mechanical; judgment applied afterwards |
| test-timing and flake census | **Yes** | Measurement, not interpretation |
| `unlazy --reverify` counts | **Yes** | Counting only; meaning is Melissa's |
| Fixture/comparator inventories (A10, A13) | **Yes, Kimi** | Wide read + structured digest; a lens still judges |
| Docs-scaffolding first drafts (A17) | **Yes, Kimi** | Draft only; Pat/Darwin/Florence finalize |
| Enumerating the 5 covered rows | **No** | Requires judging whether evidence *counts* |
| Any covered-flip decision | **No — and not any subagent's call** | Gate is owner-authorised |
| Tolerance selection (A15) | **No** | Fisher's estimand judgment |
| Threshold ≤4/48 (A08) | **No** | Owner-revisable; Q2 |
| Julia registry registration decision (A19) | **No** | Public/release-adjacent; ASK per §9 |

### Estimate & handoff points

**Block 1: ≈360-390 h ≈ 7 calendar weeks** at a sustainable pace. Block 2: 262 h+
lower bound, not scheduled.

Handoff points where this campaign should leave Cursor:
- **After B0** — if F1 fires (the 7 commits are foreign), hand to Shinichi, not to another agent.
- **After B2** — G10 sign-offs are Shinichi's; the dossiers are the handoff artifact.
- **Before B6 registry push, and before any CRAN submission** — release-adjacent, always an ASK.
- **Before Block 2 is armed at all** — resuming the ladder past 0.5.0 is Shinichi's call.
- **B3/B4/B6 long runs** — hand compute to Totoro; keep orchestration here.

---

## 8. DOCS + REAL-DATA + SISTER-STEAL INTEGRATION (consolidates the four remaining scouts)

**From the brain quality brief's five "stand the world" gates** — these are the honest
target for *Block 2's* eventual 1.0 declaration, not a Block-1 requirement, but Block 1's
A13 and A17 are explicitly the down-payment on gates 1 (reader) and 4 (reality):

1. Reader gate — cold users install, find a model-choice path, run shipped examples,
   interpret output, cite H², one identical honest maturity box on both sites.
2. Scientific gate — every public pillar passes preregistered recovery + nominal interval
   coverage over its design ladder (Block 2 territory; interval coverage exists for no
   model today per the brief).
3. Comparator gate — independent same-estimand comparator or documented no-comparator
   exception per component; identity tests + locked citations for derived quantities.
4. Reality gate — at least one provenance-preserving real dataset per flagship family
   reproduces a documented analysis, with quality diagnostics and no truth-claim from the
   case study alone (**A13 starts this; full family coverage is Block 2**).
5. Release gate — element-wise R/Julia parity, strict-failing docs builds, full local
   checks, CI, after-task evidence, ledgers, Rose audit, only then maturity declaration.

**From the docs-site scout** — concrete, already-in-repo steal targets folded into A17/A18:
gllvmTMB/drmTMB's job-shaped navbar with `desc:` on experimental routes; drmTMB's
"Can I fit and report this?" opening question + function-map-cheatsheet pattern;
DRM.jl/GLLVM.jl's DocumenterVitepress mirror-the-R-navbar + Rosetta/parity pages;
gllvmTMB's split pkgdown build/deploy + hidden internals; the fact that
`HSquared.jl`'s Documenter currently has **no `push: branches: [main]`** trigger
(updates only on tag/PR/dispatch) while R's pkgdown deploys on every main push — an
asymmetry A18 closes. The gryphon vignette is the right dataset (Wilson 2010,
real, provenance-clean) but ships `eval=FALSE` on both `gryphon-worked-example.Rmd`
and `fitting-models.Rmd` because CI has no Julia — F8/A15 resolves whether to make
it live or add a no-Julia fixture instead.

**From the real-data validation scout** — the 3-tier ladder A13 implements: (1) tiny
deterministic/malformed unit fixtures (test-of-test negatives, byte-aligned R/Julia);
(2) published anchors (Mrode Ex. 3.1/3.2/5.1 supplied-variance BLUP/MME, gryphon
estimated-VC recovery) with provenance, estimator type, tolerance, and an explicit
claim boundary — **supplied-variance is not estimated-VC validation, and the ladder
must say so at each tier, not just once in the vignette**; (3) optional large
comparator packets (sommer + one independent lineage) as opt-in, version-pinned,
hash-recorded jobs, explicitly held separate from a future genuinely-empirical
fourth dataset (not a relabelled gryphon or generated CSV).

**From the parallel-dispatch playbook** — the Kimi/Gemini/Luna cheap-tier menu is now
folded into §6/§7 above rather than kept as a separate file; its non-negotiables
(public claims / estimand decisions / Rose gates / G10 sign-offs / D-43 panel never
delegate below Sonnet/Opus) are restated in the pre-authorization table (§9) and the
scout-suitability table (§7) so they are enforced at the same place decisions get made.

---

## 9. UNLAZY GATE SKETCH — `.unlazy/h2-twin-0.5.0/` (armed post-G0, Block 1 scope)

| Group | CHECK | EXPECT |
|---|---|---|
| **G1 Lane hygiene** | Worktrees exist at the named paths; branch is `claude/lane-h2-twin-20260901`; base SHA recorded; no file overlaps PR137/PR274 | 2 worktrees, 1 branch, 0 foreign-path collisions |
| **G2 Claim↔evidence** | Every `covered` row in Julia capability-status has a committed evidence artifact; every R public claim maps to a `validation_status()` row | 0 unbacked claims; 0 R-only claims |
| **G3 Covered count** | `public_covered_count` equals the number of enumerated-and-proven rows | Asserted count == proven count (currently asserted 5) |
| **G4 Comparators** | Comparator runner executes all 7 targets; BLUPF90 either runs or has a dated unavailability note with provenance | 7/7 accounted; 0 silent skips |
| **G5 Bridge parity** | Round-trip fixtures pass both directions; one Mrode example agrees R↔Julia within the declared tolerance; parity test is in CI | 0 schema drift; parity green on both matrix legs |
| **G6 Test suites** | R `devtools::test()` and Julia `Pkg.test()` both green locally; `test_that` count ≥ 632 and not silently reduced | 0 failures; count non-decreasing without a recorded reason |
| **G7 Real-data tier** *(NEW)* | 3-tier manifest exists in both repos; each tier states its claim boundary; gryphon tier has Darwin's biology sign-off | 3/3 tiers present; 0 tiers overclaiming |
| **G8 Docs excellence** *(NEW)* | Both navbars are job-shaped; both status pages are generated, not hand-prose; CI fails on broken doctest/cross-ref on both sites | 0 flat-dump navbars; 0 `warnonly` suppression |
| **G9 Twin registration** *(NEW)* | Julia engine registered to General **before** R's CRAN submission; one shared DOI recorded | Registration order matches ROADMAP's Release Model |
| **G10 CRAN gate** | `R CMD check --as-cran` + extrachecks on hsquared 0.5.0; all five D-41 channels present and prominent | 0 ERROR, 0 WARNING; every NOTE explained; 5/5 channels present |
| **G11 Records** | check-log entries with exact commands, after-task report, capability-status + validation-debt rows, coordination board, Rose audit | All Definition-of-Done items present; `tools/preamble_cap.sh` green |

---

## 10. TEAM RAISED

**Fisher (inference).** The `public_covered_count = 5` figure is an assertion carried in a
snapshot block, and the snapshot block is the one artifact in this repo that has
demonstrably drifted before. I want the five rows *named* before any of them anchors a
downstream claim (A04). Separately: the `CAP-EXHAUSTED ≤ 4/48` threshold has, by the
repo's own admission, **no in-repo precedent**. Choosing it after seeing the run would be
fitting the gate to the result. It must be fixed before A07 executes — hence Q2.

**Rose (systems audit).** Two claim surfaces exist and I cannot currently prove they
agree: R's `validation_status()` and Julia's `capability-status.md`. Until A05 produces the
parity table, **any public statement about what H² can do is unaudited**. This revision
adds a *third* surface I now also gate: the two docs sites (A17/A18) and the two READMEs'
D-41 experimental channels (A20) — five channels, on both packages, and CRAN-clean is
explicitly not maturity, proven this run by the fact that gllvmTMB and drmTMB still carry
the badge at 0.7.0. I am also flagging that the phase snapshot in `AGENTS.md` reached 31
entries / 66 KB once before; the pointer discipline holds now, but nothing in this
campaign should re-grow it. And I note plainly: this campaign resumes a lane the brain
records as **suspended**. That resumption is Shinichi's to authorise, not this plan's to
assume.

**Gauss (numerics).** S5 is frozen at `33ab68f6`: predeclaration and script committed,
**never run**. Freezing is the expensive part and it is done. The feasibility probe is
reassuring — q=25,000 converged in 59 iterations at 54.26 s single-core, so a 48-way run
is minutes, not hours. My concern is not cost, it is that the CI RNG-fragility class fixed
on 2026-08-04 (Julia's `randn` stream is not version-stable across 1.10/1.12) must not
reappear in the comparator harness A11 or the new real-data tier A13. Pin seeds *and*
pin how datasets are generated, in both places.

**Curie / Mrode / Darwin (new to this revision, real-data tier).** A13's ladder is only
honest if the claim boundary travels with the evidence at every tier — a supplied-variance
Mrode anchor and an estimated-VC gryphon recovery are different kinds of proof, and the
existing vignette already blurs this once (calling gryphon "teaching/simulated" while also
using it as the estimated-VC recovery target). Darwin signs the gryphon tier specifically
because it is the one tier touching real biological data with a pathological raw pedigree
worked around by a supplied relationship matrix — that workaround needs to stay visible,
not quietly normalized.

**Grace / Karpinski (new to this revision, docs + CI).** The asymmetry between R's
every-push pkgdown deploy and Julia's tag/PR-only Documenter deploy (A18) is a small thing
that becomes a credibility problem the moment someone compares the two sites side by side
post-CRAN. Fix it in the same batch as the navbar rebuild (B5), before the CRAN gate (B6),
not after.

**Ada (orchestration).** The live sweep changed my plan. I intended A01 to be a formality;
it is not. Both repos are parked on the foreign `codex/2026-07-13-v07-performance-localization`
branch and the R side is 7 commits ahead, unpushed, of unestablished authorship. Cutting a
worktree from there would entangle this campaign with PR137 and PR274 on day one — exactly
the overlap that is Shinichi's call and never resolved unilaterally. So B0 is genuine
unblocking work and **the LOOP should not be armed until it lands, and should be scoped to
the `HSquared.jl` worktree specifically** once it does. I have also held the Opus budget to
two Block-1 arcs, 23 h, under 9% of the judgment bar, and pinned my own orchestration layer
to Composer-by-default with Fable reserved for genuine multi-arc disputes only — not a
default anywhere in this plan.

---

## 11. PRE-AUTHORISED AFTER G0

Once Shinichi answers the three questions below, the following proceed **without further
prompting**, per the standing Auto-review envelope:

- Creating the two worktrees and the branch `claude/lane-h2-twin-20260901`.
- All file reads, greps, and `rg` sweeps across both repos and the brain vault
  (never `intake/`).
- Local `devtools::document()`, `devtools::test()`, `devtools::check()`, `air format .`,
  `julia --project=. -e 'using Pkg; Pkg.test()'`, `julia --project=docs docs/make.jl`,
  `bash tools/preamble_cap.sh`, local pkgdown/Documenter builds (A17/A18).
- File edits and ordinary single-file deletes inside the two worktrees and
  `~/local-scratch`.
- Local `git add` **by explicit path** and `git commit` on the campaign branch.
- ControlMaster-attach SSH to Totoro (`cm-*`, already authenticated) and Totoro runs
  **≤30 minutes**.
- Writing check-log, after-task, and coordination-board entries.
- Spawning batch subagents within the 6-child budget, at the models tabled in §7,
  including Kimi/Gemini/Luna cheap-tier sub-passes inside those budgets.

**Still ASK, every time:** `git push` · force-push · `reset --hard` · merge to main ·
any release or public posting · CRAN submission · **Julia General-registry registration
(A19)** · Totoro runs **>30 min** · any DRAC job · credentials/`.env`/`~/.ssh` · fresh
Duo-triggering SSH · any `experimental → covered` flip · any edit touching PR137 or
PR274 files · **arming any Block 2 arc (A24-A26)**.

---

## 12. THREE G0 QUESTIONS

### Q1 — Base branch: cut the campaign from `main`, or from the v07 codex branch?

Both repos are sitting on `codex/2026-07-13-v07-performance-localization`, which is the
branch carrying the foreign PR137/PR274 work, and the R checkout is 7 commits ahead of its
own remote with those commits' authorship unestablished. `main` exists in both repos and is
not the current checkout. This also determines whether A19's registry step (which reads
ROADMAP's Release Model section) starts from a clean or entangled base.

**Ada recommends: cut from `main`.** It is the only base that cannot entangle this campaign
with two open foreign PRs, and overlap with a foreign lane is explicitly yours to resolve,
not mine. Cost of being wrong in this direction is a rebase later; cost in the other
direction is a tangled shared branch across two repos and two agents. If any of the 7
commits turn out to be ours and load-bearing, A02 will surface them and we cherry-pick.

### Q2 — Fix the `CAP-EXHAUSTED ≤ 4/48` threshold *before* S5 runs, or set it from the run?

The frozen S5 gate carries this threshold with no in-repo precedent, recorded as
owner-revisable before any run.

**Ada recommends: fix it before the run, at ≤ 4/48, and record the reasoning as the
precedent.** A threshold chosen after seeing the output is not a gate, and Fisher will
block on that. If ≤4/48 is the wrong number, now is the moment to change it — but change it
*blind*, on principle, not on results. This is a one-line answer that unblocks A07 and A08.

### Q3 — Do the G10 S1/S2/S3 sign-offs stay entirely with you, or may this campaign prepare
decision-ready dossiers for you to sign?

The snapshot records that delegation is resolved — G10 is **not** delegated to Szymek and
stays with you — but the three sign-off decisions themselves remain open and are listed as
blocking.

**Ada recommends: campaign prepares, you decide.** A09 assembles the evidence, states what
each sign-off would assert, and stops. No agent signs. That keeps the decision yours while
removing the assembly work from your desk, and it is the only version of this that respects
the covered-flip gate.

---

## 13. PASTE-READY `/goal` STUB + LOOP STUB (Julia worktree)

```
/goal Drive the H² twin campaign's 0.5.0 CRAN-ready arc block (hsquared R +
HSquared.jl engine) through arcs A01-A23 per
/Users/z3437171/local-scratch/h2-twin-g0-plan.md, in batches B0-B9, 6 children
max per checkpoint. Block 2 (A24-A26, the 0.6-1.0 ladder) is explicitly OUT OF
SCOPE for this goal — do not arm it without a fresh, separate G0.

Start at B0: resolve fog ticket F1 by cutting worktrees for both repos at
~/local-scratch/lanes/{hsquared,HSquared.jl}-h2-twin-20260901 on branch
claude/lane-h2-twin-20260901, from the base Shinichi selects in G0 Q1. Classify
the 7 unpushed commits currently on the R checkout of
codex/2026-07-13-v07-performance-localization before touching anything. If those
commits are Codex's, STOP and report — do not proceed to B1.

Routing: Cursor Models bar (Grok 4.6 / composer-2.5-fast / gemini-3.7-flash-high)
for recon, git state, mechanical gate-checks and unlazy counts. Other Models bar
defaults to Sonnet 5 thinking-high, or gpt-5.6-terra-medium for doc/tooling arcs
(A03, A10, A17, A20), for implementation and bounded reviews; gpt-5.6-luna-medium
for read-only verification; kimi-k3-max for wide-read/inventory/draft-only slices
inside A10/A13/A17 (draft only, always lens-reviewed before commit). Opus 5 is a
CEILING reserved for exactly two Block-1 arcs: A21 (estimand + claim-scrub
dispute) and A23 (D-43 completion panel). This orchestrator layer itself defaults
to Composer for routine batch coordination; escalate to claude-fable-5-thinking-
high only for a genuine multi-arc integration dispute the orchestrator cannot
resolve by re-reading the artifacts — never as a default.

Definition of done is the campaign's four end states E1-E4 plus unlazy gate
groups G1-G11 (§9 of the plan) all green, with Rose recording a clean audit or
explicit blockers, for the 0.5.0 block only.

Never git add -A. Never push, merge, release, register the Julia engine to the
General registry, submit to CRAN, flip experimental→covered, run Totoro
>30min or any DRAC job, touch PR137/PR274 files, or arm Block 2 (A24-A26)
without asking. Record durable decisions in repo files before the turn ends,
not in chat.

--- LOOP STUB (arm only after B0 lands and F1 is resolved; scope to the
    HSquared.jl worktree — that repo carries the compute-bearing near-term
    arcs A07/A08/A09/A11/A19) ---

/loop 6h in ~/local-scratch/lanes/HSquared.jl-h2-twin-20260901:
  report status on A07 (S5 run), A08 (threshold), A09 (G10 dossiers), A11
  (comparator harness), A19 (registry registration) against this plan's
  batch barriers B2/B3/B6; do not advance past a barrier without Rose's
  signature recorded in the coordination board; never touch the registry
  step (A19) or any Totoro run >30min without asking first.
```

---

**FINAL G0 STOP. Nothing proceeds until Q1, Q2, and Q3 are answered.**
