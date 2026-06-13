# Formula Status Diagnostic Mirror

Date: 2026-06-13

Active lenses: Ada, Shannon, Boole, Hopper, Noether, Rose, Pat.

Spawned subagents: none.

## Goal

Mirror the R twin's `formula_status()` grammar diagnostic in Julia and
Documenter without expanding parser, model-spec, or fitting behavior.

## R Handoff

R commits:

- `52d57dd Add formula grammar status diagnostic`;
- `7ba2df4 Record formula status CI evidence`.

Reported R evidence:

- R-CMD-check `27459105695`: success;
- pkgdown `27459105696`: success;
- Pages `27459143480`: success.

R issue note:

- `https://github.com/itchyshin/hsquared/issues/4#issuecomment-4697748409`

R diagnostic shape:

- 20 rows;
- columns `term`, `category`, `phase`, `syntax_status`, `fitting_status`, and
  `current_behavior`;
- separates parsed v0.1 animal syntax, reserved inert markers, and planned
  roadmap syntax.

## Julia Action

Added:

- `FormulaStatusRow`;
- `FormulaStatus`;
- `formula_status()`;
- a 20-row Documenter status table in `docs/src/model-spec-grammar.md`.

The Julia diagnostic mirrors the R column vocabulary. It returns typed rows and
is iterable like other status containers in this package.

## Files Changed

- `src/HSquared.jl`
- `src/planned_terms.jl`
- `test/runtests.jl`
- `README.md`
- `docs/design/02-formula-grammar.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/src/api.md`
- `docs/src/changelog.md`
- `docs/src/index.md`
- `docs/src/model-spec-grammar.md`
- `docs/src/roadmap.md`

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed with 293 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm
  advisories in temporary build artifacts.
- `git diff --check`: passed.
- `julia --project=. -e 'using HSquared; s = formula_status(); println(length(s)); println(s[1].term); println(s[1].syntax_status); println(s[end].term); println(s[end].syntax_status)'`:
  printed the expected 20-row boundary rows.
- Claim scan: clean with limitations. Hits were blocked/audit wording, not
  public claims that `formula_status()` parses formulas, constructs model
  specs, expands fitting, or enables any reserved/planned term.
- Follow-up docs alignment check: `julia --project=docs docs/make.jl` passed
  after left-aligning the Documenter status table.
- Remote checks for commit `72bc28f`: passed.

Remote run IDs:

- CI `27459348834`: success;
- Documenter `27459348823`: success;
- Pages deploy `27459383483`: success.

Live docs:

- root `https://itchyshin.github.io/HSquared.jl/`: HTTP 200;
- grammar page `https://itchyshin.github.io/HSquared.jl/dev/model-spec-grammar`:
  HTTP 200 and contains `formula_status()`, `experimental tiny bridge only`,
  and `qtl_scan(position, genotype_probs = probs)`.

## Public Claim Audit

Allowed wording:

- `formula_status()` reports grammar status;
- the table separates parsed, reserved, and planned rows;
- reserved and planned rows remain unavailable for fitting.

Blocked wording:

- `formula_status()` parses formulas;
- `formula_status()` constructs model specs;
- any reserved or planned formula term is now fit by Julia;
- this diagnostic changes R-to-Julia bridge execution.

Rose verdict: clean with limitations.

## What Did Not Go Smoothly

- The ad hoc smoke command exposed that `FormulaStatus` needed `firstindex`
  and `lastindex` for `formula_status()[end]`. Added both and pinned the
  behavior in tests.

## Known Limitations

- The table is manually mirrored from the R row vocabulary. Future grammar
  changes need lockstep updates in both twins.
- The table is diagnostic only and does not validate user formulas.

## Next Actions

1. Push the evidence record and watch CI/Documenter/Pages.
2. Add a GitHub issue note for the R/Jula diagnostic mirror.
