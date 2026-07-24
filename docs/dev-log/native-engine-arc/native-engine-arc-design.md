# Arc design — a native R engine for `hsquared` (planning-only)

**Author:** Ada (architect lens). **Status:** DESIGN ONLY — authorizes no implementation, no capability move, no compute run.
**Date:** 2026-07-23. **Grounding:** brain findings (D-2026-06-12, D-176) + recon R1–R4 (cited `file:line`).
**Boundary held:** every architectural claim below is tagged to a recon file or a brain finding; inferences and unverified points are marked.

---

## 1. Decision framing — this is a deliberate PIVOT of D-2026-06-12

The founding decision **D-2026-06-12 "Two Repos, One Identity"** set the contract: `hsquared` owns the
R applied-user surface; `HSquared.jl` owns the engine; the R frontend selects the Julia engine via
`hs_control(engine = "julia")` over a `JuliaCall` bridge (brain finding; corroborated by recon R1 —
`hs_control()`'s `engine` arg is the closed enum `c("fit","validate","julia")`, R1:57-58, and the default
`engine="fit"` path *errors with install instructions* when Julia is absent, i.e. **there is no R-native
fallback today**, R1:47-49). "No native R engine" was a design choice, not an oversight.

**This arc proposes a new decision (call it D-NATIVE-R-ENGINE) that changes that.** State it plainly:

- **What it CHANGES:** `hsquared` gains a *native, self-contained* R/TMB fitting engine, selectable as a
  new `engine=` value (e.g. `"tmb"`). The R package can fit the Gaussian animal model **without** JuliaCall,
  Julia, or `HSquared.jl` installed. This is a genuine architecture change: recon R1 confirms the new engine
  value is *new API surface*, not a flip of an anticipated-but-undispatched switch — `backend`/`accelerator`
  are undispatched metadata, not an engine slot (R1:118-126, R1:206-209).
- **What it PRESERVES (non-negotiable):**
  1. **The Julia bridge stays** as an *alternate* engine (`engine="julia"`/`"fit"`), not removed. Two engines,
     tracked as **separate capability-status rows** with **separate evidence chains** (recon R4:109-127; this
     is exactly how gllvmTMB/GLLVM.jl and drmTMB/DRM.jl keep separate dev-logs and a named cross-twin wording
     contract). The Julia engine remains the reference for anything the native engine does not yet cover.
  2. **The R-public / Julia-engine EVIDENCE boundary (D-176) stays.** Native R/TMB evidence supports native-R
     capability rows *only*; direct Julia evidence supports Julia rows *only*; neither transfers (recon
     R4:109-118, restating D-176; note R4:93-97 found D-176 is brain-side, not yet repo-codified — this arc
     should codify it as repo text when it lands).
  3. **The frontend contract is untouched.** `hs_build_model_spec()` and `hs_build_bridge_payload()` are
     engine-agnostic today and need no change (recon R1:184-187); the native engine consumes the *same* `spec`
     and returns the *same* `hsquared_fit` object shape (R1:80-101).

**Why pivot at all — the trigger (measured):** today's triage found the Julia A-inverse is fast
(800=3 ms, 100k=2.2 s) but the **REML fit is the bottleneck** — `fit_sparse_reml` uses a derivative-free
NelderMead that re-factorizes the sparse Cholesky MME every evaluation, timing out >7 min by 50k vs ASReml
~2 s/100k (brain finding; recon R2:121-133 confirms the re-factorize-every-eval structure). Compounding it,
the R user hits the **JuliaCall bridge** — extra overhead and instability that can crash R (brain finding;
szymekdr reports `hsquared` slow + crashes at moderate G). A native engine attacks *both*: it removes the
bridge and it can carry a Newton/Laplace fit path instead of derivative-free search.

> **Correction to the trigger premise, from recon R2 (important, do not overstate the gap):** `fit_ai_reml`
> **already exists** in the Julia engine (R2:131-162) — a genuine average-information Newton method, one
> sparse Cholesky per iteration, and it is the *default* for the genomic REML paths (R2:164-168). So the
> honest framing is **not** "Julia has no fast REML"; it is (a) the R user cannot reach *any* engine without
> the bridge, and (b) the derivative-free `fit_sparse_reml` is still the default on the *pedigree* animal-model
> path. Whether `fit_ai_reml` already closes the 50k–100k gap was **not** re-timed in recon (R2:170-178,
> R2:222-224 — flagged UNCERTAIN). This matters for the recommendation (§8): part of the win may be achievable
> *inside Julia* by defaulting the pedigree path to `fit_ai_reml`, without a native engine at all.

