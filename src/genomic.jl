"""
    centered_markers(markers; allele_frequencies = nothing)

Center a biallelic marker matrix for SNP-BLUP / RR-BLUP, using the same
allele-frequency centering and VanRaden scaling as
[`genomic_relationship_matrix`](@ref).

Returns a `NamedTuple` `(W, p, k)`: `W = markers − 2p` is the centered marker
matrix (each column sums to zero), `p` are the per-marker allele frequencies
(estimated from the columns unless supplied), and `k = 2 Σ_j p_j(1 − p_j)` is the
VanRaden scale, so that `genomic_relationship_matrix(markers) == W * Wᵀ / k`.
Computing `W`, `p`, and `k` together guarantees they share one `p`, which the
GBLUP↔SNP-BLUP equivalence requires.
"""
function centered_markers(
    markers::AbstractMatrix;
    allele_frequencies::Union{Nothing,AbstractVector} = nothing,
)
    M = Float64.(markers)
    n, m = size(M)
    (n >= 1 && m >= 1) || throw(ArgumentError("markers must be non-empty"))
    all(g -> 0 <= g <= 2, M) ||
        throw(ArgumentError("marker genotypes must be counts or dosages in [0, 2]"))

    p = if allele_frequencies === nothing
        vec(sum(M, dims = 1)) ./ (2 * n)
    else
        length(allele_frequencies) == m ||
            throw(ArgumentError("allele_frequencies must have one entry per marker"))
        Float64.(allele_frequencies)
    end
    all(f -> 0 <= f <= 1, p) ||
        throw(ArgumentError("allele frequencies must lie in [0, 1]"))

    k = 2 * sum(p .* (1 .- p))
    k > 0 ||
        throw(ArgumentError("genomic scaling is zero; all markers are monomorphic"))

    W = M .- 2 .* transpose(p)
    return (W = W, p = p, k = k)
end

"""
    genomic_relationship_matrix(markers; allele_frequencies = nothing)

VanRaden (2008) method-1 genomic relationship matrix `G` from a biallelic marker
genotype matrix `markers` (rows = individuals, columns = markers; entries are the
count of one allele, `0`/`1`/`2`, or an imputed dosage in `[0, 2]`).

Allele frequencies are estimated from the columns (`p_j = mean(markers[:, j]) / 2`)
unless supplied via `allele_frequencies`. Returns the dense symmetric

    G = Z * Zᵀ / (2 * Σ_j p_j (1 − p_j)),   Z = markers − 2p.

This is the Phase 2 genomic-relationship construction utility — it builds `G`
only. Its regularized inverse is [`genomic_relationship_inverse`](@ref), and the
experimental supplied-variance GBLUP / SNP-BLUP fitting that consume `G` / `Ginv`
are [`fit_gblup`](@ref) / [`fit_snp_blup`](@ref). `G` is typically rank-deficient
when there are fewer markers than individuals and needs regularization before
inversion.
"""
function genomic_relationship_matrix(
    markers::AbstractMatrix;
    allele_frequencies::Union{Nothing,AbstractVector} = nothing,
)
    cm = centered_markers(markers; allele_frequencies = allele_frequencies)
    return (cm.W * transpose(cm.W)) ./ cm.k
end

"""
    genomic_relationship_inverse(G; ridge = 0.01)

Regularized inverse of a genomic relationship matrix `G` (e.g. from
[`genomic_relationship_matrix`](@ref)) — the genomic relationship inverse `Ginv`
consumed by the experimental supplied-variance [`fit_gblup`](@ref). A genomic `G`
built from markers is usually rank-deficient (markers < individuals), so a ridge
is added to the diagonal before inversion: `inv(G + ridge·I)`.

This is a simple ridge regularization. Blending `G` with a pedigree `A`
(single-step / `H`-matrix) exists as an internal validation utility and is not
yet part of the public surface.
"""
function genomic_relationship_inverse(G::AbstractMatrix; ridge::Real = 0.01)
    n = size(G, 1)
    size(G, 2) == n || throw(ArgumentError("G must be square"))
    ridge >= 0 || throw(ArgumentError("ridge must be non-negative"))
    regularized = Symmetric(Matrix{Float64}(G) + ridge * I)
    isposdef(regularized) ||
        throw(ArgumentError("regularized G is not positive definite; increase ridge"))
    return inv(regularized)
end

"""
    loco_relationship_precisions(markers, marker_groups; allele_frequencies = nothing,
                                 ridge = 0.01)

Construct dense leave-one-group-out genomic relationship precisions from marker
dosages.

`marker_groups` must provide one group label per marker column, for example a
chromosome label. For each group, the helper drops that group's markers, builds a
VanRaden genomic relationship matrix from the remaining markers using
[`genomic_relationship_matrix`](@ref), and returns its regularized dense inverse
from [`genomic_relationship_inverse`](@ref). The return value is a
`Dict{String, Matrix{Float64}}` keyed by group label, ready to pass as the
`relationship_precisions` argument to [`loco_mixed_model_marker_scan`](@ref).

This is a validation-scale construction helper. It does not choose public LOCO
defaults, estimate variance components, calibrate marker-scan p-values, parse
marker files, or activate R-facing `marker_scan()` syntax.
"""
function loco_relationship_precisions(
    markers::AbstractMatrix,
    marker_groups;
    allele_frequencies::Union{Nothing,AbstractVector} = nothing,
    ridge::Real = 0.01,
)
    M = Float64.(markers)
    n, m = size(M)
    (n >= 1 && m >= 1) || throw(ArgumentError("markers must be non-empty"))

    groups = string.(collect(marker_groups))
    length(groups) == m ||
        throw(ArgumentError("marker_groups must have one entry per marker"))
    all(!isempty, groups) ||
        throw(ArgumentError("marker_groups cannot contain empty labels"))
    group_order = _unique_strings(groups)
    length(group_order) >= 2 ||
        throw(ArgumentError("LOCO relationship construction requires at least two marker groups"))

    ridge_value = Float64(ridge)
    isfinite(ridge_value) && ridge_value >= 0 ||
        throw(ArgumentError("ridge must be non-negative and finite"))

    p = if allele_frequencies === nothing
        nothing
    else
        length(allele_frequencies) == m ||
            throw(ArgumentError("allele_frequencies must have one entry per marker"))
        p_values = Float64.(allele_frequencies)
        all(f -> 0 <= f <= 1, p_values) ||
            throw(ArgumentError("allele frequencies must lie in [0, 1]"))
        p_values
    end

    precisions = Dict{String,Matrix{Float64}}()
    for group in group_order
        keep = groups .!= group
        any(keep) ||
            throw(ArgumentError("LOCO group $(group) leaves no markers for relationship construction"))
        group_p = p === nothing ? nothing : p[keep]
        G = genomic_relationship_matrix(M[:, keep]; allele_frequencies = group_p)
        precisions[group] = genomic_relationship_inverse(G; ridge = ridge_value)
    end
    return precisions
end

"""
    fit_gblup(y, X, Z, Ginv, sigma_a2, sigma_e2; ids = nothing, method = :REML)

Genomic BLUP (GBLUP) at supplied variance components: solve the Gaussian animal
model with a genomic relationship inverse `Ginv` in place of the pedigree `Ainv`,
reusing the existing Henderson mixed-model-equation solve.

`Ginv` is the (regularized) inverse of a genomic relationship matrix, e.g. from
[`genomic_relationship_inverse`](@ref). A VanRaden `G` is rank-deficient
(column-centering puts the all-ones vector in its null space, so `rank(G) ≤
n − 1`), so it must be regularized before inversion — that is
`genomic_relationship_inverse`'s job, not this function's. `sigma_a2` and
`sigma_e2` are the supplied genomic and residual variances; GBLUP here does not
estimate them.

This is a thin convenience over [`animal_model_spec`](@ref) +
[`henderson_mme`](@ref): the genomic precision enters the same `Ainv` slot the
pedigree animal model uses, so it returns the same [`HendersonMMEResult`](@ref)
and works with every existing extractor (`fixed_effects`, `breeding_values`,
`heritability`, …). It is experimental and engine-internal; the user-facing R
`genomic()` model-spec mapping is coordinated separately and not part of this
function. The dense `Ginv` path is validation-scale only — it does not gain the
sparse selected-inversion advantage.
"""
function fit_gblup(
    y::AbstractVector,
    X::AbstractMatrix,
    Z::AbstractMatrix,
    Ginv::AbstractMatrix,
    sigma_a2::Real,
    sigma_e2::Real;
    ids = nothing,
    method = :REML,
)
    spec = animal_model_spec(y, X, Z, Ginv; ids = ids, method = method)
    return henderson_mme(spec, sigma_a2, sigma_e2)
end

"""
    fit_snp_blup(y, X, markers, sigma_g2, sigma_e2; allele_frequencies = nothing,
                 ids = nothing)

SNP-BLUP / RR-BLUP at supplied variance components: estimate marker effects with
the existing Henderson MME, treating the centered markers as the random-effect
design with an identity prior.

The centered markers `W` (from [`centered_markers`](@ref)) are the random-effect
design `Z`, the relationship inverse is the identity `I_m` (markers a priori
independent), and the per-marker variance is `sigma_g2 / k` with
`k = 2 Σ_j p_j(1 − p_j)`. Returns a `NamedTuple` `(marker_effects, gebv, beta, k,
p)` where `marker_effects = â`, `gebv = W·â` are the implied genomic breeding
values, and `beta` are the fixed effects.

`gebv` equals the GBLUP genomic breeding values for the same data and variances
(the GBLUP↔SNP-BLUP equivalence). The random block is deliberately labelled
`marker_effects` (not `breeding_values`/EBV), because on this spec the random
effects are marker effects, not animal breeding values. Experimental,
supplied-variance only (no variance-component estimation); unweighted VanRaden
method-1 / single identity prior only.
"""
function fit_snp_blup(
    y::AbstractVector,
    X::AbstractMatrix,
    markers::AbstractMatrix,
    sigma_g2::Real,
    sigma_e2::Real;
    allele_frequencies::Union{Nothing,AbstractVector} = nothing,
    ids = nothing,
)
    cm = centered_markers(markers; allele_frequencies = allele_frequencies)
    Im = Matrix{Float64}(I, size(cm.W, 2), size(cm.W, 2))
    spec = animal_model_spec(y, X, cm.W, Im; ids = ids, method = :REML)
    res = henderson_mme(spec, sigma_g2 / cm.k, sigma_e2)
    a = breeding_values(res).values
    return (marker_effects = a, gebv = cm.W * a, beta = fixed_effects(res), k = cm.k, p = cm.p)
