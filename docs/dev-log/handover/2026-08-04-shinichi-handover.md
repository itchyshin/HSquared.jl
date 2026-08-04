# Handover → Shinichi (HSquared.jl, Julia engine lane) — 2026-08-04 (canonical entrypoint)

**Branch:** `codex/2026-07-13-v07-performance-localization` @ `2c1f4917` — origin is at `67b60d8b`,
so **2 commits are AHEAD and UNPUSHED** (the F6 arc through `67b60d8b` was pushed on 2026-08-04;
this session's two docs commits are not) · **PR:** #274 (DRAFT — do not auto-merge) ·
**Handed from:** Szymek · **Handed to:** Shinichi · Tree clean, all work committed, all local
checks green.

> **Resume correctly.** `main` is far behind; this branch carries the whole 07-24 → 08-04 arc.
> ```sh
> cd <repo> && git fetch origin
> git checkout codex/2026-07-13-v07-performance-localization   # DO THIS FIRST
> git log --oneline -1                                          # expect 2c1f4917 or later
> ```
> Then run the `hsquared-rehydrate` skill, read the `AGENTS.md` Live Phase Snapshot, then this doc.

---

## The one-paragraph version

Three engine fitters — `fit_ai_reml`, `fit_eigen_reml`, `fit_matrix_free_reml` — are implemented,
tested, documented, and carry staged evidence. **None is promoted. `public_covered_count` is 5 and
has not moved.** Szymek's lane is now wrapped up because **every remaining lever is either your
sign-off or needs compute he does not have.** Nothing is half-finished; nothing is waiting on a
technical unknown in this repo. The work is waiting on you.

## What you actually need to decide

Four things, in rough order of leverage. The rest of this document is support for these.

1. **Do you grant Totoro/DRAC access, and to whom?** (**S8**) This is the root blocker. It gates the
   pre-declared recovery gate at `n > 20 000` (**S5**) and the at-scale external comparator (**S6**)
   — the two legs that decide whether `fit_matrix_free_reml` is *trustworthy* rather than merely
   *consistent with our own other estimator*. Szymek has no cluster credentials; those are yours.
2. **Is G10 delegated to Szymek, or not?** This question was raised in the 2026-07-24 onboarding note
   and **has never been answered**. Until you answer it, every agent has been correctly treating all
   three G10s as yours — which means all three fitters stay staged indefinitely by default. A
   one-line answer either way unblocks a standing ambiguity.
3. **Do the three staged fitters stay staged?** (**S1/S2/S3**) You chose KEEP STAGED on 2026-07-24.
   Nothing since then has changed the evidence for `fit_ai_reml` or `fit_eigen_reml`. F6 added a
   third, with *less* evidence than the other two.
4. **Does the R bridge get scheduled?** (**S7**) It is in the other repo, and it is **the only thing
   that can move `public_covered_count` off 5.** Engine-covered ≠ R-public-covered. Until the bridge
   lands, promoting any fitter changes the engine's internal status and nothing a user can reach.

## REQUIRED SIGN-OFF LEDGER

Nothing below is signed off. Unchanged from 2026-07-28 except where noted.

| # | Sign-off / gate | Owner | Applies to | Status | Blocks |
|---|---|---|---|---|---|
| S1 | **G10 maintainer sign-off** | **Shinichi** (delegation unconfirmed) | `fit_eigen_reml` | **OPEN** — you chose KEEP STAGED 2026-07-24 | experimental→covered flip |
| S2 | **G10 maintainer sign-off** | **Shinichi** (delegation unconfirmed) | `fit_ai_reml` | **OPEN** — you chose KEEP STAGED 2026-07-24 | experimental→covered flip |
| S3 | **G10 maintainer sign-off** | **Shinichi** | `fit_matrix_free_reml` | **OPEN** — never requested; evidence incomplete | experimental→covered flip |
| S4 | **FRESH promote-specific Rose (G8)** | spawned `rose-systems-auditor` | any of the three, at flip time | **OPEN** — the 2026-07-28 Rose was slice-scoped, NOT a promotion audit | any flip |
| S5 | **Pre-declared known-truth recovery gate at `n > 20 000`** | Szymek (needs cluster) | `fit_matrix_free_reml` | **OPEN** — nothing measured above n=10 000 | S3, and re-wiring `:auto` |
| S6 | **AT-SCALE external comparator** | Szymek (needs cluster) | `fit_matrix_free_reml` | **OPEN** — ASReml ran at q=2000, *below* the crossover | S3 |
| S7 | **R bridge** (`method="eigen"`, ai_reml, matrix-free routes) | **R lane — separate repo** | all three | **OPEN** — handed off, not implemented | `public_covered_count` moving off 5 |
| S8 | **Totoro/DRAC access** | **Shinichi** to grant | S5, S6 | **OPEN — ASK PENDING, now escalated to you directly** | S5, S6 |
| S9 | **D1 successor authorization** | **Shinichi** | D1 genomic lane | **OPEN** — 5 of 6 preconditions still unmet | any D1 work |

**Discharged, for the record (not sign-offs):** the external comparator at *validation scale*
(ASReml-R AGREE); the slice-scoped Rose G8 of 2026-07-28 (CLEAR-WITH-CHANGES, all applied).

## State of the three fitters, honestly

| Fitter | What it is | Evidence it HAS | What it still OWES |
|---|---|---|---|
| `fit_ai_reml` | production-scale sparse AI-REML | pre-declared recovery-at-scale gate **PASSED v2** (0.19%/0.065% @ q=100,000, 48/48), deep-15-gen unbiasedness, boundary 8/8, `sommer` comparator AGREE 3.6e-5, 2× real spawned Rose | **G10 + the R bridge only.** The strongest of the three. |
| `fit_eigen_reml` | one-factorization eigen single-effect REML | G11 discharged; recovers `fit_ai_reml` to ~1e-6 in-CI | G10 + the R bridge |
| `fit_matrix_free_reml` | matrix-free Monte-Carlo EM-REML (F6, high-fill tail) | ASReml-R **AGREE 1.31e-7** vs exact at q=2000; crossover measured to 16.59× at fill 262; 32 deterministic CI tests | **recovery-to-truth (none exists), the at-scale comparator, any evidence above n=10 000, the R bridge, G10.** The weakest. |

**The honest reading of F6:** every leg it has compares it to *another estimator*, never to truth.
The ASReml run sits at q=2000 / fill 75.2 — **below** the measured crossover of 150, i.e. in the
regime where the exact path still wins, not the high-fill tail the fitter exists for. It is
*consistent*, not *validated*. This is exactly why `:auto` was withheld: a route would have fired
only at `n > 20 000`, the single regime never measured.

**`:auto` never selects the matrix-free fitter.** It is opt-in only, by owner decision of
2026-07-28, and a `MethodError` test pins that re-wiring the divert cannot pass silently.

## What this session did (2026-08-04, two commits, docs-only)

`fa53b573` — the published validation-status table is now **generated** from `validation_status()`
at documentation build time. `2c1f4917` — this handover, the board entry, and the Live Phase
Snapshot rotation.

The 2026-07-28 handover recorded it as "omits 4 rows". Re-derived mechanically, it was carrying
**33 of 56 rows** — 23 missing — and `V5-MARKER-THRESHOLD` was published **`partial`** where the
engine, the debt register (`covered (scoped)`), and its own promotion checkpoint all say
**`covered`**. That is a wrong status on a public page, not just a gap.

Fixed by generation rather than resync: re-copying 56 rows by hand would have restarted the clock
that produced the drift. **No `src/`, test, or fixture change; no capability flip; no new claim;
`public_covered_count` stays 5.** Detail:
`docs/dev-log/check-log.d/2026-08-04-validation-status-table-generated.md`; full report:
`docs/dev-log/after-task/2026-08-04-validation-status-table-generated.md`.

**Rose ran as a review LENS only — no subagent was spawned.** No flip occurred, so S4 is not
triggered. Flagged plainly because `AGENTS.md` requires saying so.

## Open items handed to you, beyond the ledger

- **`V1-EIGEN-REML` has a debt-register row but NO `validation_status()` row**, while its sibling
  `V1-MATFREE-REML` has both. The published validation ladder therefore shows one of the three
  staged fitters and not the other. Not fixed here on purpose: adding a row moves the published row
  count 56→57 and the `length(validation) == 56` test assertion — a claim-surface change that
  deserves its own slice, not a rider on a docs cleanup.
- **`fit_multi_effect`'s `:auto` still hard-codes `K == 1 → :exact`**, justified by an assumption F0
  falsified. Documented, not changed. A real fix routes it on measured fill.
- **`sommer` is not installed on Szymek's machine**, so five committed `run_sommer_*.R` comparators
  cannot run there; committed evidence pins sommer 4.4.5 / R 4.6.0 against that box's R 4.6.1.
  Repo-health, independent of everything above.
- **`gh` is not installed on Szymek's machine** — CI and PR state were never verifiable from there.
  Worth checking `gh run list` yourself on first contact.

## Fences that must survive this handover

- **No capability flip without a FRESH promote-specific Rose (S4) + your explicit G10.**
- **ASReml: estimand comparisons ONLY.** The §4 fence
  (`docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md:96-102`) forbids
  performance claims. Never put ASReml and a timing on the same page. Both comparator scripts carry
  an in-file instruction not to add a stopwatch.
- **Freeze-then-run, never the reverse.** The S5 predeclaration must be frozen *before* compute
  runs, which is why it was deliberately not drafted-and-frozen while S8 is open.
- **D1 genomic stays PAUSED** (D-68/D-71). The quarantined
  `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` stays untouched.
- **Do not edit the R twin from this repo.** Separate lane, separate repo.

## Local check state (2026-08-04, at `fa53b573`)

| Check | Result |
|---|---|
| `julia --project=. -e 'using Pkg; Pkg.test()'` | **passed**, zero failures/errors suite-wide |
| `julia --project=docs docs/make.jl` | **exit 0**; 6 pre-existing/environmental warnings, none new |
| `bash tools/preamble_cap.sh` | **CAP OK** — 8595 B / 14000 B, 1 snapshot entry / cap 1 |
| `tools/status_cache.json` | refreshed — rows 56, covered 13, **public_covered 5** (unchanged) |
| CI | **not verifiable** — `gh` is not installed on the handing-over machine |

## Mission-control summary

| Lane | Branch / state | Shipped since 07-28 | Next by leverage |
|---|---|---|---|
| HSquared.jl (docs) | `codex/2026-07-13-…` @ `2c1f4917`, **2 ahead of origin `67b60d8b`, unpushed** | generated validation-status table (drift class closed) | push the 2 docs commits |
| HSquared.jl (matrix-free) | same branch; experimental + opt-in | — | tail-scale recovery gate + at-scale comparator (**needs S8**) |
| HSquared.jl (ai_reml, eigen) | same branch; STAGED | — | **your G10** + R bridge |
| hsquared (R twin) | separate repo, untouched | — | opt-in routes for all three; count stays 5 |
| D1 genomic | PAUSED (D-68/D-71) | — | needs **S9**; do not conflate |

> Prior arc: `docs/dev-log/handover/2026-07-28-claude-handover.md` ·
> `docs/dev-log/handover/2026-07-24-claude-handover.md`.
