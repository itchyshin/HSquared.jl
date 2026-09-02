#!/usr/bin/env julia
# ============================================================================
# S6 -- ASReml-R comparator: at-scale estimand leg (E) + wall-clock ladder (W).
#
# STATUS: SKELETON. FROZEN-NOT-RUN. NOT AUTHORISED.
#
# This file freezes the grid, the seeds, the caps, and the toolchain assertions
# declared in:
#   docs/dev-log/recovery-checkpoints/2026-09-02-s6-asreml-wallclock-ladder-predeclaration.md
# It does NOT implement the campaign. The run path deliberately raises rather
# than fitting anything, so this script cannot produce a number by accident.
#
# It promotes NOTHING. `public_covered_count` stays 5. `V1-MATFREE-REML` stays
# experimental. No fence in section 8 of the pre-declaration is lifted by this
# file existing.
#
# PREREQUISITES (pre-declaration section 1):
#   P1  licensed ASReml-R on a drivable host -- OPEN, OWNER action (arc A33).
#   P2  ASReml scaffold + high-fill generator -- DISCHARGED by provenance port
#       (2026-09-02): comparator/prepare_asreml_matfree.jl,
#       comparator/run_asreml_matfree.R, sim/drac/f0_adversarial_fill.jl from
#       foreign tip 853bcc12 (introducing 29d04a1d / 533cf0f8). Foreign lane
#       was READ ONLY. Ported, NOT RUN.
#   P3  `fit_eigen_reml` is ABSENT from src/ on this branch -- the eigen arm is
#       OPTIONAL and is reported ABSENT, never silently dropped. (Unchanged.)
#
# TWO LEGS, TWO VERDICTS, NEVER MERGED:
#   Leg E -- estimand agreement in the high-fill tail. Closes debt item (2) at
#            the tested cells. Gated on component agreement.
#   Leg W -- wall-clock ladder. Closes NO debt. Gated SEPARATELY, and gated
#            AFTER agreement: a cell that fails agreement yields NO timing
#            number -- not a slower one, none.
#
# USAGE
#   HSQ_S6_DRYRUN=1 julia --project=. sim/phase_s6_asreml_wallclock_ladder.jl
#       Prints the frozen plan and exits 0. Draws no data, performs no fit.
#
#   julia --project=. sim/phase_s6_asreml_wallclock_ladder.jl <out.tsv>
#       Refuses to run: ASReml prerequisite check first, then an explicit
#       NOT-IMPLEMENTED stop. There is no path through this file that fits.
# ============================================================================

using Printf

const PREDECLARATION =
    "docs/dev-log/recovery-checkpoints/2026-09-02-s6-asreml-wallclock-ladder-predeclaration.md"

# ---------------------------------------------------------------------------
# Frozen grid (pre-declaration section 3). Cheapest-first run order, so a
# licence/install/harness defect surfaces on a 1-second cell, not after hours.
# ---------------------------------------------------------------------------
struct Cell
    id::String
    class::Symbol            # :lowfill_sparse | :highfill_matfree | :real_field
    q::Int                   # -1 = as observed (real pedigree)
    target_fill::String
    r_warmup::Int
    r_timed::Int
    note::String
end

const GRID = Cell[
    Cell("C1", :highfill_matfree,   2_000, "~75",       1, 5,
         "the 2026-07-28 ASReml leg's own cell -- anchors this run to that one"),
    Cell("C2", :highfill_matfree,   5_000, "~150",      1, 5,
         "the measured crossover band itself"),
    Cell("L1", :lowfill_sparse,    50_000, "~17-19",    1, 5,
         "low-fill half-sib: the win hypothesis at moderate scale"),
    Cell("T1", :highfill_matfree,  10_000, "~262",      1, 5,
         "tail; the exact path walls on selinv here"),
    Cell("L2", :lowfill_sparse,   300_000, "~17-19",    1, 3,
         "scale end of the win hypothesis (2.30 s internal, Totoro)"),
    Cell("T2", :highfill_matfree,  25_000, "~583",      1, 3,
         "the S5 gate's own scale -- recovery and comparator evidence meet"),
    Cell("R1", :real_field,            -1, "as observed", 1, 3,
         "CONDITIONAL: one non-synthetic cell. No pedigree => NOT RUN, said out loud"),
]

# ---------------------------------------------------------------------------
# Frozen truth, starts, seeds, tolerances, caps (pre-declaration sections 4-6).
# ---------------------------------------------------------------------------
const TRUTH = (mu = 5.0, sigma_a2 = 1.0, sigma_e2 = 1.0)   # h2 = 0.5, interior
const START = (sigma_a2 = 0.8, sigma_e2 = 0.8)             # deliberately off truth
const NPROBE = 64                                          # the UNTUNED default

const SEEDS_E_DGP = 20269600:20269631      # 8 per tail cell (C1, C2, T1, T2)
const SEEDS_W_DGP = 20269700:20269706      # one per grid cell, in GRID order
const MC_SEED_OFFSET = 500_000             # MC-probe seed = DGP seed + offset

