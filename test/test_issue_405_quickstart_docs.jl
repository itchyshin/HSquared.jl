using Test

@testset "issue 405 quick-start bridge status" begin
    root = normpath(joinpath(@__DIR__, ".."))
    quickstart = read(joinpath(root, "docs", "src", "quickstart.md"), String)
    readme = read(joinpath(root, "README.md"), String)

    @test occursin("control = hs_control(engine = \"julia\")", quickstart)
    @test occursin("This R call is executable", quickstart)
    @test occursin("`fit_ai_reml`, are implemented", quickstart)
    @test !occursin("That is not executable yet", quickstart)
    @test !occursin("AI-REML, production sparse reliability", quickstart)
    @test !occursin("honest Phase 0 placeholder", readme)
end
