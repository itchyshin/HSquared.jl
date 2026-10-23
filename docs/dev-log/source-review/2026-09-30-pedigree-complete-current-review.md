# E1 complete current pedigree source review — 2026-09-30

## Verdict: coverage and acceptance

**Source coverage PASS: all 889 current lines have a disjoint disposition, with zero gaps and overlaps. Acceptance HOLD for the bounded defects PD01–PD02 and factual wording below.** Ordinary diploid pedigree construction/inversion approvals remain usable within their evidence. This report is not an inheritance fitting, E1/A2/V3, campaign, performance or release signoff.

Candidate: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`, HEAD `6271cfd58651e69cd27a64dcf02cb8960a29e260`. Source SHA-256 before/after probes: `522741349ecfca48afc29d06f04bf4f6a0206fbc84648606e1ebf9f5444267d4`. Parent announced multivariate integration during this review; pedigree remained unchanged. Source was copied into owned scratch, never edited live.

## Complete disjoint span ledger

| Current lines | Count | Disposition |
|---|---:|---|
| 1–72 | 72 | Direct constructor, show/length and contract prose freshly read. Exact ID uniqueness, original-order permutation, earlier parent indices, custom markers, selfing policy. Current default rejects same known sire/dam; old faccb receipt's policy question is superseded. Mutable contained vectors remain caller-owned. |
| 73–136 | 64 | Normalization, parent-key recoding, input lengths and ordering freshly reattested. Its current delta forwards missing_values/allow_selfing through direct construction; parent-index/topological bodies match baseline exactly. |
| 137–208 | 72 | Dense A/subset and Mendelian-variance helpers plus additive docstrings read. Tabular recursion agrees with hand matrix and T⁻¹D⁻¹T identity; dense cache cap preserved. Exact body witnesses reuse baseline routines; known-inbred missing mate evidence remains current. |
| 209–328 | 120 | Additive wrapper and heap/Meuwissen–Luo/inbreeding span read. Heap visits decreasing ancestral indices; duplicate sire/dam weights accumulate. Unknown mate convention gives F=0; no universal complexity bound. Bodies exactly match baseline; approved 12,000 fixtures are retained, not rerun. |
| 329–376 | 48 | Sparse inverse and raw overloads reattested. Henderson duplicate-parent outer products sum correctly. Current known-parent signed spans 337–367 reused; body exactly matches baseline. Positive-variance check retains Float64 selfing limit. |
| 377–451 | 75 | Maternal-lineage/cytoplasmic methods and clonal prose freshly reviewed. PD02: cytoplasmic == does not match normalized key equality. Singularity/grouping interpretation otherwise correct. |
| 452–501 | 50 | Clonal alias algorithm and dominance prose freshly reviewed. PD01: terminal-only rule is not enforced; sexual descendants of ramets can be wrong. Link length/ID/cycle controls otherwise present. |
| 502–577 | 76 | Dominance/epistasis bodies, raw wrappers and metafounder introduction read. Existing non-inbred-parent limitation retained; familiar full-sib constants need unrelated-parent qualification (PD05). |
| 578–685 | 108 | Group-index resolution, finite Γ ingress, symmetry/PSD/PD checks and combined recursion read. Γ order is stable first appearance after normalization (PD03); Γ numerical thresholds need accurate prose (PD04). Positive finite Mendelian variance guard independently exercised. |
| 686–837 | 152 | All metafounder relationship/inverse/inbreeding/combined-precision overloads and docs freshly read. Raw group_of reordering is correct; animal block inverse differs from combined precision. Current wrappers preserve custom missing markers/selfing controls. PD05 animal/base F wording conflates levels. |
| 838–867 | 30 | Parent lookup and recursive topological DFS freshly reattested, exact baseline body witnesses. Cycle and absent-parent rejection tested; retained reverse 12,000-chain evidence applies at tested depth. |
| 868–889 | 22 | End of topological function, Mendelian branches, unknown-marker isequal and repr covered. Current exact signed 868–878 review reused and remaining wrapper/end lines inspected. |

Machine ledger `/private/tmp/e1-pedigree-complete-current-review-20260930/span-pins.json` contains all 12 span hashes; arithmetic confirms 889/889, zero gaps, zero overlap. `function-reuse.json` compares exact top-level function text against committed baseline `faed40182cdbba2bf69f3e8dff0c5054be2dd214` by symbol, independently of stale line coordinates. Unchanged body is a reuse witness, not an approval promotion: inheritance bodies previously unread were inspected here.

## Reused signed evidence and reconciled state

Read current coverage reconciliation's pedigree entry; signed `2026-09-30-pedigree-review.md`, `2026-09-30-pedigree-core-spans-review.md`, constructor receipt, Wave3/Wave2 receipts, and deep-chain after-task evidence.

- `test/test_pedigree_inbred_known_parent.jl` still hashes `d6f123f702b929a2eb77745d22d1c4bfc7b0bf771ad4f20ea1ea680429b8f906`, matching the 5227 signed receipt. Retain its **20/20** historical execution, both inbred-known-parent positions, hand contributions, descendant F=1/16 and depth-80 Float64 zero-variance rejection. No rerun.
- Current constructor regression hashes `279150214497278f70607c707e1b1b035c504aea0d626264e3470057a1700554`, not the older core receipt's `2e3e...`. Current code/test rejects direct default same-parent construction, permits explicit allow_selfing, ignores irrelevant fully parented group entries, and exercises wrapper custom-marker/selfing alignment. The old unresolved same-parent-policy item is **DONE** in current bytes; do not carry it as an unfixed source defect.
- The reverse-listed **12,000-deep** normalization/inverse fixture and separately broad 12,000 ancestry fixture are registered and have retained signed execution evidence. The topological and sparse assembly bodies are byte-identical baseline witnesses. Arbitrary-depth/structure safety remains conditional; absence of a new stress rerun is not absence of existing evidence.

## Fresh bounded probes

Estimated below one minute before launch. Julia 1.10.0 with measured JuliaThreads=1 and BLASThreads=1, `--compiled-modules=no --startup-file=no`; standalone module includes the exact copied pedigree source. No package dependencies, statistical optimizer, dense large pedigree, campaign, GPU or remote run.

`/private/tmp/e1-pedigree-complete-current-review-20260930/probes.jl` and `probes.log`: **56/56 diagnostic assertions pass, process exit 0, test-body 3.6 s**. Some assertions deliberately pin reproduced wrong outputs; they prove findings, not acceptance of those outputs. Positive controls include a five-animal inbred hand A, explicit T⁻¹D⁻¹T inverse, F/d, cache semantics, maternal grouping, normal dominance/epistasis, Γ=0 reduction, two labelled Γ groups, combined round-trip/distinct animal inverse, malformed Γ/group/cache guards and raw-wrapper parity.

## Grounded findings and narrow dispositions

### PD01 — P2: refuse sexual parenting by ramets before constructing C

At 452–483 the helper computes ordinary pedigree A, then replaces clone rows by genet rows. Existing docs 432–450 require terminal ramets but admit that the function does not reject sexual-parent use.

Reproduction: P,Q are unrelated founders; G=P×Q; r is recorded as a founder and clone_of[r]=G; U is unrelated; h=r×U. Current `C[h,G]=0`, independently expected 1/2 for non-inbred G. Probe prints `PD01_RAMET_CHILD_GENET=0.0 EXPECTED=0.5`.

Narrow disposition: after validating/resolving clone links, flag every row occurring in sire/dam and reject when such a row has a nonzero clone link. Preserve transitive terminal clone chains and matrix behavior for supported inputs. This is an input refusal fence, not a clone-aware sexual recursion. No new inheritance fitter is needed. Existing prerequisite that ramets be recorded with unknown sexual parents remains explicit; contradictory clone-plus-sexual-parent-record semantics are not certified.

### PD02 — P2: match cytoplasmic grouping equality to accepted pedigree keys

At 425 dictionary-normalized IDs can use isequal-distinct values, while the cytoplasmic matrix uses `labels[i]==labels[j]`. Accepted NaN founder yields diagonal 0 instead of 1. Under custom marker `(nothing,)`, IDs -0.0/+0.0 remain distinct in normalize/unique but their unrelated maternal founder lineages are merged into a matrix of ones. Both are tiny executed witnesses.

Narrow disposition: use `isequal(labels[i],labels[j])`, matching unknown-marker tests and dictionary/unique key semantics. Preserve valid ID policy and caller labels; do not impose a new blanket finite/string-label restriction solely to fix grouping.

### PD03 — P2 contract clarification: Γ labels follow normalized order

The raw groups are correctly permuted, then columns are assigned first appearance in normalized pedigree order. Raw input `ids=[child,sire,dam]`, group_of=[child_group,founder_group,founder_group] resolves Γ rows `[founder_group,child_group]`. With Γ=[.2 .1;.1 .8], normalized animal diagonal is `[1.1,1.05,1.1]`; the supplied numeric Γ is not reordered from raw group appearance.

The implementation matches its normalized contract. Add visible prose that Γ coordinate order is first appearance **after** topological sorting and a labelled independent hand fixture. Existing parity tests use the same internal resolver, so cannot alone establish the user's coordinate interpretation. A new labelled-group API remains future work; no necessary numerical reorder is proposed.

### PD04 — existing numerical acceptance boundary: describe exact Γ thresholds

`_validate_gamma` uses s=max(1,max(abs Γ)): symmetry tolerance 1e-10s, PSD threshold -1e-10s, and inverse PD threshold >1e-12s. Thus Γ=[1e-14], condition number 1 with representable reciprocal, is accepted descriptively but refused by the combined inverse. This is an absolute floor at small scale, not a condition-number test.

Disposition: state the implemented boundary accurately in docs/diagnostic. Do not alter eigenvalue/jitter policy in this slice; a separate mathematical/numerical policy review is required for broader acceptance. Experimental primitive status remains conditional on this explicit boundary.

### PD05 — P2 factual wording: animal versus metafounder F, full-sib examples

At 750–751, the animal-inbreeding doc says F<0 when its metafounder self Γ<1. With one nonnegative group Γ=.4, animal F=.2, while the leading metafounder F=-.6. The animal formula is F_i=.5 A[parent_s,parent_d]; animal F can be negative when its parents' relationship is negative (e.g. permitted negative cross-group Γ), not merely because a metafounder diagonal is below one. Distinguish the base and animal levels explicitly.

At 491–500 and 538–542, the advertised full-sib D=1/4 and AA=1/4 require unrelated non-inbred parents. Two non-inbred full-sib parents a,b (relationship .5) produce full-sib offspring with D=5/16 and AA=9/16, as independently derived and executed. Qualify these familiar examples. Preserve the existing unit-diagonal/non-inbred-parent assumption and do not imply general inbred dominance covariance fitting.

## Other carried limitations

Pedigree stores mutable vectors by reference; mutation can invalidate earlier-row/ID invariants used by @inbounds routines. This review certifies validated unchanged objects, not arbitrary post-construction mutation. Standard raw A/inbreeding/MS wrappers do not all transport normalization keywords; use a normalized Pedigree for explicit selfing/custom-marker routes unless a separate API consistency change is authorized. Dense cache caps are row-count caps, not a complete memory budget. Tiny/tolerated Γ roundoff and inverse conditioning remain bounded numerical policies. No genetic inheritance primitive implies fitted-model recovery, MME/EBV estimation calibration, arbitrary-depth safety or broad biological generality.

## Operational limits

Only owned scratch report/probes/snapshots were written. The current source and other workers' files remained unchanged. Graph context preceded source inspection; automatic graph cache refresh was denied, so current spans/hashes and exact symbol witnesses governed review. The coverage inventory itself is historical context and not acceptance evidence. New non-GPU inheritance fitting remains queued. Full E1/A2 and campaign/release gates remain open.

Graph tool-estimated avoided reading for this pedigree slice: 147,110 tokens; not measured model-token usage.
