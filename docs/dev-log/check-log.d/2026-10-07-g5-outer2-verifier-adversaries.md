# G5 outer-2 verifier adversarial tests

Command: `python3 -B LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n320-dev-prerun-v2/test_verify_outer2_attempt.py`

Result: 26/26 passed. Log SHA-256: `3c05a47b38cbf2345ce8c8858d107add5330f908c1986f4b06e163feb6595ca0`.

The suite runs synthetic records through the outer receipt verifier, uses the real `verify_execution_identity`, and stubs scientific interval and profile-evidence validators. It proves wrapper guard behavior only. No model fit or study attempt ran; no G0-G8 status changed.
