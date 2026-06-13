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
