# test_334_status_page_idempotent.jl — #334: docs/make.jl must not dirty
# docs/src/validation-status.md on a no-content-change rebuild.
#
# write_validation_status_table!() previously stamped a `<!-- regenerated:
# <timestamp> -->` line from `now(UTC)` on every call, so two calls one
# UTC-minute apart produced byte-different output even though the table body
# (from validation_status()) was unchanged. This pins: (1) two successive
# writes into a scratch copy of the real page are byte-identical, and (2) the
# written page contains no `regenerated:` timestamp line at all.

using HSquared
using Test

include(joinpath(@__DIR__, "..", "tools", "write_validation_status_page.jl"))

@testset "#334: validation-status page regeneration is idempotent, no timestamp" begin
    real_page = joinpath(@__DIR__, "..", "docs", "src", "validation-status.md")
    mktempdir() do dir
        scratch = joinpath(dir, "validation-status.md")
        cp(real_page, scratch)

        write_validation_status_table!(scratch)
        first_write = read(scratch, String)

        write_validation_status_table!(scratch)
        second_write = read(scratch, String)

        @test first_write == second_write
        @test !occursin("regenerated:", first_write)
        @test !occursin("regenerated:", second_write)

        # The BEGIN/END markers the A18/A25 test (test/runtests.jl) relies on
        # must survive.
        @test occursin("BEGIN GENERATED validation-status-table", first_write)
        @test occursin("END GENERATED validation-status-table", first_write)
    end
end
