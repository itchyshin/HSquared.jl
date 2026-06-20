# Post-fit marker-scan entry points (#45).
#
# Convenience methods that run a marker scan directly on a fitted animal model,
# pulling the design (`y`, `X`, `Z`), the relationship precision (`Ainv`), and the
# fitted variance components off the fit object — so a caller does not re-supply
# them. These are thin delegations to the core scans in `genomic.jl`; defined here
# (after both `genomic.jl` and `likelihood.jl` are loaded) because they dispatch on
# `AnimalModelFit`, which `genomic.jl` does not yet see at its own include point.
#
# The mixed-model (relatedness-corrected GLS) entry point is the headline: it uses
# the fitted `(σ²a, σ²e)` and the pedigree/relationship `Ainv` carried on the fit's
# spec, so the scan is conditioned on the same covariance the model was fit under.
# EXPERIMENTAL, dense/validation-scale. The returned p-values are NOT genome-wide
# calibrated (that gate is #48); no R `marker_scan()` activation; no bridge change.

"""
    mixed_model_marker_scan(fit::AnimalModelFit, markers; allele_frequencies = nothing,
                            marker_ids = nothing)

Run the dense supplied-variance mixed-model (relatedness-corrected GLS) marker scan
of [`mixed_model_marker_scan`](@ref) on a fitted animal model, using the fit's
`y`/`X`/`Z`, its relationship precision `Ainv`, and its fitted variance components
`(σ²a, σ²e)`. Equivalent to calling the explicit-argument method with those values
pulled off `fit.spec` and `fit.variance_components`.

EXPERIMENTAL, dense/validation-scale. The Wald p-values are NOT genome-wide
calibrated (see #48); this does not activate the R `marker_scan()` formula path or
change any bridge payload.
"""
function mixed_model_marker_scan(fit::AnimalModelFit, markers::AbstractMatrix;
                                 allele_frequencies = nothing, marker_ids = nothing)
    return mixed_model_marker_scan(
        fit.spec.y, fit.spec.X, fit.spec.Z, fit.spec.Ainv, markers,
        fit.variance_components.sigma_a2, fit.variance_components.sigma_e2;
        allele_frequencies = allele_frequencies, marker_ids = marker_ids,
    )
end

"""
    single_marker_scan(fit::AnimalModelFit, markers; allele_frequencies = nothing,
                       marker_ids = nothing)

Run the fixed-effect single-marker scan of [`single_marker_scan`](@ref) on a fitted
animal model, using the fit's `y`/`X` and its fitted residual variance `σ²e`. This
is the relatedness-UNcorrected screen (no `Z`/`Ainv`); use
[`mixed_model_marker_scan(::AnimalModelFit, ::AbstractMatrix)`](@ref) for the
relatedness-corrected scan.

EXPERIMENTAL, dense/validation-scale; p-values NOT genome-wide calibrated (#48).
"""
function single_marker_scan(fit::AnimalModelFit, markers::AbstractMatrix;
                            allele_frequencies = nothing, marker_ids = nothing)
    return single_marker_scan(
        fit.spec.y, fit.spec.X, markers;
        allele_frequencies = allele_frequencies,
        sigma_e2 = fit.variance_components.sigma_e2, marker_ids = marker_ids,
    )
end
