# Hardened plan — a native R engine for `hsquared` (planning-only)

**Author:** Ada (architect), consolidating the deepened design + adversarial panel.
**Status:** DESIGN ONLY. Authorizes no implementation, no capability move, no compute run.
**Date:** 2026-07-23.
**Supersedes:** the recommendation in `native-engine-arc-design.md §8`. The beat-the-plan review found a
cheaper dominant path; per the task's mandate ("the beat-the-plan verdict may override the original TMB
recommendation"), it does — see §1.

---

## 0. Grounding integrity (read this before trusting the rest)

Consolidated from, and cited to, files on disk:
- `native-engine-arc-design.md` (the arc: TMB engine, S0–S7, reuse ledger, gates) — cited `design:NN`.
- `native-engine-recon-r1..r4.md` (hsquared surface; Julia math contract; drmTMB template; gllvmTMB Ainv) — cited `rN:NN`.
- `adv-beat-the-plan.md` — cited `beat:NN`.
- `adv-rose.md` — cited `rose:NN`.
- `adv-gauss-karpinski.md` — cited `gk:NN`.

**Two named inputs do not exist on disk** (verified by `ls`; Rose `rose:5` and Gauss `gk:6-9` independently
confirm the same absence):
- the four "deepened specs" `deep-s1-quaas-parity.md`, `deep-s2-tmb-objective.md`, `deep-s3s4-dispatch-adapter.md`,
  `deep-stage0-measurement-protocol.md` — **never produced.** The S1/S2/S3/S4/Stage-0 detail below is folded from
  the design's own slice specs (`design:136-179`) plus what Gauss re-derived directly from Julia source
  (`gk:20-79`), **not** from the missing spec files.
- `adv-fisher-curie.md` — **never produced.** The parity/fixture/external-comparator adversarial lens the task
  asked me to fold is **UNAVAILABLE.** I substitute the design's S6 parity spec (`design:166-170`) and Gauss's
  tolerance-tiering finding (`gk:70-77`); **the dedicated parity/fixture audit remains an open gap** (§7.4), and
  no "parity is designed" claim should be made until it is done.

Every inference is tagged **UNCERTAIN**. Nothing here changes any repo.

---

## 1. HEADLINE RECOMMENDATION (overrides the original TMB-full call)

**Do NOT build the full TMB engine as the next arc. Build the cheap fixes first, measure, and let the
measurement decide whether the compiled engine is ever justified.**

The collaborator's *stated* pain is exactly two symptoms: `hsquared` is **slow**, and it **crashes at genomic
G, n≈1000** (`beat:10-13`). It is not "remove the bridge" and not "I refuse to install Julia." The full TMB
program (`design` option D) spends **2–4 weeks + a permanent compiled-package CRAN/cross-platform tax**
(`design:238,249-252`) to buy three things, each of which a cheaper option already delivers:

1. a **crash fix** that is plausibly a *one-function upstream dense-routing guard* in the Julia engine (`beat:21-28`);
2. a **speed win** that is plausibly a *one-line default flip* to `fit_ai_reml`, which **already exists and is
   already the genomic default** (`beat:30-37`, `r2` via `design:46-53`);
3. **bridge removal for only 2 of 15+ estimators** — the other 13 `engine="julia"` targets stay bridged, so the
   bridge and its crash surface are **not actually removed from the package** (`beat:83-89`, `design:210-212`).

**The recommended ladder (cheapest-dominant-first):**

- **NOW → Option A (Julia-lane, days, no pivot, no CRAN tax).** Route dense `Ginv` through a dense branch in
  `HSquared.jl`; flip the pedigree default from `fit_sparse_reml` to `fit_ai_reml`; harden the bridge with a
  warm/persistent JuliaCall session (kill per-call precompile) + dense-safe marshalling. This targets **both
  stated pains directly** (`beat:43-52,106`).
- **THEN → Stage 0 measurement (§2).** The single experiment that decides everything below.
- **THEN, only if the bridge *itself* is the residual complaint → Option B (native-R AI-REML, no TMB, no
  compiled package).** Removes the bridge for the Gaussian animal model at MEDIUM cost and **zero compiled-package
  tax** — the crucial dominance point over TMB (`beat:54-69,107`).
