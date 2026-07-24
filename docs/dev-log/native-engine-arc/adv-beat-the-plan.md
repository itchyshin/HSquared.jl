# Beat the plan — adversarial review of the native-engine arc

**Role:** adversarial planner. Mandate: find a cheaper path that still kills the collaborator's
pain, and prove the full TMB program is over-engineered until a measured condition says otherwise.
**Grounding:** arc-design.md + recon R1–R4 (cited). Inferences flagged UNCERTAIN.
**Boundary:** planning only — no implementation, no capability move, no compute run.

---

## The pain, stated precisely (do not inflate it)

The collaborator's reported pain is **two concrete symptoms**: `hsquared` is **slow**, and it
**crashes at genomic G, n≈1000** (brief). It is NOT "I refuse to install Julia" and it is NOT
"remove the bridge." The design (arc-design.md:185-200) quietly promotes *bridge removal* to the
headline win — but Ada herself concedes it is the **only** unique native win, and that the speed
premise is "overstated pending measurement" (arc-design.md:198-200, :286-288). That concession is
the crack this review drives a wedge into.

**Two facts make the full program look over-built:**

1. **The crash is a one-function upstream bug, not a missing engine.** The likely mechanism is a
   *dense* `Ginv = inv(G+ridge·I)` shoved through `sparse(Float64.(...))` and Cholesky-factored as
   if sparse, giving near-total fill-in (R2:104-114, :203-210 — inferred, UNCERTAIN). At n=1000 a
   *dense* Cholesky is milliseconds; the crash is fill-in/marshalling, not scale. The design's own
   S5 says the *native* path "should route dense `Ginv` through a **dense** branch" (arc-design.md:
   162-163). **That exact one-line routing fix applied to the existing Julia engine kills the crash
   with zero new package.** Building a multi-week compiled engine to dodge a bug that is a dense-branch
   guard upstream is the weakest link in the plan.

2. **The fast REML already exists in Julia and is already the genomic default.** `fit_ai_reml` is a
   real average-information Newton method — one sparse Cholesky per *iteration* (not per NelderMead
   eval), closed-form REML score + AI information, EM warm-start (R2:131-168). It is *already* the
   default on `fit_gblup_reml`/`fit_snp_blup_reml` (R2:164-166). The >7-min/50k timing was
   `fit_sparse_reml`'s derivative-free NelderMead (R2:121-133) — a **different** function. Whether
   `fit_ai_reml` reaches ASReml-class speed at 50–100k is **UNMEASURED** (R2:170-178, :222-224). So
   "the Julia fit is fundamentally slow" is unproven; the pedigree path merely still *defaults* to
   the slow optimizer, which is a **one-line default flip**, not an engine rewrite.

---

## The four options, scored on (crash / speed / bridge / cost)

### (A) Do NOT build a native engine — Julia dense-Ginv fix + default pedigree to `fit_ai_reml` + harden the bridge
- **Crash: FIXED (cheapest possible).** Route dense `Ginv` through a dense branch in HSquared.jl
  (R2:203-210) — the same guard S5 prescribes, applied upstream. One function.
- **Speed: LIKELY FIXED, measured-conditional.** Flip the pedigree default from `fit_sparse_reml`
  to the *already-existing* `fit_ai_reml` (R2:131-168); add JuliaCall warm-start + persistent
  session to kill per-call precompile. Gated on the Stage-0 timing (R2:222-224).
- **Bridge: HARDENED, not removed.** Warm session, no per-call precompile, dense-safe marshalling
  → overhead + instability drop sharply. Julia install still required.
- **Cost: LOW.** No compiled package, no CRAN pivot, no founding-decision (D-2026-06-12) pivot.
  Julia-lane + R-bridge edits, days not weeks. Fits the two *stated* pains directly.

### (B) Minimal native R A-inverse + `Matrix::Cholesky` MME solve — no TMB, no compiled package
- **Crash: FIXED** for the Gaussian pedigree case (never touches the bridge); dense `Ginv` handled
  by a dense solve branch.
- **Speed: CONDITIONAL.** The Quaas A⁻¹ builder is *already pure R* in gllvmTMB (`Matrix::sparseMatrix`
  triplets, no inversion, MCMCglmm-validated — R4:7-39, :131-135) and `Matrix::Cholesky` already
  factors sparse precision (drmTMB path-4 precedent, R3:124-130). The **only** new piece is the
  optimizer: transcribe HSquared.jl's closed-form AI-REML **score + AI information** (R2:143-155)
  into ~200-400 lines of R with an analytic Newton step. Fast (one Cholesky/iter). Risk: hand-coded
  gradients have no AD safety net, and the Takahashi selected-inverse trace term in pure R is the
  fiddly bit — but `sommer`/`pedigreemm` (already in Suggests, R1:154-166) do exactly this in R, and
  the Julia reference gives a term-by-term test oracle (symbolic-alignment discipline).
