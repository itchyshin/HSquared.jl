# Verified full 9-PR v0.6 integration — merge recipe (2026-07-01)

**Purpose.** De-risk the maintainer's merge of the 9 open v0.6 PRs (#215–#223) by
running the **entire** integration in a throwaway branch, resolving every conflict,
and confirming the integrated suite is green with all honesty pins intact. This
document is the mechanical recipe; it is NOT the merge itself (autonomous push to
`main` is blocked by policy — the maintainer merges).

**Status: VERIFIED GREEN.** `Pkg.test()` passed on the integrated tree;
`validation_status()` = 50 rows (covered 8 / covered_external 3 / partial 38 /
planned 1) — **identical to `main`**, nothing flipped to covered;
`tools/status_cache.json` `public_covered_count` = 1 unchanged. Trial branch
`trial/v06-full-integration` off `origin/main` @ `94d20319` (discarded after this
recipe was written).

## PR → branch-tip map (the 4 tips cover all 9 PRs; each chain is stacked)

| Chain | PRs (base→tip) | Tip branch to merge |
| --- | --- | --- |
| Ordinal family | #215 → #218 → #220 | `origin/feat/2026-07-01-v06-ordinal-recovery` |
| Gamma family | #216 → #217 → #219 | `origin/feat/2026-07-01-v06-gamma-recovery` |
| h² threshold/ordinal-observed | #221 → #223 | `origin/feat/2026-07-01-v06-ordinal-observed-h2` |
| h² Gamma latent+data | #222 | `origin/feat/2026-07-01-v06-gamma-latent-h2` |

Because #218/#220 are stacked on #215 and #217/#219 on #216, merging each **tip**
brings its whole chain. #223 is stacked on #221 (tip = `ordinal-observed-h2`);
#222 is standalone off `main`.

## Merge order + per-merge resolution (exactly what was done)

```
git checkout -b trial/v06-full-integration origin/main         # 94d20319
git merge --no-edit origin/feat/2026-07-01-v06-ordinal-recovery     # 1) CLEAN
git merge --no-edit origin/feat/2026-07-01-v06-gamma-recovery       # 2) conflicts A
git merge --no-edit origin/feat/2026-07-01-v06-ordinal-observed-h2  # 3) conflicts B
git merge --no-edit origin/feat/2026-07-01-v06-gamma-latent-h2      # 4) conflicts C
```

### 1) ordinal-recovery — CLEAN (first onto main, no overlap).

### 2) gamma-recovery — 3 conflicts, all **keep-both**
- `src/nongaussian.jl` (`fit_laplace_reml`): keep BOTH family allow-list entries
  (`:ordered_probit` AND `:gamma`) and BOTH `elseif` estimator branches. The
  git-collapsed shared `catch/end` tail must be **duplicated** so each function
  (`objord`, `objg`) has its own.
- `docs/design/capability-status.md` + `validation-debt-register.md`: **semantic**
  keep-both — each branch updated ONE row and left the other at main's original, so
  keep the *updated* V6-ORDINAL (from ordinal side) + the *updated* V6-GAMMA (from
  gamma side); drop the two stale originals. (NOT a naive union — a naive union
  keeps stale rows.)
- `src/validation_status.jl`, `test/runtests.jl`: auto-merged.

### 3) ordinal-observed-h2 — 2 doc conflicts, **3-row semantic keep-both**
- `capability-status.md` + `validation-debt-register.md`: the block spans V6-ORDINAL
  + V6-GAMMA + V6-NS-H2. Keep the updated V6-ORDINAL + updated V6-GAMMA (from the
  current tree) + the **updated V6-NS-H2** (from #221/#223: threshold liability,
  binary observed, ordinal per-category vector, QGglmm probit/ordinal comparators).
- `src/nongaussian.jl`, `src/validation_status.jl`, `test/runtests.jl`: auto-merged
  (h² code lives in `_nongaussian_h2_core`, a different function than `fit_laplace_reml`).

### 4) gamma-latent-h2 (#222) — 5 conflicts, the genuine **COMBINE**
This is the only merge needing content-combination (both sides edit the SAME h²
surfaces):
- `src/nongaussian.jl` (`_nongaussian_h2_core`, 5 regions):
  1. signature: keep BOTH kwargs → `cutpoints = nothing, shape::Float64 = NaN`;
  2. branches: keep the `:bernoulli_probit || :ordered_probit` block AND the
     `:gamma` block, followed by ONE combined `else throw` naming all supported
     families;
  3. `_h2_family_params`: keep all three specific methods (BernoulliProbit,
     OrderedProbit, Gamma) + one fallback throw (follow-up: beta-binomial,
     negative-binomial);
  4. + 5. both dispatchers thread BOTH `cutpoints = cp` AND `shape = sh`.
