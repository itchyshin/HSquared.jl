# After-task — 2026-09-07 Gate-A NG-1 Julia scale summary

## 1. Goal

Implement and locally verify the ratified Gate-A Julia NG-1 scale-summary
contract, without a promotion, calibration campaign, release action, or change
to the public R surface.

## 2. Implemented

Added and exported `nongaussian_scale_summary()`.  The bridge-facing helper
accepts Poisson-log and Binomial-logit only; `:bernoulli` is accepted solely as
the internal `Binomial(1)` input alias and every returned summary labels it
`:binomial`.  The result keeps latent and observation values explicit through
`scale`, `estimate`, and `primary`, retains required `NaN` outcomes and
reasons, rejects invalid trials/non-convergence, and contains no fit-method
field.  Focused tests cover defined/undefined scales, constant and varying
trials, extremes, invalid inputs, and the canonical Bernoulli label.

## 3a. Decisions and Rejected Alternatives

Kept the existing opt-in engine route and added only the small stateless summary
needed for a later R bridge.  Rejected a third public Bernoulli family,
averaging varying trial totals, a finite substitute for the Poisson latent
`NaN`, an R-side API change, a generic payload-v2 migration, and any
non-Gaussian REML label in the new summary.  Pre-existing older non-Gaussian
routes were neither reclassified nor promoted by this slice.

## 4. Files Touched

- `src/HSquared.jl`
- `src/nongaussian.jl`
- `test/gate_a_nongaussian.jl`
- `test/runtests.jl`
- `docs/dev-log/after-task/2026-09-07-ng1-gate-a-julia.md`
- `docs/dev-log/check-log.d/2026-09-07-ng1-gate-a-julia.md`
- `docs/dev-log/coordination-board.md`

## 5. Checks Run

- `git merge-base --is-ancestor 6987871b3b8c257cdb23100246d768f8a6fd5397 HEAD`
  and `git diff --check`: **PASS**.
- `~/.juliaup/bin/julia --project=. test/gate_a_nongaussian.jl`: **PASS**
  (`HSQ09_NG_GATEA_TESTS_OK`).
- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: **PASS**
  (`Testing HSquared tests passed`).
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: **PASS**.  Its generated
  validation-status timestamp was restored, leaving no website-source diff.
- Unlazy parent re-verification: leaf S5 **3/3 met**; Julia root ledger **6/6
  met**.  The root evidence records the exact commands and working directory.
- Independent reviews: formal NG-1 specification review **PASS**; code-quality
  reviews after `cc0aac0` and `cc2db0d` **PASS**; R-bridge contract review of
  the Bernoulli normalization **PASS**.

## 6. Tests of the Tests

The focused test was observed red against the live-main baseline because
`nongaussian_scale_summary` did not exist.  The later alias test was also
observed red: a Bernoulli call returned `:bernoulli` rather than `:binomial`.
Both failures became green only after their minimal production changes.  The
full package suite was then rerun on the final `cc2db0d` candidate head.

## 7a. Issue Ledger

Fixed: missing bridge-facing explicit-scale helper; legacy invalid-Poisson
inputs hidden by a zero shortcut; and the new helper's Bernoulli output-label
leak.  Deferred: fresh R accessors/bridge, R–Julia parity, H0/H1/H3 interval
evidence, any Totoro/DRAC campaign, comparator evidence, capability flip,
versioning, tags, registry, and release decision.

## 8. Consistency Audit

Reviewed the helper's three return paths, its exported symbol, the focused-test
inclusion in `runtests.jl`, and the committed diff.  All valid Bernoulli alias
paths now normalize to `:binomial`; invalid Bernoulli trial totals fail before
an output is formed.  A read-only R map confirmed that a later bridge must call
this stateless helper rather than the older fit-bound h² route, which retains a
wire-level Bernoulli label.  The documentation build's timestamp-only mutation
was restored.  A final scope audit found the four intended source/test files
plus only this after-task receipt, its check-log shard, and the coordination
board note in `origin/main...HEAD`; there is no Project.toml change or tag at
HEAD, and the branch remains local and unpushed.

## 9. What Did Not Go Smoothly

Unlazy initially exposed a relative-CWD binding mistake, and a 30-second
execution-wrapper yield discarded long-running child-session handles before
the root ledger could persist its results.  Re-running with retained-session
polling produced the durable full-suite and Documenter receipts.  Documenter
rewrote a generated timestamp, which was restored.  The shared closeout
generator also resolved the Dropbox hub rather than this worktree and created
one untracked placeholder report there; its exact 1,440-byte placeholder file
was verified and removed before the report was written directly in this
claimed worktree path.

## 10. Known Residuals

This is an engine-local, experimental implementation receipt only.  It does
not expose an R user API, retain per-fit R/Julia object identity, establish
cross-twin parity, validate intervals or calibration, authorize compute, or
change any capability/debt status.  Older non-Gaussian APIs and their wording
remain outside this slice and must not be read as ratified by it.

## 11. Team Learning

Active reviewers were a Julia implementation worker, an independent
code-quality reviewer, an independent formal specification reviewer, and an
independent R-bridge mapper/reviewer.  Memory receipt: the repository
`AGENTS.md`, Gate-A decision receipt, and Unlazy ledger shaped this work;
`route.py` returned no LOAD-FIRST manifest for either the fresh worktree or the
registered Dropbox checkout, so that absence is recorded rather than silently
treated as a loaded guard.  No private-memory mutation was authorized.
Golden Set: no named Golden Set was supplied for this narrow helper; the two
retained RED cases above are the direct mutation evidence instead.  Durable lesson:
when a wire-level alias is allowed for compatibility, normalize it at the new
bridge-facing result boundary and test both its input acceptance and output
label.

## 12. Cross-Product Coverage

Covers ✓ the Julia bridge-facing helper, its export, focused contract tests,
full Julia package suite, local Documenter build, and independent static
reviews.  It does NOT cover ✗ R extractors or errors, R–Julia element-wise
parity, public documentation or capability/debt ledgers, H0/H1/H3 calibration
or interval claims, external comparators, Totoro/DRAC evidence, CI, version
changes, tags, registry/CRAN actions, or a 0.9.0 release decision.
