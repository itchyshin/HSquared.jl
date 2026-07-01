# v0.6 nine-PR integration — VERIFIED merge recipe (2026-07-01)

Meta: 2026-07-01 · Claude solo · produced by a throwaway trial-merge (`trial/v06-verify-4b07b3`, since
discarded) and audited by a real `rose-systems-auditor` (**verdict: PROMOTE**). This is **non-destructive
verification prep** — it was **NOT merged to `main`** (the maintainer merges) and it **flips NOTHING to
covered** (the covered flip / "G10" is a separate, maintainer-only decision that wants a final full-chain
Rose). `Pkg.test()` was **GREEN** on the integrated tree; `validation_status()` = **50**; public-covered
fitting = **1** — all unchanged from `main`.

## Purpose

Hand the maintainer an exact, mechanical recipe to merge the 9 open v0.6 PRs (#215–#223) onto `main`, with
every conflict pre-resolved and the integration proven to build + pass tests. The trial branch that verified
this was discarded per instruction; re-running the steps below reproduces the verified tree.

## Baseline (assumed)

- `main` @ `94d20319` — `validation_status()` 50 rows (covered 8 / covered_external 3 / partial 38 /
  planned 1); `tools/status_cache.json` `public_covered_count` = 1.
- If `main` has moved, Merge 1 will no longer fast-forward; the conflict resolutions below still apply (they
  are content-based, not line-number-based).

## The 9 PRs → 4 tips (each tip carries its chain; all four branch directly off `main`)

| Order | Tip branch | PRs carried | Notes |
| --- | --- | --- | --- |
| 1 | `origin/feat/2026-07-01-v06-ordinal-recovery` | #215 → #218 → #220 | ordinal joint-fit → clmm comparator → 48-seed gate |
| 2 | `origin/feat/2026-07-01-v06-gamma-recovery` | #216 → #217 → #219 | gamma joint-fit → glmmTMB comparator → 48-seed gate; also carries the AGENTS.md snapshot bullet, `tools/status_cache.json`, and the session handovers |
| 3 | `origin/feat/2026-07-01-v06-ordinal-observed-h2` | #221 → #223 | h² threshold/ordinal-observed (#223 stacked on #221) |
| 4 | `origin/feat/2026-07-01-v06-gamma-latent-h2` | #222 | h² Gamma latent + data scale |

Ancestry verified: each tip has `origin/main` as its merge-base; #215→#218→#220 and #216→#217→#219 are
linear chains; #221 is an ancestor of #223.

## Commands

```sh
git fetch origin
git checkout -b <integration-branch> origin/main
git merge origin/feat/2026-07-01-v06-ordinal-recovery       # MERGE 1 — fast-forward, NO conflict
git merge origin/feat/2026-07-01-v06-gamma-recovery         # MERGE 2 — 3 conflicts
git merge origin/feat/2026-07-01-v06-ordinal-observed-h2    # MERGE 3 — 2 conflicts
git merge origin/feat/2026-07-01-v06-gamma-latent-h2        # MERGE 4 — 5 conflicts
```

The trial used `--no-ff` on merges 2/3/4; fast-forward-vs-merge-commit does not change any resolution below.

## Per-merge conflict resolution — ALL are "keep both / combine"

> Reconstruct cleanly; do NOT accept a git tangle. Where a family's own row/testset/`elseif` differs from the
> stale base version, keep the **updated** one; where two families both add to the same row, **weave both**.

### MERGE 1 — ordinal chain — CLEAN
Fast-forward (`main` is an ancestor of the ordinal tip). No conflicts.

### MERGE 2 — gamma chain — 3 conflicts
`src/validation_status.jl` and `test/runtests.jl` **auto-merge** (V6-ORDINAL vs V6-GAMMA rows / the two
family-fit testsets are far enough apart). Resolve:

1. **`src/nongaussian.jl`** — `fit_laplace_reml`:
   - **allow-list**: keep BOTH new symbols →
     `family in (:gaussian, :poisson, :bernoulli, :binomial, :nbinom, :beta_binomial, :bernoulli_probit, :ordered_probit, :gamma)`,
     and the error message ending `..., :bernoulli_probit, :ordered_probit, or :gamma`.
   - **the two `elseif` blocks**: keep BOTH complete blocks — `elseif family === :ordered_probit … return …`
     then `elseif family === :gamma … return …`. ⚠️ The two blocks contain an **identical `catch err … end`**
     (inside their objective closures), so git splits this into TWO conflict hunks around that shared middle.
     Do NOT resolve hunk-by-hunk (it interleaves the two objectives into a tangle). Reconstruct each `elseif`
     as a complete, independent block, each keeping its OWN copy of the shared `catch…end`.
2. **`docs/design/capability-status.md`** — the adjacent ordinal / gamma family rows tangle. HEAD =
   [ordinal **UPDATED**, gamma **STALE**]; theirs = [ordinal STALE, gamma **UPDATED**]. Keep the **ordinal row
   from HEAD** + the **gamma row from theirs** (each side's own updated row; drop the two stale copies).
3. **`docs/design/validation-debt-register.md`** — same pattern for `V6-ORDINAL` / `V6-GAMMA`: ordinal from
   HEAD, gamma from theirs.

### MERGE 3 — ordinal-observed h² — 2 conflicts
`src/nongaussian.jl` (the `_nongaussian_h2_core` region), `src/validation_status.jl` (the V6-NS-H2 row), and
`test/runtests.jl` (a new testset) all **auto-merge** — untouched by merges 1/2. Resolve:

1. **`docs/design/capability-status.md`** — HEAD = [ordinal UPDATED, gamma UPDATED, **V6-NS-H2 STALE**];
   theirs = [ordinal STALE, gamma STALE, **V6-NS-H2 UPDATED**]. Keep the two **family rows from HEAD** and the
   **`V6-NS-H2` row from theirs**.
2. **`docs/design/validation-debt-register.md`** — same: family rows from HEAD, `V6-NS-H2` from theirs.

### MERGE 4 — gamma-latent h² — 5 conflicts (the big combine)

1. **`src/nongaussian.jl`** — `_nongaussian_h2_core` (5 hunks). Combine:
   - **signature kwargs** → `; cutpoints = nothing, shape::Float64 = NaN`
   - keep **BOTH** new `elseif` branches: `elseif family === :bernoulli_probit || family === :ordered_probit …`
     (the full probit/ordinal branch, incl. the per-category `h2_observation_by_category` vector) **then**
     `elseif family === :gamma …` (the full gamma trigamma-latent + data branch).
   - the **`else` throw** → one combined message listing all supported families:
     `"nongaussian_heritability supports :gaussian/:poisson/:bernoulli/:binomial (observation scale),
     :bernoulli_probit/:ordered_probit (liability scale), and :gamma (latent/log scale, V_link = trigamma(shape));
     family :$family is follow-up (beta-binomial / negative-binomial overdispersion each need their own
     link-variance derivation)"`.
   - **`_h2_family_params`**: keep all three specific methods (`::BernoulliProbitResponse`,
     `::OrderedProbitResponse`, `::GammaResponse`) and the fallback throw ending `(follow-up: beta-binomial,
     negative-binomial)`.
   - **both `nongaussian_heritability` method tails**: thread BOTH — compute `cp` (ordered_probit cutpoints)
     AND `sh` (gamma shape) and call `_nongaussian_h2_core(…; cutpoints = cp, shape = sh)`.
   - `_trigamma` (new function from gamma-latent, near line 268) **auto-merges** clean.
2. **`src/validation_status.jl`** — combine the `V6-NS-H2` row: take HEAD (threshold+ordinal) as the base and
   splice in the two gamma pieces from theirs — (a) the `"Gamma (log): … V_link = ψ₁(shape) … ~5e-11
   (comparator/qgglmm_gamma_observed/)."` block inserted after `"log-normal–Poisson closed form. "` (before
   `"Gaussian reduces…"`); (b) the `"the _trigamma closed forms … data 0<h²<1), "` Validated item inserted
   after `"the Gaussian reduction, "`. In the **owed** field, move Gamma-data from owed → done (keep MCMCglmm +
   Fisher/Falconer owed). Row stays `partial`.
3. **`docs/design/capability-status.md`** — same `V6-NS-H2` combine (add the trigamma term to the V_link enum;
   add the `GAMMA DATA/observation scale now computed too:` block; in the comparator sentence mark ordinal-K>2
   + Gamma-data RUN+AGREES, leave MCMCglmm + Fisher/Falconer owed). Family rows from HEAD.
4. **`docs/design/validation-debt-register.md`** — same `V6-NS-H2` combine.
5. **`test/runtests.jl`** — ⚠️ **CRITICAL 3-way-merge trap.** HEAD adds the probit/ordinal h² testset, theirs
   adds the Gamma h² testset, both at the SAME anchor and both closed by a **single shared trailing `end`**
   that git deduplicates. Keeping both `@testset … begin … end` blocks means you must **ADD ONE `end`** to
   close the FIRST (probit/ordinal) testset before the second (Gamma) `@testset` begins. Stripping only the
   three conflict markers leaves the first testset unclosed → a `ParseError` reported at **EOF** (`include`
   parses top-level expressions incrementally, so earlier testsets still run and the error surfaces on the
   last block, ~line 8399 — misleading). `Meta.parseall` does NOT catch this; use `Pkg.test()` or an
   incremental `Meta.parse` that inspects for `:error`/`:incomplete` nodes.

`docs/design/19-h2-scale-contract.md`, the `AGENTS.md` snapshot bullet, and `tools/status_cache.json` come
from single branches — **no conflict**.

## Verification (performed on the integrated tree `743c62de`; re-run after your merge)

- `env OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using Pkg; Pkg.test()'` → **GREEN**
  (`Testing HSquared tests passed`, exit 0; v0.6 testsets: ordinal 62/62, ordinal joint-fit 10/10, Gamma
  31/31, Gamma joint-fit 6/6, H7 heritability 25/25, probit/ordinal liability+observed h² 21/21, Gamma
  latent+data h² 16/16).
- Count guard `@test length(validation) == 50` **HOLDS**; `validation_status()` = 50 rows, distribution
  unchanged (covered 8 / covered_external 3 / partial 38 / planned 1).
- `tools/status_cache.json` `public_covered_count` = **1** (unchanged; only the cosmetic `refreshed_from_head`
  provenance hash differs). `V6-ORDINAL` / `V6-GAMMA` / `V6-NS-H2` all remain **partial**.
- `nongaussian_heritability` verified for gaussian, poisson (latent NaN), bernoulli, binomial,
  bernoulli_probit, ordered_probit (per-category vector `h2_observation_by_category`, scalar `h2_observation`
  NaN), and gamma (trigamma latent).
- `fit_laplace_reml(family=:ordered_probit)` and `(family=:gamma)` run end-to-end and converge.
- No conflict markers anywhere in `*.jl` / `*.md` / `*.json`.

## Rose audit — VERDICT: PROMOTE

A real `rose-systems-auditor` independently re-ran every check (extracted each branch's added `nongaussian.jl`
lines and confirmed the only non-verbatim lines are exactly the mutually-exclusive combine points; loaded the
package and tallied `validation_status()`; re-ran the full suite to exit 0; diffed `status_cache.json` against
main). Verdict: **the integration is a faithful, honest reconstruction of the four branch tips — no content
dropped, no semantics altered, no markers/tangle, suite green, every honesty pin exact. Safe to hand to the
maintainer.** No overclaim was introduced by the merge.

## Pre-existing follow-ups (record; do NOT fix during the merge — a faithful merge preserves branch content)

Both are **pre-existing on the source branches** and were faithfully preserved. Both **understate** (never an
overclaim) and neither touches the covered flip. They belong on the maintainer's post-merge / G10 list.

1. **`nongaussian_heritability` docstring imprecision** (`src/nongaussian.jl`, from PR #223): says the ordinal
   (K>2) per-category observed scale "needs the cutpoints and stays a follow-up (`h2_observation = NaN`)". The
   *scalar* `h2_observation` IS genuinely NaN for ordinal, so it is literally true but understates that the
   function now returns the `h2_observation_by_category` vector.

2. **V6-ORDINAL recovery-gate three-surface staleness** (from PR #220 commit `49098cdd`, which updated only
   the debt register): the 48-seed ordinal recovery gate PASSED
   (`docs/dev-log/recovery-checkpoints/2026-07-01-ordinal-recovery-48seed.md`), and
   `docs/design/validation-debt-register.md` records it — but `src/validation_status.jl` (V6-ORDINAL `missing`
   field) still lists "a pre-declared recovery gate" as owed, and `docs/design/capability-status.md` still says
   "No recovery gate yet." **These three surfaces must be brought into lockstep before any ordinal covered
   promotion** (a covered row cannot list its own passing gate as owed). V6-GAMMA already has this right on all
   three surfaces — the pattern the ordinal row should match.

   Minor/cosmetic: `tools/status_cache.json` `refreshed_from_head` (`195e05a9`) / `refreshed_at`
   (`2026-06-30`) are stale provenance stamps; the numeric pins are correct.

## Honesty

This verifies INTEGRATION and hands a recipe. It does **not** merge to `main` and flips **nothing** to covered
— engine-covered ≠ R-public-covered; public-covered fitting stays 1. The G10 covered flip for the
ordinal/gamma families is a separate maintainer decision that wants a final full-chain Rose (and, per follow-up
2 above, the V6-ORDINAL surface lockstep first).
