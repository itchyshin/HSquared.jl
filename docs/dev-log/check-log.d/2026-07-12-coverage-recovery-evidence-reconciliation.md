# 2026-07-12 — coverage/recovery evidence reconciliation

- Goal: verify whether the four newly merged simulation drivers still needed execution.
- Active lenses: Ada/Shannon (lane and prior-work sweep), Curie/Fisher (simulation and
  estimand fidelity), Grace (DRAC provenance), Rose (claim fence). Two read-only plan-review
  subagents were dispatched; the main agent independently repeated the external checks.
- Git-first sweep: local `main` was clean at `a6955220`; driver branch head `2a473b8d` is an
  ancestor of `main`; no stash or worktree carried a newer driver implementation.
- Prior-work finding: sibling `hsquared` already banked these campaigns under doc 34. The
  stale Julia coordination entry was therefore unsafe to execute literally.
- External verification: direct SSH to `fir`; `sacct --array -X` confirmed 20/20 C1, 16/16
  C8, 3/3 supplied-K screen, 6/6 repeatability screen, 3/3 supplied-K confirm, and 40/40
  repeatability-resume tasks. The first repeatability confirm attempt timed out 40/40 at 90
  minutes; job 48040475 completed the same resume-safe seed blocks.
- Artifact checks: row/distinct-seed counts, machine-readable gate lines, SLURM submit lines,
  and directory checksum-manifest digests recorded in
  `../recovery-checkpoints/2026-07-12-coverage-recovery-evidence-reconciliation.md`.
- Decision: submit no duplicate compute. In particular, do not rerun the repeatability
  confirm: its 2,000-replicate marginal fail is frozen by doc 34 R4.
- Claim audit: no status promotion; `public_covered_count` remains 5.
- Independent Rose verdict: PROMOTE-WITH-CHANGES. Required narrowing C1 to the interpretable
  `q=120`, 0.95-level interior cells and restoring the pending Rose/maintainer ratification
  fence; applied before landing.
- Final local gates: `bash tools/preamble_cap.sh` PASS after moving the older live phase
  snapshot verbatim to the archive (1 live entry, 12,012 bytes); `git diff --check` PASS;
  active-board stale-claim scan clean; after-task R validator PASS; hub closeout compiler
  PASS; all five sbatch files pass `bash -n`; all four Julia drivers pass `Meta.parseall`;
  full `Pkg.test()` PASS (exit 0).
