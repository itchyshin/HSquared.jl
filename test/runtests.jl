using HSquared
using Test

@testset "HSquared Phase 0 scaffold" begin
    control = HSControl()

    @test control.backend isa AutoBackend
    @test control.accelerator == :auto
    @test control.precision === Float64
    @test control.save == :minimal
    @test control.save_fitted == false
    @test control.save_residuals == false
    @test control.save_design == false
    @test control.save_factorization == false
    @test control.disk_cache == false

    @test HSControl(backend = :cpu).backend isa CPUBackend
    @test HSControl(backend = "cuda", accelerator = "cuda", precision = Float32, save = "tiny").backend isa CUDABackend

    @test_throws ArgumentError HSControl(backend = :bogus)
    @test_throws ArgumentError HSControl(accelerator = :metal)
    @test_throws ArgumentError HSControl(precision = Float16)
    @test_throws ArgumentError HSControl(save = :everything)

    @test_throws Phase0NotImplementedError hsquared(nothing)
    @test_throws Phase0NotImplementedError fit_animal_model(nothing)
end
