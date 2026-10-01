using Test
using HSquared

@testset "Dictionary physical marker missingness" begin
    phenotypes = (id = ["a", "b"], y = [1.0, 2.0])
    for (symbol_values, string_values) in [
        ([0, 1], [missing, 3]),
        ([missing, 1], [0, 3]),
        ([missing, nothing], [missing, 3]),
        ([0, 1], [0, 3]),
    ]
        genotypes = Dict{Any,Any}(:id => ["a", "b"], :m1 => symbol_values,
                                  "m1" => string_values)
        physical_count = sum(count(v -> ismissing(v) || v === nothing, values)
                             for (key, values) in genotypes if string(key) != "id")
        before = deepcopy(genotypes)
        rows = data_status(HSData(phenotypes; genotypes)).genotype_status
        metrics = Dict(row.metric => row.value for row in rows)
        @test HSquared._genotype_missing_value_count(genotypes, :id) == physical_count
        @test metrics["missing_genotype_values"] == string(physical_count)
        @test metrics["duplicate_genotype_marker_columns"] == "1"
        @test metrics["genotype_marker_columns"] == "2"
        @test isequal(genotypes, before)
    end

    # Original key lookup also preserves string-only, Symbol-only, and custom IDs.
    for genotypes in [
        Dict{Any,Any}("id" => ["a", "b"], "m1" => [missing, 1]),
        Dict{Any,Any}(:id => ["a", "b"], :m1 => [nothing, 1]),
    ]
        rows = data_status(HSData(phenotypes; genotypes)).genotype_status
        metrics = Dict(row.metric => row.value for row in rows)
        @test metrics["missing_genotype_values"] == "1"
        @test metrics["duplicate_genotype_marker_columns"] == "0"
    end
    custom = Dict{Any,Any}("sample" => ["a", "b"], :m1 => [0, 1],
                            "m1" => [nothing, 3])
    rows = data_status(HSData(phenotypes; genotypes = custom,
                              genotype_id = "sample")).genotype_status
    metrics = Dict(row.metric => row.value for row in rows)
    @test metrics["missing_genotype_values"] == "1"
    @test metrics["genotype_marker_columns"] == "2"

    named = (id = ["a", "b"], m1 = [missing, 1], m2 = [0, nothing])
    @test HSquared._genotype_missing_value_count(named, :id) == 2
    matrix = [missing 1; 0 nothing]
    @test HSquared._genotype_missing_value_count(matrix, :id) == 2
    @test HSquared._genotype_missing_value_count(Dict(:id => ["a", "b"]), :id) == 0
end
