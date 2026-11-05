# PR 495 isolated test-target correction

## 1. Goal

Allow the new warning tests to load their logging API in the Julia package test environment.

## 2. Implemented

Declared the Julia `Logging` standard library in `[extras]` and the test target,
with Julia 1.10 compatibility. Runtime dependencies and warning assertions are unchanged.

## 3a. Decisions and Rejected Alternatives

A test-only public standard-library dependency avoids coupling the new tests to
internal logging APIs. We assumed the supported Julia 1.10 floor is appropriate.

## 4. Files Touched

`Project.toml`, this report and `docs/dev-log/check-log.d/2026-11-04-pr495-logging-test-target.md`.

## 5. Checks Run

In isolated source copies with the same package project and test target,
`Pkg.test()` ran a scratch test entry point including only the #416 sibling test
file. Julia 1.12.6 and 1.10.12 each passed 44 assertions. The Julia 1.10
manifest was freshly resolved. The complete package suite was not run here.

## 6. Tests of the Tests

The same isolated setup at the prior head failed before testing with `Package
Logging not found in current path`. This reproduces the hosted failure. Adding
Logging to the test target corrected it on both local Julia versions.

## 7a. Issue Ledger

PR #495 hosted CI remains to rerun against the updated head; issue #416 and its
scientific interpretation are unchanged.

## 8. Consistency Audit

The package's public logging API is used only by the new tests. The Julia
runtime dependency set and rank calculation were not changed. Project routing
and a scoped lease were checked. Golden Set was not run; no hub guard was added.

## 9. What Did Not Go Smoothly

A direct test-file run succeeded because Logging was in the surrounding
Julia environment; `Pkg.test()` exposed that it was not a test target dependency.

## 10. Known Residuals

Full hosted package checks, independent review and merge remain pending. The
root validator's existing unrelated `GATES.md` entries remain unmet.

## 11. Team Learning

For Julia test dependencies, verify inside the package's isolated test target.

## 12. Cross-Product Coverage

This covers isolated test-target loading on Julia 1.10 and 1.12. It does NOT cover all package tests, Windows, R integration, inference or
scientific gates.
