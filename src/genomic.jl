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

    scale = 2 * sum(p .* (1 .- p))
    scale > 0 ||
        throw(ArgumentError("genomic scaling is zero; all markers are monomorphic"))

    Z = M .- 2 .* transpose(p)
    return (Z * transpose(Z)) ./ scale
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
