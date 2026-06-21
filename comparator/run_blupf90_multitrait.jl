include("prepare_blupf90_multitrait.jl")

using .HSquaredBLUPF90MultitraitPacket

packet = generate_blupf90_multitrait_packet()
executables = probe_blupf90_executables()

if get(ENV, "HSQUARED_RUN_BLUPF90", "false") != "true"
    println("""
    [skip] BLUPF90/AIREMLF90 comparator is opt-in. The starter packet was
           generated and validated, but no external executable was run.

           To execute on a machine with BLUPF90-family tools:
             HSQUARED_RUN_BLUPF90=true julia comparator/run_blupf90_multitrait.jl

           This runner is evidence hygiene only until the generated outputs,
           executable versions, convergence status, alignment rules, and
           tolerance are recorded in a separate claim audit.
    """)
    exit(0)
end

for name in ("renumf90", "airemlf90")
    isnothing(executables[name]) &&
        error("HSQUARED_RUN_BLUPF90=true requires `$name` on PATH")
end

cd(packet.output_dir) do
    run(`$(executables["renumf90"]) renumf90.par`)
    isfile("renf90.par") || error("renumf90 did not produce renf90.par")
    run(`$(executables["airemlf90"]) renf90.par`)
end

println("BLUPF90-family commands completed. Record versions, convergence output, generated renf90.par, and aligned estimates before using this as comparator evidence.")
