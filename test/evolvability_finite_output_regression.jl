using Test,LinearAlgebra
@testset "Evolvability finite output contracts" begin
    G = Matrix{Float64}(I,2,2)
    @test_throws ArgumentError HSquared.variance_along_gradient(G,[1e200,0.0];normalize=false)
    @test_throws ArgumentError HSquared.variance_along_gradient(diagm([1e308,1e308]),[2.0,0.0];normalize=false)
    @test HSquared.variance_along_gradient(G,[3.0,4.0];normalize=false) == 25.0
    @test HSquared.variance_along_gradient([1.0 -1.0;-1.0 1.0],[1e200,1e200];normalize=false) == 0.0
    @test HSquared.evolvability(G,[1e200,0.0]) == 1.0
    @test HSquared.respondability(G,[1e200,0.0]) == 1.0
    @test HSquared.variance_along_gradient(diagm([1e308,1e308]),[1.0,0.0];normalize=false) == 1e308
end
