# 🎯 GOAL — Research-informed Retry-7 through D0F adjudication

```text
Run this arc in Codex only and deliver one research-informed Retry-7 D0F outcome.
HEADLINE: make route rebinding structurally difficult at the actual R adjudication
boundary, typed inside the Julia replay where the type system exists, and guarded
by weighted route-lineage conservation before any receipt can be written. First
reproduce Retry-6's rebind as a red, zero-fit test; then make it green with
route-specific admitted-evidence objects, no default route argument, a canonical
route-lineage artifact, and receipt-specific idempotent retry handling. IN PARALLEL,
use Hopper/Noether for the route and mutation contract, Gauss/Karpinski for the
Julia/storage boundary, and Grace/Rose for deployment, chronology, and claim safety;
keep all state-changing integration sequential. Only after full-cardinality D0F
and D1 synthetic lifecycle rehearsals, mutation controls, two separated exact-head
reviews, a disjoint seed reservation, clean Totoro deployment, preseal, and an
independent chronology audit are green may Retry-7 invoke its bootstrap and phenotype
seeds. Then run the 576-fit D0F campaign, independent base-R reconstruction, exact
Julia replay, weighted lineage validation, five post-run reviews, and adjudication.
DEFER behind a hard fence: actual D1-D4 compute, default-route activation,
public_covered_count changes, G10, merge, and release. DISCIPLINE: never use GitHub
Actions for campaign compute; preserve all Retry-1-6 roots/seeds, H2-2 drafts, and
the quarantined scaffold; stop immediately on a plumbing failure; if Retry-7 dies
in post-run plumbing, mint no Retry-8 until the adjudicator is re-architected again;
close with exact repo-visible evidence and an honest terminal handover.
```

## Current authority and frozen boundary

The 2026-07-16 authorization at Julia commit `0e76c985` supersedes the prior
"do not mint Retry-7" stop. The research at `6092ba72` is design input, not
activation evidence. Starting heads are Julia `6092ba72` and R `d104189`.

Retry 6 remains permanently
`UNADJUDICATED_POSTRUN_ADJUDICATOR_ROUTE_BLOCKER`; its root and complete
`2040000000` / `2041000000` seed spaces remain retired. Retry 1-5 state is also
immutable. Public routing remains held, `public_covered_count` remains 5, and
only the supplied-`Ginv` estimator is covered.

Preserve without inspection or staging:

- the two modified H2-2 Retry-5 draft files in both twins;
- Julia's untracked quarantined
  `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl`, recorded SHA-256
  `30838979b9f3aad7d3442204fb4a4a30345f24950000d7ecb23a20d63cad6155`;
- the unrelated R worktree and stash.

## Contract decisions

### Route-safe evidence

The load-bearing protection belongs in the R adjudication tooling because TSV
serialization erases Julia parametric types. Admission returns internal
route-specific evidence envelopes rather than bare data frames. Summary
reconstruction dispatches on the admitted envelope, accepts no route override,
and rejects raw or forged route combinations. The defaulted
`expected_route = "ordinary_auto_genomic"` post-run path is removed.

The tracked Julia D0F/D1 stage replay mirrors the route as an internal type
before serialization. This is defence-in-depth only: no `src/HSquared.jl`,
public engine payload, formula grammar, result payload, or R user API changes.

### Weighted route lineage

Before reviews, write canonical `stage_route_lineage.tsv` plus sidecar. Ordered
columns are:

```text
schema_version stage evidence_kind route group_kind group_id
source_attempt_count source_inventory_sha256
```

The schema is `v07-genomic-recovery-v3-route-lineage-1`.

- D0F has official/base-R/Julia x 3 design rows, each count 192.
- D1 has official/base-R/Julia x 12 cell rows, each count 48.
- The three D1 target-summary rows per cell never triple-count provenance.
- Weighted totals are exactly 576 for each evidence kind.
- Official/base-R routes are `ordinary_auto_genomic`; Julia is
  `julia_profile_replay`.
- Source inventory hashes are the authenticated corpus lock, base-R inventory,
  and Julia replay inventory respectively.

Every post-run review and the adjudication receipt bind
`route_lineage_sha256`.

### Idempotent exact receipt

Generic `v3r_write_once()` remains strict. Adjudication uses a dedicated exact
receipt committer:

- absent primary and sidecar: exclusive atomic create;
- complete, byte-identical, currently valid pair: verify and return;
- orphaned, stale, conflicting, or different pair: fail closed.

The receipt schema adds `adjudication_key_sha256`, a deterministic SHA-256 over
the stage, route-lineage hash, preseal/corpus/manifest hashes, evidence
inventories, summaries, reviews, and exact tool commits/hashes.

## Slice table

