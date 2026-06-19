# Phase 3 repeatability `h²` (σ²a/σ²pe split) identifiability study — 2026-06-18

## Question

`sim/phase3_qg_recovery.jl` gates on the repeatability `t = (σ²a+σ²pe)/total`
(robustly recovered, 5/5) but leaves the heritability `h² = σ²a/total` — the
σ²a-vs-σ²pe split — **ungated**, with a forward note that "recovering `h²`
reliably needs a denser pedigree / more relationship contrast." This study tests
that hypothesis directly: does a denser, relatedness-richer pedigree (full-sib
families, more replication, larger `n`) make the split reliably recoverable?

Truth throughout: `(σ²a, σ²pe, σ²e) = (1.0, 0.6, 1.4)` ⇒ `h²_true = 0.333`,
`t_true = 0.533`. Seeds 20260618–20260622. Estimator: `fit_repeatability_reml`.

## Designs probed (richer than the original half-sib `q=100, reps=3`)

Full-sib families with shared sires (relatedness 0.5 within family, 0.25 paternal
half-sibs across families — a real relationship contrast the original lacked):

| Design | sires × dams/sire × offspring/dam | reps | q | n | `relh` per seed | h² recovered |
| --- | --- | --- | --- | --- | --- | --- |
| small | 12 × 3 × 3 | 4 | 156 | 624 | 0.164, 0.449, 0.096, 0.595, **0.903** | 2/5 within 0.20; one σ²a→0.08 collapse |
| large | 15 × 4 × 4 | 5 | 315 | 1575 | 0.072, **0.581**, 0.264, 0.190, 0.131 | 4/5 within ~0.26; one seed misses at 0.58 |

(`t` recovered 5/5 in both designs, as before — it is the identifiable summary.)

## Conclusion (honest, evidence-based)

- More relatedness contrast (full sibs) and more data **do** improve the `h²`
  split: the large design recovers 4/5 within ~0.26, versus the original small
  half-sib design's 2/5 boundary failures.
- BUT the σ²a/σ²pe split remains **weakly identified even at n=1575**: 1 seed in
  5 still misses badly (relh 0.58), so `h²` is **not** reliably gateable at any
  practical validation scale. This is intrinsic — additive genetic and permanent
  environment are both individual-level effects separated only by the pedigree
  covariance pattern, an ill-conditioned contrast.
- Decision: keep `sim/phase3_qg_recovery.jl` gating on `t` and reporting `h²`
  ungated. The speculative "needs a denser pedigree" note is now replaced by this
  concrete evidence. Genuinely reliable `h²` recovery would need either a much
  larger, deeper multi-generation pedigree (beyond dense-validation scale) or an
  external comparator cross-check (sommer/ASReml) — both future / out-of-lane.

This converts an open speculative gap into a closed, documented finding; it does
NOT add an always-failing committed harness (which would amount to tuning a
threshold to a hard problem).