end

"""
    single_marker_scan(y, X, markers; allele_frequencies = nothing,
                       sigma_e2 = 1.0, marker_ids = nothing)

Fixed-effect single-marker scan for biallelic marker dosages at a supplied
residual variance.

Each marker column is centered with [`centered_markers`](@ref), residualized
against the fixed-effect design `X`, and tested one marker at a time in the
Gaussian linear model `y = Xβ + marker * α + e`. The returned `NamedTuple`
contains `marker_ids`, `effects`, `standard_errors`, `z_scores`, `chisq`,
`p_values`, `bonferroni_p_values`, `bh_q_values`, `lod_scores`,
`denominators`, `p`, and `k`. `p_values` are approximate two-sided
Gaussian/Wald p-values implied by the supplied residual variance.
`bonferroni_p_values` and `bh_q_values` are deterministic Bonferroni and
Benjamini-Hochberg adjustments over the returned marker set. `lod_scores` are
known-variance fixed-effect LOD-equivalent scores, computed as
`chisq / (2log(10))`.

This is a deterministic Phase 5 validation-scale utility. It is not a mixed
model GWAS/QTL scan, does not account for relatedness or population structure,
does not compute interval-mapping or mixed-model LOD scores or calibrated /
correlated-marker multiple-testing workflows, and does not activate the
R-facing `marker_scan()` formula term.
"""
function single_marker_scan(
    y::AbstractVector,
    X::AbstractMatrix,
    markers::AbstractMatrix;
    allele_frequencies::Union{Nothing,AbstractVector} = nothing,
    sigma_e2::Real = 1.0,
    marker_ids = nothing,
)
    yv = Float64.(y)
    Xmat = Matrix{Float64}(X)
    length(yv) == size(Xmat, 1) ||
        throw(ArgumentError("X row count must match y length"))
    n, p = size(Xmat)
    n > p || throw(ArgumentError("single-marker scan requires more observations than fixed effects"))
    all(isfinite, yv) || throw(ArgumentError("y must contain only finite values"))
    all(isfinite, Xmat) || throw(ArgumentError("X must contain only finite values"))
    sigma_e2 > 0 || throw(ArgumentError("sigma_e2 must be positive"))

    cm = centered_markers(markers; allele_frequencies = allele_frequencies)
    size(cm.W, 1) == n ||
        throw(ArgumentError("markers row count must match y length"))
    marker_names = if marker_ids === nothing
        ["marker_$j" for j in axes(cm.W, 2)]
    else
        length(marker_ids) == size(cm.W, 2) ||
            throw(ArgumentError("marker_ids must have one entry per marker"))
        string.(marker_ids)
    end

    XtX = Symmetric(transpose(Xmat) * Xmat)
    isposdef(XtX) ||
        throw(ArgumentError("X must have full column rank"))
    Xty = transpose(Xmat) * yv
    y_resid = yv - Xmat * (XtX \ Xty)

    effects = zeros(Float64, size(cm.W, 2))
    standard_errors = similar(effects)
    z_scores = similar(effects)
    chisq = similar(effects)
    p_values = similar(effects)
    denominators = similar(effects)

    for j in axes(cm.W, 2)
        w = view(cm.W, :, j)
        w_resid = Vector(w) - Xmat * (XtX \ (transpose(Xmat) * w))
        denom = dot(w_resid, w_resid)
        denom > sqrt(eps(Float64)) ||
            throw(ArgumentError("marker $(marker_names[j]) is collinear with X after centering"))
        alpha = dot(w_resid, y_resid) / denom
        se = sqrt(Float64(sigma_e2) / denom)
        z = alpha / se
        denominators[j] = denom
        effects[j] = alpha
        standard_errors[j] = se
        z_scores[j] = z
        chisq[j] = z^2
        p_values[j] = _standard_normal_two_sided_pvalue(z)
    end

    bonferroni_p_values = _bonferroni_adjust(p_values)
    bh_q_values = _benjamini_hochberg_adjust(p_values)
    lod_scores = chisq ./ (2 * log(10))

    return (
        marker_ids = marker_names,
        effects = effects,
        standard_errors = standard_errors,
        z_scores = z_scores,
        chisq = chisq,
        p_values = p_values,
        bonferroni_p_values = bonferroni_p_values,
        bh_q_values = bh_q_values,
        lod_scores = lod_scores,
        denominators = denominators,
        p = cm.p,
        k = cm.k,
    )
end

"""
    mixed_model_marker_scan(y, X, Z, Ainv, markers, sigma_a2, sigma_e2;
                            allele_frequencies = nothing, marker_ids = nothing)

Supplied-variance mixed-model single-marker scan for biallelic marker dosages.

The helper forms the dense validation-scale marginal covariance
`V = sigma_a2 * Z * A * Z' + sigma_e2 * I`, where `A = inv(Ainv)`, then tests
each centered marker as a fixed effect by generalized least squares conditional
on the fixed-effect design `X`. The returned fields mirror
[`single_marker_scan`](@ref): marker effects, standard errors, Wald z-scores,
chi-square statistics, approximate two-sided Gaussian/Wald p-values,
Bonferroni-adjusted p-values, Benjamini-Hochberg q-values, LOD-equivalent
scores, GLS denominators, marker IDs, allele frequencies, and the VanRaden
scale, plus supplied variance components and `target = :mixed_model_marker_scan`.

This is an engine-internal, dense, supplied-variance Phase 5 utility. It is not
variance-component estimation, LOCO, interval mapping, calibrated genome-wide
testing, a plotting backend, a bridge payload, or activation of the R-facing
`marker_scan()` formula term.
"""
function mixed_model_marker_scan(
    y::AbstractVector,
    X::AbstractMatrix,
    Z::AbstractMatrix,
    Ainv::AbstractMatrix,
    markers::AbstractMatrix,
    sigma_a2::Real,
    sigma_e2::Real;
    allele_frequencies::Union{Nothing,AbstractVector} = nothing,
    marker_ids = nothing,
)
    common = _mixed_marker_scan_common(
        y,
        X,
        Z,
        markers,
        sigma_a2,
        sigma_e2;
        allele_frequencies = allele_frequencies,
        marker_ids = marker_ids,
    )
    cache = _mixed_marker_scan_cache(common.y, common.X, common.Z, Ainv, common.sigma_a2, common.sigma_e2)
    stats = _mixed_marker_scan_stats(common.cm.W, common.marker_ids, _ -> cache)
    return _mixed_marker_scan_result(common, stats, :mixed_model_marker_scan)
end

"""
    loco_mixed_model_marker_scan(y, X, Z, relationship_precisions, marker_groups,
                                 markers, sigma_a2, sigma_e2; ...)

Leave-one-group-out supplied-variance mixed-model marker scan.

`relationship_precisions` is a dictionary or named tuple mapping each marker
group label (for example a chromosome) to the relationship precision that should
be used when testing markers in that group. The helper selects the matching
precision for each marker, forms the dense validation-scale GLS covariance, and
runs the same marker-by-marker Wald scan as [`mixed_model_marker_scan`](@ref).
Callers can build the dictionary with [`loco_relationship_precisions`](@ref), or
provide their own externally constructed matrices.

This helper only selects among supplied matrices; it does not choose public LOCO
defaults, estimate variance components, calibrate p-values, run sparse
production scans, or activate the R-facing `marker_scan()` formula term.
"""
function loco_mixed_model_marker_scan(
    y::AbstractVector,
    X::AbstractMatrix,
    Z::AbstractMatrix,
    relationship_precisions,
    marker_groups,
    markers::AbstractMatrix,
    sigma_a2::Real,
    sigma_e2::Real;
    allele_frequencies::Union{Nothing,AbstractVector} = nothing,
    marker_ids = nothing,
)
    common = _mixed_marker_scan_common(
        y,
        X,
        Z,
        markers,
        sigma_a2,
        sigma_e2;
        allele_frequencies = allele_frequencies,
        marker_ids = marker_ids,
    )
    groups = string.(collect(marker_groups))
    length(groups) == size(common.cm.W, 2) ||
        throw(ArgumentError("marker_groups must have one entry per marker"))
    all(!isempty, groups) ||
        throw(ArgumentError("marker_groups cannot contain empty labels"))

    precision_lookup = _relationship_precision_lookup(relationship_precisions)
    group_order = _unique_strings(groups)
    missing_groups = _ordered_setdiff(group_order, collect(keys(precision_lookup)))
    isempty(missing_groups) ||
        throw(ArgumentError("relationship_precisions missing marker groups: $(join(missing_groups, ", "))"))

    cache_by_group = Dict(
        group => _mixed_marker_scan_cache(
            common.y,
            common.X,
            common.Z,
            precision_lookup[group],
            common.sigma_a2,
            common.sigma_e2,
        ) for group in group_order
    )
    stats = _mixed_marker_scan_stats(common.cm.W, common.marker_ids, j -> cache_by_group[groups[j]])
    result = _mixed_marker_scan_result(common, stats, :loco_mixed_model_marker_scan)
    return merge(result, (marker_groups = groups, relationship_groups = group_order))
end

