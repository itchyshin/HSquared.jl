# After-task — 2026-09-08 A4-1 Binomial observation scale (Julia)

## 1. Goal

Close the authorized A4-1 Julia source slice: expose the numerically integrated
Binomial-logit observation-scale heritability in the *private* 0.9 envelope for
Bernoulli and scalar/common-trial Binomial fits, while retaining an explicit
non-scalar sentinel for varying trial counts.  This report records the candidate
evidence only.  It does not authorize a public claim, calibration, compute,
promotion, versioning, or release.

## 2. Active lenses and agents

The parent implementation lane owned the A4-1 source, tests, and design-contract
amendment.  This closure pass owns only this report and the accompanying check-log
entry.  No separate reviewer was asked to edit this documentation, and no foreign
lane's coordination board or handover was changed.

## 3. Candidate and files changed

The source candidate before this documentation closure was
`95b82ebdc441073ceb194bf9377116089ac48a88` on
`codex/hsq09-a3-julia-plan-7770`, comprising:

- `547114a9491effc27aca274fca4c8cbcc922451a` — A4-1 private-envelope
  Binomial observation-scale implementation, tests, and the scale-contract note.
- `95b82ebdc441073ceb194bf9377116089ac48a88` — canonicalization of an
  all-one trial vector to the Bernoulli/common-trial case, with its regression
  checks.

The implementation touches `src/nongaussian.jl`, `test/a3_three_field.jl`,
`test/a4_binomial_observation_scale.jl`, `test/runtests.jl`, and
`docs/design/19-h2-scale-contract.md`.  This closure changes only this report and
`docs/dev-log/check-log.md`.

## 4. Checks and outcomes

- Focused A4 test: `A4-1 Binomial-logit observation-scale payload` — **23/23**.
- Focused A3 regression: `A3 three-field private Julia envelope` — **44/44**.
- Full `Pkg.test()` — **exit 0** at the candidate head.
- Independent parent Unlazy re-verification — **3/3** gates met.
- `git diff --check origin/main...HEAD` — **pass**.

The focused checks establish finite, in-range observation-scale results for
Bernoulli and scalar/common-trial Binomial examples; all-one vector trials reduce
to the same common-trial result.  Varying trial vectors retain `NaN` and the exact
reason `varying_trials_no_scalar_estimand`.

## 5. Tests of the tests

The A4 test has negative controls for differing trial vectors and their order:
they must not be collapsed to a scalar or average denominator.  It also checks
that all-one vectors reduce to the Bernoulli representation.  The latter was
made intentionally RED during review: the initial implementation treated that
vector as a varying-trial sentinel, exposing the missing canonicalization; the
repair is `95b82ebd` and the regression assertion now guards it.  The ordinary
test harness includes both A3 and A4 files, and the full package suite passed
afterwards.

## 6. Public-claim audit

The new value remains in a private, versioned transport envelope.  It is not a
new public extractor or default fitting route.  No status row is flipped to
covered, and no claim of calibration, coverage, external same-estimand
comparison, promotion, or release is made here.  The private result's
varying-trial `NaN` is a deliberately named absence of a scalar estimand, not an
average-trial approximation.

## 7. Coordination and non-overlap

This worktree is isolated; no Dropbox original was edited.  A foreign Claude
lane owns `docs/dev-log/coordination-board.md` and handovers, so neither was
modified.  No S2, S3, or S9 artifact, remote job, or release material was
altered by this closure.

## 8. What did not go smoothly

The first A4 implementation did not recognize a vector of all ones as an
equivalent representation of the Bernoulli/common-trial case.  The focused
regression test exposed it, and the narrowly scoped canonicalization repair was
made before the reported re-verification.

## 9. Known limitations

This is experimental, intercept-only private-envelope behavior.  It supplies no
single observation-scale scalar for varying trial counts, no calibration or
H0/H1/H3 evidence, no retained campaign evidence, and no compute result.  It
does not authorize S10/S11, a capability promotion, version/tag/registry action,
or release.

## 10. Next actions

1. Keep the paired R bridge contract aligned and verify cross-twin parity at the
   declared tolerance.
2. Re-pin the later evidence manifest only after the paired candidate is settled.
3. Run no smoke or campaign computation without its separately approved gate;
   retain the existing release and promotion hold.
