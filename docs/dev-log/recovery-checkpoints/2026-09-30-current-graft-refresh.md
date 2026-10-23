# HSquared.jl current-candidate Graft refresh — 2026-09-30

- Target: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`
- Scope: metadata refresh only under `graft/**`; no source, test, driver, schema, or gate edits.
- Local-only behavior: inspected `graft build --help`; plain `graft build` is the wiring graph + per-file cards `$0`, with `--deep` as the distinct LLM pass. Ran plain build only; no network or LLM pass. CLI printed an available-version advisory; no upgrade/install was run.
- Build result: completed successfully; 2,664 nodes, 3,325 edges, 211 cards; 56 parsed and 155 replayed from cache. Graft check exited 0: wiring graph in sync (deep meaning layer not built).
- Refreshed paths: 216 files under `graft/**`, including `graft/INDEX.md`, `graft/.cache/{ask-index.json,extract.1df3c85459ac038a.json,fingerprint.1df3c85459ac038a.json}`, `graft/src/*.md`, and per-file cards under `graft/{bench,comparator,docs,ext,sim,src,test,tools}/**`.
- Source-tree SHA-256 before and after: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` (24 files; sorted path relative to `src`, NUL, bytes, NUL). Matches the expected frozen hash.
- Bounded Graft query: `graft ask 'factor analytic likelihood objective entry point' --source` returned `src/multivariate.jl:L362-L372` for `factor_analytic_covariance`. Checked that bounded source span; current lines 362–372 match the returned definition exactly.
- Estimated savings reported by Graft: approximately 142,429 tokens (2,153-token pack versus 144,582 tokens to read eight source files whole). `graft stats` has no session record, so this is the query's estimate, not session-aggregated usage.
- Lane lease: target preflight was run with `--file graft`; it reported `graft` clear of missing-ref work, while also reporting multiple live lanes. No other paths were touched.
