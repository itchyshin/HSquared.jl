using Test
using HSquared

# #345: the legacy 11-field payload cannot carry `boundary`, so a boundary fit must not
# report converged = true to the R bridge.
_fit345(; converged::Bool = true, boundary::Bool = false) =
    HSquared.NonGaussianFit(
        (sigma_a2 = 0.4,), -12.5, [0.3], [0.0, 0.0], ["a", "b"], converged,
        :poisson, :laplace, nothing, nothing, boundary, nothing,
    )

@testset "#345 legacy nongaussian_result_payload converged excludes boundary" begin
    @test HSquared.nongaussian_result_payload(_fit345(boundary = true)).converged === false
    @test HSquared.nongaussian_result_payload(_fit345()).converged === true
    @test HSquared.nongaussian_result_payload(_fit345(converged = false)).converged === false
    @test length(propertynames(HSquared.nongaussian_result_payload(_fit345(boundary = true)))) == 11
end
