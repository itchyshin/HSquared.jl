# 2026-09-07 — Julia applied-reader website candidate

- Commit under test: `e45831e` (local draft-only candidate).
- `OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using Pkg; Pkg.test()'`:
  PASS — `Testing HSquared tests passed`; retained log:
  `/private/tmp/hsq-web-20260907-julia-pkgtest-final.log`.
- `OPENBLAS_NUM_THREADS=1 julia --project=docs docs/make.jl`: PASS; 20 HTML
  pages under `docs/build/1`; retained log:
  `/private/tmp/hsq-web-20260907-julia-documenter-final.log`.
- `git diff --check`: PASS. SVG XML scan: PASS.
- Initial failures retained in after-task report: YAML-colon docs failure,
  generated-table exact-string failure, stale pidfile/superseded test sessions,
  CSS/fragment/SVG/browser defects. Final browser recheck remains parent-owned.
