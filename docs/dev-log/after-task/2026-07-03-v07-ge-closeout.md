# After-task — v0.7-G-E: GPU stream close-out (2026-07-03)

**Owner:** Claude solo (Opus), autonomous (goal: finish doc-25). **Branch:**
`feat/2026-07-03-v75-gpu-closeout` off `main` @ `3675b099`. **Counts:** rows **55**, covered **13**,
`public_covered_count` **5** — NO covered flip. Local, no compute.

## Headline

Closed out the v0.7 GPU stream. **V7.1–V7.5 are all COMPLETE** (each pre-declared, run, Rose-audited,
merged). This slice consolidates: refreshes the `status_cache` pointer Rose flagged stale across the
last three GPU audits, marks doc-25 V7.5 done + the V7 stream complete, and records the honest
one-line summary of the whole stream. No status flip.

## What landed

- **`tools/status_cache.json`** — `refreshed_from_head` refreshed to the current HEAD (was the
  stale `afc446c4` V8.3-era pointer); counts 55/13/5 UNCHANGED.
- **doc-25** — V7.5 → DONE, the V7 GPU stream marked COMPLETE, status header updated (both numbered
  streams done; only the two owed hardening legs remain).
- **check-log** — the consolidated V7 GPU-stream evidence table + honest summary.

## The v0.7 GPU stream, consolidated (all merged this arc)

- **G-A** device-resident GBLUP: CPU↔GPU β/GEBV ~1e-15 (H100), 5.2×→23×.
- **G-B** Float32: Float64 gate 7.3e-15, Float32 GEBV impact ~1e-6, speedup MODEST ~1.1–1.4×, TF32
  not engaged.
- **G-7.2** cross-device (A100): agreement PORTABLE (~1e-15) + Float64 gate 3.0e-15; A100 device-
  resident GBLUP 5.9×→46.7× (not a competitive claim).
- **G-C** large panel: agreement 1.35e-14; the GPU handles n=20k × m=300k on one H100 (29% of 80GB);
  Float32 modest, transfer-bound.
- **G-D** dispatcher: opt-in `backend = :cuda` on the two construction ops; `:cpu` byte-identical.

## Honest summary + scope

GPU genomic acceleration is **numerically exact** (agreement ~1e-15), **architecture-portable**
(H100 + A100), and **handles realistic panels** — but **Float32 is only a minor win** (TF32 not
engaged on either arch) and there is **no R-public surface**. `V2-GRM-GPU` stays `partial`; NO
covered flip; `public_covered_count` UNCHANGED. `Pkg.test()` GREEN (55).

## Remaining (owed hardening legs, not numbered slices)

1. **V8.4 at-scale comparator** — blupf90/sommer at a `q` where the exact path is infeasible;
   intrinsically limited by the external tool's own scale ceiling (documented honestly).
2. **Coverage-calibrated intervals** — a DRAC coverage sim for the multi-effect ratio/`h²` intervals
   (asymptotic, currently uncalibrated per their own docstrings). A preliminary local read is in
   progress. Both are for a *covered* move that stays gated (`public_covered_count` 5).
