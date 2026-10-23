using Test
using HSquared
using LinearAlgebra

@testset "Pedigree direct constructor enforces normalized indices" begin
    @test_throws ArgumentError Pedigree(["a", "b"], [0], [0, 0], [1, 2])
    @test_throws ArgumentError Pedigree(["a", "a"], [0, 0], [0, 0], [1, 2])
    for unknown_id in (missing, nothing, "", "0", 0)
        @test_throws ArgumentError Pedigree([unknown_id], [0], [0], [1])
    end
    custom_markers = ("NA",)
    custom_normalized = normalize_pedigree(
        ["0", "child"], ["NA", "0"], ["NA", "NA"]; missing_values = custom_markers,
    )
    @test custom_normalized.ids == ["0", "child"]
    @test custom_normalized.sire == [0, 1]
    @test Pedigree(copy(custom_normalized.ids), copy(custom_normalized.sire),
                   copy(custom_normalized.dam), copy(custom_normalized.original_order);
                   missing_values = custom_markers) isa Pedigree
    @test_throws ArgumentError Pedigree(["NA"], [0], [0], [1]; missing_values = custom_markers)
    @test_throws ArgumentError Pedigree(["a", "b"], [-1, 0], [0, 0], [1, 2])
    @test_throws ArgumentError Pedigree(["a", "b"], [0, 2], [0, 0], [1, 2])
    @test_throws ArgumentError Pedigree(["a", "b"], [1, 0], [0, 0], [1, 2])
    @test_throws ArgumentError Pedigree(["a", "b"], [2, 0], [0, 0], [1, 2])
    @test_throws ArgumentError Pedigree(["a", "b"], [0, 0], [0, 0], [1, 1])
    @test_throws ArgumentError Pedigree(["a", "b"], [0, 0], [0, 0], [1, 3])

    normalized = normalize_pedigree(["child", "parent"], ["parent", "0"], ["0", "0"])
    @test Pedigree(copy(normalized.ids), copy(normalized.sire), copy(normalized.dam),
                   copy(normalized.original_order)) isa Pedigree

    @test_throws ArgumentError Pedigree(["sire", "offspring"], [0, 1], [0, 1], [1, 2])
    selfed = Pedigree(["sire", "offspring"], [0, 1], [0, 1], [1, 2]; allow_selfing = true)
    @test inbreeding_coefficients(selfed) ≈ [0.0, 0.5]
    A = additive_relationship(selfed)
    @test Matrix(pedigree_inverse(selfed)) ≈ inv(A)
end

@testset "metafounder relationship rejects nonpositive Mendelian variance" begin
    ids = ["a", "b"]
    sire = [0, 0]
    dam = [0, 0]
    groups = ["g", "g"]

    # For two founders assigned to one metafounder with gamma=2, the
    # conditional Mendelian variance is zero; gamma=3 makes it negative.
    for gamma in (2.0, 3.0)
        Gamma = reshape([gamma], 1, 1)
        @test_throws ArgumentError metafounder_relationship(ids, sire, dam, groups, Gamma)
        @test_throws ArgumentError metafounder_relationship_inverse(ids, sire, dam, groups, Gamma)
    end

    # Positive-definite Gamma alone is insufficient: a group-specific
    # conditional variance can still be negative.
    Gamma_multi = [1.0 0.2; 0.2 3.0]
    @test_throws ArgumentError metafounder_relationship(
        ids, sire, dam, ["low", "high"], Gamma_multi,
    )
end

@testset "fully parented animals ignore their metafounder group entry" begin
    ids = ["sire", "dam", "child"]
    sire = ["0", "0", "sire"]
    dam = ["0", "0", "dam"]
    Gamma = reshape([0.5], 1, 1)
    ignored = metafounder_relationship(ids, sire, dam, ["base", "base", "unused"], Gamma)
    marker = metafounder_relationship(ids, sire, dam, ["base", "base", nothing], Gamma)
    @test ignored ≈ marker
end

