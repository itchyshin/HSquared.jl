# Independent retained-result review: G2 v17 outer33

Review scope: read-only consistency audit of the locally retained v17 N80/null outer33 result and retained-attempt receipt. This review does not confer gate credit or qualify G2.

## Identity and result

- Candidate SHA-256: `0efa941c2a6ae177012a03282bbeea03cd8bdd7dc8760165bcf23e7534324cd0`
- Source-lock SHA-256: `f4500848f22e1282c3f1db263fd528b6041603c585aa3780006a161854c737f2`
- Admission SHA-256: `f182cfbb91f0db5810ffd2a9deeab308e93c3982f3fda9839e98f85a7516b6c8`
- Cell, outer, seed: N80/null, 33, `11447647806120141284`
- Result JSON SHA-256: `b0da86cb3b854d5e3be212aa10ded52ef26e3a142188fe1180b42aeabbef1529`
- Retained receipt SHA-256: `8d38cd9f6277bd26504d7a17603ab59da7906bacc66ddc9d242a39ab5c88c776`

The admission identity matches in both files. The nested selector result reports `status=ok`, `success=true`, `eligible=true`, both candidates available, K0 selected, and 24/24 completed starts: six K0 and eighteen K1. The result records reference shortfalls 0 for K0 and approximately `1.14e-13` for K1, both below `1e-4`. The retained receipt records `complete_success`, rate eligibility, no gate credit, outer31/32/33 counted once in the 270-attempt denominator, and 267 attempts unrun.

## Source and review limits

The retained Totoro staging report records all 326/326 source pins matched at preflight. At review time the local worktree matched 324/326 because `checkpoint.md` and `coordination-board.md` had been updated after the frozen run. Thirty recorded loaded-engine hashes and the environment hashes match the frozen admission. The reviewer did not contact Totoro or independently rehash the remote binary and logs; claimed hashes agree across the local result and retained receipt.

## Conclusion

PASS for retained-result consistency only. This is one denominator-counted development observation. It does not establish ordinary K1 reliability, selection rates, G2 qualification, pilot qualification, confirmation, or any other Arc 1 acceptance gate.
