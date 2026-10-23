# Selected-inverse failed-factor guard

TDD red reproduced a partial sparse CHOLMOD factor from a singular matrix (`check=false`); `takahashi_diag` returned nonfinite output without throwing. The guard now checks finite stored values, a diagonal entry in each column, and finite positive diagonal pivots. The focused trace/selected-inverse file passes 30/30. Julia 1.10 `Pkg.test()` passed and ended `Testing HSquared tests passed` on the final source/test bytes.

Source/test hashes and remaining review limits are in `docs/dev-log/source-review/2026-09-29-selinv-factor-guard.md`. Project/Manifest compatibility warning retained; no resolve/update. Independent exact-current Gauss follow-up is pending. E1, A2, V3 remain open.
