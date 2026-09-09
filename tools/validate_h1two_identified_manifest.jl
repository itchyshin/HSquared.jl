#!/usr/bin/env julia

using TOML

const H1T_MANIFEST = joinpath(@__DIR__, "..", "docs", "dev-log", "evidence",
                              "2026-09-09-h1two-identified-s9-manifest.toml")

_h1t_assert(ok, label) = ok || error("H1-two identified manifest rejected: $(label)")

function validate_h1two_identified_manifest(data)
    fixture = data["fixture"]
    _h1t_assert(data["manifest"]["id"] == "HSQ09-H1T-IDENTIFIED-S9-01", "manifest id")
    _h1t_assert(fixture["seed"] == 20260701, "seed")
    _h1t_assert(fixture["sires"] == 20 && fixture["offspring"] == 200 && fixture["groups"] == 40,
                "geometry")
    _h1t_assert(fixture["truth_sigma1"] == 1.0 && fixture["truth_sigma2"] == 0.5 &&
                fixture["truth_sigma_e2"] == 1.0, "truth")
    _h1t_assert(fixture["level"] == 0.95 && fixture["group_assignment"] == "independent_of_pedigree",
                "scale or grouping")
    s10 = data["s10"]
    _h1t_assert(s10["requires_fit_converged"] && s10["requires_ratio1_finite_interior"] &&
                s10["requires_ratio2_finite_interior"] && !s10["claim_eligible"], "S10 contract")
    auth = data["authorizations"]
    _h1t_assert(auth["s10_compute"] && !auth["s11_campaign"] && !auth["promotion"] && !auth["release"],
                "authorization hold")
    _h1t_assert(data["supersedes"]["tiny_receipt"] == "NO-GO retained; never pooled", "tiny receipt retention")
    return nothing
end

function _expect_error(thunk)
    try
        thunk()
    catch err
        err isa ErrorException || rethrow()
        return nothing
    end
    error("H1-two manifest mutation was accepted")
end

function main(args = ARGS)
    args == ["--self-test"] || error("only --self-test is supported")
    data = TOML.parsefile(H1T_MANIFEST)
    validate_h1two_identified_manifest(data)
    for (table, key, value) in (("fixture", "seed", 1),
                                ("fixture", "groups", 39),
                                ("authorizations", "s10_compute", false),
                                ("s10", "claim_eligible", true))
        mutated = deepcopy(data)
        mutated[table][key] = value
        _expect_error(() -> validate_h1two_identified_manifest(mutated))
    end
    println("H1T_IDENTIFIED_MANIFEST_OK")
    println("H1T_IDENTIFIED_MANIFEST_MUTATIONS_OK")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
