using Test, LinearAlgebra, SparseArrays
@testset "Selected-inverse trace finite contracts" begin
    f = cholesky(Symmetric(sparse(reshape([1.0],1,1)));check=true)
    for bad in [NaN,Inf,-Inf]
        q = sparse(reshape([bad],1,1))
        @test_throws ArgumentError HSquared.selinv_trace_against(f,q,0)
        @test_throws ArgumentError HSquared.selinv_block_traces(f,[q],[0])
    end
    huge = sparse(reshape([big"1e400"],1,1))
    @test_throws ArgumentError HSquared.selinv_trace_against(f,huge,0)
    @test_throws ArgumentError HSquared.selinv_block_traces(f,[huge],[0])
    tiny = cholesky(Symmetric(sparse(reshape([1e-200],1,1)));check=true)
    largeq = sparse(reshape([1e200],1,1))
    @test_throws ArgumentError HSquared.selinv_trace_against(tiny,largeq,0)
    @test_throws ArgumentError HSquared.selinv_block_traces(tiny,[largeq],[0])
    double = cholesky(Symmetric(spdiagm(0=>ones(2)));check=true)
    overflow = spdiagm(0=>fill(floatmax(Float64),2))
    @test_throws ArgumentError HSquared.selinv_trace_against(double,overflow,0)
    @test_throws ArgumentError HSquared.selinv_block_traces(double,[overflow],[0])
    for q in [spdiagm(0=>[0.0,0.0]),spdiagm(0=>[2.0,3.0]),spdiagm(0=>[-2.0,3.0])]
        expected = sum(diag(Matrix(q)))
        @test HSquared.selinv_trace_against(double,q,0) == expected
        @test HSquared.selinv_block_traces(double,[q],[0]) == [expected]
    end
    @test HSquared.selinv_block_traces(double,SparseMatrixCSC[],Int[]) == Float64[]
    # Original nonzero BigFloat weights must not disappear during conversion.
    for w in (big"1e-400",-big"1e-400")
        outside = sparse([1],[2],[w],2,2)
        @test_throws ArgumentError HSquared.selinv_trace_against(double,outside,0)
        @test_throws ArgumentError HSquared.selinv_block_traces(double,[outside],[0])
        within = sparse(reshape([w],1,1))
        @test_throws ArgumentError HSquared.selinv_trace_against(tiny,within,0)
        @test_throws ArgumentError HSquared.selinv_block_traces(tiny,[within],[0])
    end
    smallest = sparse(reshape([nextfloat(0.0)],1,1))
    @test HSquared.selinv_trace_against(tiny,smallest,0) > 0
    @test HSquared.selinv_block_traces(tiny,[smallest],[0])[1] > 0

end
