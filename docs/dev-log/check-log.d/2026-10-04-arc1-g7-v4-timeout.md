# Arc1 G7 replay v4, 2026-10-04

The reviewed v4 source freeze ran all components sequentially. Julia `Pkg.test()` passed in 790.721 seconds. The mandatory-live R driver passed all six required files with zero failures, errors, or skips in 2,847.229 seconds: controls 109/109, parity 50/50, bootstrap-v2 20/20, profile-v4 85/85, uncertainty-controls 179/179, and uncertainty-live 173/173.

`R CMD check` reached package-wide `testthat.R` and was stopped after the 752.047 seconds remaining in the shared R budget. The runner recorded `timed_out=true`, process status `-15`, and process-group cleanup `terminated`. No assertion failure was reported before termination; the incomplete package check is not a pass. Because all three checks run sequentially and `R CMD check` also enables the same live Julia routes, the 3,600-second shared R budget was insufficient. The docs component did not run. G7 remains open.

Evidence directory: `.unlazy/arc1-gaussian-reliability/evidence/package-checks/20261004T152143Z-8c71269797/`.

| Artifact | SHA-256 |
| --- | --- |
| Run receipt | `47615e7c231fc4f44cac20622635d99b53ed4d945184afc704e4e14bf7040b8f` |
| Julia log | `7349ccdc9f3a0361c2b534d88e8997a0e4a4d3b90992b6553886a0b0785935c0` |
| Required-live R log | `2d1440325817fee7e44dafdc6ef01e57ff9f10ee8e4c32b8322abb4c92c810a1` |
| R CMD check log | `e02ec15117d42d907ac68942d4f2f5cc3cd384ea3550ea5009e9c06b8721354b` |
| Reviewed freeze | `3fafb4ea0924190387a1cf1aef9960eb3439ddd058271257857d54a2ed7b7fd8` |
| Independent v4 review receipt | `c7444dfff9d373f5a0982193d54dd1929d2451087fbeab666e73b406c092bffe` |

The runner timeout-floor regression was raised to 7,200 seconds using test-first verification: the self-test first failed on its new floor, then passed after the shared R cap was raised. The next source freeze requires a fresh independent review before another canonical replay. Its estimated full G7 elapsed time is approximately 85–145 minutes, below the three-hour approval threshold; the package-wide R check duration remains uncertain.
