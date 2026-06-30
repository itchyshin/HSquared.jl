# After-task — v0.4 (multivariate-unstructured) scoped covered close — 2026-06-29

## Task goal

Finish v0.4 following the locked-week plan (doc-18). v0.4 = multivariate-unstructured. The engine
model `V4-MV-REML` is ALREADY `covered` at validation scale (experimental, opt-in; NOT the public
default) per the doc-33 substitutable gate. "Finishing v0.4" = the SCOPED covered close: ratify the
covered claim with an explicit scope-of-validity + the W1 broader-DGP characterization + documented
boundaries, reconcile the cross-surface drift, confirm green checks, real Rose audit, and tee up the
non-delegable maintainer G10. Promote nothing new; public-covered FITTING surface stays 1.

## Active lenses and spawned agents

Lenses: Rose (mandatory), Gauss, Fisher, Curie, Noether, Grace, Ada. Spawned: ONE real
`rose-systems-auditor` subagent (claim-vs-evidence audit of the V4 scoped finish; verdict
PROMOTE-WITH-CHANGES; its two required edits were applied verbatim).

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
- BLUPF90 (the owed 2nd same-estimand comparator) was pursued: the UGA binary directory is reachable and
  an MKL-free path exists (`Linux/Test_static/`; Mac x86_64 under Rosetta; the modern suite uses
  `blupf90+ … OPTION method VCE`, not a standalone `airemlf90`). Download+execute was BLOCKED by the
  auto-mode classifier (untrusted third-party binary needs explicit user authorization). Filed as OWED
  hardening — per doc-18 it is optional, NOT a v0.4 blocker.

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
BLUPF90 + full-sib/3+-trait recovery + in-suite `sommer` test + deep-inbreeding remain OWED (covered does
not retire them).

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

- BLUPF90 download+execute was classifier-blocked (correctly — untrusted binary). Surfaced as a user
  authorization decision rather than worked around. v0.4 finishes without it (optional hardening).

## Known limitations

- v0.4 "covered" is validation-scale / opt-in, NOT a public-default multivariate release: no production
  sparse multivariate fitting, no R-facing model spec, no `result_payload()` widening.
- Broader-DGP recovery is characterized (partial), 5/8 — NOT a universal-recovery claim; two real scope
  edges remain (n-vanishing G[1,1] bias; single-record × extreme-r_g).
- The 2nd same-estimand REML comparator (BLUPF90/ASReml/DMU/WOMBAT) is still owed.

## Next actions

1. **Maintainer G10 (non-delegable):** ratify the V4-MV-REML scoped covered claim as edited.
2. **BLUPF90 authorization (your call):** approve downloading + running the UGA `blupf90+`/`renumf90`
   binaries to discharge the owed 2nd-comparator debt (optional hardening).
3. Push the branch + merge W1 PR #194 (Rose-clean + local checks green; no auto-merge).
4. D2 — heritability-interval default (profile-LRT) — separate slice, needs Codex + G10.
5. Still-owed V4 debt: full-sib + 3+-trait recovery; in-suite `sommer` test; deep-inbreeding boundary.
