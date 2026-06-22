module ValidationDebtTracker

# Validation-debt burn-down tracker. CONSUMES the live `validation_status()` rows
# (id/capability/phase/status/evidence/missing/claim_boundary) and reports status
# counts, a per-phase breakdown, and the verbatim open-debt list. Reporting only —
# reads existing `ValidationStatusRow.status`/`.missing`; it fits nothing, runs no
# comparator, and promotes no capability. Mirrors the unexported, dependency-light
# `sim/summarize_recovery_calibration.jl` pattern (not exported from the package).

using HSquared

export status_counts, phase_status_counts, open_debts, markdown_summary

const _ORDER = ["covered", "covered_external", "partial", "planned"]

"""Counts by status in the fixed maturity order; each bucket emitted once even if zero."""
function status_counts(status = validation_status())
    counts = Dict{String,Int}()
    for row in status
        counts[row.status] = get(counts, row.status, 0) + 1
    end
    return [s => get(counts, s, 0) for s in _ORDER]
end

"""phase => status => count."""
function phase_status_counts(status = validation_status())
    out = Dict{String,Dict{String,Int}}()
    for row in status
        d = get!(out, row.phase, Dict{String,Int}())
        d[row.status] = get(d, row.status, 0) + 1
    end
    return out
end

"""Every non-covered row (covered_external included — those rows keep open `missing` debts),
in `validation_status()` order, with the `missing` text verbatim."""
function open_debts(status = validation_status())
    rows = NamedTuple{(:id, :capability, :phase, :status, :missing),
                      Tuple{String,String,String,String,String}}[]
    for row in status
        row.status == "covered" && continue
        push!(rows, (id = row.id, capability = row.capability, phase = row.phase,
                     status = row.status, missing = row.missing))
    end
    return rows
end

# sort phases as Phase 0 < Phase 1 < ... < Phase 4B < ... < non-"Phase" last, stable by text
function _phase_key(p)
    m = match(r"^Phase (\d+)", p)
    return m === nothing ? (99, 0, p) : (parse(Int, m.captures[1]),
                                         occursin(r"^Phase \d+[A-Za-z]", p) ? 1 : 0, p)
end

"""Deterministic burn-down markdown: status table, per-phase table, open-debt list."""
function markdown_summary(status = validation_status())
    lines = String["# Validation-Debt Burn-Down", ""]
    push!(lines, "| status | rows |")
    push!(lines, "| --- | ---: |")
    total = 0
    for (s, n) in status_counts(status)
        push!(lines, "| $s | $n |")
        total += n
    end
    push!(lines, "| **total** | $total |")
    push!(lines, "", "## Per phase", "")
    push!(lines, "| phase | covered | covered_external | partial | planned | total |")
    push!(lines, "| --- | ---: | ---: | ---: | ---: | ---: |")
    psc = phase_status_counts(status)
    for phase in sort(collect(keys(psc)); by = _phase_key)
        d = psc[phase]
        c = get(d, "covered", 0); ce = get(d, "covered_external", 0)
        pa = get(d, "partial", 0); pl = get(d, "planned", 0)
        push!(lines, "| $phase | $c | $ce | $pa | $pl | $(c + ce + pa + pl) |")
    end
    push!(lines, "", "## Open debts", "")
    for d in open_debts(status)
        push!(lines, "- $(d.id) ($(d.status), $(d.phase)) — $(d.capability): $(d.missing)")
    end
    return join(lines, "\n")
end

function main(args = ARGS)
    print(markdown_summary())
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    ValidationDebtTracker.main()
end
