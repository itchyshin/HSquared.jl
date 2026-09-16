# Pre-declaration — S6 ASReml-R comparator: at-scale estimand leg + wall-clock ladder

> **STATUS: PARKED (licence ABSENT).** Design freeze intact (FROZEN-NOT-RUN content
> unchanged). A33 measured **ABSENT** on Mac + Totoro — receipt
> `~/local-scratch/h2-a33-asreml-licence-probe.md`. Nothing executed — not the grid,
> not a single cell, not a feasibility probe. **No speed claim.** Not authorised.
> `public_covered_count` stays **5**; `V1-MATFREE-REML` stays `experimental`; no row
> moves because this file exists or because A33 closed P1 as ABSENT.
>
> **Prerequisites:** **P1 = ABSENT** (A33, 2026-09-02). **P2 is DISCHARGED** by the
> 2026-09-02 provenance port (see §1). P3 remains ABSENT/`OPTIONAL` as measured.
> This gate is **licence-gated before it is compute-gated**: without a licensed
> ASReml-R on a host we can drive, the whole wall-clock leg is parked, and parking
> it is a legitimate outcome — now the measured outcome.
>
> **OWNER-REVISABLE BEFORE ANY RUN.** Freezing binds the gate, not the maintainer.
> Every threshold below may be revised and re-frozen at a new commit; what may not
> happen is a threshold moving *after* a number has been seen. Unparking requires a
> later PRESENT probe on a licensed host, then A34 before A35.

**Spine reference:** `~/local-scratch/h2-post-050-spine-mv4-s6.md` §3 (Track 2, arcs
A32/A33/A34/A35). This document is **A32**. **A33 is DONE — ABSENT** (Mac + Totoro);
see receipt above. Ladder **PARKED**; design freeze intact.

**Ledger position.** S6 is item **(2)** of the four things `V1-MATFREE-REML` owes
before any covered flip (`docs/design/validation-debt-register.md`, the
`V1-MATFREE-REML` row): the **at-scale** external comparator. The 2026-07-28
ASReml-R leg discharged that item **at validation scale only** — q = 2,000, fill
75.2, **below** the measured ~150 crossover, i.e. in the regime where the exact
path still wins, not the tail `fit_matrix_free_reml` exists for
(`docs/dev-log/recovery-checkpoints/2026-07-28-asreml-matfree-comparator.md`, on
the v0.7 lineage). The remaining three items — S4 (fresh promote-specific Rose
audit), S7 (R bridge), S3/G10 (maintainer sign) — are untouched by this document.

---

## 0. The one discipline this document exists to enforce

**Two different things are being run on the same host in one campaign, and they
must not be reported as one result.**

| Leg | What it asks | Gate | Debt it touches |
|---|---|---|---|
| **Leg E — estimand agreement at tail scale** | Do HSquared and ASReml-R agree on the *same estimand* in the high-fill tail? | Component agreement, pre-declared tolerances (§5) | Closes `V1-MATFREE-REML` item (2) at the tested cells; narrows item (3) |
| **Leg W — wall-clock ladder** | How long does each fitter take, per `(n, fill)` cell, against ASReml-R on the same host? | Agreement-before-timing per cell (§6) | **None.** It closes no validation debt. It is a performance measurement, gated separately, and it can FAIL or be parked without affecting Leg E |

Running them together is efficient. **Merging their verdicts would be the
mistake.** Two legs, two verdicts, two reports, and the §8 Rose fences hold across
both until each leg has separately reported and been audited.

Today's honest position, stated this starkly on purpose: **one estimand-agreement
run exists at q = 2,000, and zero wall-clock ASReml comparisons anywhere.** Every
internal timing in this repository is HSquared measured against itself.

---

## 1. Prerequisites — three OPEN, two of them measured on this branch

Stated first, because a pre-declaration that hides its blockers is a wish list.

### P1 — Licensed ASReml-R host (**ABSENT**, A33 2026-09-02)

**Measured ABSENT** on the campaign Mac (R 4.6.0) and Totoro (R 4.5.3 via existing
ControlMaster): `packageVersion("asreml")` / `library(asreml)` both fail with no
package called `asreml` — never reached a licence-error path. Receipt:
`~/local-scratch/h2-a33-asreml-licence-probe.md`.

