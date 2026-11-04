using Test
using HSquared
using LinearAlgebra

# Test-only coverage lane: kwargs pass-through, custom ids, guards, and the
# raw-array row-order remap of the metafounder single-step H^Gamma path.
@testset "fit_metafounder_single_step kwargs, ids, guards, and input-order remap" begin
    ids = [1, 2, 3, 4, 5]; sire = [0, 0, 1, 1, 3]; dam = [0, 0, 2, 2, 4]
    ped = normalize_pedigree(ids, sire, dam)
    n = length(ped)
    needs = [ped.sire[i] == 0 || ped.dam[i] == 0 for i in 1:n]
    group = [needs[i] ? "base" : "0" for i in 1:n]
    Γ = fill(0.35, 1, 1)
    Aγ = metafounder_relationship(ped, group, Γ)
    g = [3, 4, 5]
    G = Aγ[g, g] + 0.1 * I
    y = [10.0, 12.0, 11.0, 9.0, 13.0]; X = ones(5, 1); Z = Matrix(1.0I, 5, 5)

    @testset "raw-array overload with parents listed after offspring" begin
        perm = [5, 3, 1, 4, 2]                       # offspring before parents
        ids_s, sire_s, dam_s = ids[perm], sire[perm], dam[perm]
        pedS = normalize_pedigree(ids_s, sire_s, dam_s)
        @test pedS.original_order != collect(1:n)   # the fixture really is out of order
        group_by_id = Dict(ped.ids[i] => group[i] for i in 1:n)
        group_s = [group_by_id[i] for i in ids_s]
        # genotyped animals 4, 3, 5 (deliberately not ascending), as input rows
        geno_ids = [4, 3, 5]
        rows_s = [findfirst(==(a), ids_s) for a in geno_ids]
        rows_sorted = [findfirst(==(a), ped.ids) for a in geno_ids]
        Gg = Aγ[rows_sorted, rows_sorted] + 0.1 * I

        Hraw = metafounder_single_step_inverse(ids_s, sire_s, dam_s, group_s, Γ, Gg, rows_s;
                                               tau = 0.8, omega = 1.2)
        Href = metafounder_single_step_inverse(ped, group, Γ, Gg, rows_sorted;
                                               tau = 0.8, omega = 1.2)
        idx = [findfirst(==(a), pedS.ids) for a in ped.ids]
        @test Matrix(Hraw)[idx, idx] ≈ Matrix(Href) atol = 1e-10
        # Without the remap the result would differ: input rows are not normalized rows.
        @test rows_s != [findfirst(==(a), pedS.ids) for a in geno_ids]

        @test_throws ArgumentError metafounder_single_step_inverse(
            ids_s, sire_s, dam_s, group_s, Γ, Gg, [1, 2, n + 1])
    end

    @testset "kwargs pass-through and custom ids" begin
        custom = ["a", "b", "c", "d", "e"]
        kw = (tau = 0.8, omega = 1.2, blend_weight = 0.1, ridge = 1e-6)
        fit = fit_metafounder_single_step(y, X, Z, ped, group, Γ, G, g, 1.0, 1.5;
                                          kw..., ids = custom)
        Hk = metafounder_single_step_inverse(ped, group, Γ, G, g; kw...)
        direct = fit_gblup(y, X, Z, Hk, 1.0, 1.5; ids = custom)
        @test breeding_values(fit).values ≈ breeding_values(direct).values atol = 1e-10
        @test breeding_values(fit).ids == custom
        # the knobs are not ignored
        plain = fit_metafounder_single_step(y, X, Z, ped, group, Γ, G, g, 1.0, 1.5)
        @test !isapprox(breeding_values(fit).values, breeding_values(plain).values; atol = 1e-8)
    end

    @testset "guards" begin
        @test_throws ArgumentError fit_metafounder_single_step(y, X, Z, ped, group, Γ, G, [3, 4, 6], 1.0, 1.5)
        @test_throws ArgumentError fit_metafounder_single_step(y, X, Z, ped, group, Γ, G, [0, 4, 5], 1.0, 1.5)
        @test_throws ArgumentError fit_metafounder_single_step(y, X, Z, ped, group, Γ, G[1:2, 1:2], g, 1.0, 1.5)
        @test_throws ArgumentError fit_metafounder_single_step(y, X, Z, ped, group, Γ, G, [3, 4], 1.0, 1.5)
        @test_throws ArgumentError fit_metafounder_single_step(y, X, Z, ped, group, fill(-0.35, 1, 1), G, g, 1.0, 1.5)
        group2 = vcat(group, "base")
        @test_throws ArgumentError fit_metafounder_single_step(y, X, Z, ped, group[1:end-1], Γ, G, g, 1.0, 1.5)
        @test_throws ArgumentError fit_metafounder_single_step(y, X, Z, ped, group2, Γ, G, g, 1.0, 1.5)
        @test_throws ArgumentError fit_metafounder_single_step(y, X, Z, ped, group, Γ, G, g, 0.0, 1.5)
        @test_throws ArgumentError fit_metafounder_single_step(y, X, Z, ped, group, Γ, G, g, -1.0, 1.5)
        @test_throws ArgumentError fit_metafounder_single_step(y, X, Z, ped, group, Γ, G, g, 1.0, 0.0)
        @test_throws ArgumentError fit_metafounder_single_step(y, X, Z, ped, group, Γ, G, g, 1.0, -1.5)
    end

    @testset "Gamma not symmetric / not PSD" begin
        Γ2 = [0.35 0.1; 0.2 0.35]                    # asymmetric (2 groups)
        group_two = [needs[i] ? (i == 1 ? "base" : "alt") : "0" for i in 1:n]
        @test_throws ArgumentError fit_metafounder_single_step(y, X, Z, ped, group_two, Γ2, G, g, 1.0, 1.5)
        Γ3 = [0.1 0.5; 0.5 0.1]                      # symmetric, indefinite
        @test_throws ArgumentError fit_metafounder_single_step(y, X, Z, ped, group_two, Γ3, G, g, 1.0, 1.5)
    end
end
