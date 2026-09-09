# H3 locked Julia environment receipt

## Scope

This receipt materializes a reproducible local Julia environment for the
unarmed H3 candidate.  It is environment preparation only: no H3 fit,
simulation, remote transfer, scheduler submission, promotion, or release is
authorized or performed.

## Provenance

- Candidate project: `Project.toml` at `82f836f368e37cf75609f721f7a03bde3113e10b`.
- The starting `Manifest.toml` was copied from the sealed H1 sibling worktree
  only after `cmp` proved its `Project.toml` byte-identical and
  `git diff 4d4a55c..H1-head -- src` proved no engine-source difference.
- The copied manifest SHA-256 is
  `a3d4803f05af9738bc5796b1534bdb3249a263efb6c618cae6088d3f0c7ce221`.
- `Pkg.instantiate()` completed locally and precompiled HSquared; the direct
  dependency resolution reports `Optim v1.13.3` under Julia 1.10.0.

## Verification

- Current focused C1-ext H1/H3 scaffold: **102/102 pass**.
- Current ordinary `Pkg.test()`: pass.
- No new package resolution was requested; `Pkg.instantiate()` accepted the
  pinned lock rather than selecting a new dependency graph.

## Boundary

The lock makes current-head tests reproducible.  It does not prove H3
scientific correctness, does not ratify the H3 contract, and does not authorize
the proposed Totoro smoke or any DRAC confirmation.
