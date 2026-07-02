#!/usr/bin/env julia
# Generate the mission-control status.json from MACHINE STATE (git/gh + a cached
# validation_status() count) — never hand-typed (kills the count-drift risk R1/R2/R3).
#
# Dual-tool: by default reads the validation count from tools/status_cache.json so it
# runs WITHOUT loading HSquared (Claude, no live Julia). Pass --refresh-count to
# recompute the count live (Codex / anyone with the instantiated project) and rewrite
# the cache. Everything else (branch/head/CI/open PRs) is always derived live.
#
# Usage:
#   julia tools/gen_status_json.jl [--current-slice="..."] [--next="..."]
#         [--drac-cluster=fir --drac-job=123 --drac-state=RUNNING --drac-seeds=10/200]
#         [--deploy-dir=~/.claude/hsquared-control-centre]
#   julia --project=. tools/gen_status_json.jl --refresh-count   # recompute the cache live
#
# Honesty: public_covered_count is hard-pinned to 5 — (1) the v0.1 univariate Gaussian
# animal model (default `engine="fit"` path), (2) the opt-in common-environment
# two-effect model (`engine="julia", target="two_effect"`; c² covered, maternal leg
# still experimental), (3) the opt-in arbitrary-N independent random-effect model
# (`(1|g)`; `engine="julia", target="multi_effect"`; animal ratio covered, INDEPENDENT
# effects only, intervals asymptotic/uncalibrated), (4) the opt-in random-regression
# k=2 reaction-norm model (`rr()`; target="random_regression"; K_g + h²(t) curve,
# POINT-ESTIMATE, NOT k≥3/not (x|g)/not non-Gaussian), and (5) the opt-in direct–maternal
# correlated 2×2 G animal model (`maternal_genetic()`; target="direct_maternal"; Willham
# total-h² labelled triple, direct h² ≠ total h², validation-scale/dense n≤1000, NOT the
# default). The covered/partial/planned split is generated, never quoted in prose.

using Dates

jesc(s) = replace(string(s), "\\" => "\\\\", "\"" => "\\\"", "\n" => " ", "\r" => " ", "\t" => " ")
function trycmd(cmd)
    try
        return strip(read(cmd, String))
    catch
        return ""
    end
end
argval(flag, default="") = begin
    i = findfirst(a -> startswith(a, flag * "="), ARGS)
    i === nothing ? default : split(ARGS[i], "=", limit=2)[2]
end
hasflag(flag) = any(a -> a == flag, ARGS)

root = trycmd(`git rev-parse --show-toplevel`)
isempty(root) && (root = pwd())
cachepath = joinpath(root, "tools", "status_cache.json")

# --- validation count: refresh live, or read the cache -----------------------------
if hasflag("--refresh-count")
    @eval using HSquared
    rows = Base.invokelatest(HSquared.validation_status)
    d = Dict{String,Int}()
    for r in rows
        s = string(getproperty(r, :status))
        d[s] = get(d, s, 0) + 1
    end
    open(cachepath, "w") do io
        print(io, """{
  "rows": $(length(rows)),
  "covered": $(get(d,"covered",0)),
  "covered_external": $(get(d,"covered_external",0)),
  "partial": $(get(d,"partial",0)),
  "planned": $(get(d,"planned",0)),
  "public_covered_count": 5,
  "refreshed_at": "$(Dates.format(now(), "yyyy-mm-dd"))",
  "refreshed_from_head": "$(trycmd(`git -C $root log -1 --format=%h`))",
  "note": "Machine-refreshable validation_status() count cache. Refresh: julia --project=. tools/gen_status_json.jl --refresh-count."
}
""")
    end
    println("refreshed cache: ", cachepath)
end

cache = isfile(cachepath) ? read(cachepath, String) : ""
cnt(key) = (m = match(Regex("\"$key\"\\s*:\\s*(\\d+)"), cache); m === nothing ? -1 : parse(Int, m.captures[1]))
rows, cov, covx, part, plan = cnt("rows"), cnt("covered"), cnt("covered_external"), cnt("partial"), cnt("planned")
refreshed = (m = match(r"\"refreshed_at\"\s*:\s*\"([^\"]*)\"", cache); m === nothing ? "?" : m.captures[1])

