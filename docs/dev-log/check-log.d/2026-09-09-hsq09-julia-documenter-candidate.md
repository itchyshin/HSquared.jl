# HSquared 0.9 candidate — fresh Documenter receipt

- **Candidate:** `codex/hsq09-h3-prerun-20260909` at
  `e70ca56f` (the immediately preceding ordinary-test receipt); no candidate
  source or documentation content was changed by this build.
- **Command:**
  ```sh
  JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
    /Users/z3437171/.juliaup/bin/julia --project=docs docs/make.jl
  ```
- **Result:** exit success.  Documenter ran doctests, template expansion,
  cross-references, document checks, indices, HTML rendering, and the local
  DocumenterVitepress site build.
- **Warnings retained:** 43 checked-module docstrings are not included in the
  manual; local execution skipped deployment; Vitepress supplied defaults for
  optional local configuration files and found no favicon.  These were warnings,
  not failed document checks, and this receipt makes no claim that they are
  resolved.
- **Generated-state handling:** `docs/Manifest.toml` and `docs/build/` are
  ignored.  The build regenerated only the timestamp in tracked
  `docs/src/validation-status.md`; its table content was unchanged and the
  timestamp was restored before this receipt was recorded.
- **Scope fence:** a local documentation build is ordinary Julia candidate
  evidence only.  It does not prove hosted documentation, R pkgdown, CI,
  H3 interval formation/calibration, promotion, or release.
