# After-task — Wave F production-scale sparse fitting: evidence assembled + STAGED

**2026-07-24 · branch `codex/2026-07-13-v07-performance-localization` · Claude (end-to-end,
owner-directed) · ultra-plan `keen-orbiting-horizon`.** Promotes NOTHING; `public_covered_count`
stays 5; no capability-status row flipped. This is the evidence-assembly close; a
production-default declaration still OWES a spawned Rose G8 + owner G10 + the R bridge.

## Goal / mission
Assemble the **production-scale sparse fitting** evidence for the univariate Gaussian animal model
(`fit_ai_reml`) to the Wave-F "Track A" bar — a pre-declared recovery-at-scale gate + an at-scale
benchmark + a same-estimand `sommer` REML comparator — and STAGE it for the owner's G10 call.
Owner confirmed this arc (over R-bridge activation and standard-QG kernels) 2026-07-24.

## Key finding — the arc was "wire + gate", not "build"
The prior-work sweep (corrected by the Phase-2 review) found the univariate sparse path **already
exists**: `fit_ai_reml` is sparse-Henderson + CHOLMOD + Takahashi selinv on its core; a matrix-free
PCG solver is already benchmarked (v0.8-S2, q→10⁶); Wave F is already designed (doc-17) and scouted
(doc-23); F1/F3 convergence hardening + #114/#182 boundary hardening are already merged. So the arc
became: **measure the real scale behaviour, gate recovery at scale, and stage** — not build a fitter.