const AGREE_TOL_EXACT = 1e-5      # ASReml vs fit_ai_reml: MAX rel.diff over seeds
const AGREE_TOL_MC = 0.05         # ASReml vs fit_matrix_free_reml: MEAN |rel.diff|

const CAP_FIT_SECONDS = 7_200         # single fit, any program -> CAP_EXCEEDED
const CAP_ITERATIONS = 200            # function default, kept, NOT raised
const CAP_CELL_SECONDS = 28_800       # all arms in one cell
const CAP_CAMPAIGN_SECONDS = 172_800  # whole ladder, per host

# ---------------------------------------------------------------------------
# Prerequisite: ASReml. Absent => stop with a message that names what is missing.
# There is deliberately no HSquared-only fallback: a ladder with no ASReml arm
# would look like a ladder and would not be one.
# ---------------------------------------------------------------------------
function require_asreml()
    cmd = get(ENV, "HSQ_S6_ASREML_CMD", "")
    if isempty(cmd)
        error("""
        S6 STOP -- ASReml-R prerequisite not satisfied. NOTHING WAS RUN.

        HSQ_S6_ASREML_CMD is unset, so no licensed ASReml-R invocation is
        available. This gate is LICENCE-GATED BEFORE IT IS COMPUTE-GATED: both
        legs compare against ASReml-R, and neither means anything without it.

        A NO here is a legitimate outcome. It parks the wall-clock ladder; it
        does not invalidate the frozen design, and it must not be worked around
        by running the HSquared fitters alone and calling the result a ladder.

        What is needed (pre-declaration section 1, P1 -- an OWNER action, arc A33):
          * a licensed ASReml-R on a host we can drive (Totoro first for the H2
            leg, or DRAC -- whichever carries the licence);
          * HSQ_S6_ASREML_CMD pointing at the Rscript invocation that runs it;
          * a launch receipt naming host, cells, expected wall-clock, and the
            owner authorisation. Every cell here is a >30 min job, so every one
            of them ASKs.

        NO LAPTOP CLAIMS: the campaign laptop has no ASReml-R and no number
        produced on it may enter either leg's report.

        Frozen design: $(PREDECLARATION)
        """)
    end
    return cmd
end

# ---------------------------------------------------------------------------
# Prerequisite: P2 scaffold files present on THIS branch (ported with provenance).
# Presence only — never execute the prepare/runner from this skeleton.
# ---------------------------------------------------------------------------
const SCAFFOLD_FILES = (
    "comparator/prepare_asreml_matfree.jl",
    "comparator/run_asreml_matfree.R",
    "sim/drac/f0_adversarial_fill.jl",
)

function require_scaffold()
    missing = [f for f in SCAFFOLD_FILES if !isfile(f)]
    isempty(missing) && return nothing
    error("""
    S6 STOP -- P2 scaffold files missing on this branch. NOTHING WAS RUN.

    Expected (ported with provenance from
    refs/heads/codex/2026-07-13-v07-performance-localization @ 853bcc12):
      $(join(SCAFFOLD_FILES, "\n      "))

    Missing:
      $(join(missing, "\n      "))

    Frozen design: $(PREDECLARATION)
    """)
end

# ---------------------------------------------------------------------------
# Toolchain: ASSERTED, not merely recorded.
#
# This is the S5 lesson, fixed here because it cannot be retrofitted to an
# already-run gate: three agents reached for three `julia` binaries across two
# versions because the frozen S5 gate RECORDED its interpreter without
# ASSERTING it. RNG streams are not version-stable across that range, so the
# version is load-bearing, not decorative.
# ---------------------------------------------------------------------------
function assert_toolchain()
    problems = String[]

    want_julia = get(ENV, "HSQ_S6_JULIA_VERSION", "")
    if isempty(want_julia)
        push!(problems, "HSQ_S6_JULIA_VERSION unset -- the interpreter must be " *
                        "asserted, not discovered (S5 lesson).")
    elseif string(VERSION) != want_julia
        push!(problems, "Julia version is $(VERSION), declared $(want_julia).")
    end

    want_sha = get(ENV, "HSQ_S6_HSQUARED_SHA", "")
    if isempty(want_sha)
        push!(problems, "HSQ_S6_HSQUARED_SHA unset -- a dirty or wrong checkout " *
                        "must not be able to produce evidence silently.")
    end

    for (var, want) in ("OPENBLAS_NUM_THREADS" => "1", "JULIA_NUM_THREADS" => "1")
        got = get(ENV, var, "")
        got == want || push!(problems, "$(var) is '$(got)', declared '$(want)'.")
    end

    isempty(problems) && return nothing
    error("S6 STOP -- toolchain assertions failed. NOTHING WAS RUN.\n  " *
          join(problems, "\n  ") * "\n\nFrozen design: $(PREDECLARATION)")
end

