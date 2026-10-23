using Test, LinearAlgebra, SparseArrays, HSquared

function coefcov_test_payload(; basis="legendre", bounds=[10.0, 30.0])
    block = Dict{String,Any}(
        "name"=>"reaction", "type"=>"coefcov", "Z"=>sparse([1.0 0; 0 1; 1 0]),
        "relmat_status"=>"identity", "ids"=>["a", "b"],
        "basis"=>basis, "order"=>2, "Phi"=>[1.0 -1; 1 0; 1 1],
        "covariate"=>"age", "covariate_bounds"=>bounds,
        "cov_structure"=>"unstructured")
    Dict{String,Any}("payload_version"=>2, "y"=>[1.0, 2.0, 3.0],
                    "X"=>ones(3,1), "random_effects"=>[block])
end

coefcov_malformed = Pair{String,Function}[]
for field in ("basis", "order", "Phi", "covariate", "cov_structure")
    push!(coefcov_malformed, "missing $field" => (p -> delete!(p["random_effects"][1], field)))
end
for (field, value) in (
    ("basis", "spline"), ("basis", :legendre), ("order", true),
    ("order", 0), ("order", -1), ("order", 2.0), ("order", "2"),
    ("Phi", ones(2,2)), ("Phi", ones(3,3)), ("Phi", [1., 2., 3.]),
    ("Phi", [1.0 NaN; 1 0; 1 1]), ("Phi", [1.0 Inf; 1 0; 1 1]),
    ("Phi", ["1" "0"; "1" "0"; "1" "0"]),
    ("Phi", ones(ComplexF64,3,2)), ("Phi", sparse(ones(3,2))),
    ("Phi", [big"1e1000" big"0"; big"1" big"0"; big"1" big"0"]),
    ("covariate", " "), ("covariate", 7),
    ("covariate_bounds", nothing), ("covariate_bounds", [0., 0.]),
    ("covariate_bounds", [30., 10.]), ("covariate_bounds", [10., Inf]),
    ("covariate_bounds", [10.]), ("covariate_bounds", [true, false]),
    ("covariate_bounds", ["10", "30"]),
    ("cov_structure", "full"), ("cov_structure", :diagonal))
    label = "$field = $(repr(value))"
    push!(coefcov_malformed, label => (p -> p["random_effects"][1][field] = value))
end

@testset "coefcov parser contract" begin
@testset "coefcov preserves metadata and frozen fit boundary" begin
    p = coefcov_test_payload()
    parsed = HSquared.parse_payload_v2(p)
    @test parsed.dispatch == :coefcov
    b = parsed.blocks[1]
    for field in (:basis, :order, :Phi, :covariate, :covariate_bounds, :cov_structure)
        @test hasproperty(b, field)
        hasproperty(b, field) && @test getproperty(b,field) == p["random_effects"][1][string(field)]
    end
    @test_throws HSquared.Phase0NotImplementedError HSquared.fit_payload_v2(p)
    raw = HSquared.parse_payload_v2(coefcov_test_payload(basis="raw",bounds=nothing))
    @test raw.dispatch == :coefcov
    hasproperty(raw.blocks[1], :covariate_bounds) && @test raw.blocks[1].covariate_bounds === nothing
    diagonal = coefcov_test_payload()
    diagonal["random_effects"][1]["cov_structure"] = "diagonal"
    @test HSquared.parse_payload_v2(diagonal).dispatch == :coefcov
    # Symbol-key Dict and NamedTuple forms share the same field contract.
    sym = Dict(Symbol(k)=>v for (k,v) in p)
    sym[:random_effects] = [Dict(Symbol(k)=>v for (k,v) in p["random_effects"][1])]
    @test HSquared.parse_payload_v2(sym).dispatch == :coefcov
    nt = (; (Symbol(k)=>v for (k,v) in p)...)
    nt = merge(nt, (random_effects=[(; (Symbol(k)=>v for (k,v) in p["random_effects"][1])...)],))
    @test HSquared.parse_payload_v2(nt).dispatch == :coefcov
end

@testset "coefcov rejects malformed coefficient fields" begin
    for (label, mutate!) in coefcov_malformed
        @testset "$label" begin
            p = coefcov_test_payload(); mutate!(p)
            @test_throws ArgumentError HSquared.parse_payload_v2(p)
        end
    end
end

@testset "ordinary independent-block parsing remains valid" begin
    p = coefcov_test_payload()
    first = p["random_effects"][1]
    first["type"] = "pedigree"; first["relmat_status"] = "supplied"
    first["relmat_inverse"] = sparse(I,2,2)
    @test HSquared.parse_payload_v2(p).dispatch == :animal
    second = Dict{String,Any}("name"=>"group", "type"=>"iid",
        "Z"=>first["Z"], "ids"=>["c", "d"], "relmat_status"=>"identity")
    push!(p["random_effects"], second)
    @test HSquared.parse_payload_v2(p).dispatch == :two_effect
end

@testset "coefcov rejects sparse wrappers before conversion" begin
    for Phi in (transpose(sparse([1.0 1 1; -1 0 1])),
                adjoint(sparse([1.0 1 1; -1 0 1])),
                view(sparse([1.0 -1 9; 1 0 9; 1 1 9; 9 9 9]), 1:3, 1:2))
        @test issparse(Phi)
        p = coefcov_test_payload()
        p["random_effects"][1]["Phi"] = Phi
        @test_throws ArgumentError HSquared.parse_payload_v2(p)
    end
end

@testset "coefcov accepts dense transpose, adjoint, and view controls" begin
    for Phi in (transpose([1.0 1 1; -1 0 1]),
                adjoint([1.0 1 1; -1 0 1]),
                view([1.0 -1 9; 1 0 9; 1 1 9; 9 9 9], 1:3, 1:2))
        @test !issparse(Phi)
        p = coefcov_test_payload()
        p["random_effects"][1]["Phi"] = Phi
        parsed = HSquared.parse_payload_v2(p)
        @test parsed.dispatch == :coefcov
        @test hasproperty(parsed.blocks[1], :Phi)
        if hasproperty(parsed.blocks[1], :Phi)
            @test parsed.blocks[1].Phi == Matrix(Phi)
            @test parsed.blocks[1].Phi isa Matrix{Float64}
        end
    end
end
end
