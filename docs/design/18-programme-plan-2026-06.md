# 18 · Programme plan (2026-06) — to completion across both twins

Status: **living programme plan** — the durable, Codex-visible store of the cross-twin plan.
Authored from live repo state + the Julia/R phase maps + the bridge map + the plan-history digest +
three domain meetings (Engine/Validation, Bridge/R-lane, Coordination) + three ultraplan panels
(integrate, red-team, transfer). It records **durable science** (phases, gates, the dependency DAG,
campaign specs, estimates). It does **not** hold live commit/PR numbers or a day-by-day calendar — those
go stale and live in the latest `docs/dev-log/handover/` doc + the generated `status.json`. **Counts are
generator-derived; never hand-quote them** (see §Widget). The only durable honesty pins:
`validation_status()` = 48 rows and **public-covered *fitting* surface = 1** (the v0.1 univariate
Gaussian animal model). This doc claims no capability; the status tables remain the source of truth.

Twin-lane analogue/companion docs: `11-completion-plan.md` (milestone runway), `16-promotion-gate-predicates.md`
(the covered bar), `14-program-backlog.md` (the slice catalogue), `12-bridge-compatibility.md` (bridge).

## Operating mode + compute

**Auto-mode + stop-and-ask.** AUTO: write tests/oracles, implement *planned* slices, run *pre-declared*
sims, ingest results, draft docs, local checks, regenerate `status.json`, branch commits, smoke runs.
**STOP + ASK** (err toward more): scope/approach uncertainty; an important finding (a gate passes or
**fails**, a surprise, a bug in shipped code); a decision (covered promotion, default/API/wording change,
comparator choice, version label); a cluster needs connecting; an outward action (merge, non-docs PR to
`main`, posting); compute beyond the pre-declared budget; a Rose-flagged claim risk; **a covered-claim
regression** (see Risks R9).

**Per-slice rhythm (test → sim → validate):** failing test/oracle → minimal impl → deterministic in-suite
test → opt-in recovery/coverage sim with a *pre-declared, committed* gate → external same-estimand
comparator (G11) where a numeric claim is made → real **Rose** audit → maintainer **sign-off**.

**Compute topology:**

| Host(s) | CPU | GPU | SLURM | Use |
|---|---|---|---|---|
| totoro (UAlberta Biology) | ✅ | ❌ | ❌ (direct) | small CPU tests/sims; not large arrays |
| fir, nibi, rorqual, trillium, narval (DRAC general) | ✅ | ✅ | ✅ | CPU arrays (rorqual/trillium 192c) and GPU |
| tamia, vulcan, killarney (DRAC PAICE) | — | ✅ only | ✅ | GPU work (Track B) |

Accounts `def-snakagaw_cpu`/`_gpu` (+ `aip-snakagaw`). **Depot on `/project`; SLURM only on DRAC, never
login-node compute; predeclaration committed before any `sbatch` (hard, permanent gate).** Connections
drop — verify reachability before any run; if a needed host is down, STOP and ask for it (batched).

## Workers — sequential, never parallel

Claude and Codex are **one baton, passed via `docs/dev-log/handover/`** — exactly one works the repo at a
time; never simultaneous. Claude = `[solo]` engine slices + DRAC end-to-end (when it holds the baton) +
docs + review fan-out. Codex = live R/TMB + JuliaCall, real fits, `R CMD check`, heavy comparators, all
`needs-R`/`bridge` work. Maintainer = covered-promotion sign-off (G10), outward posting, credential
decisions — non-delegable. "Parallel" here only ever means: DRAC job-array fan-out, subagent
review/search fan-out within one session, and order-free `[solo]` slices — never two committers.

## Phase maps — distance-to-gate governs execution; the version ladder is release-naming only

Release ladder (naming): v0.1 Gaussian ✅ → v0.2 genomic → v0.3 standard-QG → v0.4 multivariate (+4B FA)
→ v0.5 QTL → v0.6 non-Gaussian → v0.7 GPU → v0.8 HPC → **v0.9 R↔Julia bridge consolidation** → v1.0 release.
**The lanes number their phases differently** (the engine by capability layering, R by what-users-get-next);
they are not a shared coordinate system, so execution is ordered by *distance to the covered gate*, not by
phase/version number. **The R↔Julia bridge is one-way (R calls Julia via JuliaCall; Julia never calls R) and
is the load-bearing adoption feature** (R audience + Julia speed). Bridge activation happens AS-YOU-GO — each
covered engine model should get its R-facing exposure + parity test alongside — with **v0.9** the dedicated
consolidation/hardening + the production-fitting execution path (the master gate). Honest current state: the
engine leads; the R-lane bridge activation for the covered models (V4-MV, V3-two-effect) is owed.

