# Non-Gaussian h² decomposition — Fisher + Falconer review (2026-07-01)

**Scope / honesty fence.** This banks the verdicts of a real `fisher-inference-reviewer`
and `falconer-quantgen-interpreter` pass on the V6-NS-H2 h² decomposition. It is
**EVIDENCE toward** the owed "Fisher/Falconer sign-off on the exact decomposition"
(listed in the V6-NS-H2 debt row + Rose's integration audit) — it is **NOT the sign-off
itself, and NOTHING flips to covered.** V6-ORDINAL / V6-GAMMA / V6-NS-H2 stay `partial`;
the MCMCglmm same-estimand comparator + maintainer G10 remain independently owed. The
required corrections below belong in the REAL h² PRs (#221/#223 for the code + probit/ordinal
docs; #222 for the Gamma doc) BEFORE any covered flip — they are documented here, not pushed
to the feature branches from a docs branch.

## Both verdicts: SOUND-WITH-CAVEATS

The math, estimands, and identifying conventions are **correct throughout** — both lenses
independently re-derived the two load-bearing reductions (Gamma latent `V_link = ψ₁(ν) =
Var[log Y]`; the observation-scale μ-cancellation) and confirmed the estimand convention
against the *actual* QGglmm comparator calls (not just the numeric tolerance already banked).
No derivation error was found. The corrections are honesty/consistency/wording items required
to make the surface *self-describing* at this repo's bar.

## Verified patch available (2026-07-01)

Corrections 1 (bias-fence), 2 (plug-in/no-interval status), and 4 (interior-category
Stein-understatement caveat) are now applied + **test-verified** as
`docs/dev-log/recovery-checkpoints/2026-07-01-h2-biasfence.patch` — a 6-line `src/nongaussian.jl`
diff generated on the v0.6 integration build: `:bernoulli_probit` → `information_limited = true`;
`:ordered_probit` → `information_limited = p_min < 0.05` (fires for sparse categories) + the
interior-category "descriptive, not selectable" caveat; both caveats gain the plug-in/no-interval
note. `Pkg.test()` stays GREEN and `validation_status()` count stays **50** with the patch applied
(verified: probit `information_limited` flips true, ordinal sparse-design flag fires, balanced
design stays false). Apply with `git apply` after merging the 9 PRs. Correction 3 (the doc-19 §2.3
Dempster–Lerner-ordering sentence) is a pure-prose addition captured below — the code caveat already
states "always < h2_latent". No test asserted the old `information_limited = false`, so nothing
downstream breaks.

## The convergent finding (BOTH lenses, independently) — highest priority

**The `information_limited` bias-fence is family-incomplete.** The Laplace/penalized-IRLS σ²a
downward-bias flag fires only for single-trial **logit** Bernoulli (`n_trials == 1`), but
`:bernoulli_probit` is single-trial **by construction** and is the *worst* case for that bias,
yet both probit returns hard-code `information_limited = false`. Presenting the flagship
"selection-relevant liability h²" as clean while flagging the equivalent logit number is a
genuine inconsistency (Fisher: "assume ten more of the same kind"; Falconer: "a quant-geneticist
would object"). This is the one finding both would hold the sign-off on.

## Required corrections (for the real PRs, before G10)

1. **Bias-fence (CONVERGENT — Fisher #1 + Falconer #3).** In `src/nongaussian.jl` (on
   `origin/feat/2026-07-01-v06-ordinal-observed-h2`), the `:bernoulli_probit` return sets
   `information_limited = false` — change to `true` (single-binary is always information-limited),
   and for `:ordered_probit` flag/caveat the sparse-extreme-category case. Update the per-call
   `caveat` strings to state the liability h² inherits the single-record Laplace bias, and name
   the probit/ordinal liability h² in `docs/design/19-h2-scale-contract.md` §5's Laplace-bias fence
   (currently logit/low-count-centric).

2. **Plug-in / no-interval status (Fisher #2).** Every scale is a deterministic plug-in point
   estimate conditional on supplied `V_fixed` + estimated σ²a/ν/cutpoints, with zero uncertainty
   propagation and no calibrated interval. State this explicitly in the caveat + doc §5 — a user
   seeing `h2_latent = 0.31` will otherwise read it as a fitted, error-bounded estimate.

3. **Dempster–Lerner ordering as a FACT (Falconer #1).** Add to doc §2.3: because
   `z²/[p(1−p)] < 1` for all incidences (max ≈ 0.637 at p=0.5), the observed-0/1 heritability is
   ALWAYS smaller than the liability heritability — the classic DL ordering. (Verified empirically:
   e.g. VA=1,μ=0 → liab 0.500 vs obs 0.318.)

4. **Ordinal interior-category Stein-understatement caveat (Falconer #2).** The per-category
   observed h² is the QGglmm data-scale (Stein first-order Ψ²V_A) estimand; for **interior**
   categories, where `P(y=k|η)` is non-monotone in the breeding value, `E[∂P/∂η] ≈ 0` and the
   value can substantially UNDERSTATE the exact indicator genetic variance (Falconer's K=3 check:
   formula 0.0028, QGglmm agrees 0.0206, exact Monte-Carlo ~0.044 — a >10× gap). NOT a bug (it
   faithfully reproduces the QGglmm/de Villemereuil definition), but the `:ordered_probit` caveat +
   doc §3 must say the per-category vector is DESCRIPTIVE, not a set of independently-selectable
   heritabilities — the liability-scale h² is the selection-relevant summary.

## Non-blocking flag (Falconer #4)

Mean-standardized **evolvability** `CV_A` / `I_A = V_A,obs/μ²` (Houle 1992; Hansen–Pélabon) is the
natural companion to the Gamma/positive-continuous data-scale h² (the machinery — `Var(μ)`, `E[μ²]`
— is already computed). Not required for this slice; note it in doc §6 as an owed companion so the
Gamma surface is not read as complete for evolvability questions.

## What this discharges / what remains owed

- **Discharges (as evidence):** the "Fisher/Falconer review of the exact decomposition" owed item is
  now RUN — both SOUND-WITH-CAVEATS, math correct, with the 4 corrections above. The maintainer's
  final sign-off + the corrections landing in the real PRs complete it.
- **Still owed (independently):** the MCMCglmm same-estimand comparator (lane 2); the maintainer G10
  covered flip (public-covered 1→3). Neither is affected by this review.

## Provenance

Real subagents: `fisher-inference-reviewer` + `falconer-quantgen-interpreter`, run 2026-07-01 on the
PR-branch h² code (`origin/feat/2026-07-01-v06-{gamma-latent,ordinal-observed}-h2:src/nongaussian.jl`)
+ `docs/design/19-h2-scale-contract.md`. Both independently reproduced the QGglmm estimands
(trigamma vs CV; DL ordering/transform; ordinal per-category vs Monte-Carlo). `main` untouched.
