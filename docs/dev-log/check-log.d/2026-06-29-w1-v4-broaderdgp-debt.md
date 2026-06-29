# 2026-06-29 — W1 V4 broader-DGP debt characterization (Rose-audited)

- Drafted a debt-discharge proposal mapping the W1 Campaign 2 factorial + the σ²a bias-vs-n
  sweep to the V4-MV-REML standing debt.
- Ran a **real Rose audit** (`rose-systems-auditor` subagent) — verdict **revise-before-applying**:
  fences clean (no status/count change, comparators preserved, `V1-HERIT-TCAL` planned, covered=1),
  but "DISCHARGED" overclaimed, the σ²a small-q level was the noisiest of three runs, and the
  convergence claim was over-scoped (it=20000 only at q=400).
- Applied Rose's required changes: "discharged" → **characterized (partial)**; flagged the small-q
  bias level as MCSE-noisy across the 50/48/30-seed runs (the monotone DECAY is the robust signal);
  scoped the convergence claim to q=400 (inferred at small-n); carried the seed counts / 5-of-8 pass /
  single-record-boundary / R9-clean facts into the register append.
- Applied the corrected, additive-evidence append to the `V4-MV-REML` row (covered status UNCHANGED).

## Checks

- Rose audit: revise-before-applying → all required wording changes applied (verbatim verbs corrected).
- Status fence: V4-MV-REML stays `covered`; `validation_status()` count is a `src/` table, NOT this
  `.md` (count guard `test/runtests.jl:174 == 48` unaffected by a register-text edit); public-covered = 1;
  `V1-HERIT-TCAL` stays `planned`. No new covered flip, no 2nd-comparator debt change (Bayesian ≠ REML).
- `git diff --check` clean; foreign files never staged.

## Claim audit

Clean-with-corrections. Additive evidence + honest caveats on an already-covered row, the overclaiming
verb downgraded per Rose, the noisy small-q level and the scoped convergence claim corrected. Nothing
promoted; the 2nd same-estimand comparator + full-sib/3+-trait recovery remain owed. Maintainer nod
requested for the register edit (additive, not a status move).
