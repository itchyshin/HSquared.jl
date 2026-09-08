# Check log — 2026-09-07 S8 Julia NG-1 claim reconciliation

- **Base:** `946c597a6180620ece585aa583e8e07d5cb1fe01`.
- **Scope:** documentation-only reconciliation of the existing NG-1
  scale-summary claim.  The functional diff is exactly three ledger rows:
  `docs/design/06-public-claims-register.md`,
  `docs/design/capability-status.md`, and
  `docs/design/validation-debt-register.md` (`V6-NG-1`).  This shard and its
  paired after-task receipt record provenance only.
- **No executable-source/test/API change:** no Julia implementation, export, test source,
  R route, capability status symbol, promotion, public-covered count, version,
  tag, registry, release, deployment, calibration, coverage, comparator, or
  fitted-behavior claim changed.

| Check or review | Outcome | Boundary retained |
| --- | --- | --- |
| Initial `~/.juliaup/bin/julia --project=. test/gate_a_nongaussian.jl` | Did not start because the fresh worktree lacked its git-ignored `Manifest.toml` | Environmental setup failure only; not a Gate-A test failure |
| `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.instantiate()'` | Completed locally; no tracked diff | Local dependency materialization only |
| Re-run `~/.juliaup/bin/julia --project=. test/gate_a_nongaussian.jl` | **PASS** — `HSQ09_NG_GATEA_TESTS_OK` | Confirms the pre-existing focused Gate-A contract test ran; no new test was added |
| `~/.juliaup/bin/julia --project=docs docs/make.jl` | **PASS** — `S8_DOCS_BUILD_OK` | Retained 43 existing unincluded-docstring warnings; its generated timestamp-only `docs/src/validation-status.md` noise was restored and is not part of the diff |
| Independent Rose claim review | One wording correction applied; final verdict **CLEAN** | Editorial claim-surface audit, not new numerical or behavioral evidence |

The three ledger rows retain the existing engine-only NG-1 statement:
`partial (experimental; not covered)`, the focused Gate-A test, S7 parity
reference `e6a1ce4`, and explicit negative space.  They do not widen the
contract into a non-Gaussian REML, public-R, calibration, coverage, comparator,
or fitted-behavior claim.

This receipt does NOT authorize G6–G10, release, or compute.
