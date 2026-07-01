# After-task — v0.6 probit/ordinal liability + binary-observed h² (doc-20 Step 4) — 2026-07-01

> **Update:** this PR grew from liability-only to also include the **BINARY (`:bernoulli_probit`)
> observed-0/1 scale** (QGglmm probit integration, verified EQUAL to the Dempster–Lerner transform to
> MC precision — see the check-log addendum). The ordinal K>2 observed scale + the Gamma data scale
> stay fenced. A fresh Rose audit covers the addition. Suite green, count 50, nothing flipped.

## Task goal
Autonomous follow-up after the v0.6 ordinal + Gamma covered-READY close. Extend the exported
`nongaussian_heritability` to the threshold families (`:bernoulli_probit`, `:ordered_probit`) with the
liability-scale heritability — the selection-relevant primary scale for the top v0.6 family, and the
doc-20 Step-4 / doc-19 §2.3 follow-up. Closed-form + exact; NOT a covered flip. Branch
`feat/2026-07-01-v06-ordinal-liability-h2` (off `main`).

## Active lenses and spawned agents
- Review lenses: Falconer/Fisher (the liability estimand + Dempster–Lerner), Grace (docs build).
- Real subagent: a `rose-systems-auditor` claim-vs-evidence audit (see check-log / status).

## Live phase snapshot
Extends `V6-NS-H2` (h² transform) with the probit/ordinal LIABILITY scale. `main` @ `94d20319`,
count 50, public-covered fitting 1 — UNCHANGED. Independent of the 6-PR family chain (needs only the
probit/ordinal KERNELS, which are on `main`). This is a 7th, independent PR candidate.

## Files changed (this slice)
- `src/nongaussian.jl` — `_nongaussian_h2_core` `:bernoulli_probit || :ordered_probit` branch
  (liability `V_A/(V_A+1+V_fixed)`, observed NaN); `_h2_family_params` for both probit families;
  docstring + error message.
- `test/runtests.jl` — new 13-assertion TDD testset.
- `src/validation_status.jl`, `docs/design/capability-status.md`,
  `docs/design/validation-debt-register.md` — V6-NS-H2 row lockstep (liability added; owed list moves
  probit → observed-scale-only).
- `docs/dev-log/check-log.d/2026-07-01-v06-ordinal-liability-h2.md`, this report.

## What changed
For a threshold (probit) family the latent scale IS the liability, with `V_link = 1` (Dempster–Lerner
1950). So `h²_liab = V_A/(V_A + 1 + V_fixed)` — a deterministic function of the estimated `V_A`,
independent of μ and the cutpoints. Returned in `h2_latent` with `method = :probit_liability`; the
observed/category scale (which needs the incidence/cutpoints) is fenced as a follow-up (`NaN`).

## Checks run and exact outcomes
- TDD: probit families THREW pre-implementation (RED); post-implementation exact
  (`h2_latent = 0.3333…`; K=2 ordinal→bernoulli-probit reduction `0.4444… == 0.4444…`;
  `latent_total = 3.0` with `V_fixed = 1`).
- `Pkg.test()` → **PASS**: new testset 13/13, H7 25/25, count guard `== 50`.
- `docs/make.jl` → exit 0 (docstring change renders).
- Real Rose audit → (recorded in the check-log / status update).

## Public claim audit
V6-NS-H2 stays `partial`/`experimental` (it already was — the h² transform is unpromoted). No covered
flip; `public_covered` = 1; count 50. The liability closed form is exact by construction — no
"unbiased"/"validated coverage" claim is made; the standing QGglmm/MCMCglmm comparator debt is for the
OBSERVATION scale and is retained.

## Tests of the tests
The K=2 ordinal→bernoulli-probit reduction is the load-bearing cross-check (two independent code paths
must agree exactly). The cutpoint-independence assertion guards against accidentally letting the
cutpoints leak into the liability partition. The V_fixed assertion pins the denominator convention
(`V_fixed` enters the liability total, per doc-19 §4).

## Coordination notes
Julia-engine lane, solo. No R edits. Independent of #215–#220 (off `main`); the `fit`-based path for
`:ordered_probit` lights up once #215 (the ordinal joint fit) merges — but the core + the
`(sigma_a2, mu, family)` path are complete and tested now.

## What did not go smoothly
Nothing material. Branch-switch line-number drift required a re-read before the core Edit (expected).

## Known limitations
LIABILITY scale only. The observed/category scale (Dempster–Lerner `z²/[p(1−p)]` binary; per-category
ordinal) is a follow-up. The Gamma observation-scale h² is deliberately NOT attempted — it needs an
NS-2017 distribution-specific-variance (trigamma) literature check, not a midnight guess.

## Next actions
1. Rose audit → address → open PR (independent of the 6-PR chain).
2. Follow-up: the threshold OBSERVED/category scale (needs incidence integration); then the Gamma
   observation-scale h² after the NS-2017 trigamma lit-check.
3. Maintainer: the 6-PR v0.6 merge + G10 (unchanged; this slice does not affect it).
