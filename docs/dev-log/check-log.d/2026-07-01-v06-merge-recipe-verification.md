# 2026-07-01 v0.6 nine-PR merge recipe — trial-verified (non-destructive)

- Goal: verify the integration of the 9 open v0.6 PRs (#215–#223) and hand back an exact merge recipe.
  Throwaway branch; NOT merged to `main`; NOT a covered flip.
- Method: `trial/v06-verify-4b07b3` off `origin/main` `94d20319`; merged 4 tips (ordinal #215→#218→#220,
  gamma #216→#217→#219, h² #221→#223, #222); all conflicts keep-both/combine, reconstructed cleanly.
- `Pkg.test()`: **GREEN**, exit 0 (`Testing HSquared tests passed`). Count guard `@test length(validation)
  == 50` holds.
- `validation_status()`: **50** rows; covered 8 / covered_external 3 / partial 38 / planned 1 (unchanged from
  main). `tools/status_cache.json` `public_covered_count` = **1**. `V6-ORDINAL`/`V6-GAMMA`/`V6-NS-H2` all
  remain `partial`.
- `nongaussian_heritability` verified for gaussian/poisson/bernoulli/binomial/probit/ordinal(per-category
  vector)/gamma; `fit_laplace_reml(family=:ordered_probit)` and `(family=:gamma)` converge end-to-end.
- Bug caught + fixed in the trial: `test/runtests.jl` — the two h² testsets shared one trailing `end` (git
  deduplicated); adding one `end` restored balance (initial `Meta.parseall` missed it; `Pkg.test()` caught it).
- Real `rose-systems-auditor` on the integrated tree → **PROMOTE** (faithful, honest; no dropped content, no
  altered semantics, all pins exact). Flagged two PRE-EXISTING source-branch imprecisions (recorded in the
  recipe, not fixed).
- Trial branch DELETED (never pushed). Recipe committed to `docs/2026-07-01-v06-merge-recipe`
  (`docs/dev-log/recovery-checkpoints/2026-07-01-full-v06-merge-recipe.md`), PR #225 opened.
- Scope: verification + recipe only. No engine/test/status change on `main`; nothing promoted to covered.
