# After-task — H^Gamma bridge payload hardening

Date: 2026-06-21. Lane: Julia engine (`HSquared.jl`). Branch:
`codex/hgamma-bridge-payload-hardening`. Type: bridge-readiness evidence slice.

## Live Phase Snapshot

As of this report, Julia `main` is `d3cdc89` after the JWAS fitted-target
agreement probe (#129), with post-merge CI green. The current branch hardens the
engine-side supplied-Gamma single-step H^Gamma bridge surface only. R `hsquared`
owns the public formula/model-spec lane; this Julia thread did not edit the R
repository. No capability is promoted to covered.

## Goal

Start the second Big-3 item after the comparator probe: reduce R-bridge risk
for metafounder single-step by proving the Julia H^Gamma REML fit already
returns through the standard bridge-facing `AnimalModelFit` surface.

## Active Lenses

Hopper + Boole + Emmy checked bridge/result-shape semantics. Gauss + Noether
checked the H^Gamma precision/fitter delegation. Fisher + Curie + Mrode checked
the validation fixture and remaining evidence gaps. Rose kept the public claim
boundary clean. Grace covered local checks. Ada + Shannon kept the R/Julia lane
split. No subagents were spawned.

## Files Changed

- `test/runtests.jl` — adds a converged nonzero-Gamma H^Gamma REML fixture that
  asserts standard `result_payload()`, `fit_diagnostics()`, PEV/reliability IDs,
  reliability range, and selinv-vs-dense PEV/reliability parity.
- `src/validation_status.jl`, `docs/src/validation-status.md`,
  `docs/design/validation-debt-register.md`, and
  `docs/design/capability-status.md` — record the payload smoke without
  promoting status.
- `docs/design/12-bridge-compatibility.md` — changes the metafounder
  single-step row from planned fixture to nonzero-Gamma REML payload smoke.
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-hgamma-bridge-payload.md`

## Commands / Results

- `gh run watch 27909120868 --repo itchyshin/HSquared.jl --exit-status` —
  passed for the post-merge `main` CI from PR #129: Julia 1.10 and Julia 1
  jobs both succeeded.
- `julia --project=. -e 'using Pkg; Pkg.test()'` — passed. The updated
  H^Gamma bridge primitive testset passed 40/40.
- `julia --project=docs docs/make.jl` — passed, with existing local-build
  warnings for omitted internal docstrings, skipped deployment detection,
  default Vitepress assets, and npm audit output.
- `git diff --check` — passed.

## Public Claim Audit

Clean with limitations. The useful claim is limited to: "a nonzero supplied-Gamma
H^Gamma REML fit can populate the standard Julia `AnimalModelFit` bridge payload
and diagnostics fields, including PEV/reliability IDs and selinv-vs-dense
parity." This is not an R bridge execution claim, not a public formula claim,
not Gamma estimation, not an external comparator, not sparse/APY scaling, and
not covered validation.

## Tests Of The Tests

The new fixture uses a deterministic five-animal pedigree with one supplied
metafounder group, nonzero `Gamma`, and an interior REML optimum. It checks that
no H^Gamma-specific extractor branch is needed by routing through
`result_payload(reml_hgamma)`, `fit_diagnostics(reml_hgamma)`,
`prediction_error_variance(...; method = :selinv)`, and
`reliability(...; method = :selinv)`.

## Coordination Notes

R lane was not edited. The R twin should treat this as Julia-side contract
evidence for the future metafounder/single-step bridge, not as permission to
claim live R support until the R formula/model-spec payload is ratified and
tested.

## Known Limitations / Next Actions

- R-side model-spec/payload work remains separate and unclaimed.
- External H/H^Gamma comparator evidence remains open.
- Mrode Ch.11 style H/H-inverse fixture remains open.
- Gamma estimation remains absent.
- Sparse/APY scaling remains open.
