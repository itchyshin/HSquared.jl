# Handover: W1 DRAC evidence week → Codex (cross-tool, sequential baton)

Meta: 2026-06-29 · from Claude (solo this week, Codex out) · to Codex (has the live Julia/DRAC toolchain).
Read order: `AGENTS.md` → this doc → `docs/design/18-programme-plan-2026-06.md` (durable plan) →
`docs/dev-log/after-task/2026-06-29-w1-drac-evidence-week.md`. The baton is **sequential, never parallel**.

## 1 · Mission-control

| Repo | Branch / head | CI | What shipped | Next by leverage |
| --- | --- | --- | --- | --- |
| HSquared.jl | `w1/2026-06-29-evidence-week-setup` @ `ea72fd7f` (pushed; **no PR yet**, no auto-merge) | not run on branch | doc-18 plan mirror; S0 generated board (R1 fixed); S1 bootstrap draw-once; S2 V4 factorial+gate; 2 DRAC campaigns RUN + banked | 1. Maintainer G10 on the V4 scoped-finish. 2. C1 medium follow-up. 3. Open the W1 PR (Rose first). |
| hsquared (R) | clean `main` `8c5c886` (#112) | green | untouched this week | mirror status only after a Julia covered move |

## 2 · State (verify live before acting — frozen numbers go stale)

- `validation_status()` = 48 (5/3/39/1); **public-covered fitting = 1**; `V1-HERIT-TCAL` `planned`.
  **Nothing promoted this week.** Confirm with `git -C . log --oneline -1` + `gh pr list`.
- Held docs PRs **#193** (closeout) and **#191** (handover) are still open, untouched (maintainer's call).

## 3 · Never-stage (verbatim — never `git add -A`)

- `docs/dev-log/recovery-checkpoints/2026-06-22-r-twin-nongaussian-per-record-trials-spec.md`
- `sim/phase6_nongaussian_interval_coverage.tsv`

## 4 · DRAC state (fir, `def-snakagaw_cpu`)

| campaign | job | cluster | state | result | evidence |
| --- | --- | --- | --- | --- | --- |
| smoke | 46235170 | fir | COMPLETED | pipeline OK | — |
| C2 V4 recovery | 46235637 | fir | COMPLETED | R9 CLEAN; 5/8 pass | `docs/.../2026-06-29-w1-c2-v4-broaderdgp-*` |
| C1 interval coverage | 46236262 | fir | COMPLETED | σ²a delta under-covers; profile best | `docs/.../2026-06-29-w1-c1-interval-coverage*` |

- **Clean W1 checkout** at `~/projects/def-snakagaw/HSquared.jl` (fresh clone, branch `w1/...`).
- **The prior Wave-F checkout is preserved** at `~/projects/def-snakagaw/HSquared.jl.waveF-backup-20260629`
  (it was dirty — uncommitted `Project.toml`/`src/likelihood.jl`/`src/pedigree.jl` at #178). **Maintainer:
  review/recover or discard.** Shared depot: `~/projects/def-snakagaw/julia_depot`.
- Per-cell raw outputs live under `sim/drac/results/w1_{v4,interval}/` on fir (not in git; the summaries are).

## 5 · What needs the live toolchain / maintainer (your queue)

1. **V4 scoped-finish (E10), maintainer G10 — non-delegable.** C2 shows recovery holds on the covered
   scope + balanced/moderate cells but has two honest boundaries (the ~5% σ²a G[1,1] bias, now detectable
   at larger n; single-record × extreme-r_g). Decide: scope the covered claim to where recovery holds +
   document the boundaries, **or** investigate (does the G[1,1] bias shrink with more iterations / a
   bias correction?). Either way: a real **Rose audit** + maintainer sign-off before any covered move.
   The same-estimand `sommer` leg already exists; this is the doc-33 path-(b) recovery half.
2. **C1 medium follow-up.** Re-run `sim/drac/phase1_interval_coverage.sbatch` with the medium design
   (q=240) + larger n_boot, right-sized (medium's bootstrap is the cost — split reps across more tasks).
3. **Open the W1 PR** (`gh pr create` from `w1/2026-06-29-evidence-week-setup`) after a Rose pass; no
   auto-merge. The branch is docs/tools/sim only — no `src/`/`R/` — so `Pkg.test()` behavior is unchanged,
   but run `Pkg.test()` + `docs/make.jl` once on the branch to confirm CI-green before the PR.
4. Optional: the C1 result suggests **profile-LRT is the better existing interval default** — a separate,
   gated slice if the maintainer wants it (would touch the public default → full DoD + Rose + G10).

## 6 · How to rehydrate (you HAVE the live toolchain)

```sh
module load julia/1.10.10
export JULIA_DEPOT_PATH=$HOME/projects/def-snakagaw/julia_depot   # on fir
# local: PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. -e 'using Pkg; Pkg.test()'
# refresh the board count live: julia --project=. tools/gen_status_json.jl --refresh-count
ssh fir   # SLURM only, never login-node compute; depot on /project
```

## 7 · Gotchas

- Don't `git add -A` (the two foreign files). Don't promote without G11 + Rose + G10. DRAC evidence is
  TRIAGE until a gate clears. The R9 rule is armed in the ADEMP (a `base_inside`-class failure = STOP).
  The `:8791` board is the canonical control-centre — regenerate `status.json` via the generator, never
  hand-edit. totoro = UAlberta CPU box (no SLURM), not for arrays.
