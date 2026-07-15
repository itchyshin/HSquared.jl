# 2026-07-14 — v0.7 D0F retry-4 endpoint-representation blocker

- Exact deployed heads: R `83d19e8c781292a551f9fcb2149c011a37299691`;
  Julia `e5d4a0aac7473a82655032717399a465d1a6635e`; candidate
  `fc9d39df650b20aa09d769d9f9528eed1b606f1e`.
- Clean reviews, deployment, preseal, zero-seed preflight, n-ladder, and
  16-worker smoke preceded official execution on Totoro.
- Official route 576/576 successful/converged; independent base-R 576/576;
  exact Julia replay 455/576 before four batches stopped fail-closed. The
  remaining 121 rows have no replay output and are not 121 failures.
- Five of 13 official boundary rows have a one-ULP difference between the
  component-derived ratio and engine-declared endpoint. The bit-exact replay
  check and `fit_error` classification are validator defects, not solver, KKT,
  gradient, convergence, or recovery evidence.
- Disposition:
  `UNADJUDICATED — REPLAY_ENDPOINT_REPRESENTATION_BLOCKER`. No Julia summary or
  receipt; root and bases `2036000000` / `2037000000` retired; D1/D2 never
  opened; ordinary route held; `public_covered_count = 5`.
- R verification: documentation regenerated; pkgdown check clean; built-package
  `R CMD check --no-manual` `Status: OK`; after-task and diff checks pass.
- Julia verification: full `Pkg.test()` green; Documenter/Vitepress green;
  preamble cap green; after-task and diff checks pass.
- Full checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-07-14-v07-d0f-retry4-boundary-parity-blocker.md`.
