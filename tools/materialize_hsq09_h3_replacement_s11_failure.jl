#!/usr/bin/env julia
# Retain an externally observed scheduler failure without rerunning its frozen seed.

include(joinpath(@__DIR__, "..", "sim", "hsq09_h3_replacement_s11.jl"))

function _h3_s11_external_failure_main(args=ARGS)
    length(args) == 4 || error("use --cell=rg|ram --seed=INTEGER --failure-reason=TEXT --out=PATH")
    options = Dict(split(arg[3:end], "=", limit=2) for arg in args if startswith(arg, "--") && occursin('=', arg))
    length(options) == 4 && Set(keys(options)) == Set(["cell", "seed", "failure-reason", "out"]) || error("invalid options")
    seed = parse(Int, options["seed"])
    cell = options["cell"]
    path = write_h3_replacement_s11_external_failure_receipt(
        options["out"];
        cell=cell,
        seed=seed,
        failure_reason=options["failure-reason"],
    )
    println("H3_REPLACEMENT_S11_EXTERNAL_FAILURE_RETAINED cell=$(cell) seed=$(seed) path=$(path) claim_eligible=false")
end

if abspath(PROGRAM_FILE) == @__FILE__
    _h3_s11_external_failure_main()
end
