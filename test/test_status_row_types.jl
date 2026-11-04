# Contract tests for the exported status-row types. The R twin reads these
# field names, so an accidental rename or retype must fail here loudly.
# Structure only: no prose assertions (other lanes edit status text often).

@testset "status row types: field names, types, immutability" begin
    contract = (
        BackendInfoRow => (
            (:backend, :accelerator, :requested, :selectable, :execution_available, :status, :note),
            (Symbol, Symbol, Bool, Bool, Bool, Symbol, String),
        ),
        ValidationStatusRow => (
            (:id, :capability, :phase, :status, :evidence, :missing, :claim_boundary),
            (String, String, String, String, String, String, String),
        ),
        FormulaStatusRow => (
            (:term, :category, :phase, :syntax_status, :fitting_status, :current_behavior),
            (String, String, String, String, String, String),
        ),
        HSDataIDOverlapRow => ((:metric, :count), (String, Int)),
        HSDataMarkerStatusRow => ((:metric, :value), (String, String)),
    )
    for (T, (names, types)) in contract
        @test fieldnames(T) == names
        @test fieldtypes(T) == types
        @test isstructtype(T)
        @test !ismutabletype(T)
    end
end

@testset "backend_info invariants across every backend and accelerator" begin
    gpu_backends = (:cuda, :amdgpu, :metal, :oneapi)
    for b in HSquared.BACKEND_INFO_SYMBOLS, a in HSquared.ACCELERATOR_SYMBOLS
        info = backend_info(HSControl(backend = b, accelerator = a))
        @test info isa BackendInfo
        @test info.control.backend == HSquared._coerce_backend(b)
        @test info.control.accelerator == a
        @test length(info) == length(HSquared.BACKEND_INFO_SYMBOLS)
        @test length(info.rows) == length(HSquared.BACKEND_INFO_SYMBOLS)
        @test all(row -> row isa BackendInfoRow, info.rows)
        @test [row.backend for row in info.rows] == collect(HSquared.BACKEND_INFO_SYMBOLS)
        @test all(row -> row.selectable, info.rows)
        @test all(row -> !row.execution_available, info.rows)
        @test all(row -> row.status == :planned, info.rows)
        @test all(row -> !isempty(row.note), info.rows)
        for row in info.rows
            expected = row.backend == b || row.backend == a ||
                       (a == :gpu && row.backend in gpu_backends)
            @test row.requested == expected
        end
    end

    # Default control names no backend and no accelerator.
    @test !any(row -> row.requested, backend_info().rows)

    # Rows are stable across calls and indexable.
    @test backend_info()[1] == backend_info()[1]
    @test backend_info()[1].backend == :cpu

    # show is the default struct printing; it must at least name every backend.
    shown = sprint(show, backend_info())
    @test occursin("BackendInfo", shown)
    for b in HSquared.BACKEND_INFO_SYMBOLS
        @test occursin(":$(b)", shown)
    end
end

@testset "HSControl rejects unknown backend and accelerator symbols" begin
    @test_throws ArgumentError HSControl(backend = :bogus)
    @test_throws ArgumentError HSControl(backend = "bogus")
    @test_throws ArgumentError HSControl(accelerator = :bogus)
    @test_throws ArgumentError HSControl(accelerator = "bogus")
    for b in HSquared.BACKEND_INFO_SYMBOLS
        @test_throws ArgumentError HSControl(backend = b, accelerator = :bogus)
    end
    for a in HSquared.ACCELERATOR_SYMBOLS
        @test_throws ArgumentError HSControl(backend = :bogus, accelerator = a)
    end
end

@testset "validation_status and formula_status row structure" begin
    # Status set pinned from main at the time of writing; widening it is a
    # deliberate contract change that should update this line.
    allowed = Set(["covered", "covered_external", "partial", "planned"])

    vs = validation_status()
    @test vs isa ValidationStatus
    @test length(vs) > 0
    @test all(row -> row isa ValidationStatusRow, vs.rows)
    ids = [row.id for row in vs.rows]
    @test length(unique(ids)) == length(ids)
    @test all(!isempty, ids)
    @test all(row -> !isempty(strip(row.claim_boundary)), vs.rows)
    @test all(row -> row.status in allowed, vs.rows)

    fs = formula_status()
    @test fs isa FormulaStatus
    @test length(fs) > 0
    @test all(row -> row isa FormulaStatusRow, fs.rows)
    terms = [row.term for row in fs.rows]
    @test length(unique(terms)) == length(terms)
    @test all(!isempty, terms)
end
