# H3 replacement protocol — unratified scientific draft

**Status:** DRAFT ONLY.  This document is a recommendation produced after the
sealed H3 S10 no-go.  It changes no source, fixture, manifest, public/API/bridge
contract, capability status, or release state.  It authorizes neither an S10
rerun nor S11/DRAC compute.

## Why a replacement is needed

The sealed candidate (`82f836f368e37cf75609f721f7a03bde3113e10b`) supplied no
eligible H3 intervals: the one retained PATH_ONLY Totoro S10 had an
`r_g` non-convergence and a non-positive-definite observed-information failure
for `r_am`.  Those retained failures are evidence about that candidate, not a
reason to erase them or silently retry it.  See
`2026-09-09-h3-s10-no-go-decision-card.md` and its linked receipt.

The proposed replacement isolates the two scientific targets.  They have
different models, incidence structures, failure modes, and denominators; they
must never be pooled.

## Proposed contract, before any new fixture is materialized

| Cell | Target and truth | DGP / fitted model | Interval and required output | Evidence already available | Not yet evidenced |
| --- | --- | --- | --- | --- | --- |
| H3-rg | `r_g = G[1,2] / sqrt(G[1,1] * G[2,2])`; with `G = [1 .35; .35 .7]`, truth `0.35/sqrt(0.7) ≈ 0.41833` | Two-trait repeated-record half-sib DGP: `u ~ N(0, A ⊗ G)`, `e ~ N(0, I ⊗ R)`; fit unstructured `fit_multivariate_reml` | `genetic_correlation_interval(...; method = :delta, level = .95)`; Fisher-z interval for the off-diagonal genetic correlation | The covered point-estimate recovery design is q=80 (8 sires, 16 dams, 56 offspring), three records/animal, n=240; 12/12 cold starts converged. | That point recovery is **not** interval calibration or even proof that a particular new seed yields a finite interval. |
| H3-ram | `r_am = σ_dm / sqrt(σ²_ad * σ²_am)`; truth `-0.3`, with `(σ²_ad, σ²_am, σ²e) = (1, .5, 1)` and `σ_dm = -.3*sqrt(.5)` | Direct–maternal DGP `y = μ + Z_d a_d + Z_m a_m + e`, one pedigree `A`, correlated `G_dm`; fit `direct_maternal_interval` | `direct_maternal_interval(...; level = .95)` and its `genetic_correlation` Fisher-z interval | The covered confound-broken point-recovery design is ND=30, NS=6, NOFF=8, NGEN=4, q=996, n=960; 48/48 cold starts converged. | The recovery and comparator evidence are **not** calibration of the `r_am` interval. |

The stated methods are asymptotic delta/Fisher-z methods.  This draft makes no
claim of REML for an unrelated non-Gaussian path, of profile/bootstrap coverage,
or of public R promotion.

## Proposed replacement DGMs

### H3-rg — repeated-record identified fixture

Materialize a *new immutable fixture* from the already successful point-recovery
structure, rather than retrying the failed tiny (`3:4:12`, two-record) smoke or
promoting the existing `8:16:96`, two-record scaffold without evidence:

- 8 sires, 16 dams, 56 offspring (q=80), with three records per animal
  (n=240);
- `G = [1 .35; .35 .7]` and `R = [.8 .2; .2 .55]`;
- intercept-only fixed-effect design; one record-to-animal incidence `Z` per
  trait; unstructured multivariate REML; and
- a cold start distinct from the truth parameters, recorded verbatim in the
  new fixture.  The historical recovery statement must not be mistaken for an
  interval result when deciding this start.

The existing `G12=.9` near-boundary cell remains a **negative control** only:
the documented SE path throws and therefore must retain a non-interval/
NON-INTERPRETABLE result.  It cannot be converted into a scalar interval or
counted in the interior-cell denominator.

### H3-ram — confound-broken direct–maternal fixture

Materialize a new immutable interval fixture using the already identified
structure, not the failed tiny maternal cell:

- ND=30, NS=6, NOFF=8, NGEN=4; four overlapping generations, shared sires,
  and dams with their own record plus at least eight recorded offspring;
- q=996, n=960, a common pedigree relationship `A`; and
- `(σ²_ad, σ²_am, r_am, σ²e) = (1, .5, -.3, 1)` with
  `σ_dm = -.3*sqrt(.5)`.

The associated negative control removes dams' own records (and so restores the
direct–maternal confounding mechanism).  Its role is to show the fixture guard
is sensitive to identification, not to create a replacement success.  Its
failure must be retained separately and excluded from the interior denominator.

## Proposed S10 rule (requires a future, separate authorization)

The replacement manifest must pin a candidate source commit, Julia executable,
`Manifest.toml`, driver, fixture, test, and one disjoint master seed **per cell**
before execution.  This draft deliberately does not pick seeds: a seed plus the
new cold-start specification is part of the immutable artifact to be reviewed,
not an unreviewed choice embedded in prose.

One pinned-thread, one-rep Totoro S10 run would execute each interior cell once.
For each cell separately, the sole PATH_ONLY success criterion is:

1. the fit reports convergence;
2. the requested 95% interval is present, finite, ordered, and strictly inside
   `(-1, 1)`; and
3. its estimator/target/method/level fields match the table above.

Every raw output, error, exit status, hash, elapsed time, and `seff`/resource
receipt is retained.  A failed cell does not get another seed or a substitute
fixture; it stops that cell at HOLD.  Neither a successful `r_g` nor a
successful `r_am` changes the status of the other.

## Conditional S11 policy (also requires a future authorization)

Only if an individual cell passes its replacement S10 may a separately sealed
S11 manifest propose a retained one-seed-per-task campaign.  Before submission,
the measured S10 runtime determines routing: a campaign estimated at more than
30 minutes needs the pre-run report and DRAC approval; otherwise the existing
compute routing policy applies.  No `r_g`/`r_am` pooling is permitted.

For any S11 result, report a denominator for that one estimand only:
`coverage = covered / interval_success`, with all unsuccessful fits retained and
reported.  The protocol must predeclare the MCSE and classification bands before
the first campaign task.  A passing numerical count may support only the
predeclared per-cell phrase (for example, directional-conservative); it cannot
promote capability, version, tag, registry, or release state.

## Decision requested

Choose one of these mutually exclusive next moves:

1. **Ratify this replacement protocol as a scientific contract.**  Then the
   next reversible slice is source-inert fixture/manifest/validator
   materialization followed by a new explicit S10 authorization.
2. **Keep H3 outside 0.9.0.**  Reconcile the release programme around its
   currently earned H0 and H1 evidence without an H3 interval claim.

This draft is deliberately not a release decision and does not revise the
existing H3 no-go receipt.
