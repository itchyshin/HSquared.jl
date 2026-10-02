# Existing multivariate warning-fixture diagnosis

The corrected full R check activates the current Julia worktree and removes all seven stale-engine bridge errors. It has 3866 passing assertions and one failure at test-multivariate.R532. That regression requires the later observed-information non-positive-definite refusal text.

One exact-fit reproduction (n8, two traits, one missing response, 400 iterations) produces converged=false and one uncertainty warning. The actual recorded Julia reason is: multivariate uncertainty requires a fit with converged = true. No SE fields are returned. The current convergence guard (src/multivariate.jl313-316) precedes information formation and positive-definiteness checks (1667-1695). The bridge still records and surfaces the error; no missing-warning or computable-SE conclusion follows.

The deliberate regression repair accepts only those two specified refusal reasons and still requires the warning. It does not accept arbitrary warnings, suppress warnings or fabricate SEs. Runtime code and the numerical fixture are unchanged. The R test producer owns that single existing test path after parent preflight and lease expansion. Focused and full R replay remain required.