- Engine (−1…8): 0 scaffold (public default) · 1 Gaussian 🧪 · 2 genomic 🧪 · 3 QG+inheritance 🧪 · 4 MV 🧪 · 4B FA 🧪 (recovery did not pass) · 5 QTL 🧪 · 6 non-Gaussian ⛔ · 7 GPU ⛔ (G0/G1 landed) · 8 HPC ⛔.
- R (0…8): 1 Gaussian ✅ covered · 2 QG 🧪 · 3 MV 🧪 · 4 FA-diagonal 🧪 · 5 genomic+single-step 🧪 · 6 non-Gaussian 🧪 · 7 inheritance ⛔ · 8 scale ⛔.

## Bridge — built far past covered; not the bottleneck

~15 wired opt-in `target=` paths (ai_reml/sparse_reml/henderson_mme/repeatability/two_effect/multivariate/
nongaussian/genomic/single_step/single_step_construct/metafounder/metafounder_single_step/snp_blup/
random_regression). Real forward gaps (5): (b) custom-kernel relationship marshalling; (c) FA/low-rank
eigenbasis payload; (e) `marker_scan()` formula + calibrated genome-wide thresholds; (f) production fitting
execution (the master gate); (g) structured-fit covariance SEs. Reclassified out: (a) live `HSData` object
marshalling = a by-design boundary (array decomposition IS the contract); (d) per-record `n_trials` =
already closed at formula level. **The bottleneck is G11 evidence + production fitting, not plumbing.**

## What's left to completion — by distance to gate

The covered bar = generic floor **G1–G11** (`16-promotion-gate-predicates.md`). **G11** for estimators = a
*pre-declared known-truth recovery gate* (no post-hoc relaxation) + a *same-estimand external REML
comparator*. Bayesian agreement (MCMCglmm/JWAS) never substitutes; doc-33 lets a 2nd passing recovery gate
substitute for a 2nd *open* comparator, but the same-estimand KIND is never waived. Maintainer **G10**
sign-off is non-delegable.

**Same-estimand REML comparator inventory (honest):** `sommer` = the only runnable same-estimand REML leg
today. Owed / not runnable: `pedigreemm` (debt mention only, no invocation), `BLUPF90`/`ASReml`/`DMU`/
`WOMBAT` (binaries absent). Agreement-only — do NOT satisfy G11: `rrBLUP`/`BGLR` (Bayesian/estimated-
variance), `MCMCglmm`, `JWAS`, `AGHmatrix` (G construction).

Priority by closeness to a 2nd covered model:
1. **Multivariate-unstructured — closest.** Engine-covered already; to finish, the broader-DGP recovery
   gate via doc-33 path-(b) (a `sommer` leg + a passing recovery gate already exist — an open door, not a
   wall). A BLUPF90 second lineage is optional hardening, not a blocker. ⚠️ regression risk (R9).
2. **Standard-QG kernels** — **two-effect REML now COVERED (2026-06-30)**; repeatability + RR owed. RR
   **covered aim = k=2 linear reaction norm** (Gaussian + each non-Gaussian family + the genetic GLLVM;
   engine general-`k` stays experimental; `k>2` covered is post-v1.0 via reduced-rank / FA `K_g`) — see
   `docs/dev-log/decisions/2026-06-30-rr-aim-and-nongaussian-family-plan.md`. Per kernel: a committed
   recovery harness + a pre-declared gate + a same-estimand comparator.
3. **Genomic** — engine done; blocked on a same-estimand REML genomic comparator that does not exist yet
   (rrBLUP/BGLR are agreement-only). Realistic path = a BLUPF90 binary (unstarted). Trails correctly.
