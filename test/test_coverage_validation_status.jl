# HJ1 — validation_status.jl tail: counts and container contracts.

using HSquared
using Test

@testset "validation_status_counts matches validation_status rows" begin
    vs = validation_status()
    ct = HSquared.validation_status_counts()
    @test ct.rows == length(vs)
    allowed = ("covered", "covered_external", "partial", "planned")
    tally(s) = count(row -> row.status == s, vs.rows)
    @test ct.covered == tally("covered")
    @test ct.covered_external == tally("covered_external")
    @test ct.covered_incl_external == ct.covered + ct.covered_external
    @test ct.partial == tally("partial")
    @test ct.planned == tally("planned")
    @test ct.covered + ct.covered_external + ct.partial + ct.planned == ct.rows
    @test all(row -> row.status in allowed, vs.rows)
    @test vs[1] === first(vs)
    @test collect(vs) == vs.rows
    shown = sprint(show, vs)
    @test occursin("ValidationStatus", shown)
end