function _mixed_marker_scan_common(
    y::AbstractVector,
    X::AbstractMatrix,
    Z::AbstractMatrix,
    markers::AbstractMatrix,
    sigma_a2::Real,
    sigma_e2::Real;
    allele_frequencies::Union{Nothing,AbstractVector} = nothing,
    marker_ids = nothing,
)
    yv = Float64.(y)
    Xmat = Matrix{Float64}(X)
    Zmat = Matrix{Float64}(Z)
    n = length(yv)
    size(Xmat, 1) == n ||
        throw(ArgumentError("X row count must match y length"))
    size(Zmat, 1) == n ||
        throw(ArgumentError("Z row count must match y length"))
    n > size(Xmat, 2) ||
        throw(ArgumentError("mixed-model marker scan requires more observations than fixed effects"))
    all(isfinite, yv) || throw(ArgumentError("y must contain only finite values"))
    all(isfinite, Xmat) || throw(ArgumentError("X must contain only finite values"))
    all(isfinite, Zmat) || throw(ArgumentError("Z must contain only finite values"))
    rank(Xmat) == size(Xmat, 2) ||
        throw(ArgumentError("X must have full column rank"))
    sa2 = Float64(sigma_a2)
    se2 = Float64(sigma_e2)
    isfinite(sa2) && sa2 > 0 ||
        throw(ArgumentError("sigma_a2 must be positive and finite"))
    isfinite(se2) && se2 > 0 ||
        throw(ArgumentError("sigma_e2 must be positive and finite"))

    cm = centered_markers(markers; allele_frequencies = allele_frequencies)
    size(cm.W, 1) == n ||
        throw(ArgumentError("markers row count must match y length"))
    marker_names = if marker_ids === nothing
        ["marker_$j" for j in axes(cm.W, 2)]
    else
        length(marker_ids) == size(cm.W, 2) ||
            throw(ArgumentError("marker_ids must have one entry per marker"))
        string.(marker_ids)
    end
    return (y = yv, X = Xmat, Z = Zmat, cm = cm, marker_ids = marker_names, sigma_a2 = sa2, sigma_e2 = se2)
end

function _mixed_marker_scan_cache(
    yv::Vector{Float64},
    Xmat::Matrix{Float64},
    Zmat::Matrix{Float64},
    Ainv::AbstractMatrix,
    sigma_a2::Float64,
    sigma_e2::Float64,
)
    n = length(yv)
    Ainvmat = Matrix{Float64}(Ainv)
    size(Ainvmat, 1) == size(Ainvmat, 2) ||
        throw(ArgumentError("Ainv must be square"))
    size(Zmat, 2) == size(Ainvmat, 1) ||
        throw(ArgumentError("Z columns must match Ainv dimensions"))
    all(isfinite, Ainvmat) || throw(ArgumentError("Ainv must contain only finite values"))

    Ainv_sym = Symmetric(Ainvmat)
    isposdef(Ainv_sym) ||
        throw(ArgumentError("Ainv must be positive definite"))
    A = inv(Ainv_sym)
    V = Symmetric(sigma_a2 * Zmat * A * transpose(Zmat) + sigma_e2 * Matrix{Float64}(I, n, n))
    isposdef(V) ||
        throw(ArgumentError("supplied covariance must be positive definite"))
    cholV = cholesky(V)

    Vinv_X = cholV \ Xmat
    Vinv_y = cholV \ yv
    XtVinvX = Symmetric(transpose(Xmat) * Vinv_X)
    isposdef(XtVinvX) ||
        throw(ArgumentError("X must have full column rank under the supplied covariance"))
    cholXtVinvX = cholesky(XtVinvX)
    Py = Vinv_y - Vinv_X * (cholXtVinvX \ (transpose(Xmat) * Vinv_y))
    return (cholV = cholV, Vinv_X = Vinv_X, cholXtVinvX = cholXtVinvX, Py = Py)
end

function _mixed_marker_scan_stats(W::AbstractMatrix, marker_names::Vector{String}, cache_for_marker)
    effects = zeros(Float64, size(W, 2))
    standard_errors = similar(effects)
    z_scores = similar(effects)
    chisq = similar(effects)
    p_values = similar(effects)
    denominators = similar(effects)

    for j in axes(W, 2)
        cache = cache_for_marker(j)
        w = Vector(@view(W[:, j]))
        Vinv_w = cache.cholV \ w
        Pw = Vinv_w - cache.Vinv_X * (cache.cholXtVinvX \ (transpose(cache.Vinv_X) * w))
        denom = dot(w, Pw)
        denom > sqrt(eps(Float64)) ||
            throw(ArgumentError("marker $(marker_names[j]) is collinear with X under the supplied covariance"))
        alpha = dot(w, cache.Py) / denom
        se = sqrt(inv(denom))
        z = alpha / se
        denominators[j] = denom
        effects[j] = alpha
        standard_errors[j] = se
        z_scores[j] = z
        chisq[j] = z^2
        p_values[j] = _standard_normal_two_sided_pvalue(z)
    end

    bonferroni_p_values = _bonferroni_adjust(p_values)
    bh_q_values = _benjamini_hochberg_adjust(p_values)
    lod_scores = chisq ./ (2 * log(10))
    return (
        effects = effects,
        standard_errors = standard_errors,
        z_scores = z_scores,
        chisq = chisq,
        p_values = p_values,
        bonferroni_p_values = bonferroni_p_values,
        bh_q_values = bh_q_values,
        lod_scores = lod_scores,
        denominators = denominators,
    )
end

function _mixed_marker_scan_result(common, stats, target::Symbol)
    return (
        marker_ids = common.marker_ids,
        effects = stats.effects,
        standard_errors = stats.standard_errors,
        z_scores = stats.z_scores,
        chisq = stats.chisq,
        p_values = stats.p_values,
        bonferroni_p_values = stats.bonferroni_p_values,
        bh_q_values = stats.bh_q_values,
        lod_scores = stats.lod_scores,
        denominators = stats.denominators,
        p = common.cm.p,
        k = common.cm.k,
        variance_components = (sigma_a2 = common.sigma_a2, sigma_e2 = common.sigma_e2),
        target = target,
    )
end

function _relationship_precision_lookup(relationship_precisions::AbstractDict)
    lookup = Dict{String,Any}()
    for (key, value) in relationship_precisions
        lookup[string(key)] = value
    end
    isempty(lookup) ||
        return lookup
    throw(ArgumentError("relationship_precisions cannot be empty"))
end

function _relationship_precision_lookup(relationship_precisions::NamedTuple)
    lookup = Dict{String,Any}()
    for key in keys(relationship_precisions)
        lookup[string(key)] = getproperty(relationship_precisions, key)
    end
    isempty(lookup) ||
        return lookup
    throw(ArgumentError("relationship_precisions cannot be empty"))
end

function _relationship_precision_lookup(relationship_precisions)
    throw(ArgumentError("relationship_precisions must be a dictionary or named tuple"))
end

"""
    marker_manhattan_data(scan; chromosomes = nothing, positions = nothing,
                          p_floor = floatmin(Float64), chromosome_gap = 1.0)
    marker_manhattan_data(scan, marker_spec::HSMarkerMapSpec; ...)
    marker_manhattan_data(scan, data::HSData; ...)

Prepare plot-ready Manhattan data from a direct [`single_marker_scan`](@ref)
result.

The helper returns marker IDs, raw p-values, `-log10(p)` values, chromosome
labels, marker positions, cumulative plotting positions, and a deterministic
plot order. If chromosome or position metadata is omitted, all markers are
placed on chromosome `"1"` with sequential positions. Zero p-values are floored
only for `-log10` display values, and the floor is returned in the output.
When a validated [`HSMarkerMapSpec`](@ref) or [`HSData`](@ref) with marker
metadata is supplied, marker IDs must match the scan exactly; chromosome and
position metadata are then aligned to the scan marker order, while chromosome
display order follows the marker-map order.

This is a data-preparation helper only. It does not draw a plot, does not parse
marker maps, does not run a mixed-model marker scan, and does not activate the
R-facing `marker_scan()` formula term.
"""
function marker_manhattan_data(
    scan;
    chromosomes = nothing,
    positions = nothing,
    p_floor::Real = floatmin(Float64),
    chromosome_gap::Real = 1.0,
)
    marker_ids, p_values = _scan_marker_ids_and_p_values(scan)

    m = length(p_values)
    chromosome_values = if chromosomes === nothing
        fill("1", m)
    elseif chromosomes isa AbstractString || chromosomes isa Symbol
        fill(string(chromosomes), m)
    else
        string.(collect(chromosomes))
    end
    position_values = if positions === nothing
        Float64.(collect(1:m))
    else
        Float64.(collect(positions))
    end

    return _marker_manhattan_data_from_vectors(
        marker_ids,
        p_values,
        chromosome_values,
        position_values,
        p_floor,
        chromosome_gap,
    )
end

function marker_manhattan_data(
    scan,
    marker_spec::HSMarkerMapSpec;
    p_floor::Real = floatmin(Float64),
    chromosome_gap::Real = 1.0,
)
    marker_ids, p_values = _scan_marker_ids_and_p_values(scan)
    map_order = _marker_map_order_for_scan(marker_ids, marker_spec)
    return _marker_manhattan_data_from_vectors(
        marker_ids,
        p_values,
        marker_spec.chromosome[map_order],
        marker_spec.position[map_order],
        p_floor,
        chromosome_gap;
        chromosome_order = _unique_strings(marker_spec.chromosome),
    )
end

function marker_manhattan_data(
    scan,
    data::HSData;
    p_floor::Real = floatmin(Float64),
    chromosome_gap::Real = 1.0,
)
    data.marker_spec !== nothing ||
        throw(ArgumentError("HSData must contain marker metadata"))
    return marker_manhattan_data(
        scan,
        data.marker_spec;
        p_floor = p_floor,
        chromosome_gap = chromosome_gap,
    )
end

function _scan_marker_ids_and_p_values(scan)
    marker_ids = _scan_marker_ids(scan)
    hasproperty(scan, :p_values) ||
        throw(ArgumentError("scan must have a p_values field"))

    p_values = _checked_p_values(getproperty(scan, :p_values))
    m = length(p_values)
    length(marker_ids) == m ||
        throw(ArgumentError("marker_ids and p_values must have the same length"))
    return marker_ids, p_values
