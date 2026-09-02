# 2026-09-02 — A19 experimental 0.5.0 version bump (draft)

**Lane:** `chore/a19-experimental-050-bump` from `origin/main` `69f16572`  
**Worktree:** `~/local-scratch/lanes/HSquared.jl-a19-050-20260902`  
**Fence:** experimental label kept; `public_covered_count` **5**; no covered
flip; no `@JuliaRegistrator register`; do not merge until **A19 GO** +
**A13 SIGNED**.

## Commands

```text
# version surfaces only (no NEWS.md — Documenter changelog used)
# Project.toml version = "0.5.0"
# CITATION.cff version: 0.5.0 (no invented DOI)
# docs/src/changelog.md ## 0.5.0 (experimental)
```

Local numeric check after the bump (metadata only; full `Pkg.test()` left to CI):

```sh
julia --project=. -e 'using TOML; println(TOML.parsefile("Project.toml")["version"])'
```

Expected: `0.5.0`. CI on the draft PR is the suite evidence.
