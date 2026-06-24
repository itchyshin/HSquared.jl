# Session handover — 2026-06-24 (the A→D "stop-today" list CLOSED + R-twin parity)

**Audience: the next session, whether Claude Code _or_ Codex.** This file is the
"START HERE." Repository state is the source of truth; this is the at-a-glance map.

---

## 0. The mission (unchanged)

Finish the **two twin packages**:

- **`hsquared`** (R) — the public user language (formula grammar, `hs_control`,
  extractors). Path: `/Users/z3437171/Dropbox/Github Local/hsquared`.
- **`HSquared.jl`** (Julia) — the computational engine (pedigree/genomic relationship
  matrices, REML/AI-REML, EBVs/BLUPs). Path:
  `/Users/z3437171/Dropbox/Github Local/HSquared.jl`.

"**Finish**" = the **v0.1 covered contract** (univariate Gaussian animal model) is
solid, validated, and public; **everything beyond it stays honestly fenced** as
`experimental`/`partial` until it earns the full evidence chain (implementation +
tests + docs + capability-status row + validation-debt row + Rose audit + clean local
checks + clean CI). **Public-default covered count = 1 (Gaussian). It must not grow
without the gate.**

---

## 1. Where we are right now (repo = truth)

| Repo | `main` | Notes |
| --- | --- | --- |
| HSquared.jl | `95c82b1a` (#188) | `validation_status()` = **48 rows**; covered (public) = **1** (Gaussian) |
| hsquared | `4fa4b16` (#111) | R CI red ONLY on a pre-existing non-ASCII warning (see §6) |

**⚠️ Two FOREIGN untracked files in HSquared.jl — NEVER commit them** (they are not
ours; leave them alone):
- `docs/dev-log/recovery-checkpoints/2026-06-22-r-twin-nongaussian-per-record-trials-spec.md`
- `sim/phase6_nongaussian_interval_coverage.tsv`

Always `git add <explicit paths>`, never `git add -A`/`.` in HSquared.jl.

---

## 2. What this session landed (the A→D list, all closed)

A NotebookLM methods knowledge base (id `3b3d2ec5-7779-41ee-b968-22623c80278b`; leads
banked in `shinichi-brain/memory/LEARNINGS.md`) surfaced four improvement leads. All
four were resolved, plus the R-twin parity:

| Slice | Result |
| --- | --- |
| **A** — opt-in EM-REML warm-start in `fit_ai_reml` (`em_warmup`) | ✅ **Merged #186.** Default `0` = byte-identical. **Optimum-invariant** on identified fits; **rescues bad-start convergence** (a `(1e4,1e-2)` start non-converged at em=0 → converges at em≥3). Does **NOT** fix #182. |
| **B** — log-variance / log-Cholesky reparam | ❌ **Tried → reverted.** Naive log-reparam of the AI step is numerically unstable, AND #182 is already correct (non-identified → `converged=false` is the right answer, not a bug). Honest negative banked. The lead is still sound for **multivariate PD covariance** (V4 G0/R0), not the univariate model. |
| **C** — Wave F G1 GPU VanRaden `G`/`Ginv` | ✅ **Merged #187 (RAN on tamia, 4× H100, job 352612).** CPU↔GPU agreement **~1e-14** across all variants; benchmark **GEMM 1.3×→~5×** (m 2k→40k) / **ridge Ginv ~2.7–2.9×**. `V2-GRM-GPU` rows flipped to "GPU-agreed + benchmarked". |
| **D** — `preconditioner=:ichol` for `solve_animal_model_pcg` | ✅ **Merged #188.** Right-looking IC(0) + Manteuffel shift. **Correctness primitive** (matches direct solve ~1e-15; ≤ plain-CG iters: 21 → 19 Jacobi → **16 IC(0)**). No performance claim. |
| **R-twin parity for A** | ✅ **Merged hsquared #111.** `em_warmup` exposed via `hs_control(engine_control = list(em_warmup = k))` → bridge → `fit_ai_reml(...; em_warmup = k)`. **Live-verified**: well-formed call + optimum-invariant (VC diff 5.3e-9 on the Mrode fixture). |

**B/C/D need no R parity:** B was reverted; C is experimental engine-GPU (NOT covered —
R's `backend`/`accelerator` stay "planned"); D is an internal solver primitive with no R
surface. So the Julia→R parity owed this session is **complete**.

**Five real Rose audits this session — all CLEAN.** **Nothing promoted to covered.**

Per-slice evidence: `docs/dev-log/after-task/2026-06-23-{px-em-warmstart,g1-gpu-genomic,d-ichol-pcg-preconditioner}.md` and hsquared `docs/dev-log/after-task/2026-06-24-r-twin-em-warmup-parity.md`; check-logs in each repo.

---

## 3. Rehydrate FIRST (before any substantial work)

### If you are **Claude Code**
1. Run the **`hsquared-rehydrate`** skill (live git/CI + the doc set).
2. Read, in order: this handover → `AGENTS.md` (Live Phase Snapshot) → `ROADMAP.md` →
   `docs/dev-log/coordination-board.md` → `docs/dev-log/check-log.md` → the newest
   after-task reports (§2) → `docs/design/01-v0.1-contract.md` →
   `docs/design/capability-status.md` → `docs/design/validation-debt-register.md`.
3. Skills live in `.claude/skills/`; review-lens subagents in `.claude/agents/`
   (spawn `rose-systems-auditor` — **mandatory** for any public claim).

### If you are **Codex**
1. `AGENTS.md` is read natively — start there, then this handover, then the same doc
   set listed above (all plain Markdown in the repo).
2. The team mirror is `.codex/agents/*.toml` (Ada orchestrator, Rose auditor, the
   review scientists). Rose's claim-vs-evidence gate is still mandatory.
3. **You run the live toolchain** (this is the Claude↔Codex division of labour): real
   R/TMB + Julia fits, `R CMD check`, simulations, Documenter/pkgdown rendering.

### Live-bridge / live-check environment (either tool)
`julia` is installed at `~/.juliaup/bin/julia` but is **NOT on `PATH`** by default.
To run the R↔Julia live bridge or any live test:
```sh
export PATH="$HOME/.juliaup/bin:$PATH"
export HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl"
export NOT_CRAN=true          # so testthat::skip_on_cran() does not skip live tests
```
Engine checks: `julia --project=. -e 'using Pkg; Pkg.test()'` and
`julia --project=docs docs/make.jl`. R checks: `devtools::test()`,
`devtools::check(document = FALSE, args = "--no-manual")`, `devtools::document()`.

---

## 4. Immediate next steps (prioritized)

1. **(R CI unblock — quick win)** Resolve the pre-existing `R/validation-status.R`
   non-ASCII WARNING (escape σ²/h²/≈ to `\uxxxx`, or relax the workflow's
   `error-on` from `"warning"`). This is the ONLY thing keeping hsquared `main` CI red.
   A background-task chip already captures it. (`devtools::check` is otherwise
   `0 errors | 1 warning | 0 notes`.)
2. **(Housekeeping)** Keep the `AGENTS.md` Live Phase Snapshot refreshed per after-task
   (done in this handover).
3. **(Engine, experimental)** Remaining Track B GPU: G1 Float32 + device-resident `G`
   (for G2 chaining) → G2 (GBLUP/GREML on GPU) → G3 → G4 → G5. Track A: deep-pedigree
   re-measure (F2 re-open) toward an eventual F4 default-path promotion.
4. **(The real prize — covered promotions)** External-comparator evidence is the gate
   for moving anything from `partial`/`experimental` to `covered`: a 2nd same-estimand
   REML comparator for `V4-MV-REML`; coverage calibration for the non-Gaussian families
   (V6-*). No covered promotion without it.

Pick by leverage; #1 is cheap and unblocks clean R merges. Use `AskUserQuestion` if the
direction is genuinely the owner's call.

---

## 5. Standing disciplines (do not drop — these are load-bearing)

- **Honest status.** No fitting/performance/GPU/genomics claim without the full evidence
  chain. Repo state — not chat, not memory — is the source of truth.
- **Rose is mandatory** before any public/repo-visible claim. Run the real
  `rose-systems-auditor` (Claude) / Rose `.codex` agent; address its flags.
- **One PR per slice; full Definition of Done** (AGENTS.md): impl + tests + docs +
  capability-status row + validation-debt row + check-log + after-task report + Rose +
  clean local checks (+ clean CI if pushed).
- **Local checks over CI** (cost discipline): run `Pkg.test()`/`docs/make.jl` and
  `devtools::check()`/`test()` locally before pushing.
- **Twin contract:** the R repo must never promise Julia capabilities that are not
  implemented + validated + recorded in `capability-status.md`. Do not edit the R
  repo's claims from the engine lane carelessly.
- **Never commit the two foreign untracked files** (§1); stage explicit paths.

---

## 6. Open items, debts, and resources

- **Background-task chip (pending):** fix the `R/validation-status.R` non-ASCII warning
  → greens hsquared CI (see §4.1).
- **NotebookLM methods KB:** id `3b3d2ec5-7779-41ee-b968-22623c80278b` (personal Google
  account; query via the `notebooklm` skill). Banked leads in
  `shinichi-brain/memory/LEARNINGS.md` — remaining unmined: full **PX-AI** (beyond the
  warm-start base), **Takahashi selected inverse** (= TMB's "inverse subset"; HSquared's
  natural sparse-SE primitive), Hadfield/Nakagawa MCMC priors. Useful for DRM + GLLVM
  teams too.
- **Retained validation debts** (from AGENTS.md): V4-MV-REML 2nd comparator + in-suite
  unstructured-`sommer` test + broader-DGP recovery + deep-inbreeding boundary; the
  fitted-Mrode confrontation; non-Gaussian coverage calibration.
- **Cross-session memory:** `shinichi-brain/memory/LEARNINGS.md` (this session's
  close-out is "UPDATE 3 (2026-06-24)") and `~/.claude/memory/memory_summary.md`.
