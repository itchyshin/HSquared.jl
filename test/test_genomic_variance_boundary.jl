using Test, HSquared

@testset "representable weighted contributions near Float64 maximum" begin
    for (p,effect) in ((0.5,1.8961503816218352e154),(0.1,3.160250636036392e154))
        weight=2p*(1-p)
        reference=setprecision(BigFloat,256) do
            Float64(BigFloat(weight)*BigFloat(effect)^2)
        end
        @test isfinite(reference)
        summary_value=try
            marker_variance_explained((marker_ids=["m"],effects=[effect],p=[p])).marker_variances[1]
        catch err
            err
        end
        @test summary_value isa Float64 && summary_value == reference
        table_scan=(marker_ids=["m"],effects=[effect],p=[p],standard_errors=[1.0],
                    z_scores=[1.0],chisq=[1.0],p_values=[0.5],bonferroni_p_values=[0.5],
                    bh_q_values=[0.5],lod_scores=[1.0],denominators=[1.0])
        table_value=try
            marker_scan_table(table_scan).marker_variances[1]
        catch err
            err
        end
        @test table_value isa Float64 && table_value == reference
        overflow=merge(table_scan,(effects=[2effect],))
        @test_throws ArgumentError marker_variance_explained(overflow)
        @test_throws ArgumentError marker_scan_table(overflow)
    end
    @test_throws ArgumentError marker_variance_explained((marker_ids=["m"],effects=[Inf],p=[0.0]))
    @test_throws ArgumentError marker_variance_explained((marker_ids=["m"],effects=[1.0],p=[NaN]))
end

@testset "finite fast candidates cannot conceal true weighted overflow" begin
    for (p,effect) in ((0.25,2.1894858665067565e154),(0.08,3.4946515178772264e154))
        weight=2p*(1-p)
        reference=setprecision(BigFloat,256) do
            Float64(BigFloat(weight)*BigFloat(effect)^2)
        end
        @test isinf(reference)
        table_scan=(marker_ids=["m"],effects=[effect],p=[p],standard_errors=[1.0],
                    z_scores=[1.0],chisq=[1.0],p_values=[0.5],bonferroni_p_values=[0.5],
                    bh_q_values=[0.5],lod_scores=[1.0],denominators=[1.0])
        @test_throws ArgumentError marker_variance_explained(table_scan)
        @test_throws ArgumentError marker_scan_table(table_scan)
        below=prevfloat(effect)
        below_reference=setprecision(BigFloat,256) do
            Float64(BigFloat(weight)*BigFloat(below)^2)
        end
        @test isfinite(below_reference)
        below_scan=merge(table_scan,(effects=[below],))
        @test marker_variance_explained(below_scan).marker_variances[1] == below_reference
        @test marker_scan_table(below_scan).marker_variances[1] == below_reference
    end
end
