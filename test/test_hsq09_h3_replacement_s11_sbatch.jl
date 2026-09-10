using Test
const H3_S11_SBATCH = read(joinpath(@__DIR__, "..", "sim", "drac", "hsq09_h3_replacement_s11.sbatch"), String)
const H3_S11_PRERUN = read(joinpath(@__DIR__, "..", "sim", "drac", "hsq09_h3_replacement_s11_prerun.sbatch"), String)
@testset "H3 S11 Narval launcher" begin
    for text in ("#SBATCH --array=1-2000%100", "#SBATCH --cpus-per-task=1", "#SBATCH --output=/project/6098264/snakagaw/hsq09-h3-replacement-s11-20260910/logs/%x_%A_%a.out", "#SBATCH --error=/project/6098264/snakagaw/hsq09-h3-replacement-s11-20260910/logs/%x_%A_%a.err", "JULIA_NUM_THREADS=1", "OPENBLAS_NUM_THREADS=1", "refusing overwrite", "--cell=")
        @test occursin(text, H3_S11_SBATCH)
    end
    @test !occursin("--array=1-2000%101", H3_S11_SBATCH)
    for text in ("#SBATCH --time=00:20:00", "H1_DEPOT=/project/6098264/snakagaw/hsq09-h1t-identified-s11-36ae0691/julia-depot", "JULIA_PKG_OFFLINE=true", "Pkg.instantiate(; update_registry=false); Pkg.precompile()", "for cell in rg ram", "H3_REPLACEMENT_S11_PRERUN_OK")
        @test occursin(text, H3_S11_PRERUN)
    end
end
println("H3_REPLACEMENT_S11_SBATCH_TESTS_OK")
