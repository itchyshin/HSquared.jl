# GLLVM trait-order result contract, 2026-09-29

The full Julia `Pkg.test()` passed before the final Unicode separator
regression cases were added. The focused GLLVM trait-effects test file passed
after those cases, including 34 assertions in the Poisson T3/K2 ordinary-
restart testset. R's live `gllvm-optin` bridge filter passed 87 assertions with
zero failures, warnings, or skips after numerical trait-permutation checks
were added. Trait names preserve caller response order; the R normalizer
rejects missing or mismatched returned names. Capability status remains
unchanged. See
`docs/dev-log/after-task/2026-09-29-gllvm-trait-order-contract.md`.
