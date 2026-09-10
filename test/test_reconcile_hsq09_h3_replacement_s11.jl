using Test
include(joinpath(@__DIR__, "..", "tools", "reconcile_hsq09_h3_replacement_s11.jl"))

function _h3_s11_test_write(dir; corrupt=false)
    for (i, seed) in enumerate(H3_S11_RANGES["rg"])
        ok=i <= 1800; covered=ok && i <= 1710
        values=(H3_S11_ID, seed, "r_g", .4183300132670378, .95, ok, ok,
            ok ? "" : "retained_failure", corrupt && i == 2000 ? true : covered,
            ok ? .42 : NaN, ok ? .2 : NaN, ok ? .7 : NaN, "delta", "fisher_z", false)
        open(joinpath(dir,"rep-$(seed).tsv"),"w") do io
            println(io,join(H3_S11_COLUMNS,'\t')); println(io,join(values,'\t'))
        end
    end
end

@testset "H3 S11 reconciliation" begin
    mktempdir() do dir
        _h3_s11_test_write(dir)
        result=h3_replacement_s11_reconcile(dir;cell="rg")
        @test result.requested == 2000 && result.retained == 2000
        @test result.interval_success == 1800 && result.covered == 1710
        @test result.classification == :calibrated_candidate && !result.claim_eligible
    end
    mktempdir() do dir
        _h3_s11_test_write(dir;corrupt=true)
        @test_throws ErrorException h3_replacement_s11_reconcile(dir;cell="rg")
    end
end
println("H3_REPLACEMENT_S11_RECONCILE_TESTS_OK")
