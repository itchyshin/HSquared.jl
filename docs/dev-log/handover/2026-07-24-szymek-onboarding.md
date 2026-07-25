# START HERE — Szymek onboarding (developing HSquared.jl / hsquared with Claude Code)

Welcome. This repo pair is a Julia computational engine + its R user package for quantitative-genetic
mixed models. This note is for **you** (read it) and for **your Claude** (point it here). It's the
fast path to being productive without tripping the guardrails.

## The two repos (the "twin")
- **`HSquared.jl`** — the **Julia engine**. Does the actual computation (REML/AI-REML fitting, sparse
  linear algebra, genomic matrices). This is where the fit-performance work lives.
- **`hsquared`** — the **R package**. The user-facing language (what a breeder types). Calls Julia.
- **Rule:** a Claude session in one repo edits ONLY that repo. R claims must match Julia reality.
  If you're not sure which repo owns a change, ask (or check `AGENTS.md`).

## Your first session (do this every time)
1. Open the repo in Claude Code. It auto-reads `CLAUDE.md` → `AGENTS.md` — the operating doctrine.
   **Don't fight it; it encodes how this project works.**
2. Tell Claude: **"rehydrate with hsquared-rehydrate"** (a skill that loads live git/CI/roadmap state),
   then **"read `docs/dev-log/handover/2026-07-24-claude-handover.md`"** — the current entrypoint.
3. That's it — Claude now knows the full state and won't re-discover.

## Five things about how this repo *thinks* (so Claude's caution makes sense)
1. **Evidence-gated.** Claude here will NOT claim a fitter "works / is production-ready" without the
   full chain: tests → a **pre-declared recovery gate** (frozen before it runs) → an **external
   comparator** (sommer / ASReml / BLUPF90) → a **Rose audit** (a skeptic sub-agent) → owner sign-off.
   That conservatism is the point — it's why current evidence is **"staged, not promoted."**
2. **Repo state is truth, not chat.** The memory lives in files: `ROADMAP.md`,
   `docs/design/capability-status.md` (what's actually validated), `docs/dev-log/`. Trust those.
3. **Stage, don't flip.** Marking a capability "covered" or making any public claim is a deliberate
   **owner (G10)** decision, gated behind a fresh Rose audit. See "What needs Shinichi" below.
4. **Smoke-first + real compute.** Always run a tiny version before an expensive one. Heavy sims run
   on a server, not your laptop (see Compute).
5. **Honest status.** No fitting/performance/GPU claim without the evidence. If Claude says "I can't
   claim that yet," it's doing its job.

## Your workflow (practical)
- **Plan mode for anything big.** Let Claude propose a plan and approve it before it acts. For large
  multi-step work, ask it to use the **`ultra-plan`** skill (decompose → sub-agents → verify).
- **Local checks before pushing:** `julia --project=. -e 'using Pkg; Pkg.test()'` and
  `julia --project=docs docs/make.jl`. This repo prefers local checks over burning CI minutes.
- **Don't auto-merge.** Open a PR; the maintainer merges.
- **Leave the "foreign" dirty files alone.** Four files in the tree belong to a PAUSED genomics thread
  (D1) — they're listed in the handover; never stage them.
- **Small, focused commits.** Never `git add -A` (it would grab the foreign files).

## Compute — the one real gotcha for you
The doctrine mentions **Totoro** and **DRAC** clusters. Those are configured for **Shinichi's** login
(his SSH sockets, his Duo). **You cannot use them** — they're his credentials. For heavy runs you need
**your own** compute: your own Totoro/DRAC account, or run at smaller scale locally. The recovery gates
in the latest work ran ~15 min on a 384-core server; on a laptop, shrink `n`/seeds and smoke first.
Tell your Claude what compute YOU have so it scales to that.

## Your actual problem — the fit_ai_reml performance you reported
Your original "REML fit is broken / slow" report was **diagnosed** (read
`docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md`):
- **Not broken.** With real genetic signal it converges in **5–7 iterations** (the earlier "never
  converges" was a stale checkout + no-signal test data — two confounds, both fixed).
- **The "slow" is fill-in.** On a well-structured pedigree it's already fast (n=10,000 ≈ 0.6 s;
  q=300,000 ≈ 2.3 s). It only walls on **high-fill / highly-interconnected** pedigrees at large n
  (measured: q=20,000 high-fill = 25 min), driven by the selected-inverse.
- **What to do for YOUR pedigree:** use `fit_animal_model(spec; target = :auto)` — it routes by your
  pedigree's actual fill. If your data is normal-fill field data, it already scales. If it's high-fill
  AND large (n>20k), the lever is **F6** (a matrix-free PCG solver — already benchmarked, needs wiring
  into the fit loop; see `docs/dev-log/recovery-checkpoints/2026-07-24-f0-adversarial-highfill-decision.md`).
  That's a well-scoped first project if you want one.
- **Validating against ASReml:** the comparator pattern is in `comparator/` (we use `sommer`). Adapt
  it to feed your ASReml variance components + compare — same-estimand REML should agree to ~1e-4.

## What needs Shinichi (not yours to decide unless he says so)
- **Flipping any capability to "covered" / any public claim** = his G10 sign-off. You can develop +
  generate evidence freely; the promotion is his call. **Clarify with him whether he's delegating G10
  to you** — if yes, you own it (and should still run the Rose audit first).
- **Editing the R twin from the Julia repo** (or vice versa) — respect the boundary.

## Quick cheatsheet
```
# start a session (in the repo)
claude "rehydrate with hsquared-rehydrate + docs/dev-log/handover/2026-07-24-claude-handover.md"
# big change → plan first, approve, then let it run
# before pushing:
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=docs docs/make.jl
# heavy sim → smoke locally first, then run on YOUR compute
```
Authoritative current state: `docs/dev-log/handover/2026-07-24-claude-handover.md`. Ask your Claude to
spawn **Rose** before any "it works / it's ready" claim — that's the house rule, and it's a good one.