# ---------------------------------------------------------------------------
# Dry run: print the frozen plan. Draws no data. Performs no fit.
# ---------------------------------------------------------------------------
function dryrun()
    println("S6 ASReml comparator -- DRY RUN. NOT_RUN: no data drawn, no fit performed.")
    println("Frozen design: ", PREDECLARATION)
    println()
    println("Truth (mu, sigma_a2, sigma_e2) = ", TRUTH, "  [h2 = 0.5, interior]")
    println("Neutral start                  = ", START, "  [a timing leg must not warm-start from truth]")
    println("nprobe                         = ", NPROBE, "  [UNTUNED default; opt-in, `:auto` does NOT route here]")
    println()
    println("GRID -- cheapest-first; identified by (q, fill, class), because the axis is")
    println("        fill nnz(L)/n, NOT raw n:")
    @printf("  %-4s %-18s %9s %-14s %-8s  %s\n",
            "cell", "class", "q", "target fill", "warm/tim", "why")
    for (i, c) in enumerate(GRID)
        q = c.q < 0 ? "observed" : string(c.q)
        @printf("  %-4s %-18s %9s %-14s %d/%-6d  %s\n",
                c.id, string(c.class), q, c.target_fill, c.r_warmup, c.r_timed, c.note)
        @printf("       timing DGP seed %d, MC-probe seed %d\n",
                SEEDS_W_DGP[i], SEEDS_W_DGP[i] + MC_SEED_OFFSET)
    end
    println()
    println("LEG E -- estimand agreement, high-fill cells only (C1, C2, T1, T2), 8 seeds each.")
    println("         DGP seeds ", SEEDS_E_DGP, "; MC-probe seeds = DGP + ", MC_SEED_OFFSET, ".")
    @printf("         ASReml vs fit_ai_reml        : MAX rel.diff over seeds  <= %g\n", AGREE_TOL_EXACT)
    @printf("         ASReml vs fit_matrix_free_reml: MEAN |rel.diff| over seeds <= %g\n", AGREE_TOL_MC)
    println("         A FAIL is a banked negative. No threshold moves afterwards.")
    println()
    println("LEG W -- wall-clock ladder. Closes NO debt. Metric order is not negotiable:")
    println("         1. variance-component AGREEMENT gates the cell;")
    println("            a cell that fails agreement yields NO timing number -- not a slower one, none;")
    println("         2. median of r_timed runs after r_warmup discarded;")
    println("         3. convergence status and iteration count reported, not asserted;")
    println("         4. matrix-free records nprobe and trace_mcse every fit.")
    println()
    println("CAPS (pre-declared; each is UNTESTED until it binds --")
    println("      S5's `CAP_EXHAUSTED <= 4/48` came in at 0/48 and so remains unexercised):")
    @printf("  CAP_FIT_SECONDS      = %d s   -> CAP_EXCEEDED: a result, never a timing number\n", CAP_FIT_SECONDS)
    @printf("  CAP_ITERATIONS       = %d     -> function default, kept; raising it is tuning to pass\n", CAP_ITERATIONS)
    @printf("  CAP_CELL_SECONDS     = %d s  -> report and stop; never shrink q or drop an arm\n", CAP_CELL_SECONDS)
    @printf("  CAP_CAMPAIGN_SECONDS = %d s -> stop and report to the maintainer\n", CAP_CAMPAIGN_SECONDS)
    println()
    println("FITTER ARMS: fit_ai_reml (required) | fit_matrix_free_reml (required, high-fill)")
    println("             fit_eigen_reml -> ABSENT on this branch (P3): reported ABSENT, never blank")
    println("             ASReml-R -> licence-gated (P1): absent => NOT RUN, not partially run")
    println()
    println("P2 SCAFFOLD: PORTED (not run) --")
    for f in SCAFFOLD_FILES
        @printf("             %s  [%s]\n", f, isfile(f) ? "present" : "MISSING")
    end
    println()
    println("FENCE: no 'faster than ASReml' claim on any surface until Leg W has reported")
    println("       AND been Rose-audited. An agreement result is not a timing result.")
    println("       The honest answer today is: cannot say.")
    println()
    println("STATUS: NOT_RUN.")
    return nothing
end

# ---------------------------------------------------------------------------
function main()
    if get(ENV, "HSQ_S6_DRYRUN", "") == "1"
        dryrun()
        return 0
    end

    require_asreml()     # stops here today: no licensed host (P1)
    require_scaffold()   # P2: ported files must be present (presence only)
    assert_toolchain()

    error("""
    S6 STOP -- the campaign is NOT IMPLEMENTED in this skeleton, by design.
    NOTHING WAS RUN.

    Prerequisites that this skeleton can check locally are satisfied (P2 scaffold
    present; P1 ASReml cmd set; toolchain asserted), but this file freezes the
    grid, the seeds, the caps, and the toolchain assertions ONLY. Implementing
    the two legs is a separate, authorised slice (spine arcs A34 Leg E and A35
    Leg W). P2 was discharged by the 2026-09-02 provenance port; P3 remains
    ABSENT (`fit_eigen_reml` reported ABSENT, never blank).

    Do not implement the legs inside this file without re-reading the frozen
    design first, and do not run a cell without an owner launch receipt.

    Frozen design: $(PREDECLARATION)
    """)
end

if abspath(PROGRAM_FILE) == (@__FILE__)
    exit(main())
end
