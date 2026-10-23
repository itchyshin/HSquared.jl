using Test
using HSquared

@testset "reserved formula terms describe their own scope" begin
    for (term, direct_utility) in ((:marker_scan, "mixed_model_marker_scan"),
                                   (:genomic, "fit_gblup"))
        err = try
            getproperty(HSquared, term)()
            nothing
        catch caught
            caught
        end
        @test err isa ArgumentError
        message = sprint(showerror, err)
        @test occursin("formula term", message)
        @test occursin(direct_utility, message)
        @test !occursin("no genomic prediction, marker scan", message)
    end
end
