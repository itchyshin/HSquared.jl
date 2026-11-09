# HJ1 — validation_status.jl tail: counts and container contracts.

using HSquared
using Test

@testset "validation_status_counts audited tally (HJ1)" begin
    # Pinned counts must match `tools/gen_status_json.jl` → `tools/status_cache.json`
    # (refreshed from `validation_status()` on 2026-09-04). Update this test whenever
    # `VALIDATION_STATUS_DATA` gains rows or changes status labels.
    ct = HSquared.validation_status_counts()
    @test ct.rows == 56
    @test ct.covered == 15
    @test ct.covered_external == 3
    @test ct.covered_incl_external == 18
    @test ct.partial == 37
    @test ct.planned == 1
    @test ct.covered + ct.covered_external + ct.partial + ct.planned == ct.rows

    vs = validation_status()
    @test length(vs) == ct.rows
    allowed = ("covered", "covered_external", "partial", "planned")
    @test all(row -> row.status in allowed, vs.rows)
    @test vs[1] === first(vs)
    @test collect(vs) == vs.rows
    shown = sprint(show, vs)
    @test occursin("ValidationStatus", shown)
end