4. **QTL** — calibrated genome-wide thresholds (null-DGP sims) + `marker_scan()` activation.
5. **Non-Gaussian / GLLVM** — have Poisson/Binomial/probit/NB2/beta-binomial + GLLVM; coverage
   conservative-not-calibrated. PLAN (`docs/dev-log/decisions/2026-06-30-rr-aim-and-nongaussian-family-plan.md`):
   priority by breeding relevance — **T1 ordinal/categorical threshold** (calving ease — top value) →
   Gamma/lognormal → zero-inflated/hurdle; T4 (survival/Tweedie) post-v1.0. Same-estimand comparator =
   **glmmTMB** (Laplace-ML; MCMCglmm/brms/THRGIBBS are Bayesian agreement-only). Scale-labelled h² (latent
   + observation, QGglmm convention). Non-Gaussian + GLLVM RR k=2 per the RR aim.
6. **FA / low-rank — furthest** — recovery did not pass; eigenbasis payload (gap c) not built.

Cross-cutting enablers: fitted Mrode; production sparse fitting (Wave F F4–F8 — the scale enabler);
small-sample interval calibration (`V1-HERIT-TCAL`, planned); the missing-data plan (FIML/Laplace).

## Dependency DAG (serial spine + parallel axes)

The `validation_status()` count-guard (`test/runtests.jl`) forces **one merged row-adding PR at a time** —
a transfer-safety feature (two row-adding PRs cannot strand). Parallelism lives only in DRAC job-arrays,
subagent fan-out, and order-free `[solo]` slices.

```
[solo] INDEPENDENT (any order): A6 widget · interval coverage · MV broader-DGP recovery · two-component interval · coverage study · production-sparse · inheritance kernels
GATED CHAINS: recovery → promote-MV · genomic value-match → GBLUP/GREML covered · calibrated thresholds → R gwas()
NEEDS-R/BRIDGE [Codex]: flip genomic()/single_step()/marker_scan() reserved→parsed · eigenbasis R · metafounder bridge · GLLVM R
NEEDS-EXTERNAL: BLUPF90 binary (optional MV 2nd leg; genomic comparator) · GCTA/statgenGWAS
HARDWARE: GPU G0✅→G1✅→{G2∥G3∥G4}→G5
```

## Mission-control widget — generated single-source-of-truth (A6)

The canonical board is `~/.claude/hsquared-control-centre/` (`index.html` polls `version.txt` + `status.json`
every 8 s, served on `:8791`). Its `status.json` must be **generated, never hand-typed** by
`tools/gen_status_json.jl`, which emits it from machine state: `validation_status()` + `capability-status.md`
+ `git`/`gh`. **Dual-tool-runnable:** read the `validation_status()` count from a committed cached artifact
so Claude (no live Julia) can regenerate the git/PR/DRAC fields, while Codex refreshes the count live.
Hard-pin `public_covered_count: 1` + a `honesty_assert`; label DRAC output `TRIAGE` until a gate passes.
Triggers: regenerate at every slice/stage boundary + every DRAC job state-change; each write bumps
`version.txt`. Retire the duplicate R-only board; demote `docs/src/mission-control.md` to a link. Fallback:
a "stale since <ts>" banner rather than confident wrong numbers. Schema: `generated_at, generator_version,
public_covered_count, honesty_assert, repos[]{name,branch,head,ci}, validation{rows,covered,
covered_external,partial,planned}, current_slice, open_prs[], drac{cluster,job_id,state,seeds_done},
blockers[], next_safe_action`.

## Codex-transfer architecture (the baton is always sequential)

1. **Durable plan = this doc.** It is the Codex-visible store; live numbers + the day-by-day calendar are
   intentionally excluded (they belong to the handoff + `status.json`).
2. **Cold-start Codex handoff → `docs/dev-log/handover/<date>-codex-handover.md` (13 sections):** the
   standing 7-part template + programme additions — a Locked-week + DRAC job table (`campaign | job-id |
   cluster | state | seeds_done/total | TSV path on /project | resumable`); the never-stage foreign-files
   list verbatim; and a toolchain-tuned rehydration recipe that flips the framing (Codex HAS the live
   Julia/DRAC toolchain — exact env: `module load julia/1.10.10`, `JULIA_DEPOT_PATH=/project/def-snakagaw/
   julia_depot`, `ssh fir`, SLURM-only).
3. **6-step baton ritual (symmetric).** Hand-off: commit the branch (`wip:` checkpoint if mid-slice) +
   push → `git diff --check`, note checks not runnable live → write the handoff (`handover-to-codex`
   skill) → append the coordination board → regenerate `status.json` (bumps `version.txt`) → refresh the
   AGENTS snapshot, leave the PR (no auto-merge). Hand-back mirrors it (`handover-to-claude`; the outgoing
   worker runs `Pkg.test` + `docs/make.jl` + DRAC ingest first). **Invariant:** the incoming worker
   rehydrates, then verifies HEAD/PRs against live `gh` before acting (frozen plan numbers go stale fast).
