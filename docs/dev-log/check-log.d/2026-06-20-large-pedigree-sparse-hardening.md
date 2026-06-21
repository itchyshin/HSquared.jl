# 2026-06-20 Large-pedigree sparse AI-REML fit + selinv PEV hardening (#6)

- **Goal:** harden the sparse AI-REML fit + selinv PEV at a larger pedigree than the
  existing ≤110-animal fixtures (#6 production-sparse hardening). Built in parallel
  with two worktree agents (recovery families + per-trait families).
- **Active lenses:** Gauss (sparse linear algebra) + Henderson (MME) + Karpinski (sparse
  scaling, but NO perf claim) + Rose (claims).
- **Probe:** a cold q=420 fit converged in 2.2s; EBVs/β exactly == `henderson_mme`;
  selinv PEV == dense PEV to 1.9e-16.
- **What landed:** a committed deterministic 420-animal half-sib test in
  `test/runtests.jl` (no engine code change — the sparse path already exists):
  `fit_ai_reml` converges; β (atol 1e-8) + EBVs (atol 1e-7) exactly self-consistent
  with `henderson_mme` at the fitted VCs; selinv PEV/reliability == dense diagonal
  (atol 1e-8) at 420 animals. CORRECTNESS-at-scale only — NO timing asserted.
- **Gates:** 7 assertions; full `Pkg.test()` green (test ~0.1s warm).
- **Docs:** capability-status (`Sparse production fitting / AI-REML` + `Production sparse
  reliability / PEV`) + validation-debt (`V1-REML`) + `validation_status()`
  (`V1-AI-REML` evidence strengthened, `V1-SELINV-PEV` → 420; "still needs" trimmed of
  large-pedigree hardening); no new row, stays 41. `validation_status()` loads, 41 rows.
- **Honest status:** correctness-at-scale; NO performance/benchmark claim (GPU parked).
  `V1-AI-REML` was already `covered` (external bridge); only Julia-native hardening added.
  Nothing newly promoted.
- **Rose audit:** CLEAN (inline). Only correctness asserted; "no performance claim"
  explicit; covered status unchanged in substance. Placed in a distinct test region /
  distinct doc rows from the parallel agents (auto-merge).
