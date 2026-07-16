# 🎯 GOAL — Retry-7 exact-head evidence and pre-RNG admission

```text
Run this plan in Codex only, sequentially across HSquared.jl and hsquared. Deliver
one repo-visible, exact-head pre-RNG admission packet: fresh local checks, a
full-cardinality zero-fit D0F-to-D1 synthetic rehearsal, exact-head CI and two
separated review batches, then a clean Totoro deployment rehearsal and a Sol-owned
preseal/chronology decision. HEADLINE: prove the new route-safe adjudication and
typed replay contract on the precise pushed R/Julia heads before either Retry-7
seed space can reach RNG. IN PARALLEL: only read-only plan review and, after exact
heads are frozen, the independent reviewers within their prescribed batches.
DEFER AND FENCE: bootstrap materialization, phenotype draws, the 576-fit D0F
campaign, D1-D4 compute, default-route activation, G10, public_covered_count change,
merge, release, and any mutation of retired roots or protected Retry-5 drafts.
DISCIPLINE: a source/schema/tool-byte change restarts the exact-head gate; campaign
work runs only on Totoro/DRAC; preserve the protected state; report a clean negative
honestly; complete the after-task and handover evidence before closeout.
```

## Status and authority

This is a new execution plan derived from the already-landed architecture plan
[`2026-07-15-retry7-pre-rng-readiness-ultraplan.md`](2026-07-15-retry7-pre-rng-readiness-ultraplan.md),
the Retry-7 handover, and the 2026-07-16 research-first authorization. It does
not replace their scientific contract. It narrows the next work to the remaining
pre-RNG gates.

Starting exact heads are Julia `97681439` (origin matched) and R `b190a0c`
(origin matched), on `codex/2026-07-13-v07-performance-localization`. The only
permitted working-tree drift is the declared pair of Retry-5 drafts in each twin
and Julia's quarantined untracked downstream scaffold. Retry-1--6 roots and seed
spaces are immutable. Retry-7 phenotype `2042000000` and bootstrap `2043000000`
reservations remain unspent. `public_covered_count` remains 5.

The local runtime did not expose a live model-picker/catalog. Before any actual
dispatch, Ada must refresh the model IDs and effort controls from the current
Codex picker/runtime, then replace the provisional Luna/Terra/Sol labels below
with the live IDs in the dispatch manifest. No mixed-tier execution claim is
valid without the enforced tiered-cli receipt.

## Phase 0.25 prior-work sweep

| Surface | Evidence reused | Consequence |
| --- | --- | --- |
| Julia and R heads | matching pushed Retry-7 heads; declared protected drift only | do not repair, absorb, or regenerate protected material |
| Existing plan | S1--S8 architecture, seed reservation, and synthetic/mutation work are landed | start at S9 rather than reimplementing the contract |
| Handover | full exact-head checks, a new synthetic root, CI, reviews, Totoro rehearsal, then Sol gate remain | preserve their order and hard stops |
| Brain search | no newer Retry-7 execution record was retrieved | repository and handover remain the operational truth |
| R worktree/stash | unrelated non-Gaussian worktree and historical stash exist | leave untouched |

## Approval gate

This document is a plan, not authorization to execute. Before Phase 1, obtain
explicit approval for this plan and record the sole active owner on both twins.
If another HSquared/hsquared process, worktree movement, or unlisted drift appears,
stop, preserve state, and rehydrate rather than continuing.

## Slice table

