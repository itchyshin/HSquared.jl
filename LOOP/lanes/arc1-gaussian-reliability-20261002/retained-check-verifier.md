# Retained G1/G6/G7 check verifier proposal

This is a proposed Unlazy binding for already completed package checks. The verifier only reads retained receipts and files. It does not launch Julia, R, docs, or model fits, and it does not edit `GATES.md` or approve a gate. Its success markers mean only that the named retained check is internally bound to the externally supplied receipt and freeze hashes, current source inventories, exact runner commands, and retained outputs.

Run from the HSquared.jl repository root. The exact receipt and freeze SHA-256 values must be reviewed independently and supplied explicitly. A copied receipt with a changed hash, a stale freeze, or a current source mismatch refuses with exit 1 and no success marker.

## G1: focused Julia objective and contract tests

Receipt: `.unlazy/arc1-gaussian-reliability/oracles/runs/20261003T042838Z-758ac22910f4/run.json`  
Receipt SHA-256: `c01b27f473de72e20b69eb1e4325f1f4dc475073f7373d75c4cbefa79908e809`  
Freeze: `/private/tmp/h2-arc1-oracle-freeze-20261003-final-package.json`  
Freeze SHA-256: `520b89a2bf1029453287582a26e51fc5c0e82858046cd2b9afb21e2450efdbaa`

```sh
PYTHONDONTWRITEBYTECODE=1 python3 LOOP/lanes/arc1-gaussian-reliability-20261002/verify_retained_checks.py \
  --gate G1 \
  --receipt "$PWD/.unlazy/arc1-gaussian-reliability/oracles/runs/20261003T042838Z-758ac22910f4/run.json" \
  --receipt-sha256 c01b27f473de72e20b69eb1e4325f1f4dc475073f7373d75c4cbefa79908e809 \
  --freeze /private/tmp/h2-arc1-oracle-freeze-20261003-final-package.json \
  --freeze-sha256 520b89a2bf1029453287582a26e51fc5c0e82858046cd2b9afb21e2450efdbaa
```

Expected marker: `ARC1_G1_RETAINED_RECEIPT_VERIFIED`.

## G6: mandatory live R/Julia bridge checks

Use the same completed package `all` receipt and freeze as G7 below. The retained R driver names exactly the four mandatory Arc1 test files, and the receipt binds its command, thread limits, CSV/RDS outputs, JuliaCall bootstrap copy, and source before/after snapshots. This does not rely on the older standalone G6 oracle receipt, whose R-help pins predate the current package freeze.

Expected marker: `ARC1_G6_RETAINED_RECEIPT_VERIFIED`.

## G7: full local package, R, and documentation checks

Receipt: `.unlazy/arc1-gaussian-reliability/evidence/package-checks/20261003T041019Z-c04d832d1f/run.json`  
Receipt SHA-256: `8f4c6eec9b0177b5cafc6a89860fbe663a5e1e3f188fb875e8694f41090be21d`  
Freeze: `/private/tmp/h2-arc1-package-freeze-20261003-html-v3/freeze.json`  
Freeze SHA-256: `a38f51cfc53e26fe4e1b8a721e37df3da8046513ec0f58d8f4d5ab8c211fe774`

```sh
PYTHONDONTWRITEBYTECODE=1 python3 LOOP/lanes/arc1-gaussian-reliability-20261002/verify_retained_checks.py \
  --gate G7 \
  --receipt "$PWD/.unlazy/arc1-gaussian-reliability/evidence/package-checks/20261003T041019Z-c04d832d1f/run.json" \
  --receipt-sha256 8f4c6eec9b0177b5cafc6a89860fbe663a5e1e3f188fb875e8694f41090be21d \
  --freeze /private/tmp/h2-arc1-package-freeze-20261003-html-v3/freeze.json \
  --freeze-sha256 a38f51cfc53e26fe4e1b8a721e37df3da8046513ec0f58d8f4d5ab8c211fe774
```

Expected marker: `ARC1_G7_RETAINED_RECEIPT_VERIFIED`.

Final read-only verifier stdout is retained under `/private/tmp/arc1-retained-verifier-final/`: `G1.log` SHA-256 `4f7f076e2fe029d6adc3d3b3ebbaf036cc54fda478695c2eb49c3d3d0c24b322`, `G6.log` SHA-256 `9759d4d32072d45b7a2bf90aeb3c561eb9cb408a73e8ac81fc4344c2077fd7ac`, and `G7.log` SHA-256 `2e03ac424a10fb2748abc2b428a7a3a49392629ee6e154faccf3ab47f3afe269`. Each contains only its expected success marker.

## Proposed binding shape

Verifier SHA-256: `ece090c5d902d6551f73201153c77429997ec088161e22fa93220e79920d2d89`.

Because `LOOP/` is intentionally outside the package input inventory, every Unlazy CHECK must bind this helper itself before invoking it. Use the following guard immediately before each command above (then require exit 0 and that gate's success-only marker):

```sh
test "$(shasum -a 256 LOOP/lanes/arc1-gaussian-reliability-20261002/verify_retained_checks.py | awk '{print $1}')" = ece090c5d902d6551f73201153c77429997ec088161e22fa93220e79920d2d89 || exit 1
```

Store the external receipt/freeze hashes above in the reviewed authorization entry rather than reading them from the candidate receipt itself. A mismatch, helper-source drift, nonzero verifier exit, or absent success marker is a failed check. Do not use this helper to change approval records automatically.

G2–G5 remain unbound. No scientific receipt bundle or independent study pin set was supplied for these checks. G7's real full-package run passed Julia, R, and docs; earlier G7 attempt `20261003T023112Z-fd216a1d63` failed and is not accepted by the verifier. The G1/G6/G7 markers do not qualify scientific gates, authorize confirmation allocation, or change the frozen 400-run allocation hold.
