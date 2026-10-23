# Pre-declaration — `fit_matrix_free_reml` tail-scale known-truth recovery gate (S5)

> **STATUS: FROZEN at this commit. NOT RUN.** Both conditions the v2 draft set for freezing are now
> discharged, by measurement rather than assertion:
>
> **(a) The S8 premise is false.** The v2 draft withheld the freeze because "S8 (Totoro/DRAC access)
> is OPEN". Checked 2026-08-04: Totoro was reachable the whole time through the existing
> `ControlMaster` socket (384 cores, idle), and **Julia 1.10.0 was already installed** at
> `~/hsq_work/julia-1.10.0/bin/julia`. S8 was never a live blocker for this gate.
>
> **(b) Feasibility at the pre-declared `q` is now MEASURED, not assumed.** A single-seed probe on
> Totoro at the pre-declared `q = 25,000` high-fill config: measured fill `nnz(L)/n` = **583.3**
> (continuing the documented `50→77→149→262→471` trend), `fit_matrix_free_reml` **CONVERGED in 59
> iterations**, wall **54.26 s** single-core. Leg A is therefore ≈45–48 min serial, or a few minutes
> at 48-way parallelism on Totoro. The gate is affordable at the `q` it pre-declares. *(Caveats,
> stated because they bound the claim: n=1, one stochastic fill realization, and true 48-way
> concurrent behaviour on the shared machine was not tested. Leg X's 8 seeds at `q=2,000` were not
> separately timed — expected minor, but that is inference, not measurement.)*
>
> The implementing script `sim/phase_s5_matfree_tail_recovery_gate.jl` exists as of this commit and
> has been run in **SMOKE mode only**. The full 48+8-seed gate has **NOT** been run.
>
> **Freeze-then-run is satisfied:** this text and its script are committed *before* any gate compute.
> A feasibility timing probe is not the gate — it consumes no pre-declared seed and touches no pass
> criterion.
>
> **OWNER-REVISABLE BEFORE ANY RUN.** One number here is a judgment call with no in-repo precedent:
> A3's **CAP-EXHAUSTED ≤ 4/48 (~8.3%)** bound. Unlike A2's 0/48 (rule-of-three), nothing anchors it.
> Because nothing has run, the maintainer may revise it — or anything else here — and simply re-freeze
> at a new commit hash. Freezing binds the gate, not the maintainer.

**Revision log:** v1 (initial draft) → v2 (2026-08-04, same day): Leg A's non-convergence criterion
revised from a two-way graceful/non-graceful split to a three-way CONVERGED / CAP-EXHAUSTED /
NON-GRACEFUL classification with separate pre-declared bounds on (b) and (c), plus a pre-declared
iteration cap and a required iterations-to-outcome distribution, on evidence from an independent
local reproduction of the in-CI F6 fixture (`test/runtests.jl:4417-4446`) across two Julia
versions. → **v3 (2026-08-04, FROZEN):** S8 premise measured false; `q=25,000` feasibility measured
on Totoro; implementing script written and SMOKE-verified; status DRAFT → FROZEN. Scope otherwise
unchanged. Implementation note carried from the script: a **fourth** outcome
(`converged=false` with `iterations < cap`, via the positivity early-break in
`src/iterative_solve.jl`) is reachable; per this document's own instruction it is logged as an
explicit anomaly and excluded from A1/A2/A3 rather than folded into CAP-EXHAUSTED.

This is the **S5** item on the sign-off ledger (`docs/dev-log/handover/2026-08-04-shinichi-handover.md`,
`docs/dev-log/handover/2026-07-28-claude-handover.md`) and serves **G11**'s known-truth-recovery
clause (`docs/design/16-promotion-gate-predicates.md:31-35`) for `V1-MATFREE-REML`, the way
`docs/dev-log/recovery-checkpoints/2026-07-24-eigen-reml-recovery-gate-predeclaration.md` served
G11 for `V1-EIGEN-REML`. **It promotes nothing.** A PASS does not flip `fit_matrix_free_reml` from
`experimental`/`partial` to `covered`, and `public_covered_count` stays 5 regardless of outcome —
that additionally needs S6 (at-scale external comparator, separately owed), S4/G8 (a FRESH
promote-specific Rose audit), S3/G10 (maintainer sign-off), and S7 (the R bridge, separate repo).
A FAIL is a **banked negative**: `V1-MATFREE-REML` stays exactly where it is, and the already-withheld
`:auto` fence (`docs/design/capability-status.md:91`) stays withheld regardless.

