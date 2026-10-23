# Independent current-source FA comparator and measured-limits review

Date: 2026-09-30. Verdict: **PASS for this exact-current one-fixture informed-start comparator and source-level measured-limit wording**. The comparator provenance gap in the earlier final-panel disposition is closed by fresh current-source evidence. Whole A2 remains HOLD for remaining engine/R-route review spans, source wording cleanup and whole-wave panel signoff. Rose's final claim audit remains separate.

## Artifact integrity and pins

Retained packet: `docs/dev-log/recovery-checkpoints/fa-same-model-exact-20260930/` in `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`.

| Artifact | SHA-256 |
| --- | --- |
| Full artifact manifest | `06ac14abb62d6e55a4674c8a436e8905b9b2b43a0a29a03e7f183d9229ef53ed` |
| Run pins | `7aac20e52977f4110d37cfb72124cfe1900be3fea8fe8d1fa226a607c02fe622` |
| Receipt | `629620197a9004066cd2450cf91c273b2c6df1f10ab986952e23735322d2c70c` |
| Frozen source tree | `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` |
| Current multivariate source | `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670` |
| Response CSV, same historical fixture | `f5ddfd9b0783ac80b87f6135b5e43dde4a0f7748c968ca534d31215b8702a467` |
| R fit script | `3d02e1852c51bfb9fc9ef98389b02dd3352bb6369bfbc48dc78c5138b87dea52` |
| Julia fit script | `7cb16fa2fd17b2ae6c0455708310faf6004a1d99209faba3f40e2eadf6afbd4c` |
| R crosscheck script | `faac3dc7c6ec189ad731614a22c4b8eb3d01f04c9bf307b5e584f7246523f051` |

Every artifact manifest entry and run-pins file hash independently matches, including all inputs, fitted matrices, parameters, EBVs and logs. Replacing the isolated output directory with /private/tmp in each of the three scripts reproduces its original-script-pins hash exactly. Thus their only adaptation is the path change. The response hash also matches the earlier fixture pin. Local source tree was recomputed after review and remains frozen; parent HEAD 6271cfd5 is the announced source-neutral checkpoint.

## Model and stacking audit

The fixture has 12 pedigree animals, two complete records per animal, four Gaussian traits and trait intercepts. Both fitted models use G=λλ′+diag(ψ), rank one, absolute ψ floor 1e-4 and unstructured positive-definite R. R uses ψ=1e-4+exp(parameters); its residual lower-Cholesky parameterization and Julia's informed initial pair represent the same covariance model. Both start from the identical generating covariance pair; their different optimization algorithms do not make this an ordinary-start comparison.

R stacks y=as.vector(t(Y)) in record-major order. D=1_n⊗I_4, Zfull=Z⊗I_4, genetic covariance A⊗G and residual covariance I_n⊗R give V=(ZAZ′)⊗G+I_n⊗R. Its full REML objective includes (N-p)log(2π), log|V|, log|D′V⁻¹D| and the GLS residual quadratic. The crosscheck reconstructs GLS beta and genetic BLUPs using that same record-major model, then maps the effect vector back to animal-by-trait rows for Julia EBV comparison. These equations and mappings match the bounded current-source likelihood checked earlier; no new broad derivation was required.

## Logs and independent no-fit reproduction

The retained R log records convergence code 0, 171 function/90 gradient evaluations, R 4.6.0 and 1.013 seconds. It prints a rounded likelihood; the full R value is recovered from the fitted CSVs by cross-evaluation. Julia log records version 1.10.0, convergence true, 5500 iterations under the 10000 cap and 2.453628208 seconds. The failed first Julia launch reports an unavailable channel before loading/fitting; it is retained and is not a failed fitted attempt replaced by the later run.

Estimate before the independent crosscheck: under one minute, OPENBLAS_NUM_THREADS=1. Copied CSVs and a path-adapted crosscheck ran under Rscript --vanilla in `/private/tmp/e1-fa-current-comparator-audit-20260930`, exit 0, whole command about 0.34 seconds. No optimizer, response generation, new Julia process or refit ran. The independent crosscheck log is byte-identical to the retained log.

| Comparison | Result |
| --- | --- |
| R REML at R fitted pair | -149.673026622690 |
| R REML at Julia fitted pair | -149.673015078209 |
| Julia evaluations at both pairs | Match the corresponding R values to printed precision |
| Maximum absolute G difference | 7.2490748e-6 |
| Maximum absolute R difference | 1.5803251e-5 |
| Independently reconstructed EBV at Julia pair | Maximum difference 3.219647e-15 |
| EBV difference between fitted pairs | 1.790407e-5 |
| h2 difference between fitted pairs | 5.812434e-6 |

Both fits have uniqueness estimates near the absolute floor. This packet establishes objective/covariance/EBV agreement at the represented local solution. It gives no global optimum, regular inference, broad recovery, external-package parity or calibration guarantee. The original 200-seed ordinary-start study retains its separate pedigree DGP, 5000 cap and full denominator.

## Added R article claim consistency

Current candidate articles reviewed: `/private/tmp/hsquared-fa-gllvm-20260927/vignettes/articles/current-limits.Rmd:133–145` and `multivariate.Rmd:279–300`, with its existing boundary at 262–275,304–308.

Article snapshots: `current-limits.Rmd` SHA-256 `ffa1e30ca62767c9815d27af88976c591ee16ea8bc6ab8431c82bd04a8ed3bba`; `multivariate.Rmd` SHA-256 `60168da9381732694c90c7401008bfddc74ec2ee2948ef25bbe1942da096f632`.

The new wording correctly reports 200 attempts, 141 converged, 110 recovered, 59 nonconverged, 20 G-error and 11 R-error classifications. The 55% fraction, 3.52-percentage-point MCSE and rounded Wilson 48.1%–61.7% interval agree with the retained primary summary. Its 60-animal/three-record complete T4/K1 pedigree DGP, intercepts, unstructured residual covariance and two ordinary starts capped at 5000 each match frozen driver metadata.

Thirteen near-floor flags including six recovered rows, and two better-nonconverged flags including one recovered row, are reported without exclusion. The articles retain no overall pass cutoff, diagnostic-only interpretation of nonconverged output, and limits on optimizer reliability/coverage. Separate founder-fixture unit/order checks and the informed-start same-model comparator are scoped to their own fixtures. The full fitted G includes uniqueness; low-rank covariance alone is not used for trait genetic summaries. Experimental/partial labels and public count seven remain explicit. No claim inconsistency found in these additions. This review checks source wording only; rendering/live-page inspection and Rose's final audit remain separate.

## Disposition

The prior missing old-source blob no longer blocks comparator provenance: this new packet is pinned directly to current d3/fc41 and reproduces the comparison on the exact historical input. Preserve the earlier report as the chronology and treat only its comparator-provenance hold as superseded. Scientific A2 diagnostic closeout remains bounded PASS; whole A2 continues HOLD on its remaining review/signoff obligations. No covered-status, release, inference-calibration or broad fitting approval follows.

All writes are confined to this report and the authorized copied no-fit crosscheck directory. No live candidate, article, campaign or source edits occurred. Existing exact context sufficed; no new Graft query was needed.