---

## 2. Engine choice — TMB, and why (argued)

**Recommendation: TMB (C++ autodiff via `TMB::MakeADFun`), not pure-R `Matrix`/CHOLMOD.**

The animal model is a **Gaussian LMM with a single sparse-precision random effect** (`u ~ N(0, σa² A)`,
precision `Ainv/σa²`; recon R2:27-73). That is TMB's core competency and exactly the shape drmTMB and gllvmTMB
already solve.

**How much the siblings hand you for free (this is mostly assembly, not invention):**

- **drmTMB's precomputed-sparse-precision TMB pattern is directly reusable** (recon R3:22-51): `model_type==99`
  assembles `-log p(u|θ)` from a `DATA_SPARSE_MATRIX(Q)` + `DATA_SCALAR(log_det_Q)` passed *in from R* —
  quadratic form + AD only, precision never re-derived inside the tape (R3:40-51, R3:150-156). This is precisely
  the shape that fixes the measured re-factorize-every-eval bottleneck.
- **drmTMB's REML-via-marginalization + fit loop is a working, tested skeleton** (recon R3:52-101): REML =
  fold fixed effects into `random=` (Cox–Reid/Laplace joint-marginal, R3:72-78); `MakeADFun` once (R3:59-68);
  `nlminb` with a preset-retry ladder + optional multistart (R3:80-85); `sdreport()` for variance-component
  and BLUP uncertainty (R3:88-101). This is the "AI-REML-equivalent fast fit path" the R side lacks (R3:157-160).
- **gllvmTMB hands you the sparse Quaas A-inverse builder** (recon R4:7-39): `pedigree_to_Ainv_sparse()` /
  `.gllvm_pedigree_precision` builds `A⁻¹` by sparse-triplet accumulation with **no matrix ever inverted**,
  already MCMCglmm-free and already validated against `MCMCglmm::inverseA()$Ainv` (R4:11-14, R4:131-135).

**Why not pure-R `Matrix`/CHOLMOD:** you *could* hand-write REML in R with `Matrix::Cholesky` on the MME and a
NelderMead/Newton loop — but you would be re-deriving gradients by hand (error-prone) or falling back to
derivative-free search (the exact bottleneck we are fleeing). TMB gives exact AD gradients + the Laplace
marginal for free, and it is **the whole-stack convention** — drmTMB, gllvmTMB both use `LinkingTo:
RcppEigen, TMB` (R3:135-137, R4:64). Matching the stack means the CRAN build machinery, the fit-loop idioms,
the `sdreport` extraction, and the C++ helper-porting precedent (R4:145-150) all transfer. A pure-R engine
matches *nothing* and would still need CHOLMOD-quality sparse factorization to be competitive.

**The one genuine caveat for TMB (from recon R2):** TMB's default is **Laplace + `nlminb`/L-BFGS on the joint
NLL**, which finds the REML optimum by a *different, standard* route than the Julia engine's closed-form
Gaussian **AI-REML** score/information formulas (R2:211-218). The Julia docstring is explicit these are **not**
interchangeable outside the exact Gaussian linear model (R2:156-158). Consequence: for the Gaussian animal
model, TMB will land on the same optimum but with a different per-iteration cost profile than ASReml's AI-REML;
matching ASReml *wall-clock* is a claim to be *measured*, not assumed (see §7 risks, §5 what-this-fixes).

---

## 3. Reuse ledger (co-opt aggressively; cite the evidence)

