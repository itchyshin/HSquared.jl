# Retained package-check evidence

This note records the current bounded package checks for Arc1. They establish successful component execution on the named frozen inputs. They do not close any scientific acceptance gate, authorize studies, or support capability promotion.

## G1 focused component

- Run: `.unlazy/arc1-gaussian-reliability/oracles/runs/20261003T042838Z-758ac22910f4/`
- Receipt SHA-256: `c01b27f473de72e20b69eb1e4325f1f4dc475073f7373d75c4cbefa79908e809`
- Reviewed freeze: `/private/tmp/h2-arc1-oracle-freeze-20261003-final-package.json`, SHA-256 `520b89a2bf1029453287582a26e51fc5c0e82858046cd2b9afb21e2450efdbaa`
- Result: passed in 154.782 seconds on the current reviewed Julia source. The eight retained `ARC1_TEST_COUNTS` records report 70, 217, 951, 154, 38, 35, 148, and 65 passes. Their sum is 1,678; each record has zero failures, errors, and broken tests. The count was independently parsed and asserted against the eight run logs.

## Combined G7 package checks

- Run: `.unlazy/arc1-gaussian-reliability/evidence/package-checks/20261003T041019Z-c04d832d1f/`
- Receipt SHA-256: `8f4c6eec9b0177b5cafc6a89860fbe663a5e1e3f188fb875e8694f41090be21d`
- Reviewed freeze: `a38f51cfc53e26fe4e1b8a721e37df3da8046513ec0f58d8f4d5ab8c211fe774`
- Result: all selected components passed, total elapsed time 977.84 seconds. Julia `Pkg.test()` passed in 522.951 seconds; required-live R parity passed 219 assertions in 77.704 seconds; R CMD check completed in 251.202 seconds with zero errors, warnings, and notes; the isolated local docs build completed in 30.751 seconds.
- The docs build rendered `1/validation-status.html` with SHA-256 `c77089c35f3903c2d4d7ea31d2e59824667f91571cd61f3fe76ca007e9f91506`. This is local rendering evidence only; no deployment occurred.
- Julia source was HEAD `dbba9c3a`; isolated R source was commit `37fdd90`. The run JSON records the component logs and input checks. Earlier failed G7 attempts remain retained as failures and are superseded only for the current package-check status by this later passing run.

## Scope and remaining status

The fresh G1 component and combined G7 package checks pass. The Arc1 ledger still has G0–G8 open. Package checks do not establish profile coverage, rank-selection reliability, calibration, or study performance.

Six authorized Totoro engineering timing cases completed in 308.84 seconds. Twenty-eight of thirty target intervals formed; residual variance (Ve) at N=160 and permanent-environment variance (Vpe) at N=320 remain unresolved in the near-zero-additive cases. These are engineering results, not allocated study outcomes. Astra's independent high-precision review found three candidate-certificate deficits of approximately `1.69891308e-8`, `1.42095406e-8`, and `1.53685648e-8`, each above the frozen `1e-8` certificate limit. No numerical policy changed. No allocated study or campaign has run, and no promotion or public status change is supported.