## What is being validated

`fit_matrix_free_reml` (`src/iterative_solve.jl:1010`) is the `K=1` face of the matrix-free
Monte-Carlo EM-REML estimator: matrix-free PCG solves + a Hutchinson stochastic score trace, so the
MME coefficient matrix is never assembled or factorized. It exists for the ONE regime F0 measured
infeasible for the exact fitter — **high fill-in AND `n` past the dense-eigen cap (`n > 20,000`)** —
and it has **never been measured there**. Every existing leg compares it to *another estimator*
(`fit_ai_reml` in-CI at `n=400`; ASReml-R at `q=2,000`, `docs/dev-log/recovery-checkpoints/2026-07-28-asreml-matfree-comparator.md`),
never to a known truth, and the ASReml run itself sits **below** the measured crossover fill of 150
(`docs/design/capability-status.md:91`) — i.e. in the regime where the exact path still wins, not
the regime this fitter exists for. This gate adds the missing **known-truth, tail-scale** evidence:
does the fitter, run standalone with its documented default settings, recover the true `(σ²a, σ²e)`
in the high-fill / `n > 20,000` regime it was built for.

This gate covers **only** the recovery-to-truth leg (validation-debt-register.md:57 item (1)) and
narrows item (3) ("no evidence above `n=10,000`") at a single point. It does **not** cover: the
at-scale external comparator (item (2)/S6), the joint fill×n crossover surface (item (4)), a full
`nprobe` tuning study (item (5) — this draft adds one informational data point, not a study),
calibrated intervals, `>2` components, non-Gaussian responses, or the R bridge (S7).

## Model / DGP (locked)

- **Model:** single-effect Gaussian animal model, `y = μ + u + e`, `Z = I_n`.
- **Truth:** `(σ²a, σ²e) = (1.0, 1.0)`, `μ = 5.0` → **h² = 0.5**, interior/off-boundary. This
  reuses the established truth convention of the high-fill evidence family for this fitter —
  `sim/drac/f0_adversarial_fill.jl:53` (`simulate_y` defaults), `sim/matrix_free_crossover_benchmark.jl`
  (same defaults), `comparator/prepare_asreml_matfree.jl:44` (`const MU, SA, SE = 5.0, 1.0, 1.0`) —
  **not** F5 v2's `(2.0, 1.0, 1.5)`, which belongs to the low-fill half-sib family. Reusing the
  high-fill family's own truth keeps this gate's numbers directly comparable to the existing F0 /
  crossover / ASReml evidence at smaller `q`.
