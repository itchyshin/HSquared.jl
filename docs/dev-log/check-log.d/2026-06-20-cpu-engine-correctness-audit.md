# 2026-06-20 CPU engine correctness audit (manual spot-check)

- **Goal:** serve the "accuracy first — make sure CPU is done properly" directive with
  a durable, honest record of the CPU engine's correctness posture (the multi-agent
  fan-out audit failed 3× on API rate/session limits).
- **Active lenses:** Gauss (numerics) + Rose (claim-vs-evidence) + Fisher (inference).
- **What landed:** `docs/dev-log/2026-06-20-cpu-engine-correctness-audit.md` — a
  manual from-scratch re-derivation of the two subtlest kernels (`fit_ai_reml`
  average-information + score; `laplace_marginal_loglik`) confirming both CORRECT,
  plus a consolidation of the per-kernel evidence-class posture (independent oracle /
  reduction / hand-checked) and the honest conclusion.
- **Conclusion:** CPU numerical correctness is sound for solo engine work (riskiest
  kernels independently re-derived; the rest carry independent-oracle/reduction
  evidence; no bug found in the spot-check); the remaining gap to `covered` is
  EXTERNAL-comparator parity, which is cross-lane (R lane), not solo engine code.
- **Honesty:** explicitly framed as a spot-check + posture summary, NOT an exhaustive
  line-by-line audit; no capability/claim change; nothing promoted to covered.
- **Docs-only:** no code/test/capability change; `docs/make.jl` unaffected.
- **Rose audit:** CLEAN — the note claims only what was verified, flags the fan-out
  failure and the spot-check scope honestly, and makes no covered/performance claim.
