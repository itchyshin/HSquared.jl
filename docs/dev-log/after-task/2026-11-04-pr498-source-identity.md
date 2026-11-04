# PR 498 source-identity portability checkpoint

## 1. Goal

Prepare a focused correction for PR #498's Windows source-identity failure and
retain the existing fail-closed source boundary.

## 2. Implemented

The extension test now uses the manifest's forward-slash path convention.
The source snapshot rejects resolved paths outside the admitted root and paths
inside the root that resolve outside `src`. Adversarial tests cover both slash
styles, absolute and traversal paths, and a POSIX symlink escape.

## 3a. Decisions and Rejected Alternatives

The correction keeps the canonical manifest format and does not reorder any
FA selector or scientific guard. Assumption: `src` identities must resolve
inside the admitted `src` directory, as the existing path contract states.

## 4. Files Touched

`sim/arc1/execution_identity.jl`, `test/arc1_simulation_identity.jl`, and
this report.

## 5. Checks Run

The focused no-fit identity test file passed under Julia 1.10.12 and 1.12.6 on
macOS with one BLAS thread and at most two Julia threads. The source-directory
negative check failed before the fix and passed afterwards. Windows CI and
full package tests have not run for this commit.

## 6. Tests of the Tests

The root-contained `src/../outside.jl` adversarial case was accepted by the
old code and rejected by the change. Both slash forms and absolute paths are
tested. The real symlink test runs on POSIX; Windows symlink creation and a
real cross-drive case are not covered.

## 7a. Issue Ledger

PR #498 has a Julia 1.10 Windows source-path failure and separate latest-Julia
FA retry-fixture failures. This patch targets the former and strengthens source
containment. It does not resolve the FA fixture or the seed guards.

## 8. Consistency Audit

The expected identity inventory remains canonical forward-slash paths. The
production check continues to reject unrecognized inventory paths and hash
mismatches. Independent review found no source symlinks in this checkout.
Memory receipt: lane preflight and the scoped lease isolated the two source
files; historical execution identities remain unchanged. Golden Set: not run;
no hub guard changed.

## 9. What Did Not Go Smoothly

The historical guard suite remains fail-closed and the original PR remains a
draft. Native Windows behavior cannot be checked on this macOS host.

## 10. Known Residuals

Windows CI, full test suite, model-fit tests, FA fixture, seed guard policy,
and scientific gates remain open. This branch has no merge or release claim.

## 11. Team Learning

A canonical serialized path and a native filesystem path are different
representations; validate both the spelling in the inventory and the resolved
containment. Independent review checked the patch and its test boundaries.

## 12. Cross-Product Coverage

Covered: no-fit source identity and containment on macOS Julia 1.10 and 1.12,
plus both separator strings. This does NOT cover native Windows execution,
Windows symlinks, real cross-drive paths, numerical fits or scientific gates.

A focused Julia 1.13.3 attempt using a copied Julia 1.10 manifest refused a
loaded `Statistics` extension absent from that manifest. That run does not
establish a defect in a freshly resolved Julia 1.13 environment. It records a
source/environment mismatch; Windows and latest-Julia CI are still required.

A rerun on Julia 1.13.3 passed both focused no-fit testsets using a fresh
Julia 1.13-resolved manifest with SHA-256
`272ce679b561dedde1d733b783905cc6201cd9ed08b99acc1f87082e5454597b`.
The source was an export of code commit `db48d9754af1a6f9b06b304925a2022778e01174`.
Package-manager precompilation briefly exceeded the intended Mac CPU budget;
future runs should cap precompile tasks as well as Julia and BLAS threads.

For the separate FA retry-fixture failure, a no-fit matrix check confirmed on
Julia 1.10.12 and 1.13.3 that zero FA loadings reproduce the diagonal covariance
under the current parameterization. This supports the proposed fixture repair
but does not exercise the selector or establish that its test passes.
