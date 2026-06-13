# Planned Quantitative-Genetic Marker Vocabulary Mirror

Date: 2026-06-13

Active lenses: Ada, Shannon, Boole, Hopper, Noether, Mendel, Henderson, Rose,
Pat.

Spawned subagents: none.

## Goal

Mirror the R twin's planned standard quantitative-genetic formula markers on
the Julia side without creating unsupported model-spec, fitting, relationship,
or precision-kernel behavior.

## R Handoff

R commits:

- `14e5781 Add planned quantitative genetics markers`;
- `10e8fd7 Record QG marker CI evidence`.

R marker names:

- `permanent()`;
- `common_env()`;
- `maternal_genetic()`;
- `maternal_env()`;
- `paternal_genetic()`;
- `paternal_env()`;
- `cytoplasmic()`;
- `imprinting()`;
- `dominance()`;
- `epistasis()`;
- `relmat()`;
- `precision()`.

Reported R evidence:

- R-CMD-check `27458718993`: success;
- pkgdown `27458718981`: success;
- Pages `27458751023`: success.

R issue note:

- `https://github.com/itchyshin/hsquared/issues/4#issuecomment-4697708772`

R docs-sync handoff:

- `92c1d12 Add formula grammar article`;
- `794722f Record formula grammar article CI evidence`;
- R-CMD-check `27458881927`: success;
- pkgdown `27458881926`: success;
- Pages `27458916142`: success;
- issue note
  `https://github.com/itchyshin/hsquared/issues/4#issuecomment-4697726092`.

## Julia Action

Added:

- `planned_quantgen_terms()`;
- `permanent()`;
- `common_env()`;
- `maternal_genetic()`;
- `maternal_env()`;
- `paternal_genetic()`;
- `paternal_env()`;
- `cytoplasmic()`;
- `imprinting()`;
- `dominance()`;
- `epistasis()`;
- `relmat()`;
- `precision()`.

Each function throws a planned-not-implemented error. This mirrors the R marker
names without constructing model specs or relationship/precision objects.

Julia-specific note: `Base` already exports `precision`, so `precision()` is
available as `HSquared.precision()` rather than an exported unqualified name.
The reserved term remains `:precision` for bridge vocabulary parity.

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
- `docs/src/model-spec-grammar.md`
- `docs/src/roadmap.md`
- `docs/make.jl`

## Checks

- First `julia --project=. -e 'using Pkg; Pkg.test()'`: failed because
  exporting `precision()` conflicted with `Base.precision`.
- Final `julia --project=. -e 'using Pkg; Pkg.test()'`: passed with 282 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment skipped as
  expected outside CI; generated Vitepress dependencies reported npm
  advisories in temporary build artifacts.
- `git diff --check`: passed.
- Claim scan: clean with limitations. Hits were blocked/audit wording, not
  public claims of Phase 2+ QG fitting, custom relationship/precision kernels,
  genomic prediction, marker scans, QTL/eQTL scans, GPU execution, ASReml
  superiority, backend benchmarking, or CPU/GPU numerical agreement.
- GitHub CI after push: pending.

## Public Claim Audit

Allowed wording:

- Julia reserves planned standard quantitative-genetic model-term names;
- those names mirror the R formula markers;
- calls error with planned-not-implemented wording.

Blocked wording:

- permanent/common environment fitting works;
- maternal or paternal effect fitting works;
- cytoplasmic inheritance or imprinting fitting works;
- dominance or epistasis fitting works;
- custom relationship or precision kernels are validated;
- any Phase 2+ quantitative-genetic effect is implemented.

Rose verdict: clean with limitations.

## What Did Not Go Smoothly

- The first local package test exposed an export conflict between
  `HSquared.precision` and `Base.precision`. The fix was to keep
  `HSquared.precision()` as a qualified planned marker and not export it.
