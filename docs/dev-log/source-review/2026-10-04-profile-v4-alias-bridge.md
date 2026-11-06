# Profile-v4 history alias bridge review

Read-only independent review of the current Julia/R bridge-alias optimization and its Julia preflight-test correction.

## Result

The successful transport path is sound at the inspected source hashes. Julia reconciles existing histories, rejects malformed or conflicting values, then shares one vector under the v3 and v4 keys. The bridge omits the v4 duplicate only when requested and actual method identities both say `arc1_profile_v4` and Julia confirms the histories are the same object. R reconstructs the public v4 key, validates the evidence, and removes the private verification marker before returning public data. The live fixture and full nested fixture check restored fields and parity; conflicting aliases remain rejected.

The Julia test correction is valid: v4 sink setup occurs before ID validation, so a deliberately invalid ID list tests sink initialization without running the expensive profile. At that point the requested method and shared aliases exist, while actual method identity is correctly absent.

## Source pins

- Julia `src/arc1_interfaces.jl`: `26e9e17ed2ef4261cf21910d9b2ff3c13ed2f1342a01f23976feb9a59ea832ac`.
- Julia `src/arc1_profiles.jl`: `1ea5352533d5827af6a857be269984ca8ba4f9ad9dbda03950078d6253d759f2`.
- Julia `test/arc1_interfaces.jl`: `af56173075eba3e9e511133c1e594afb94ee23d44c4df4ef1717ecb27912485a`.
- R `R/julia-bridge.R`: `8f3b5e293bf0ec2a0ab9a27dc51bceaf38e45799a48692a8d09bf1fab9d38846`.
- R `R/arc1-uncertainty.R`: `f3dcb889b145296ca22e3705410187e0c35729487647e69317170fba6ea37586`.
- R `tests/testthat/test-arc1-profile-v4-live.R`: `6e14114dcc1252eaaedd365cdcc8bdce4cca350ba600c9ba5b1fb3ab0a68469a`.
- Required-live receipt: `.unlazy/h2-nongpu-completion/evidence/arc1-profile-v4-alias-optimized-required-live-R-pass-20261004.md`, SHA-256 `a204f55244893b2cade6d2bea1b1482d6e45f61d193cf861566a60f519aadaf8`.

The receipt pins the Julia interface and profile sources, but not the changed Julia interface test. The full package replay separately pins that test and passed with exit code 0. The live R run itself does not establish that Julia test.

## Remaining issue

On an R bridge error or interruption, the failure reader still reads and validates the full dual-history sink without using the success projection. This preserves strict failure evidence but may incur the former duplicate-conversion cost on that path. No correctness blocker was found in the successful optimization. This technical bridge review does not replace the pending Astra scientific review, close G6, or establish project completion.
