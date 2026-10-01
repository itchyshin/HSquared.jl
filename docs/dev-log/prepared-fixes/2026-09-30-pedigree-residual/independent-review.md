# Independent review: pedigree residual proposal

## 1. Goal

**Bounded PASS for PD01–PD05** at source `6f4661f1e64dd0c079595be5b754813ba66ea998fc301bdcbd5422c5cdf72f86`. Author Sol's proposal independently reviewed by Astra. Exact baseline is `522741349ecfca48afc29d06f04bf4f6a0206fbc84648606e1ebf9f5444267d4`, HEAD6271cfd58651e69cd27a64dcf02cb8960a29e260. Parent's full889-line read-only receipt supplies historical coverage; this review verifies its proposed narrow defect disposition. Broader inheritance fitting and programme acceptance remain separate.

## 2. Implemented

No implementation edit. Applied the exact author patch to a separately copied baseline in owned scratch, independently verified pins and reviewed all9 mutation groups. Verified that, after undoing the single equality-expression replacement and five-line guard, every remaining non-docstring source byte matches baseline. This preserves normalization, heap/inbreeding, ordinary sparse inverse, Gamma validation/eigen policy, combined recursion/inverse, dominance and epistasis.

## 3a. Decisions and Rejected Alternatives

Reject clone rows used as sire or dam before dense relationship construction. Keep ordinary sexual reproduction by a genet, terminal clones and transitive clone chains. This accurately fences an unsupported calculation without inventing clone-aware sexual recursion.

Use isequal consistently with Julia Dict/unique key semantics. NaN and signed-zero IDs remain supported under the existing missing-marker policy. Gamma coordinates follow first appearance among needed groups in normalized pedigree order; Gamma values are not permuted from caller-original group order. No numerical acceptance threshold was broadened.

## 4. Files Touched

Only `/private/tmp/hsq-pedigree-residual-independent-20260930/` and this report. No author packet, live source, runner or status document changed.

| Artifact | SHA256 |
| --- | --- |
| `/private/tmp/hsq-pedigree-residual-fix-20260930/report.md` | `78e8dad5a2d04acbc9af8952ef1f583174a62738d16828d8966894e62c761a69` |
| `/private/tmp/hsq-pedigree-residual-fix-20260930/pedigree.patch` | `3e09499f65e37de33bf91260c156ca65212e004c2dd5d300fddcdeffe9153852` |
| `/private/tmp/hsq-pedigree-residual-independent-20260930/package/src/pedigree.jl` | `6f4661f1e64dd0c079595be5b754813ba66ea998fc301bdcbd5422c5cdf72f86` |
| `/private/tmp/hsq-pedigree-residual-independent-20260930/package/test/pedigree_residual_contracts.jl` | `b5340105415224aa1ca2602107c5da4feafddfbeedff84bdd6bde2c78cb00670` |
| `/private/tmp/hsq-pedigree-residual-independent-20260930/independent-challenges.jl` | `fbc432368c1cba06fddee08de5b8f543e0fb363acdbd559c0fc15d6c795764f6` |
| `/private/tmp/hsq-pedigree-residual-independent-20260930/replay-run.jl` | `ac9ecb1293412fdf2060e8acfc59e52ce6c98c516ecdd611807f2f24be5f42fe` |
| `/private/tmp/hsq-pedigree-residual-independent-20260930/independent-final.log` | `1df5d3f9863d2d25651826c9f9674244bc3075133a9257ba1bc2e6b97942ac72` |
| `/private/tmp/hsq-pedigree-residual-independent-20260930/replay.json` | `2f008bd095926d88654a01aba251bbefab2254bd67004793a1f05d215a9cc23e` |
| `/private/tmp/hsq-pedigree-residual-independent-20260930/body-reattest.json` | `2613dd5f64af9980ff5db296e207c313a27f98f972e0c34e70052505a9c5bad0` |
| `/private/tmp/hsq-pedigree-residual-independent-20260930/existing-runtests-snapshot.jl` | `f3e7a9aab3842f1f934a8ef1ebf8050d97bcc78feb85a38cb5b8a6199bff0eda` |

## 5. Checks Run

All36 pins in author pins.json independently verified. Patch application reproduces prepared source and test byte for byte. Live pedigree was remeasured at unchanged522741baseline. Copied runner is pinned at f3e7a9aab3842f1f934a8ef1ebf8050d97bcc78feb85a38cb5b8a6199bff0eda; only its five named existing construction testsets were parsed/evaluated, with an assertion that all five names were found.

