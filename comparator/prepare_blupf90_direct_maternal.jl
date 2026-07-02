# Prepare a BLUPF90 comparator packet for the direct–maternal 2×2 G_dm REML estimator
# (`fit_direct_maternal_reml`, V4-DIRECT-MATERNAL covered evidence, 2nd same-estimand
# comparator leg — ADDITIVE evidence; no status flip, validation_status() count unchanged).
#
# Reads the committed comparator/sommer_dm/ fixture (written by prepare_sommer_dm.jl with
# predeclared seed 20264000) and emits a renumf90-format packet under
# comparator/blupf90_direct_maternal/ so renumf90 1.166 + blupf90+/AIREMLF90 2.60 can
# estimate the SAME (σ²_ad, σ²_am, σ_dm, σ²e) on the same data.
#
# MODEL (BLUPF90 OPTIONAL mat recipe):
#   - One EFFECT for the intercept (cross alpha, position 2)
#   - One EFFECT for the own-animal id (cross alpha, position 3)
#   - RANDOM animal  → builds direct genetic effect (Z_d: record → own animal)
#   - OPTIONAL mat   → renumf90 auto-adds maternal genetic effect from the pedigree's dam
#                      (Z_m: record → dam), estimand = same as engine Z_m
#   - FILE + FILE_POS: the integer-coded pedigree (animal sire dam, 0=unknown)
#   - (CO)VARIANCES: neutral 2×2 start for G_dm (non-degenerate off-diagonal)
#   - RESIDUAL_VARIANCE: neutral 1.0 start
#
# DAM-IDENTIFICATION VERIFIED (confirmed before writing this emitter):
#   The dam_id column in sommer_dm/dm.csv (pedigree row of the dam of each record's
#   own animal) EQUALS the pedigree's dam column for 0/960 mismatches. So OPTIONAL mat
#   (which uses pedigree dam) and the engine's Z_m (record→dam_id) are the SAME.
#
#   julia --project=. comparator/prepare_blupf90_direct_maternal.jl

using Printf

const SOMMER_DM  = joinpath(@__DIR__, "sommer_dm")
const OUT        = joinpath(@__DIR__, "blupf90_direct_maternal")

function main()
    mkpath(OUT)

    # ── 1. Read the committed fixture ───────────────────────────────────────────
    dm_path  = joinpath(SOMMER_DM, "dm.csv")
    ped_path = joinpath(SOMMER_DM, "pedigree.csv")
    tgt_path = joinpath(SOMMER_DM, "engine_target.csv")

    isfile(dm_path)  || error("dm.csv not found at $dm_path — run prepare_sommer_dm.jl first")
    isfile(ped_path) || error("pedigree.csv not found at $ped_path")
    isfile(tgt_path) || error("engine_target.csv not found at $tgt_path")

    # Parse dm.csv: y, animal, dam_id
    dm_lines = readlines(dm_path)
    header = dm_lines[1]
    cols = split(header, ",")
    @assert strip(cols[1]) == "y"      "Expected y in col 1; got $(cols[1])"
    @assert strip(cols[2]) == "animal" "Expected animal in col 2; got $(cols[2])"
    @assert strip(cols[3]) == "dam_id" "Expected dam_id in col 3; got $(cols[3])"

    records = [(parse(Float64, split(l, ",")[1]),
                parse(Int,     split(l, ",")[2]),
                parse(Int,     split(l, ",")[3])) for l in dm_lines[2:end] if !isempty(strip(l))]
    n = length(records)

    # Parse pedigree.csv: id, sire, dam
    ped_lines = readlines(ped_path)
    ped_header = ped_lines[1]
    pcols = split(ped_header, ",")
    @assert strip(pcols[1]) == "id"   "Expected id in col 1; got $(pcols[1])"
    @assert strip(pcols[2]) == "sire" "Expected sire in col 2; got $(pcols[2])"
    @assert strip(pcols[3]) == "dam"  "Expected dam in col 3; got $(pcols[3])"

    pedigree = [(parse(Int, split(l, ",")[1]),
                 parse(Int, split(l, ",")[2]),
                 parse(Int, split(l, ",")[3])) for l in ped_lines[2:end] if !isempty(strip(l))]
    q = length(pedigree)

    # Read engine target
    tgt_lines = readlines(tgt_path)
    tgt = Dict{String,String}()
    for l in tgt_lines[2:end]
        !isempty(strip(l)) || continue
        kv = split(l, ",")
        tgt[strip(kv[1])] = strip(kv[2])
    end

    println("Fixture: n=$n records, q=$q pedigree animals")
    println("Engine targets:")
    for k in ("sigma_ad", "sigma_am", "sigma_dm", "sigma_e2", "r_am", "converged")
        println("  $k = $(get(tgt, k, "MISSING"))")
    end

    # ── 2. Write the BLUPF90 data file ──────────────────────────────────────────
    # Columns: y(1) intercept(2) animal_id(3)
    # Note: renumf90 with OPTIONAL mat derives the maternal identity from the pedigree;
    # the data file needs only the own-animal id (the pedigree's dam is used automatically).
    dat_file = "direct_maternal.dat"
    open(joinpath(OUT, dat_file), "w") do io
        for (y, animal, _dam_id) in records
            @printf(io, "%.10f 1 %d\n", y, animal)
        end
    end
    println("Wrote $dat_file ($n records)")

    # ── 3. Write the pedigree file ───────────────────────────────────────────────
    # Format: animal sire dam (integer codes, 0=unknown)
    ped_file = "direct_maternal.ped"
    open(joinpath(OUT, ped_file), "w") do io
        for (id, sire, dam) in pedigree
            println(io, "$id $sire $dam")
        end
    end
    println("Wrote $ped_file ($q animals)")

    # ── 4. Write renumf90.par (OPTIONAL mat recipe) ─────────────────────────────
    # NEUTRAL START: off-diagonal non-degenerate (avoids trapping AI-REML at diagonal);
    # mirroring the blupf90_multitrait precedent: use [1.0, -0.1; -0.1, 0.5].
    # RESIDUAL_VARIANCE: neutral 1.0.
    # Format rule (from prepare_blupf90_two_effect.jl and the multitrait fix):
    #   keyword and value on SEPARATE lines; blank value-lines for FIELDS_PASSED + WEIGHT;
    #   `cross alpha` (not numer); FILE_POS present; (CO)VARIANCES as 2×2 block.
    par_lines = [
        "DATAFILE",
        dat_file,
        "TRAITS",
        "1",
        "FIELDS_PASSED TO OUTPUT",
        "",
        "WEIGHT(S)",
        "",
        "RESIDUAL_VARIANCE",
        "1.0",
        "EFFECT",
        "2 cross alpha",
        "EFFECT",
        "3 cross alpha",
        "RANDOM",
        "animal",
        "OPTIONAL",
        "mat",
        "FILE",
        ped_file,
        "FILE_POS",
        "1 2 3 0 0",
        "(CO)VARIANCES",
        " 1.0 -0.1",
        "-0.1  0.5",
        "OPTION method VCE",
    ]

    par_file = "renumf90.par"
    open(joinpath(OUT, par_file), "w") do io
        for l in par_lines
            println(io, l)
        end
    end
    println("Wrote $par_file (OPTIONAL mat, neutral 2×2 G_dm start, RESIDUAL 1.0)")

    println("\nPacket ready in: $OUT")
    println("Next steps:")
    println("  1. cd $OUT && <path>/renumf90 $par_file")
    println("  2. <path>/blupf90+ renf90.par   # or airemlf90 renf90.par")
    println("  Compare estimated G_dm + σ²e to engine targets above.")
end

main()