Prior note that it was not on the campaign laptop
(`docs/dev-log/2026-09-01-blupf90-tool-unavailability.md`) is confirmed and widened.
**A NO / ABSENT parks Leg W (and Leg E's ASReml arm) without invalidating this
design** — now the measured outcome. Owner may still obtain a licence elsewhere;
until a PRESENT re-probe, A34/A35 stay unarmed. Bundle any obtain-or-park decision
with the existing S7/D1 owner items; **DP-1 push remains first.**

### P2 — The ASReml scaffold is NOT on this branch (MEASURED, 2026-09-02; **PORTED 2026-09-02**)

**Finding (A32 freeze):** `comparator/prepare_asreml_matfree.jl` and the high-fill
`adversarial()` generator `sim/drac/f0_adversarial_fill.jl` existed **only** on
`refs/heads/codex/2026-07-13-v07-performance-localization` — verified by walking
every ref's tree, not by reading a path. That is a **foreign codex lane** (GOAL
invariant I4: do not touch it).

**Port receipt (this commit family, campaign only; foreign lane READ ONLY):**

| Campaign path | Source introducing SHA | Date | Blob SHA |
|---|---|---|---|
| `comparator/prepare_asreml_matfree.jl` | `29d04a1d9abf649eb33981cacccd65643999a449` | 2026-07-28 | `8a5a44da6adcb8e15dfbff83d2bb328f6644e631` |
| `comparator/run_asreml_matfree.R` | `29d04a1d9abf649eb33981cacccd65643999a449` | 2026-07-28 | `295b718def1ea99ade2fd44a971db3df203893c2` |
| `sim/drac/f0_adversarial_fill.jl` | `533cf0f8c84e69624b6127d6736d96db4718d799` | 2026-07-24 | `24a5edf1d9667dd05647b04b3a8719bb6e9c582e` |

Foreign tip used for the show: `853bcc12a25dee4445374754b048662576df2fef`
(`codex/2026-07-13-v07-performance-localization`). Each file carries a provenance
header; bodies match the foreign blobs byte-for-byte after the header. **PORTED,
NOT RUN** — neither prepare nor runner nor F0 bench was executed; S6 Leg E/W
remain unimplemented in the skeleton.

The inlined `adversarial()` at `sim/phase_s5_matfree_tail_recovery_gate.jl:95`
remains available for the ladder DGP; the ported `f0_adversarial_fill.jl` is the
standalone high-fill scaffold named by this prerequisite.

**P2 status: DISCHARGED on this campaign branch.** P1 is **ABSENT** (A33);
Leg E/W implementations remain unarmed while parked.

### P3 — `fit_eigen_reml` does not exist on this branch (MEASURED, 2026-09-02)

`rg fit_eigen_reml src/` returns **nothing** on `claude/lane-h2-twin-20260901` at
`03b43d1a`; `src/HSquared.jl` exports `fit_ai_reml` and `fit_matrix_free_reml` and
no eigen fitter. The spine's §3.3 "three fitters reported separately" is therefore
**not executable here as written**. This gate resolves that by declaring the fitter
set explicitly (§4.2) rather than discovering it at run time: **two fitters on this
branch**, with the eigen arm declared OPTIONAL and reported as ABSENT unless the
running branch actually provides it. An absent fitter is a recorded absence, never
a silently dropped column.

---

## 2. Axis discipline — fill, not `n`

**The key axis is fill `nnz(L)/n`, not raw `n`.** A pedigree 15× smaller at 15×
higher fill can cost ~660× more (`docs/src/fitting-at-scale.md`). A grid indexed on
`n` alone would measure the wrong thing and would produce a "scaling curve" that is
an artefact of which pedigrees happened to be drawn.

