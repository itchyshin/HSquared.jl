using Test, HSquared

@testset "independent probe summary controls" begin
    for samples in ([0.,0.], [1.,3.], [1e308,-1e308], [-1e308,0.,1e308],
                    [1e308,1e308], [nextfloat(0.),nextfloat(0.)],
                    [.1,.2,.3,.4])
        got_m,got_se=HSquared._matrix_free_probe_summary(samples)
        values=BigFloat.(samples); n=length(values)
        oracle_m=sum(values)/n
        oracle_se=sqrt(sum((values .- oracle_m).^2)/(n-1)/n)
        @test got_m ≈ Float64(oracle_m) atol=2eps()
        @test got_se ≈ Float64(oracle_se) atol=2eps()
    end
    m,se=HSquared._matrix_free_probe_summary([1.2])
    @test m == 1.2 && isnan(se)
    @test_throws ArgumentError HSquared._matrix_free_probe_summary(Float64[])
    @test_throws ArgumentError HSquared._matrix_free_probe_summary([Inf,1.])
    @test_throws ArgumentError HSquared._matrix_free_probe_summary([NaN,1.])
end
