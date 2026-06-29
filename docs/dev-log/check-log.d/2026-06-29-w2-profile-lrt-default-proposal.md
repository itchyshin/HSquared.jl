# 2026-06-29 — W2 profile-LRT default proposal (Rose-audited) + medium-coverage correction

- Drafted a proposal recommending the default `heritability_interval` switch from delta/Wald to
  profile-LRT (option a) or documenting profile as the recommended opt-in (option c), based on the
  W1 Campaign 1 coverage evidence.
- Ran a **real Rose audit** (`rose-systems-auditor` subagent) — verdict **clean-with-changes**.

## What Rose caught (and the fixes applied)

1. **A real data error (not just wording):** the medium-coverage *summary* table reported level-LUMPED
   coverage — the first medium ingest grouped by `(method, h²)` WITHOUT separating the 90%/95% levels, so
   every number blended both. Verified against the committed level-separated TSV
   (`2026-06-29-w1-c1-medium-coverage.tsv`). **Fixed:** rewrote the medium summary with TSV-derived
   numbers (σ²a delta-z 95%: 0.944/0.925/0.870 at h²=0.3/0.5/0.7, not the lumped 0.914/0.917/0.860) and
   corrected the same 0.917→0.925 / ~0.86→~0.87 in the `V1-HERIT-TCAL` register append. tiny+small
   summary + both TSVs were unaffected (only the medium summary's ingest had the bug).
2. **Overclaim "profile is the better default / delta is the worst":** true only for σ²a in the small
   design; profile under-covers h²=0.3 (small) where delta is fine, and over-covers σ²a at medium. **Fixed:**
   reframed as **failure mode** — profile is *conservative* (over-covers), delta's small-n σ²a failure is
   *anti-conservative* (under-covers); an anti-conservative default is the worse user error. Not "best
   everywhere."
3. **Interpretable-cells gating:** the ranking rests only on interpretable cells (small h²≥0.3 + all
   medium). **Fixed:** stated explicitly in the table caption.
4. **Minor:** noted that a Julia default flip changes R behavior with no R code change but needs an R
   roxygen-doc edit; confirmed "no new code" for option (a) (`heritability_interval(:profile)` is
   implemented at `src/likelihood.jl:1464` + tested at `test/runtests.jl:4996`).

## Checks

- Rose verdict: clean-with-changes → all required changes applied; numbers re-derived from the committed TSVs.
- Fences (Rose-confirmed): no change made; a default change routes through the R↔Julia contract (Codex) +
  maintainer G10 + a fresh Rose audit of the new default's claim; `V1-HERIT-TCAL` stays `planned`;
  `validation_status()` = 48 unchanged; public-covered = 1.
- `git diff --check` clean; foreign files never staged.

## Claim audit

Clean-with-corrections. A maintainer-facing recommendation (not a change), with the data error fixed, the
claim reframed to what the evidence supports (failure mode, not uniform calibration), and the ranking
scoped to interpretable cells. The default change itself remains gated on Codex + maintainer G10.