end

function _scan_marker_ids(scan)
    hasproperty(scan, :marker_ids) ||
        throw(ArgumentError("scan must have a marker_ids field"))
    marker_ids = string.(collect(getproperty(scan, :marker_ids)))
    !isempty(marker_ids) ||
        throw(ArgumentError("marker_ids must be non-empty"))
    return marker_ids
end

function _marker_manhattan_data_from_vectors(
    marker_ids::Vector{String},
    p_values::Vector{Float64},
    chromosome_values::AbstractVector,
    position_values::AbstractVector,
    p_floor::Real,
    chromosome_gap::Real;
    chromosome_order = nothing,
)
    m = length(p_values)

    p_floor_value = Float64(p_floor)
    isfinite(p_floor_value) && 0 < p_floor_value <= 1 ||
        throw(ArgumentError("p_floor must be finite and in (0, 1]"))
    gap = Float64(chromosome_gap)
    isfinite(gap) && gap >= 0 ||
        throw(ArgumentError("chromosome_gap must be finite and non-negative"))

    chromosome_labels = string.(collect(chromosome_values))
    length(chromosome_labels) == m ||
        throw(ArgumentError("chromosomes must have one entry per marker"))

    positions_float = Float64.(collect(position_values))
    length(positions_float) == m ||
        throw(ArgumentError("positions must have one entry per marker"))
    all(x -> isfinite(x) && x >= 0, positions_float) ||
        throw(ArgumentError("positions must be finite and non-negative"))

    chromosome_order_values = chromosome_order === nothing ?
        _unique_strings(chromosome_labels) :
        string.(collect(chromosome_order))
    duplicates = _duplicate_string_ids(chromosome_order_values)
    isempty(duplicates) ||
        throw(ArgumentError("chromosome order cannot contain duplicate values: $(join(duplicates, ", "))"))
    missing_chromosomes = _ordered_setdiff(_unique_strings(chromosome_labels), chromosome_order_values)
    isempty(missing_chromosomes) ||
        throw(ArgumentError("chromosome order is missing chromosomes: $(join(missing_chromosomes, ", "))"))

    chromosome_rank = Dict{String,Int}()
    for (rank, chromosome) in pairs(chromosome_order_values)
        chromosome_rank[chromosome] = rank
    end

    marker_order = sortperm(collect(1:m);
        by = i -> (chromosome_rank[chromosome_labels[i]], positions_float[i], i))
    plot_positions = zeros(Float64, m)
    offset = 0.0
    for chromosome in chromosome_order_values
        chromosome_indices = [i for i in marker_order if chromosome_labels[i] == chromosome]
        isempty(chromosome_indices) && continue
        for i in chromosome_indices
            plot_positions[i] = offset + positions_float[i]
        end
        offset = maximum(plot_positions[chromosome_indices]) + gap
    end

    return (
        marker_ids = marker_ids,
        chromosomes = chromosome_labels,
        positions = positions_float,
        plot_positions = plot_positions,
        p_values = p_values,
        neglog10_p_values = .-log10.(max.(p_values, p_floor_value)),
        order = marker_order,
        p_floor = p_floor_value,
    )
end

"""
    marker_region_data(scan; chromosomes, positions, chromosome, start = nothing,
                       stop = nothing, flank = 0, total_variance = nothing,
                       p_floor = floatmin(Float64))
    marker_region_data(scan, marker_spec::HSMarkerMapSpec; ...)
    marker_region_data(scan, data::HSData; ...)

Prepare scan data for one chromosome or chromosome-window region.

The helper reuses [`marker_scan_table`](@ref) validation, then subsets the
row-aligned marker-scan table by chromosome and optional coordinate bounds.
When `start` and/or `stop` are supplied, a non-negative `flank` expands that
window before filtering. Returned rows are ordered by position within the
region, with original scan indices preserved.

This is a direct Julia data-preparation helper only. It does not draw a plot,
choose thresholds, calibrate p-values, run interval mapping, activate
`gwas_table()` / `qtl_table()` / `eqtl_table()`, activate R-facing
`marker_scan()` syntax, or change the bridge payload.
"""
function marker_region_data(
    scan;
    chromosomes = nothing,
    positions = nothing,
    chromosome,
    start = nothing,
    stop = nothing,
    flank::Real = 0,
    total_variance = nothing,
    p_floor::Real = floatmin(Float64),
)
    (chromosomes !== nothing && positions !== nothing) ||
        throw(ArgumentError("chromosomes and positions are required for marker_region_data"))
    return _marker_region_data(
        scan,
        chromosomes,
        positions;
        chromosome = chromosome,
        start = start,
        stop = stop,
        flank = flank,
        total_variance = total_variance,
        p_floor = p_floor,
    )
end

function marker_region_data(
    scan,
    marker_spec::HSMarkerMapSpec;
    chromosome,
    start = nothing,
    stop = nothing,
    flank::Real = 0,
    total_variance = nothing,
    p_floor::Real = floatmin(Float64),
)
    marker_ids = _scan_marker_ids(scan)
    map_order = _marker_map_order_for_scan(marker_ids, marker_spec)
    return _marker_region_data(
        scan,
        marker_spec.chromosome[map_order],
        marker_spec.position[map_order];
        chromosome = chromosome,
        start = start,
        stop = stop,
        flank = flank,
        total_variance = total_variance,
        p_floor = p_floor,
    )
end

function marker_region_data(
    scan,
    data::HSData;
    chromosome,
    start = nothing,
    stop = nothing,
    flank::Real = 0,
    total_variance = nothing,
    p_floor::Real = floatmin(Float64),
)
    data.marker_spec !== nothing ||
        throw(ArgumentError("HSData must contain marker metadata"))
    return marker_region_data(
        scan,
        data.marker_spec;
        chromosome = chromosome,
        start = start,
        stop = stop,
        flank = flank,
        total_variance = total_variance,
        p_floor = p_floor,
    )
end

function _marker_region_data(
    scan,
    chromosomes,
    positions;
    chromosome,
    start,
    stop,
    flank::Real,
    total_variance,
    p_floor::Real,
)
    table = _marker_scan_table(scan, chromosomes, positions; total_variance = total_variance)
    m = length(table.marker_ids)

    chromosome_value = string(chromosome)
    !isempty(chromosome_value) ||
        throw(ArgumentError("chromosome must be a non-empty value"))
    start_value = _checked_optional_region_bound(start, :start)
    stop_value = _checked_optional_region_bound(stop, :stop)
    if start_value !== nothing && stop_value !== nothing
        stop_value >= start_value ||
            throw(ArgumentError("stop must be greater than or equal to start"))
    end
    flank_value = _checked_region_flank(flank)
    p_floor_value = Float64(p_floor)
    isfinite(p_floor_value) && 0 < p_floor_value <= 1 ||
        throw(ArgumentError("p_floor must be finite and in (0, 1]"))

    window_start = start_value === nothing ? nothing : max(0.0, start_value - flank_value)
    window_stop = stop_value === nothing ? nothing : stop_value + flank_value
    lower = window_start === nothing ? -Inf : window_start
    upper = window_stop === nothing ? Inf : window_stop

    selected = [
        i for i in 1:m if table.chromosomes[i] == chromosome_value &&
            lower <= table.positions[i] <= upper
    ]
    !isempty(selected) ||
        throw(ArgumentError("marker region contains no markers"))

    order = selected[sortperm(selected; by = i -> (table.positions[i], table.scan_indices[i]))]
    region = (
        marker_ids = table.marker_ids[order],
        chromosomes = table.chromosomes[order],
        positions = table.positions[order],
        plot_positions = table.positions[order],
        scan_indices = table.scan_indices[order],
        effects = table.effects[order],
        abs_effects = table.abs_effects[order],
        standard_errors = table.standard_errors[order],
        z_scores = table.z_scores[order],
        chisq = table.chisq[order],
        p_values = table.p_values[order],
        bonferroni_p_values = table.bonferroni_p_values[order],
        bh_q_values = table.bh_q_values[order],
        lod_scores = table.lod_scores[order],
        denominators = table.denominators[order],
        allele_frequencies = table.allele_frequencies[order],
        allele_variances = table.allele_variances[order],
        marker_variances = table.marker_variances[order],
        proportion_variance_explained = table.proportion_variance_explained === nothing ?
            nothing :
            table.proportion_variance_explained[order],
        total_variance = table.total_variance,
        chromosome = chromosome_value,
        requested_start = start_value,
        requested_stop = stop_value,
        flank = flank_value,
        window_start = window_start,
        window_stop = window_stop,
        neglog10_p_values = .-log10.(max.(table.p_values[order], p_floor_value)),
        p_floor = p_floor_value,
        target = table.target,
    )

    if hasproperty(table, :vanraden_scale)
        region = merge(region, (vanraden_scale = table.vanraden_scale,))
    end
    if hasproperty(table, :variance_components)
        region = merge(region, (variance_components = table.variance_components,))
    end
    if hasproperty(table, :marker_groups)
        region = merge(region, (marker_groups = table.marker_groups[order],))
    end

    return region
end

function _checked_optional_region_bound(value, field::Symbol)
    value === nothing && return nothing
    bound = _checked_real_scalar(value, field)
    isfinite(bound) && bound >= 0 ||
        throw(ArgumentError("$(field) must be finite and non-negative"))
    return bound
end

function _checked_region_flank(flank::Real)
    flank_value = Float64(flank)
    isfinite(flank_value) && flank_value >= 0 ||
        throw(ArgumentError("flank must be finite and non-negative"))
    return flank_value
end

function _checked_marker_alpha(alpha)
    alpha_value = _checked_real_scalar(alpha, :alpha)
    isfinite(alpha_value) && 0 < alpha_value <= 1 ||
        throw(ArgumentError("alpha must be finite and in (0, 1]"))
    return alpha_value
end

