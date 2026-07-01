# v0.6 non-Gaussian h² arc — completion plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **COORDINATION (read first):** As of 2026-07-01 there are **two other active HSquared lanes** — a merge-recipe lane (opened PR #225, a near-duplicate of #224's recipe) and an MCMCglmm-comparator lane (worktree `charming-noether`, branch `feat/2026-07-01-v06-mcmcglmm-h2-comparator`). **Do not start any autonomous task below without first re-checking `gh pr list --state open` + `git worktree list` and confirming no other lane owns it.** Most of this plan is maintainer-gated or cross-repo precisely so it does NOT collide; the one small autonomous task (Task 1.2) is explicitly coordination-gated.

**Goal:** Take the v0.6 non-Gaussian h² arc from "evidence gathered, families covered-READY" (9 PRs #215–#223 open + evidence on PR #224) to its endpoint — ordinal + Gamma families COVERED and the h² surface usable, including R activation.

**Architecture:** The arc is ~90% complete. The two families (ordinal `:ordered_probit`, Gamma `:gamma`) each have a joint estimator + an agreeing same-estimand comparator + a passing 48-seed recovery gate; the h² surface (latent/liability/observation for every family) is implemented and externally validated (QGglmm ≤5e-11, glmmTMB, MCMCglmm probit+ordinal). What remains is **not new engine capability** — it is (a) landing the PRs, (b) the maintainer's covered flip, (c) cross-repo R activation, plus small documentation/verification polish. Honesty pins hold throughout: **nothing flips to covered without maintainer G10; engine-covered ≠ R-public-covered; count stays 50; public-covered fitting stays 1** until the flip.

**Tech Stack:** Julia 1.10 (`~/.juliaup/bin/julia`), the `HSquared` package, `src/nongaussian.jl`, `docs/design/{19-h2-scale-contract,20-v06-ordinal-covered-path}.md`, the `rose-systems-auditor` subagent; R twin `hsquared` (separate repo, R lane) for Phase 3.

---

## Current state (grounding)

- `main` @ `94d20319`; `validation_status()` = 50 (covered 8 / covered_external 3 / partial 38 / planned 1); `public_covered_count` = 1. CI green on all PRs.
- Open: **#215–#220** (ordinal + Gamma families: joint estimation → comparator → recovery gate), **#221–#223** (h² surface: threshold liability + binary observed, ordinal per-category, Gamma latent+data), **#224** (this-arc evidence bundle: recipe + handover + Fisher/Falconer review + verified bias-fence patch + QGglmm/glmmTMB/MCMCglmm comparators), **#225** (other lane's recipe duplicate).
- `nongaussian_result_payload` (`src/nongaussian.jl:841`) already carries `variance_components` (which holds `cutpoints` for ordinal / `shape` for Gamma) — the payload is family-uniform and deliberately heritability-free.
- `nongaussian_heritability(fit)` already surfaces scale-labelled h² (latent/liability/observation/per-category) — **doc-20 Step 4 is satisfied by this function**, not by a payload field.
- Owed, verified, not-yet-applied: the Fisher/Falconer fixes — bias-fence (`docs/dev-log/recovery-checkpoints/2026-07-01-h2-biasfence.patch`, tested green) + the doc-19 §2.3 Dempster–Lerner-ordering sentence (Task 1.1).

---

## Phase 0 — Land the 9 PRs  ·  MAINTAINER-GATED (non-autonomous)

Not an implementation task; a merge the maintainer performs. Included for sequencing.

- [ ] **0.1 (maintainer):** Merge #215–#223 onto `main` using the verified recipe in `docs/dev-log/recovery-checkpoints/2026-07-01-full-v06-merge-recipe.md` (or the other lane's #225 — dedupe first). All conflicts are keep-both / one combine; `Pkg.test()` green post-merge with count 50.
- [ ] **0.2 (maintainer, in-merge):** Apply the field-7 fix (recipe step 5) + `git apply docs/dev-log/recovery-checkpoints/2026-07-01-h2-biasfence.patch` so the merged `V6-NS-H2` row is self-consistent and `:bernoulli_probit`/sparse-ordinal carry `information_limited = true`.
- [ ] **0.3 (verify):** `julia --project=. -e 'using Pkg; Pkg.test()'` green; `grep public_covered_count tools/status_cache.json` → 1; count guard `== 50`. **Gate:** if any red, stop and diagnose before Phase 1.

---

## Phase 1 — Documentation polish  ·  AUTONOMOUS (coordination-gated)

The only net-new autonomous work, and it is small. **Runs AFTER Phase 0 (needs the merged tree) and only after confirming no other lane owns doc-19/doc-20.**

### Task 1.1: doc-19 §2.3 Dempster–Lerner ordering sentence (Falconer correction #3)

**Files:**
- Modify: `docs/design/19-h2-scale-contract.md` (§2.3, the threshold/liability section)

- [ ] **Step 1: Confirm the sentence is absent** — `grep -n "Dempster–Lerner ordering\|z²/\[p(1−p)\] < 1\|0.637" docs/design/19-h2-scale-contract.md`. Expected: no match (the ordering is stated as a transform but not as a directional fact).
- [ ] **Step 2: Add the sentence** to §2.3, immediately after the Dempster–Lerner transform is introduced:

```markdown
Because `z²/[p(1−p)] < 1` for all incidences (maximum ≈ 0.637 at p = 0.5), the
observed-0/1 heritability is ALWAYS smaller than the liability heritability — the
classic Dempster–Lerner ordering (verified empirically: e.g. V_A=1, μ=0 → liability
0.500 vs observed 0.318).
```

- [ ] **Step 3: Verify docs build** — `julia --project=docs docs/make.jl` exits 0.
- [ ] **Step 4: Commit** — `git add docs/design/19-h2-scale-contract.md && git commit -m "docs(v0.6): state the Dempster–Lerner ordering as a fact (doc-19 §2.3, Falconer)"`

### Task 1.2: (conditional) scale-labelled h² convenience on the payload — DECISION, likely NO-OP

doc-20 Step 4 says "surface latent + observation h², never a single unlabeled h²." `nongaussian_heritability(fit)` already does this. The family-uniform `nongaussian_result_payload` is deliberately heritability-free.

- [ ] **Step 1: Decide, do not assume.** Re-read `docs/design/20-v06-ordinal-covered-path.md` Step 4 + Step 5 and the payload docstring (`src/nongaussian.jl:809`). If Step 4/5 requires the labelled h² *inside the payload* (vs. via the separate exported function), that is a design change to a covered-adjacent contract → **do NOT implement autonomously; escalate to the maintainer** (it touches the R-bridge payload shape both twins depend on). If Step 4 is satisfied by the exported `nongaussian_heritability` (the likely reading), record that in the after-task note and treat this task as a NO-OP.
- [ ] **Step 2 (only if maintainer approves a payload change):** add a scale-labelled `heritability` field computed via `nongaussian_heritability(fit)` (a NamedTuple of `(scale => value)` pairs, never a bare ratio), with a round-trip test that a fitted `:ordered_probit`/`:gamma` payload carries the labelled h² and the count guard stays 50. Left unspecified here on purpose — it needs the maintainer's contract decision first.

---

## Phase 2 — Covered flip (ordinal + Gamma)  ·  MAINTAINER-GATED (G10, non-delegable)

The arc's headline. Moves public-covered fitting **1 → 3**. Not autonomous; requires the maintainer's G10 and its own full-chain Rose.

- [ ] **2.1 (maintainer + real Rose):** Spawn a `rose-systems-auditor` on the merged tree for the ordinal + Gamma covered claim specifically — verify each family's doc-16 prerequisites on `main` (joint estimator + agreeing same-estimand comparator + passing pre-declared 48-seed gate), predeclaration-before-result ordering, no "unbiased" wording. This is a DIFFERENT audit from #224's integration Rose (which audited the merge, not the flip).
- [ ] **2.2 (maintainer):** Atomic flip across all three surfaces — `src/validation_status.jl` (`V6-ORDINAL` + `V6-GAMMA` `partial → covered`), `docs/design/capability-status.md`, `docs/design/validation-debt-register.md` — in lockstep. `validation_status()` covered 8 → 10; **count stays 50**; `public_covered_count` 1 → 3 in `tools/status_cache.json` (regenerate via `julia tools/gen_status_json.jl`).
- [ ] **2.3 (verify):** `Pkg.test()` green; the three surfaces agree; scope fence intact (engine-covered, opt-in, NOT the R public default until Phase 3).

---

## Phase 3 — R activation (doc-20 Step 5)  ·  CROSS-REPO, GATED (R lane, not this repo)

Surfaces the families + `nongaussian_heritability` in the R twin `hsquared`. **This repo (HSquared.jl) is the engine lane; the R lane owns this — do NOT edit `hsquared` from here.** Sequenced after Phase 2. Needs a Codex/R-lane baton (live R/TMB bridge) and its own maintainer gate.

- [ ] **3.1 (R lane):** Expose `family = "ordinal"` / `"gamma"` in the `hsquared` formula/`hs_control` surface, marshalling to `fit_laplace_reml(family = :ordered_probit / :gamma)` over the JuliaCall bridge; live-verify a well-formed call + optimum parity (the #111 `em_warmup` parity pattern).
- [ ] **3.2 (R lane):** Expose the scale-labelled `nongaussian_heritability` as an R extractor returning the labelled h² (latent/liability/observation/per-category), never a bare ratio (doc-20 Step 4 contract, R side).
- [ ] **3.3 (R lane + maintainer):** R-public covered decision is SEPARATE from the engine G10 (Rose-risk-5 / V4-MV-REML precedent: engine-covered ≠ R-public-covered). The R public surface stays experimental until its own gate.

---

## Verification (arc-level)

1. **Phase 0:** merged `main` `Pkg.test()` green, count 50, public-covered 1 (pre-flip).
2. **Phase 1.1:** doc-19 §2.3 contains the ordering sentence; `docs/make.jl` exit 0.
3. **Phase 2:** post-flip `Pkg.test()` green, count **still 50**, covered 8→10, public_covered 1→3, three surfaces lockstep, real Rose PROMOTE.
4. **Phase 3:** R live-bridge test green; R public surface labelled + honestly scoped.
5. **Honesty pins (every phase):** no "unbiased"; nothing flips to covered before 2.1's Rose + maintainer G10; engine-covered ≠ R-public-covered.

## Definition of Done (per AGENTS.md)

Per-phase: implementation (where autonomous) + tests + docs + capability-status row + validation-debt row + check-log evidence + after-task report + real Rose audit + clean local checks (+ clean CI if pushed). **Arc DoD:** ordinal + Gamma covered on `main` (post-G10), h² surface usable, R activation landed or explicitly deferred with a debt row. Maintainer G10 gates Phases 0 and 2; the R lane + its maintainer gate own Phase 3.

## Risks / fences

- **Lane collision (primary risk):** two other HSquared lanes are active. Re-check `gh pr list` + `git worktree list` before ANY autonomous task; if a lane owns doc-19/doc-20/the payload, defer to it. Prefer commenting on the mirrored coordination ledger over racing.
- **Covered-regression:** Phase 2's flip must not disturb the count guard (50) or other rows; the flip is additive status-only.
- **Payload-contract creep (Task 1.2):** the family-uniform heritability-free payload is a shared R-bridge contract — do not change it autonomously.
- **Cross-repo discipline:** Phase 3 is the R lane's; this engine lane does not edit `hsquared`.
