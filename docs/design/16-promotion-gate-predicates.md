# Promotion-gate predicates (what `covered` requires)

Status: **the bar, not the state.** This doc states, per capability, the
falsifiable predicate required to move `partial` / `covered_external` / `planned`
→ `covered`. It **promotes nothing**. Repository state — the `status` field of
`validation_status()` and the passing tests — decides what *is* true; this doc
decides what *would be required*. Keyed by the `validation_status()` row `id`
(the canonical key in `src/validation_status.jl`) so the gate and the engine
table never drift.

Generalizes three existing precedents: the v0.1 Promotion Predicate
(`hsquared/docs/design/01-v0.1-contract.md`), the V4-MV-REML substitutable gate
(`hsquared/docs/design/33-v4-multivariate-promotion-gate-review.md` +
`docs/dev-log/decisions/2026-06-22-mv-reml-substitutable-gate.md`), and the
validation hierarchy (`docs/design/04-validation-canon.md` / `AGENTS.md` DoD).

## Generic covered predicate (the universal floor)

Every capability must clear ALL of:

- **G1** implementation in `src/`.
- **G2** deterministic, RNG-free in-suite tests (`test/runtests.jl`).
- **G3** docs + a runnable example, or an explicit not-public-yet note.
- **G4** a `capability-status.md` row (R lane, where user-facing).
- **G5** a `validation-debt-register.md` row + a `validation_status()` row.
- **G6** check-log evidence (exact commands + outcomes).
- **G7** an after-task report (`docs/dev-log/after-task/`).
- **G8** a real **Rose** claim-vs-evidence audit (a spawned subagent, not a lens).
- **G9** clean local checks (`Pkg.test`, `docs/make.jl`) + clean CI if pushed.
- **G10** maintainer **explicit sign-off** (covered is a public claim).
- **G11** for any ESTIMATOR additionally: a **known-truth recovery** result under
  a **pre-declared** pass gate (no post-hoc threshold relaxation — the
  `docs/dev-log/decisions/2026-06-14-calibration-failure-response` rule) **AND** a
  **same-estimand external comparator** (its KIND fixed — REML-vs-REML; Bayesian
  agreement such as MCMCglmm/JWAS does NOT substitute).

### Substitutability rule (from doc-33)

When no second *open* same-estimand comparator exists (the open-package reality
for multivariate-animal-model REML — only `sommer`), G11's comparator clause is
satisfiable by **either** (a) a second independent same-estimand REML lineage
(ASReml/BLUPF90/DMU/WOMBAT) **or** (b) a passing **pre-declared** known-truth
recovery gate, on top of the one existing same-estimand leg. The same-estimand
**kind** requirement is never waived.

## Per-capability predicate (delta on top of the floor)

Rather than copy 41 rows here (they would drift), the **capability-specific delta
for each row is its `missing` field in `validation_status()`** — that field is, by
construction, exactly "what remains before covered." Read it as the predicate:
the row reaches `covered` when the generic floor holds **and** every item in its
`missing` field is discharged (or substituted per the rule above). The
auto-generated burn-down (`sim/summarize_validation_debt.jl`, slice I9) lists
those `missing` items verbatim per open row.

### Worked exemplars (precedent, transcribed not invented)

- **v0.1 univariate Gaussian animal model** (`V1-AI-REML` covered; R `hsquared()`
  covered): the 4-item v0.1 predicate — gryphon published-REML anchor + `sommer`
  same-estimand agreement + known-truth DGP recovery + `at_boundary` surfacing
  (`01-v0.1-contract.md`). All satisfied.
- **`V1-MRODE-FIT` / `V1-COMPARATORS`** (`covered_external`): the published-canon
  + external-comparator legs of the same predicate. Covered *externally* — they
  still carry open `missing` debts (e.g. ASReml), so they appear in the burn-down.
- **`V4-MV-REML`** (`covered`, 2026-06-22): the substitutable gate via path (b) —
  one `sommer` same-estimand leg + a **pre-declared** 48-seed recovery gate that
  passed + a real Rose audit + sign-off. Retained debts (a 2nd same-estimand
  comparator, the in-suite unstructured-`sommer` test, broader-DGP recovery, the
  deep-inbreeding boundary) are **not retired** — see the next section.

## "Covered" does NOT retire debt

Promotion keeps the row's open `missing` items. `covered` means the predicate was
met at the declared scope (often experimental / validation-scale / opt-in — NOT
the public default), not that every related limitation is gone. The burn-down
(I9) therefore still lists a covered row's residual `missing` items.

## Maintenance

Keyed to `validation_status()` row IDs. When a row is added or promoted in
`src/validation_status.jl`, update its predicate understanding here in the same
slice. **Non-goals:** this is the human-authored gate — NOT the auto-generated
burn-down tracker (I9, `sim/summarize_validation_debt.jl`) and NOT the
mission-control `status.json` (A6). It records *what would be required*; those
report *what is*.
