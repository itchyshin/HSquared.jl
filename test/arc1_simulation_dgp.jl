using Test
include(joinpath(@__DIR__, "..", "sim", "arc1", "independent_dgp.jl"))

@testset "Arc1 independent simulation DGP" begin
    ped = arc1_founder_pedigree(16)
    @test length(ped.ids) == 22
    @test length(ped.observed_rows) == 16
    @test length(ped.observed_ids) == 16
    @test [ped.observed_id_to_row[id] for id in ped.observed_ids] == ped.observed_rows
    A = arc1_dense_relationship_oracle(ped)
    @test all(A[i,i] == 1 for i in 1:size(A,1))
    # First sire's first dam offspring are rows 7:10; second dam rows 11:14.
    @test A[7,8] == 0.5
    @test A[7,11] == 0.25
    @test A[7,15] == 0.0
    @test_throws ArgumentError arc1_founder_pedigree(15)
    @test_throws ArgumentError arc1_fa_truth(1.0)

    # Controlled one-hot innovations reconstruct the implemented inheritance
    # map and its multivariate record covariance without a stochastic tolerance.
    C = arc1_inheritance_transform(ped)
    @test C * C' ≈ A atol=1e-14 rtol=1e-14
    truth = arc1_fa_truth(0.15)
    observed = ped.observed_rows
    Aobs = A[observed, observed]
    fa_basis = arc1_fa_innovation_basis(ped, truth)
    generated_covariance = fa_basis * fa_basis'
    target_covariance = kron(Aobs, truth.G) + kron(Matrix{Float64}(I, 16, 16), truth.R)
    @test generated_covariance ≈ target_covariance atol=2e-14 rtol=2e-14

    a = arc1_simulate_fa(UInt64(0x0123456789abcdef), 16, 0.15)
    perm = [16, 1, 9, 4, 13, 2, 7, 11, 5, 3, 12, 6, 10, 8, 14, 15]
    b = arc1_simulate_fa(UInt64(0x0123456789abcdef), 16, 0.15; row_order=perm)
    @test a.truth.G == b.truth.G
    @test a.observed_id_to_row == b.observed_id_to_row
    @test Dict(id => vec(a.Y[i,:]) for (i,id) in pairs(a.observed_ids)) ==
          Dict(id => vec(b.Y[i,:]) for (i,id) in pairs(b.observed_ids))
    @test all(isfinite, a.Y)
    @test size(a.Y) == (16, 4)
    @test a.julia_version == string(VERSION)
    @test a.seed == UInt64(0x0123456789abcdef)

    r = arc1_simulate_repeatability(UInt64(7), 16, :near_zero_pe)
    rperm = arc1_simulate_repeatability(UInt64(7), 16, :near_zero_pe; row_order=perm)
    @test length(r.y) == 32
    @test r.truth.Vpe == 0.01
    @test r.observed_ids == ped.observed_ids
    repeat_rows = (y, ids) -> Dict(id => y[2i-1:2i] for (i, id) in pairs(ids))
    @test repeat_rows(r.y, r.observed_ids) == repeat_rows(rperm.y, rperm.observed_ids)
    @test length(unique(r.record_ids)) == 32
    @test [r.record_id_to_row[id] for id in r.record_ids] == collect(1:32)
    @test r.record_animal_ids == repeat(r.observed_ids; inner=2)
    rec_order = reverse(1:32)
    rrecords = arc1_simulate_repeatability(UInt64(7), 16, :near_zero_pe; record_order=rec_order)
    @test rrecords.record_ids == r.record_ids[rec_order]
    @test rrecords.record_animal_ids == r.record_animal_ids[rec_order]
    @test rrecords.y == r.y[rec_order]

    for (label, Va, Vpe, Ve) in ((:Va_zero, 0.0, 0.3, 0.7), (:Vpe_zero, 0.3, 0.0, 0.7))
        edge = arc1_repeatability_truth(label)
        @test (edge.Va, edge.Vpe, edge.Ve) == (Va, Vpe, Ve)
        edge_data = arc1_simulate_repeatability(UInt64(8), 16, label)
        @test all(isfinite, edge_data.y)

        basis = arc1_repeatability_innovation_basis(ped, edge)
        basis_cov = basis * basis'
        repeated_A = kron(Aobs, ones(2,2))
        expected_cov = Va .* repeated_A + Vpe .* kron(Matrix{Float64}(I,16,16), ones(2,2)) + Ve .* Matrix{Float64}(I,32,32)
        @test basis_cov ≈ expected_cov atol=2e-14 rtol=2e-14
    end
end
