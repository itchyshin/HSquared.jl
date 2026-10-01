using HSquared
using LinearAlgebra
using Test

@testset "one known inbred parent and one unrelated missing parent" begin
    ids = ["a", "b", "c", "k"]
    sire = ["0", "0", "a", "a"]
    dam = ["0", "0", "b", "c"]
    base = normalize_pedigree(ids, sire, dam)
    base_Ainv = Matrix(pedigree_inverse(base))
    @test inbreeding_coefficients(base)[findfirst(==("k"), base.ids)] ≈ 0.25

    # The known parent k is inbred. Put k in the sire position, then the dam
    # position, with the other parent unknown and unrelated by convention.
    sire_ped = normalize_pedigree([ids; "u"], [sire; "k"], [dam; "0"])
    dam_ped = normalize_pedigree([ids; "u"], [sire; "0"], [dam; "k"])
    for ped in (sire_ped, dam_ped)
        k = findfirst(==("k"), ped.ids)
        u = findfirst(==("u"), ped.ids)
        F = inbreeding_coefficients(ped)
        d = mendelian_sampling_variances(ped)
        Ainv = Matrix(pedigree_inverse(ped))
        A = additive_relationship(ped)

        @test F[u] ≈ 0.0
        @test d[u] ≈ 11 / 16
        @test Ainv[u, u] ≈ 16 / 11
        @test Ainv[k, k] ≈ base_Ainv[findfirst(==("k"), base.ids), findfirst(==("k"), base.ids)] + 4 / 11
        @test Ainv[u, k] ≈ -8 / 11
        @test Ainv ≈ transpose(Ainv)
        @test Ainv * A ≈ I atol = 1e-10
    end
    @test Matrix(pedigree_inverse(sire_ped)) ≈ Matrix(pedigree_inverse(dam_ped))

    # A descendant of the one-parent animal has F = 1/16, checking that the
    # inbreeding traversal propagates through the unknown-mate convention.
    descendant = normalize_pedigree([ids; "u"; "v"], [sire; "k"; "u"], [dam; "0"; "b"])
    v = findfirst(==("v"), descendant.ids)
    @test inbreeding_coefficients(descendant)[v] ≈ 1 / 16
    @test Matrix(pedigree_inverse(descendant)) * additive_relationship(descendant) ≈ I atol = 1e-10
end

@testset "Float64 selfing boundary rejects zero Mendelian variance" begin
    depth = 80
    ids = ["g$i" for i in 0:depth]
    sire = fill("0", depth + 1)
    dam = fill("0", depth + 1)
    for i in 2:(depth + 1)
        sire[i] = ids[i - 1]
        dam[i] = ids[i - 1]
    end
    ped = normalize_pedigree(ids, sire, dam; allow_selfing = true)
    F = inbreeding_coefficients(ped)
    @test F[findfirst(==("g54"), ped.ids)] == 1.0
    @test_throws ArgumentError pedigree_inverse(ped)
end
