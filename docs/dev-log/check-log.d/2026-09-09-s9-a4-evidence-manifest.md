# Check log — 2026-09-09 S9-A4 source-inert supersession

- Candidate pins: Julia `4d4a55c14c9234270979a76c53888d65634a6eaf`; R
  `fd2825795d3d481311912d29f3c377f2897d321d`.
- Dedicated validator checks the exact pins, all eleven governed hashes, the
  historical S9 manifest digest, clean R candidate, Julia source-inert path
  allowance, all-false action/result state, and exit-78 refusal fence.
- Dedicated test executes the positive check plus rejection mutations for
  compute authorization, Julia pin, legacy digest, governed hash, and an
  unknown manifest field.
- No simulation, remote action, promotion, or release was run.
