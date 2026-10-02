# Independent founder/Mendelian DGP for Arc1 evidence generation.

# This file deliberately does not call HSquared relationship, kernel, or fit
# helpers. N is the number of observed offspring; parents are retained as
# unobserved pedigree rows and the returned map identifies observed rows.
using LinearAlgebra
using Random

function arc1_fa_truth(rho::Real)
    0 <= rho < 1 || throw(ArgumentError("rho must be in [0,1); rho=1 is singular for this simulator"))
    loading = sqrt(0.5 * rho) .* [1.0, 1.0, -1.0, -1.0]
    psi = fill(0.5 * (1 - rho), 4)
    G = loading * loading' + Diagonal(psi)
    R = fill(0.1, 4, 4)
    R[diagind(R)] .= 0.5
    return (; loading, psi, G=Matrix(G), R)
end

function arc1_repeatability_truth(signal::Symbol)
    vals = signal === :interior ? (0.3, 0.2, 0.5) :
           signal === :near_zero_pe ? (0.3, 0.01, 0.69) :
           signal === :near_zero_additive ? (0.01, 0.3, 0.69) :
           signal === :Va_zero ? (0.0, 0.3, 0.7) :
           signal === :Vpe_zero ? (0.3, 0.0, 0.7) :
           throw(ArgumentError("unknown repeatability signal: $signal"))
    return (; Va=vals[1], Vpe=vals[2], Ve=vals[3], h2=vals[1]/sum(vals),
            repeatability=(vals[1]+vals[2])/sum(vals))
end

"""Apply the frozen founder/Mendelian recursion to one row of innovations per animal."""
function arc1_apply_inheritance(ped, innovations::AbstractMatrix;
                                sire_weight=0.5, dam_weight=0.5, mendelian_weight=sqrt(0.5))
    n = length(ped.ids)
    size(innovations, 1) == n || throw(ArgumentError("one innovation row is required per pedigree animal"))
    effects = Matrix{Float64}(innovations)
    for i in 1:n
        sire, dam = ped.sire[i], ped.dam[i]
        if sire != 0 && dam != 0
            effects[i, :] = sire_weight .* effects[sire, :] .+
                            dam_weight .* effects[dam, :] .+
                            mendelian_weight .* innovations[i, :]
        end
    end
    return effects
end

"""Linear inheritance map used by the simulator, also useful for exact basis checks."""
function arc1_inheritance_transform(ped; kwargs...)
    return arc1_apply_inheritance(ped, Matrix{Float64}(I, length(ped.ids), length(ped.ids)); kwargs...)
end

"""Innovation-to-record matrix for the two-record repeatability simulator."""
function arc1_repeatability_innovation_basis(ped, truth)
    m = length(ped.observed_rows); n = length(ped.ids)
    Cobs = arc1_inheritance_transform(ped)[ped.observed_rows, :]
    basis = zeros(2m, n + 3m)
    for i in 1:m
        for r in 1:2
            row = 2i - 2 + r
            basis[row, 1:n] .= sqrt(truth.Va) .* Cobs[i, :]
            basis[row, n+i] = sqrt(truth.Vpe)
            basis[row, n+m+2i-2+r] = sqrt(truth.Ve)
        end
    end
    return basis
end

"""FA innovation-to-observed-record map in record-major trait blocks."""
function arc1_fa_innovation_basis(ped, truth)
    m = length(ped.observed_rows)
    Cobs = arc1_inheritance_transform(ped)[ped.observed_rows, :]
    LG = cholesky(Symmetric(truth.G)).L
    LR = cholesky(Symmetric(truth.R)).L
    return hcat(kron(Cobs, LG), kron(Matrix{Float64}(I, m, m), LR))
end

"""Build the frozen unrelated-founder, two-dams-per-sire, 4-offspring/dam pedigree."""
function arc1_founder_pedigree(N::Integer)
    N > 0 && N % 8 == 0 || throw(ArgumentError("N observed offspring must be positive and divisible by 8"))
    nsire = N ÷ 8
    ids = String[]; sire = Int[]; dam = Int[]; observed = Int[]
    for i in 1:nsire
        push!(ids, "sire-$i"); push!(sire, 0); push!(dam, 0)
    end
    sire_rows = collect(1:nsire)
    dam_rows = Int[]
    for i in 1:(2nsire)
        push!(ids, "dam-$i"); push!(sire, 0); push!(dam, 0); push!(dam_rows, length(ids))
    end
    for i in 1:nsire, d in 1:2, k in 1:4
        push!(ids, "offspring-$(length(observed)+1)")
        push!(sire, sire_rows[i]); push!(dam, dam_rows[2(i-1)+d]); push!(observed, length(ids))
    end
    return (; ids, sire, dam, observed_rows=observed,
            observed_ids=ids[observed], observed_id_to_row=Dict(ids[j]=>j for j in observed))