| Component | Source | Reuse verdict | Evidence |
| --- | --- | --- | --- |
| Sparse Quaas `A⁻¹` builder | gllvmTMB `R/pedigree-precision.R:170-214`, exposed `pedigree_to_Ainv_sparse()` `R/animal-keyword.R:569-611` | **Port near-verbatim** (with provenance comment + `inst/COPYRIGHTS`, the precedented pattern) | R4:7-39, R4:131-135, R4:145-150 |
| Sparsity-preserving handoff to TMB | gllvmTMB `.gllvmTMB_maybe_keep_sparse_ainv` `R/animal-keyword.R:632-641` | **Reuse pattern** — keep `Ainv` sparse construction→`DATA_SPARSE_MATRIX`; densify only if user supplied dense | R4:84-89, R4:136-139 |
| Precompute `log_det` R-side, pass as TMB data | gllvmTMB `src/gllvmTMB.cpp:297-314`; drmTMB `src/drmTMB.cpp:350-351` | **Reuse pattern** — avoids re-deriving logdet in the AD tape (attacks the measured bottleneck) | R4:140-143, R3:44-51 |
| `-log p(u|θ)` sparse-precision NLL block | drmTMB `src/drmTMB.cpp:671-685` (`model_type==99`) | **Adapt** — same quadratic-form-from-precomputed-precision block, `u`=animal effects | R3:22-51 |
| `MakeADFun(random=)` + REML-by-marginalization | drmTMB `R/drmTMB.R:470-477`, `:858-898` | **Adapt** — fold `β` into `random=` for REML | R3:52-78 |
| `nlminb` preset-retry ladder + multistart | drmTMB `R/drmTMB.R:602-680` | **Reuse skeleton** | R3:80-85, R3:157-160 |
| `sdreport()` → variance-component / BLUP SEs + intervals | drmTMB `R/drmTMB.R:2399-2453`, `:489-517` | **Reuse skeleton** — gives PEV/reliability/heritability_interval fields | R3:88-101 |
| `spec`/`payload` construction (formula parse, `X`/`Z` assembly) | hsquared `R/model-spec.R`, `R/bridge-payload.R:33-40,63-65,162-192` | **Reuse unchanged** — engine-agnostic; `Z` already `Matrix::sparseMatrix`, `X` dense | R1:184-187, R1:129-136 |
| `hsquared_fit` object + extractors + evolvability | hsquared `R/fit-object.R:1-29`, `R/extractors.R`, `R/evolvability.R` | **Reuse unchanged** — native engine must only produce the same `result` shape | R1:80-101, R1:200-205 |

**What is genuinely NEW for hsquared (the invention, not the assembly):**

1. **A new `src/*.cpp` TMB template specialized to the univariate Gaussian animal-model REML identity** of
   `sparse_reml_loglik` (recon R2:39-73) — `-½[(n-p)log2π + logdetR + logdetG + logdetC + quad]`. drmTMB's
   template is close in *pattern* but its objective is DRM/phylo-shaped; the hsquared objective and its EBV
   split (R2:56-64) must be written to match the Julia estimand term-by-term.
2. **The `engine="tmb"` dispatch branch** in `hsquared()` — new API surface (R1:118-126, R1:183-187).
3. **A result-payload adapter** mapping TMB `sdreport`/`parList` output → the exact `hs_normalize_julia_result`
   shape (R1:200-205): `variance_components`, `heritability`, `breeding_values`, `fixed_effects`,
   `random_effects$animal`, `loglik`, `df`, `nobs`, `predictions`, `diagnostics`, `converged` (+ optional
   `prediction_error_variance`, `reliability`, `heritability_interval`, SEs). Eight of these are *required* for
   `print`/`summary` (R1:99-101).
4. **`TMB`/`RcppEigen` added to `DESCRIPTION` `LinkingTo`/`Imports`** — none exist today (R1:168-171); this is a
   real CRAN-surface change (compiled code), the biggest new build/maintenance obligation.

---

## 4. Slices (ordered, dependency-annotated)

Each slice: **in → out → reuses → dep**. Sizes are order-of-magnitude, not commitments.

- **S0 — Decision record + evidence-boundary codification** (planning/docs).
  in: this design; out: a `docs/dev-log/decisions/` entry for D-NATIVE-R-ENGINE + a repo-codified D-176
  evidence-boundary note (R4:93-97 flagged it is not yet repo text); a new *planned* capability-status row
  `native_r_tmb_animal_model = planned` + validation-debt row. reuses: —. **dep: none. Gate for everything below.**

- **S1 — Sparse Quaas `A⁻¹` builder in R.**
  in: pedigree (`spec$random$animal`); out: sparse `dgCMatrix` `A⁻¹` + `log_det`, validated against
  `nadiv::ainverse()` and/or `MCMCglmm::inverseA()$Ainv`. reuses: gllvmTMB `R/pedigree-precision.R:170-214`
  (port + provenance). **dep: S0.** *(This is the single largest missing R-native math component, R1:74-77.)*