function _marker_map_order_for_scan(marker_ids::Vector{String}, marker_spec::HSMarkerMapSpec)
    duplicate_scan_ids = _duplicate_string_ids(marker_ids)
    isempty(duplicate_scan_ids) ||
        throw(ArgumentError("scan marker_ids must be unique when matching a marker map: $(join(duplicate_scan_ids, ", "))"))

    missing_from_map = _ordered_setdiff(marker_ids, marker_spec.marker_ids)
    missing_from_scan = _ordered_setdiff(marker_spec.marker_ids, marker_ids)
    if !isempty(missing_from_map) || !isempty(missing_from_scan)
        details = String[]
        isempty(missing_from_map) || push!(details, "missing from marker map: $(join(missing_from_map, ", "))")
        isempty(missing_from_scan) || push!(details, "missing from scan: $(join(missing_from_scan, ", "))")
        throw(ArgumentError("scan marker_ids must match marker map IDs exactly; $(join(details, "; "))"))
    end

    marker_index = Dict(id => i for (i, id) in pairs(marker_spec.marker_ids))
    return [marker_index[id] for id in marker_ids]
end

"""
    marker_qq_data(scan; p_floor = floatmin(Float64))

Prepare plot-ready QQ data from a direct [`single_marker_scan`](@ref) result.

The helper sorts observed p-values from smallest to largest and returns the
paired expected uniform order-statistic p-values, raw and sorted p-values,
marker IDs, sorted marker IDs, `-log10` observed and expected values, the sort
order, and the display p-value floor. Zero p-values are floored only for
display values; raw p-values are preserved.

This is a data-preparation helper only. It does not draw a plot, estimate
genomic inflation, calibrate p-values, run a mixed-model marker scan, or
activate the R-facing `marker_scan()` formula term.
"""
function marker_qq_data(scan; p_floor::Real = floatmin(Float64))
    marker_ids, p_values = _scan_marker_ids_and_p_values(scan)
    p_floor_value = Float64(p_floor)
    isfinite(p_floor_value) && 0 < p_floor_value <= 1 ||
        throw(ArgumentError("p_floor must be finite and in (0, 1]"))

    order = sortperm(collect(eachindex(p_values)); by = i -> (p_values[i], i))
    sorted_p_values = p_values[order]
    m = length(sorted_p_values)
    expected_p_values = collect(1:m) ./ (m + 1)

    return (
        marker_ids = marker_ids,
        p_values = p_values,
        sorted_marker_ids = marker_ids[order],
        sorted_p_values = sorted_p_values,
        expected_p_values = expected_p_values,
        observed_neglog10_p_values = .-log10.(max.(sorted_p_values, p_floor_value)),
        expected_neglog10_p_values = .-log10.(expected_p_values),
        order = order,
        p_floor = p_floor_value,
    )
end

const _CHISQ1_MEDIAN = 0.454936423119572

"""
    marker_genomic_inflation(scan; expected_median = 0.454936423119572)

Compute a genomic-control-style inflation diagnostic from a direct marker-scan
result.

The helper expects a `chisq` field such as the one returned by
[`single_marker_scan`](@ref), [`mixed_model_marker_scan`](@ref), or
[`loco_mixed_model_marker_scan`](@ref). It returns a compact `NamedTuple` with
`lambda_gc = median(chisq) / expected_median`, the observed median chi-square,
the expected median, the number of markers, and the scan target when available.
The default expected median is the 0.5 quantile of a one-degree-of-freedom
chi-square distribution.

This is a diagnostic summary only. It does not calibrate p-values, correct the
scan statistics, choose genome-wide thresholds, or activate R-facing
`marker_scan()` syntax.
"""
function marker_genomic_inflation(scan; expected_median::Real = _CHISQ1_MEDIAN)
    hasproperty(scan, :chisq) ||
        throw(ArgumentError("scan must have a chisq field"))
    values = Float64.(collect(getproperty(scan, :chisq)))
    !isempty(values) ||
        throw(ArgumentError("chisq values must be non-empty"))
    all(x -> isfinite(x) && x >= 0, values) ||
        throw(ArgumentError("chisq values must be finite and non-negative"))

    expected = Float64(expected_median)
    isfinite(expected) && expected > 0 ||
        throw(ArgumentError("expected_median must be positive and finite"))

    median_chisq = _median_float(values)
    target = hasproperty(scan, :target) ? getproperty(scan, :target) : :direct_marker_scan
    return (
        lambda_gc = median_chisq / expected,
        median_chisq = median_chisq,
        expected_median = expected,
        n_markers = length(values),
        target = target,
    )
end

"""
    marker_significance_summary(scan; alpha = 0.05)

Summarize nominal marker hits from a direct marker-scan result.

The helper expects the scan fields returned by [`single_marker_scan`](@ref),
[`mixed_model_marker_scan`](@ref), or [`loco_mixed_model_marker_scan`](@ref):
marker IDs, raw p-values, Bonferroni-adjusted p-values,
Benjamini-Hochberg q-values, chi-square values, and LOD-equivalent scores. It
returns per-marker significance flags, counts, marker IDs and scan indices for
raw, Bonferroni, and BH summaries, plus the top marker by raw p-value.

The thresholds are nominal summaries over the markers already present in the
scan: raw `p <= alpha`, Bonferroni raw-p threshold `alpha / m`, adjusted
Bonferroni `p_adj <= alpha`, and BH `q <= alpha`. This helper does not
calibrate correlated-marker genome-wide thresholds, estimate effective marker
counts, correct p-values, choose public GWAS/QTL thresholds, draw plots, or
activate R-facing `marker_scan()` syntax.
"""
function marker_significance_summary(scan; alpha = 0.05)
    alpha_value = _checked_marker_alpha(alpha)
    marker_ids, p_values = _scan_marker_ids_and_p_values(scan)
    m = length(marker_ids)
    bonferroni_p_values = _checked_scan_p_value_field(scan, :bonferroni_p_values, m)
    bh_q_values = _checked_scan_p_value_field(scan, :bh_q_values, m)
    chisq = _checked_scan_float_field(scan, :chisq, m; nonnegative = true)
    lod_scores = _checked_scan_float_field(scan, :lod_scores, m; nonnegative = true)

    raw_flags = collect(p_values .<= alpha_value)
    bonferroni_flags = collect(bonferroni_p_values .<= alpha_value)
    bh_flags = collect(bh_q_values .<= alpha_value)
    scan_indices = collect(1:m)
    top_index = first(sortperm(scan_indices; by = i -> (p_values[i], i)))
    target = hasproperty(scan, :target) ? getproperty(scan, :target) : :direct_marker_scan

    return (
        marker_count = m,
        alpha = alpha_value,
        nominal_p_threshold = alpha_value,
        bonferroni_raw_p_threshold = alpha_value / m,
        adjusted_p_threshold = alpha_value,
        bh_q_threshold = alpha_value,
        raw_significant = raw_flags,
        bonferroni_significant = bonferroni_flags,
        bh_significant = bh_flags,
        n_raw_significant = count(identity, raw_flags),
        n_bonferroni_significant = count(identity, bonferroni_flags),
        n_bh_significant = count(identity, bh_flags),
        raw_marker_ids = marker_ids[raw_flags],
        bonferroni_marker_ids = marker_ids[bonferroni_flags],
        bh_marker_ids = marker_ids[bh_flags],
        raw_scan_indices = scan_indices[raw_flags],
        bonferroni_scan_indices = scan_indices[bonferroni_flags],
        bh_scan_indices = scan_indices[bh_flags],
        min_p_value = minimum(p_values),
        min_bonferroni_p_value = minimum(bonferroni_p_values),
        min_bh_q_value = minimum(bh_q_values),
        max_chisq = maximum(chisq),
        max_lod_score = maximum(lod_scores),
        top_marker_id = marker_ids[top_index],
        top_scan_index = top_index,
        top_p_value = p_values[top_index],
        top_bonferroni_p_value = bonferroni_p_values[top_index],
        top_bh_q_value = bh_q_values[top_index],
        top_chisq = chisq[top_index],
        top_lod_score = lod_scores[top_index],
        target = target,
    )
end

"""
    marker_scan_table(scan; total_variance = nothing)
    marker_scan_table(scan, marker_spec::HSMarkerMapSpec; ...)
    marker_scan_table(scan, data::HSData; ...)

Prepare a deterministic row-aligned marker-scan table from a direct scan result.

The helper expects the scan fields returned by [`single_marker_scan`](@ref),
[`mixed_model_marker_scan`](@ref), or [`loco_mixed_model_marker_scan`](@ref):
marker effects, standard errors, Wald statistics, chi-square values, p-values,
Bonferroni p-values, Benjamini-Hochberg q-values, LOD-equivalent scores,
denominators, and allele frequencies. It preserves the original scan order and
returns those vectors with `scan_indices`, the scan `target`, allele variances,
and marker-level variance contributions `2p(1-p) * effect^2`. If
`total_variance` is supplied, it also returns
`proportion_variance_explained = marker_variance / total_variance`.

When an already-validated [`HSMarkerMapSpec`](@ref) or [`HSData`](@ref) with
marker metadata is supplied, marker IDs must match exactly and chromosome /
position vectors are aligned to the scan order.

This is a direct Julia table-preparation helper only. It does not sort markers,
draw plots, calibrate p-values, choose thresholds, estimate marker-scan
variance components, activate R-facing `marker_scan()` syntax, or change the
bridge payload.
"""
function marker_scan_table(scan; total_variance = nothing)
    return _marker_scan_table(scan, nothing, nothing; total_variance = total_variance)
end

function marker_scan_table(
    scan,
    marker_spec::HSMarkerMapSpec;
    total_variance = nothing,
)
    marker_ids = _scan_marker_ids(scan)
    map_order = _marker_map_order_for_scan(marker_ids, marker_spec)
    return _marker_scan_table(
        scan,
        marker_spec.chromosome[map_order],
        marker_spec.position[map_order];
        total_variance = total_variance,
    )
end

function marker_scan_table(
    scan,
    data::HSData;
    total_variance = nothing,
)
    data.marker_spec !== nothing ||
        throw(ArgumentError("HSData must contain marker metadata"))
    return marker_scan_table(scan, data.marker_spec; total_variance = total_variance)
