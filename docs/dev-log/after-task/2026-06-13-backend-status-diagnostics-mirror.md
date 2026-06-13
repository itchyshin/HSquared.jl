# Backend Status Diagnostics Mirror

Date: 2026-06-13

Active lenses: Ada, Shannon, Hopper, Karpinski, Grace, Rose, Pat.

Spawned subagents: none.

## Goal

Mirror the R twin's `backend_info()` status diagnostic with a typed Julia
surface that reports planned backend availability honestly.

## R Handoff

R commits:

- `498d41f Add backend status diagnostics`;
- `8266a82 Record backend diagnostics CI evidence`.

R surface:

- `backend_info(control = hs_control())`;
- rows: `cpu`, `threads`, `cuda`, `amdgpu`, `metal`, `oneapi`;
- columns: `backend`, `accelerator`, `requested`, `selectable`,
  `execution_available`, `status`, and `note`;
- `selectable = TRUE` for all rows;
- `execution_available = FALSE` for all rows;
- `status = "planned"` for all rows.

Reported R evidence for the implementation commit:

- local R tests: 151 pass;
- local `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- R-CMD-check `27458148965`: success;
- pkgdown `27458148970`: success;
- Pages `27458179717`: success.

Reported R evidence for the evidence commit:

- R-CMD-check `27458206919`: success;
- pkgdown `27458206905`: success;
- Pages `27458237087`: success.

## Julia Action

Added:

- `BackendInfoRow`;
- `BackendInfo`;
- `backend_info(control = HSControl())`.

The Julia row fields mirror the R shape:

- `backend`;
- `accelerator`;
- `requested`;
- `selectable`;
- `execution_available`;
- `status`;
- `note`.

Current status is intentionally conservative: all rows are selectable metadata,
all rows have `execution_available == false`, and all rows have
`status == :planned`.

## Files Changed

- `src/HSquared.jl`
- `src/backends.jl`
- `src/control.jl`
- `test/runtests.jl`
- `README.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/src/api.md`
- `docs/src/changelog.md`
- `docs/src/index.md`
- `docs/src/roadmap.md`

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed with 211 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment skipped as
  expected outside CI; generated Vitepress dependencies reported npm
  advisories in temporary build artifacts.
- `git diff --check`: passed.
- Claim scan: clean with limitations. Hits were blocked/audit wording or
  historical check-log notes, not public execution or speed claims.
- GitHub CI for commit `80bd8be`: success, run `27458402884`.
- GitHub Documenter for commit `80bd8be`: success, run `27458402883`.
- GitHub Pages deploy: success, run `27458435663`.
- Live docs `https://itchyshin.github.io/HSquared.jl/`: HTTP 200.

GitHub Actions emitted Node 20 deprecation annotations for upstream actions.
They were non-failing and do not affect the package or docs results.

## Public Claim Audit

Allowed wording:

- Julia has a typed `backend_info()` status diagnostic;
- backend names are selectable control metadata;
- all backend execution statuses are planned/unavailable;
- CPU is the trusted default target.

Blocked wording:

- runtime backend probing exists;
- GPU execution works;
- Metal, CUDA, AMDGPU, or oneAPI backends execute model code;
- backend benchmarking exists;
- CPU/GPU numerical agreement has been tested.

Rose verdict: clean with limitations.
