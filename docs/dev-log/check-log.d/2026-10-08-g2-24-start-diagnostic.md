# G2 current-source 24-start retained diagnostic, 2026-10-08

Scope: replay the current `arc1_v1` selector on already-consumed outer7 and outer10 N=80/null inputs. Diagnostic only; zero G2-counted cases.

Candidate v2 (`baf4fccf84ef75a6c5cb4401caeefe629bae076981e1f95e44f9a1718717e630`, lock `1a1ef2155146ac3471e7f26078a3807c392b14af220b89ba564e426ff258bf45`) passed 35 offline tests but Astra exact-source review returned HOLD. The review is retained at `evidence/g2-next-method-v2/astra-review-HOLD.json` (SHA-256 `dd21bb2d2ef7f8fac4a0c23b2a6f58d966eb2684df3c4639a8643d11d2fd811a`). Findings: vector `+` failed at Julia top level; terminal audit was not pinned.

Candidate v3 (`b05c58ef68ab5caad2eef828ba4bdc53585c01b12826a7c425a511ea32fbef39`) uses `vcat`, binds the audit among 47 pins, and has a no-fit Julia smoke receipt. Lock SHA-256 `44b743b688628ec6b87401ed5e4705d0c278e71bae342f107ca0ce0814699ca6`. Checks: v3 offline suite 37/37; no-fit smoke exit 0 with zero selector/simulation/objective calls; exact-digest preflight refused launch without a review receipt. Astra exact-source review passed (receipt SHA-256 `bd55000f548be233d6f541416c1c51c42bafb368b4bf59ad6bdfe05b2221ee5e`).

The reviewed diagnostic ran in about 38 seconds, below the 180-second hard cap. Run directory: `evidence/g2-next-method-v3/output/run-20261008T061051Z-8cad1ba6/`. It completed 24/24 attempts per case (six K0, eighteen K1), selected K0 for both, recorded zero simulations and zero G2 cases, and changed no seeds or denominators. Original 19-row ledgers and failures were preserved.

Combined output SHA-256 `b94f5b3badcd7f7e5db9e50cb20820fa2819c45090fc3b648e1efe5986f0cf0e`; outer7 `463d30fa1220fc0ef434a43b6ec3c5c36fe798f7b4778f86d34bc2ab9f9da39c`; outer10 `996ca01de57547fdd9540effb0e3bd08f618fc6df9cac54ca706f044fe0cb30c`. Independent Astra output audit PASS receipt SHA-256 `b8567e60fdb980c1d0ca4ab753f9dfc81207e7c755c792789732479232342e01`.

Result summary: outer7 K0/K1 criteria 910.183822/915.736078; outer10 924.636183/931.465370. All K1 attempts remain near-floor. G2-G5 and G8 remain open; G1/G6/G7 need current paired source evidence. R lane and coordination files with foreign changes were not modified.

Commands:

- `python3 evidence/g2-next-method-v3/test_runner.py`: 37 tests passed.
- `python3 evidence/g2-next-method-v3/run_diagnostic.py --candidate-sha256 b05c58ef68ab5caad2eef828ba4bdc53585c01b12826a7c425a511ea32fbef39`: preflight pass, not admitted, no Julia process started.
- Exact reviewed launch used `--launch` with candidate SHA above and review SHA-256 `bd55000f548be233d6f541416c1c51c42bafb368b4bf59ad6bdfe05b2221ee5e`; exit 0.
- `git diff --check`: pass.