- **S2 — Gaussian animal-model TMB template (`src/hsquared.cpp`).**
  in: `y, X, Z, DATA_SPARSE_MATRIX(Ainv), DATA_SCALAR(log_det_Ainv)`, params `β, u, log σa², log σe²`;
  out: joint NLL matching `sparse_reml_loglik` (R2:39-73). reuses: drmTMB `src/drmTMB.cpp:671-685` pattern +
  gllvmTMB logdet-as-data pattern. **dep: S0 (S1 supplies the data at runtime, S2 can be authored in parallel
  against a fixture `Ainv`).**

- **S3 — R wrapper + `hs_control(engine="tmb")` dispatch.**
  in: `spec`/`payload` from the existing frontend; out: a fit that returns the *same* `hsquared_fit` shape
  (R1:80-101). reuses: hsquared `spec`/`payload` unchanged (R1:184-187) + drmTMB `MakeADFun` loop skeleton
  (R3:52-85). **dep: S1, S2.**

- **S4 — REML + `sdreport` → variance components / EBVs / intervals.**
  in: fitted `obj`; out: the required 8 result fields + optional PEV/reliability/heritability_interval/SEs.
  reuses: drmTMB `R/drmTMB.R:2399-2453` `sdreport` + `parList` split (R3:88-101); REML-by-marginalization
  (R3:72-78). **dep: S3.**

- **S5 — Genomic GBLUP native path.**
  in: `Ginv = inv(G + ridge·I)` in the `Ainv` slot; out: GBLUP fit via the *same* template. reuses: S2/S3/S4
  path unchanged (recon R2:94-100 confirms Julia GBLUP is literally the animal model with `Ginv` in the `Ainv`
  slot — no genomic-specific numerics). **NOTE / design divergence:** `Ginv` is **dense** (no pedigree
  sparsity); recon R2:104-114 flags that pushing a dense `Ginv` through a *sparse*-Cholesky assumption is the
  **likely crash mechanism the collaborator hit** (inferred, not measured — R2:222). The native path should
  therefore route dense `Ginv` through a **dense** TMB branch, not the `DATA_SPARSE_MATRIX` branch (R2:203-210).
  **dep: S4. Do S5 only after S1–S4 are validated.**

- **S6 — Parity + external-comparator tests.**
  in: shared fixtures; out: native-TMB fit matches (a) `HSquared.jl` on the same data to tolerance, and
  (b) an *external* comparator (`nadiv` for `A⁻¹`; ASReml/`sommer`/`pedigreemm` for variance components + EBVs).
  reuses: `nadiv`/`sommer`/`pedigreemm` already in hsquared `Suggests` (R1:154-166). **dep: S4 (pedigree), S5
  (genomic). This is the slice that lets any capability row MOVE off `planned`.**

- **S7 — AI-REML / scale story (optional, deferred).**
  in: S4 native fit; out: a decision on whether to (a) accept TMB Laplace + `nlminb` as the native fit and
  *measure* its wall-clock vs ASReml, or (b) additionally implement the closed-form Gaussian AI-REML
  score/information (R2:143-155) for a faster native path. reuses: Julia `fit_ai_reml` formulas as the
  numerical target (R2:211-218). **dep: S6.** *(The AI-REML formulas do NOT transfer to any non-Gaussian
  extension, R2:156-158 — S7's scope is Gaussian-only by construction.)*

**Critical path:** S0 → S1 → S2 → S3 → S4 → S6. S5 and S7 branch off after S4. S1 and S2 can proceed in parallel after S0.

---

## 5. What this fixes (tie back to the trigger)

1. **Removes the JuliaCall bridge dependency** — the R user's *actual* measured pain (bridge overhead +
   R-crashing instability at moderate G; brain finding, corroborated by R1:47-49 showing the default path
   hard-errors without Julia). A native `engine="tmb"` fits with zero Julia in the loop.
2. **Replaces derivative-free search with a Newton/Laplace fit** — TMB gives exact AD gradients and the Laplace
   marginal, so the native pedigree path does *not* inherit the `fit_sparse_reml` re-factorize-every-eval
   NelderMead cost that timed out >7 min by 50k (brain finding; R2:121-133). Precomputing `Ainv` + `log_det`
   R-side and passing them as data (R3:44-51, R4:140-143) is the specific mechanism.
