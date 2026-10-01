using Test, HSquared

@testset "public genomic documentation remains attached" begin
    for name in (:genome_wide_threshold_from_null, :genome_wide_marker_scan,
                 :centered_markers, :single_step_inverse)
        @test haskey(Docs.meta(HSquared), Docs.Binding(HSquared, name))
    end
end

@testset "finite median extremes and label metadata neighbours" begin
    @test HSquared._median_float([-1e308,1e308]) == 0.0
    @test HSquared._median_float([-1e308,-1e308]) == -1e308
    @test HSquared._median_float([-nextfloat(0.0),-nextfloat(0.0)]) == -nextfloat(0.0)
    @test HSquared._median_float([nextfloat(0.0),2nextfloat(0.0)]) ==
        Float64((BigFloat(nextfloat(0.0))+BigFloat(2nextfloat(0.0)))/2)
    s=(marker_ids=["m"],p_values=[0.5])
    @test_throws ArgumentError marker_manhattan_data(s;chromosomes=missing)
    @test_throws ArgumentError marker_qq_data((marker_ids=[missing],p_values=[0.5]))
    @test_throws ArgumentError HSquared._marker_manhattan_data_from_vectors(["m"],[0.5],["a"],[1.0],1e-300,1.0;chromosome_order=[missing])
    @test marker_qq_data((marker_ids=["missing"],p_values=[0.5])).marker_ids == ["missing"]
end
