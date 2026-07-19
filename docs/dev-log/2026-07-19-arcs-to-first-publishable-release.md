# H² — main arcs to a first publishable (JSS-quality) release

**2026-07-19. Strategic planning synthesis (Shinichi + Claude). Durable note — NOT a capability claim.**
Companion to `ROADMAP.md` (Phases 0–8) and `docs/design/18-programme-plan-2026-06.md`. A condensed version
lives on the mission-control H2 board (`live/status/H2.json` → `capability.note`).
**Return-to trigger:** revisit after the v0.7 genomic activation arc closes (D1→D4 + G10); the next planning
decision is to LOCK the first-paper scope (arc D) and sequence arcs A/B/C against it.

## Readiness estimate (conservative, honest)

Toward a first release publishable in a top venue (e.g. *Journal of Statistical Software*): **~45–50%
overall.** Split:
- **Julia engine** (methods + validation): well advanced, **~70%** — unusually broad, recovery-gated +
  external-comparator-validated covered set; but production sparse/genomic/generality still experimental.
- **User-facing R package** (the artifact we'd actually publish): earlier, **~40%** — narrow public surface
  (`public_covered_count = 5`), the R↔Julia bridge mostly opt-in, docs/vignettes incomplete, no CRAN release.

The remaining work is mostly the **"last mile"** (packaging, docs, R surface, validation close-out), NOT
new methods — and the last mile is routinely underestimated (it's often what decides acceptance). Scoping
the first paper to the already-validated core → closer to **~55–60%**.

## Current arc (in flight)

Genomic public activation (v0.7 → Phase 2 close): **D0F ✓ → D1 (in progress) → D2 → D3 → D4** + G1–G7 +
a separate maintainer **G10** + a doc-44 amendment. Only when the full ladder clears does
`public_covered_count` move off 5 and the `ordinary_auto_genomic` route go public.

## Publication critical path — the four arcs that gate a first release

- **A · Production-scale fitting.** Promote the sparse / matrix-free AI-REML path (validated to ~10⁶
  individuals on DRAC) from a validation-scale **oracle** to the actual **default** fitting engine. (Phase 1/8 close.)
- **B · R public surface.** Turn *engine*-covered estimators into *R-public*-covered ones — a clean,
  documented R formula interface end-to-end, a robust R↔Julia bridge, proper extractors. **THE biggest gate**
  (it's why the R side is ~40% and the count sits at 5).
- **C · Docs + CRAN.** Vignettes, worked examples, pkgdown, CRAN compliance, first tagged release.
- **D · The paper.** Scope + niche vs sommer / ASReml / BLUPF90 / MCMCglmm, reproducible examples, benchmarks.

## Later-version scope (future papers; NOT first-release-critical)

- Multivariate + factor-analytic **G** public activation (Phase 4/4B) — R syntax, rotation conventions,
  calibrated inference (FA multi-seed calibration has NOT fully passed).
- QTL/GWAS/eQTL public formula path + calibrated mixed-model p-values (Phase 5).
- Non-Gaussian & GLLVM-style / ordination models (Phase 6).
- GPU + backend dispatch (Phase 7); HPC production scaling — checkpointing, disk-backed, distributed (Phase 8).

## Strategic lever (the decision that moves the date most)

The first paper's **scope** is the highest-leverage choice. A **focused first release** — pedigree +
genomic + the covered multi-effect / multivariate REML core, exposed through a clean R surface — is
publishable far sooner than the full 8-phase vision, which is really a **multi-paper programme**.
**Recommendation:** scope paper 1 to the validated core; treat Phases 4B/5/6/7/8 as follow-on papers.
