# DocStr repair v2: test sandbox dependency

Author: actual GPT-6.1 Sol, High effort. Date: 2026-10-01 UTC. Scratch-only proposal for independent sandbox review. Baseline HEAD `ec9414c35d7621c6bd4321a9d16067ac9a2ea2eb`. The v1 packet and its independent 9-control-per-runtime receipt remain preserved. No live file, numerical source, runtime dependency, package version, Manifest or frozen campaign artifact was edited here.

## Concrete unmet environment requirement

The parent-owned actual Julia 1.13.1 full `Pkg.test` exited early after 84.49 seconds: `Package REPL not found in current path` at `test/runtests.jl:5`. Log: `/private/tmp/hsq-final-integrated-checks-20260930/julia-package-final.log`, lines 228-257. The v1 focused `--project` checks validated the canonical documentation content but did not reproduce the package test sandbox. Their passing counts remain true within that narrower environment; they do not establish sandbox compatibility. No dependency bypass is proposed.

## Minimal documented correction

There is no `test/Project.toml`. The package already uses root `[extras]`, `[targets].test` and explicit test compatibility bounds for its test dependencies. Add REPL to those existing sections, with its shipped UUID `3fa0cd96-eef1-5676-8a61-b3b8758bbffb` and compatibility `1.10`. The compatibility retains the supported Julia 1.10 floor and allows current 1.x REPL stdlib versions. This does not add REPL to `[deps]`.

A separate test project would require a complete migration/duplication of existing direct test dependencies and a new environment scheme. It is broader than this failure. Julia's shipped Pkg documentation supports the existing extras/targets scheme; `Pkg/src/Operations.jl:2959-3008` constructs the test project from package dependencies plus the target's named extras and compatibility entries. The shipped REPL Project supplies the UUID; Julia's Docs API documentation supplies the need to load REPL on Julia >=1.11.

The patch adds one explanatory test-only comment. Both v1 documentation readers and every original assertion remain unchanged. Numerical source and archived campaign Project/Manifest stay immutable. Active Project's new hash must be separately recorded in renewed package evidence; an older environment freeze cannot attest it. Temporary sandbox resolution is not a campaign-environment rewrite.

## Exact pins and checks

- Original active Project: `37f0e6aaa6492c76519ed7771b226972cea531a7104866e5753890e31e163033`.
- Prepared active Project: `8797dab5ac93c3c03e29c6fa3924056c173873d40356e8be86a7367344cdd9dc`.
- `test-repl-dependency.patch`: `825e0483d3934567ee4ece58a105e77d024921a9141bc3488e2c599059d338d5`.
- Unchanged Manifest preserved as `Manifest-original.toml`: `c5940f2be0347f7ff987468aed67f17070f556a0aa99e0e5ec5317898cfa0fad`.
- Already installed v1 runner/API tests: `27b7adbfe0b1c8d397e9041710fe713410d6692d9ef8ebf50af4354a0429adf3` / `3a3afbfbfb1cf3f81566b8cdb7871dd874b73c4481736a8f097fda8dd3215299`.

TOML structural checks confirm runtime dependencies/version unchanged, correct REPL UUID/compatibility, and all prior test targets retained in order. `git apply --check` succeeds against the current unchanged root Project. No new author full-suite or statistical replay was run.

## Independent actual sandbox gate and handoff

The independent reviewer owns separate copied packages and will replace their scratch test runner with bounded documentation assertions, then invoke actual `Pkg.test` on Julia 1.10.0 and 1.13.1. Estimated under two minutes per runtime, owned timeout 120 seconds, Julia/BLAS one thread. The probe must record that its active child test project differs from the package root, that ordinary `using REPL` succeeds, and that canonical unsupported-route/neighbor documentation assertions and negative controls pass. No `Base.require`, LOAD_PATH injection or dependency bypass may be used. Preserve all original/frozen artifacts and record any temporary sandbox metadata separately.

Independent sandbox PASS and parent integration/full-suite/current-head hosted checks remain required. Independent sandbox results and final hosted outcomes remain separate evidence. Parent must refresh the active Project/runner/source freeze while preserving the historical failed full-run and campaign environment.

Signed: GPT-6.1 Sol, High, author of this isolated test-only dependency proposal.