- **Full TMB (Option D) is justified ONLY under the measured condition in §2.** Otherwise it is over-engineered
  (`beat:93-108`).

This is a demotion of the compiled engine from "recommended next arc" to "conditional endpoint," on the strength
of the adversarial finding — not a reversal of the underlying architecture, which remains sound (`gk:11,186`).

---

## 2. STAGE 0 — the non-negotiable first step (it decides everything)

**Nothing below Stage 0 may start until Stage 0 reports.** The entire speed rationale currently rests on an
**unmeasured** quantity, and on a **mis-anchored** measured one (`gk:13-17`).

### 2.1 The mis-anchoring to correct first
The only measured number — "Julia A-inverse 100k = 2.2 s" — is the **triplet builder** (`pedigree_inverse`),
**not** the per-iteration **MME sparse-Cholesky factorization** (`cholesky(Symmetric(lhs))`, `likelihood.jl:184`)
that governs REML wall-clock (`gk:113-126,170-172`). Conflating builder-time with factorization-time is "the core
over-optimism risk of the whole arc" (`gk:126`). Stage 0 must measure the **factorization**, converged, at scale.

### 2.2 The experiment (folded from the design's go-condition + Gauss's six confound controls)
Re-time the **fully converged** `fit_ai_reml` (not `fit_sparse_reml`) at 50k and 100k. Report against a stated
ASReml baseline (whose provenance must be shown, not recalled — `gk:177`). Control all six confounds (`gk:130-164`),
each of which invalidates the number if left uncontrolled:

1. **JIT / TTFX** — warm up; discard the first (compiling) call.
2. **Symbolic-analysis-per-iteration** — `_sparse_mme_system` rebuilds `lhs` and re-runs CHOLMOD symbolic analysis
   every iteration (`gk:140-146`). State whether you are measuring "is *current* `fit_ai_reml` ASReml-fast?" (it
   is) vs "could a native engine be?" (needs analyze-once) — they are different questions.
3. **Thread count** — Totoro pins `OPENBLAS_NUM_THREADS=1`; ASReml is multi-threaded. Fix and report both.
4. **Pedigree structure realism** — fill-in depends on depth/connectivity. Use a **real or realistically deep**
   pedigree; a shallow simulated one gives an optimistic number that won't generalize.
5. **Full-convergence, not one iteration ×N** — time the converged fit at matched tolerance from a comparable start.
6. **Sparse-pedigree vs dense-genomic timed SEPARATELY** — two experiments, reported apart; they are different
   bottlenecks (§7.2).

Add one confirmatory sub-experiment: **reproduce the collaborator's n≈1000 GBLUP crash and profile it**
(`gk:99,192`; `design:263-265`) — because the stated "dense-`Ginv`-through-sparse-Cholesky" mechanism is
**quantitatively implausible** at n=1000 (a 1000×1000 dense Cholesky is ~8 MB / milliseconds; CHOLMOD goes
supernodal-dense, it does not crash — `gk:90-102`). Do not claim any fix for a crash whose mechanism is unconfirmed.

Cost: ~1 session on Totoro (`design:303`). This is cheap and could reframe the entire arc.

### 2.3 THE DECISION HINGE (the measured condition that alone justifies full TMB)

> **Build the full TMB engine (Option D) only if Stage 0 shows the wall-clock gap to ASReml SURVIVES both cheap
> fixes — i.e. `fit_ai_reml` (and, by extension, a pure-R analytic AI-REML, Option B) still misses ASReml-class
> speed because the cost is in the per-iteration sparse factorization / selected-inverse ITSELF, not in the
> derivative-free wrapper or the dense-`Ginv` bug — AND the roadmap commits to non-Gaussian / Laplace families
> where no closed-form AI-REML gradient exists** (`beat:111-118`; `r2` non-transfer via `design:213-216`, `gk:70`).

