# Handover to Codex — 2026-06-24

**You are Codex, picking up the HSquared.jl + hsquared twin program.** This note
was written by the Claude session that did the work below. You work in the **same
repo** (`HSquared.jl`) and its R twin (`hsquared`). `AGENTS.md` is your native
instruction file — read it first; this is the session-specific "what just happened +
what's next." Repository state is the source of truth.

---

## 0. The mission (unchanged)

Finish the **two twin packages**:
- **`hsquared`** (R) — the public user language. `/Users/z3437171/Dropbox/Github Local/hsquared`.
- **`HSquared.jl`** (Julia) — the engine. `/Users/z3437171/Dropbox/Github Local/HSquared.jl`.

"**Finish**" = the **v0.1 covered contract** (univariate Gaussian animal model) is
solid, validated, public; **everything beyond stays `experimental`/`partial`** until
it earns the full evidence chain. **Public-default covered count = 1 (Gaussian). Do
not grow it without the gate** (impl + tests + docs + capability-status row +
validation-debt row + Rose audit + clean checks + external comparator where the gate
names one).

---

## 1. Current state (repo = truth)

| Repo | `main` | CI |
| --- | --- | --- |
| HSquared.jl | `06c7e71b` (#189) | green |
| hsquared | `8c5c886` (#112) | **green** (first time — see §2) |

`validation_status()` = **48 rows**; covered (public) = **1** (Gaussian). Nothing was
promoted this session.

**⚠️ Two FOREIGN untracked files in HSquared.jl — NEVER commit them** (not ours):
- `docs/dev-log/recovery-checkpoints/2026-06-22-r-twin-nongaussian-per-record-trials-spec.md`
- `sim/phase6_nongaussian_interval_coverage.tsv`

Always `git add <explicit paths>` in HSquared.jl; never `git add -A`/`.`.

---

## 2. What the Claude session did since taking over

A NotebookLM methods scout surfaced four leads (A–D); all resolved, plus parity +
hygiene. Per-slice evidence is in `docs/dev-log/after-task/` and the prior
tool-agnostic handover `docs/dev-log/handover/2026-06-24-session-handover.md` (read it
for the full A–D detail — not duplicated here).

| Slice | Result |
| --- | --- |
| **A** em_warmup EM-REML warm-start (`fit_ai_reml`) | ✅ #186. Default `0` = byte-identical; optimum-invariant on identified fits; rescues bad-start convergence; NOT a #182 fix. |
| **B** log-variance reparam | ❌ tried → reverted. Numerically unstable AND #182 is already correct (non-identified → `converged=false`). Honest negative. |
| **C** G1 GPU VanRaden `G`/`Ginv` | ✅ #187. Ran on tamia (4× H100, job 352612): CPU↔GPU ~1e-14; GEMM 1.3×→~5×, ridge Ginv ~2.7–2.9×. |
| **D** `preconditioner=:ichol` for `solve_animal_model_pcg` | ✅ #188. IC(0) + Manteuffel shift; correctness primitive (matches direct ~1e-15; 21→19 Jacobi→16 IC(0) iters). No perf claim. |
| **R-twin parity for A** | ✅ hsquared #111. `em_warmup` via `hs_control(engine_control=…)` → bridge → `fit_ai_reml`. Live-verified, optimum-invariant (VC diff 5.3e-9). |
| **R CI greened** | ✅ hsquared #112. The pre-existing `R/validation-status.R` non-ASCII WARNING was a single em-dash → escaped to `—` (runtime output identical). `devtools::check` now 0/0/0; merged on the first green hsquared CI. |
| **Handover + snapshot** | ✅ #189 (docs-only). |

**Banked finding (evidence-based, not yet a repo debt row):** HSquared.jl intervals
are **all asymptotic** — normal-z for Wald/delta (`_standard_normal_quantile`,
e.g. `heritability_interval(:delta)` the default h² CI) and χ²₁ for profile-LRT
(`q = z*z` at `src/likelihood.jl:1491`). There is **no small-sample t-calibration**
(`qt`/df) anywhere; the object self-labels `interval_method = "asymptotic_reml"`. The
only finite-sample-aware path is the parametric **bootstrap**
(`bootstrap_variance_component_interval`, C6) — opt-in, not coverage-calibrated. See
§4 candidate 3 and `~/.claude/memory/methods-small-sample-t-calibration.md`.

**Five real Rose audits this session — all CLEAN. Nothing promoted to covered.**

---

## 3. Your operating contract (Codex)

- **`AGENTS.md` is native — read it.** It is the source of truth (Claude reads it via
  `CLAUDE.md` → `@AGENTS.md`; you read it directly).
- **Your team mirror is `.codex/agents/*.toml`** (Ada orchestrator, Rose auditor, and
  the review scientists — `gauss`, `curie`, `fisher`, `henderson`, `mrode`, `hopper`,
  etc.). **Rose's claim-vs-evidence audit is MANDATORY before any public/repo-visible
  claim.**
- **Division of labour (you run the live toolchain).** The standing Claude↔Codex split:
  Codex runs **real R/TMB + Julia fits, `R CMD check`, simulations, Documenter/pkgdown
  rendering**; Claude plans/refactors/writes prose + pure-logic. Lean into the live
  evidence — that is your comparative advantage here.
- **Live env (matters — `julia` is NOT on `PATH` by default):**
  ```sh
  export PATH="$HOME/.juliaup/bin:$PATH"
  export HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl"
  export NOT_CRAN=true        # so testthat::skip_on_cran() does not skip live-bridge tests
  ```
- **Standard checks (run locally before pushing — cost discipline):**
  ```sh
  julia --project=. -e 'using Pkg; Pkg.test()'      # engine
  julia --project=docs docs/make.jl                  # engine docs
  # hsquared (R): devtools::test(); devtools::check(document = FALSE, args = "--no-manual")
  ```
- **Disciplines (load-bearing):** honest status (no fitting/perf/GPU claim without the
  full chain); one PR per slice; full Definition of Done; never commit the two foreign
  files; the R repo must never promise unimplemented Julia capability.

---

## 4. The plan — next moves by leverage

1. **Engine GPU (Track B, experimental).** G1 Float32 + device-resident `G` (for G2
   chaining) → G2 (GBLUP/GREML on GPU) → G3 → G4 → G5. The CPU↔GPU agreement harness +
   tamia sbatch already exist under `sim/drac/`. Track A: deep-pedigree re-measure
   (F2 re-open) toward an eventual F4 default-path promotion.
2. **External-comparator evidence (the only gate to a covered promotion).** A 2nd
   same-estimand REML comparator for `V4-MV-REML`; coverage calibration for the
   non-Gaussian families (V6-*). This is the real prize — nothing moves to `covered`
   without it. You can run these live (ASReml/BLUPF90/sommer/JWAS) — high value.
3. **Small-sample t-calibration for intervals (NEW candidate, cross-repo).** Found NOT
   implemented (§2). Cheap mechanically (swap normal-z → `qt(df)` and `q = z*z` →
   `q = t²`), but the **df is the hard part**: `n − p` is wrong for an animal model
   (BLUPs are integrated out) — use a design-based df (≈ independent families/
   individuals − variance components) or a sim-calibrated effective df, then **validate
   by a coverage sim**. Shared interest with drmTMB/gllvmTMB. **First easy slice:** add
   a `validation-debt-register.md` row capturing this (it is not banked there yet),
   then a Wald-t prototype behind a coverage sim. Reference:
   `~/.claude/memory/methods-small-sample-t-calibration.md`.
4. **Housekeeping.** Keep the `AGENTS.md` Live Phase Snapshot refreshed per after-task.

Pick by leverage. If a direction is genuinely the owner's call, ask before committing.

---

## 5. Pointers (the durable detail)

- **Full A–D detail:** `docs/dev-log/handover/2026-06-24-session-handover.md` +
  `docs/dev-log/after-task/2026-06-23-{px-em-warmstart,g1-gpu-genomic,d-ichol-pcg-preconditioner}.md`
  + hsquared `docs/dev-log/after-task/2026-06-24-r-twin-em-warmup-parity.md`.
- **Status/contract:** `docs/design/01-v0.1-contract.md`,
  `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`,
  and `validation_status()` (48 rows).
- **NotebookLM methods KB** (cross-project — HSquared/DRM/GLLVM): notebook id
  `3b3d2ec5-7779-41ee-b968-22623c80278b`. Leads (incl. unmined PX-AI full, Takahashi
  selected inverse) banked in `~/shinichi-brain/memory/LEARNINGS.md` (this session =
  "UPDATE 3 (2026-06-24)").
- **DRAC/tamia runbook** (verified this session): `~/shinichi-brain/tools/drac-setup.md`.
- **Cross-project methods notes:** `~/.claude/memory/methods-small-sample-t-calibration.md`,
  `~/.claude/memory/design-missing-data-drmtmb-gllvmtmb.md`.
- **Sibling repos** (process patterns, not statistical code): `drmTMB`, `gllvmTMB`,
  `DRM.jl`, `GLLVM.jl`.