3. **Gives an ASReml-*class* fitting *shape*** — sparse-Cholesky MME, few Newton iterations, `sdreport`
   uncertainty. **Claim discipline:** "ASReml-*class*" is the *architecture*; matching ASReml's ~2 s/100k
   *wall-clock* is a number to be **measured in S6/S7**, not asserted from design (§7).

**Honest hedge (from recon R2):** part of item 2's benefit may already be reachable *inside Julia* by
defaulting the pedigree path to the existing `fit_ai_reml` (R2:131-168) — which was NOT re-timed (R2:222-224).
That does not remove the bridge (item 1 still stands as the native engine's unique win), but it does mean "the
Julia fit is fundamentally slow" is an **overstatement**; the durable, native-only win is **bridge removal**,
with the fit-speed win being *conditional* on `fit_ai_reml`'s measured 50k–100k behavior.

---

## 6. What this does NOT change / claim ceiling

- **`public_covered_count` stays 5.** No capability moves on design alone. A native-engine row is born
  `planned` (S0) and can only move to `covered` after S6 produces its **own** validation evidence (D-176:
  native evidence for native rows only; R4:109-118). Julia rows keep their own evidence; nothing this arc does
  makes any Julia claim more or less valid.
- **The Julia twin and its evidence stay.** The bridge engine is not deprecated or removed; it remains the
  reference and the only path for the 15 `engine="julia"` `target=` estimators (R1:53-56) unless/until a native
  slice explicitly covers one.
- **Scope is the univariate Gaussian animal model + GBLUP only.** Multivariate, non-Gaussian/Laplace,
  single-step, metafounder, SNP-BLUP, random-regression are **out of scope** for this arc (R1:210-215 flags the
  scoping was undecided; this design decides it: **in = Gaussian animal model (S1–S4) + GBLUP (S5); everything
  else = future arcs**). A `partial` row for the native engine must state it does NOT cover those.
- **No `backend`/`accelerator`/GPU claim.** Those remain undispatched metadata (R1:114-126); the native engine
  is CPU/TMB only. No GPU story here.

---

## 7. Risks + effort (honest)

**Effort (order-of-magnitude, wall-clock, given the reuse):**

- S1 (Quaas port): **small** — the algorithm is handed to you and pre-validated (R4:131-135). ~1–2 sessions
  incl. `nadiv` parity.
- S2 (TMB template): **medium** — new C++, must match the REML identity term-by-term (R2:39-73). ~2–4 sessions
  incl. getting `logdetC`/`quad` to agree with Julia.
- S3+S4 (wrapper + result adapter): **medium** — reuses the drmTMB loop but the result-shape adapter is fiddly
  (8 required fields, R1:85-101). ~2–3 sessions.
- S5 (genomic dense branch): **small–medium** once S1–S4 exist.
- S6 (parity + external comparators): **medium–large** — this is where most *calendar* time goes, because
  parity to tolerance against both HSquared.jl and an external tool (ASReml/sommer) is the actual bar for a
  covered claim.
- S7: **medium**, optional.

Rough total to a *validated* native Gaussian animal-model engine (S0–S4+S6): **on the order of 2–4 weeks of
focused work**, most of it in S2 and S6, *not* in S1. This is inference from the recon-established reuse
surface, not a measured estimate — flagged as such.

**Hardest parts:**

1. **Matching estimands exactly for parity (S2/S6).** The Julia `sparse_reml_loglik` uses a specific
   sparse-MME REML identity (`quad = y'R⁻¹y − rhs'C⁻¹rhs`, EBV = random block of the MME solve; R2:44-64).
   TMB reaches the *same optimum* by a *different* route (Laplace joint marginal, R2:191-197). Getting loglik,
   variance components, AND EBVs to agree to tolerance — not just the optimum — is the real work. drmTMB's
   template is a *pattern* match, not a drop-in (§3, new item 1).
2. **TMB build + CRAN implications.** Adding compiled code (`LinkingTo: RcppEigen, TMB`, a `src/`) turns
   `hsquared` from a pure-R package into a compiled one (R1:168-171). Cross-platform build (Windows/macOS
   toolchains), longer check times, and CRAN's compiled-code scrutiny all apply. This is the biggest *ongoing*
   cost, and it is the one the pure-Julia-bridge design was specifically avoiding.
3. **REML in TMB vs AI-REML numerics.** TMB's Laplace + `nlminb` is not ASReml's AI-REML; wall-clock parity is
   unproven (R2:211-218, R2:156-158). "ASReml-class *speed*" is a measured claim, gated on S6/S7, not a design
   guarantee.
4. **Dense-`Ginv` trap (S5).** Must consciously route dense `Ginv` through a dense branch (R2:203-210), or the
   native engine reproduces the *same* likely crash mechanism the collaborator hit (R2:104-114, inferred).

**Go-conditions (all must hold before S1 code is written):**

- [ ] Owner explicitly authorizes the D-2026-06-12 pivot (this is a founding-decision change, §1).
- [ ] Owner accepts `hsquared` becoming a **compiled** package (CRAN + cross-platform build burden).
- [ ] A one-shot **measurement** first: re-time Julia `fit_ai_reml` (not `fit_sparse_reml`) at 50k–100k
      (R2:222-224 — this is currently UNCERTAIN). If `fit_ai_reml` already hits ASReml-class speed, the
      *speed* rationale weakens to *bridge-removal-only*, which changes the cost/benefit.
- [ ] Sequential-lane clear: this is R-lane (`hsquared`) work; coordinate the twin boundary before starting
      (CLAUDE.md lane rule — do not edit the R repo from the Julia session).

---

## 8. Recommendation (Ada's honest call)

**Is this a good next arc? — Qualified yes on strategic merit, but NOT the immediate next arc, and NOT before
one cheap measurement.**

**The strongest argument FOR:** the *bridge removal* is a real, durable, user-facing win that nothing else
delivers — the collaborator's crashes are a bridge/JuliaCall problem, and no amount of Julia-side tuning fixes
that for an R user (brain finding; R1:47-49). And the reuse surface is exceptional: gllvmTMB hands you the
sparse `A⁻¹` builder pre-validated, drmTMB hands you the entire TMB fit/`sdreport` loop. This genuinely is
*mostly assembly* (§3). If `hsquared` is meant to be a first-class R package that applied quant-geneticists
install and trust, a native engine is the honest end-state, and the stack (TMB) is the right one.

**The strongest arguments for CAUTION:**
1. It **pivots a founding decision** — not a thing to start on momentum.
2. It turns a pure-R package into a **compiled** package with a permanent CRAN/cross-platform tax.
3. Part of the *speed* premise is **overstated pending measurement**: `fit_ai_reml` already exists and may
   already be fast (R2:131-178, UNCERTAIN). The unique native win is bridge-removal; the speed win is
   conditional.

**Ranking against the D1 genomic go/no-go the owner is also weighing:**

- The **D1 genomic-recovery** line has died at eight-plus distinct stages; the owner leans GO but the retirement
  fence and the D-71 planning-only boundary stand (Live Phase Snapshot). It is a *validation/evidence* arc on an
  existing capability, deep in a fragile campaign.
- **This native-engine arc** is a *fresh build* on a clean, high-reuse surface that targets the collaborator's
  *actual reported pain*. It has no death-march history and a much clearer definition of done (S6 parity).

**My call:** rank the native-engine arc **above** resuming D1 genomic-recovery *if* the goal is user-facing
value and program health — it addresses a live collaborator complaint, sits on a proven reuse base, and its
"done" is legible. D1 is higher-risk, lower-morale, and its value is internal-evidence, not user-facing.

**But** do **not** greenlight native-engine implementation yet. Do this instead, in order:
1. **Measurement first (cheap, ~1 session, Totoro):** re-time Julia `fit_ai_reml` at 50k/100k and try the
   dense-`Ginv` GBLUP path at the collaborator's scale to confirm the crash mechanism (R2:222-224, R2:104-114).
   This costs almost nothing and could *reframe* the whole arc (bridge-removal-only vs speed+bridge).
2. **Owner decision on the pivot** (§1) and on accepting a compiled package (§7 go-conditions).
3. **Then** S0→S1 as a scoped, single-lane R-side arc.

Net: **a strong candidate for the *next major R-lane arc*, gated behind one measurement and an explicit
pivot decision — not something to begin coding this session.**

---

*This document is design only. It authorizes no implementation, no capability-status move, and no compute run.
Every architectural claim is cited to recon R1–R4 or a brain finding; inferences (dense-`Ginv` crash, effort
totals, `fit_ai_reml` scaling) are flagged UNCERTAIN and must be measured, not assumed.*