| Slice | Member | Model / effort | Dispatch | Estimate | Deliverable / dependency |
| --- | --- | --- | --- | ---: | --- |
| S0 Rehydrate and replace plan | Ada | Sol high | native/inherited | 30-45 min | Heads, sole ownership, preservation ledger, this plan |
| S1 Cheapest red gate | Hopper + Noether | Terra high | tiered-cli/enforced | 1-2 h | Retry-6 rebind and weighted-lineage red tests |
| S2 Route-safe admission | R contract builder | Terra high | tiered-cli/enforced isolated worktree | 2-4 h | Evidence envelopes, dispatch, raw-frame rejection |
| S3 Julia typed mirror | Karpinski | Terra high | tiered-cli/enforced isolated worktree | 1-2 h | Internal typed replay route only |
| S4 Lineage + receipt contract | R contract builder | Terra high | tiered-cli/enforced | 2-4 h | Lineage artifact, review/receipt bindings, exact-retry committer |
| S5 Full synthetic lifecycle | Fisher + builder | Terra high | tiered-cli/enforced | 3-5 h | 576-row D0F then D1 subprocess roots, no mocked finalizer |
| S6 Mutation campaign | Noether | Terra high | tiered-cli/enforced read-only | 2-3 h | Earliest-gate matrix and tree immutability |
| S7 Architecture review | Hopper + Gauss/Karpinski + Rose | Terra high | parallel tiered-cli/enforced | 1-2 h | NOT-DONE-first findings before seed reservation |
| S8 Retry-7 contract and seeds | Ada + seed-lock owner | Sol high | native/inherited | 1-2 h | Doc-49 amendment; reserve unused candidate phenotype `2042000000` and bootstrap `2043000000` only after expanded disjointness verification |
| S9 Land, check, and exact reviews | Ada; Fisher/Noether; then Hopper/Grace/Rose | Sol owner, Terra/Sol reviewers | two strictly separated batches | 3-6 h | Full local checks, commit/push exact heads, exact-head CI, then batch A and later batch B content-addressed ledgers |
| S10 Clean deploy and preseal | Ada + Grace | Sol high | native/inherited | 2-3 h | Deploy reviewed commits to fresh clean Totoro clones, remote synthetic rehearsal, canonical staging root, preseal written last |
| S11 Bootstrap, zero-seed preflight, chronology | Ada; then Rose | Sol high | sequential native work then tiered-cli/enforced read-only audit | 1-2 h | Revalidate preseal, materialize bootstrap, persist deployed-Julia zero-seed receipt, then independently prove phenotype admission chronology |
| S12 Retry-7 D0F | Ada + compute launcher | Sol high | native/inherited | compute-dependent | Admit phenotype RNG only after S11; inspect first fit, then complete 576 fits |
| S13 Post-run closure | Five reviewers + Ada | Terra reviewers, Sol owner | separated batches | 3-6 h | Three routes, lineage, reviews, adjudication, final validation |
| S14 Verify and consolidate | Rose + Ada | Sol high | independent verify then native consolidate | 1-2 h | Logs, reports, phase snapshot, handover |

Native Codex agents inherit the task model. Any claimed mixed-tier execution
must use `codex-tier-run.sh` and retain its dispatch manifest. State-changing
integration, seed reservation, deployment, preseal, RNG, and receipt creation
remain sequential. Exact-head CI and both review batches occur only after the
reviewed commits are pushed. Review batch A (Fisher + Noether) must close before
the later batch B (Hopper + Grace + Rose) begins. Any code/schema change after
exact-head review restarts S9.

## Test and acceptance gates

### Zero-fit architecture gate

- Reproduce the old Julia-to-ordinary rebind as a red test before repair.
- After repair, summary reconstruction accepts only admitted evidence and no
  route argument.
- Raw frames, forged envelope/route combinations, route overrides, and wrong
  driver commits fail before summary construction.
- Full-cardinality deterministic D0F and D1 fixtures each contain 576 rows.
- D1 binds the exact synthetic D0F `PASS/COMPLETE` root and receipt.
- Real `Rscript --vanilla` subprocesses run summary, lineage, five reviews,
  adjudication, exact receipt retry, `validate-final`, and tree validation.
- No test replaces `v3r_expected_final()`, `v3r_adjudicate_tables()`, summary
  constructors, or execution-context validation.

### Mutations

Mutate route/driver/implementation/tool hashes, lineage counts/groups/inventory,
summaries with regenerated sidecars, review order/verdict/path/tree, concurrent
writers, identical/conflicting receipt retries, D1 predecessor identity,
deployment cleanliness, preseal RNG state, and post-preseal tree bytes. Every
mutation records its expected and observed earliest gate, exit status, receipt
absence, and unchanged before/after tree digest.

### Pre-RNG gate

Five exact reviews bind identical pushed R/Julia commits and tool bytes after
exact-head CI. The new candidate seed spaces (`2042000000` phenotype and
`2043000000` bootstrap) are disjoint from all historical/retired spaces before
reservation. Totoro checkouts are clean and hash-matched. Schema-3 preseal does
not claim to bind CI, review ledgers, deployment, diagnostic preflight, or
chronology; those remain content-addressed external admission receipts checked
by chronology. The preseal preserves `.Random.seed`, is written last, and no
successor bootstrap manifest, attempt, packet, corpus lock,
recomputation, summary, lineage, post-run review, or adjudication receipt exists.

### Campaign gate

Revalidate the preseal from a clean process, then materialize the bootstrap and
run the deployed Julia zero-seed preflight. Persist both receipts. Independently
audit chronology only after those steps and before the first phenotype.
Inspect the first official fit for non-empty, finite, contract-valid output;
then continue to 576 fits with `OPENBLAS_NUM_THREADS=1` and no more than 96
Totoro workers. Lock the corpus only when complete. Base R and Julia each
reconstruct 576 authenticated rows. Numerical parity, lineage, five post-run
reviews, idempotent receipt handling, and `validate-final` must all pass.

## Stop rules

- A cleanly adjudicated scientific negative result is valid and terminal.
- Any pre-RNG failure blocks seed use and returns to the relevant gate.
- Any post-RNG plumbing failure freezes the root and full reserved spaces,
  creates no manual receipt, opens no D1, and forbids Retry-8 until a new
  adjudicator architecture is approved.
- A D0F `PASS/COMPLETE` stops with D1 eligible but unexecuted; D1 needs a new
  preregistration/preseal goal.
- Campaign compute is Totoro/DRAC only, never GitHub Actions.
- No activation, G10, merge, release, or covered-count change occurs here.

Estimated wall time is 16-28 focused hours plus Retry-7 compute. Write a durable
handover after the pre-RNG gate if context pressure requires a fresh sequential
Codex task.