- **Pedigree generator — HIGH FILL, not F5 v2's half-sib.** `adversarial(q; nfounder_frac=0.005,
  seed)` (`sim/drac/f0_adversarial_fill.jl:33-49`, identical copy in
  `sim/matrix_free_crossover_benchmark.jl` and `comparator/prepare_asreml_matfree.jl:41-59`): a
  small founder base (`nf = max(4, round(0.005·q))`) plus random mating — each non-founder draws 2
  distinct parents uniformly from **all** earlier individuals. This is the exact generator that
  produced every fill/cost number in `docs/src/fitting-at-scale.md` and
  `docs/dev-log/recovery-checkpoints/2026-07-24-f0-adversarial-highfill-decision.md`. F5 v2's
  `halfsib(q)` (line 51-60 of that file) is **low fill even at q=300,000** (`~17-19`,
  `docs/src/fitting-at-scale.md`) and would not exercise the regime this fitter exists for — using
  it here would test the wrong thing.
- **Phenotype:** `simulate_y(ped; sigma_a2, sigma_e2, mu, seed)` (`sim/drac/f0_adversarial_fill.jl:53-66`)
  — gene-drop breeding values down the topologically-sorted pedigree (Mendelian-sampling variance by
  parent-known count) + Gaussian residual. Same `seed` value is reused for both `adversarial(...)`
  and `simulate_y(...)` within a replicate, matching the established convention (F5 v2 Leg B,
  `sim/phase_f5_scale_recovery_gate_v2.jl:193`; `comparator/prepare_asreml_matfree.jl`'s single
  `DATASEED` driving both).
- **Fitter call:** `fit_matrix_free_reml(spec; nprobe=64, initial=(sigma_a2=0.8, sigma_e2=0.8),
  seed=<mc_probe_seed>)`, all other keywords (`tol=1e-4, iterations=200, pcg_tol=1e-9,
  pcg_maxiter=2000, shared_probes=false, compute_loglik=true`) left at the function defaults
  (`src/iterative_solve.jl:1010-1019`) — no tuning to pass. `nprobe=64` is the function's own
  default (line 1013) and has **never been checked against an exact or external comparator in
  this regime** — the existing ASReml comparator tested `nprobe∈{128,512}`
  (`comparator/prepare_asreml_matfree.jl:44`), not the default a caller actually gets.
  `initial=(0.8,0.8)` is deliberately off-truth (truth is `(1.0,1.0)`), mirroring F5 v2's own
  practice of not starting the optimizer at the answer — unlike the F0/crossover/ASReml scripts,
  which start exactly at `(1.0,1.0)`.
- **DGP seed vs. MC-probe seed are distinct axes.** `adversarial`/`simulate_y`'s `seed` (what data
  is drawn) and `fit_matrix_free_reml`'s `seed` (which Monte-Carlo probes are drawn) are never the
  same integer, mirroring `sim/v08_s2fit_recovery_scale.jl`'s `base + s` (data) vs.
  `base + 100000 + s` (MC fit) offset pattern (see `run_recovery`, that file).

## Seeds (cold-start; UNSEEN at declaration)

- **Leg A (tail recovery, 48 seeds):** DGP seeds `20269500:20269547`; MC-probe seeds
  `20769500:20769547` (`DGP + 500,000`).
- **Leg X (agreement anchor, 8 seeds):** DGP seeds `20269200:20269207`; MC-probe seeds
  `20769200:20769207` (`DGP + 500,000`).
- **Disjointness evidence.** A file-type-restricted (`*.jl *.md *.R`, excluding data/CSV, which
  otherwise pollute the match with coincidental decimal substrings) `git grep` sweep of every
  literal 8-digit `2026xxxx` token in the tree at `origin/codex/2026-07-13-v07-performance-localization`
  found the highest occupied point in that space is exactly `20269000..20269008`
  (`comparator/prepare_asreml_matfree.jl:41,116` — `DATASEED=20269000`, MC-probe seeds
  `DATASEED+1..DATASEED+8`), with **nothing above 20269008** anywhere in `2026xxxx`. All four
  chosen endpoints (`20269200`, `20269207`, `20269500`, `20269547`) and both derived MC-probe
  endpoints (`20769200`, `20769207`, `20769500`, `20769547`) were individually re-verified with
  zero matches. Two near-misses during this search, corrected before finalizing: an initial
  `20269000`-adjacent candidate collided with the ASReml comparator's own seeds above; a
  `20263000`-based candidate collided with `sim/phase5_qtl_rebuild_production_gate.jl:64-65`
  (`20263000:20263039`, cited from `docs/dev-log/recovery-checkpoints/2026-06-30-v5-qtl-rebuild-production-gate-predeclaration.md:20-21`).
  Full occupied-block picture used to place this gate clear of everything: `0614-0630`, `0663`,
  `0678`, `0700-0747`, `0800-0847` (+ derived `20360800-20360848` via v08's own `+100000` offset),
  `0900-0984`, `1000-1149`, `2000-2011`, `3000-3039`, `4000-4200`, `5000-5047`, `6000-6047`,
  `7000-7147`, `7999-8807`, `9000-9008`. The unrelated `2027xxxxxx` (10-digit) seed family — v0.7
  genomic optimizer-localization work (`docs/design/45-v07-genomic-optimizer-localization.md`,
  `sim/phase2_v07_genomic_optimizer_localization.jl`, and the quarantined
  `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl`'s neighbors) — was identified and
  avoided entirely rather than reasoned about digit-by-digit; this gate's seeds stay inside the
  8-digit `2026xxxx` animal-model-gate convention throughout.
- `MersenneTwister(seed)` per draw, matching every cited precedent.

## PASS criteria (ALL required; NO post-hoc relaxation — `docs/dev-log/decisions/2026-06-14-calibration-failure-response`)

This gate has two legs, reusing F5 v2's letter convention where the *kind* of criterion matches:
**Leg A** (recovery — same role as F5 v2's Leg A) and **Leg X** (anchor/agreement — same role as
F5 v2's Leg X). It has **no** Leg B (deep-pedigree unbiasedness) or Leg C (near-constant-*y*
boundary) equivalent — out of scope for this predeclaration; the non-graceful-failure-rate
criterion below (A2) substitutes for a dedicated boundary leg by testing gracefulness *at* the
tail-scale interior truth, not at a separate degenerate fixture.

### Leg A — tail-scale recovery (`q = 25,000`, high fill, 48 seeds). PRIMARY.

`q = 25,000` is **not a measured value** — it is chosen because it is clearly past the dual wall
documented at `q = 20,000` (the eigen dense cap `max_dense_n=20_000`, and the exact fitter's
measured 1,529 s wall at fill 471, `docs/dev-log/recovery-checkpoints/2026-07-24-f0-adversarial-highfill-decision.md`).
The fill at `q=25,000` is **UNKNOWN** until the script measures it (via
`HSquared._sparse_mme_system` + `cholesky`, mirroring `sim/drac/f0_adversarial_fill.jl:78-81`) —
expected to exceed 471 given fill increases with `q` for this generator (measured: `50→77→149→262→471`
as `q: 1,000→2,000→5,000→10,000→20,000`, same doc), but the exact value is not claimed here. The
script must print and TSV-log the measured fill so a reader can confirm ex post that the tested
regime was in fact high-fill.

**Outcome classification — THREE-WAY, revised 2026-08-04 on Slice-B evidence** (see callout below).
Every attempted fit is classified into exactly one of:

- **(a) CONVERGED** — `fit.converged == true` (tolerance met inside the iteration cap).
- **(b) CAP-EXHAUSTED** — `fit.converged == false`, but graceful (no throw; `σ̂²a`, `σ̂²e` finite and
  `≥ 0`) — the CORRECTED Leg C boundary contract (`sim/phase_f5_scale_recovery_gate_v2.jl:139-164`)
  — **and** `fit.iterations == 200` (the pre-declared cap, see below). The script must assert this
  last equality explicitly: a graceful, non-converged fit with `iterations < 200` would be a THIRD
  failure mechanism this taxonomy has not anticipated, and must be logged as an anomaly, not
  silently folded into (b).
- **(c) NON-GRACEFUL** — threw, or returned non-finite or negative `σ̂²a`/`σ̂²e`, regardless of
  `iterations`.
- **Graceful := (a) ∪ (b).** This is the SAME boundary contract as before; it is unchanged as a
  concept but is now a necessary, not sufficient, pass condition (see A3).

> **Why three-way, and why now.** Slice-B independently reproduced the F6 in-CI fixture
> (`test/runtests.jl:4417-4446`, `fit_matrix_free_reml(specm; nprobe=256, seed=20260728)`, n=400,
> high-fill) on two Julia versions: **1.10.0** — `mf.converged=false`, `mf.iterations=200`
> (cap-exhausted), relative error to the exact fit **5.45%**; **1.12.6** — `mf.converged=true`,
> `mf.iterations=116`, relative error **0.79%**. Two consequences for this gate. First, the
> zero-boundary hypothesis behind the literature's 17.5-30.5% figure (cited above as context, not
> criterion) is **falsified for this instance** — `converged=false` here was iteration-cap
> exhaustion, not a non-positive-variance early break, so that literature figure is doubly not the
> criterion: not only would matching it be unfalsifiable (as already noted), the failure mode it
> describes is not even the one this fitter is showing. Second, and the reason the two-way
> graceful/non-graceful split from the original draft is **necessary but not sufficient**: a
> cap-exhausted fit is graceful (finite, no throw) and was going to be silently averaged into A1
> like any converged fit, at a **5.45%** individual relative error against a 5% gate — i.e. exactly
> the kind of result this leg exists to catch could have been diluted into a passing mean rather
> than surfaced. **A separate finding, orthogonal to the fix:** the dataset differs entirely between
> the two Julia versions on the identical `seed=20260728` (`sire`/`dam` hashes differ) — an
> `MersenneTwister` stream is not assumed portable across this range of Julia versions for this
> fixture. This gate cannot assume its own 48+8 seeds draw identical data across Julia versions
> either; the manifest's existing `julia=VERSION` field (mirroring `sim/v08_s2fit_recovery_scale.jl`)
> is therefore load-bearing, not decorative — any cross-machine comparison of this gate's own
> results must condition on it.

**Iteration cap: pre-declared at `iterations = 200` (the function default,
`src/iterative_solve.jl:1010`), kept deliberately, not raised.** Justification: raising it would be
tuning the fitter to pass a gate whose whole point is to test what a caller actually gets by
default — the same "no tuning to pass" reasoning already applied to `nprobe=64`. But Slice B's
116-of-200 "easy" draw shows the margin is thinner than the crossover-table evidence (which never
reports iteration counts) suggested, so this gate **measures the margin instead of assuming it**:
record `fit.iterations` for every attempted fit (Leg A AND Leg X, both `nprobe` arms), and report
the **min / median / max of the iterations-to-outcome distribution** across all 48 (Leg A) and 8
(Leg X) seeds in both the TSV and the summary table (see Output contract). Additionally, as an
**informational-only, non-gating** diagnostic: any seed landing in bucket (b) is re-fit once at
`iterations = 1,000` (same `nprobe`, same MC-probe seed) to distinguish "converges given more
budget" from "does not converge regardless" — this bears on whether a future default-cap change is
warranted, but is explicitly not part of this gate's frozen PASS/FAIL boundary.

- **A1 (PRIMARY): mean relative error vs. known truth.** Over all **graceful = (a)∪(b)** seeds,
  `|mean(σ̂²a) − 1.0| / 1.0 ≤ 0.05` **and** `|mean(σ̂²e) − 1.0| / 1.0 ≤ 0.05`. Mirrors F5 v2's
  `:relative` pass mode (`sim/phase_f5_scale_recovery_gate_v2.jl:41, 130-131, 192`) and its own
  stated reason: `|bias| ≤ 2·MCSE` is **pathological as MCSE→0** at scale (line 27 comment). Bias
  and MCSE are still computed and reported (mirroring `bias_row`, lines 106-112) but are
  **SECONDARY / informational only** — not gating. **New, informational-only breakdown:** A1 is
  ALSO reported computed over the CONVERGED-only (a) subset, so a reader can see whether
  cap-exhausted (b) seeds are pulling the mean off-target — this does not change the gating set.
- **A2 (non-graceful rate, bucket (c)): unchanged from the prior draft.** Pre-declared upper bound
  **0 out of 48** (rule-of-three upper 95% CI ≈ 6.3% at n=48 vs. ≈ 37.5% at Leg C's n=8). Reasoning
  as before: mirrors Leg C's own 100%-graceful standard; this truth is interior (h²=0.5), so a
  well-behaved fitter has no a priori reason to throw or return a non-finite/negative estimate at
  all.
- **A3 (NEW — cap-exhaustion rate, bucket (b)): a SEPARATE bound, because (b) means something
  different about the fitter than (c) does.** (c) is a correctness/robustness failure; (b) is a
  budget/tuning signal — the estimate is graceful and may even be close to truth, but is not a
  verified-converged optimum. **Pre-declared upper bound: ≤ 4 out of 48 (~8.3%).** This is stated
  as a considered, explicit judgment call, not derived from a rate estimate — Slice B supplies one
  anecdote at a different (n=400) scale, not a distribution at this gate's q=25,000 tail scale, and
  no existing precedent in this repo sets a cap-exhaustion bound to anchor to (unlike A2's Leg-C
  precedent). The reasoning: tolerate a handful of hard draws without failing the whole gate over a
  budget question rather than a correctness one, while still catching the case Slice B's own
  language warns of ("the cap margin is thinner than it appears") if it turns out to bite at a
  material rate. **Exceeding 4/48 is itself a finding** — it would mean the 200-iteration default is
  measurably insufficient at tail scale, which this gate should surface as a FAIL, not average away
  inside A1.
- **Leg A GATE = A1 ∧ A2 ∧ A3.** If A2 or A3 fails, A1 is still computed and reported (both over the
  full graceful set and the converged-only subset) for diagnosis, but Leg A fails regardless.

### Leg X — estimator-agreement anchor (`N_ANCHOR = 2,000`, high fill, 8 seeds).

Reuses F5 v2's `N_ANCHOR = 2,000` (`sim/phase_f5_scale_recovery_gate_v2.jl:45`) per the locked
design, because the exact fitter is cheap there regardless of fill (F0 doc Regime B: 1.82 s at
`q=2,000`, fill 76.6) — this is the only leg in this gate that calls `fit_ai_reml`, avoiding the
1,529 s/seed tail-scale exact cost. **Deviates from F5 v2's Leg X in two respects, both
deliberate:**

1. **Pedigree:** uses the SAME high-fill `adversarial()` generator as Leg A (at `q=2,000` instead
   of `q=25,000`), not F5 v2's `halfsib(N_ANCHOR)`. F5 v2's anchor pedigree is low-fill; anchoring
   there would not meaningfully exercise the matrix-free approximation this gate exists to check.
2. **Tolerance and summary statistic:** F5 v2's Leg X compares two **exact**, deterministic
   algorithms (eigen vs. AI-REML) with `AGREE_TOL=1e-6` on the **max** relative difference across
   seeds (lines 40, 166-182). `fit_matrix_free_reml` is **stochastic** — copying `1e-6`/max here
   would almost certainly fail a correctly-working fitter: the already-committed crossover
   benchmark shows matrix-free-vs-exact relative differences of `4.7e-3` to `1.7e-2` at
   `nprobe=64` (`docs/src/fitting-at-scale.md` crossover table, high-fill pedigrees), and the
   already-committed ASReml comparator shows matrix-free centred on the exact/ASReml answer at
   `~0.2-0.5%` relative, `nprobe∈{128,512}` (`docs/dev-log/recovery-checkpoints/2026-07-28-asreml-matfree-comparator.md`,
   Leg 2 table) — three to four orders of magnitude looser than `1e-6`. That comparator's own
   design note is directly on point: *"A Monte-Carlo estimator is not expected to hit a point
   value... A tight relative tolerance here would be meaningless"* (`comparator/prepare_asreml_matfree.jl:19-25`).

  For each of the 8 seeds: build ONE fresh high-fill dataset (fresh DGP seed, `q=2,000`), fit BOTH
  `fit_ai_reml` (exact) and `fit_matrix_free_reml` (`nprobe=64`, distinct MC-probe seed) on that
  SAME dataset, and record the paired signed relative difference `(matrix-free − exact)/exact`
  per component (structurally F5 v2's Leg X per-seed pairing, `sim/phase_f5_scale_recovery_gate_v2.jl:173-176`,
  applied to a different estimator pair). **PASS: mean |relative difference| across the 8 seeds
  ≤ `AGREE_TOL_MC = 0.05`** for both components; SD and max reported informationally (not gating —
  MAX-of-8 of a stochastic quantity is itself a high-variance statistic and an inappropriate gate
  here, per the same ASReml-comparator reasoning). `0.05` is **not** re-derived from an existing
  named constant; it is chosen with headroom above the two grounding ranges cited above (roughly
  3-25× the crossover-table range, 10-25× the ASReml gaps), loose enough to be a fair bar for MC
  noise, tight enough to be falsifiable.
- **Informational-only `nprobe` add-on** (folding in the 2026-07-28 handover's explicit ask —
  "Fold in the `nprobe`-vs-error study (64 is an untuned default)",
  `docs/dev-log/handover/2026-07-28-claude-handover.md`; also validation-debt-register.md:57 item
  (5)): on the SAME 8 datasets, additionally fit `fit_matrix_free_reml` at `nprobe=256` (a
  round intermediate point distinct from the ASReml comparator's own 128/512) and report whether
  mean |relative difference| shrinks vs. the `nprobe=64` gating run, consistent with the
  documented `∝ 1/√nprobe` expectation (`docs/src/fitting-at-scale.md`). **This does not gate
  anything** — the PASS/FAIL boundary is fixed at the untested default, `nprobe=64`.
- **Leg X GATE = mean |relative difference| ≤ 0.05 at `nprobe=64`, both components.**

**Overall GATE = Leg A ∧ Leg X.**

## Departures from the F5 v2 template, and why (summary)

| Element | F5 v2 | This gate | Why |
|---|---|---|---|
| Pedigree (Leg A / anchor) | `halfsib` (low fill) | `adversarial` (high fill) | fitter's target regime is high fill; halfsib never exercises it |
| Truth | `(μ,σ²a,σ²e)=(2.0,1.0,1.5)` | `(5.0,1.0,1.0)` | reuses the established high-fill-family convention (F0/crossover/ASReml), not the halfsib-family one |
| Leg A tolerance | `REL_TOL=0.05`, relative mode | same, unchanged | task-locked; directly mirrored |
| Non-convergence criterion | raw `converged` (Legs A/B); graceful (Leg C only) | THREE-WAY: converged / cap-exhausted / non-graceful, each Leg A, bounds on (b) and (c) separately | task-locked correction of the v1 banked-negative flaw, THEN revised again 2026-08-04 on Slice-B evidence that graceful-but-cap-exhausted is not the same claim as converged |
| Iteration cap | not addressed | pre-declared at the function default (200), kept not raised; margin measured (min/median/max iterations recorded), informational re-fit at 1,000 for cap-exhausted seeds | Slice B: 116/200 on an "easy" draw shows thinner margin than assumed; "no tuning to pass" argues against silently raising the cap |
| Anchor tolerance | `AGREE_TOL=1e-6`, max-of-seeds | `AGREE_TOL_MC=0.05`, mean-of-seeds | comparing exact-vs-exact (F5v2) is not the same statistical object as exact-vs-stochastic (here); 1e-6/max would be near-guaranteed to fail a correct implementation |
| `nprobe` reporting | n/a | default (gating) + 256 (informational) | folds in the 2026-07-28 handover's explicit ask without touching the gate |

## Run command (SMOKE first, per smoke-first discipline)

```sh
# 1. SMOKE — harness/plumbing check only. NOT feasibility evidence for q=25,000, and NOT tuned to
#    any observed result (mirrors the eigen gate's own smoke discipline). Uses q=10,000 because
#    that is an ALREADY-EVIDENCED point (matrix-free 13.9 s at fill 262, docs/src/fitting-at-scale.md
#    crossover table) — unlike F5 v2, whose SMOKE could shrink q freely because its FULL q=100,000
#    was already known-feasible from the F0 Regime-A baseline before F5 v2 committed to it. This
#    gate has NO prior matrix-free measurement above q=10,000, so the full q=25,000 commitment
#    carries genuine, currently-unquantified wall-clock risk that SMOKE at q=10,000 cannot resolve
#    (see caveat below).
env HSQ_S5_SMOKE=1 OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase_s5_matfree_tail_recovery_gate.jl smoke_s5.tsv

