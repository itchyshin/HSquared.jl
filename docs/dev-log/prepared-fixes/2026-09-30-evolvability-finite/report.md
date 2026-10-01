# Evolvability complete current review and finite-result proposal

## Scope and disposition

All314 original lines inspected at src/evolvability.jl SHAfd49987ee69c1f9b6e3335bdb6e4f8c73b6f0cdab3da4b7263cf4e87b6577ff3. Complete coverage PASS; bounded repair independent approval pending. Existing Gauss/Noether conditioning/stability approval and Kirkpatrick/Rose definitions/claims reviews are retained at their stated exact scopes, rather than expanded into whole-file approval.

| Original span | Disposition |
| --- | --- |
|1-35|Descriptive genetic geometry and latent rotation versus trait-unit interpretation reviewed; generic result covariance extraction is a caller contract.|
|36-68|Finite square/symmetric PSD, zero-variance covariance and trait-normalized PSD guards inspected. No changes.|
|69-92|Scale-normalized positive-definite inverse metric and explicit Float64 condition ceiling inspected; earlier signed numerical repair reused exactly.|
|93-104|Finite normalized direction computed through maximum-entry scaling; no changes.|
|105-153|e=unit-beta transpose G beta, c=1/(unit-beta transpose G-inverse beta), respondability=norm(G unit-beta); definitions and return arithmetic inspected.|
|154-194|Autonomy=c/e with numerical upper clamp, raw or normalized variance of a contrast; raw finite inputs can return infinite variance. Bounded finite-result proposal prepared.|
|195-259|PCA sorted nonnegative eigenvalues, sign canonicalization, repeated eigenspace warning, leading axis and mean trace/n inspected. Existing normalized trace arithmetic unchanged.|
|260-294|Plot geometry, scale-safe explained fractions, axis slicing and PCA scaled-vector labels inspected. Requested axes are converted through Int; strict integer/error taxonomy remains a metadata debt.|
|295-314|Correlation plotting forwards covariance to the reviewed genetic_correlation helper; optional labels/h2 are caller-supplied annotations. Lengths are checked; label uniqueness and finite h2 provenance remain explicit metadata debts.|

## Confirmed repair and numerical meaning

The finite identity G with raw beta=[1e200,0] returns Inf for the genetic index variance. G=diag([1e308,1e308]) with raw beta=[2,0] also returns Inf. Both mathematical variances exceed Float64 range. Returning them without a range refusal makes subsequent numeric summaries misleading. The proposal checks finite derived quadratic forms and response norm before returning, keeping moderate values, zero contrasts and admissible roundoff clamping unchanged. It does not add a practical scale cutoff or change covariance/condition acceptance.

## Evidence

Before every no-fit Julia1.10 launch, estimated below30seconds, one Julia and one BLAS thread, startup/compiled modules disabled. Original regression5PASS/2FAIL, exit1. Final proposal7/7 new plus18/18 existing stability controls PASS, exit0. Two intermediate standalone harness failures were missing explicit exports/imports in the reused test, not source defects; both logs are retained. Final imports include every unqualified existing symbol. No fit, optimizer, campaign, remote compute, GPU or full package test ran.

## Retained limits

The helpers describe G in supplied trait coordinates. Rotation invariance is only for latent rotations preserving G; trait units, distinct trait maps and close/repeated eigenspaces require interpretation. General inverse-metric uncertainty, estimated-G inference, conditioning beyond the explicit ceiling, underflow/cancellation accuracy and broad scale calibration remain debts. Optional plot annotations do not certify fitted heritability, trait ordering or provenance. Future label/h2 validation can be separately tightened; no new fit or R capability is implied by these plotting helpers. This proposal does NOT cover whole E1/A2/V3, recovery/calibration, GPU, capability promotion, submission or tag.
