# 2026-10-25 issue 408: variance_component_uncertainty (one information matrix)

Goal: give the univariate AI-REML route a single call that returns the variance-component
covariance, its standard errors, the h2 standard error and the logit-delta h2 interval from ONE
average-information matrix, instead of three calls that each rebuild and factorise it.

Commands: `julia --project=. test/test_issue_408_variance_component_uncertainty.jl` (red on main:
the helper is undefined; green on branch: 10 passed). Neighbours green: `test_issue_408_plot_data_single_information.jl`,
`test_api_docstrings.jl`, `test_issue_417_api_reference_docs.jl`, `test_issue_418_changelog_claims.jl`,
`test_issue_437_nonconverged_uncertainty.jl`, `test_status_row_types.jl`.

Claim boundary: Julia-side function only. The R bridge in itchyshin/hsquared still calls the
three standalone functions and `variance_components_plot_data`; it needs a follow-up to call the
bundle (with a fallback when absent). Not done and still open in #408: PrecompileTools or a sysimage
for the first-call cost (owner decision on a new runtime dependency), lazy PEV and reliability
(hsquared#266), near-boundary NaN SEs, and the FD-versus-AI validation run. No timing was
re-measured here; the saving is two of three factorisations, about 0.09 s at N = 5000 per the
issue's own measurement. No capability-status change.
