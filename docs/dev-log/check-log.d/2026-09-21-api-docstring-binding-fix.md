## 2026-09-21 — `multi_effect_variance_component_covariance` docstring reattached `[JL]`

Documenter was RED on `main` from `25531235` (#370) through `e05fcf0e` (#371). Run
`35646992413`:

```
┌ Error: no docs found for 'HSquared.multi_effect_variance_component_covariance'
  in `@docs` block in docs/src/api.md:3-211
┌ Error: Cannot resolve @ref for md"[`multi_effect_variance_component_covariance`](@ref)"
  in docs/src/api.md.   (×3)
ERROR: LoadError: `makedocs` encountered errors [:docs_block, :cross_references]
  -- terminating build before rendering.
```

### Cause

`7c1ddf19` (#362) split the function into a private `_multi_effect_variance_component_covariance`
(which carries the `unavailable` kwarg) and a thin public wrapper. The docstring stayed above
the PRIVATE definition, though its own signature line names the public one. Nothing asked for
the public binding until #370 added the five #352 functions to `docs/src/api.md` — so the
defect was latent for two PRs and surfaced as a docs failure, not as the rename it was.

This is the second instance of the same class in this arc: the #370 report (§9) records
catching an unresolvable `[_ratio_delta_ci](@ref)` the same way. That one was fixed; this one
was not, and #370/#371 merged with Documenter red.

### Fix

The docstring is moved, verbatim, onto `function multi_effect_variance_component_covariance`.
The private definition keeps a plain `#` comment saying why it exists. No prose was rewritten.
No behaviour, estimand, export, capability row or count changes; `public_covered_count` stays
**7**, version stays `0.9.0`.

### Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'` — **passed**, exit 0, 176 summaries, 0
  failures / 0 errors / 0 broken, Julia 1.13.0, Mac Studio M1 Ultra.
- Binding audit over every `HSquared.*` line in `docs/src/api.md` via `Docs.meta`: **1**
  entry without a docstring before the change, **0** after. It was the only one.
- `julia --project=docs docs/make.jl` — all Documenter stages pass. Zero occurrences of
  `docs_block`, `cross_references`, `no docs found` or `Cannot resolve @ref`; the build now
  reaches `RenderDocument` and `DocumenterVitepress: rendering MarkdownVitepress pages`,
  i.e. PAST the gate that terminated it on CI. It then dies at
  `npm run … vitepress build` (`ProcessExited(127)`) — the pre-existing local failure the
  2026-09-21 post-fit report already verified is IDENTICAL from `main` in this checkout and
  is a property of the checkout, not the repo. Linking `docs/node_modules` into `docs/build`
  does not help: DocumenterVitepress wipes `docs/build` at the start of the run. **The full
  render is therefore unverified locally and is left to CI.**
- `bash tools/preamble_cap.sh` — **CAP OK** (11,024 B of 14,000; 1 snapshot entry).
- `bash tools/build_check_log.sh --check` — well-formed.

### Claim boundary

The failure observed locally pre-fix was not the Documenter one — this checkout dies at npm
first. The causal chain is: CI's error names the binding; `Docs.meta` shows that binding had
no docstring and the private one did; it was the only such entry in `api.md`; after the move
the binding resolves and all Documenter stages pass. Green CI on the PR is the confirming
leg and had not run at the time of writing.

### Incidental, pre-existing — one stale ledger anchor

`tools/check_capability_citations.py` FAILED on `main` before this change:
`docs/design/capability-status.md:95` cited `test/runtests.jl:6926` for the Phase 4
direct–maternal row, was re-pointed to `7145` by the #370 arc, and has drifted again.
Re-pointed to `7237`, the `@testset "Phase 4 direct–maternal 2×2 G"` heading, with
`fit_direct_maternal_reml` at `7266` and `direct_maternal_interval` at `7281` inside the
checker's ±80-line window. Now **OK — 82 verified, 0 skipped**.

This is the THIRD re-point of the same anchor. A line number is a citation that rots on
every insertion above it; a heading- or name-based anchor would not. Not changed here —
that is a `tools/` design decision, not this slice's.
