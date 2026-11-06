## 2026-10-09 G5 artifact/container map and raw-selection regression

Current-source Julia `test/arc1_simulation_executor.jl` passed 194/194 executor, 10/10 admission, and 15/15 diagnostic identity checks. Log: `/private/tmp/arc1-container-julia-current-source-rerun.log`, SHA-256 `a8edd5e20650970f8adfa8e047e5b90e9cf6cdacf14feb4e70cd425f7d76fd3d`. Exact test hash: `35b50b7ae1b67bac2c3a3c5fdad64360869016a34259b4cd4aafd7ac40ec9b8b`; executor source hash: `484cff8b70c71931df3c5e392bb85d6456583a862bf07c91e4d6929b65ffd812`.

Canonical Python adversary suite passed 55 tests in 705.682 seconds. Log: `/private/tmp/arc1-receipt-adversaries-current-source.log`, SHA-256 `8df45004b30b304066aabb0c7ada696be345ae6c49bdc20abad0847c352d2a31`. Test hash: `4449126f21077400897d321216ae464f7639c1d997f79cce15dd2d77fff571be`.

The suite initially found one stale generated historical-source-audit mismatch. The canonical `arc1_manifest.write_manifest` refresh changed only `historical_seed_audit` compared with a generated temporary candidate; the isolated failure then passed 1/1, and the full suite passed on rerun. Manifest SHA-256 after refresh: `ce2e03d79628da5769a4c7ef2e5a2f53a92b3c7a400fe5255e9bd34d5ecc7cac`.

Astra passed the partial source map at `docs/dev-log/source-review/2026-10-09-g5-authoritative-container-field-check-map-v5.md`, SHA-256 `7272f73738207968823b8aeadfaf6a2cc8b35e0ff6289f4a1070ef20de52272a`. This is source/receipt mapping only; G5 remains open. The legacy 130,851,693-byte artifact inspection approach and performance evidence remain open. No campaign, gate, seed allocation, denominator, public status, or covered-count change.

After-task R structure validation passed; the acceptance-ledger stage returned UNMET for the still-open Arc 1 gates. The evidence promotion check passed for 8 registered claims. No gate was marked abandoned.

After the coordination/checkpoint changes, the manifest writer regenerated the source audit and `verify_manifest` passed. Final manifest SHA-256 `55c099e7bbf4be1dacfe0c69cf61e7c278b54a475ed8cfc2caddb787386c0d3a`. The isolated historical-audit test passed 1/1 again; log `/private/tmp/arc1-historical-seed-audit-closeout.log`, SHA-256 `961e7ae1e17ac71eb38cc7e1ba23540a21924e60254e778ea1e94b2ac3319434`.

After-task report: `docs/dev-log/after-task/2026-10-09-g5-container-map-and-regression.md`.
