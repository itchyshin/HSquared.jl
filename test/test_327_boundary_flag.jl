using Test
using HSquared
using LinearAlgebra

# Deterministic half-sib pedigree: `nsire` unrelated sires (ids 1:nsire), `nsire`
# unrelated dams (ids nsire+1:2nsire), then `noff` offspring cycling through the
# sire/dam pairs. Founders get ids 1:2nsire, offspring 2nsire+1:2nsire+noff.
function _b327_pedigree(nsire::Int, noff::Int)
    nf = 2 * nsire
    n = nf + noff
    ids = collect(1:n)
    sire = zeros(Int, n)
    dam = zeros(Int, n)
    for k in 1:noff
        i = nf + k
        fam = ((k - 1) % nsire) + 1
        sire[i] = fam
        dam[i] = nsire + fam
    end
    ped = HSquared.normalize_pedigree(ids, sire, dam)
    Ainv = HSquared.pedigree_inverse(ped)
    Z = Matrix{Float64}(I, n, n)
    X = ones(n, 1)
    return (ped = ped, Ainv = Ainv, Z = Z, X = X, n = n, nsire = nsire)
end

@testset "#327 boundary flag: honest search-bound reporting" begin
    @testset "(a) null-DGP Poisson (~200 animals) hits the lower bound" begin
        f = _b327_pedigree(10, 180)   # 20 founders + 180 offspring = 200
        y = fill(4.0, f.n)            # constant response -> zero genetic signal
        fit = HSquared.fit_laplace_reml(y, f.X, f.Z, f.Ainv; family = :poisson,
                                        initial = (sigma_a2 = 1.0,), ids = f.ped.ids)
        @test fit.boundary == true
        err = try
            HSquared.nongaussian_three_field_payload(fit)
            nothing
        catch e
            e
        end
        @test err isa ArgumentError
        @test occursin("boundary", err.msg)
        # #347: the message must name the actual lever (`initial`, which recentres the
        # log-scale search bracket) and must not suggest `restart_check = true` can clear
        # an already-flagged boundary -- it only makes the check stricter (never a rescue).
        @test occursin("initial", err.msg)
        @test occursin("restart_check", err.msg)
        @test occursin("cannot clear", err.msg)
    end

    @testset "(b) informative Poisson DGP (~300 animals) stays interior" begin
        f = _b327_pedigree(15, 270)   # 30 founders + 270 offspring = 300
        y = zeros(f.n)
        for k in 1:f.n
            if k <= 2 * f.nsire
                fam = k <= f.nsire ? k : k - f.nsire
            else
                fam = ((k - 2 * f.nsire - 1) % f.nsire) + 1
            end
            y[k] = 2.0 * fam + 8.0 + (k % 2)
        end
        fit = HSquared.fit_laplace_reml(y, f.X, f.Z, f.Ainv; family = :poisson,
                                        initial = (sigma_a2 = 1.0,), ids = f.ped.ids)
        @test fit.boundary == false
        tf = HSquared.nongaussian_three_field_payload(fit)
        @test tf.schema == "nongaussian_three_field_v09"
    end

    @testset "(c) restart_check performs exactly one extra fit, no recursion" begin
        f = _b327_pedigree(10, 180)
        y = fill(4.0, f.n)
        fit = HSquared.fit_laplace_reml(y, f.X, f.Z, f.Ainv; family = :poisson,
                                        initial = (sigma_a2 = 1.0,), ids = f.ped.ids,
                                        restart_check = true)
        @test fit.boundary == true
        @test fit.restart_estimate !== nothing
        # The restart is exactly one plain refit from the bumped start (no recursion):
        # its `restart_estimate` must equal a manual refit from the same bumped start.
        fit2 = HSquared.fit_laplace_reml(y, f.X, f.Z, f.Ainv; family = :poisson,
                                         initial = (sigma_a2 = 1.0 * exp(3.0),), ids = f.ped.ids)
        @test fit.restart_estimate == fit2.variance_components.sigma_a2
    end

    @testset "(d) :gamma rail hit -> boundary" begin
        X = ones(3, 1); Z = Matrix(1.0I, 3, 3); Ainv = Matrix(1.0I, 3, 3)
        y = [1.0, 1.0, 1.0]     # constant, strictly positive, uninformative
        fit = HSquared.fit_laplace_reml(y, X, Z, Ainv; family = :gamma)
        @test fit.boundary == true
    end

    @testset "(e) :nbinom uninformative case -> boundary" begin
        X = ones(3, 1); Z = Matrix(1.0I, 3, 3); Ainv = Matrix(1.0I, 3, 3)
        y = [1.0, 1.0, 1.0]
        fit = HSquared.fit_laplace_reml(y, X, Z, Ainv; family = :nbinom)
        @test fit.boundary == true
    end
end
