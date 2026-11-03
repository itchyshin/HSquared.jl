# Arc 1 G1 retained-verifier inventory parity

Date: 2026-10-05  
Lane: Codex Arc 1 runner, branch `codex/arc1-gaussian-reliability-20261002`  
Scope: test-harness consistency only. This does not constitute a G1 scientific run.

## Change

The synthetic retained-receipt adapter now includes `test/arc1_fa_v2_contracts.jl`, matching the current oracle runner's nine-suite order. A regression assertion compares the adapter fixture to `tools/arc1_oracles.py::JULIA_TESTS` exactly. The pinned production verifier source was left unchanged.

## Evidence

- Test-first failure: `python3 -m unittest discover -s LOOP/lanes/arc1-gaussian-reliability-20261002/tests -p 'test_verify_retained_checks.py'` failed because the synthetic receipt omitted the runner's v2 suite and therefore had an incomplete command list. The parity assertion also showed the test inventory had eight suites while the runner had nine, with v2 contracts second.
- After correction, the same command passed: 8 tests, exit 0.
- Full lane-local Python suite: `python3 -m unittest discover -s LOOP/lanes/arc1-gaussian-reliability-20261002/tests -p 'test_*.py'` passed: 8 tests, exit 0.
- Oracle adversarial self-test: `python3 tools/arc1_oracles.py --self-test` passed and ended with `ARC1_ORACLE_SELF_TEST_PASS`.
- `python3 -m py_compile` on the verifier and test passed.
- Scoped `git diff --check` passed.
- A Luna read-only check confirmed both nine-entry inventories match in order, including the v2 suite at position two.

## Source identities

- `verify_retained_checks.py`: `038cd1ecaad86a06a334503eeab680c8a25cdfd51e2b20323c8011c0a63a4854`
- `test_verify_retained_checks.py`: `19aa87832f30d7db63bb3ffad16934d8a362780ff68d5a5fcbe39b5ce1ae37e9`
- Read-only oracle runner `tools/arc1_oracles.py`: `d9e18d06765d220925251e3208ced2cbdca53a17236496d0d7d6803434e8435c`
- The unchanged verifier still matches the source hash pinned by the locked GATES checks: `b9dd0269d7c00f1be7c3663514b2a4f9f547c7082d3990c5db7ee3c3b80871a6`.

## Limits

This repairs the verifier's ability to model the current G1 receipt. It does not produce a reviewed source freeze, validate a scientific G1 run, admit a pilot, close G0 or G1, or establish any R parity or calibration result. All Arc 1 acceptance gates remain open. No public claim or capability status changed.
