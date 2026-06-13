# HSData Expression Diagnostics

Date: 2026-06-13

Active lenses: Ada, Emmy, Jason, Pat, Hopper, Karpinski, Rose, Grace.

Spawned subagents: none.

## Scope

Mirror the R twin's `hs_data()` expression-status diagnostics in Julia
`HSData`.

This is metadata diagnostics only. It does not add eQTL or omics fitting,
automatic expression-feature joins, GLLVM workflows, bridge payload changes,
or file-backed expression storage.

## R Handoff

R repo `itchyshin/hsquared` reported:

- implementation commit `c5e97d1`;
- evidence commit `06cdf59`;
- issue update:
  <https://github.com/itchyshin/hsquared/issues/8#issuecomment-4698297184>.

R diagnostics report:

- expression rows;
- expression IDs;
- expression feature count;
- named expression feature count;
- unnamed expression feature count;
- duplicate named expression feature count;
- component type.

## Implementation

Added:

- `HSDataExpressionStatusRow`;
- `expression_status` on `HSDataStatus`;
- expression-status diagnostics for table-like expression components;
- expression-status diagnostics for matrix-like expression components;
- stored `expression_id` in `HSData` so table-like feature columns can be
  counted after excluding the ID column.

Plain Julia matrices are reported as matrix components with unnamed features
because base matrices do not carry feature column names.

## Files Updated

- `src/HSquared.jl`
- `src/data.jl`
- `test/runtests.jl`
- `README.md`
- `ROADMAP.md`
- `docs/src/api.md`
- `docs/src/data.md`
- `docs/src/index.md`
- `docs/src/roadmap.md`
- `docs/src/changelog.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/09-hsdata-contract.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.md`

## Validation

Local checks:

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals sum
  to 446 checks; the Phase 1 HSData ID container testset has 106 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm
  advisories in temporary build artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: returned no matches.
- Claim-boundary scan: found only expected guardrail and blocked-wording hits
  around expression joins, eQTL/omics, GLLVM workflows, marker/QTL/GWAS
  workflows, genomic fitting, GPU workflows, and existing backend speed-claim
  guardrails.

Remote checks for implementation commit `81e82b0`:

- CI `27464814149`: success on Julia 1 and Julia 1.10.
- Documenter `27464814148`: success.
- Pages deploy `27464876181`: success.
- GitHub Actions reported non-blocking Node 20 deprecation annotations for the
  action stack.

Live docs:

- `https://itchyshin.github.io/HSquared.jl/dev/data.html`: HTTP 200 and
  contains `Expression Metadata` and `expression_status`.
- `https://itchyshin.github.io/HSquared.jl/dev/api.html`: HTTP 200 and
  contains `HSDataExpressionStatusRow`.

## Public Claim Audit

Allowed wording:

- `data_status(::HSData)` reports expression rows, expression IDs, feature
  counts, named/unnamed feature counts, duplicate named feature counts, and
  component type for in-memory expression components.

Blocked wording:

- expression features are automatically joined into model matrices;
- eQTL or omics models are fitted;
- GLLVM workflows are implemented;
- marker/QTL/GWAS workflows are implemented;
- genomic fitting or GPU workflows are implemented;
- bridge payloads consume expression components.

## Known Limitations

- Matrix-like expression inputs need explicit `expression_ids` for ID matching.
- Base Julia matrices are reported with unnamed features.
- File-backed arrays, sparse expression matrices, PLINK/VCF data, and
  chunked/streamed omics storage remain planned.
- Annotation-feature matching remains under `annotation_id`.

## Next Actions

1. Commit and push the remote-evidence update.
2. Watch CI, Documenter, and Pages for the evidence commit.
3. Update the issue ledger.
