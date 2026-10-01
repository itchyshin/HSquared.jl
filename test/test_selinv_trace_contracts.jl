@testset "Selected inverse trace validates support and dimensions" begin
    C = sparse([2.0 -1.0 0.0; -1.0 2.0 -1.0; 0.0 -1.0 2.0])
    factor = cholesky(Symmetric(C); check = true)
    off_pattern = sparse([1, 3], [3, 1], [1.0, 1.0], 3, 3)

    @test_throws ArgumentError HSquared.selinv_trace_against(factor, off_pattern, 0)
    @test_throws ArgumentError HSquared.selinv_trace_against(factor, sparse(ones(2, 3)), 0)
    @test_throws ArgumentError HSquared.selinv_trace_against(factor, spzeros(3, 3), -1)

    @test_throws ArgumentError HSquared.selinv_block_traces(factor, [off_pattern], [0])
    @test_throws ArgumentError HSquared.selinv_block_traces(factor, [sparse(ones(2, 3))], [0])
    @test_throws ArgumentError HSquared.selinv_block_traces(factor, [spzeros(3, 3)], [1])
    @test_throws ArgumentError HSquared.selinv_block_traces(factor, [Matrix(C)], [0])

    diagonal_precision = sparse([1, 2, 3], [1, 2, 3], [1.0, 2.0, 3.0], 3, 3)
    expected = tr(Matrix(diagonal_precision) * inv(Matrix(C)))
    @test HSquared.selinv_trace_against(factor, diagonal_precision, 0) ≈ expected
    @test HSquared.selinv_block_traces(factor, [diagonal_precision], [0])[1] ≈ expected

    n = 6
    permuted_C = spdiagm(0 => fill(5.0, n))
    for j in 2:n
        permuted_C[1, j] = -1.0
        permuted_C[j, 1] = -1.0
    end
    permuted_factor = cholesky(Symmetric(permuted_C); check = true)
    @test permuted_factor.p != collect(1:n)
    selected = HSquared.takahashi_selinv(permuted_factor)
    dense_inverse = inv(Matrix(permuted_C))
    for j in 1:n, k in nzrange(selected, j)
        @test nonzeros(selected)[k] ≈ dense_inverse[rowvals(selected)[k], j] atol = 1e-12
    end
    # Exercise the trace routines' original-to-permuted support lookup, not
    # only selected-entry materialization, against an independent dense trace.
    permuted_precision = sparse(permuted_C)
    expected_permuted_trace = tr(Matrix(permuted_precision) * dense_inverse)
    @test HSquared.selinv_trace_against(permuted_factor, permuted_precision, 0) ≈
          expected_permuted_trace atol = 1e-12
    @test HSquared.selinv_block_traces(permuted_factor, [permuted_precision], [0])[1] ≈
          expected_permuted_trace atol = 1e-12
end

@testset "Selected inverse rejects a failed Cholesky factor" begin
    singular = sparse([1.0 1.0; 1.0 1.0])
    failed_factor = cholesky(Symmetric(singular); check = false)

    @test any(value -> !isfinite(value) || value <= 0.0, diag(sparse(failed_factor.L)))
    @test_throws ArgumentError HSquared.takahashi_diag(failed_factor)
end

@testset "Selected inverse rejects nonfinite inverse values" begin
    tiny_spd = sparse(reshape([1.0e-320], 1, 1))
    valid_factor = cholesky(Symmetric(tiny_spd); check = true)

    @test all(value -> isfinite(value) && value > 0.0, diag(sparse(valid_factor.L)))
    @test_throws ArgumentError HSquared.takahashi_diag(valid_factor)
    @test_throws ArgumentError HSquared._selinv_zvals(valid_factor; per_pair = true)
end