- **Bridge: REMOVED** for the Gaussian animal model — pure R, zero Julia.
- **Cost: MEDIUM, but NO compiled-package tax.** This is the crucial dominance point over (D):
  it removes the bridge *without* turning `hsquared` into a compiled CRAN package. The permanent
  Windows/macOS toolchain + compiled-code CRAN scrutiny (arc-design.md:249-252) — the single biggest
  ongoing cost of the whole plan — **evaporates**.

### (C) Thin native path ONLY for the dense-Ginv GBLUP that crashes; pedigree stays on the bridge
- **Crash: FIXED** (dense G, dense Cholesky, dense solve — n=1000 is trivial dense).
- **Speed: unhelped for pedigree** (still bridged + still `fit_sparse_reml` unless combined with A).
- **Bridge: removed for GBLUP only.**
- **Cost: LOW-MEDIUM but NARROW.** Strictly dominated: the same crash is fixed more cheaply by (A)'s
  upstream dense-routing guard, which *also* leaves one code path instead of splitting the engine.
  (C) only makes sense if the bridge cannot be hardened at all — not the case here.

### (D) Full TMB native engine as designed (S0–S7)
- **Crash: FIXED** (dense branch, S5) — but no cheaper than (A)/(C) at fixing it.
- **Speed: FIXED for Gaussian**, at the cost of a new C++ template that must match the REML identity
  term-by-term (R2:39-73; arc-design.md:244-248) — the hardest and slowest slice.
- **Bridge: removed for exactly 2 of 15+ estimators** (Gaussian animal model + GBLUP); the other 13
  `engine="julia"` targets stay bridged (R1:53-56; arc-design.md:210-212). So the bridge dependency
  and its crash surface are **not actually removed from the package** — the user still meets the
  bridge on any non-covered estimator.
- **Cost: HIGH.** 2–4 weeks (arc-design.md:238), founding-decision pivot (§1), and a **permanent**
  compiled-package CRAN/cross-platform tax (:249-252) — incurred to remove the bridge from a *subset*
  and to fix a crash that a one-line upstream guard already fixes.

---

## Verdict: what actually dominates

The full TMB program spends multi-week + permanent-compiled-package cost to buy (i) a crash fix that
is a one-function upstream guard, (ii) a speed win that is a one-line default flip to code that
already exists, and (iii) bridge removal for only 2 of 15+ estimators. For the collaborator's two
*stated* pains, **(A) delivers both this week** at Julia-lane + bridge cost, with no pivot and no
compiled-package tax. If the residual complaint is the *bridge itself* (Julia install / structural R
crashes), **(B) removes it for the Gaussian case without the compiled-package tax that is (D)'s worst
permanent cost** — making (B), not (D), the correct bridge-removal arc for the common model. TMB earns
its compiled-AD tax only where hand-analytic AI-REML gradients **do not exist** (non-Gaussian/Laplace
families — R2:156-158) or where R-level factorization provably can't scale.

**Ranked (best next arc → worst):**
1. **(A) Julia dense-Ginv fix + `fit_ai_reml` default + bridge warm-start** — fixes both stated pains, days, no pivot, no CRAN tax. **Do this first.**
2. **(B) Minimal native-R AI-REML (no TMB)** — removes the bridge for the Gaussian model at MEDIUM cost and **zero compiled-package tax**; the right *second* arc if the bridge itself is the residual pain.
3. **(D) Full TMB program** — justified only under the measured+roadmap condition below; otherwise over-engineered.
4. **(C) Thin GBLUP-only native path** — strictly dominated; (A) fixes the same crash more cheaply with one code path.

**The single measured condition that tips it to full TMB (D):** Stage-0 re-times the fit at 50–100k
and finds the wall-clock gap survives *both* cheap fixes — i.e. `fit_ai_reml` (and a pure-R analytic
AI-REML, option B) **still miss ASReml-class speed because the cost is in the per-iteration sparse
factorization/selected-inverse itself, not in the derivative-free wrapper or the dense-Ginv bug** —
**and** the roadmap commits to non-Gaussian/Laplace families where no closed-form AI-REML gradient
exists (R2:156-158). Only when *both* hold does compiled AD earn its permanent CRAN/cross-platform tax
over (A)+(B). If the Stage-0 number shows `fit_ai_reml` already at ASReml-class speed, (A) alone likely
closes the case and (D) should not be built.
