# Planned Genomic/QTL Marker Vocabulary Mirror

Date: 2026-06-13

Active lenses: Ada, Shannon, Boole, Hopper, Noether, Jason, Rose, Pat.

Spawned subagents: none.

## Goal

Mirror the R twin's planned genomic/QTL formula markers on the Julia side
without creating unsupported model-spec, fitting, or scan behavior.

## R Handoff

R commits:

- `dc53584 Add planned genomic QTL markers`;
- `3c82c9a Record genomic marker CI evidence`.

R marker names:

- `genomic()`;
- `single_step()`;
- `markers()`;
- `marker_scan()`;
- `qtl_scan()`.

Reported R evidence for implementation commit `dc53584`:

- local formula tests: 17 pass;
- local full tests: 158 pass;
- local `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- R-CMD-check `27458338370`: success;
- pkgdown `27458338374`: success;
- Pages `27458374477`: success.

## Julia Action

Added:

- `planned_model_terms()`;
- `genomic()`;
- `single_step()`;
- `markers()`;
- `marker_scan()`;
- `qtl_scan()`.

Each function throws a planned-not-implemented error. This mirrors the R marker
names without constructing a model spec or scan object.

## Files Changed

- `src/HSquared.jl`
- `src/planned_terms.jl`
- `test/runtests.jl`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-v0.1-contract.md`
- `docs/design/02-formula-grammar.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/src/api.md`
- `docs/src/changelog.md`
- `docs/src/genomics-qtl-gpu-hpc.md`
- `docs/src/index.md`
- `docs/src/roadmap.md`

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed with 227 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment skipped as
  expected outside CI; generated Vitepress dependencies reported npm
  advisories in temporary build artifacts.
- `git diff --check`: passed.
- Claim scan: clean with limitations. Hits were blocked/audit wording, not
  public claims of genomic prediction, single-step fitting, marker-effect
  estimation, marker scans, QTL/eQTL scans, GPU execution, ASReml superiority,
  backend benchmarking, or CPU/GPU numerical agreement.
- GitHub CI for commit `bc0fe77`: success, run `27458684148`.
- GitHub Documenter for commit `bc0fe77`: success, run `27458684126`.
- GitHub Pages deploy: success, run `27458715550`.
- Live docs `https://itchyshin.github.io/HSquared.jl/`: HTTP 200.

GitHub Actions emitted Node 20 deprecation annotations for upstream actions.
They were non-failing and do not affect the package or docs results.

## Public Claim Audit

Allowed wording:

- Julia reserves planned genomic/QTL model-term names;
- those names mirror the R formula markers;
- calls error with planned-not-implemented wording.

Blocked wording:

- genomic prediction works;
- single-step fitting works;
- marker-effect estimation works;
- marker scans, QTL scans, or eQTL scans work;
- marker matrices, maps, genotype probabilities, or LOCO behavior are
  validated.

Rose verdict: clean with limitations.