Every cell below is therefore identified by **`(q, target fill, problem class)`**,
and **measured fill is recorded per cell** (via `HSquared._sparse_mme_system` +
`cholesky`, mirroring the S5 gate's own fill measurement). A cell whose measured
fill lands outside its declared band is reported at its **measured** fill and
flagged — the band is a design target, not a claim about what was drawn.

Two problem classes, kept apart because they exercise different code paths and
support different hypotheses:

| Class | Generator | Fill regime | Which fitter it exists to test |
|---|---|---|---|
| **LOW-FILL SPARSE** | `halfsib(q)` — low fill (~17–19) even at q = 300,000 | ≤ ~20 | `fit_ai_reml`; the sparse-exact win hypothesis |
| **HIGH-FILL MATFREE** | `adversarial(q; nfounder_frac = 0.005)` — small founder base, random mating | ~75 → 580+ | `fit_matrix_free_reml`; the tail the exact path walls on |

Both generators are the ones that produced every existing fill/cost number in this
repository (`docs/src/fitting-at-scale.md`,
`docs/dev-log/recovery-checkpoints/2026-07-24-f0-adversarial-highfill-decision.md`).
No new generator is introduced by this gate.

---

## 3. The grid (FROZEN)

Seven cells. `q` = number of individuals in the pedigree; `n` = number of records
(here `n = q`, `Z = I`, matching every cited precedent).

| Cell | Class | q | Target fill | Why this cell exists | Prior measurement it anchors to |
|---|---|---|---|---|---|
| **L1** | low-fill sparse | 50,000 | ~17–19 | the win hypothesis at moderate scale | interpolates F0 Regime A (0.87 s at q = 100,000) |
| **L2** | low-fill sparse | 300,000 | ~17–19 | scale end of the win hypothesis | F0 Regime A: **2.30 s** internal, Totoro |
| **C1** | high-fill matfree | 2,000 | ~75 | **the existing ASReml leg's own cell** — anchors this run against 2026-07-28 | ASReml-R 4.2.0.482 agreement 1.31e-7 / 8.07e-8 vs `fit_ai_reml` |
| **C2** | high-fill matfree | 5,000 | ~150 | the crossover band itself | crossover table: exact 25.0 s vs matrix-free 9.12 s (2.74×) |
| **T1** | high-fill matfree | 10,000 | ~262 | tail; exact walls on selinv | 132 s Totoro / 231 s Mac Studio exact; 13.9 s matrix-free |
| **T2** | high-fill matfree | 25,000 | ~583 | **the S5 gate's own scale** — recovery and comparator evidence meet | S5: fill 583.3 measured, matrix-free 54.26 s single-core |
| **R1** | real field pedigree | as observed | as observed | one non-synthetic cell — random-mating synthetics are **adversarial, not typical** | none; this cell is new evidence by construction |

**R1 is conditional and must not be silently dropped.** It requires a real field
pedigree that may lawfully be used on the licensed host. If no such pedigree is
available at run time, R1 is reported as **NOT RUN — no pedigree available**, and
the report states plainly that every remaining cell is synthetic. A ladder made
entirely of random-mating synthetics measures an adversarial regime and must say
so.

**Cell ordering at run time is cheapest-first** (C1 → C2 → L1 → T1 → L2 → T2 → R1),
so a licence, install, or harness defect surfaces on a 1-second cell rather than
after hours of L2.

---

## 4. Fixed design (FROZEN)

### 4.1 Same estimand — the non-negotiables

1. **Model:** univariate Gaussian animal model, `y = μ + u + e`, `Z = I`, REML.
   Identical incidence, identical fixed effects (intercept only), identical
   relationship input on both sides.
2. **ASReml gets the PEDIGREE, not our `Ainv`,** and builds its own inverse via
   `ainverse()` — exactly as the 2026-07-28 leg did. Feeding it our `Ainv` would
   make it a re-implementation of our own lineage rather than an independent one.
3. **Neutral starts on both sides.** The existing ASReml matfree scripts warm-start
   from truth; a **timing** leg must not. A warm start measures the start, not the
   fitter. Declared start: `(σ²a, σ²e) = (0.8, 0.8)` on the HSquared side (the S5
   convention, deliberately off the truth `(1.0, 1.0)`), and ASReml's own default
   initial values with no truth-informed override, recorded verbatim from the `.asr`
   log.
4. **Truth:** `(μ, σ²a, σ²e) = (5.0, 1.0, 1.0)` → h² = 0.5, interior. This is the
   established high-fill-family convention (F0 / crossover / ASReml comparator /
   S5), not the low-fill half-sib family's `(2.0, 1.0, 1.5)`. Reusing it keeps this
   gate's numbers directly comparable to the existing evidence at smaller `q`. The
   low-fill cells L1/L2 use the **same** truth for cross-class comparability, which
   is a deliberate departure from the half-sib family's own convention and is
   recorded here rather than discovered in the results.

### 4.2 Fitter set (declared, not discovered)

| Arm | Availability | Gating role |
|---|---|---|
| `fit_ai_reml` | present on this branch | **required** in every cell |
| `fit_matrix_free_reml` (`nprobe = 64`, the untuned default) | present on this branch | **required** in every high-fill cell; optional in L1/L2 |
| `fit_eigen_reml` | **ABSENT on this branch** (P3) | **OPTIONAL.** Run only if the executing branch provides it; otherwise the column reads `ABSENT`, never blank |
| ASReml-R | licence-gated (P1) | **required** for both legs; absent ⇒ the whole gate is NOT RUN, not partially run |

**`:auto` routing is disclosed, never hidden.** The standing fence
(`docs/design/capability-status.md`, `V1-MATFREE-REML` row, pinned in CI by a
20-assertion testset since 2026-09-01) is that `:auto` does **not** route to
matrix-free. So matrix-free is **opt-in in every cell**, and the report must say
so in the same paragraph as any matrix-free timing. A reader must not be able to
infer "this is what a default caller gets" from a matrix-free number.

### 4.3 Pinned and **ASSERTED** toolchain

This is the open question the S5 run raised, and it is fixed here because it cannot
be retrofitted to an already-run gate: **three agents reached for three `julia`
binaries across two versions because the frozen S5 gate *recorded* its interpreter
without *asserting* it.**

The harness **asserts, and refuses to run when the assertion fails**:

- `VERSION` matches a pre-declared `HSQ_S6_JULIA_VERSION` (exact `major.minor.patch`).
- `Base.active_project()` is the intended project.
- The HSquared commit SHA (`git rev-parse HEAD`) matches a pre-declared value passed
  in explicitly, so a dirty or wrong checkout cannot silently produce evidence.
- `OPENBLAS_NUM_THREADS` and `JULIA_NUM_THREADS` equal their declared values.
- On the R side: `packageVersion("asreml")`, `R.version.string`, and the licence
  expiry are read and **asserted non-missing**, not merely printed.

Recorded in the manifest of every output file: host, physical core count, BLAS
vendor and version, `OPENBLAS_NUM_THREADS`, `JULIA_NUM_THREADS`, Julia version,
HSquared SHA, ASReml-R version, R version, and the run timestamp.

### 4.4 Seeds (cold-start, UNSEEN at declaration)

Placed clear of every occupied 8-digit `2026xxxx` block. Occupancy re-measured on
this branch 2026-09-02: the highest occupied point anywhere in `*.jl` / `*.md` /
`*.R` is `20269547` (S5 Leg A), and the derived-probe family reaches `20769547`.
Nothing occupies `202696xx`–`202699xx` or `207696xx`–`207699xx`; both endpoints
were re-verified with zero matches.

| Purpose | DGP seeds | MC-probe seeds (`DGP + 500,000`) |
|---|---|---|
| **Leg E** — agreement, 8 seeds per tail cell (C1, C2, T1, T2) | `20269600:20269631` (8 per cell, allocated in cell order) | `20769600:20769631` |
| **Leg W** — timing, 1 dataset per cell, re-timed `R_TIMED` times | `20269700:20269706` (one per cell L1,L2,C1,C2,T1,T2,R1) | `20769700:20769706` |

`MersenneTwister(seed)` per draw. **DGP seed and MC-probe seed are distinct axes**
and never the same integer, per the `sim/v08_s2fit_recovery_scale.jl` convention.

**RNG portability is not assumed.** S5 measured that a `MersenneTwister` stream is
*not* version-stable across the Julia range in use — the same seed drew a different
dataset on 1.10 and 1.12. The asserted Julia version (§4.3) is therefore
load-bearing, not decorative, and **no cross-host comparison in this gate may span
Julia versions** without re-drawing and saying so.

---

## 5. Leg E — estimand agreement at tail scale (GATED FIRST)

**Cells:** C1, C2, T1, T2 (the high-fill class). 8 seeds each, cold-start.
**Arms per seed:** ASReml-R; `fit_ai_reml`; `fit_matrix_free_reml` (`nprobe = 64`).
Where the exact path is infeasible (T2 — F0 measured 1,529 s at q = 20,000 / fill
471, and T2 is larger), `fit_ai_reml` is recorded as **NOT ATTEMPTED — infeasible
by prior measurement**, with the citation, and Leg E at that cell compares ASReml
against matrix-free only.

**Tolerances — different for the two comparisons, because they are different
statistical objects.** This mirrors the 2026-07-28 comparator's own reasoning
(*"A Monte-Carlo estimator is not expected to hit a point value… A tight relative
tolerance here would be meaningless"*):

| Comparison | Statistic | PASS bound | Provenance of the bound |
|---|---|---|---|
| ASReml vs `fit_ai_reml` (deterministic vs deterministic) | max relative difference across the 8 seeds, per component | **≤ 1e-5** | the 2026-07-28 leg measured 1.31e-7 / 8.07e-8; 1e-5 is ~100× headroom over that, still ~4 orders tighter than the MC bound |
| ASReml vs `fit_matrix_free_reml` (deterministic vs stochastic) | mean \|relative difference\| across the 8 seeds, per component | **≤ 0.05** | the S5 `AGREE_TOL_MC` constant, unchanged; SD and max reported informationally, **not gating** (max-of-8 of a stochastic quantity is itself high-variance and an inappropriate gate) |

**Leg E GATE = both bounds hold in every attempted cell, for both components
(`σ²a`, `σ²e`).**

**A FAIL is a banked negative.** `V1-MATFREE-REML` stays exactly where it is, item
(2) stays open, and no threshold is moved afterwards
(`docs/dev-log/decisions/2026-06-14-calibration-failure-response`). A FAIL gets a
per-cell diagnostic read to separate a genuine defect from a flaw in *this* gate,
but any correction requires its own fresh pre-declaration.

---

## 6. Leg W — the wall-clock ladder (GATED SECOND, AND SEPARATELY)

### 6.1 Metric order — agreement first, then time. Always.

1. **Variance-component agreement gates the cell.** Before **any** timing number
   from a cell may be quoted, the fitters compared in that cell must agree there, at
   the §5 tolerances, on that cell's timing dataset. **A cell that fails agreement
   yields NO timing number — not a slower one, none.** A fitter that is fast because
   it is answering a different question is not fast.
2. **Median of `R_TIMED` timed runs after `R_WARMUP` discarded warm-up runs**, per
   repo convention. Declared: **`R_WARMUP = 1`, `R_TIMED = 5`** on cells whose single
   fit is under 60 s (C1, C2, T1, L1); **`R_WARMUP = 1`, `R_TIMED = 3`** on the
   expensive cells (L2, T2, R1). Min, median, max, and the raw per-run vector are all
   recorded; the **median** is the reported statistic.
3. **Convergence status and iteration count per fit — reported, not asserted.** A
   timing from a non-converged fit is recorded with its status attached and is
   **excluded from the reported median**, with the exclusion count disclosed.
4. **For matrix-free: `nprobe` and `trace_mcse` recorded on every fit.** Standing
   caveat, restated in the report: `nprobe = 64` is an **untuned default** and no
   study relates `nprobe` to variance-component error at scale (debt item (5)). A
   matrix-free timing at an untuned `nprobe` is a measurement of that configuration,
   not of the method's best achievable speed — in either direction.

### 6.2 CAP — pre-declared, and the reason it is stated in advance

| Cap | Value | What happens when it binds |
|---|---|---|
| `CAP_FIT_SECONDS` (single fit, any fitter, any program) | **7,200 s (2 h)** | fit is terminated and recorded as `CAP_EXCEEDED`. That is a **result** ("did not finish within 2 h on this host"), never a timing number and never a ratio |
| `CAP_ITERATIONS` (HSquared fitters) | **200** — the function default, kept, not raised | a fit hitting it is `CAP_EXHAUSTED`, excluded from the timing median, counted and disclosed. Raising the cap to make a fitter look better is tuning to pass |
| `CAP_CELL_SECONDS` (all arms × all runs in one cell) | **28,800 s (8 h)** | the cell stops; completed arms are reported, remaining arms recorded `NOT RUN — cell cap`. The correct response is to report and stop, **never** to silently shrink `q`, drop a fitter, or reduce `R_TIMED` |
| `CAP_CAMPAIGN_SECONDS` (whole ladder, per host) | **172,800 s (48 h)** | stop and report to the maintainer |

**The S5 lesson this inherits, stated so it cannot be forgotten:** S5's
`CAP_EXHAUSTED ≤ 4/48` came in at **0/48** — it never bound, so the threshold choice
remains **unexercised**. Every cap above is in the same position until it binds. **A
blind threshold that never bound is untested, not validated**, and none of these
numbers may be cited as a validated operating limit.

### 6.3 What Leg W may and may not conclude

- It may report: "on host H, at cell C, program P's median wall-clock was T
  seconds, having agreed with program Q on the variance components to tolerance τ."
- It may **not** report a speed ratio for any cell that failed agreement, nor for
  any arm that hit a cap, nor across cells with different measured fill as though
  they were a scaling law.
- **Margins are stated across realizations, not from the best draw.** S5's own
  lesson: the 1.10.10 draw alone would have supported a ~30× margin claim; across
  the two realizations measured it is **~3.5×**. Report the latter. Any Leg W margin
  is reported as the range across the timed runs and, where more than one
  realization exists, across realizations.
- **Leg W closes no validation debt.** Its PASS is a measurement, and its
  publication is separately gated by §8.

---

## 7. Compute routing — asked before sizing

Per the compute playbook, and the answer differs by leg:

| Work | Host | Reasoning |
|---|---|---|
| **Leg E (agreement) — the H² leg** | **Totoro first**, if it carries the licence | 384-core, no queue, `OPENBLAS_NUM_THREADS=1`; the S5 gate's own host, so T2's numbers are directly comparable to the measured 54.26 s single-core there |
| **Leg W (ladder)** | **Whichever host carries the ASReml-R licence** | The binding constraint is the **licence, not the cores**: a 384-core box without ASReml-R is useless here. DRAC (SLURM array) if the licence lives there |
| Anything on the campaign laptop | **NOWHERE** | see below |

**No laptop claims.** The campaign laptop has no ASReml-R and is a shared
interactive machine with uncontrolled background load. **No number produced on a
laptop may enter either leg's report**, including as a sanity check, and the harness
records the host so a laptop-origin row is identifiable after the fact.

**Every cell in this ladder is a >30-minute job, so every one of them ASKs**
(`LOOP/GOAL.md`: Totoro ≤ 30 min pre-authorised; Totoro > 30 min ASKs; **any** DRAC
job ASKs). A launch receipt naming the host, the cells, the expected wall-clock, and
the owner authorisation is required before the first cell runs.

---

## 8. Rose fences — STANDING, and unchanged by this document existing

Verbatim-ready. They hold through 0.6 regardless of this track's fate, and **writing
a pre-declaration lifts none of them.**

- **"No faster than ASReml."** No `hsquared` or `HSquared.jl` surface — README,
  vignette, docstring, `capability-status.md`, `validation_status()`, release note,
  talk, or commit message — may state or imply a speed comparison against ASReml
  until Leg W has **reported** and been **Rose-audited**.
- **No production-performance claim on any fitter.** Internal timings are
  self-comparisons and must be labelled as measurement, not competitive claim.
- **`test/fixtures/comparator_targets.toml` indexes estimand comparators only.**
  Adding a performance row is a gated change, not bookkeeping.
- **The 2026-07-28 ASReml leg is an estimand comparator at q = 2,000 / fill 75.2**
  and must be cited with that scope, never as "validated at scale".
- **An agreement result is not a timing result.** If Leg E lands and Leg W does not,
  the public position stays **"cannot say"**.
- **The one-line honest verdict, preserved:** *"Can HSquared beat ASReml?" —* **cannot
  say, and no surface should imply otherwise.** The plausible engineering story
  (competitive on low-fill livestock pedigrees at large q; ASReml's mature ordering
  and symbolic reuse possibly still winning on dense/high-fill or multivariate) is a
  **hypothesis**, and is the reason to run the ladder rather than a preview of its
  result.

---

## 9. Implementing skeleton — `sim/phase_s6_asreml_wallclock_ladder.jl`

Committed alongside this document, in the freeze-then-run order. **It is a skeleton.
The campaign has not been run — no cell, no seed, no SMOKE mode, no feasibility
probe.** Two zero-compute paths *were* exercised, and are recorded here rather than
left as an assertion that the file works: `HSQ_S6_DRYRUN=1` printed the frozen plan
and exited 0, and the default path stopped on the missing-ASReml prerequisite with
the intended message. Neither drew a dataset nor performed a fit.

Its contract:

- **It refuses to run without ASReml.** Absent `HSQ_S6_ASREML_CMD` (or a resolvable
  ASReml-R invocation), it exits with an explicit message naming the missing
  prerequisite and pointing at this document — it does not fall back to an
  HSquared-only run that would look like a ladder.
- **`HSQ_S6_DRYRUN=1` prints the frozen plan and exits 0.** Cells, seeds, caps,
  tolerances, and the resolved toolchain assertions are printed; **no fit is
  performed**.
- **It asserts the toolchain (§4.3) before any timing** and refuses to proceed on a
  mismatch.
- **`NOT_RUN` is the default state** it reports for every cell.

The heavy grid has **not** been executed and must not be until P1–P3 clear, this
document is re-read, and an owner authorisation with a launch receipt exists.

---

## 10. Output contract

**Two files, never one**, so the legs cannot be merged by accident downstream:

- `docs/dev-log/comparator-runs/<date>-s6-estimand-tailscale.md` + its TSV — Leg E.
- `docs/dev-log/comparator-runs/<date>-s6-wallclock-ladder.md` + its TSV — Leg W.

Every TSV opens with manifest comment lines (`#`) carrying the full §4.3 toolchain
record and the verbatim PASS-criterion text, mirroring
`sim/v08_s2fit_recovery_scale.jl`'s manifest style.

Leg E TSV columns: `cell, class, q, fill_measured, seed_dgp, seed_mc, program,
fitter, sigma_a2, sigma_e2, converged, iterations, reldiff_sa2, reldiff_se2,
nprobe, trace_mcse, status`.

Leg W TSV columns: `cell, class, q, fill_measured, seed_dgp, seed_mc, program,
fitter, run_index, phase(warmup|timed), wall_s, converged, iterations, nprobe,
trace_mcse, agreement_gate(PASS|FAIL|NOT_EVALUATED), status(OK|CAP_EXCEEDED|
CAP_EXHAUSTED|NOT_ATTEMPTED|ABSENT|NOT_RUN)`.

A single `GATE_JSON {...}` line per leg, with `leg`, `gate_pass`, `version`, the
cells attempted, and the per-cell verdicts, mirroring the S5 gate's own contract.

---

## 11. Review gate before anything is published

Pre-declaration commit (**this**) → owner authorisation + launch receipt → run →
report to `docs/dev-log/comparator-runs/` → **Curie / Fisher / Mrode / Gauss** on
Leg E and **Karpinski / Gauss / Jason** on Leg W → **Rose (mandatory)** on both →
and only then are the §8 fences either lifted with evidence or explicitly restated.

**PASS on both legs promotes nothing by itself.** `V1-MATFREE-REML` additionally
owes S4 (fresh Rose promote audit), S7 (R bridge, other repo), and S3/G10
(maintainer sign). `public_covered_count` stays **5** regardless of this gate's
outcome.

---

> Related: `docs/design/validation-debt-register.md` (`V1-MATFREE-REML` row, item (2)) ·
> `docs/design/capability-status.md` (`V1-MATFREE-REML` row; the `:auto` fence) ·
> `docs/dev-log/recovery-checkpoints/2026-08-04-f6-matfree-tail-recovery-predeclaration.md`
> (S5 — structural template, interpreter-assertion lesson, `AGREE_TOL_MC`) ·
> `docs/dev-log/recovery-checkpoints/2026-09-01-f6-matfree-tail-recovery-result.md`
> (S5 result; the ~3.5× margin discipline) ·
> `docs/dev-log/recovery-checkpoints/2026-07-24-f0-adversarial-highfill-decision.md`
> (fill/cost measurements; DGP generator provenance) ·
> `docs/src/fitting-at-scale.md` (crossover table; the fill-not-`n` axis) ·
> `sim/phase_s5_matfree_tail_recovery_gate.jl` (harness template; local `adversarial()`) ·
> `~/local-scratch/h2-post-050-spine-mv4-s6.md` §3 (spine, Track 2) ·
> `~/local-scratch/h2-asreml-speed-brief.md` (evidence brief, 2026-09-01).
