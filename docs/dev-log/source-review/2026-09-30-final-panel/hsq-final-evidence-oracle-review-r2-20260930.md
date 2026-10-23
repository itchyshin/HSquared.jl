# Final evidence oracle review, revision 2

## 1. Request and verdict

HOLD pending four residual evidence-binding corrections. Revision 1 remains untouched at `/private/tmp/hsq-final-evidence-oracle-review-20260930.md`. The revised checker closes the earlier inventory, artifact, rendered-page, and result-schema defects exercised here.

## 2. Scope and independence

Read all 113 lines of the revised acceptance checker and exercised it in an owned synthetic evidence package. No fits, builds, live writes, or numerical-source edits were run. Prior numerical input and identity authorship remains acknowledged; the reviewer did not author this acceptance checker.

## 3. Exact source pin

Reviewed `check_final_programme_evidence.py` SHA256 `55a6b55f9bdfddf3b7c5c7e9ddf0e8560b5ac66badfc6ee7f40b3b3cc372c8cb`. The live scratch checker still matched the copied reviewed bytes at the end of probing. Owned package: `/private/tmp/hsq-final-oracle-independent-probes-r2-20260930`.

## 4. Closed findings

All seven false acceptance cases from revision 1 now reject when fixtures conform to the revised schema. The checker requires discovered source/test Julia files, Project/Manifest/runner pins, all consumed result/log/freeze/HTML pins, nonempty terms, required named Julia and R pages, integer zero exit status, explicit false timeout status, finite positive elapsed time, and parseable start time. Package evidence must start after its source freeze. Unconditional require calls remain effective under Python optimization.

## 5. Residual documentation inventory defect

The documentation inventory is checked only for named file hashes. Omitting docs/src/b.md from a complete valid fixture's inventory and changing that omitted file still prints DOCS_PASS with exit zero. Require equality with the discovered documentation source inventory, plus docs/make.jl. Missing files, added files, and deleted files must invalidate the corresponding docs receipt.

## 6. Residual environment-binding defect

The checker pins evidence copies named docs-Project.toml and docs-Manifest.toml but never compares them with the current root's docs environment. Changing root/docs/Manifest.toml still prints DOCS_PASS. Require digest equality between those artifact copies and root/docs/Project.toml and root/docs/Manifest.toml, or include the current environment files in an exact complete documentation input inventory with checked matching copies. Pinning the old copy alone does not bind it to the supplied current root.

## 7. Residual command and project defects

Re-pinning a live bridge result whose project is /different/project and whose command is unrelated still prints R_BRIDGE_DOCS_PASS. Re-pinning a package result whose command is unrelated still prints JULIA_PASS. Require the expected package Pkg.test command shape and the expected bridge test filter/stop-on-failure command, and require the bridge result project to resolve to the supplied root. Record or validate explicit operation identities for other result kinds too. Immutable manifests bind the bytes presented to the checker, but these cases show that internally contradictory evidence can still receive a successful programme label.

## 8. Synthetic evidence and outcomes

Estimated under ten seconds; actual batch elapsed 3.54 seconds. Thirty-one controls: three valid complete scopes, twenty-four correctly rejected mutations, and four residual acceptance cases above. Fixtures include nested test files, source freeze UTC, starts after freeze, every consumed artifact pin, five required rendered pages, complete R code/tests/man/vignettes inventory, and Project/Manifest/runner.

Rejected cases include changed source, nested test, documentation, result, log, Julia HTML, R HTML; added source/test; zero source/test inventory; omitted result/log/freeze/HTML/environment pins; Boolean exit status; absent estimate state; infinite elapsed; malformed time; result predating freeze; empty terms; missing R page; and changed source under python -O. Each rejection had empty stdout and nonzero exit. Each valid and residual accepted case had exactly its scope's success token and exit zero. Logs and structured outcomes are probes.log and results.json; original synthetic bytes are retained by the probe script.

## 9. Builder and current evidence requirements

Parent's plan to copy the actual R check log and latest HTML into durable artifacts and generate a fresh manifest closes the stale Julia-page receipt and absent R-log alias preparation issues from revision 1. That builder is not yet reattested here. Preserve exact R prefix mapping: package-doc-freeze key R/R/animal.R maps to candidate-relative R/animal.R by stripping only the first R/. Do not install until completed package evidence and final current rendered artifacts have been frozen.

## 10. Limits and next action

This review does NOT cover full-package success, numerical calibration, CI, deployment, or visual inspection of every rendered page. Parent should close sections 5 through 7 and run the same frozen synthetic package against the next exact checker. Results from a real completed check remain necessary before final programme tokens can be used.

## 11. Preservation, Memory receipt, and Golden Set

Only revision-2 owned fixtures and this report were written. Revision 1, numerical source, original tests, live evidence, and other lanes were preserved. Memory receipt: inherited preservation guidance only; current checker bytes and independent fixtures supply all findings. Golden Set: complete synthetic valid controls were retained while adding mutations; no old package assertion was weakened.

## 12. Style and final disposition

Slopcheck runs on the absolute report path with zero em dashes. The specified revised checker was completely reviewed. Acceptance is HOLD for four reproduced residual cases; the closed revision-1 cases are explicitly retained as rejection controls.
