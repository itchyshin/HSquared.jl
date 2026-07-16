# Codex handover — Retry-7 Terra/high implementation lane

**Date:** 2026-07-16

**From:** Codex Sol architecture/plan checkpoint

**To:** one fresh Codex Terra/high implementation task

**Branch in both twins:** `codex/2026-07-13-v07-performance-localization`

**Status:** architecture and seed contract landed; no official Retry-7 RNG used

## Goal

Continue the approved research-informed Retry-7 D0F arc from the landed
architecture checkpoint. The immediate Terra/high scope is exact-head package
verification, clean deployment rehearsal, and preparation of the pre-RNG gate.
Use explicit Sol jobs only for the seed-contract decision, adjudication, and
final adversarial gates. Do not invoke official phenotype or bootstrap RNG until
every pre-RNG gate below is green.

## Read first

1. `AGENTS.md` — its single live phase snapshot is the current start point.
2. `docs/superpowers/plans/2026-07-15-retry7-pre-rng-readiness-ultraplan.md`.
3. `docs/dev-log/after-task/2026-07-16-retry7-architecture-seed-contract-checkpoint.md`.
4. R twin `docs/design/49-v07-genomic-recovery-v3-sample-size-ladder.md`.
5. R twin `docs/dev-log/after-task/2026-07-16-retry7-architecture-seed-contract-checkpoint.md`.
6. Authorization and research inputs:
   `docs/dev-log/handover/2026-07-16-retry7-research-first-authorization.md`
   and
   `docs/dev-log/scout/2026-07-16-postrun-adjudicator-provenance-research.md`.

## Ownership and operating boundary

- This handover has exactly one live consumer: the new Terra/high Codex task.
- Claude and Codex remain sequential. Do not create another editing lane in
  either twin while this task owns them.
- Parallel work is allowed only for read-only reviews or genuinely disjoint
  worktrees. Integration, deployment, receipt creation, and RNG are sequential.
- The R package owns the public boundary. The Julia changes are confined to the
  tracked operational replay; do not change `src/HSquared.jl`, public payloads,
  formula grammar, result shapes, or the R user API.
- Campaign compute is Totoro/DRAC only, never GitHub Actions. Keep Totoro at no
  more than 96 single-threaded workers for this arc.

## Landed checkpoint

- R twin exact checkpoint: `b190a0cebbefa9af195b0722a5ab77be72474a71`
  (`Harden Retry-7 adjudication contract`), pushed to origin.
- Julia operational implementation checkpoint:
  `7858c4ce8458c0a64698d0fb534f006e9a0e3443`
  (`Type Retry-7 replay route evidence`). The branch tip also contains this
  handover and phase/audit documentation; resolve and bind the current origin
  HEAD before exact-head reviews.
- Earlier Julia authorization/research commits remain in ancestry:
  `0e76c985` and `6092ba72`.
- Draft PRs remain #137 (R) and #274 (Julia). Do not merge them in this arc.

## What is implemented

### R adjudication boundary

- Locked route-specific admitted-evidence envelopes with smart constructors,
  exact row seals, and S3 summary dispatch; there is no caller-supplied or
  defaulted route argument.
- Canonical `stage_route_lineage.tsv` with authenticated source inventories.
  D0F has 9 rows (official/base-R/Julia by three designs); D1 has 36 rows
  (three evidence kinds by twelve cells). Each evidence kind weighs to 576.
- Adjudication schema v2 binds lineage, summaries, reviews, evidence
  inventories, preseal/corpus/manifest provenance, exact tool bytes, and a
  deterministic `adjudication_key_sha256`.
- Receipt-specific exact retry: an absent primary/sidecar pair is created
  exclusively; a complete byte-identical valid pair is recognized; stale,
  orphaned, conflicting, or byte-different pairs fail closed.
- A full 576-row synthetic D0F-to-D1 lifecycle plus mutation campaign exercises
  the real R subprocess finalizer and receipt retry path.

### Julia replay mirror

- Internal `EvidenceRoute` and `EvidenceRow{R}` types preserve route identity
  through replay and summary dispatch. Serialized route is derived from type.
- D1 predecessor and pre-RNG review parsing use schema v2 and bind lineage,
  adjudication key, and all three tool hashes.
- No engine numerical code, public Julia API, package metadata, or result
  payload changed.

### Seed contract

- Retry-7 phenotype base: `2042000000` (576 seeds).
- Retry-7 bootstrap base: `2043000000` (3 seeds).
- The 579 reservations are disjoint from 42,067 historical/retired seeds and
  91,728 proposed D1-D4 seeds.
- Expanding and validating these integers consumed no RNG. Neither reserved
  space has been invoked.

## Evidence already green

- Full R `devtools::test()` with the Retry-7 mutation gate: PASS, no failures;
  59 documented live/comparator skips.
- Julia `Pkg.test()`: PASS.
- Julia Documenter build: PASS with pre-existing docstring/assets warnings and
  no deployment.
