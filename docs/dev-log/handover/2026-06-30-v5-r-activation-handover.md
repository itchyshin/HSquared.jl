# Handover: v0.5 QTL covered flip → Codex / R lane (the `gwas()` activation)

Meta: 2026-06-30 · from Claude (HSquared.jl Julia engine lane, solo) · to Codex (live R/JuliaCall toolchain) +
maintainer (G10). Read order: `AGENTS.md` → this doc → `docs/design/18-programme-plan-2026-06.md` (§QTL, lines
100/120-122) → the three v0.5 after-task reports below. The baton is sequential.

## TL;DR

Both **Julia-lane-reachable** legs of v0.5 (QTL) are DONE and merged. The V5 covered flip is now gated
**solely** on the R `gwas()`/`marker_scan()` activation — a cross-lane NEEDS-R/BRIDGE task in the `hsquared`
repo (which the Julia lane must not edit) — plus maintainer G10. Nothing is promoted; `V5-MARKER-THRESHOLD`
stays `partial`/`experimental`; `validation_status()` = 48 (covered 7 / covered_external 3 / partial 37 /
planned 1); public-covered fitting = 1; `gwas()` significance wording HELD.

## What is DONE in the Julia lane (verify live before acting)

| Leg | Evidence | PR | Status |
| --- | --- | --- | --- |
| Calibration — type-I control (single design) | add-one `genome_wide_pvalue` gate PASS (mean type-I 0.0543 ≤ α+2·MCSE), where the `(1−α)` quantile rule had FAILED anti-conservative (#202) | #203 (`8d9de557`) | merged |
| Calibration — type-I control (design grid) | add-one gate PASS at (n,m) ∈ {(200,100),(300,200),(500,300)} (means 0.068/0.058/0.061) | #204 (`799d65cc`) | merged |
| External comparator | **PLINK 1.9 max(T)** (`--assoc --mperm 2000`, EMP2) reproduces `genome_wide_pvalue` across β=0→0.8: SAME top marker ×5, genome-wide p agreeing to MC error, per-marker χ²/T² cor 0.998-1.000 | #205 (`06768f71`) | merged |

- Pre-declarations (commit-before-run) + RESULTs:
  `docs/dev-log/recovery-checkpoints/2026-06-30-v5-qtl-addone-gate-predeclaration.md`,
  `…-v5-qtl-addone-design-sweep-predeclaration.md`, `…-v5-plink-maxt-comparator.md`.
- After-task reports: `docs/dev-log/after-task/2026-06-30-v5-addone-threshold-gate-pass.md`,
  `…-v5-addone-design-sweep-pass.md`, `…-v5-plink-comparator.md`.
- Comparator harness (reproducible; PLINK not vendored): `comparator/prepare_plink_threshold.jl` +
  `comparator/plink_threshold/`.
- Each slice: real Rose audit → PROMOTE; `Pkg.test()` green; CI green; nothing promoted.

## What the R lane / Codex must do for the covered flip (the SOLE remaining leg)

doc-18 line 120 gates the V5 covered claim on `calibrated thresholds → R gwas()`. Concretely, in `hsquared`:

1. **Activate `marker_scan()` / `gwas()`** from reserved→parsed: wire the R formula surface to the Julia engine
   `single_marker_scan` / `mixed_model_marker_scan` + `genome_wide_pvalue` (the add-one max(T) rule — NOT the
   `(1−α)` quantile threshold, which #202 showed is anti-conservative). The genome-wide significance call MUST
   use `genome_wide_pvalue` (validated here) for the formal accept/reject.
2. **Bridge payload parity**: a marker-scan result payload + the genome-wide p; an R-lane Julia-free parity
   fixture mirroring `test/fixtures/marker_scan_parity/` (already serialized on the Julia side).
3. **R-facing significance wording**: only after (1)+(2) may the held `gwas()` significance wording be
   activated. Until then it stays held.
4. **Then** the covered flip is a JOINT contract move (AGENTS.md rule 2): update BOTH twins' status surfaces in
   lockstep, a real Rose audit, and maintainer **G10** sign-off. The Julia `validation_status()` V5 row moves
   `partial→covered` ONLY as part of that atomic cross-twin flip — do not flip it from the Julia lane alone.

## Honest fences (do NOT overclaim)

- The calibration evidence is **type-I CONTROL** of the add-one rule on ONE LD architecture, intercept-only
  design, single trait — NOT power, NOT covariate-adjusted GWAS (Freedman–Lane / ter Braak), NOT multiple LD
  schemes. The comparator is one independent implementation (PLINK) on one design.
- The add-one and PLINK statistics differ (known vs estimated residual variance; max rel χ² diff ~0.09 null →
  ~0.27 at a strong-causal marker) — the genome-wide DECISION agrees, but do not claim statistic identity.
- Optional hardening (not required for the leg): a 2nd external comparator (GCTA `--mlma` / statgenGWAS), a
  covariate-adjusted null, more LD architectures, coverage calibration, and the #45 post-fit/formula-driven
  scan dependency.

## Never-stage (verbatim — never `git add -A`; stage explicit paths only)

- `docs/dev-log/recovery-checkpoints/2026-06-22-r-twin-nongaussian-per-record-trials-spec.md`
- `sim/.v2gate_run.log.txt`
- `sim/phase6_nongaussian_interval_coverage.tsv`

These three foreign/untracked files were present at session start and must stay untracked.

## State to verify live

- `git -C . log --oneline -1` → `main` @ `06768f71` (#205). `gh pr list` → no open v0.5 PRs.
- `validation_status()` → 48 rows; V5-MARKER-THRESHOLD `partial`. `Pkg.test()` green.
- `hsquared` R twin: clean `main` (mirror status only AFTER the joint covered flip).