- If Stage 0 shows `fit_ai_reml` **already at ASReml-class speed** → Option A alone likely closes the case; **do
  not build TMB** (`beat:117-118`).
- If the gap survives but the roadmap stays **Gaussian-only** → Option B (native-R AI-REML) captures bridge
  removal **without** the compiled-package tax; **still do not build TMB** (`beat:100-103`).
- Only **both** conditions together earn the compiled-AD tax.

---

## 3. The four options, scored (from beat-the-plan; this is the menu the owner is choosing among)

| Option | Crash | Speed | Bridge | Cost | Pivot? | CRAN tax? |
| --- | --- | --- | --- | --- | --- | --- |
| **A** Julia dense-`Ginv` fix + `fit_ai_reml` default + bridge warm-start | FIXED | LIKELY FIXED (measured-conditional) | HARDENED, not removed | LOW (days) | No | No |
| **B** Minimal native-R AI-REML (`Matrix::Cholesky`, no TMB) | FIXED (Gaussian) | CONDITIONAL | **REMOVED** (Gaussian) | MEDIUM | No | **No** |
| **C** Thin native GBLUP-only path | FIXED | unhelped for pedigree | removed (GBLUP only) | LOW–MED, NARROW | No | (compiled if TMB) |
| **D** Full TMB engine (S0–S7) | FIXED | FIXED (Gaussian) | removed for 2/15+ | HIGH (2–4 wk) | **Yes** | **Yes, permanent** |

Verdicts (`beat:93-109`): **A dominates for the two stated pains.** **B dominates D for bridge removal on the
common model** — it removes the bridge *without* the compiled-package tax that is D's worst permanent cost.
**C is strictly dominated** (A fixes the same crash more cheaply with one code path). **D earns its tax only under
§2.3.**

---

## 4. The recommended path, in detail

### 4.1 Option A — do this first (Julia lane + R bridge; days)
- **Dense-`Ginv` guard:** in `HSquared.jl`, route a dense `Ginv = inv(G+ridge·I)` through a dense factorization
  branch instead of `sparse(...)`→sparse-Cholesky (`beat:43-46`; the same guard S5 prescribes, applied upstream).
  **Gate:** only after §2.2 profiling confirms the actual crash mechanism (`gk:99`) — the fix must match the
  measured cause, not the inferred one.
- **Default flip:** make `fit_ai_reml` the default on the pedigree animal-model path (it is already the genomic
  default; `beat:33-37`). Gated on the §2 timing.
- **Bridge hardening:** persistent/warm JuliaCall session to remove per-call precompile; dense-safe marshalling
  (`beat:47-52`). This attacks the R-crash instability directly — which, per Gauss, is a **more plausible crash
  culprit at n=1000 than fill-in** (`gk:96-98`).
- **Boundary:** this is **Julia-lane + R-bridge** work. The current session is the Julia lane; the bridge/default
  edits touch `HSquared.jl`, the R-side warm-session touches `hsquared` — coordinate the twin boundary before
  starting (`design:266-267`; CLAUDE.md lane rule).

### 4.2 Option B — the right *second* arc if the bridge itself is the residual pain (native-R, no compiled package)
- **Reuse (already pure R):** the Quaas `A⁻¹` builder is *already pure-R* in gllvmTMB (`Matrix::sparseMatrix`
  triplets, no inversion, MCMCglmm-validated — `r4:7-39,131-135` via `beat:57-58`); `Matrix::Cholesky` already
  factors sparse precision (drmTMB path-4 precedent, `beat:59-60`).
- **The only new piece:** transcribe `HSquared.jl`'s closed-form AI-REML **score + AI information** (`r2` via
  `beat:60-64`) into ~200–400 lines of R with an analytic Newton step. Risk: hand-coded gradients have **no AD
  safety net**, and the Takahashi selected-inverse trace term in pure R is fiddly — but `sommer`/`pedigreemm`
  (already in `Suggests`, `r1:154-166`) do exactly this in R, and the Julia reference is a **term-by-term test
  oracle** (symbolic-alignment discipline, `beat:62-64`).
