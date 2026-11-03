# G2 K0 six-split method adoption

Date: 2026-10-07  
Decision owner: Arc 1 driver

I adopt the method amendment in `2026-10-07-g2-k0-six-split-followup-candidate.md`, SHA-256 `9b7f6c3e0b4c482126258000b87e1cac3fb882669ec0064c648d3ff821573d14`. Astra independently passed that exact proposal hash on 2026-10-07. The proposal freezes the six K0 starts, preserves the production 0.5 initialization, applies the better-unaccepted guard to both ranks, and restricts qualification to manifest-proven untouched development attempts with source-version-separated results.

Implementation may now proceed under that exact method specification. This adoption does not permit numerical execution before tests and exact-source review pass. Development runs must use only allocated cases proven untouched by the attempt registry and manifest. The exhausted N=80/null indices 1–30, all prior attempts, pilot seeds, and confirmation seeds are excluded from new tuning observations. No replacement seeds are permitted.

The G2/G3 thresholds, reference tolerance, optimizer cap, denominator rules, and R/Julia parity requirements remain as frozen. Pilot and confirmation remain held until the development and pilot qualification checks pass. This decision grants no gate credit or capability promotion.
