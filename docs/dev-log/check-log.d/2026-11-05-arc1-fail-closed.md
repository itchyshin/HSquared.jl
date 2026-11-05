# Arc 1 temporary execution pause checks

- `python3 test/test_arc1_launch_refusal.py -v`: 6/6 passed locally after a
  failing pre-change run. No executor was invoked.
- `python3 test/test_arc1_execution_scope.py -q`: 5/5 passed locally.
- `python3 test/test_arc1_diagnostic_cells.py -q`: 13/13 passed locally;
  four internal synthetic tests mock the new refusal.
- Julia 1.12.6 no-fit CLI check: 6/6 assertions passed; the unmodified command
  refused missing input and forged engineering-probe mode without output.
- A fake-engine subprocess passed on an isolated copy with the refusal removed
  for that test only. It does not exercise the production CLI's launch path.
- Local pilot and receipt checks have the fixture and historical-collision
  limitations described in the after-task report. Full package CI is pending.
