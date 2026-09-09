using Test

const H1T_S11_SBATCH = joinpath(@__DIR__, "..", "sim", "drac", "h1two_identified_s11.sbatch")

@testset "identified H1-two S11 Slurm contract" begin
    script = read(H1T_S11_SBATCH, String)
    @test occursin("#SBATCH --account=def-snakagaw_cpu", script)
    @test occursin("#SBATCH --partition=cpubase_bycore_b1", script)
    @test occursin("#SBATCH --array=1-2000%100", script)
    @test occursin("#SBATCH --cpus-per-task=1", script)
    @test occursin("#SBATCH --mem=2G", script)
    @test occursin("#SBATCH --time=00:05:00", script)
    @test occursin("export JULIA_NUM_THREADS=1", script)
    @test occursin("export OPENBLAS_NUM_THREADS=1", script)
    @test occursin("H1T_S11_SEED_START=202609100001", script)
    @test occursin("H1T_S11_SEED_STOP=202609102000", script)
    @test occursin("--seed=\"\${seed}\"", script)
    @test occursin("--out=\"\${receipt}\"", script)
end

println("H1T_S11_SBATCH_TESTS_OK")
