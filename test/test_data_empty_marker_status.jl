using Test
using HSquared

@testset "empty marker maps have unavailable position bounds" begin
    phenotypes = (id = ["a", "b"], y = [1.0, 2.0])
    markers = (marker = String[], chromosome = String[], position = Float64[])
    data = HSData(phenotypes; markers)

    status = data_status(data)
    @test [row.metric for row in status.marker_status] == [
        "marker_map_markers",
        "genotype_marker_columns",
        "aligned_marker_columns",
        "chromosomes",
        "position_min",
        "position_max",
        "alignment",
    ]
    @test [row.value for row in status.marker_status] == [
        "0",
        "0",
        "0",
        "0",
        "not_available",
        "not_available",
        "not_checked_no_genotypes",
    ]
end

@testset "raw pedigree status preserves a lone parent alias" begin
    phenotypes = (id = ["a", "b"], y = [1.0, 2.0])

    sire_only = data_status(HSData(phenotypes;
        pedigree = (id = ["a", "b"], father = ["0", "ghost"]))).pedigree_status
    @test sire_only[7].count == 1
    @test sire_only[8].count == 0
    @test sire_only[9].count == 1

    dam_only = data_status(HSData(phenotypes;
        pedigree = (id = ["a", "b"], mother = ["0", "ghost"]))).pedigree_status
    @test dam_only[7].count == 0
    @test dam_only[8].count == 1
    @test dam_only[9].count == 1

    sire_with_metadata = data_status(HSData(phenotypes;
        pedigree = (id = ["a", "b"], father = ["0", "ghost"], sex = ["F", "M"]))).pedigree_status
    sire_metadata_counts = Dict(row.metric => row.count for row in sire_with_metadata)
    @test sire_metadata_counts["known_sire_links"] == 1
    @test sire_metadata_counts["known_dam_links"] == 0
    @test sire_metadata_counts["missing_known_parent_ids"] == 1

    dam_with_metadata = data_status(HSData(phenotypes;
        pedigree = (id = ["a", "b"], sex = ["F", "M"], mother = ["0", "ghost"]))).pedigree_status
    dam_metadata_counts = Dict(row.metric => row.count for row in dam_with_metadata)
    @test dam_metadata_counts["known_sire_links"] == 0
    @test dam_metadata_counts["known_dam_links"] == 1
    @test dam_metadata_counts["missing_known_parent_ids"] == 1

    malformed = (id = ["a", "b"], father = ["0"])
    @test_throws ArgumentError data_status(HSData(phenotypes; pedigree = malformed))
end
