# Julia Sister Boundary Scout

Date: 2026-06-13

Active lenses: Jason, Shannon, Grace, Karpinski, Rose.

Spawned subagents: none.

## Question

What should `HSquared.jl` learn from the local Julia sister packages before
widening Phase 1?

## Local Sources Checked

- `/Users/z3437171/Dropbox/Github Local/DRM.jl/AGENTS.md`
- `/Users/z3437171/Dropbox/Github Local/DRM.jl/docs/make.jl`
- `/Users/z3437171/Dropbox/Github Local/DRM.jl/docs/src/index.md`
- `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/AGENTS.md`
- `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/docs/make.jl`
- `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/docs/src/index.md`

## Lessons Borrowed

- Use named review lenses in updates, but do not imply separate agents are
  running unless they are actually spawned.
- Keep Julia engine APIs tied to a public R twin contract, with Hopper owning
  the translation boundary.
- Use DocumenterVitepress early so package documentation grows beside code.
- Keep status tables and public prose honest: implemented, planned, and missing
  must stay separated.
- Record cross-project learning in `docs/dev-log/scout/` so it is not lost in
  chat.
- Treat sister package code as a reference for architecture and process. Do not
  copy statistical code without checking license, provenance, and fit for this
  package.

## HSquared.jl Action

- Add the initial DocumenterVitepress site scaffold.
- Start Phase 1 with a narrow engine utility: pedigree normalization plus sparse
  `Ainv`, not full animal-model fitting.
- Keep high-level fitting entry points as placeholders until ML/REML, EBVs, and
  validation land.

## Claim Wording Risk

The main risk is saying "animal models work" when only relationship-matrix
utilities work. Public docs should say "`Ainv` construction works" and "model
fitting is planned."
