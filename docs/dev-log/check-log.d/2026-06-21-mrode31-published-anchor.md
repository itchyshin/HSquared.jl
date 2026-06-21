# 2026-06-21 Mrode Example 3.1 Published Animal-Model Anchor

- Goal: add Julia-native evidence for issue #46 by pinning the published Mrode
  (2014) Example 3.1 animal-model EBVs and invariant sex contrast at supplied
  variance components.
- Active lenses: Ada, Shannon, Henderson, Mrode, Fisher, Curie, Grace, Rose.
- Spawned subagents: none.
- Starting point:
  - `main` at `945bd2a` after #138.
  - Post-#138 `main` CI, Documenter, and Pages were green before this branch
    was finalized.
- Implementation evidence:
  - Added testset `Phase 1 Mrode Example 3.1 published animal-model anchor
    (#46)`.
  - Inputs: Mrode Example 3.1 pedigree animals 1-8; records on animals 4-8;
    `WWG = [4.5, 2.9, 3.9, 3.5, 5.0]`; sex fixed effect; `sigma_a2 = 20`,
    `sigma_e2 = 40`.
  - Checks: Julia `fit_animal_model(...; target = :henderson_mme)` and direct
    `henderson_mme` reproduce the published EBVs to `atol = 1e-6`, and the
    male-minus-female sex contrast matches `0.95407223`.
  - Test of test: EBVs perturbed by `+0.1` are explicitly rejected at the same
    tolerance.
- Documentation/status updates:
  - `V1-MME` evidence now records the published Example 3.1 supplied-variance
    anchor.
  - `V1-DENSE-OUT`, the validation canon, public claims register, capability
    status, Documenter validation page, and coordination board were updated to
    remove stale "no EBV/source data" wording while keeping the estimated-VC
    and same-estimand comparator gates open.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` — passed. The new Mrode 3.1
    testset passed 9 checks inside the full suite.
  - `julia --project=docs docs/make.jl` — passed with existing local warnings
    for omitted internal docstrings, skipped deployment detection, substituted
    Vitepress defaults, missing logo/favicon, and npm audit output.
  - `git diff --check` — passed.
  - `rg -n "fitted textbook Mrode|fitted Mrode validation is covered|missing fitted Mrode|missing from the Mrode lane|no fitted Mrode|not fitted Mrode|fitted Mrode output validation remains planned|fitted Mrode animal-model outputs are validated|published Mrode Example 3.1|Mrode Example 3.1" docs/design docs/src src test docs/dev-log --glob '!docs/build/**' --glob '!docs/node_modules/**'`
    — current edited surfaces now describe Example 3.1 as supplied-variance
    evidence; remaining older hits are historical after-task/check-log
    snapshots or intentional boundary language.
- Boundary:
  - Published supplied-variance animal-model anchor only.
  - Not variance-component estimation.
  - Not same-estimand REML comparator parity.
  - Not sire-model implementation; R lane owns the Mrode 3.2 sire anchor.
  - No covered-status promotion.
  - No R files touched.
- Rose verdict: clean with limitations.