**179/179 PASS**, process exit0, wall21.54s. Components:30new author tests;122existing (53cytoplasmic,15clonal,22dominance,13epistatic,19metafounder);27independent challenges. Estimated under1min before launch, timeout60s; Julia1.10.0 measured1thread and BLAS1thread. Existing Project/Manifest/depot reused with no dependency updates, `--compiled-modules=no --startup-file=no`. No fitting, optimizer, simulation, stress chain, campaign or GPU work ran.

## 6. Tests of the Tests

Author test SHA b534010... was frozen before changes; retained baseline red25pass5fail pins verified. Those failures identify missing sire/dam/transitive-ramet rejection and wrong NaN/signed-zero lineage matrices. Green tests preserve ordinary supported neighboring behavior.

Independent tests use a handwritten five-animal additive matrix and exact clone row duplication, independently labelled three-group Gamma recursion (including cross-covariances, not merely wrapper equality), and a three-block maternal-lineage partition. An intentionally permuted Gamma matrix yields a different answer, demonstrating that the coordinate test can catch the proposed semantic confusion. The strict inverse threshold is challenged at1e-12 (reject) and its next Float64 value (accept). All27 pass.

## 7a. Issue Ledger

| Finding | Independent disposition |
| --- | --- |
| PD01 ramet used as sexual parent | PASS: guard checks nonzero clone links for each sire/dam after link/cycle validation and before denseA; ordinary genet offspring remain valid |
| PD02 key equality | PASS: isequal yields unit NaN diagonal and distinct signed-zero founder lineages, including descendants |
| PD03 Gamma group coordinates | PASS: prose matches normalized first-appearance order; independent3-group hand oracle confirms |
| PD04 Gamma numerical boundary | PASS as accurate documentation of existing s=max(1,maxabsGamma), symmetry/PSD tolerances and strict absolute inverse floor; no new conditioning guarantee |
| PD05 animal/base F and full-sib constants | PASS: founderGamma.4 gives animalF.2 while leading metafounderF=-.6; related non-inbred parents need different full-sib constants as tested |

## 8. Consistency Audit

Clone guard refers to whether the actual parent row is explicitly marked as a clone, which covers transitive copies without forbidding a genet that has both sexual offspring and terminal copies. Representative traversal and cycle error order are unchanged. Existing advice that ramets have unknown sexual parents remains visible; this patch does not validate every contradictory recorded-parent/clone combination.

Cytoplasmic equality matches the pedigree dictionary keys and does not reorder labels. Raw metafounder overload still permutes group_of by pedigree.original_order. Fully known-parent groups are ignored, so first appearance means first appearance among groups used by unknown-parent slots; the surrounding prose states this. Docs distinguish animal block inverse from augmented precision and animalF from leading baseF. Threshold text matches code exactly; a tiny well-conditioned Gamma can be rejected on absolute scale.

The existing889-line coverage receipt is retained. This review does not repeat or enlarge historical12,000-chain/depth80 evidence. Mutation count9, source length907; all additions are accountable to the two executable edits and factual docstring changes.

## 9. What Did Not Go Smoothly

No independent test failure or patch drift occurred. Author explicitly recorded an omitted pre-run estimate before its red run; this review preserves that operational lapse and does not rewrite it as compliant. Our numerical replay was estimated before launch and completed within estimate. Graft cache refresh was permission-denied; exact source/pins and literal identifiers governed review. Its tool-estimated avoided reading for this pedigree slice was330032tokens, not measured model-token usage.

## 10. Known Residuals

No new proof of arbitrary ancestry depth, dense resource bounds, post-construction mutation safety, general inbred dominance covariance, broad clone reproduction, labelled Gamma API, Gamma threshold optimality or inheritance fitting/recovery. Terminal clones with contradictory recorded sexual parents remain outside the documented input convention. Existing generic missing markers in clone_of are unchanged. Parent owns public status/debt consistency and test registration.

## 11. Team Learning

A small refusal guard can stop a scientifically wrong unsupported path while retaining valid construction helpers. Key equality must remain consistent downstream of normalization. Tests with explicit labels and hand cross-covariances establish coordinate meaning more strongly than wrapper self-consistency alone.

## 12. Cross-Product Coverage

Covers the Julia pedigree relationship-helper correction and its documented domain: clone-parent rejection, terminal/transitive clone rows, maternal-lineage key equality, Gamma group order, existing numerical boundary and factual examples. Proposed registration: include `test/pedigree_residual_contracts.jl` once after relevant existing pedigree dependencies. This review does NOT cover R behavior, new inherited-effect model fitting, EBV recovery/calibration, full E1/A2/V3, campaigns, GPU, performance or release. Parent should apply the narrow patch and retain exact composed-tree evidence; no whole-inheritance approval follows.