end

function _marker_scan_table(scan, chromosomes, positions; total_variance)
    marker_ids = _scan_marker_ids(scan)
    m = length(marker_ids)

    effects = _checked_scan_float_field(scan, :effects, m)
    standard_errors = _checked_scan_float_field(scan, :standard_errors, m; positive = true)
    z_scores = _checked_scan_float_field(scan, :z_scores, m)
    chisq = _checked_scan_float_field(scan, :chisq, m; nonnegative = true)
    p_values = _checked_scan_p_value_field(scan, :p_values, m)
    bonferroni_p_values = _checked_scan_p_value_field(scan, :bonferroni_p_values, m)
    bh_q_values = _checked_scan_p_value_field(scan, :bh_q_values, m)
    lod_scores = _checked_scan_float_field(scan, :lod_scores, m; nonnegative = true)
    denominators = _checked_scan_float_field(scan, :denominators, m; positive = true)
    allele_frequencies = _checked_scan_allele_frequencies(scan, m)
    allele_variances = 2 .* allele_frequencies .* (1 .- allele_frequencies)
    marker_variances = allele_variances .* effects .^ 2
    total = _checked_marker_total_variance(total_variance)
    proportions = total === nothing ? nothing : marker_variances ./ total
    target = hasproperty(scan, :target) ? getproperty(scan, :target) : :direct_marker_scan

    table = (
        marker_ids = marker_ids,
        scan_indices = collect(1:m),
        effects = effects,
        abs_effects = abs.(effects),
        standard_errors = standard_errors,
        z_scores = z_scores,
        chisq = chisq,
        p_values = p_values,
        bonferroni_p_values = bonferroni_p_values,
        bh_q_values = bh_q_values,
        lod_scores = lod_scores,
        denominators = denominators,
        allele_frequencies = allele_frequencies,
        allele_variances = allele_variances,
        marker_variances = marker_variances,
        proportion_variance_explained = proportions,
        total_variance = total,
        target = target,
    )

    if hasproperty(scan, :k)
        table = merge(table, (vanraden_scale = _checked_scan_scalar(scan, :k; nonnegative = true),))
    end
    if hasproperty(scan, :variance_components)
        table = merge(table, (variance_components = getproperty(scan, :variance_components),))
    end
    if hasproperty(scan, :marker_groups)
        table = merge(table, (marker_groups = _checked_scan_marker_groups(scan, m),))
    end

    chromosomes === nothing && positions === nothing && return table
    chromosome_values, position_values = _checked_marker_summary_metadata(chromosomes, positions, m)
    return merge(table, (chromosomes = chromosome_values, positions = position_values))
end

"""
    gwas_table(scan; trait = nothing, total_variance = nothing)
    gwas_table(scan, marker_spec::HSMarkerMapSpec; ...)
    gwas_table(scan, data::HSData; ...)

Prepare a GWAS-labelled table from an already-computed direct marker scan.

This is a semantic wrapper around [`marker_scan_table`](@ref): it preserves the
row-aligned marker scan fields and adds `analysis = :gwas`. If `trait` is
supplied, it is recorded as non-empty scalar table metadata. Existing scan
statistics, optional marker-map metadata, and optional variance proportions are
not recomputed.

This helper does not run a marker scan, estimate variance components, calibrate
p-values, choose genome-wide thresholds, activate R-facing `marker_scan()`
syntax, draw plots, or change the bridge payload.
"""
function gwas_table(scan; trait = nothing, total_variance = nothing)
    table = marker_scan_table(scan; total_variance = total_variance)
    return _marker_analysis_table(table, :gwas; trait = trait)
end

function gwas_table(
    scan,
    marker_spec::HSMarkerMapSpec;
    trait = nothing,
    total_variance = nothing,
)
    table = marker_scan_table(scan, marker_spec; total_variance = total_variance)
    return _marker_analysis_table(table, :gwas; trait = trait)
end

function gwas_table(
    scan,
    data::HSData;
    trait = nothing,
    total_variance = nothing,
)
    data.marker_spec !== nothing ||
        throw(ArgumentError("HSData must contain marker metadata"))
    return gwas_table(scan, data.marker_spec; trait = trait, total_variance = total_variance)
end

"""
    qtl_table(scan; trait = nothing, total_variance = nothing)
    qtl_table(scan, marker_spec::HSMarkerMapSpec; ...)
    qtl_table(scan, data::HSData; ...)

Prepare a QTL-labelled table from an already-computed direct marker scan.

This is a semantic wrapper around [`marker_scan_table`](@ref): it preserves the
row-aligned marker scan fields and adds `analysis = :qtl`. If `trait` is
supplied, it is recorded as non-empty scalar table metadata. The LOD-equivalent
scores are the scan's existing fixed-effect known-variance scores; no interval
mapping or mixed-model LOD workflow is performed here.

This helper does not run a marker scan, perform interval mapping, estimate
variance components, calibrate p-values, choose QTL thresholds, activate
R-facing `marker_scan()` / `qtl_scan()` syntax, draw plots, or change the bridge
payload.
"""
function qtl_table(scan; trait = nothing, total_variance = nothing)
    table = marker_scan_table(scan; total_variance = total_variance)
    return _marker_analysis_table(table, :qtl; trait = trait)
end

function qtl_table(
    scan,
    marker_spec::HSMarkerMapSpec;
    trait = nothing,
    total_variance = nothing,
)
    table = marker_scan_table(scan, marker_spec; total_variance = total_variance)
    return _marker_analysis_table(table, :qtl; trait = trait)
end

function qtl_table(
    scan,
    data::HSData;
    trait = nothing,
    total_variance = nothing,
)
    data.marker_spec !== nothing ||
        throw(ArgumentError("HSData must contain marker metadata"))
    return qtl_table(scan, data.marker_spec; trait = trait, total_variance = total_variance)
end

"""
    eqtl_table(scan; feature = nothing, total_variance = nothing)
    eqtl_table(scan, marker_spec::HSMarkerMapSpec; ...)
    eqtl_table(scan, data::HSData; ...)

Prepare an eQTL-labelled table from an already-computed direct marker scan.

This is a semantic wrapper around [`marker_scan_table`](@ref): it preserves the
row-aligned marker scan fields and adds `analysis = :eqtl`. If `feature` is
supplied, it is recorded as non-empty scalar table metadata for the expression
feature, gene, or transcript represented by the scan.

This helper does not run expression-wide scans, classify cis/trans windows,
join expression or annotation tables, estimate variance components, calibrate
p-values, activate R-facing `marker_scan()` / eQTL syntax, draw plots, or
change the bridge payload.
"""
function eqtl_table(scan; feature = nothing, total_variance = nothing)
    table = marker_scan_table(scan; total_variance = total_variance)
    return _marker_analysis_table(table, :eqtl; feature = feature)
end

function eqtl_table(
    scan,
    marker_spec::HSMarkerMapSpec;
    feature = nothing,
    total_variance = nothing,
)
    table = marker_scan_table(scan, marker_spec; total_variance = total_variance)
    return _marker_analysis_table(table, :eqtl; feature = feature)
end

function eqtl_table(
    scan,
    data::HSData;
    feature = nothing,
    total_variance = nothing,
)
    data.marker_spec !== nothing ||
        throw(ArgumentError("HSData must contain marker metadata"))
    return eqtl_table(scan, data.marker_spec; feature = feature, total_variance = total_variance)
end

function _marker_analysis_table(table, analysis::Symbol; trait = nothing, feature = nothing)
    analysis in (:gwas, :qtl, :eqtl) ||
        throw(ArgumentError("analysis must be :gwas, :qtl, or :eqtl"))

    result = merge(table, (analysis = analysis,))
    trait_label = _checked_optional_label(trait, :trait)
    feature_label = _checked_optional_label(feature, :feature)
    trait_label === nothing || (result = merge(result, (trait = trait_label,)))
    feature_label === nothing || (result = merge(result, (feature = feature_label,)))
    return result
end

function _checked_optional_label(value, field::Symbol)
    value === nothing && return nothing
    label = strip(string(value))
    !isempty(label) ||
        throw(ArgumentError("$(field) must be a non-empty value when supplied"))
    return label
end

"""
    marker_effects(scan; sort_by = :p_value, top_n = nothing,
                           decreasing = nothing)
    marker_effects(scan, marker_spec::HSMarkerMapSpec; ...)
    marker_effects(scan, data::HSData; ...)

Prepare a deterministic marker-effect summary from a direct marker-scan result.

The helper expects the scan fields returned by [`single_marker_scan`](@ref),
[`mixed_model_marker_scan`](@ref), or [`loco_mixed_model_marker_scan`](@ref):
marker effects, standard errors, Wald statistics, chi-square values, p-values,
Bonferroni p-values, Benjamini-Hochberg q-values, LOD-equivalent scores, and
denominators. It returns those fields sorted into a compact `NamedTuple` with
`scan_indices`, `sort_by`, `decreasing`, `top_n`, and the scan target when
available. Supported `sort_by` values are `:p_value`, `:bonferroni_p_value`,
`:bh_q_value`, `:chisq`, `:lod_score`, `:effect`, and `:abs_effect`; p-value
metrics sort ascending by default, while effect-size/statistic metrics sort
descending by default.

When an already-validated [`HSMarkerMapSpec`](@ref) or [`HSData`](@ref) with
marker metadata is supplied, marker IDs must match exactly and chromosome /
position vectors are aligned to the returned summary order.

This is a direct Julia summary helper only. It does not calibrate p-values,
choose thresholds, draw plots, activate R-facing `marker_scan()` syntax, or
change the bridge payload.
"""
function marker_effects(
    scan;
    sort_by::Symbol = :p_value,
    top_n = nothing,
    decreasing::Union{Nothing,Bool} = nothing,
)
    return _marker_effects(
        scan,
        nothing,
        nothing;
        sort_by = sort_by,
        top_n = top_n,
        decreasing = decreasing,
    )
end

