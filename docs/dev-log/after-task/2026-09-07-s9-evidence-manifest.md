# After-task — 2026-09-07 S9 source-inert evidence manifest

**Scope:** source-only binding from Julia S8 base
1dbf8b97a3b28f814e3418239ac1658acbbc19bb and clean R S7 candidate
e6a1ce4e8a691795487420668b349fb9e2670059. No smoke, campaign, scientific
result, public behavior, release action, or capability claim was added.

## 1. Goal

Bind the already-predeclared H0/H1/H3 source contracts to the exact S8 Julia
and S7 R candidates in a fail-closed manifest. Prove that this binding neither
executes nor implies a smoke, campaign, interval result, promotion,
version/count change, or release.

## 2. Implemented

Added an S9 TOML manifest, a standard-library Julia validator, and a dedicated
negative-control test. The manifest exact-pins the Julia S8 base and R S7
head, and pins SHA-256 hashes for all eleven governed protocol, driver, test,
template, and
validation-manifest inputs. It records separate H0, H1, and H3 terms; frozen
seed/stride/replication and conditional-coverage rules; H1-t's banked
characterization-only limit; H3's generating-G0/R0 initialization; and the
exact unarmed exit-78 scheduler template.

The validator is closed-schema. It requires the Julia S9 checkout to descend
from that exact S8 base, requires the R checkout to equal S7 exactly, and
rejects altered terms or hashes, wrong or dirty R roots, and every non-inert
authorization state.

## 3a. Decisions and Rejected Alternatives

S9 remains source binding, not a run of any available driver or an
interpretation of historical evidence. Interval_success remains the conditional
coverage denominator, separate from fit_converged; pooling is
sum(covered) / sum(I), not an average of cells.

Rose rejected an initial global H0 ratification statement because S9 cannot
adjudicate current H0 state. The final manifest says only that S9 authorizes no
new H0 action and does not adjudicate H0. The validator initially required
Julia HEAD to equal S8; that was replaced with the correct ancestry test.
Rejected smoke, screen, confirm,
campaign, covered flip, count/version change, tag, registry, and release work.

## 4. Files Touched

- docs/dev-log/evidence/2026-09-07-hsq09-s9-evidence-manifest.toml — exact
  provenance, hashes, frozen terms, and false action fence.
- tools/validate_hsq09_s9_manifest.jl — closed-schema, provenance, hash,
  source-contract, cleanliness, and active-template validator.
- test/test_hsq09_s9_manifest.jl — disposable-copy negative controls.
- docs/dev-log/after-task/2026-09-07-s9-evidence-manifest.md — this receipt.
- docs/dev-log/check-log.d/2026-09-07-s9-evidence-manifest.md — paired log.

No src, exported API, dependency declaration, R source, governed source,
fixture, simulation driver, scheduler template, result TSV, or release surface
changed. Julia materialized an ignored local Manifest.toml for its normal suite;
it left no tracked diff.

## 5. Checks Run

- Exact-pair validator: PASS, marker S9_MANIFEST_PAIR_OK; it confirms S8 is
  an ancestor of the S9 candidate and R is exact at S7.
- Exact-pair inert assertion: PASS, markers S9_MANIFEST_PAIR_OK and
  S9_INERT_OK.
- Dedicated disposable-copy negative-control test: PASS, marker
  S9_NEGATIVE_CONTROLS_OK; 39/39 assertions passed.
- Normal Julia Pkg.test() suite completed at candidate head; no tracked
  dependency change remained.
- The first Unlazy reverify hit its fixed 120-second timeout while that suite
  was still passing. The unchanged full-suite command was rerun through
  Unlazy's supported 300-second timeout and passed with
  Testing HSquared tests passed.
- git diff --check: PASS.
- Fisher protocol review and final independent Rose re-review: APPROVE.
- Standard after-task validation: PASS, including
  acceptance ledger: 3 file(s), every gate satisfied.

No simulation, benchmark, smoke, scheduler submission, comparator, CI dispatch,
documentation build, version bump, tag, push, registry, or release action ran.

## 6. Tests of the Tests

