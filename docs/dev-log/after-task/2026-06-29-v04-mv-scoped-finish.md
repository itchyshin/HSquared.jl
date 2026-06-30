# After-task — v0.4 (multivariate-unstructured) scoped covered close — 2026-06-29

## Task goal

Finish v0.4 following the locked-week plan (doc-18). v0.4 = multivariate-unstructured. The engine
model `V4-MV-REML` is ALREADY `covered` at validation scale (experimental, opt-in; NOT the public
default) per the doc-33 substitutable gate. "Finishing v0.4" = the SCOPED covered close: ratify the
covered claim with an explicit scope-of-validity + the W1 broader-DGP characterization + documented
boundaries, reconcile the cross-surface drift, confirm green checks, real Rose audit, and tee up the
non-delegable maintainer G10. Promote nothing new; public-covered FITTING surface stays 1.

## Active lenses and spawned agents

Lenses: Rose (mandatory), Gauss, Fisher, Curie, Noether, Grace, Ada. Spawned: TWO real
`rose-systems-auditor` subagents — (1) the V4 scoped finish (PROMOTE-WITH-CHANGES → two edits applied
verbatim); (2) the executed BLUPF90 comparator leg (PROMOTE-WITH-CHANGES → scope tag
"(point-estimate, single fixture)" + a gitignore-precision fix applied verbatim).

## Live phase snapshot