function marker_effects(
    scan,
    marker_spec::HSMarkerMapSpec;
    sort_by::Symbol = :p_value,
    top_n = nothing,
    decreasing::Union{Nothing,Bool} = nothing,
)
    marker_ids, _ = _scan_marker_ids_and_p_values(scan)
    map_order = _marker_map_order_for_scan(marker_ids, marker_spec)
    return _marker_effects(
        scan,
        marker_spec.chromosome[map_order],
        marker_spec.position[map_order];
        sort_by = sort_by,
        top_n = top_n,
        decreasing = decreasing,
    )
end

function marker_effects(
    scan,
    data::HSData;
    sort_by::Symbol = :p_value,
    top_n = nothing,
    decreasing::Union{Nothing,Bool} = nothing,
)
    data.marker_spec !== nothing ||
        throw(ArgumentError("HSData must contain marker metadata"))
    return marker_effects(
        scan,
        data.marker_spec;
        sort_by = sort_by,
        top_n = top_n,
        decreasing = decreasing,
    )
end

"""
    marker_variance_explained(scan; total_variance = nothing,
                              sort_by = :marker_variance, top_n = nothing,
                              decreasing = nothing)
    marker_variance_explained(scan, marker_spec::HSMarkerMapSpec; ...)
    marker_variance_explained(scan, data::HSData; ...)

Prepare deterministic marker-level variance-contribution summaries from a
direct marker-scan result.

The helper expects scan `marker_ids`, marker `effects`, and allele frequencies
`p` such as those returned by [`single_marker_scan`](@ref),
[`mixed_model_marker_scan`](@ref), or [`loco_mixed_model_marker_scan`](@ref).
For each biallelic marker it computes `2p(1-p) * effect^2`. If
`total_variance` is supplied, it also returns
`proportion_variance_explained = marker_variance / total_variance`. Supported
`sort_by` values are `:marker_variance`, `:proportion_variance_explained`,
`:allele_variance`, `:effect`, `:abs_effect`, and `:p_value`; p-value sorting
requires a scan `p_values` field. Variance and effect-size metrics sort
descending by default, while p-values sort ascending.

When an already-validated [`HSMarkerMapSpec`](@ref) or [`HSData`](@ref) with
marker metadata is supplied, marker IDs must match exactly and chromosome /
position vectors are aligned to the returned summary order.

This is a direct Julia summary helper only. It does not estimate marker-scan
variance components, calibrate p-values, claim calibrated PVE/model R², choose
thresholds, draw plots, activate R-facing `marker_scan()` syntax, or change the
bridge payload.
"""
function marker_variance_explained(
    scan;
    total_variance = nothing,
    sort_by::Symbol = :marker_variance,
    top_n = nothing,
    decreasing::Union{Nothing,Bool} = nothing,
)
    return _marker_variance_explained(
        scan,
        nothing,
        nothing;
        total_variance = total_variance,
        sort_by = sort_by,
        top_n = top_n,
        decreasing = decreasing,
    )
end

function marker_variance_explained(
    scan,
    marker_spec::HSMarkerMapSpec;
    total_variance = nothing,
    sort_by::Symbol = :marker_variance,
    top_n = nothing,
    decreasing::Union{Nothing,Bool} = nothing,
)
    marker_ids = _scan_marker_ids(scan)
    map_order = _marker_map_order_for_scan(marker_ids, marker_spec)
    return _marker_variance_explained(
        scan,
        marker_spec.chromosome[map_order],
        marker_spec.position[map_order];
        total_variance = total_variance,
        sort_by = sort_by,
        top_n = top_n,
        decreasing = decreasing,
    )
end

function marker_variance_explained(
    scan,
    data::HSData;
    total_variance = nothing,
    sort_by::Symbol = :marker_variance,
    top_n = nothing,
    decreasing::Union{Nothing,Bool} = nothing,
)
    data.marker_spec !== nothing ||
        throw(ArgumentError("HSData must contain marker metadata"))
    return marker_variance_explained(
        scan,
        data.marker_spec;
        total_variance = total_variance,
        sort_by = sort_by,
        top_n = top_n,
        decreasing = decreasing,
    )
end

function _marker_variance_explained(
    scan,
    chromosomes,
    positions;
    total_variance,
    sort_by::Symbol,
    top_n,
    decreasing::Union{Nothing,Bool},
)
    marker_ids = _scan_marker_ids(scan)
    m = length(marker_ids)

    effects = _checked_scan_float_field(scan, :effects, m)
    allele_frequencies = _checked_scan_allele_frequencies(scan, m)
    allele_variances = 2 .* allele_frequencies .* (1 .- allele_frequencies)
    marker_variances = allele_variances .* effects .^ 2
    total = _checked_marker_total_variance(total_variance)
    proportions = total === nothing ? nothing : marker_variances ./ total
    p_values = hasproperty(scan, :p_values) ?
        _checked_scan_p_value_field(scan, :p_values, m) :
        nothing

    metric, canonical_sort_by, default_decreasing = _marker_variance_sort_metric(
        sort_by,
        effects,
        allele_variances,
        marker_variances,
        proportions,
        p_values,
    )
    decreasing_value = decreasing === nothing ? default_decreasing : decreasing
    order_all = if decreasing_value
        sortperm(collect(1:m); by = i -> (-metric[i], i))
    else
        sortperm(collect(1:m); by = i -> (metric[i], i))
    end

    top_count = _checked_top_n(top_n, m)
    order = order_all[1:top_count]
    target = hasproperty(scan, :target) ? getproperty(scan, :target) : :direct_marker_scan

    summary = (
        marker_ids = marker_ids[order],
        effects = effects[order],
        abs_effects = abs.(effects[order]),
        allele_frequencies = allele_frequencies[order],
        allele_variances = allele_variances[order],
        marker_variances = marker_variances[order],
        proportion_variance_explained = proportions === nothing ? nothing : proportions[order],
        total_variance = total,
        scan_indices = order,
        sort_by = canonical_sort_by,
        decreasing = decreasing_value,
        top_n = top_count,
        target = target,
    )
    p_values === nothing || (summary = merge(summary, (p_values = p_values[order],)))

    chromosomes === nothing && positions === nothing && return summary
    chromosome_values, position_values = _checked_marker_summary_metadata(chromosomes, positions, m)
    return merge(
        summary,
        (
            chromosomes = chromosome_values[order],
            positions = position_values[order],
        ),
    )
end

function _checked_scan_allele_frequencies(scan, n::Int)
    hasproperty(scan, :p) ||
        throw(ArgumentError("scan must have a p field"))
    return _checked_allele_frequencies(getproperty(scan, :p), n)
end

function _checked_allele_frequencies(values, n::Int)
    allele_frequencies = Float64.(collect(values))
    length(allele_frequencies) == n ||
        throw(ArgumentError("p must have one entry per marker"))
    all(p -> isfinite(p) && 0 <= p <= 1, allele_frequencies) ||
        throw(ArgumentError("p values must be finite allele frequencies in [0, 1]"))
    return allele_frequencies
end

function _checked_marker_total_variance(total_variance)
    total_variance === nothing && return nothing
    total = _checked_real_scalar(total_variance, :total_variance)
    isfinite(total) && total > 0 ||
        throw(ArgumentError("total_variance must be positive and finite"))
    return total
end

function _checked_scan_scalar(scan, field::Symbol; nonnegative::Bool = false)
    value = _checked_real_scalar(getproperty(scan, field), field)
    isfinite(value) ||
        throw(ArgumentError("$(field) must be finite"))
    if nonnegative
        value >= 0 ||
            throw(ArgumentError("$(field) must be non-negative"))
    end
    return value
end

function _checked_real_scalar(value, field::Symbol)
    try
        return Float64(value)
    catch
        throw(ArgumentError("$(field) must be numeric"))
    end
end

function _checked_scan_marker_groups(scan, n::Int)
    marker_groups = string.(collect(getproperty(scan, :marker_groups)))
    length(marker_groups) == n ||
        throw(ArgumentError("marker_groups must have one entry per marker"))
    all(!isempty, marker_groups) ||
        throw(ArgumentError("marker_groups cannot contain empty labels"))
    return marker_groups
end

function _marker_variance_sort_metric(
    sort_by::Symbol,
    effects::Vector{Float64},
    allele_variances::Vector{Float64},
    marker_variances::Vector{Float64},
    proportions,
    p_values,
)
    if sort_by in (:marker_variance, :marker_variances, :variance, :variance_explained)
        return marker_variances, :marker_variance, true
    elseif sort_by in (:proportion_variance_explained, :proportion, :pve)
        proportions !== nothing ||
            throw(ArgumentError("total_variance is required when sort_by is $(sort_by)"))
        return proportions, :proportion_variance_explained, true
    elseif sort_by in (:allele_variance, :allele_variances)
        return allele_variances, :allele_variance, true
    elseif sort_by == :effect
        return effects, :effect, true
    elseif sort_by in (:abs_effect, :abs_effects, :absolute_effect)
        return abs.(effects), :abs_effect, true
    elseif sort_by in (:p_value, :p_values, :p)
        p_values !== nothing ||
            throw(ArgumentError("scan must have a p_values field when sort_by is $(sort_by)"))
        return p_values, :p_value, false
    end
    throw(ArgumentError("unsupported sort_by value: $(sort_by)"))
end

