# Marker-spec / HSData / total_variance / trait paths of `qtl_table`.
# Only current behaviour is pinned; no src changes.
module QTLTableMarkerPaths
using Test, HSquared

const y = [1.0, 2.0, 4.0, 2.0, 3.0]
const X = ones(5, 1)
const M = [
    0.0 0.0
    1.0 0.0
    2.0 1.0
    0.0 2.0
    1.0 2.0
]
const scan = single_marker_scan(y, X, M; marker_ids = ["m1", "m2"])
# Map order differs from scan order on purpose.
const marker_map_data = HSData(
    (id = ["a"], y = [1.0]);
    markers = (marker = ["m2", "m1"], chr = ["1", "2"], pos = [1, 5]),
)
const marker_spec = marker_map_data.marker_spec

@testset "qtl_table marker_spec path" begin
    qtl = qtl_table(scan, marker_spec; trait = "yield")
    ref = marker_scan_table(scan, marker_spec)
    @test qtl.analysis == :qtl
    @test qtl.trait == "yield"
    @test qtl.marker_ids == ["m1", "m2"]
    @test qtl.chromosomes == ["2", "1"]
    @test qtl.positions == [5.0, 1.0]
    @test qtl.chromosomes == ref.chromosomes
    @test qtl.positions == ref.positions

    gwas = gwas_table(scan, marker_spec)
    @test gwas.analysis == :gwas
    qtl_rest = Base.structdiff(qtl, NamedTuple{(:analysis, :trait)})
    gwas_rest = Base.structdiff(gwas, NamedTuple{(:analysis,)})
    @test keys(qtl_rest) == keys(gwas_rest)
    for k in keys(gwas_rest)
        @test getproperty(qtl_rest, k) == getproperty(gwas_rest, k)
    end

    # no trait supplied: no trait field
    @test !haskey(qtl_table(scan, marker_spec), :trait)
end

@testset "qtl_table HSData path" begin
    from_spec = qtl_table(scan, marker_spec; trait = "yield", total_variance = 2.0)
    from_data = qtl_table(scan, marker_map_data; trait = "yield", total_variance = 2.0)
    @test from_data == from_spec
    @test from_data.chromosomes == ["2", "1"]
    @test_throws ArgumentError qtl_table(scan, HSData((id = ["a"], y = [1.0])))
end

@testset "qtl_table total_variance" begin
    plain = qtl_table(scan, marker_spec)
    @test plain.total_variance === nothing

    tv = qtl_table(scan, marker_spec; total_variance = 2.0)
    @test tv.total_variance == 2.0
    @test tv.proportion_variance_explained ≈ tv.marker_variances ./ 2.0 atol = 1e-12
    @test tv.marker_variances == plain.marker_variances

    # consistent with marker_variance_explained (which sorts; align by scan_indices)
    mve = marker_variance_explained(scan, marker_spec; total_variance = 2.0)
    @test mve.total_variance == 2.0
    by_scan = sortperm(mve.scan_indices)
    @test mve.proportion_variance_explained[by_scan] ≈ tv.proportion_variance_explained atol = 1e-12
    @test mve.marker_variances[by_scan] ≈ tv.marker_variances atol = 1e-12

    # one-argument form agrees too
    @test qtl_table(scan; total_variance = 2.0).proportion_variance_explained ≈
          tv.proportion_variance_explained atol = 1e-12

    for bad in (0, 0.0, -1.0, NaN, Inf, "2.0", "not numeric")
        @test_throws ArgumentError qtl_table(scan, marker_spec; total_variance = bad)
        @test_throws ArgumentError qtl_table(scan, marker_map_data; total_variance = bad)
        @test_throws ArgumentError marker_variance_explained(scan; total_variance = bad)
    end
end

@testset "qtl_table trait label" begin
    @test qtl_table(scan, marker_spec; trait = :yield).trait == "yield"
    @test qtl_table(scan, marker_spec; trait = "  yield ").trait == "yield"
    for bad in ("", "   ")
        @test_throws ArgumentError qtl_table(scan, marker_spec; trait = bad)
        @test_throws ArgumentError qtl_table(scan, marker_map_data; trait = bad)
    end
    # Numeric trait labels are currently stringified ("1", "1.5") rather than
    # rejected. The label docs say only "non-empty"; whether a number should be
    # refused is a contract question, so the expected rejection is recorded as
    # broken instead of pinning the accepted behaviour.
    rejects(f) = try
        f()
        false
    catch err
        err isa ArgumentError
    end
    for bad in (1, 1.5)
        @test_broken rejects(() -> qtl_table(scan, marker_spec; trait = bad))
        @test_broken rejects(() -> qtl_table(scan, marker_map_data; trait = bad))
    end
end

@testset "qtl_table marker id mismatch" begin
    # map has more entries than the scan
    more_map = HSData(
        (id = ["a"], y = [1.0]);
        markers = (marker = ["m1", "m2", "m3"], chr = ["1", "1", "2"], pos = [1, 2, 3]),
    )
    @test_throws ArgumentError qtl_table(scan, more_map.marker_spec)
    @test_throws ArgumentError qtl_table(scan, more_map)
    # scan has more ids than the map
    short_map = HSData(
        (id = ["a"], y = [1.0]);
        markers = (marker = ["m1"], chr = ["1"], pos = [1]),
    )
    @test_throws ArgumentError qtl_table(scan, short_map.marker_spec)
    # same size, unmatched id
    other_map = HSData(
        (id = ["a"], y = [1.0]);
        markers = (marker = ["m1", "mX"], chr = ["1", "1"], pos = [1, 2]),
    )
    @test_throws ArgumentError qtl_table(scan, other_map.marker_spec)
    @test_throws ArgumentError qtl_table(scan, other_map)
    # duplicate scan ids
    dup_scan = merge(scan, (marker_ids = ["m1", "m1"],))
    @test_throws ArgumentError qtl_table(dup_scan, marker_spec)
end
end
