using Test, HSquared, LinearAlgebra, Random

@testset "G2-G6 genomic input and summary contracts" begin
    M = [0.0 1.0 2.0; 1.0 0.0 1.0; 2.0 2.0 0.0;
         0.0 2.0 1.0; 1.0 1.0 0.0; 2.0 0.0 2.0]
    y = [1.0, 2.0, 4.0, 2.0, 1.0, 3.0]
    X = ones(6, 1)
    Z = Matrix{Float64}(I, 6, 6)
    good_groups = ["a", "b", "missing"]
    precisions = loco_relationship_precisions(M, good_groups)
    scan = single_marker_scan(y, X, M)

    @testset "labels keep literal missing distinct from absent values" begin
        @test Set(keys(precisions)) == Set(good_groups)
        good_loco = loco_mixed_model_marker_scan(y, X, Z, precisions, good_groups, M, 1.0, 1.0)
        @test good_loco.marker_groups == good_groups
        @test marker_scan_table(good_loco).marker_groups == good_groups
        for absent in (missing, "", "   ", nothing)
            bad = Any["a", "b", absent]
            @test_throws ArgumentError loco_relationship_precisions(M, bad)
            @test_throws ArgumentError loco_mixed_model_marker_scan(y, X, Z, precisions, bad, M, 1.0, 1.0)
            @test_throws ArgumentError marker_scan_table(merge(scan, (marker_groups=bad,)))
            @test_throws ArgumentError HSquared._marker_scan_table(scan, bad, [1.0,2.0,3.0];total_variance=nothing)
            @test_throws ArgumentError marker_manhattan_data(scan;chromosomes=bad,positions=[1.0,2.0,3.0])
            @test_throws ArgumentError marker_scan_result_payload(merge(scan,(relationship_groups=bad,)))
            @test_throws ArgumentError HSquared._relationship_precision_lookup(Dict(absent=>Z))
        end
        @test marker_manhattan_data(scan;chromosomes=:chr1).chromosomes == fill("chr1",3)
        @test_throws ArgumentError marker_manhattan_data(scan;chromosomes="   ")
        @test_throws ArgumentError marker_region_data(scan;chromosomes=good_groups,positions=[1.0,2.0,3.0],chromosome=missing)
        @test_throws ArgumentError gwas_table(scan;trait=missing)
        @test_throws ArgumentError eqtl_table(scan;feature=missing)
        @test gwas_table(scan;trait="missing").trait == "missing"
    end

    @testset "weighted representable variance and even median" begin
        s=(marker_ids=["m"],effects=[1e200],p=[1e-200])
        reference=Float64(2*BigFloat(s.p[1])*(1-BigFloat(s.p[1]))*BigFloat(s.effects[1])^2)
        @test isfinite(reference)
        v=marker_variance_explained(s;total_variance=2.0)
        @test v.marker_variances[1] ≈ reference rtol=8eps(Float64)
        @test v.proportion_variance_explained[1] ≈ reference/2 rtol=8eps(Float64)
        ts=merge(scan,(effects=[1e200,-1e200,1e200],p=[1e-200,0.0,1.0]))
        table=marker_scan_table(ts;total_variance=2.0)
        @test table.marker_variances[1] ≈ reference rtol=8eps(Float64)
        @test table.marker_variances[2:3] == [0.0,0.0]
        @test all(isfinite,table.proportion_variance_explained)
        @test marker_variance_explained((marker_ids=["m"],effects=[-2.0],p=[0.5])).marker_variances ≈ [2.0]
        @test_throws ArgumentError marker_variance_explained((marker_ids=["m"],effects=[1e200],p=[0.5]))
        @test_throws ArgumentError marker_scan_table(merge(scan,(effects=fill(1e200,3),)))
        @test_throws ArgumentError marker_variance_explained((marker_ids=["m"],effects=[1.0],p=[0.5]);total_variance=1e-310)
        @test_throws ArgumentError marker_scan_table(scan;total_variance=1e-310)
        @test HSquared._median_float([1e308,1e308]) == 1e308
        @test HSquared._median_float([1.0,3.0]) == 2.0
        @test HSquared._median_float([3.0,1.0,2.0]) == 2.0
        @test HSquared._median_float([nextfloat(0.0),nextfloat(0.0)]) == nextfloat(0.0)
        @test marker_genomic_inflation((chisq=[1e308,1e308],);expected_median=2.0).lambda_gc == 5e307
        @test_throws ArgumentError marker_genomic_inflation((chisq=[1e308,1e308],);expected_median=0.1)
    end

    @testset "probability endpoints and original Real exceedance counts" begin
        nulls=[0.0,0.0]
        @test genome_wide_pvalue(big"1e-1000",nulls) == 1/3
        @test genome_wide_pvalue(-big"1e-1000",nulls) == 1.0
        @test genome_wide_pvalue(big"1e1000",nulls) == 1/3
        @test genome_wide_pvalue(-big"1e1000",nulls) == 1.0
        @test genome_wide_pvalue(0.0,nulls) == 1.0
        @test genome_wide_pvalue(2.0,[1.0,2.0,3.0]) == 3/4
        @test_throws ArgumentError genome_wide_pvalue(Inf,nulls)
        @test_throws ArgumentError genome_wide_pvalue(0.0,[NaN])
        @test_throws ArgumentError genome_wide_threshold_from_null([1.0,2.0];alpha=big"1e-1000")
        @test_throws ArgumentError genome_wide_threshold_from_null([1.0,2.0];alpha=BigFloat(1)-big"1e-50")
        @test_throws ArgumentError genome_wide_marker_scan(y,X,M;n_permutations=1,alpha=big"1e-1000",rng=MersenneTwister(221))
        @test_throws ArgumentError genome_wide_marker_scan(y,X,M;n_permutations=1,alpha=BigFloat(1)-big"1e-50",rng=MersenneTwister(222))
        @test genome_wide_threshold_from_null([1.0,2.0];alpha=0.5).threshold == 1.5
        @test_throws ArgumentError genome_wide_threshold_from_null([1.0,2.0];alpha=0.0)
        @test_throws ArgumentError genome_wide_threshold_from_null([1.0,2.0];alpha=1.0)
        @test_throws ArgumentError genome_wide_threshold_from_null([NaN])
    end

    @testset "unchanged supplied-frequency and single-step semantics" begin
        cm=centered_markers(M;allele_frequencies=[0.1,0.2,0.3])
        @test cm.W ≈ M .- 2 .* transpose([0.1,0.2,0.3])
        @test any(!iszero,sum(cm.W;dims=1))
        A=[1.0 0.2;0.2 1.0]; Q=inv(Symmetric(A)); rows=[2,1]
        @test single_step_inverse(Q,A,A[rows,rows],rows) ≈ Q
        @test single_step_inverse(Q,A,A[rows,rows],rows;tau=2.0) ≈ 2Q
        @test single_step_inverse(Q,A,A[rows,rows],rows;ridge=0.1) != Q
        @test HSquared._standard_normal_two_sided_pvalue(9.0) ≈ 2.257176811907681e-19 rtol=1e-12
    end
end
