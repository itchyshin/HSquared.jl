# Write the known-truth fixture used by test/test_issue_352_pe_recovery.jl.
#
#   julia +1.10 --project=. test/fixtures/issue_352_pe_recovery/generate.jl
#
# Truth: Va = 1.0, Vpe = 0.6, Ve = 0.8, intercept 2.0.
# Design: 100 founders + 200 offspring (random sire and dam drawn from the
# founders, so relationship contrast exists), 3 records per animal (900 rows).
# Breeding values are gene-dropped: a_k = (a_sire + a_dam) / 2 + N(0, Va / 2).
# Drawing them i.i.d. would give A = I and a degenerate, non-identified fixture.
#
# Julia 1.13 changed randn() and MersenneTwister(Int) uniforms, so a live seed
# is not a pin; the test reads these CSVs instead. Regenerate only on Julia 1.10.

using Random

function _write_fixture()
    VERSION.major == 1 && VERSION.minor == 10 ||
        error("regenerate only on Julia 1.10; this Julia is ", VERSION)
    Va, Vpe, Ve = 1.0, 0.6, 0.8
    nf, no, reps = 100, 200, 3
    nan = nf + no
    rng = Random.MersenneTwister(20261026)
    sire = zeros(Int, nan)
    dam = zeros(Int, nan)
    for k in (nf + 1):nan
        sire[k] = rand(rng, 1:nf)
        dam[k] = rand(rng, 1:nf)
        while dam[k] == sire[k]
            dam[k] = rand(rng, 1:nf)
        end
    end
    a = zeros(nan)
    a[1:nf] = randn(rng, nf) .* sqrt(Va)
    for k in (nf + 1):nan
        a[k] = 0.5 * (a[sire[k]] + a[dam[k]]) + randn(rng) * sqrt(Va / 2)
    end
    pe = randn(rng, nan) .* sqrt(Vpe)
    open(joinpath(@__DIR__, "pedigree.csv"), "w") do io
        println(io, "id,sire,dam")
        for k in 1:nan
            println(io, k, ",", sire[k], ",", dam[k])
        end
    end
    open(joinpath(@__DIR__, "y.csv"), "w") do io
        println(io, "animal,y")
        for _rep in 1:reps, k in 1:nan
            println(io, k, ",", 2.0 + a[k] + pe[k] + randn(rng) * sqrt(Ve))
        end
    end
    println("wrote fixture in ", @__DIR__)
end

_write_fixture()