- Julia replay synthetic selftest: PASS; explicitly no official RNG.
- Canonical pre-seed-constant lifecycle root:
  `/private/tmp/hsq-retry7-synthetic-s7-canonical-v3`.
  D0F receipt `e4b2fde27be49fbd59d37363cbfdf3f1aaefd2074db4f5bc421b99a2748b3f90`;
  D1 receipt `4a82def6c522e0908a0528c85a788eb794f201ccbf093d09f13f0744c1cb6bf5`.
  This root proves the architecture but predates the final Retry-7 seed constant
  update, so it is not final exact-head evidence.
- Independent S7 architecture reviews: R CLEAN; Julia CLEAN; Grace/Rose CLEAN.
- Both after-task reports pass the canonical structure validator; Julia
  `tools/preamble_cap.sh` passes with exactly one live snapshot.

## Next Immediate Steps

1. Rehydrate both repos and confirm sole ownership, exact origin heads, clean
   tracked state apart from the declared carried-over files, matching sidecars,
   and no live Totoro/DRAC recovery-v3 process.
2. On the unchanged landed heads, run the fresh exact-head local gate:
   focused recovery-v3 tests, full R tests, built-source `R CMD check
   --no-manual`, Julia 1.10 `Pkg.test()`, Julia docs, replay selftest,
   sidecars, `git diff --check`, and `tools/preamble_cap.sh`.
3. Rerun the full-cardinality D0F-to-D1 synthetic lifecycle after the final seed
   and parity-pin changes. Exercise identical receipt retry and exact-tree final
   validation. Record the new root, receipt hashes, lineage hashes, counts, and
   five CLEAN reviews in repo-visible evidence.
4. Push any documentation-only check evidence. Wait for package-check/docs CI;
   GitHub Actions must not run campaign compute or retain campaign artifacts.
5. Obtain the separated exact-head reviews required by the ultra-plan. Any
   source/schema/tool-byte change invalidates them and restarts this gate.
6. Deploy the exact reviewed R and Julia heads to fresh clean Totoro checkouts.
   Run the deployed synthetic launcher rehearsal, including duplicate receipt
   recognition and a dirty-deployment rejection. Do not use official seeds.
7. Prepare the canonical Retry-7 root and preseal inputs. At the seed-contract
   decision, stop Terra and run an explicit Sol job to verify disjoint seeds,
   retirement semantics, clean deployment, review bindings, and preseal
   chronology. Preseal is written last and must preserve `.Random.seed`.
8. Run the independent pre-RNG chronology audit. It must prove both reserved
   spaces unused and every post-preseal/runtime artifact absent.
9. Only after the Sol seed-contract gate and chronology audit are CLEAN may the
   Terra lane invoke bootstrap materialization and the phenotype seeds, inspect
   one official fit, and scale to the 576-fit D0F campaign on Totoro/DRAC.
10. On any post-RNG plumbing failure, freeze the root and both complete reserved
    spaces, write no manual receipt, open no D1, and mint no Retry-8. If compute
    completes, reconstruct all 576 base-R rows and 576 Julia rows, build
    summaries and weighted lineage, then stop for an explicit Sol adjudication
    job and final adversarial gate.

## Hard stop rules

- `public_covered_count` remains **5**; supplied-`Ginv` only.
- No default-route activation, G10, D1-D4 compute, merge, release, or public
  recovery claim is authorized.
- A clean scientific negative is a valid terminal D0F outcome.
- Any pre-RNG defect returns to implementation/review without seed use.
- Any post-RNG plumbing defect retires Retry-7 and forbids Retry-8 until the
  adjudicator architecture is approved again.
- Actual D1 compute is a separate goal even if D0F adjudicates `PASS/COMPLETE`.

## CARRIED-OVER — preserve exactly

Do not inspect, edit, stage, delete, hash-refresh, or absorb these into Retry-7:

- Julia and R modified Retry-5 drafts:
  `docs/dev-log/after-task/2026-07-15-v07-d0f-retry5-post-preseal-tree-blocker.md`
  and
  `docs/dev-log/check-log.d/2026-07-15-v07-d0f-retry5-post-preseal-tree-blocker.md`.
- Julia untracked quarantined scaffold:
  `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl`, recorded SHA-256
  `30838979…6155`.
- All Retry-1 through Retry-6 roots and their phenotype/bootstrap seed spaces.

These files make `git status` intentionally non-clean. The relevant requirement
is no unexplained tracked drift and no change to the declared protected state.

## Known residuals and gotchas

- The synthetic lifecycle deliberately uses precomputed evidence and a
  deployment-projection seam. It does not substitute for clean Totoro
  deployment and remote launcher rehearsal.
- A raw `testthat::test_dir()` does not load the package namespace for this
  suite. Use `devtools::test()` or the package's focused helper.
- Replay selftest syntax is `--mode=selftest`, not `--selftest`.
- Tree digests must exclude `.git`; mutable repository metadata is not campaign
  evidence.
- Route-count conservation catches the Retry-6 defect; shuffle invariance alone
  would not.
- Receipt retry compares canonical bytes, not merely parse-equivalent fields.
- Never regenerate a sidecar without treating the tool-byte change as a review
  invalidation.

## Resume command

```text
Rehydrate from docs/dev-log/handover/2026-07-16-codex-handover.md + the AGENTS.md snapshot, then continue the Retry-7 Next Immediate Steps. Run as Terra/high; call explicit Sol jobs only for seed contracts, adjudication, and final adversarial gates.
```