| Slice | Member | Provisional model / effort | Dispatch | Estimate | Input → output | Dependency |
| --- | --- | --- | --- | ---: | --- | --- |
| S0 Plan review and owner lock | Rose + Shannon | Terra / high | tiered-cli/enforced, read-only | 30 min | this plan + heads → scope/overlap verdict | approval |
| S1 Exact-head local R gate | Ada/R owner | Terra / high | native/inherited, sequential | 1–2 h | R `b190a0c` → focused/full tests and fresh `R CMD check` log | S0 CLEAN |
| S2 Exact-head local Julia gate | Karpinski + Ada | Terra / high | native/inherited, sequential | 45–90 min | Julia `97681439` → `Pkg.test`, docs, replay selftest, sidecars, preamble log | S1 |
| S3 Zero-fit full-cardinality lifecycle | Curie + Fisher + Mrode + R owner | Terra / high | native/inherited, sequential integration | 1–2 h | exact twins → new synthetic root, D0F/D1 receipts, lineage/tree hashes | S1,S2 |
| S4 Exact-head evidence commit and CI | Grace + Ada | Terra / medium | native/inherited, sequential | 45–90 min + CI | check evidence only → pushed heads and package/docs CI links | S3 |
| S5 Review batch A | Fisher + Noether | Terra / high | tiered-cli/enforced, parallel read-only | 1–2 h | exact hashes/tool bytes → two independent CLEAN/BLOCKED ledgers | S4 CI green |
| S6 Review batch B | Hopper + Grace + Rose | Terra / high | tiered-cli/enforced, parallel read-only | 1–2 h | batch-A CLEAN exact heads → route/deploy/claim ledgers | S5 CLEAN |
| S7 Clean Totoro rehearsal | Grace + Ada | Terra / high | native/inherited, sequential | 2–3 h | fresh clean twin clones → launcher smoke, duplicate-receipt success, dirty-deploy rejection | S6 CLEAN |
| S8 Sol seed-contract/preseal decision | Ada + seed-lock owner | Sol / high | native/inherited, sequential | 1–2 h | all exact receipts → disjointness/retirement/deploy binding verdict and preseal (last) | S7 CLEAN |
| S9 Independent chronology audit | Rose | Sol / high | tiered-cli/enforced, read-only | 1–2 h | preseal + deployment receipts → proof that both spaces remain unused and no runtime artifact exists | S8 CLEAN |
| S10 Verify and consolidate | Rose + Ada | Sol / high | native/inherited | 1–2 h | all ledgers → check log, after-task, capability/debt confirmation, durable handover | S9 CLEAN |

Fan-out is two bounded read-only review batches: S5 has two reviewers in parallel;
S6 has three reviewers in parallel only after S5 closes. All integration,
deployment, receipt creation, and preseal actions are sequential. This fits one
focused session only through S4; S5--S10 should normally use a durable handover.

## Acceptance criteria and stop rules

1. S1 and S2 must run from the stated heads with no unexplained drift; `git diff
   --check` passes in both twins. The R check is freshly built, not a stale
   `*.Rcheck` directory.
2. S3 must use real R subprocess finalization and produce 576 synthetic rows at
   both D0F and D1, identical receipt retry, exact-tree validation, five synthetic
   CLEAN reviews, and recorded receipt/lineage/tree SHA-256 values. It may not
   invoke official RNG.
3. S4 must push documentation/check evidence only. GitHub Actions can run package
   checks and docs, never campaign compute or campaign artifacts.
4. Reviews must bind the exact same R/Julia commits and exact tool bytes; any
   source/schema/tool-byte change invalidates S5--S6 and restarts at S1.
5. S7's remote smoke must first prove non-empty valid output from fresh clean
   Totoro clones, then exercise duplicate receipt recognition and dirty-deployment
   rejection. It uses no official seed.
6. S8 is the first Sol-only decision. Preseal is written last, preserves
   `.Random.seed`, and does not materialize bootstrap data.
7. S9 must independently prove zero use of both Retry-7 seed spaces and absence
   of every post-preseal runtime artifact. A BLOCKED audit ends this plan before
   any bootstrap/phenotype action.

No plan outcome authorizes D0F RNG automatically. A separate explicit Sol
authorization is required after S10. Any pre-RNG defect returns to the relevant
implementation/review slice without seed use. Any post-RNG plumbing failure, if
later authorized work reaches that point, freezes the root and both spaces and
forbids Retry-8 pending a new adjudicator architecture.

## Verification and closure

Rose reviews the plan at S0 and independently audits the final chronology at S9.
At S10, rerun the relevant local checks from clean processes, compare the
status-only protected-state ledger against Phase 0.25 while explicitly excluding
the protected Retry-5 drafts and quarantined scaffold from inspection or hashing,
validate the after-task report, update the single live phase snapshot only if its
substantive state changed, and write a handover with exact commits, tool hashes,
reviewer receipts, remote-root path, and the next authorized action. Do not alter
public capability language unless a capability-status row and validation-debt
record independently support it.

## Grounded search

No new external evidence search is planned: the authorization and Ranganathan
research note are already landed inputs, and this slice is operational verification.
If a new architectural or scientific question appears, pause and offer a scoped
NotebookLM pass before changing the contract.
