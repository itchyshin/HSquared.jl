# Final evidence oracle review, revision 3

## 1. Request and verdict

Bounded PASS for the revised acceptance-oracle contract and the specified mutation controls. Reports from revisions 1 and 2 remain preserved. This verdict approves the checker logic exercised here; actual completed evidence and its final manifest still require byte attestation before any programme success claim.

## 2. Scope and independence

Reviewed all 122 lines of the checker at the exact revision below. No fits, builds, package tests, live writes, or numerical-source edits were run. Prior numerical input/identity authorship is acknowledged; the reviewer did not author the acceptance checker.

## 3. Exact reviewed pin

`check_final_programme_evidence.py` SHA256: `2a404a0a2bb478b5f45bced92993a3c8193196f92f322f5f820fa892b26e0c4d`.

Copied checker and owned evidence: `/private/tmp/hsq-final-oracle-independent-probes-r3-20260930`. The copied bytes matched the parent scratch checker during final pin measurement.

## 4. Finding dispositions

Every reproduced revision-1 false acceptance and all four revision-2 residual cases now reject. The documentation source set must equal discovered docs/src files plus docs/make.jl. Current docs/Project.toml and docs/Manifest.toml receive separate exact hash checks. Package command and bridge command/project/thread contracts are checked before success tokens are printed.

## 5. Execution environment normalization

Read current and execution-copy docs TOML files independently. The only semantic Project difference is sources/HSquared/path: the current historical absolute path becomes '..'. The only semantic Manifest difference is deps/HSquared/0/path: the current candidate location becomes the execution-copy location. All other values, including dependency entries and versions, agree. The comparison is recorded in docs-environment-comparison.json. Current environment hashes and execution-copy artifact hashes serve separate purposes; byte equality between these intentionally normalized files is not required.

## 6. Meaningful valid controls

The complete fixtures include source, nested tests, runner, Project/Manifest, source-freeze UTC, successful result starts after freeze, exact package and bridge commands, one-thread metadata, all consumed artifact pins, five named Julia/R HTML pages, complete R input groups, complete documentation sources, and separate current documentation environment hashes. All three normal scopes and the complete Julia scope under Python optimization return their exact expected standalone token with exit zero.

## 7. Negative controls

Thirty-one rejection cases cover changed source, nested test, documentation, result, log, Julia HTML, R HTML; added source/test/docs; zero source/test inventory; omitted mandatory pins; Boolean exit status; absent timeout state; infinite elapsed; malformed time; package predating freeze; empty terms; missing named R page; omitted changed documentation; changed current docs environment; wrong package command; wrong bridge project/command; wrong bridge command alone; wrong bridge threads; and changed source under python -O. Every rejection returns nonzero exit and empty stdout.

## 8. Run accounting and retained attempt

Estimated under ten seconds per no-fit batch. Final replay elapsed about 3.33 seconds: 35 controls, four valid acceptances and 31 refusals. Initial 31-case replay also passed. Re-entering the synthetic fixture generator then included its previously created manifest as an artifact, causing a self-hash failure. The failed command output and original fixture script are retained; the generator now excludes its own manifest. No checker correction was needed for that fixture error. Full outcomes are results-additional.json and additional-final.log.

## 9. Manifest and installation requirements

Parent should install these exact reviewed checker bytes and freeze the completed logs, results, current source/test inventory, R log copy, current documentation inputs/environments, and latest rendered HTML. Preserve package-doc-freeze normalization by stripping exactly the first R/ prefix. This review does not attest an unfinished or separately regenerated final manifest. Run each installed scope and require both zero exit and its exact standalone success token.

## 10. Remaining boundaries

This review does NOT cover numerical calibration, CI, deployment, a new capability claim, or visual inspection of every page. Rendered term checks are text-presence checks. Trusted manifest construction and truthful execution receipts remain prerequisites. The parent's reported completed package run is not independently rerun here.

## 11. Preservation, Memory receipt, and Golden Set

Only owned revision-3 fixtures and this report were written. Earlier reviews, original package assertions, live evidence, and other lanes were preserved. Memory receipt: inherited checkout preservation guidance only; current source and deterministic probes establish this verdict. Golden Set: complete valid fixtures were retained throughout refusal testing.

## 12. Style and final disposition

Absolute-path slopcheck accompanies the packet. No em dashes appear. All specified false-pass paths now refuse, including optimization mode. Bounded checker-contract approval is PASS at the exact pin in section 3; full programme evidence attestation is the parent's next step.