4. **Sync:** durable plan (human decisions, no live numbers) · `status.json` (generated) · coordination
   board (append-only). Outgoing writes all three; incoming reads all three.
5. **Mid-slice safety:** clean `git status` (only the two foreign `??` files; real WIP committed `wip:` +
   pushed) · foreign files untracked + named · branch pushed · DRAC arrays resumable (job-id +
   `seeds_done/total`; TSVs on `/project`) · `status.json next_safe_action` set · **no half-applied
   covered-promotion** (a promotion is atomic — single PR + G10, never spans a hop) · no pending outward action.

## Work-unit estimation

Counts firm-ish (from the backlog); wall-clock fuzzy (DRAC queue + the serial spine + Codex availability
dominate). slice = one DoD PR · set = backlog letter-group · sim = pre-declared DRAC array · validation =
external same-estimand comparator.

| Milestone / track | Sets | Slices left | In-suite tests | DRAC sims | Comparator runs | Effort |
|---|---|---|---|---|---|---|
| Widget + infra | A | ~2 | ~2 | — | — | S |
| Interval calibration | C | ~3 | ~5 | 1 | — | M |
| MV-unstructured (finish) | E | ~2 | ~5 | 1 | 0 needed (doc-33) +1 optional | M |
| Standard-QG | C,D | ~6 | ~12 | 2–3 | 2–3 (sommer) | M–L |
| Genomic | F | ~4 | ~10 | 1–2 | 2–3 (needs BLUPF90 — owed) | M–L |
| Production sparse | B,K | ~5 | ~8 | 1–2 | 1–2 | L |
| QTL | G | ~5 | ~10 | 2–4 | 1–2 (GCTA) | L |
| Non-Gaussian | H | ~4 | ~10 | 2–3 | 1–2 (glmmTMB) | L |
| FA / low-rank | E | ~2 | ~5 | 2 (must pass) | 1 | L |
| GPU (Track B) | G | ~4 | ~6 | agreement+bench | CPU↔GPU | L |
| Inheritance | J | ~7 | ~10 | light | oracle | M |
| HPC | (8) | ~4 | ~4 | distributed | machine | L |
| Release | L | ~3 | ~3 | — | — | M |

Totals (order-of-magnitude): ~50 slices / ~12 sets / ~85 tests / ~15–20 DRAC sims / ~10–12 real
comparator runs / 6 G10 sign-offs. Horizons: **core covered programme** (widget + finish MV + standard-QG
+ genomic + start production-sparse) ≈ 6–8 weeks; **full v0.8** ≈ 3–4 months, hardware/Codex-gated.

## Standing risks

| # | Risk | Sev | Mitigation |
|---|---|---|---|
| R1 | Stale hand-typed control-centre board | High | A6 generator (first); "stale since" banner until then; identify the `:8791` PID before touching it. |
| R2/R3 | Phase-number + count drift across surfaces | Med | A6 derives all counts; only prose pins = `validation_status()`=48 + covered=1; never hand-quote capability-status. |
| R4 | DRAC misuse (login compute, `/scratch` depot, oversized/non-resumable) | High | SLURM only; depot `/project`; `seff` right-size; resumable arrays; predeclaration committed before `sbatch`. |
| R5 | Premature covered claim | High | no covered without G11 + G10; DRAC = TRIAGE until gated; Bayesian ≠ same-estimand REML. |
| R6 | Foreign files staged | Med | never `git add -A`; named verbatim in every handoff + the mid-slice checklist. |
| R7 | totoro misuse | Low | UAlberta CPU box (no GPU/SLURM); small direct runs only. |
| R8 | Auto-merge / auto-post | Med | no auto-merge; outward posting maintainer-only. |
| R9 | **Covered-claim regression** — a broader-DGP cell *inside* an already-covered scope fails its gate | High | **STOP-and-ask** (not a banked negative): narrow the covered row's scope or revisit the promotion. Tag campaign cells inside-scope vs new-scope before launch. |
| R10 | Comparator mislabelling (rrBLUP/BGLR/pedigreemm treated as G11) | Med | `sommer` is the only runnable same-estimand REML leg; the rest are owed or agreement-only. |