# --- live git/gh facts for both repos ----------------------------------------------
sib = joinpath(dirname(root), "hsquared")
function repofacts(dir, ghslug)
    b = trycmd(`git -C $dir rev-parse --abbrev-ref HEAD`)
    h = "$(trycmd(`git -C $dir log -1 --format=%h`)) $(trycmd(`git -C $dir log -1 --format=%s`))"
    cijq = ".[0].conclusion"
    ci = trycmd(`gh run list -R $ghslug --branch $b --limit 1 --json conclusion --jq $cijq`)
    return (b, h, isempty(ci) ? "unknown" : ci)
end
jb, jh, jci = repofacts(root, "itchyshin/HSquared.jl")
rb, rh, rci = isdir(sib) ? repofacts(sib, "itchyshin/hsquared") : ("?", "(sibling hsquared not found)", "unknown")

prsjq = "[.[]|{num:.number,title:.title,branch:.headRefName}]"
prs = trycmd(`gh pr list -R itchyshin/HSquared.jl --state open --json number,title,headRefName --jq $prsjq`)
isempty(prs) && (prs = "[]")

slice = argval("--current-slice", "—")
nextact = argval("--next", "—")
drac_cluster = argval("--drac-cluster", "")
drac_job = argval("--drac-job", "")
drac_state = argval("--drac-state", "none")
drac_seeds = argval("--drac-seeds", "")
dracjob_json = isempty(drac_job) ? "null" : "\"$(jesc(drac_job))\""
dracseeds_json = isempty(drac_seeds) ? "null" : "\"$(jesc(drac_seeds))\""
dracclu_json = isempty(drac_cluster) ? "null" : "\"$(jesc(drac_cluster))\""

genat = Dates.format(now(), "yyyy-mm-ddTHH:MM:SS")
status = """{
  "generated_at": "$genat",
  "generator_version": "tools/gen_status_json.jl @ $(trycmd(`git -C $root log -1 --format=%h`))",
  "public_covered_count": 5,
  "honesty_assert": "Public-covered FITTING surface = 5: (1) v0.1 univariate Gaussian animal model (default path); (2) the opt-in common-environment two-effect model (engine=julia, target=two_effect; c² covered, maternal leg experimental); (3) the opt-in arbitrary-N independent random-effect model ((1|g); target=multi_effect; animal ratio = narrow-sense h², other blocks are variance-explained proportions NOT heritabilities; INDEPENDENT effects only, NOT correlated/RR/non-Gaussian); (4) the opt-in random-regression k=2 reaction-norm model (rr(); target=random_regression; K_g + h²(t) curve, POINT-ESTIMATE, NOT k≥3/not (x|g)/not non-Gaussian); and (5) direct–maternal correlated 2×2 G animal model (maternal_genetic(); target=direct_maternal; opt-in; Willham total-h² labelled triple, direct h² ≠ total h², validation-scale/dense n≤1000, single relationship A, NOT the default). All intervals asymptotic/delta-method, NOT coverage-calibrated. Everything else is experimental / partial / planned. Counts below are generated from validation_status(), never hand-typed.",
  "validation": {"rows": $rows, "covered": $cov, "covered_external": $covx, "partial": $part, "planned": $plan, "source": "cache", "refreshed_at": "$refreshed"},
  "repos": [
    {"name": "HSquared.jl", "branch": "$(jesc(jb))", "head": "$(jesc(jh))", "ci": "$(jesc(jci))"},
    {"name": "hsquared", "branch": "$(jesc(rb))", "head": "$(jesc(rh))", "ci": "$(jesc(rci))"}
  ],
  "open_prs": $prs,
  "current_slice": "$(jesc(slice))",
  "drac": {"cluster": $dracclu_json, "job_id": $dracjob_json, "state": "$(jesc(drac_state))", "seeds_done": $dracseeds_json},
  "blockers": [],
  "next_safe_action": "$(jesc(nextact))",
  "foreign_never_stage": [
    "docs/dev-log/recovery-checkpoints/2026-06-22-r-twin-nongaussian-per-record-trials-spec.md",
    "sim/phase6_nongaussian_interval_coverage.tsv"
  ]
}
"""

# --- deploy: status.json + bumped version.txt + the board html ---------------------
deploy = expanduser(argval("--deploy-dir", "~/.claude/hsquared-control-centre"))
mkpath(deploy)
write(joinpath(deploy, "status.json"), status)
write(joinpath(deploy, "version.txt"), Dates.format(now(), "yyyymmddHHMMSS"))
board = joinpath(root, "tools", "control-centre", "index.html")
isfile(board) && cp(board, joinpath(deploy, "index.html"); force=true)

println("wrote ", joinpath(deploy, "status.json"), "  (rows=$rows covered=$cov, public_covered=5)")
