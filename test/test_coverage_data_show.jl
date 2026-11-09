# HJ1 — data.jl show methods and status container printing.

using HSquared
using Test

@testset "HSData show helpers (HJ1)" begin
    phenotypes = (id = ["a", "b"], y = [1.0, 2.0])
    data = HSData(phenotypes; pedigree = (id = ["a", "b"], sire = ["0", "0"], dam = ["0", "0"]))
    ds = sprint(show, data)
    @test occursin("HSData(", ds)
    @test occursin("phenotype IDs", ds)
    @test occursin("pedigree IDs", ds)

    im = sprint(show, data.id_map)
    @test occursin("HSDataIDMap(", im)
    @test occursin("phenotype IDs", im)

    status = data_status(data)
    ss = sprint(show, status)
    @test occursin("HSDataStatus(", ss)
    @test occursin("phenotypes", ss)
    @test status.pedigree_status !== nothing
end
