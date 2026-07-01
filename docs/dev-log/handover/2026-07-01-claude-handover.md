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
### Verified merge recipe (I ran a throwaway trial-merge `main → #220 → #219`, suite green)

Merging the ordinal chain onto `main` is **clean**. Merging the gamma chain then yields **exactly 3
conflicts**, all the trivial "keep both" class (`src/validation_status.jl` + `test/runtests.jl`
**auto-merge** — no manual step):

1. **`src/nongaussian.jl`** — the `fit_laplace_reml` family allow-list + the two `elseif` dispatch
   cases. Keep BOTH: allow-list → `(…, :bernoulli_probit, :ordered_probit, :gamma)` (update the error
   string to match); keep the complete `:ordered_probit` block AND the complete `:gamma` block.
   ⚠️ The naive 3-way merge *tangles* them — both insert a `try/catch` at the same anchor, so git
   interleaves the two objectives around one shared `catch…end`. Do NOT accept the tangle; rebuild as
   two independent `elseif` blocks, each with its OWN `try … catch … end`.
2. **`docs/design/capability-status.md`** — the ordinal + Gamma rows. Keep the ordinal row from the
   ordinal chain (the FULL joint+comparator+gate version) and the Gamma row from the gamma chain (the
   FULL version incl. the rail). One FULL row from each side — not ours/theirs wholesale.
3. **`docs/design/validation-debt-register.md`** — same as (2): ordinal-FULL + Gamma-FULL.

**Verified post-resolution (trial branch, then discarded — never pushed to `main`):** count guard
stays **50**; both families symbol-reachable (`family=:gamma` → shape 28.33; `family=:ordered_probit`
→ cutpoints [0, 0.98]); full `Pkg.test()` **green** on the integrated tree, incl. ordinal JOINT 10/10,
Gamma JOINT 6/6, ordinal kernel 62/62, Gamma kernel 31/31. So the maintainer's merge is mechanical —
apply the 3 resolutions above and the integrated suite is green.

## What is maintainer-gated (NOT autonomous — do not self-do)

1. **Merge the 6 PRs** into `main` (two chains; keep-both on the one conflict class). Autonomous push to
   `main` is blocked by policy; the maintainer merges.
2. **G10 — the covered FLIP.** With joint estimator + agreeing same-estimand comparator + passing
   pre-declared gate, BOTH families now have all doc-16 covered PREREQUISITES. Flipping V6-ORDINAL and/or
   V6-GAMMA `partial → covered` (which would move **public-covered fitting 1 → 3**) is the maintainer's
   non-delegable **G10** call. It also wants a final Rose audit on the full chain. Engine-covered ≠
   R-public-covered — the R surfaces stay experimental regardless.

## Additional PRs this session (h² surface — independent of the 6-PR family chain)

Three more PRs landed, all extending the exported `nongaussian_heritability` (the `V6-NS-H2` row);
each is off `main`, real-Rose-audited, honesty pins intact (count 50, public-covered 1, nothing
flipped). They **compose** — each adds an `elseif` to `_nongaussian_h2_core` + a clause to the same
`V6-NS-H2` row, so at merge they are **trivial keep-both** with each other:

- **[#221](https://github.com/itchyshin/HSquared.jl/pull/221)** — ordinal/probit **liability**-scale h²
  (`V_A/(V_A+1+V_fixed)`, probit `V_link=1`, Dempster–Lerner). Rose **PROMOTE (clean)**; CI green.
- **[#222](https://github.com/itchyshin/HSquared.jl/pull/222)** — Gamma **latent**-scale h²
  (`V_A/(V_A+ψ₁(ν)+V_fixed)`, `V_link=trigamma(shape)`, verified numerically). Includes the doc-19 §3.1
  decision resolving the Gamma `V_link` (trigamma, NOT the lognormal approx). Rose **PROMOTE (clean)**.
- Both are EXACT closed forms with verified constants → no recovery gate / same-estimand comparator
  owed for those values. The **observation/data** scale for BOTH threshold and Gamma remains fenced
  (`h2_observation = NaN`) — the genuine next follow-up, and it wants a QGglmm/MCMCglmm external
  comparator (doc-19 §5), so it's best done with external validation, not a closed-form guess.

## Follow-ups (not covered blockers)

- Scale-labelled h²: ordinal **liability** (#221) + Gamma **latent** (#222) DONE; the **observation/data**
  scale for threshold + Gamma is the remaining doc-20 Step-4 piece. **Status by piece:**
  - **BINARY threshold observed-0/1 scale — DONE + EXTERNALLY VALIDATED (#221).** QGglmm probit
    integration `Ψ²V_A/[p̄(1−p̄)]`, verified EQUAL both to the Dempster–Lerner transform (Rose's
    independent 20000-pt Simpson quadrature → 1.2e-6 + an analytic proof) AND to the actual **QGglmm
    0.8.0 package** (`QGparams(model=binom1.probit)`, ≤4.5e-6 over 9 cases;
    `comparator/qgglmm_probit_observed/`). The doc-19 §5 external-comparator debt is **DISCHARGED** for
    this scale. Rose PROMOTE (+ 3 doc-fixes applied).
  - **LOGIT (Bernoulli) observed scale — EXTERNALLY VALIDATED (#221).** The pre-existing logit
    observation scale also agrees with QGglmm `binom1.logit` (≤2.5e-6) — its external-comparator debt is
    **DISCHARGED** too.
  - **Gamma LATENT scale — DONE (coded in #222).** `V_link=trigamma(ν)` (doc-19 §3.1).
  - **QGglmm is now installed (CRAN 0.8.0) + a comparator harness exists**
    (`comparator/qgglmm_probit_observed/compare.R`). KEY convention it pinned (the internal DL/quadrature
    checks could NOT): QGglmm's `var.p` for the observation integration is the PREDICTOR variance
    `V_A+V_fixed`, NOT `V_A+V_link+V_fixed`. So the remaining comparators are now unblocked-with-QGglmm:
    - **Binomial(n>1) + Poisson observed scales — DONE + EXTERNALLY VALIDATED (#221).** QGglmm
      `Poisson.log` (≤1.7e-16, machine precision) + `binomN.logit` (≤1.2e-8) agree with the engine — so
      **all FOUR QGglmm-builtin observation scales** (logit, probit, Poisson, binomN; 25 comparisons)
      are now externally discharged. Rose PROMOTE-clean.
    - **ORDINAL (K>2) observed/category scale — owed (non-builtin).** QGglmm's ordinal support + the
      per-category vs per-threshold convention need checking. A careful follow-up.
    - **Gamma data/observation scale — owed.** QGglmm has NO built-in Gamma model — it needs a CUSTOM
      model spec (inverse-link `exp`, var.func `μ²/ν`, d.inv.link `exp`) with the shape ν. Finicky; a
      careful follow-up (do NOT rush the custom var.func).
  This is the honest boundary the overnight session stopped at: the DONE pieces are internally
  cross-checked AND (for the two observation scales) externally validated against QGglmm; the owed pieces
  need either an easy builtin run (Poisson/binomN) or careful convention work (ordinal, Gamma-custom).
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