- `src/validation_status.jl`, `capability-status.md`, `validation-debt-register.md`
  (the V6-NS-H2 row on all three): the tree already had the #221/#223
  threshold/ordinal version; **splice in** the Gamma latent (trigamma `V_link`) +
  Gamma data-scale sentences and flip the "Gamma-data comparator owed" clause to
  "RUN + AGREES (~5e-11 via QGglmm custom Gamma-log model)". Net: the merged
  V6-NS-H2 carries the COMPLETE surface (logit, Poisson, Gaussian, probit liability,
  binary observed, ordinal per-category, Gamma latent+data) with MCMCglmm +
  Fisher/Falconer still the only owed comparator/review.
- `test/runtests.jl`: the two h² testsets ("probit/ordinal LIABILITY + binary-OBSERVED"
  and "Gamma LATENT + DATA-scale") were tangled at one insertion point sharing a
  single `end`. Close the first testset with its own `end`, then let the existing
  `end` close the second.

## Verification (on the integrated tree)

- `env OPENBLAS_NUM_THREADS=1 ~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`
  → **passed** (incl. the count guard `@test length(validation) == 50`).
- `validation_status()` = **50** (covered 8 / covered_external 3 / partial 38 /
  planned 1) — identical to `main`.
- `public_covered_count` = **1** (unchanged; only the cosmetic `refreshed_from_head`
  hash differs in `status_cache.json`).
- `nongaussian_heritability` reachable for gamma (`method=:gamma_trigamma_latent`),
  ordinal (per-category vector, scalar `h2_observation`=NaN), probit (liability +
  binary observed).
- 50 files added vs `main` (comparators, sims, recovery checkpoints, code).
- NOT run on the throwaway: `julia --project=docs docs/make.jl` — the real merge
  should run it (the doc edits are markdown-table only, structurally safe).

## Follow-ups the REAL merge should fold in (pre-existing, NOT merge-introduced)

**Rose audit of the integration → PROMOTE-WITH-CHANGES** (all pins independently
re-confirmed: `Pkg.test()` green, count 50, split unchanged vs main, nothing flipped to
covered, `public_covered_count` 1; comparator artifacts real — probit 4.45e-6, ordinal
3.17e-8, Gamma-data 5.07e-11; `_nongaussian_h2_core` two-branch + single `else throw`,
`_h2_family_params` three methods + one fallback, both dispatchers thread `cutpoints`+`shape`;
`06-public-claims-register.md` untouched). One REQUIRED fix + two nice-to-haves:

### REQUIRED (5th merge step — NOT a git conflict, so a mechanical merge misses it)
- **`src/validation_status.jl` — the V6-NS-H2 `claim_boundary` field (7th tuple element).**
  Both branch tips inherited this string identically from `main`; #221/#223 updated the
  `evidence`/`missing` fields to "QGglmm RUN + AGREES" but LEFT the 7th field saying
  "has NO external-comparator (QGglmm/MCMCglmm) evidence" — so the merged row
  **self-contradicts** (and `validation_status()` prints it to users). Git does NOT flag
  it (no conflict). The real PR (#221/#223) — or the maintainer, in the merge — MUST apply:
  - **Before:** `…flagged \`information_limited\`) and has NO external-comparator (QGglmm/MCMCglmm) evidence and no Fisher/Falconer sign-off on the decomposition. Exported but experimental…`
  - **After:** `…flagged \`information_limited\`); the QGglmm external comparator is RUN + AGREES (logit / binary-probit / Poisson / binomN / ordinal-K>2 / Gamma-data; ≤4.5e-6) but an MCMCglmm comparator and a Fisher/Falconer sign-off on the decomposition are still owed. Exported but experimental…`
  - Verified on the trial branch: count stays **50**, `V6-NS-H2` stays `partial`, contradiction gone.

### NICE-TO-HAVE (for the real PRs, not blocking the merge)
- The per-family **G10 covered flip** (ordinal/gamma) needs its OWN full-chain Rose on the
  actual #219/#220 PR — this integration Rose is NOT that flip audit. (The V6-GAMMA debt
  cell already says so; just don't conflate the two.)
- `sim/.v2gate_run.log.txt` (a dot-prefixed 5-line run log) rode into the diff — confirm it
  is meant to be tracked, else `.gitignore` it before the real PRs land.

## Honesty fence

Merging these 9 PRs is **additive/experimental** — it does NOT flip any capability
to covered. The G10 covered flip (public-covered fitting 1 → 3 for ordinal + gamma)
is a SEPARATE, non-delegable maintainer decision and is out of scope for the merge.