- **Why B beats D here:** removes the bridge for the Gaussian animal model **without** turning `hsquared` into a
  compiled CRAN package — the permanent Windows/macOS toolchain + compiled-code scrutiny (`design:249-252`)
  **evaporates** (`beat:66-69`).

### 4.3 Option D — full TMB, only if §2.3 holds. Specs in §5.

---

## 5. IF TMB proceeds (§2.3 met): the staged program, with deepened specs + all corrections folded

Architecture is unchanged and sound (`gk:11,186`): TMB (`MakeADFun`, Laplace + `nlminb`) on the univariate
Gaussian animal model, matching the whole-stack convention (drmTMB/gllvmTMB `LinkingTo: RcppEigen, TMB`).
Reuse ledger unchanged from `design:96-108`. Corrections below are load-bearing.

### S0 — Decision record + evidence-boundary codification (docs)
- Out: a `docs/dev-log/decisions/` entry for D-NATIVE-R-ENGINE; **repo-codify D-176** (native evidence → native
  rows only; it is currently brain-side, not repo text — `design:31-33`, `r4:93-97`); a *planned* capability row
  `native_r_tmb_animal_model = planned` + validation-debt row.
- **CORRECTION (Rose `rose:50`):** S0 is **NOT** "dep: none." Its real precondition is **owner authorization of
  the D-2026-06-12 pivot** (§8). State that.
- **CORRECTION (Rose `rose:51`):** S0's deliverables (decision record, capability row) live in the **R repo
  `hsquared`**, not this Julia repo. The current session is the Julia lane — "do not edit the R repo from here"
  (CLAUDE.md) applies; S0 is an R-lane deliverable.

### S1 — Sparse Quaas `A⁻¹` builder in R
- Port gllvmTMB `pedigree_to_Ainv_sparse()` (`R/pedigree-precision.R:170-214`) with provenance comment +
  `inst/COPYRIGHTS`; validate against `nadiv::ainverse()` / `MCMCglmm::inverseA()$Ainv` (`design:136-140`).
- **Effort:** small — algorithm handed over, pre-validated. **Deep-spec caveat:** the intended
  `deep-s1-quaas-parity.md` was never written; the parity fixtures/tolerances for this step are **not deepened** —
  treat the parity design as TODO, not done.

### S2 — Gaussian animal-model TMB template (`src/hsquared.cpp`)
- Objective: joint `nll = −log p(y|β,u,θ) − log p(u|θ)` matching `sparse_reml_loglik` (`r2` via `design:141-145`).
- **MAJOR RECALIBRATION (Gauss `gk:20-51`):** the design says "getting logdetC/quad to agree is the real work"
  (`design:231,247`) — this **over-claims the math as hard.** Gauss *derived* the equivalence: for a Gaussian
  response + Gaussian prior + linear predictor the joint is exactly quadratic in (β,u), **Laplace is exact**, and
  with β folded into `random=` the Hessian **is** the MME coefficient matrix `C` exactly, so `−log L_TMB` equals
  the Julia REML objective **term for term** (logdetC and quad included; logdet is permutation-invariant so
  CHOLMOD vs AMD ordering agree to machine precision). **S2 is not hard math; it is getting two conventions
  right.** Recalibrate S2 effort down on the math, and toward the two **silent** convention traps:
  1. **log-variance vs log-SD factor-of-2 (HIGH-likelihood porting bug, `gk:54-61`).** drmTMB's reusable block
     writes `2·n·log_sd` and scales by `exp(−2·log_sd)` because its parameter is an **SD**. S2 declares params as
     **log σ²**. Copying drmTMB verbatim gives `2nℓ` (doubles logdetG) and `exp(−2ℓ)` (squares precision) — the
     fit still "converges," to the **wrong variance.** Assert `n·ℓ` and `exp(−ℓ)` term-by-term in the
     symbolic-alignment table **before** writing C++.
  2. **β must be in `random=` or you compute ML, not REML — silently (`gk:62-68`).** The X-block of `logdetC` *is*
     the REML adjustment; TMB reproduces it only by integrating β over a flat prior. β must carry **no** prior/ridge.

