# Check-log — v0.7-G-7.2 cross-device GPU replicate (Narval A100) (2026-07-03)

**Slice:** re-run the committed G-A + G-B GPU harnesses on a 2nd architecture (A100) to confirm the
CPU↔GPU agreement is architecture-portable. Branch `feat/2026-07-03-v07-g72-crossdevice`. No new code.

## Key result (Narval A100, job 64637092)

- **G-A cross-device agreement PASSED:** device-resident GBLUP β/GEBV ≡ CPU to **~1e-15** on the A100
  (`# agreement OK`), as on the H100 → GPU agreement is architecture-portable.
- **G-B Float64 gate PASSED:** 3.0e-15. Float32 FP32-level accuracy (GEBV impact ~1e-6), TF32 not
  engaged (default==pedantic), modest speedup ~1.0–1.2× — same as H100.
- Device-resident GBLUP benchmark on A100: 5.9×→46.7× (machine-specific, not a competitive claim).

## Evidence

- sbatch `sim/drac/g_ab_narval.sbatch` (Narval gpu_env under `/project/def-snakagaw`, CUDA bound to
  the local cuda/12.6 module).
- Artifacts (tracked): `sim/drac/results/{g_a,g_b}_narval_64637092.tsv`, `v07_g72_narval_64637092.out`.
- Pre-declaration `2026-07-03-v07-g72-crossdevice-predeclaration.md` committed before the run; result
  `2026-07-03-v07-g72-crossdevice-result.md`.
- `Pkg.test()` GREEN (count 55 UNCHANGED); `V2-GRM-GPU` stays `partial`.

## Honesty

Agreement portable; timings per-machine (no A100-vs-H100 competitive claim). No covered flip;
`public_covered_count` UNCHANGED. GPU = acceleration.