Disposable candidate copies prove rejection of altered master seed, denominator,
claim eligibility, Julia SHA, R SHA, governed-input hash, H0 authorization,
unknown result field, absent R root, wrong R root, and dirty R root. It accepts
a temporary committed S9 descendant but rejects an unrelated same-tree base.
The scheduler mutation changes exit 78 to exit 0 and updates its expected hash, so
rejection proves the semantic active-command guard rather than only hash
mismatch. The test invokes no driver, Rscript, sbatch, or evidence campaign.

The first Rose review is also a claim-boundary negative control: it rejected the
global H0 statement, after which the scope-only correction was mutation-tested
and independently approved.

## 7a. Issue Ledger

- Resolved: exact S8/S7 provenance and eleven governed inputs are pinned
  fail-closed.
- Resolved: the ignored Unlazy isolation predicate now compares physical
  worktree roots, not common Git metadata shared by linked worktrees.
- Resolved: S9 no longer makes an unqualified H0-ratification assertion.
- Resolved: the validator now proves S8 ancestry for the S9 checkout rather
  than incorrectly requiring S9 HEAD to equal its base; G5 remains the separate
  five-path scope proof.
- Recorded limitation: the ordinary full suite exceeds Unlazy's default
  120-second per-check ceiling on this host. It was not skipped or weakened;
  the final reverify used the tool's supported 300-second timeout and retained
  the initial timeout as diagnostic evidence.
- Deferred: S10 smoke authorization/output; S11 retained campaign; G6–G10;
  all coverage/calibration/comparator claims; promotion, versioning, CI, and
  release.

## 8. Consistency Audit

Manifest, validator, tests, Fisher review, and Rose audit agree that S9 is an
unrun contract: I equals interval_success, coverage is conditional on finite
ordered intervals, and I is never convergence. H0, H1, and H3 remain separate;
H1-t remains characterization-only, and H3 evidence would be conditional on
its generating-G0/R0 start.

Every action/result field is false. The template's only active commands refuse
and exit 78. All eleven input hashes resolve at the exact paired candidates;
the Julia checkout is proven to descend from S8 while R is exact at S7. Final
Rose verdict: APPROVE.

## 9. What Did Not Go Smoothly

Three review defects were caught before closeout. Linked worktrees share a common
Git directory, so that was not a valid isolation predicate; the ignored gate now
uses physical worktree roots. S9 also initially treated H0 as globally
unratified; it now records only S9's lack of authority to authorize or
adjudicate H0. Finally, the first provenance check confused an exact base pin
with an exact candidate HEAD; it now validates ancestry and is regression-tested
with both a committed descendant and an unrelated base.

The normal Julia environment needed its ignored manifest materialized. That
setup left no tracked change.

The default 120-second Unlazy ceiling also killed one full-suite reverify after
it had progressed through passing tests. The real command completes in roughly
three minutes here, so the final gate and standard after-task reverify used the
same command with the tool's supported 300-second limit. No test selection was
changed.

## 10. Known Residuals

S9 establishes no interval performance, coverage, calibration, recovery,
comparator agreement, or public non-Gaussian behavior. It does not validate
smoke output, runtime, scheduler resources, or retained denominator accounting.

**It does NOT authorize G6–G10, release, or compute.** S10 still needs a
separate explicit maintainer compute authorization and bounded estimate before
any Totoro feasibility run.

## 11. Team Learning

A source hash alone cannot show that a scheduler template still refuses
execution. Mutating the template while updating its expected hash tests the
useful semantic invariant. The same restraint applies to claim words: record
only the state this slice controls rather than asserting a global scientific or
governance status beyond its remit.

No durable-memory update or Golden-Set mutation was authorized.

## 12. Cross-Product Coverage

Covers ✓ exact S8 base ancestry and exact S7 identity, eleven source hashes,
source-only schema, H0/H1/H3 predeclared terms, false action/result fields, unarmed
scheduler refusal, malformed-manifest rejection, and normal Julia regression.

It does NOT cover ✗ S10 smoke output; S11 retained evidence; any H0/H1/H3
calibration or coverage result; comparator; R-public activation; fitting
behavior; promotion; counts; versioning; CI; tagging; registry; deployment;
release; or a Totoro/DRAC/local compute campaign. This receipt does NOT
authorize G6–G10, release, or compute.
