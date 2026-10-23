using Test

@testset "issue 404 install command" begin
    root = normpath(joinpath(@__DIR__, ".."))
    readme = read(joinpath(root, "README.md"), String)
    index = read(joinpath(root, "docs", "src", "index.md"), String)
    quickstart = read(joinpath(root, "docs", "src", "quickstart.md"), String)
    install = "Pkg.add(url = \"https://github.com/itchyshin/HSquared.jl\")"

    @test occursin(install, readme)
    @test occursin("Julia 1.10", readme)
    @test occursin("Pkg.instantiate()", readme)
    @test occursin("HSQUARED_JULIA_PROJECT", readme)
    @test !occursin("Pkg.add(url=...)", readme)

    @test occursin(install, index)
    @test occursin("Julia 1.10", index)
    @test occursin("Pkg.instantiate()", index)
    @test !occursin("Pkg.add(url=...)", index)

    @test occursin(install, quickstart)
    @test !occursin("Pkg.add(url=...)", quickstart)
end
