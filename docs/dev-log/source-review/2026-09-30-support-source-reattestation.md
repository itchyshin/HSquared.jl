# E1 support-source reattestation, 2026-09-30

## Scope and verdict

This is a read-only reattestation of the support-source byte comparison and recorded review dispositions for `src/HSquared.jl`, `src/backends.jl`, `src/control.jl`, `src/model_spec.jl`, `src/plotting_ext.jl`, `src/postfit.jl`, `src/sparse_bridge.jl`, `src/gpu_ext.jl`, `src/errors.jl`, and `src/planned_terms.jl`. It covers exact bytes and reconciles existing component receipts. It is not a final E1 panel acceptance, full E1 approval, new numerical review, fitted-capability approval, public-status approval, or release approval.

At candidate HEAD `9c10f09c1bdc7f7ab19cb07c339d1dc83179f429`, I independently SHA-256 hashed the exact current bytes of all ten source files and counted their lines. The results match every recorded current hash and line count in `docs/dev-log/source-review/2026-09-30-support-baseline-byte-comparison.json` (that inventory SHA-256: `fb0ad0047564f08bfed5f9dc14294ad07bdf409ef4b3b94ca412e15f5a6eb003`). Seven files match the historical baseline byte-for-byte; `gpu_ext.jl`, `errors.jl`, and `planned_terms.jl` differ from baseline and match their current component pins. Detailed independent pins are in `/private/tmp/e1-support-source-reattestation-20260930.json`.

The E1 reconciliation records source freeze `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` and source-neutral commits through the candidate HEAD above. No source files were changed for this reattestation. No Julia, R, GPU, fit, optimizer, benchmark, or generated-page runtime was used. Existing status labels, public covered count, and historical numeric results were not edited.

## File dispositions and boundaries

| Current file | Byte result | Reattested disposition and carried boundary |
| --- | --- | --- |
| `src/HSquared.jl` | 258 lines; equals frozen baseline | Wave 3 full-file scoped pass for include/export order and the inspected direct routes. It does not certify the fitters, new exports, R-Julia parity, or unreviewed neighboring bodies. Wave 3 whole-panel verdict remains HOLD. |
| `src/backends.jl` | 167 lines; equals frozen baseline | Wave 4 scoped pass for backend types, parsing and metadata. Paired `control.jl` review is conditional and limited to metadata contracts. `Threads` remains planned with execution unavailable; this is not evidence of threaded execution, accelerator execution, or performance. A deliberately custom backend subtype can still lead to `MethodError` in metadata conversion. |
| `src/control.jl` | 107 lines; equals frozen baseline | Wave 3 and Wave 4 scoped status/control review, plus 2026-09-30 contract review. `HSControl` stores backend and save metadata; backend selection is explicitly planned. The custom-backend edge above remains. The review did not benchmark or execute a threaded or accelerator backend. Its review receipt notes the hash was established on follow-up, so it does not claim byte identity before the first read; the current hash independently matches the inventory. |
| `src/model_spec.jl` | 104 lines; equals frozen baseline | Wave 3 complete-file structural pass, narrowed by the 2026-09-30 Henderson contract review. It is a dimension-oriented univariate Gaussian specification helper, not a fitted-input validity proof. ID uniqueness and order against relationship rows and `Z` columns are caller responsibilities; `y`, `X`, `Z`, and `Ainv` are retained by reference. Exported constructors can bypass helper checks, and numeric/symmetry/positive-definite validity depends on route-specific checks. No fitted animal-model validity or R-Julia alignment follows. |
| `src/plotting_ext.jl` | 61 lines; equals frozen baseline | Wave 4 complete pass for the stub and documentation scope. The `Makie` implementation is extension-owned and unreviewed here. No drawing-runtime approval follows. |
| `src/postfit.jl` | 58 lines; equals frozen baseline | Wave 4 historical delegate-scope pass is superseded as a current unconditional conclusion by the 2026-09-30 marker-scan findings. The exact-current wrapper/source component review records the unresolved failed-fit, zero-additive boundary, and positional row-order contract. A separate prepared repair now checks convergence, permits zero additive variance with positive residual variance, retains rejection of invalid variance inputs including negative values that underflow during conversion, and documents marker row order as matching `fit.spec.y` with no ID alignment. Its independent runtime controls include fixed-effect GLS oracle checks and both mixed and LOCO underflow controls. The patch is unapplied: live `postfit.jl` remains at the frozen hash, so integration is HOLD and must not be represented as a source fix or unconditional pass. Preserve the initial independent HOLD evidence. Dense experimental scanning and uncalibrated Wald p-values remain explicit limits. |
| `src/sparse_bridge.jl` | 87 lines; equals frozen baseline | Wave 1 complete static pass for CSC pointer endpoints, monotonicity, row bounds/order, and index conversion. No fresh real R-Julia sparse-bridge transport or parity evidence follows; that is separate integration evidence. |
| `src/gpu_ext.jl` | 90 lines; differs from baseline, matches current pin | Wave 4 static interface pass for generic declarations, weak-dependency wiring, and corrected `MethodError` wording. CUDA runtime/device agreement/performance are unverified and excluded from E1 completion criteria. No GPU call or completion claim is made. |
| `src/errors.jl` | 22 lines; differs from baseline, matches current pin | Exact-current complete-file scoped pass: unavailable-operation text identifies the specific route and points to capability status. Carried low-severity test gap: tests do not assert that the supplied operation appears in rendered `showerror` output. |
| `src/planned_terms.jl` | 359 lines; differs from baseline, matches current pin | Exact-current complete-file scoped pass and Wave 4 wording repair. Formula status is a grammar diagnostic; reserved formula-term stubs deliberately throw. Existing direct Julia utilities are named where available, while the R formula grammar remains closed. Fixed-rank FA remains an expert-control route; `cov=fa(K=k)` remains planned for the R formula interface; automatic rank remains a separate follow-on. Carried documentation/test debt: the adjacent grammar table calls itself the exact typed row while some displayed values differ from `formula_status()`, and existing tests do not compare every row/enum. |

## Whole-review status

Wave 1, Wave 3, and Wave 4 each record HOLD for their whole review/panel scope. The per-file passes above retain their stated scopes and do not close those holds. The exact-current reconciliation still requires final independent panel acceptance and findings disposition. GPU runtime is not a prerequisite. Source unchanged status does not imply a passed integration, fit, calibration, R-Julia parity, or public capability gate.

## Evidence pointers

- `docs/dev-log/source-review/2026-09-27-wave1.md`
- `docs/dev-log/source-review/2026-09-27-wave3.md`
- `docs/dev-log/source-review/2026-09-27-wave4.md`
- `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`
- `docs/dev-log/source-review/2026-09-29-errors-planned-terms.md`
- `docs/dev-log/source-review/2026-09-30-model-specification-contract-review.md`
- `docs/dev-log/source-review/2026-09-30-backend-control-contract-review.md`
- `docs/dev-log/source-review/2026-09-30-postfit-marker-scan-review.md`
- `docs/dev-log/prepared-fixes/2026-09-30-postfit-marker-contract/receipt.md` and `hashinventory.json`
- `docs/dev-log/source-review/2026-09-30-e1-current-coverage-reconciliation.md`

The independent SHA and line-count inventory is `/private/tmp/e1-support-source-reattestation-20260930.json`. This report records current component reattestation only; the final E1 panel acceptance remains owed.
