# H3 G0 supersession — check log

- The unarmed H3 card moved from source basis `4d4a55c` to tested candidate
  `82f836f3` after the convergence-accounting correction.
- The manifest now pins the new driver SHA-256
  `6c1b74cc207247241e395bd78143c07f01b0091682d3049e57bfdbb1a8d0401d`
  and environment lock SHA-256
  `a3d4803f05af9738bc5796b1534bdb3249a263efb6c618cae6088d3f0c7ce221`.
- `test/test_hsq09_h3_g0_manifest.jl` and the validator mutation self-test
  pass after the supersession.
- All authorization fields remain false.  No compute or public-state action
  occurred.