end

"""Independent tabular covariance oracle based only on parent links."""
function arc1_dense_relationship_oracle(ped)
    n = length(ped.ids); A = zeros(n, n)
    for i in 1:n
        s, d = ped.sire[i], ped.dam[i]
        for j in 1:(i-1)
            A[i,j] = A[j,i] = (s == 0 ? 0.0 : 0.5A[s,j]) + (d == 0 ? 0.0 : 0.5A[d,j])
        end
        A[i,i] = 1 + (s == 0 || d == 0 ? 0.0 : 0.5A[s,d])
    end
    return A
end

function _arc1_mvn(rng, covariance)
    return cholesky(Symmetric(Matrix{Float64}(covariance))).L * randn(rng, size(covariance,1))
end

"""Generate independent FA records; returns truth and the explicit observed-ID mapping."""
function arc1_simulate_fa(seed::UInt64, N::Integer, rho::Real; row_order=nothing)
    ped = arc1_founder_pedigree(N); truth = arc1_fa_truth(rho); rng = MersenneTwister(seed)
    innovations = Float64[]
    for _ in ped.ids
        append!(innovations, randn(rng, 4))
    end
    for _ in 1:N
        append!(innovations, randn(rng, 4))
    end
    basis = arc1_fa_innovation_basis(ped, truth)
    generated = basis * innovations
    Y = permutedims(reshape(generated, 4, N)) .+ [0.0, 1.0, -1.0, 2.0]'
    order = row_order === nothing ? collect(1:N) : collect(row_order)
    sort(order) == collect(1:N) || throw(ArgumentError("row_order must be a permutation of observed offspring"))
    return (; Y=Y[order,:], pedigree=ped, observed_ids=ped.observed_ids[order],
            observed_id_to_row=ped.observed_id_to_row, truth, seed, julia_version=string(VERSION),
            row_order=order)
end

"""Generate two-record scalar repeatability observations on the same pedigree."""
function arc1_simulate_repeatability(seed::UInt64, N::Integer, signal::Symbol;
                                     row_order=nothing, record_order=nothing)
    ped = arc1_founder_pedigree(N); truth = arc1_repeatability_truth(signal); rng = MersenneTwister(seed)
    order = row_order === nothing ? collect(1:N) : collect(row_order)
    sort(order) == collect(1:N) || throw(ArgumentError("row_order must be a permutation of observed offspring"))
    innovations = Vector{Float64}(undef, length(ped.ids) + 3N)
    innovations[1:length(ped.ids)] = randn(rng, length(ped.ids))
    offset = length(ped.ids)
    for i in 1:N
        innovations[offset + i] = randn(rng) # one permanent effect shared by both records
        innovations[offset + N + 2i - 1] = randn(rng)
        innovations[offset + N + 2i] = randn(rng)
    end
    basis = arc1_repeatability_innovation_basis(ped, truth)
    canonical_y = basis * innovations
    rows = reduce(vcat, ([2i-1, 2i] for i in order))
    generated_record_ids = ["$(ped.observed_ids[i])-record-$r" for i in order for r in 1:2]
    generated_record_animal_ids = repeat(ped.observed_ids[order]; inner=2)
    rec_order = record_order === nothing ? collect(1:2N) : collect(record_order)
    sort(rec_order) == collect(1:2N) || throw(ArgumentError("record_order must permute 1:2N"))
    selected_rows = rows[rec_order]
    return (; y=canonical_y[selected_rows], pedigree=ped, observed_ids=ped.observed_ids[order],
            observed_id_to_row=ped.observed_id_to_row, truth, seed, julia_version=string(VERSION),
            row_order=order, record_ids=generated_record_ids[rec_order],
            record_animal_ids=generated_record_animal_ids[rec_order],
            record_id_to_row=Dict(id=>i for (i,id) in pairs(generated_record_ids[rec_order])))
end