@testset "Raw metafounder wrappers preserve pedigree ID alignment" begin
    # The input rows are deliberately not topologically sorted. `group_of` follows
    # the same input-ID order and distinguishes the two founder groups.
    ids = ["child", "sire", "dam"]
    sire = ["sire", "0", "0"]
    dam = ["0", "0", "0"]
    group_of = ["child_group", "founder_group", "founder_group"]
    Gamma = [0.6 0.15; 0.15 0.8]
    ped = normalize_pedigree(ids, sire, dam)
    sorted_group = group_of[ped.original_order]
    A_gamma = metafounder_relationship(ped, sorted_group, Gamma)

    @test metafounder_relationship(ids, sire, dam, group_of, Gamma) ≈ A_gamma
    @test metafounder_relationship_inverse(ids, sire, dam, group_of, Gamma) ≈ inv(A_gamma)
    @test metafounder_inbreeding(ids, sire, dam, group_of, Gamma) ≈ diag(A_gamma) .- 1
    @test metafounder_inverse(ids, sire, dam, group_of, Gamma) ≈
          metafounder_inverse(ped, sorted_group, Gamma)

    # The raw-array wrapper interprets genotype rows in the caller's original ID
    # order, even when the genotype subset is scattered and differently ordered.
    input_genotyped_rows = [3, 1]
    original_to_sorted = invperm(ped.original_order)
    normalized_genotyped_rows = original_to_sorted[input_genotyped_rows]
    G = A_gamma[normalized_genotyped_rows, normalized_genotyped_rows]
    @test metafounder_single_step_inverse(
        ids, sire, dam, group_of, Gamma, G, input_genotyped_rows,
    ) ≈ metafounder_single_step_inverse(
        ped, sorted_group, Gamma, G, normalized_genotyped_rows,
    )
    @test_throws ArgumentError metafounder_single_step_inverse(
        ids, sire, dam, group_of, Gamma, G, [length(ids) + 1],
    )
    @test_throws ArgumentError metafounder_relationship(ids, sire, dam, group_of[1:2], Gamma)
    @test_throws ArgumentError metafounder_relationship(
        ids, sire, dam, group_of, Gamma; max_relationship_cache = length(ped) - 1,
    )

    # Raw wrappers retain normalization controls instead of forwarding them to
    # the already-normalized Pedigree methods.
    custom_ids = ["selfed", "founder"]
    custom_sire = ["founder", "NA"]
    custom_dam = ["founder", "NA"]
    custom_group = ["NA", "base"]
    custom_ped = normalize_pedigree(custom_ids, custom_sire, custom_dam;
                                    missing_values = ("NA",), allow_selfing = true)
    custom_sorted_group = custom_group[custom_ped.original_order]
    custom_Gamma = reshape([0.7], 1, 1)
    custom_A = metafounder_relationship(custom_ped, custom_sorted_group, custom_Gamma)
    @test metafounder_relationship(
        custom_ids, custom_sire, custom_dam, custom_group, reshape([0.7], 1, 1);
        missing_values = ("NA",), allow_selfing = true,
    ) ≈ custom_A
    @test metafounder_relationship_inverse(
        custom_ids, custom_sire, custom_dam, custom_group, custom_Gamma;
        missing_values = ("NA",), allow_selfing = true,
    ) ≈ inv(custom_A)
    @test metafounder_inbreeding(
        custom_ids, custom_sire, custom_dam, custom_group, custom_Gamma;
        missing_values = ("NA",), allow_selfing = true,
    ) ≈ diag(custom_A) .- 1
    @test metafounder_inverse(
        custom_ids, custom_sire, custom_dam, custom_group, custom_Gamma;
        missing_values = ("NA",), allow_selfing = true,
    ) ≈ metafounder_inverse(custom_ped, custom_sorted_group, custom_Gamma)

    custom_input_rows = [2, 1]
    custom_normalized_rows = invperm(custom_ped.original_order)[custom_input_rows]
    custom_G = custom_A[custom_normalized_rows, custom_normalized_rows]
    @test metafounder_single_step_inverse(
        custom_ids, custom_sire, custom_dam, custom_group, custom_Gamma,
        custom_G, custom_input_rows; missing_values = ("NA",), allow_selfing = true,
    ) ≈ metafounder_single_step_inverse(
        custom_ped, custom_sorted_group, custom_Gamma, custom_G, custom_normalized_rows,
    )

    meta_row = only(row for row in validation_status() if row.id == "V1-METAFOUNDER")
    @test meta_row.status == "partial"
    @test occursin("single-step H^Γ primitive", meta_row.evidence)
    @test occursin("supplied-variance animal-model MME", meta_row.claim_boundary)
    @test occursin("no R-facing formula or payload", meta_row.claim_boundary)
    @test occursin("or covered claim", meta_row.claim_boundary)
end
