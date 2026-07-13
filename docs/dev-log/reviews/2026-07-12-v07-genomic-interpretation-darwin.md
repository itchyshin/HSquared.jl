# Darwin audit — v0.7 genomic quantitative-genetic interpretation

**Date:** 2026-07-12  
**Julia branch:** `codex/2026-07-12-v07-genomic-activation`  
**R branch:** `codex/2026-07-12-v07-genomic-activation`  
**Endpoint reviewed:** negative / held  
**Final re-audit verdict:** **CLEAN**  
**Initial verdict:** `CHANGES_REQUIRED` (retained below as audit history)

## Final re-audit

All three interpretation findings are resolved across the active R source,
generated help, NEWS, capability/claims/debt ledgers, and top-level, genomic, and
model-status vignettes.

- Public guidance now gives
  `genomic_variance_ratio = sigma_g2 / (sigma_g2 + sigma_e2)`, calls it the
  genomic variance-component ratio on the declared relationship scale, and says
  it is not generally an average marginal phenotypic-variance fraction or
  pedigree-, founder-base-, population-, or universal narrow-sense
  heritability.
- The supplied-`Ginv` explanation remains conditional on the user-supplied
  precision and does not inherit marker-construction provenance.
- Pilot summaries now disclose independent HWE/no-LD markers and explicitly
  deny robustness evidence for LD, population structure, imputation,
  base-frequency misspecification, real panels, and production genotype data.
- The achieved-state phrases “this activation,” “frozen narrow genomic
  activation,” and “narrow genomic activation” no longer occur on the audited
  active surfaces. Current behaviour is consistently an explicit experimental
  route; default activation remains unimplemented.
- Source and generated `hs_control`/`hsquared`/`genomic` help carry the same
  interpretation, and `git diff --check` is clean.

The negative endpoint is therefore **CLEAN** from the Darwin applied
quantitative-genetic interpretation lens. This verdict does not promote the
route: the 432 rows remain a stopped Julia diagnostic, confirmation remains
absent, the R route remains partial/held and non-production, and
`public_covered_count` remains 5.

## Initial audit bottom line (superseded by the re-audit above)

The scientific boundary is mostly honest. The active surfaces consistently retain
sample-frequency, unweighted VanRaden method 1 with
`K_lambda = G + 0.01I`; supplied `Ginv` provenance remains unknown; the result is
labelled `genomic_variance_ratio`; the 432 rows are described as a diagnostic pilot
from the pre-repair Julia-only harness; confirmation did not run; default routing
and count movement remain withheld; and the route is repeatedly fenced as dense,
experimental, validation-scale, and not production.

Three interpretation repairs are still required before the negative endpoint is
clean for applied readers. None requires a numerical or implementation change.

## Initial required changes (audit history)

### 1. Major — explain the coefficient ratio, not only rename it

The design contract correctly defines

```text
r_G = sigma_g2 / (sigma_g2 + sigma_e2)
```

and states that, because `K_lambda` is not constrained to mean diagonal one and
the `0.01I` ridge changes its scale, this coefficient ratio is not generally the
fraction of average marginal phenotypic variance. That distinction is absent from
the applied genomic article, the model-status article, the top-level vignette,
and the generated reference wording. Those surfaces say “not pedigree
heritability,” which is necessary but not sufficient: an applied reader can still
read a number returned by `heritability()` as an ordinary phenotypic-variance
fraction under a different name.

Add, near the first public explanation of marker and supplied-precision results:

- the explicit coefficient formula;
- the human description “genomic variance-component ratio on the declared
  relationship scale”; and
- the warning that it is not generally the fraction of average marginal
  phenotypic variance and is not pedigree-, founder-base-, population-, or
  universal narrow-sense heritability.

For supplied `Ginv`, retain the stronger existing fence: because construction and
scale are unknown, the coefficient is conditional on the inverse supplied by the
user. Do not silently inherit the marker-built `K_lambda` interpretation.

### 2. Major — disclose that the stopped diagnostic has no LD/structure robustness scope

The evidence checkpoint and frozen contract correctly say the pilot simulated
independent HWE hard calls with population MAF sampled from `Uniform(0.05, 0.5)`;
it is explicitly a no-LD design. The main applied genomic article, NEWS, model-
status article, top-level vignette, and R capability/claims rows report the
432-seed stop without this DGP boundary. “Nine preregistered cells” varies `n`,
`m`, and the coefficient ratio, not LD, population structure, imputation, allele-
frequency misspecification, or real marker panels.

Where the pilot is summarized for users, add one compact sentence saying that it
used an exact-model HWE/no-LD design and provides no robustness evidence for LD,
population structure, imputation, base-frequency misspecification, or production
genotype data. This is especially important because “marker-rich” cells can
otherwise be mistaken for realistic genomic-panel evidence.

### 3. Minor but cross-surface — stop calling the held route an activation

Several active R-source surfaces still use “activation” as though it were an
achieved state:

- `R/hs_control.R`: “this activation does not move ...” (and generated
  `man/hs_control.Rd`);
- `vignettes/articles/genomic-prediction.Rmd`: “this activation does not change
  ...”;
- `vignettes/articles/model-status.Rmd`: “frozen narrow genomic activation” and
  “the narrow genomic activation.”

Replace these with “explicit experimental route,” “held activation candidate,”
or equivalent. “Activation” is appropriate in the arc/design name and in phrases
such as “default activation remains unimplemented”; it is misleading when used as
the noun for current shipped behaviour after the negative endpoint.

## Claim-by-claim interpretation verdict

| Interpretation | Verdict |
| --- | --- |
| Sample-frequency VanRaden1 plus `0.01I` is the frozen marker construction | supported and clearly stated |
| Supplied-`Ginv` construction, allele-frequency basis, ridge, and denominator are unknown | supported and clearly stated |
| The output is a coefficient-scale genomic variance ratio | supported in code/metadata; public explanation incomplete |
| The output is pedigree or population narrow-sense heritability | explicitly denied; do not claim |
| The output is generally an average marginal phenotypic-variance fraction | not established; public warning required |
| The 432 rows establish broad marker-route recovery | explicitly denied |
| The 432 rows establish robustness to LD, structure, imputation, or real panels | not established; public DGP warning required |
| The route is production-ready or a production genotype pipeline | explicitly denied |
| Default activation or a covered-count move occurred | explicitly denied; terminology cleanup required |

## Initial re-audit gate (now discharged)

Darwin can return **CLEAN** after the three wording repairs are applied to the R
source documentation and regenerated manuals, followed by a neighbour sweep for
the same two failure modes:

1. any genomic result described as bare `h2`, ordinary heritability, or a generic
   phenotypic-variance fraction; and
2. any recovery/pilot sentence that could be read as LD-, structure-, real-panel-,
   or production-robust evidence.

The negative scientific outcome itself needs no reinterpretation: low convergence
and precision blockers legitimately hold the candidate, but they do not show that
the estimator fails under LD or production data because those settings were not
studied.