function _marker_effects(
    scan,
    chromosomes,
    positions;
    sort_by::Symbol,
    top_n,
    decreasing::Union{Nothing,Bool},
)
    marker_ids, p_values = _scan_marker_ids_and_p_values(scan)
    m = length(marker_ids)

    effects = _checked_scan_float_field(scan, :effects, m)
    standard_errors = _checked_scan_float_field(scan, :standard_errors, m; positive = true)
    z_scores = _checked_scan_float_field(scan, :z_scores, m)
    chisq = _checked_scan_float_field(scan, :chisq, m; nonnegative = true)
    bonferroni_p_values = _checked_scan_p_value_field(scan, :bonferroni_p_values, m)
    bh_q_values = _checked_scan_p_value_field(scan, :bh_q_values, m)
    lod_scores = _checked_scan_float_field(scan, :lod_scores, m; nonnegative = true)
    denominators = _checked_scan_float_field(scan, :denominators, m; positive = true)

    metric, canonical_sort_by, default_decreasing = _marker_summary_sort_metric(
        sort_by,
        effects,
        chisq,
        p_values,
        bonferroni_p_values,
        bh_q_values,
        lod_scores,
    )
    decreasing_value = decreasing === nothing ? default_decreasing : decreasing
    order_all = if decreasing_value
        sortperm(collect(1:m); by = i -> (-metric[i], i))
    else
        sortperm(collect(1:m); by = i -> (metric[i], i))
    end

    top_count = _checked_top_n(top_n, m)
    order = order_all[1:top_count]
    target = hasproperty(scan, :target) ? getproperty(scan, :target) : :direct_marker_scan

    summary = (
        marker_ids = marker_ids[order],
        effects = effects[order],
        abs_effects = abs.(effects[order]),
        standard_errors = standard_errors[order],
        z_scores = z_scores[order],
        chisq = chisq[order],
        p_values = p_values[order],
        bonferroni_p_values = bonferroni_p_values[order],
        bh_q_values = bh_q_values[order],
        lod_scores = lod_scores[order],
        denominators = denominators[order],
        scan_indices = order,
        sort_by = canonical_sort_by,
        decreasing = decreasing_value,
        top_n = top_count,
        target = target,
    )

    chromosomes === nothing && positions === nothing && return summary
    chromosome_values, position_values = _checked_marker_summary_metadata(chromosomes, positions, m)
    return merge(
        summary,
        (
            chromosomes = chromosome_values[order],
            positions = position_values[order],
        ),
    )
end

function _checked_scan_float_field(scan, field::Symbol, n::Int; nonnegative::Bool = false, positive::Bool = false)
    hasproperty(scan, field) ||
        throw(ArgumentError("scan must have a $(field) field"))
    values = Float64.(collect(getproperty(scan, field)))
    length(values) == n ||
        throw(ArgumentError("$(field) must have one entry per marker"))
    all(isfinite, values) ||
        throw(ArgumentError("$(field) values must be finite"))
    if positive
        all(>(0), values) ||
            throw(ArgumentError("$(field) values must be positive"))
    elseif nonnegative
        all(>=(0), values) ||
            throw(ArgumentError("$(field) values must be non-negative"))
    end
    return values
end

function _checked_scan_p_value_field(scan, field::Symbol, n::Int)
    hasproperty(scan, field) ||
        throw(ArgumentError("scan must have a $(field) field"))
    values = _checked_p_values(getproperty(scan, field))
    length(values) == n ||
        throw(ArgumentError("$(field) must have one entry per marker"))
    return values
end

function _marker_summary_sort_metric(
    sort_by::Symbol,
    effects::Vector{Float64},
    chisq::Vector{Float64},
    p_values::Vector{Float64},
    bonferroni_p_values::Vector{Float64},
    bh_q_values::Vector{Float64},
    lod_scores::Vector{Float64},
)
    if sort_by in (:p_value, :p_values, :p)
        return p_values, :p_value, false
    elseif sort_by in (:bonferroni_p_value, :bonferroni_p_values, :bonferroni)
        return bonferroni_p_values, :bonferroni_p_value, false
    elseif sort_by in (:bh_q_value, :bh_q_values, :q_value, :q_values)
        return bh_q_values, :bh_q_value, false
    elseif sort_by in (:chisq, :chi_square, :chi_square_statistic)
        return chisq, :chisq, true
    elseif sort_by in (:lod_score, :lod_scores, :lod)
        return lod_scores, :lod_score, true
    elseif sort_by == :effect
        return effects, :effect, true
    elseif sort_by in (:abs_effect, :abs_effects, :absolute_effect)
        return abs.(effects), :abs_effect, true
    end
    throw(ArgumentError("unsupported sort_by value: $(sort_by)"))
end

function _checked_top_n(top_n, n::Int)
    top_n === nothing && return n
    top_n isa Integer ||
        throw(ArgumentError("top_n must be an integer or nothing"))
    1 <= top_n <= n ||
        throw(ArgumentError("top_n must be between 1 and the number of markers"))
    return Int(top_n)
end

function _checked_marker_summary_metadata(chromosomes, positions, n::Int)
    (chromosomes !== nothing && positions !== nothing) ||
        throw(ArgumentError("chromosomes and positions must be supplied together"))
    chromosome_values = string.(collect(chromosomes))
    length(chromosome_values) == n ||
        throw(ArgumentError("chromosomes must have one entry per marker"))
    all(!isempty, chromosome_values) ||
        throw(ArgumentError("chromosomes cannot contain empty labels"))
    position_values = Float64.(collect(positions))
    length(position_values) == n ||
        throw(ArgumentError("positions must have one entry per marker"))
    all(x -> isfinite(x) && x >= 0, position_values) ||
        throw(ArgumentError("positions must be finite and non-negative"))
    return chromosome_values, position_values
end

function _median_float(values::Vector{Float64})
    sorted_values = sort(values)
    n = length(sorted_values)
    middle = n ÷ 2
    return isodd(n) ? sorted_values[middle + 1] :
           (sorted_values[middle] + sorted_values[middle + 1]) / 2
end

# Abramowitz-Stegun 7.1.26 approximation to Phi(z). Maximum absolute error is
# about 7.5e-8, enough for deterministic fixed-effect scan diagnostics without
# adding a statistics dependency.
function _standard_normal_cdf_approx(z::Real)
    x = Float64(z)
    isfinite(x) || throw(ArgumentError("z must be finite"))
    x == 0 && return 0.5
    t = 1 / (1 + 0.2316419 * abs(x))
    poly = (((((1.330274429 * t - 1.821255978) * t + 1.781477937) * t -
              0.356563782) * t + 0.319381530) * t)
    upper = exp(-0.5 * x^2) * inv(sqrt(2 * pi)) * poly
    cdf = x >= 0 ? 1 - upper : upper
    return clamp(cdf, 0.0, 1.0)
end

function _standard_normal_two_sided_pvalue(z::Real)
    cdf = _standard_normal_cdf_approx(z)
    return clamp(2 * min(cdf, 1 - cdf), 0.0, 1.0)
end

function _checked_p_values(p_values)
    values = Float64.(p_values)
    !isempty(values) || throw(ArgumentError("p_values must be non-empty"))
    all(p -> isfinite(p) && 0 <= p <= 1, values) ||
        throw(ArgumentError("p_values must be finite values in [0, 1]"))
    return values
end

function _bonferroni_adjust(p_values)
    values = _checked_p_values(p_values)
    m = length(values)
    return clamp.(m .* values, 0.0, 1.0)
end

function _benjamini_hochberg_adjust(p_values)
    values = _checked_p_values(p_values)
    m = length(values)
    order = sortperm(values)
    sorted_values = values[order]
    sorted_adjusted = similar(sorted_values)
    running_min = 1.0
    for i in m:-1:1
        running_min = min(running_min, sorted_values[i] * m / i)
        sorted_adjusted[i] = clamp(running_min, 0.0, 1.0)
    end
    adjusted = similar(values)
    adjusted[order] = sorted_adjusted
    return adjusted
end

"""
    _single_step_Hinv(Ainv, A, G, genotyped_rows; tau = 1.0, omega = 1.0,
                      blend_weight = 0.0, ridge = 0.0)

Single-step genomic relationship inverse `H⁻¹` (Aguilar et al. 2010;
Christensen & Lund 2009):

    H⁻¹ = A⁻¹ + scatter(τ·Gʷ⁻¹ − ω·A₂₂⁻¹)  over the genotyped rows `g`,

where `Ainv` is the pedigree inverse `A⁻¹`, `A` the dense pedigree relationship
matrix, `A₂₂ = A[g, g]` the block among the genotyped animals (in sorted
pedigree-row order), and `Gʷ = (1 − blend_weight)·G + blend_weight·A₂₂` the
optionally blended/ridged genomic relationship among them.

Critically, `A₂₂⁻¹` is the inverse of the *submatrix* `A[g, g]`, **not** the
submatrix `(A⁻¹)[g, g]` — the two differ.

Internal validation-only construction utility: dense, not exported, and **not**
wired into fitting. The `blend_weight` / `tau` / `omega` / `ridge` knobs are not
comparator-validated; defaults are `blend_weight = ridge = 0`, `tau = omega = 1`.
"""
function _single_step_Hinv(
    Ainv::AbstractMatrix,
    A::AbstractMatrix,
    G::AbstractMatrix,
    genotyped_rows::AbstractVector{<:Integer};
    tau::Real = 1.0,
    omega::Real = 1.0,
    blend_weight::Real = 0.0,
    ridge::Real = 0.0,
)
    n = size(Ainv, 1)
    size(Ainv, 2) == n || throw(ArgumentError("Ainv must be square"))
    size(A) == (n, n) || throw(ArgumentError("A must match Ainv dimensions"))
    g = collect(genotyped_rows)
    ng = length(g)
    all(r -> 1 <= r <= n, g) ||
        throw(ArgumentError("genotyped_rows must be valid row indices of Ainv"))
    size(G) == (ng, ng) ||
        throw(ArgumentError("G must be square of size length(genotyped_rows)"))

    A22 = Matrix{Float64}(A[g, g])
    A22inv = inv(Symmetric(A22))                     # inverse of the SUBMATRIX of A
    Gblend = (1 - blend_weight) .* Matrix{Float64}(G) .+ blend_weight .* A22
    Greg = Symmetric(Gblend + ridge * I)
    isposdef(Greg) ||
        throw(ArgumentError("genotyped genomic block is not positive definite; increase ridge or blend_weight"))
    Gwinv = inv(Greg)

    Hinv = Matrix{Float64}(Ainv)
    Hinv[g, g] = Hinv[g, g] .+ (tau .* Gwinv .- omega .* A22inv)
    return Hinv
end