### S3 — R wrapper + `hs_control(engine="tmb")` dispatch
- Consume the existing engine-agnostic `spec`/`payload` unchanged (`r1:184-187`); reuse drmTMB `MakeADFun` loop
  skeleton + `nlminb` retry ladder (`r3:52-85`). Return the same `hsquared_fit` shape.
- **Deep-spec caveat:** `deep-s3s4-dispatch-adapter.md` was never written — the dispatch-branch and result-adapter
  field mapping are specified only at the design's level (`design:116-121`), not deepened.

### S4 — REML + `sdreport` → variance components / EBVs / intervals
- Reuse drmTMB `sdreport` + `parList` split (`r3:88-101`); produce the 8 required result fields + optional
  PEV/reliability/heritability_interval/SEs (`design:152-155`).
- **CORRECTION (Gauss `gk:70-77`) — tolerance tiers, fold into S6:** point estimates and EBVs agree to **tight**
  tolerance (same optimum, same MME solve); **SEs and PEV agree only to a LOOSER tolerance by construction** —
  TMB `sdreport` (delta method on inverted joint Hessian) vs Julia's explicitly-built AI information matrix are
  asymptotically equivalent but differ at the 3rd–4th digit. Splitting this is a design requirement, not a bug
  budget. The design's "loglik, variance components AND EBVs to agree to tolerance" (`design:247`) must be split.

### S5 — Genomic GBLUP native path
- **CORRECTION (Rose `rose:40-44`):** the design says "GBLUP via the *same* template … S2/S3/S4 path unchanged"
  (`design:157-163`) — this **contradicts itself** in the same slice, because it also requires routing dense
  `Ginv` through a **dense** branch. S2's template is authored for `DATA_SPARSE_MATRIX`. Restate as: **"S2 template
  EXTENDED with a dense branch (`DATA_MATRIX` + dense quadratic form → TMB dense Cholesky); S3/S4 wrapper reused;
  the dense branch carries its OWN fixture + parity check."** It is load-bearing, not cosmetic (`gk:83-88`), and
  its effort is under-counted as "small–medium" (`rose:44`).
- **CORRECTION (Gauss `gk:104-111`) — scaling ceiling, must be stated:** dense `Ginv` is O(n²) memory / O(n³)
  time. n=10k → 0.8 GB, seconds; **n=100k → 80 GB, infeasible.** The dense branch is correct for
  **moderate G only.** 100k genomic needs the marker-dimensioned **SNP-BLUP / RR-BLUP** path (`fit_snp_blup`) —
  which the design scopes **OUT** (`design:213-216`) while also naming 100k genomic as a target. **Resolve the
  tension explicitly:** native dense GBLUP covers moderate G; 100k genomic is out of scope for this arc (needs
  SNP-BLUP or APY).
- **Do S5 only after S1–S4 validated** (`design:164`).

### S6 — Parity + external-comparator tests (the slice that lets a row move off `planned`)
- Native-TMB fit matches (a) `HSquared.jl` to tolerance and (b) an external comparator (`nadiv` for `A⁻¹`;
  ASReml/`sommer`/`pedigreemm` for variance components + EBVs) (`design:166-170`). Apply the S4 tolerance tiers
  (tight: loglik/EBV/point estimates; loose: SE/PEV).
- **GAP (Fisher/Curie lens missing, §0):** the dedicated parity/fixture adversarial spec was never produced. This
  slice's fixture design, comparator provenance, and tolerance thresholds are **NOT independently audited.** No
  `experimental→covered` move may rest on S6 until that audit exists.

### S7 — AI-REML / scale story (optional, Gaussian-only by construction; `design:172-177`, `r2` non-transfer `gk:70`).

**Critical path:** S0 → S1 → S2 → S3 → S4 → S6; S5, S7 branch after S4; S1 ∥ S2 after S0.

---

## 6. Rose overclaim fixes — applied (checklist)