## What was accomplished (per slice)
- **S1 — scoping (done).** Verified live (not on the scout's word) that the 3 "un-merged" branches
  are safe to close: `phase5-sparse-aireml` + `v84-atscale` are already ancestors of HEAD;
  `sparse-boundary-hardening` is superseded (boundary work in HEAD via #114, later graceful fix
  #182 — cherry-pick would regress). Confirmed the src map; pinned the doc-18-vs-capability-status
  drift (MV/two-effect/RR-k2/genomic-REML/ordinal/Gamma already covered — doc-18 prose stale).
  Remote-branch deletion left to the owner (outward action; not blocking).
- **S2 — F0 measure-first (done).** The 2026-06-23 baseline (half-sib) already showed the direct
  path scales (q=300k in 2.3s). Added the missing **adversarial high-fill** leg
  (`sim/drac/f0_adversarial_fill.jl`, `533cf0f8`): a random-mating pedigree whose `nnz(L)/n` grows
  with n. **Two regimes** established — low-fill scales; high-fill walls super-linearly (Totoro
  q=10k = 132s, fill 262, selinv-driven). **Decision:** F6 (wire the existing PCG) is the lever for
  the high-fill n>20k tail only, DEFERRED; the deliverable is scoped to the low-fill regime + the
  eigen `:auto` crossover. Doc: `2026-07-24-f0-adversarial-highfill-decision.md` (`86a733b7`).
- **S3 — convergence hardening (done).** `Pkg.test()` green on this branch; F1 (O(n) inbreeding),
  F3 (#180 relative-VC criterion) and #114/#182 boundary hardening all present + passing. Nothing
  to port (the branch was superseded).
- **S4 — wire (light).** The sparse path is already reachable via `fit_animal_model(target=:ai_reml
  / :auto)`; `fit_multi_effect(method=:matrix_free)` already wires PCG into a K-component fit loop.
  No default flip (F4b) — that is the staged G10 declaration, not done in-plan.
- **S5 — pre-declared recovery-at-scale gate (frozen `77ecad3a`).** `sim/phase_f5_scale_recovery_gate.jl`
  + predeclaration, frozen BEFORE running. **Leg A (recovery at q=100,000): PASS** — 48/48 converged,
  mean rel.err σ²a 0.49% / σ²e 0.05%. Legs B (deep 15-gen, |bias|≤2·MCSE — 1.17/0.92) and X
  (eigen≈AI-REML 3.4e-7) also PASS, but **Leg C (boundary) FAILED 6/8** → the pre-declared
  GATE = A∧B∧C∧X is a **BANKED NEGATIVE** (`2026-07-24-f5-scale-recovery-gate-result.md`).
  Diagnosed as a Leg-C **test-design flaw** (near-constant y legitimately converges to a valid tiny
  σ²≈1e-14 — finite, non-throwing, the #182 contract holds — which the criterion wrongly rejected),
  NOT a `fit_ai_reml` defect. **NOT relaxed.**
- **S6 — F8 comparator (done).** Direct `sommer`≡`fit_ai_reml` AGREE to 3.59e-5 (`514807a0`),
  complementing the eigen-thread transitive leg. Doc: `2026-07-24-f8-sommer-aireml-comparator.md`.
- **S7 — Rose G8 + stage + handoff (done).** A REAL spawned `rose-systems-auditor` (opus) audited
  the package: **CLEAR-WITH-CHANGES** — fences all hold (count 5, no capability flip, foreign files
  untouched, nothing promoted, F6 honestly deferred). Applied its 3 fixes: 2 F0 wording softenings
  (dropped "already production-scale"; named the eigen-`:auto` mitigation's unproven->60 caveat) +
  the F5 frozen-header erratum (Leg A is the executed `:relative` recovery test, not bias/MCSE).
  Rose's pending-dependency (the F5 B/C/X legs) has since resolved to the banked-negative above.

## Evidence inventory (STAGED, nothing promoted)
| Leg | Artifact | Result |
|---|---|---|
| F0 benchmark | `sim/drac/f0_adversarial_fill.jl` + baseline | low-fill scales to 300k/2.3s; high-fill walls (132s@q=10k) |
| F5 recovery gate | `sim/phase_f5_scale_recovery_gate.jl` (frozen 77ecad3a) | **GATE FAIL (banked)**: A/B/X PASS (recovery 0.49% @ q=1e5; deep unbiased; eigen≡AI 3.4e-7); C boundary FAIL 6/8 = test-design flaw, not a fitter defect |
| F8 comparator | `comparator/{prepare,run}_sommer_aireml.*` | sommer≡AI-REML 3.59e-5 (AGREE) |

## Fences held
`public_covered_count` = 5 throughout; no capability-status row flipped; no `src` logic changed
(F0/F5/F8 are opt-in sims + comparators, not CI); the 4 foreign dirty files untouched; R twin not
edited; D1 genomic PAUSED (D-68); TMB deferred; F6/GPU/multivariate/APY deferred.

## Next steps (for the owner / next session)
1. **Owner G10:** the production-default flip (F4b) is **NOT gate-supported** — the pre-declared
   gate FAILED (banked negative, a Leg-C test-design flaw, not a fitter defect). The recovery
   (0.49% @ q=1e5) + deep-unbiasedness + `sommer` comparator evidence is strong, but a **corrected,
   RE-DECLARED** boundary gate (accept graceful-stop OR converge-to-valid-tiny-σ²) must PASS before
   a gate-supported default flip. Count stays 5 regardless.
2. **R lane:** expose the production-scale path via the R bridge (separate repo).
3. **F6 follow-on (deferred):** wire the existing v0.8-S2 PCG into the fit loop for the high-fill
   n>20k tail, if/when a real high-fill large pedigree needs it.
4. Owner: close the 3 stale branches; consider splitting PR #274.

## Gotchas
- **Freeze BEFORE running** — the F5 gate's integrity anchor is commit `77ecad3a`.
- **Leg-A criterion:** a bias/MCSE test is pathological at q=1e5 (MCSE→0); Leg A uses a recovery
  (relative-error) criterion, Leg B keeps bias/MCSE at moderate n. The smoke caught this.
- **High-fill exact-cov Leg B is expensive** (dense inv+chol at n=4500 × 48) — ~15 min on Totoro.
- Totoro clone tracks only `main`; `git fetch origin <branch>` + checkout the commit explicitly.
