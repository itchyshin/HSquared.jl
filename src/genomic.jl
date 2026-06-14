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

This is the Phase 2 genomic-relationship construction utility. It builds `G`
only: the genomic inverse `Ginv`, GBLUP / single-step fitting, and marker-effect
outputs are not implemented. `G` is typically rank-deficient when there are fewer
markers than individuals and needs regularization before inversion.
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
[`genomic_relationship_matrix`](@ref)). It is intended as the genomic
relationship inverse for the animal-model engine (GBLUP), but is a construction
utility only and is **not yet wired into model fitting**. A genomic `G` built
from markers is usually rank-deficient (markers < individuals), so a ridge is
added to the diagonal before inversion: `inv(G + ridge·I)`.

This is a simple ridge regularization. Blending `G` with a pedigree `A`
(single-step / `H`-matrix) is not implemented.
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
`p_values`, `bonferroni_p_values`, `bh_q_values`, `denominators`, `p`, and
`k`. `p_values` are approximate two-sided Gaussian/Wald p-values implied by
the supplied residual variance. `bonferroni_p_values` and `bh_q_values` are
deterministic Bonferroni and Benjamini-Hochberg adjustments over the returned
marker set.

This is a deterministic Phase 5 validation-scale utility. It is not a mixed
model GWAS/QTL scan, does not account for relatedness or population structure,
does not compute LOD scores or calibrated/correlated-marker multiple-testing
workflows, and does not activate the R-facing `marker_scan()` formula term.
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

    return (
        marker_ids = marker_names,
        effects = effects,
        standard_errors = standard_errors,
        z_scores = z_scores,
        chisq = chisq,
        p_values = p_values,
        bonferroni_p_values = bonferroni_p_values,
        bh_q_values = bh_q_values,
        denominators = denominators,
        p = cm.p,
        k = cm.k,
    )
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
