# 2026-06-21 Structured Covariance Status Sync (#42)

- Goal: reconcile Julia-facing structured-covariance docs with the already
  banked diagonal/unstructured bridge payload and fixture.
- Active lenses: Ada, Shannon, Hopper, Boole, Kirkpatrick, Fisher, Grace, Rose.
- Starting point: `main` at `07a3c63` after the threshold validation-status
  sync. R-lane context: hsquared PR #74 (`b4b4da5`) already retargeted R issue
  #22 so diagonal is described as banked and lowrank/fa remains open.
- Evidence checked:
  - `src/validation_status.jl` already says the rotation-free `:diagonal`
    structure is bridge-exposed through `multivariate_result_payload`.
  - `docs/design/validation-debt-register.md` already has `V4-BRIDGE` for the
    diagonal/unstructured payload and `test/fixtures/structured_covariance_parity/`.
  - `docs/design/12-bridge-compatibility.md` already lists structured
    covariance as experimental with #42 and the planned lowrank/fa follow-up.
  - `docs/src/validation-status.md`, `docs/design/capability-status.md`, and
    `docs/design/06-public-claims-register.md` still contained stale wording
    implying no bridge/result-payload change for all structured covariance.
- Changes:
  - Updated the human-facing `V4-FA` docs and public-claims wording to separate
    the banked `:diagonal`/`:unstructured` payload from blocked lowrank/fa
    loading exposure.
  - Added a coordination-board entry and after-task evidence.
  - Retargeted live issue #42 so it records the banked diagonal/unstructured
    payload and keeps lowrank/fa bridge exposure open.
- Commands run:
  - `julia --project=docs docs/make.jl` — passed with existing local
    Documenter/Vitepress warnings for skipped deployment detection, substituted
    Vitepress defaults, missing logo/favicon, and npm audit output.
  - `gh issue edit 42 --body ...` — passed; #42 remains open.
  - `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-structured-covariance-status-sync.md`
    — passed.
  - `git diff --check` — passed.
- Rose verdict: clean with limitations. Status/docs sync only: no behavior
  change, no lowrank/fa bridge payload, no R covariance syntax activation, no
  external comparator, no broad calibration claim, and no promotion.