1. **§5-item-2 bottleneck mis-attribution (`rose:25-32`) — APPLIED.** "Precomputing `Ainv`+`log_det` is the
   specific mechanism" is **false as the primary claim.** The measured bottleneck is re-factorizing the MME
   coefficient matrix `C` every eval; `C` depends on the variance ratio and **cannot be precomputed**.
   Corrected mechanism: *gradient-based outer optimization (few evals) vs NelderMead's derivative-free simplex
   (many evals); each eval still factorizes the MME once — structurally comparable to Julia's existing
   `fit_ai_reml`, so any per-iteration speed edge over a `fit_ai_reml`-defaulted Julia path is unproven, and the
   native-only durable win is **bridge removal**.* (This is why §1 demotes speed to conditional.)
2. **">7 min timeout" clause (`rose:34-38`) — APPLIED.** Dropped from any mechanism sentence; it reads as an
   implicit wall-clock promise the native path has not measured. Keep the architectural point (not-NelderMead)
   without importing the number.
3. **S5 "path unchanged" self-contradiction (`rose:40-44`) — APPLIED** in §5-S5 above.
4. **S0 dependency (`rose:50`) — APPLIED:** S0's precondition is the owner pivot decision, not "none."
5. **S0 lane ownership (`rose:51`) — APPLIED:** S0 deliverables target the R repo `hsquared`.
6. **D-176 not-yet-repo-codified (`rose:52`) — KEPT** as an S0 deliverable, not asserted as existing.

What the design got right and must NOT be diluted (`rose:57-62`): the correction box pre-empting "Julia has no
fast REML"; the evidence boundary (`public_covered_count` stays 5); the pivot handled as an explicit owner
decision; the scope ceiling (Gaussian animal model + GBLUP only). These carry forward intact.

---

## 7. Verification section + risks (Gauss/Karpinski numerics + parity)

### 7.1 The core over-optimism risk (Gauss `gk:13-17,113-126`)
The speed case rests on an **unmeasured** MME sparse-Cholesky **factorization** cost, mis-anchored to the
A-inverse **builder** time (2.2 s/100k). **No "ASReml-class speed" claim may be made** until Stage 0 measures the
factorization, converged, on a realistic pedigree, with the six confounds controlled. Verification gate for any
speed claim = Stage 0 (§2), not design.

### 7.2 Dense-GBLUP risks (Gauss `gk:83-111`)
- Dense branch architecturally correct but the **crash mechanism is quantitatively implausible at n=1000**
  (`gk:90-102`) — reproduce/profile before claiming the fix (folded into §2.2). More plausible culprits: bridge
  marshalling; a true scale larger than n=1000; a CHOLMOD symbolic-analysis pathology.
- Dense branch has an **unstated 100k ceiling** (80 GB) — state that native dense GBLUP is moderate-G only (§5-S5).

### 7.3 Objective-parity risks (Gauss `gk:52-77`)
- S2 convention trap 1: log-variance vs log-SD factor-of-2 (silent wrong variance) — assert term-by-term first.
- S2 convention trap 2: β in `random=` and prior-free, or you silently compute ML not REML.
- SE/PEV tolerance is looser than point-estimate tolerance **by construction** — tier the S6 checks.

### 7.4 Parity-audit gap (Fisher/Curie lens missing, §0)
The external-comparator/fixture parity design was **not independently adversarially reviewed** — the intended
`adv-fisher-curie.md` was never produced. **Open action:** commission that audit before S6 is used to move any
capability row. Until then, S6 parity is a *plan*, not a *validated design*.

### 7.5 Compiled-package + pivot risk (see §8).

### 7.6 Effort totals
Self-flagged as inference, not measurement (`design:238-240`); acceptable with the flag. Note S2's math effort
is **lower** than the design states (`gk:49-50`) and S5's dense-branch effort is **higher** (`rose:44`) — the two
corrections partially offset.

---

## 8. Claim ceiling, pivot decision, compiled-package tax

