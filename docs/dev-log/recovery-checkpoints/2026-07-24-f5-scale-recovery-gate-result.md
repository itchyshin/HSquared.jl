# Result — F5 production-scale recovery gate: **GATE FAIL (banked negative)**

**2026-07-24 · Totoro (julia 1.12.6, single-thread) · gate frozen at `77ecad3a` BEFORE running ·
OPT-IN, NOT CI · promotes NOTHING; `public_covered_count` stays 5.** Per the pre-declaration a
failure is a **banked negative, never a post-hoc relaxation** — this result stands as FAIL.

## Verdict: **GATE = A ∧ B ∧ C ∧ X = FAIL** (C failed)

`GATE_JSON {"gate_pass":false, ...}`

| Leg | Criterion (pre-declared) | Result | |
|---|---|---|---|
| **A** recovery at q=100,000 | 48/48 conv AND mean rel.err ≤ 5% | σ²a **0.49%**, σ²e **0.05%**, 48/48 | **PASS** |
| **B** deep pedigree (15-gen, n≈4500) | 48/48 conv AND \|bias\| ≤ 2·MCSE | σ²a \|bias\|/MCSE **1.17**, σ²e **0.92**, 48/48 | **PASS** |
| **C** boundary (near-constant y, n=2000) | 8/8 graceful (conv=false, finite, no throw) | **6/8 graceful** | **FAIL** |
| **X** eigen ≈ AI-REML (n=2000) | ≤ 1e-6 | σ²a **3.40e-7**, σ²e 1.81e-7 | **PASS** |

## Diagnosis of the Leg-C failure — a TEST-DESIGN flaw, NOT a `fit_ai_reml` defect

Leg C required `converged = false` at the σ→0 boundary. A local per-seed diagnostic
(`scratchpad/f5_boundary_diag.jl`, julia 1.10.0 — DIAGNOSTIC, does not re-run or relax the gate)
shows every boundary seed is **finite and non-throwing** — the #182 no-throw/no-NaN contract HOLDS
on all 8 — but several **converge to a valid tiny optimum** rather than stopping:

```
seed 20268200: conv=true  σ²a=2.50e-14 σ²e=9.42e-13   (graceful=false by Leg-C)
seed 20268202: conv=false σ²a=1.17e-13 σ²e=0.0112      (graceful=true)
seed 20268205: conv=true  σ²a=8.32e-15 σ²e=9.42e-13   (graceful=false by Leg-C)
… (Totoro/1.12.6 counted 6/8 graceful; local/1.10.0 counted 3/8 — the split is julia-version /
   near-machine-precision sensitive because with 1e-6 noise σ̂²a sits at ~1e-14)
```

With **near-constant** y (1e-6 noise, not exactly zero) the fitter can find a tiny positive σ̂²a and
**converge legitimately** — an honest, finite, non-throwing outcome. Leg C wrongly counted that as a
failure by demanding `converged=false`. So the **fitter's boundary behaviour is correct**; the
**pre-declared Leg-C criterion was mis-specified** (it should accept EITHER a graceful stop OR a
converge-to-valid-tiny-σ², both finite/non-throwing — exactly the "finite optimum OR documented
boundary" contract).

**This is not a relaxation.** The gate result is FAIL. A **corrected, RE-DECLARED** boundary leg is
FUTURE work, run as fresh separate evidence — it does not resurrect this gate.

## Erratum (Rose G8 finding) — the frozen script's header is stale on Leg A
`sim/phase_f5_scale_recovery_gate.jl:39–45` (the docstring PASS block) still says Leg A is
"|bias| ≤ 2·MCSE / NO DETECTABLE across-seed bias at production scale". That is a **stale
pre-split copy**: the EXECUTED code (`:220` `pass_mode=:relative`, `:52` `REL_TOL=0.05`, `:142–143`)
and the pre-declaration doc (`…f5-…predeclaration.md`) make Leg A a **mean-relative-error ≤ 5%
recovery** test. It is NOT a relaxation — the header was the *stricter* criterion, and code + doc
were frozen together in `77ecad3a`. Read Leg A as the executed relative-recovery test; the mid-file
comment (`:142–143`) is already correct.

## What stands (strong positive evidence, but NOT a passing gate)
Leg A (recovery to 0.49% at q=100,000, 48/48), Leg B (deep-pedigree unbiasedness, all \|bias\|≤2·MCSE),
Leg X (eigen≡AI-REML to 3.4e-7), and the F8 `sommer` comparator (AGREE 3.6e-5) are all strong. But
because the **overall pre-declared gate FAILED**, the production-default (F4b) is **NOT
gate-supported** — the owner's G10 sees honest partial evidence + a banked-negative gate, not a
passed gate. `public_covered_count` stays 5; nothing promoted.

> Related: `2026-07-24-f5-scale-recovery-gate-predeclaration.md` · `2026-07-24-f0-adversarial-highfill-decision.md` ·
> `2026-07-24-f8-sommer-aireml-comparator.md` · Rose G8 audit (CLEAR-WITH-CHANGES, applied).
