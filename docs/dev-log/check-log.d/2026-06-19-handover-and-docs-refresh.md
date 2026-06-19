# 2026-06-19 Session handover (v2) + Documenter API refresh

- Goal: produce a complete inheritance handover (plan + goal + state + in-flight +
  decisions), refresh the live widget, and bring the Documenter API page in line
  with the current exported surface.
- Lenses: Ada, Shannon, Grace, Rose.

## Done

- `docs/src/api.md`: added the 22 exported bindings missing from the manual — the
  Phase-3 relationship family (`additive_/dominance_/epistatic_/cytoplasmic_/
  clonal_relationship`, `maternal_lineage`, `mendelian_sampling_variances`,
  `single_step_inverse`), the REML fitting variants (`fit_gblup_reml`,
  `fit_snp_blup_reml`, `fit_single_step[_reml]`, `repeatability_mme`,
  `fit_repeatability_reml`, `two_effect_mme`, `fit_two_effect_reml`,
  `fit_laplace_reml`, `laplace_reml_interval`), the new `multivariate_covariance_standard_errors`
  + `covariance_structure_lrt`, `repeatability_interval`, and `NonGaussianFit`.
- Adding `fit_laplace_reml` first surfaced an unresolved `[`NonGaussianFit`](@ref)`
  (its docstring rendered but the struct wasn't in any `@docs` block → dead link →
  VitePress build failure); fixed by adding `HSquared.NonGaussianFit` to the page.
- Widget `status.json` refreshed to the handover state (`live_agents = 0`); noted
  the killed workflow/JWAS agent need relaunch. `index.html`/`version.txt` untouched.
- Handover note: `docs/dev-log/after-task/2026-06-19-session-handover-v2.md`.

## Evidence

- `~/.juliaup/bin/julia --project=docs docs/make.jl` → exit 0 (no unresolved
  `@ref`, VitePress build clean) AFTER adding `NonGaussianFit`.
- Docs/widget/handover only — no `src/` or `test/` change; suite unaffected (1822).

## Claim boundary

No capability moved to covered. Documentation now reflects the full exported
surface on the dev site.
