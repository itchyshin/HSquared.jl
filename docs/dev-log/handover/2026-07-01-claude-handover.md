# Handover → next Claude / maintainer — v0.6 non-Gaussian covered-READY (2026-07-01)

Meta: 2026-07-01 · from Claude · autonomous overnight segment (maintainer away). Supersedes
`2026-06-30-claude-handover-v04-v06.md` (that doc's PR numbers #211–#214 are already MERGED into
`main` @ `94d20319`; this doc covers the six PRs that came after).

## Mission-control snapshot

| Field | State |
| --- | --- |
| Programme goal (`/goal`) | *finish — Fast & Accurate Algorithms for Mixed & Latent-Variable Model Fitting (HSquared · DRM · GLLVM)* — long-horizon, not a one-session finish |
| `main` | `94d20319` — count **50**, covered **8**, **public-covered fitting = 1** (v0.1 Gaussian). Both v0.6 KERNELS (ordinal + Gamma) already merged; rows present as `partial` |
| Open work | **6 stacked PRs** (#215–#220): the v0.6 ordinal + Gamma JOINT estimators + same-estimand comparators + pre-declared recovery gates. All experimental/`partial`. NONE flips covered |
| This segment | Hardened the Gamma joint estimator (σ²a + shape-ν **safety rail**) after a runaway-shape bug on uninformative data; re-confirmed the 48-seed gate byte-identical post-rail. Landed on **#219** |
| Honesty pins | count **50**, public-covered fitting **1**, no "unbiased" wording, engine-covered ≠ R-public-covered. Covered FLIP = maintainer **G10** only |
| Rose (this slice) | see "Rose verdict" below |

## What this segment did (on top of the 6-PR chain)

The v0.6 ordinal + Gamma families were already **covered-READY** at the start of this segment: each has
(1) a JOINT estimator, (2) a same-estimand comparator that AGREES, and (3) a PASSING pre-declared
48-seed recovery gate. This segment closed one robustness gap found while verifying the Gamma payload:

- **Bug:** `fit_laplace_reml(...; family = :gamma)` returned a runaway shape `ν ≈ 4e5` on a tiny,
  uninformative test fixture — the Gamma shape is weakly identified through a flat large-`ν` likelihood
  when there is no replication.
- **Fix (`7666b656`, on #219):** a SAFETY RAIL confining both `log σ²a` and `log ν` to `init ± 8`
  (return a finite penalty outside; an estimate at a rail = "not credibly identified at this design"),
  plus a `try/catch` returning a finite penalty on Singular/PosDef/Domain errors. This **mirrors the
  ordinal σ²a guard** (Rose principle: one weakly-identified scalar rail implies the sibling needs it
  too). The Phase-2 Gamma-fit test fixture was switched from a 12-animal pedigree to an **A = I /
  repeated-records** design (q=6 × 4 reps) so `ν` is identified, with a bounded assertion
  (`0 < ν < 1e4`). Status text updated on all surfaces.
- **Inert-on-identified-data proof (`195e05a9`, on #219):** re-ran the pre-declared 48-seed recovery
  gate against the post-rail committed code — reproduces the table **byte-for-byte**
  (`gate_pass=true`, 48/48; σ²a bias −0.0033/MCSE 0.0089; ν bias −0.0019/MCSE 0.0434). The rail did
  not relax the gate; it can only bind on pathological/uninformative data.

DoD checks this segment: full `Pkg.test()` green (count guard `== 50` intact) · `docs/make.jl` exit 0 ·
Gamma payload verified to carry the joint-estimated `shape` via the family-uniform
`nongaussian_result_payload` passthrough (Phase 3 satisfied-by-construction) · board refreshed
(`rows=50 covered=8 public_covered=1`).

## The six open PRs (all `partial`, none flips covered)

Two independent **stacked** chains off `main`:

| Chain | PRs (merge order) | Tip branch | What it adds |
| --- | --- | --- | --- |
| **Ordinal** | #215 (joint) → #218 (comparator) → #220 (recovery) | `feat/2026-07-01-v06-ordinal-recovery` @ `49098cdd` | `fit_laplace_reml(family=:ordered_probit)` joint cutpoint+σ²a estimation; `ordinal::clmm` same-estimand comparator agrees; 48-seed gate PASSES |
| **Gamma** | #216 (joint) → #217 (comparator) → #219 (recovery **+ rail**) | `feat/2026-07-01-v06-gamma-recovery` @ `195e05a9` | `fit_laplace_reml(family=:gamma)` joint σ²a+shape estimation; `glmmTMB Gamma(link="log")` comparator agrees; 48-seed gate PASSES; **the rail fix above** |

- Each PR is based on the previous in its chain (`gh pr view <n> --json baseRefName`). Each recovery
  **tip** is cumulative (contains its chain's joint + comparator commits).
- **No count-guard change across the merge** — `main` is already at 50; the joint fits EXTEND the
  existing `V6-ORDINAL` / `V6-GAMMA` row evidence, they do not add rows.
- **One cross-chain conflict class** (both chains touch the same anchors in `src/nongaussian.jl` +
  `test/runtests.jl`): the `fit_laplace_reml` family dispatch / allow-list, and the two adjacent
  joint-estimation testsets. **Resolution: keep BOTH the `:ordered_probit` and `:gamma` cases /
  testsets** — they are non-overlapping. Verify with a throwaway trial-merge before finalizing (the
  prior-handover discipline).

## What is maintainer-gated (NOT autonomous — do not self-do)

1. **Merge the 6 PRs** into `main` (two chains; keep-both on the one conflict class). Autonomous push to
   `main` is blocked by policy; the maintainer merges.
2. **G10 — the covered FLIP.** With joint estimator + agreeing same-estimand comparator + passing
   pre-declared gate, BOTH families now have all doc-16 covered PREREQUISITES. Flipping V6-ORDINAL and/or
   V6-GAMMA `partial → covered` (which would move **public-covered fitting 1 → 3**) is the maintainer's
   non-delegable **G10** call. It also wants a final Rose audit on the full chain. Engine-covered ≠
   R-public-covered — the R surfaces stay experimental regardless.

## Follow-ups (not covered blockers)

- Scale-labelled h² transform for ordinal (liability/observation) + Gamma (observation) — doc-20 Step 4.
- Broader-DGP + pedigree-A (non-`I`) recovery designs for both families (current gates are A=I / q=80).
- Second same-estimand comparator per family (MCMCglmm `threshold` for ordinal; a 2nd Gamma tool).
- R formula/bridge activation for ordinal + Gamma families (currently engine-internal only).

## Rehydration recipe for the next session

1. Run the `hsquared-rehydrate` skill (live git/CI + `ROADMAP.md`, coordination board, check-log,
   newest after-task, `docs/design/capability-status.md`, `validation-debt-register.md`).
2. Read this handover + the two recovery checkpoints (`docs/dev-log/recovery-checkpoints/
   2026-07-01-{gamma,ordinal}-recovery-48seed.md`) + the two comparator checkpoints.
3. Confirm honesty pins on `main`: `grep public_covered tools/status_cache.json` → 1; count guard
   `test/runtests.jl:174` `== 50`.
4. Spawn a real `rose-systems-auditor` before ANY covered claim.

## One-command resume (paste in an authenticated terminal)

```
claude "Rehydrate from docs/dev-log/handover/2026-07-01-claude-handover.md; the v0.6 ordinal+Gamma chains (#215–#220) are covered-READY and await maintainer merge + G10. Continue with the doc-20 Step-4 scale-labelled h² transform, or prep the merge trial."
```

## Rose verdict (this segment's Gamma rail slice, #219)

A real `rose-systems-auditor` subagent audited the slice → **PROMOTE-WITH-CHANGES** (all applied).
Rose independently **re-ran the 48-seed gate** (byte-identical: gate_pass=true, 48/48, σ²a bias
−0.0033/MCSE 0.0089, ν bias −0.0019/MCSE 0.0434) and the **full suite** (green, count guard `== 50`),
reasoned that the rail sits ~3000× from the gate optimum on both axes so it **can only bind on
pathological data** (verified inert, not masking a bias), and confirmed **no overclaim** (V6-GAMMA
`partial` on all surfaces; `public_covered=1`; covered flip reserved to G10).

The three required changes were pure **documentation-lockstep** drift — I had updated the new fixture
text on `validation_status.jl` + `validation-debt-register.md` but (a) missed `capability-status.md`
(stale "structured-pedigree sire-signal fixture" text), and (b) left the runtime owed-field
self-contradictory (listing the comparator + recovery gate as *owed* when both are *done*). All three
fixed (commit after this doc): `capability-status.md` fixture text + owed list corrected; the
`validation_status()` V6-GAMMA evidence field now records the passed 48-seed gate and the owed field
drops the done items. The three honesty surfaces now agree. No code, test, or gate change; count
stays 50.
