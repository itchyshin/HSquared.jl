# H3 genetic-correlation preflight source review

Reviewer: Astra, independent static review. Date: 2026-10-04.

Reviewed exact hashes:

- `sim/mv_h3_rg_screen_20261004.jl`: `7aedf158ff736807459fede3c52bde434f380105420b7f54a6a8e38ae6756f7c`
- `test/test_mv_h3_rg_screen_contract.jl`: `6e9f70b0ec751876a747d64b198be204674082874d0488d5293f5989988cc35f`

Decision: **ADMIT for source-only, non-executing preflight.** The selected-file pin set is no longer described as the complete loaded source closure. Receipts explicitly leave loaded-code identity, dependency resolution, seed allocation, and seed freshness unverified, require later fresh-process verification against an immutable bundle, and keep execution ineligible. Recursive versioned identity encoding and invalid timing-bound checks have adversarial tests. The omitted-source mutation test demonstrates the receipt's stated boundary.

This review admits neither a timing pilot nor a screen. It does not verify the full source/dependency closure, seed inventory freshness, attempt runner, interruption/resume behavior, or calibration. No tests, fits, simulations, or seed generation were run by the reviewer.
