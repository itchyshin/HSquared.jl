# 2026-07-02 — Generality-gap doc-consistency sweep: COMPLETE + CERTIFIED airtight `[JL+R]`

Closes the ultraplan. An ultracode 20-agent adversarial verification sweep
(`tasks/wn53jg239.output`) confirmed the `public_covered_count` 1→5 win is
**evidence-airtight** (every gate/comparator/parity AIRTIGHT — Phase 3 literally so;
zero numerics / evidence-chain / dangerous-overclaim findings) but found **11
adversarially-confirmed stale status-surface contradictions** — covered models still
labelled `partial`/`experimental` from uneven propagation of the Phase 1–3 flips.
Direction was SAFE (under-claiming), but real.

**HONEST CORRECTION:** the 2026-07-02 overnight after-task report stated "no stale
contradictions / all honesty pins held." That was true only for what the Phase 4 Rose
audit swept (direct–maternal + its flagged spots); it did NOT re-sweep the earlier-phase
flips across all surfaces. The verification sweep (run precisely to check) caught the debt.

## The 11 findings + resolution (all confirmed clean at HSquared.jl 2b2078cc / hsquared f01ff61)

**hsquared — named surfaces (R-lane peer, commit `5389f23`, merged):**
- `06-public-claims-register.md:21` common-env still partial → covered
- `capability-status.md:29,34` two-effect + RR still partial → covered
- `R/formula-status.R:179,197-206` common-env/multi-effect "experimental" prose → covered
- `model-status.Rmd` covered models under experimental header → split section

**hsquared — vignettes/README the named pass missed (PR #121, merged):**
- `rr-comparator.Rmd:45-50` "k=2 flip staged / rr() not covered" (blocking) → covered
- `validation-evidence.Rmd:265-270, 287-289` "opt-in models are partial" (blocking) → split
- `multi-effect-comparator.Rmd:279` "engine-covered ≠ R-public-covered" → covered
- `fitting-models.Rmd:46-50, 216-217` blanket "experimental" over covered common-env → qualified
- `README.md:41-45` "each mirroring a partial gate" → covered set identified (line 79 genuinely-partial, kept)

**HSquared.jl — v0.6 orphans #243's count-52 scope didn't touch (PR #245, merged):**
- `validation-debt-register.md:72-73` V6-ORDINAL + V6-GAMMA `partial` → `covered (scoped)` (lagged the #229/`62033227` G10 flip; integrity-confirmed #229 was a real Rose+G10 flip before retiring the text)
- `validation_status.jl:467` V6-GAMMA "owed a Rose audit + G10 flip" (already done via #229) → retired; genuine standing debt kept

## Certification (targeted re-check of every spot, 2026-07-02)

All 11 spots return covered/split wording; **no stale contradiction remains**. Counts
UNCHANGED: HSquared.jl `validation_status()` rows=53 / covered=13 / `public_covered_count`=5;
hsquared `validation_status()` 21 rows. No coverage decision moved — pure propagation.
Both repos' CI green (Julia 1+1.10+Documenter; R-CMD-check+pkgdown). No numerics, no failed
gate, no dangerous overclaim.

## Banked low-priority nits (cosmetic, non-blocking, not contradictions)

- `validation_status.jl` doc-16 vs doc-33 citation style inconsistency (both resolve).
- `likelihood.jl:1661` fence tagged "Falconer" but the statement is Willham (row + R surface correctly attribute Willham).
- `comparator/sommer_rr/` R-side stdout not committed (engine side + script are).
- `tools/status_cache.json` `refreshed_from_head` pointer stale (counts correct, verified live).

## Verdict

**The mixed-model generality-gap ultraplan is COMPLETE and CERTIFIED airtight.**
Public surface: 1→5 covered models (v0.1 Gaussian + common-env two-effect/c² + arbitrary
`(1|g)` + RR k=2 + direct–maternal 2×2 G), each gate + comparator + Rose + paired CI.
Engine scale foundation: Phase 5 P5.1 sparse AI-REML (experimental; perf benchmark OWED,
the one remaining compute-gated item — not a generality claim).
