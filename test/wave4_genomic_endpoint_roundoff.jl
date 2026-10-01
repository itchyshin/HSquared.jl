using Test, HSquared, LinearAlgebra, SparseArrays
function boundary_fixture(mode)
        # Deliberately construct strong lower/interior/upper profile targets.
        # Do not regenerate endpoint expectations from a stdlib RNG: randn's
        # seeded stream changed between Julia 1.10 and 1.12.
        values = repeat(collect(range(0.25, 4.0; length = 20)), inner = 2)
        n = length(values)
        exponent = mode == :lower ? 0.0 : mode == :interior ? 0.3 :
                   mode == :upper ? 0.75 : error("unknown boundary fixture mode")
        signs = repeat([1.0, -1.0], n ÷ 2)
        y = signs .* values .^ exponent
        K = Matrix(Diagonal(values))
        Q = Matrix(Diagonal(1 ./ values))
        ids = ["id$(i)" for i in 1:n]
        provenance = (
            relationship_source = "markers",
            relationship_method = "deterministic_test_kernel",
            allele_frequency_source = "deterministic_test",
            ridge = 0.0,
            scale_denominator = 1.0,
            relationship_scale = "K_test",
            id_order_fingerprint = HSquared._genomic_id_order_fingerprint(ids),
            marker_content_fingerprint = repeat("0", 64),
            kernel_fingerprint = HSquared._genomic_matrix_fingerprint("K_lambda", K, ids),
            precision_fingerprint = HSquared._genomic_matrix_fingerprint("Q_lambda", Q, ids),
        )
        spec = animal_model_spec(y, ones(n, 1), sparse(1.0I, n, n), Q;
                                 ids = ids, method = :REML)
        return (spec = spec, provenance = provenance, K = K)
    end
@testset "stationary endpoint likelihood comparison" begin
    f = boundary_fixture(:lower)
    pre = HSquared._genomic_boundary_precheck(f.spec, f.provenance, f.K)
    c = HSquared._genomic_profile_context(pre)
    ll0 = HSquared._genomic_profile_reml(c, 0.0).loglik
    ll1 = HSquared._genomic_profile_reml(c, 1.0).loglik
    # Independent paired-data identity: delta ll = -1/2[n log(S(r)/n) + sum(log h)].
    # No generic profile evaluator or optimizer is used by this oracle.
    function paired_gain(r, eigenvalues)
        rb = BigFloat(r)
        h = rb .* BigFloat.(eigenvalues) .+ (1 - rb)
        - (length(h) * log(sum(inv, h) / length(h)) + sum(log, h)) / 2
    end
    for r in (1e-10, 5e-9, 1e-8, 1e-7)
        @test paired_gain(r, c.eigenvalues) < 0
        ll = HSquared._genomic_profile_reml(c, r).loglik
        # Deliberately include the positive one-ULP comparison seen across platforms.
        @test HSquared._genomic_endpoint_adjacent_improves(c, r, ll, ll0, ll1) === false
        @test HSquared._genomic_endpoint_adjacent_improves(c, r, nextfloat(ll0), ll0, ll1) === false
    end
    for scale in (0.2, 0.5, 0.9, 1.0, 1.1, 1.2)
        scaled = animal_model_spec(scale .* f.spec.y, f.spec.X, f.spec.Z, f.spec.Ainv;
                                   ids=f.spec.ids, method=:REML)
        ps = HSquared._genomic_boundary_precheck(scaled, f.provenance, f.K)
        profile = HSquared._genomic_boundary_profile(scaled, ps)
        @test profile.status == "boundary_lower"
        @test profile.profile_ratio == 0.0
        fit = HSquared._fit_ai_reml_genomic_boundary(scaled;
                    provenance=f.provenance, kernel=f.K)
        @test fit.boundary.status == "boundary_lower"
        @test fit.fit.converged
        @test fit.boundary.numerical_ratio == 1e-7
    end
    # Real improvement smaller than one Float64 ULP of the absolute likelihood:
    # df=2, residual weights w1=3/4,w2=1/4, directions +1,-1/2.
    # delta ll = -log(1-r/8) + [log(1+r)+log(1-r/2)]/2.
    gain_context = (eigenvalues=[2.0, 0.5, 1.0],
        y=[sqrt(3)/2, 0.5, 0.0], X=[0.0;0.0;1.0;;], n=3,p=1)
    for r in (1e-10, 1e-16)
        lo = HSquared._genomic_profile_reml(gain_context,0.).loglik
        near = HSquared._genomic_profile_reml(gain_context,r).loglik
        @test -log1p(-BigFloat(r)/8) + (log1p(BigFloat(r))+log1p(-BigFloat(r)/2))/2 > 0
        @test HSquared._genomic_endpoint_adjacent_improves(gain_context,r,near,lo,-10.0) === true
    end
    # Reflection checks the upper endpoint through the same exact profile.
    reflected = merge(gain_context,(eigenvalues=[0.5, 2.0, 1.0],
        y=gain_context.y ./ sqrt.(gain_context.eigenvalues)))
    for r in (1-1e-10, 1-1e-16)
        hi = HSquared._genomic_profile_reml(reflected,1.).loglik
        near = HSquared._genomic_profile_reml(reflected,r).loglik
        @test HSquared._genomic_endpoint_adjacent_improves(reflected,r,near,-10.0,hi) === true
    end
    # Direct strict helper contracts remain unchanged.
    @test HSquared._genomic_endpoint_adjacent_improves(5e-8,1.5e-10,0.,-1.)
    @test HSquared._genomic_endpoint_adjacent_improves(1-5e-8,1.5e-10,-1.,0.)
    @test HSquared._genomic_endpoint_adjacent_improves(c,NaN,ll0,ll0,ll1) === true
    @test setprecision(BigFloat, 64) do
        HSquared._genomic_endpoint_adjacent_improves(c,1e-10,nextfloat(ll0),ll0,ll1) === nothing
    end
end
