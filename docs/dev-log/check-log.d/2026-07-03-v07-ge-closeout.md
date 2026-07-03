# Check-log — v0.7-G-E GPU stream close-out (2026-07-03)

**Slice:** consolidate the v0.7 GPU stream (V7.1–V7.5). Branch `feat/2026-07-03-v75-gpu-closeout`.
Local, no compute.

## What this slice does

- **`tools/status_cache.json` pointer refreshed** — `refreshed_from_head` was stale (`afc446c4`, a
  V8.3-era commit, flagged by Rose on V7.2/V7.4/V7.3); re-ran `tools/gen_status_json.jl
  --refresh-count` → now points at the current HEAD; counts 55/13/5 UNCHANGED (correct).
- **doc-25 V7.5 → DONE; the V7 GPU stream (V7.1–V7.5) marked COMPLETE**; doc-25 status header updated
  (both V8 and V7 numbered streams done; only the two owed hardening legs remain).
- **NO status flip** — `V2-GRM-GPU` stays `partial`. There is no covered move (the whole GPU stream
  is engine acceleration, not a new R-public model; `public_covered_count` stays 5).

## The consolidated V7 GPU-stream evidence (all merged)

| Slice | Result |
|---|---|
| G-A device-resident GBLUP | CPU↔GPU β/GEBV ~1e-15 (H100); 5.2×→23× |
| G-B Float32 | Float64 gate 7.3e-15; Float32 GEBV ~1e-6; speedup MODEST ~1.1–1.4×; TF32 not engaged |
| G-7.2 cross-device (A100) | agreement PORTABLE (~1e-15) + Float64 gate 3.0e-15; A100 bench 5.9×→46.7× |
| G-C large panel | agreement 1.35e-14; handles n=20k×m=300k (29% of 80GB); Float32 modest, transfer-bound |
| G-D dispatcher | opt-in `backend = :cuda` on the two construction ops; `:cpu` byte-identical |

## Honest one-line summary

GPU genomic acceleration is **numerically exact** (agreement ~1e-15), **architecture-portable**
(H100 + A100), and **handles realistic panels** (n=20k × m=300k on one H100) — but **Float32 is only
a minor win** (TF32 not engaged) and there is **no R-public surface**. `V2-GRM-GPU` stays `partial`;
`public_covered_count` UNCHANGED. `Pkg.test()` GREEN (55).