- **Claim ceiling:** `public_covered_count` stays **5**. No capability moves on design or on Options A/B/D alone.
  A native row is born `planned` (S0) and can only reach `covered` after S6 produces its **own** validation
  evidence (D-176; `design:206-209`). Scope ceiling: univariate Gaussian animal model + GBLUP only; the 15
  `engine="julia"` estimators stay Julia-only; a `partial` row must state what it does NOT cover
  (`design:213-216`). **No** `backend`/`accelerator`/GPU claim.
- **Pivot decision (owner-only):** Options A and C require **no** founding-decision pivot. **Option B pivots
  D-2026-06-12 partially** (a native R engine exists, but pure-R, no compiled dependency). **Option D fully
  pivots** D-2026-06-12 *and* turns `hsquared` from pure-R into a **compiled** package. The pivot is an explicit
  owner decision, gated, never started on momentum (`design:9-18,284-285`).
- **Compiled-package tax (the decisive cost asymmetry):** Option D's `LinkingTo: RcppEigen, TMB` + `src/` is a
  **permanent** Windows/macOS toolchain + compiled-code CRAN-scrutiny burden (`design:249-252`) — the single
  biggest ongoing cost, and the one the original pure-Julia-bridge design was specifically avoiding. **Option B
  removes the bridge for the Gaussian model without incurring it** (`beat:66-69`). This asymmetry is why B
  dominates D whenever the roadmap is Gaussian-only.

---

## 9. DECISION MENU FOR THE OWNER

Three real choices (C is dominated, excluded). Ada's ranking is the order shown.

**Choice 1 — CHEAP FIRST (Ada's #1 recommendation).**
Run **Stage 0** (§2, ~1 session, Totoro), then ship **Option A** (Julia dense-`Ginv` guard + `fit_ai_reml`
default + bridge warm-start). Fixes both *stated* pains in **days**, **no pivot, no CRAN tax.**
→ *Choose this unless you already know the bridge itself (Julia install / structural R crashes) is the pain you
must remove.* It is the highest-value, lowest-regret move, and Stage 0 is a prerequisite for everything else anyway.

**Choice 2 — REMOVE THE BRIDGE CHEAPLY (Ada's #2, the right *second* arc).**
After Choice 1, if the residual complaint is the bridge itself, build **Option B** (native-R AI-REML, no TMB).
Removes the bridge for the Gaussian animal model at MEDIUM cost with **zero compiled-package tax.** Partially
pivots D-2026-06-12 but keeps `hsquared` pure-R.
→ *Choose this over full TMB whenever the roadmap stays Gaussian-only.*

**Choice 3 — FULL TMB ENGINE (Ada's #3, conditional endpoint — not the next arc).**
Build **Option D** (S0–S7, §5) **only if Stage 0's §2.3 hinge holds**: the ASReml gap survives both cheap fixes
(cost is in the per-iteration factorization itself) **AND** the roadmap commits to non-Gaussian/Laplace families
where no closed-form AI-REML gradient exists. Costs 2–4 weeks, a full founding-decision pivot, and a **permanent**
compiled-package tax.
→ *Choose this only when both measured + roadmap conditions are met; otherwise it is over-engineered.*

**Ada's bottom line:** Choice 1 now (it is also the measurement gate). Let Stage 0's number and the roadmap's
family-scope decide between stopping at Choice 1, advancing to Choice 2, or — only if §2.3 truly holds —
committing to Choice 3. Ranked against the D1 genomic-recovery go/no-go the owner is also weighing, this ladder
is still the **higher-value, more-legible R-lane arc** (it targets a live collaborator complaint on a proven
reuse base, `design:290-300`) — but its *cheap rungs*, not the full compiled engine, are what to start.

---

*Planning only. No implementation, no capability-status move, no compute run. Every architectural claim is cited
to the design, recon r1–r4, or an adversarial file on disk; inferences (dense-`Ginv` crash, `fit_ai_reml`
scaling, effort totals) are flagged UNCERTAIN and must be measured. Two named inputs (the four `deep-*` specs and
`adv-fisher-curie.md`) were never produced — the S1/S2/S3/S4/Stage-0 detail is folded from the design + Gauss's
re-derivation, and the parity audit remains an open gap (§7.4).*