# 2. FULL — the pre-declared 48+8-seed evidence.
env OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase_s5_matfree_tail_recovery_gate.jl s5_recovery.tsv
```

`HSQ_S5_SMOKE=1` (naming mirrors `HSQ_F5_SMOKE`, `sim/phase_f5_scale_recovery_gate_v2.jl:42`):
`Q_TAIL_SMOKE=10,000`, 3 Leg-A seeds, `N_ANCHOR` unchanged at 2,000, 2 Leg-X seeds.

**Feasibility caveat, stated plainly.** Unlike every prior gate's Leg A, `q=25,000`'s per-seed
matrix-free wall-clock is genuinely unmeasured. The crossover table shows matrix-free scaling
roughly linearly with fill and staying cheap through `q=10,000` (13.9 s, fill 262) — informally
extrapolating that trend suggests `q=25,000` should remain on the order of tens of seconds to a
few minutes per seed, **but this is an extrapolation, not a measurement, and is not to be treated
as one.** The script should print wall-clock per seed as it runs; if the observed per-seed cost
early in the 48-seed run projects to an impractically long serial run, the correct response is to
stop and report to the maintainer, **not** to silently shrink `Q_TAIL` or the seed count — that
would be exactly the post-hoc relaxation this doctrine forbids. A revised target scale would need
its own fresh pre-declaration.

## Output contract

**STDOUT:** per-seed progress lines (mirroring F5 v2's `@printf` style), a summary table per leg
(mean/bias/MCSE/rel.err, mirroring `bias_row`), then a single `GATE_JSON {...}` line (mirroring
`sim/phase_f5_scale_recovery_gate_v2.jl:198-202`) and `exit(gate ? 0 : 1)` (line 203). Required
`GATE_JSON` fields: `gate_pass`, `version` (e.g. `"s5-draft-v2"`), `truth`, `iterations_cap`(200),
`A:{pass, pass_A1, pass_A2, pass_A3, n_converged, n_cap_exhausted, n_non_graceful, rel_sa,
rel_se, rel_sa_converged_only, rel_se_converged_only, bias_sa, mcse_sa, bias_se, mcse_se, q,
fill_measured, iters_min, iters_median, iters_max}`, `X:{pass, n, nprobe, mean_reldiff_sa,
mean_reldiff_se, sd_reldiff_sa, sd_reldiff_se, max_reldiff_sa, max_reldiff_se,
nprobe256_mean_reldiff_sa, nprobe256_mean_reldiff_se, iters_min, iters_median, iters_max}`.

**TSV file** (positional `ARGS[1]`, mirroring `sim/v08_s2fit_recovery_scale.jl`'s `main()`):
manifest comment lines (`#`) — script name + timestamp, host, `julia` version,
`OPENBLAS_NUM_THREADS`, `Q_TAIL`, `N_ANCHOR`, `iterations_cap`, seed ranges, truth, and the
PRIMARY/SECONDARY criterion text verbatim (mirroring that file's own manifest style) — followed by
two header+row blocks. `julia=VERSION` in the manifest is load-bearing (Slice B: RNG streams are
not assumed portable across Julia versions for this fixture), not decorative.

- Leg A: `seed\tdgp_seed\tmc_seed\toutcome\tconverged\titerations\tsigma_a2\tsigma_e2\trel_err_sa2\trel_err_se2\tfill\twall_s\tcapreset_iterations1000_sigma_a2\tcapreset_iterations1000_sigma_e2\tcapreset_iterations1000_converged`
  (`outcome` ∈ `{CONVERGED, CAP_EXHAUSTED, NON_GRACEFUL}`; the last three `capreset_*` columns are
  populated only for `CAP_EXHAUSTED` rows, the informational `iterations=1,000` re-fit, else blank)
- Leg X: `seed\tdgp_seed\tmc_seed64\tmc_seed256\toutcome64\toutcome256\titerations64\titerations256\tex_sa2\tex_se2\tmf64_sa2\tmf64_se2\tmf256_sa2\tmf256_se2\treldiff64_sa2\treldiff64_se2\treldiff256_sa2\treldiff256_se2`

The summary block preceding `GATE_JSON` (STDOUT and TSV trailing comment lines) must also print the
min/median/max of the `iterations` column for Leg A (all 48) and Leg X (both `nprobe` arms, 8
each) — the distribution Slice B showed cannot be assumed and must be measured.

## What PASS / FAIL means for `V1-MATFREE-REML`

**PASS** discharges validation-debt-register.md:57 item (1) ("no recovery-to-truth") and narrows
item (3) at the single `q=25,000` point tested — it does **not** close item (3) generally, item
(2)/S6 (at-scale comparator), item (4) (fill×n surface), item (5) beyond the informational
`nprobe=256` point, or item (6). It serves G11's recovery clause. It does **not** flip
`V1-MATFREE-REML` to `covered`, does not move `public_covered_count` off 5, and does not substitute
for S1-S4/S6/S7. A FRESH promote-specific Rose (S4/G8) and the maintainer's explicit G10 (S3)
remain required before any flip — exactly as `fit_ai_reml` and `fit_eigen_reml` still need theirs
after their own gates passed (both KEPT STAGED by owner choice, 2026-07-24).

**FAIL** is a banked negative: `V1-MATFREE-REML` stays exactly where it is; the already-withheld
`:auto` route stays withheld (it excludes this fitter regardless of this gate). Per the F5 v2
v1→v2 precedent (`sim/phase_f5_scale_recovery_gate_v2.jl:12-23`), a FAIL should first get a
per-seed diagnostic read to tell a genuine fitter defect from a test-design flaw in THIS gate —
but any correction requires its own fresh v2-style pre-declaration, never a post-hoc edit of this
one.

## Pre-commit smoke (functional check only — NOT the 48-seed evidence)

To be run and recorded (script output, host, Julia version, timestamp) immediately before the
actual freeze commit, mirroring the eigen gate's own smoke record
(`docs/dev-log/recovery-checkpoints/2026-07-24-eigen-reml-recovery-gate-predeclaration.md`,
"Pre-commit smoke" section) — confirming the harness runs end-to-end, emits well-formed
`GATE_JSON` and TSV, and produces finite, near-truth-ballpark, graceful fits at `q=10,000`. Not
tuned to any observed result; not acceptance evidence.

> Related: `docs/design/16-promotion-gate-predicates.md:31-35` (G11 + substitutability) ·
> `docs/design/capability-status.md:91` (`V1-MATFREE-REML` row) ·
> `docs/design/validation-debt-register.md:57` (`V1-MATFREE-REML` debt row) ·
> `sim/phase_f5_scale_recovery_gate_v2.jl` (structural template) ·
> `docs/dev-log/recovery-checkpoints/2026-07-24-eigen-reml-recovery-gate-predeclaration.md`
> (field-structure template) ·
> `docs/dev-log/recovery-checkpoints/2026-07-24-f0-adversarial-highfill-decision.md` (fill/cost
> measurements + DGP generator provenance) ·
> `docs/dev-log/recovery-checkpoints/2026-07-28-asreml-matfree-comparator.md` (external comparator
> at validation scale; SD-band precedent) ·
> `sim/v08_s2fit_recovery_scale.jl` (TSV contract + DGP/MC-seed offset precedent) ·
> `docs/src/fitting-at-scale.md` (crossover table; honest-scope fences) ·
> `docs/dev-log/handover/2026-08-04-shinichi-handover.md` and
> `docs/dev-log/handover/2026-07-28-claude-handover.md` (S5 ledger row; freeze-then-run doctrine;
> the `nprobe`-vs-error ask).
