using Test, HSquared, LinearAlgebra

@testset "metafounder_animal_model guards and cross-identities" begin
    ids = ["s1", "s2", "d1", "o1", "o2", "o3"]
    sire = ["0", "0", "0", "s1", "s1", "s2"]
    dam = ["0", "0", "0", "d1", "d1", "o1"]
    ped = normalize_pedigree(ids, sire, dam)
    n = length(ped)
    founder = [ped.sire[i] == 0 || ped.dam[i] == 0 for i in 1:n]
    group1 = [founder[i] ? "base" : "0" for i in 1:n]
    # two metafounder groups: s1, s2 -> "A"; d1 -> "B"
    group2 = [founder[i] ? (ped.ids[i] == "d1" ? "B" : "A") : "0" for i in 1:n]
    y = [5.2, 4.8, 5.0, 5.5, 4.6, 5.1]
    X = ones(n, 1)
    Z = Matrix(1.0I, n, n)
    σa, σe = 1.0, 2.0

    # Cross-identity: with G = A^Γ[g,g] and tau = omega = 1, H^Γ⁻¹ = inv(A^Γ),
    # so the single-step EBVs equal the animal-only metafounder solve.
    @testset "equals fit_metafounder_single_step with G = A^Γ[g,g]" begin
        for (group, Γ) in ((group1, fill(0.3, 1, 1)),
                           (group2, [0.5 0.2; 0.2 0.6]))
            Aγ = metafounder_relationship(ped, group, Γ)
            rows = [4, 5, 6]
            res = metafounder_animal_model(y, X, Z, ped, group, Γ, σa, σe)
            ss = fit_metafounder_single_step(y, X, Z, ped, group, Γ, Aγ[rows, rows], rows, σa, σe)
            @test ss.beta ≈ res.beta atol = 1e-8
            @test ss.animal_effects.values ≈ res.animal_effects.values atol = 1e-8
        end
    end

    # m = 2 with a nonzero off-diagonal
    @testset "m = 2 off-diagonal Γ" begin
        Γ = [0.5 0.2; 0.2 0.6]
        res = metafounder_animal_model(y, X, Z, ped, group2, Γ, σa, σe)
        manual = henderson_mme(
            animal_model_spec(y, X, Z, metafounder_relationship_inverse(ped, group2, Γ); ids = ped.ids),
            σa, σe)
        @test res.beta ≈ manual.beta atol = 1e-12
        @test res.animal_effects.values ≈ manual.animal_effects.values atol = 1e-12
        res0 = metafounder_animal_model(y, X, Z, ped, group2, zeros(2, 2), σa, σe)
        @test maximum(abs.(res.animal_effects.values .- res0.animal_effects.values)) > 1e-6
        # the off-diagonal itself matters
        resd = metafounder_animal_model(y, X, Z, ped, group2, Diagonal([0.5, 0.6]) |> Matrix, σa, σe)
        @test maximum(abs.(res.animal_effects.values .- resd.animal_effects.values)) > 1e-6
        # Γ size must match the number of resolved groups
        @test_throws ArgumentError metafounder_animal_model(y, X, Z, ped, group2, fill(0.3, 1, 1), σa, σe)
    end

    @testset "ids keyword" begin
        Γ = fill(0.3, 1, 1)
        custom = ["a$i" for i in 1:n]
        res = metafounder_animal_model(y, X, Z, ped, group1, Γ, σa, σe; ids = custom)
        default = metafounder_animal_model(y, X, Z, ped, group1, Γ, σa, σe)
        @test collect(res.animal_effects.ids) == custom
        @test collect(default.animal_effects.ids) == collect(ped.ids)
        @test res.animal_effects.values ≈ default.animal_effects.values atol = 1e-12
    end

    @testset "variance guards" begin
        Γ = fill(0.3, 1, 1)
        @test_throws ArgumentError metafounder_animal_model(y, X, Z, ped, group1, Γ, 0.0, σe)
        @test_throws ArgumentError metafounder_animal_model(y, X, Z, ped, group1, Γ, -1.0, σe)
        @test_throws ArgumentError metafounder_animal_model(y, X, Z, ped, group1, Γ, σa, 0.0)
        @test_throws ArgumentError metafounder_animal_model(y, X, Z, ped, group1, Γ, σa, -2.0)
    end

    @testset "Γ guards" begin
        @test_throws ArgumentError metafounder_animal_model(y, X, Z, ped, group2, [0.5 0.3; 0.1 0.6], σa, σe)  # non-symmetric
        @test_throws ArgumentError metafounder_animal_model(y, X, Z, ped, group2, [0.5 0.9; 0.9 0.5], σa, σe)  # not PSD
        @test_throws ArgumentError metafounder_animal_model(y, X, Z, ped, group1, fill(-1.0, 1, 1), σa, σe)    # not PSD
    end

    @testset "group_of guards" begin
        Γ = fill(0.3, 1, 1)
        @test_throws ArgumentError metafounder_animal_model(y, X, Z, ped, group1[1:5], Γ, σa, σe)       # wrong length
        @test_throws ArgumentError metafounder_animal_model(y, X, Z, ped, [group1; "base"], Γ, σa, σe)  # too long
        unknown = copy(group1); unknown[1] = "0"                                                       # founder without a group
        @test_throws ArgumentError metafounder_animal_model(y, X, Z, ped, unknown, Γ, σa, σe)
    end
end
