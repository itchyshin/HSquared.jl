# After-task — H2 engine-performance thread: AI-REML diagnosis, robustness fixes, and the eigen-once fitter

**Meta:** 2026-07-24 · Claude (Julia engine lane) · branch `codex/2026-07-13-v07-performance-localization` ·
mode: live-toolchain (Totoro benchmarking + local Pkg.test) · triggered by collaborator **szymekdr** (Discord).

## Task goal

Resume the H2 engine-PERFORMANCE thread (NOT the paused D1 genomic lane). First re-run the real-signal
benchmark on Totoro to answer the decision hinge — does `fit_ai_reml` converge fast with real genetic signal?
— then instrument the score trajectory and diagnose boundary-vs-bug. The thread then expanded (owner-driven)
into: fix the crash/robustness gaps found, benchmark the "why is it slow" levers, and build + wire a
one-factorization eigen-once fitter for both the Julia engine and (by coordination) the R twin.

## Outcome (met)

- **Decision hinge RESOLVED:** `fit_ai_reml` converges in **5–8 Newton iterations** with real h²=0.4 signal
  (Totoro, current code). The prior "runs to the 100-iteration cap / never converges" was a **stale Totoro
  checkout (pre-#180 relative-change fix) + no-signal benchmark data** — two confounds, both retired. **No
  bug** (Gauss re-derived the score/AI/Newton algebra from Henderson identities; byte-unchanged since origin).
- **The "slow" is fill-in-driven selected-inverse cost**, not the Cholesky (at random n=10000 the factorization
  is 0.7 s of a 170 s fit). On realistic pedigrees the fit is already fast (n=10000 = 0.64 s).
- **Robustness fixes (tested):** `PosDefException` graceful-stop guards on BOTH AI-REML loops (single-effect
  `_fit_ai_reml_diagnostics` + multi-effect `fit_sparse_multi_effect_aireml`) + a well-identified
  iteration-count regression guard.
- **New fitter (tested, experimental):** `fit_eigen_reml` — a one-factorization eigen-once single-effect REML
  (EMMA/GEMMA), recovers AI-REML to ~1e-8, **6.95× faster on high-fill n=10000**, wired via
  `fit_animal_model(target = :eigen | :auto)`; `:auto` routes eigen-vs-sparse by the MME fill proxy `nnz(L)/n`.
- **Fences held:** `public_covered_count` stays **5**; no capability-status covered move; TMB native engine NOT
  built (deferred, owner-gated D-2026-06-12); paused D1 lane untouched.

## Active lenses and spawned agents

- **Gauss** (numerical) — independent AI-REML algebra audit → NO BUG (boundary-only); flagged the two secondary
  gaps (main-loop PosDef guard; missing iteration-count test), both since fixed. `scratchpad/gauss-aireml-audit.md`.
- **Rose** (claim-vs-evidence) — TWO audits: (1) the diagnosis findings (CLEAR w/ 2 edits — ASReml
  not-head-to-head, well-identified qualifier — applied); (2) the eigen fitter claims (CLEAR w/ 1 edit —
  dangling `bench_eigen.jl` citation → point to findings doc — applied). All fences verified.
- **Ada** (this session) — orchestration; ran a Phase-0.25 prior-work sweep that caught the already-overturned
  ordering lever via the brain (2026-06-23), avoiding a re-derivation.

## Files changed

**Engine + tests (this session's changes only; 4 pre-existing foreign dirty files left untouched):**
- `src/likelihood.jl` — `score_trace` instrumentation (append-only); `PosDefException` guard + degenerate-
  likelihood routing in `_fit_ai_reml_diagnostics` and `fit_sparse_multi_effect_aireml`; new `fit_eigen_reml`;
  `_auto_reml_route` fill-proxy heuristic; `:eigen_reml`/`:auto` in `_coerce_fit_target` + `fit_animal_model`.
- `src/HSquared.jl` — export `fit_eigen_reml`.
- `test/runtests.jl` — 5 new testsets: indefinite-MME single-effect (9), multi-effect sibling (5),
  iteration-count guard (5), eigen fitter + `target=:eigen` (11), `target=:auto` routing (6).

**Docs / status:**
- `docs/design/capability-status.md` — experimental Eigen-once row (count stays 5).
- `docs/design/validation-debt-register.md` — `V1-EIGEN-REML` row + `V1-REML` update (new guards).
- `AGENTS.md` + `docs/dev-log/phase-snapshot-archive.md` — Live Phase Snapshot updated (old entry archived).
- `docs/dev-log/handover/2026-07-24-claude-handover.md` — SUPERSEDED-in-part correction banner.
- New: `docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-{diagnosis-ultraplan,findings}.md`,
  `…-eigen-fitter-r-bridge-contract.md`, `docs/dev-log/check-log.d/2026-07-24-ai-reml-convergence-diagnosis.md`.

## Checks run and exact outcomes

- `julia --project=. -e 'using Pkg; Pkg.test()'` — **GREEN** at every stage (5 runs across the session);
  final run `Testing HSquared tests passed`; new testsets 9/9, 5/5, 5/5, 11/11, 6/6; no regressions.
- Totoro (real-signal): n=1000–10000 converge 5–8 iters, `relative_change_tolerance`, ĥ²≈0.48–0.51.
- Totoro (fill-in): factorization 0.7 s of 170 s at random n=10000 → selected inverse is the cost.
- Totoro (symbolic-reuse): 1.3–3.25× on the factorization but ~1× total (factorization is a minority).
- Totoro (eigen crossover): eigen recovers AI to ~1e-8; wins 6.95× at random n=10000, loses on realistic.
- `bash tools/preamble_cap.sh` — CAP OK (8895 B < 14000; 1 snapshot entry).

## Public claim audit

`public_covered_count` stays **5** (verified in `capability-status.md` + `ROADMAP.md`). The eigen fitter is
**experimental / partial**, NOT covered, NOT the public default, NOT wired to R. The "6.95×" and "0.64 s ≤
ASReml 12.9 s" are OFF-CI benchmark numbers recorded in the findings doc, explicitly NOT head-to-head on
Szymek's data. "No convergence bug" is scoped to well-identified interior problems (flat-ridge fixtures can
take dozens of iterations — correct, not fast). Rose audited both the diagnosis and the fitter; all edits applied.

## Tests of the tests

- The PosDef guards were RED-confirmed first (scratch: current code threw `PosDefException`), then GREEN.
- The eigen correctness gate asserts equality to `fit_ai_reml` at rtol 1e-6 (actual ~5e-8; Rose independently
  re-ran → inside bound). The `:auto` routing test uses clearly-separated fill regimes (realistic → sparse,
  random → eigen) so it does not straddle the threshold. Guards (Z≠I, dense-size, kwargs) each `@test_throws`.

## Coordination notes

- **R lane:** `docs/dev-log/native-engine-arc/2026-07-24-eigen-fitter-r-bridge-contract.md` is the handoff for
  the `hsquared` R twin (this Julia lane does NOT edit the R repo). Key point: eigen returns a standard
  `AnimalModelFit`, so the existing `result_payload` normalizer covers it; R adds an opt-in `method="eigen"`
  route + the method-string mapping. A ledger-issue comment should point the R lane at that doc.
- **Brain:** filed a triage note correcting the handover ("A-inverse is fast; converges fine; ordering
  overturned") and corrected it after the /ask-brain sweep found the 2026-06-23 ordering result.

## What did not go smoothly

- The initial `bench_signal.jl` had a scalar-`randn` bug (no residual variance) that smoke-first caught — the
  fit correctly recovered the degenerate data, not an engine fault.
- The `nohup julia … &` over ssh holds the channel (Bash times out); worked around by reading the output FILE.
- I twice over-framed a lever (symbolic-reuse as "the fix"; "add a fill-reducing ordering") — measurement and
  the brain sweep corrected both. Recorded honestly in the findings doc.

## Known limitations

- `fit_eigen_reml` is `Z=I`-only, single-effect, dense `O(n³)` (guarded at `max_dense_n`); the K≥2 case cannot
  be simultaneously diagonalized. The `:auto` fill threshold (60) is a conservative first-pass; the exact
  crossover is a joint fill×n surface. None of this is covered/public.
- The multi-effect PosDef path has no `termination_reason` field (that function doesn't track one) — it stops
  gracefully via `converged=false`, matching its existing break paths.

## Next actions

1. **Owner:** review + merge the PR (no auto-merge).
2. **R lane:** implement the R `method="eigen"` route from the bridge contract; confirm `public_covered_count`
   stays 5.
3. **Promotion (experimental → covered):** a pre-declared multi-seed recovery gate + an external same-estimand
   comparator (ASReml/blupf90) + a Rose audit — flagged in `V1-EIGEN-REML`.
4. **Refine `:auto`:** move the threshold to the joint fill×n crossover (chip spawned).
5. **Szymek:** close the loop — not broken, "slow" understood, fill-in-aware fast path exists.