Branch `w1/2026-06-29-evidence-week-setup` @ `406f3100` (+ this slice; PR #194 open). `validation_status()`
= 48 rows (5 covered / 3 covered_external / 39 partial / 1 planned) — UNCHANGED. Public-covered fitting
= 1 (v0.1 Gaussian). V4-MV-REML stays `covered` (validation-scale); the close is a scoped RATIFICATION,
not a flip. No API / default / R-wording change.

## Files changed (this slice)

- `docs/design/capability-status.md` — Multivariate REML (estimate G0/R0) row: status `experimental` →
  `covered` (Rose Edit B: reconcile stale drift — the row predated the #161 covered promotion), closing
  fence rewritten to the covered framing + scope-of-validity.
- `docs/design/validation-debt-register.md` — V4-MV-REML row: added the explicit SCOPE OF VALIDITY
  sentence (Rose Edit A).
- `src/validation_status.jl` — V4-MV-REML function row: scope-of-validity appended to the limitations
  string (Edit A mirror); struck "larger-n" from the owed broader-recovery list since W1 characterized it
  (Edit C). No status-code or row-count change.
- `docs/dev-log/after-task/2026-06-29-v04-mv-scoped-finish.md` (this report) + check-log entry.
- **BLUPF90 leg (added this slice):** all three validation-scale surfaces also updated to record the
  executed `blupf90+` 2.60 comparator + the 2nd-comparator discharge (point-estimate, single fixture);
  `test/runtests.jl` V4 honesty-guards updated to the new wording (5 assertions); `.gitignore` extended for
  BLUPF90 run artifacts; NEW evidence record
  `docs/dev-log/recovery-checkpoints/2026-06-29-v4-blupf90-comparator.md`.

## What changed

- Established the green foundation owed from W1 (the W1 after-task explicitly never ran these): `Pkg.test()`
  PASS and `docs/make.jl` exit 0 — confirming PR #194 is CI-green-ready (the branch touches no `src/`
  beyond this slice's status text).
- Real Rose audit on the scoped finish → PROMOTE-WITH-CHANGES. Rose confirmed the covered claim is
  substantively honest (rests on the pre-declared 48-seed gate + one `sommer` same-estimand leg ≤8e-5;
  never says "unbiased"; W1's 5/8 factorial correctly filed as additive characterization with the covered
  scope `base_inside` passing → R9-clean), but flagged two mechanical blockers: no written scope-of-validity,
  and a stale `experimental` on capability-status. Both applied verbatim.
- Cross-surface reconciliation: all three VALIDATION-scale surfaces (the `validation_status()` function,
  the debt register, capability-status) now agree on `covered`; the PUBLIC-claims register stays `partial`
  (Rose finding 3: correct public-vs-validation layering — left untouched).
- BLUPF90 2nd same-estimand REML comparator — **EXECUTED** (user-authorized via the AskUserQuestion
  "Run BLUPF90 first" selection). Downloaded `renumf90` 1.166 + `blupf90+` 2.60 (Mac x86_64, statically
  linked / MKL-free per `otool -L`, run under Rosetta). `blupf90+` AI-REML from a **non-degenerate neutral
  start** independently converged (7 rounds, final 9.6e-13) to the same fixture optimum — G0/R0 ~1e-5
  (BLUPF90 5-sig-fig printout-limited), β ~1e-7, EBV correlation 1.000 both traits. A real Rose audit
  (PROMOTE-WITH-CHANGES) confirmed it is a genuine INDEPENDENT same-estimand REML leg (not started at the
  answer) and required the scope tag "(point-estimate, single fixture)". The 2nd-comparator owed item is
  now **DISCHARGED (point-estimate, single fixture)** across all three validation-scale surfaces. Evidence:
  `docs/dev-log/recovery-checkpoints/2026-06-29-v4-blupf90-comparator.md`.
- Found a real packet bug: `comparator/prepare_blupf90_multitrait.jl` writes `renumf90.par` with the
  datafile name INLINE (renumf90 needs keyword/value on separate lines) and EFFECT type `numer` (should be
  `alpha`). Worked around with a corrected `renumf90_fixed.par`; **fixing the prepare-script emitter is a
  noted follow-up** (not done this slice).

## Checks run and exact outcomes

- `Pkg.test()` (local, julia 1.10.0) — run twice (pre-edit and post-`src`-edit) → `Testing HSquared tests
  passed` (exit 0) both times; includes the `validation_status()` 48-row count guard
  (`test/runtests.jl:174`), the status-set guard (`:221`), and BLUPF90 packet preflight 37/37.
- `validation_status()` live → 48 rows, V4-MV-REML `covered`, counts 5/3/39/1 — UNCHANGED by the edits.
- `docs/make.jl` → exit 0 (benign no-logo / 28-docstrings warnings only; no errors).
- `git diff --check` → clean; the two foreign never-stage files remain untracked (verified).

## Public claim audit

Clean (Rose-audited). Nothing promoted; public-covered fitting = 1; `validation_status()` = 48 unchanged;
no public default / API / R-wording change. V4-MV-REML stays validation-scale `covered`, now with an
explicit scope-of-validity + the two documented boundaries. The public-claims register stays `partial`.
The BLUPF90 2nd-comparator is now executed + DISCHARGED (point-estimate, single fixture; Rose-audited);
full-sib/3+-trait recovery + in-suite `sommer` test + deep-inbreeding remain OWED (covered does not retire
them).

## Tests of the tests

The count guard + status-set guard re-pass on the edited `src/validation_status.jl`, proving the
scope-of-validity text and the larger-n strike did not change the row count or introduce a new status code.
The W1 DRAC evidence (fir `46235637`/`46237216`) carries committed seeds/versions + the pre-declared
aggregate bias/MCSE gate (ADEMP); the covered basis is the separate pre-declared 48-seed gate
(`a7b1f9ad`→`24ee2d9c`), not the W1 factorial.

## Coordination notes

Claude solo (baton held). No R files touched. D2 (interval default → profile-LRT) is a SEPARATE
public-contract slice needing Codex (R-twin) + G10 — not part of this scoped finish. If the maintainer
takes D2, a Codex hand-back is owed.

## What did not go smoothly

- BLUPF90 download+execute was first classifier-blocked (correctly — untrusted binary); surfaced as a user
  authorization decision, the user selected "Run BLUPF90 first", and it then ran successfully.
- The committed packet's `renumf90.par` did not run as-is (datafile-name-inline format bug + EFFECT `numer`);
  needed a manual `renumf90_fixed.par`. The prepare-script fix is a follow-up.

## Known limitations

- v0.4 "covered" is validation-scale / opt-in, NOT a public-default multivariate release: no production
  sparse multivariate fitting, no R-facing model spec, no `result_payload()` widening.
- Broader-DGP recovery is characterized (partial), 5/8 — NOT a universal-recovery claim; two real scope
  edges remain (n-vanishing G[1,1] bias; single-record × extreme-r_g).
- The BLUPF90 2nd same-estimand REML comparator is now executed but is ONE fixture / ONE (G,R) truth point
  (point-estimate, single fixture); broader multi-design comparator parity + full-sib/3+-trait recovery
  remain owed.

## Next actions

1. **Maintainer G10 (non-delegable):** ratify the V4-MV-REML scoped covered claim + the executed BLUPF90
   2nd-comparator discharge (point-estimate, single fixture), as edited.
2. Push the branch + merge PR #194 (Rose-clean ×2 + local checks green; no auto-merge).
3. **Follow-up (noted, not done):** fix the `prepare_blupf90_multitrait.jl` `renumf90.par` emitter
   (separate-line keyword/value; `cross alpha`; add `FILE_POS`) so the committed packet runs without the
   manual `renumf90_fixed.par`.
4. D2 — heritability-interval default (profile-LRT) — separate slice, needs Codex + G10.
5. Still-owed V4 debt: full-sib + 3+-trait recovery (incl. broader multi-design comparator parity);
   in-suite `sommer` test; deep-inbreeding boundary.
