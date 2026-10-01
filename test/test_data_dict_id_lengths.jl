using Test
using HSquared

@testset "dictionary genotype and expression IDs match source rows" begin
    phenotypes = (id = ["a"], y = [1.0])

    genotypes = Dict(:m1 => [0, 1, 2])
    @test_throws ArgumentError HSData(
        phenotypes; genotypes, genotype_ids = ["a", "b"],
    )
    @test_throws ArgumentError HSData(
        phenotypes; genotypes, genotype_ids = ["a", "b", "c"],
        expression = Dict(:g1 => [1.0, 2.0, 3.0]), expression_ids = ["a", "b"],
    )

    aligned = HSData(
        phenotypes; genotypes, genotype_ids = ["a", "b", "c"],
    )
    genotype_status = data_status(aligned).genotype_status
    @test genotype_status[1].value == "3"
    @test genotype_status[2].value == "3"

    @test_throws ArgumentError HSData(
        phenotypes; genotypes = Dict(:m1 => [0, 1], :m2 => [0, 1, 2]),
        genotype_ids = ["a", "b", "c"],
    )

    inconsistent_table = (m1 = [0, 1, 2], m2 = [0, 1])
    table_error = try
        HSData(phenotypes; genotypes = inconsistent_table, genotype_ids = ["a", "b", "c"])
        nothing
    catch error
        error
    end
    @test table_error isa ArgumentError
    @test occursin("columns in named-tuple data must have the same number of rows", sprint(showerror, table_error))

    scalar_column_error = try
        HSData(
            phenotypes;
            genotypes = (m1 = [0, 1], metadata = nothing),
            genotype_ids = ["a", "b"],
        )
        nothing
    catch error
        error
    end
    @test scalar_column_error isa ArgumentError
    @test occursin(
        "each column in named-tuple data must have a length",
        sprint(showerror, scalar_column_error),
    )

    dict_scalar_error = try
        HSData(
            phenotypes;
            genotypes = Dict(:m1 => [0, 1], :metadata => nothing),
            genotype_ids = ["a", "b"],
        )
        nothing
    catch error
        error
    end
    @test dict_scalar_error isa ArgumentError
    @test occursin(
        "each column in dictionary data must have a length",
        sprint(showerror, dict_scalar_error),
    )
end

@testset "HSData preserves exact typed ID matching" begin
    data = HSData(
        (id = [1], y = [1.0]);
        genotypes = Dict(:m1 => [0, 1]), genotype_ids = ["1", "other"],
    )

    @test id_map(data).phenotypes_without_genotypes == [1]
    @test id_map(data).genotypes_without_phenotypes == ["1", "other"]
    @test_throws ArgumentError HSData((id = Int[], y = Float64[]))
end
