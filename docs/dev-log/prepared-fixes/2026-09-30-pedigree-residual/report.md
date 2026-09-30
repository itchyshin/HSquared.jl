# Bounded pedigree residual correction proposal — 2026-09-30

## 1. Goal

Prepare a scratch correction for PD01 terminal-ramet refusal, PD02 cytoplasmic equality, and PD03–PD05 factual contract prose from the complete pedigree source review. Base candidate HEAD `6271cfd58651e69cd27a64dcf02cb8960a29e260`, source SHA-256 `522741349ecfca48afc29d06f04bf4f6a0206fbc84648606e1ebf9f5444267d4`.

Review receipt `/private/tmp/e1-pedigree-complete-current-review-20260930.md` accounts for all 889 base-source lines with zero gaps/overlaps. Its coverage PASS and acceptance HOLD remain historical base verdicts. This proposal is ready for parent independent review; it does not certify full pedigree acceptance or full E1/A2.

## 2. Implemented

- `clonal_relationship` now refuses any row explicitly marked as a clone when it occurs as a sire or dam, after link/cycle validation and before dense A construction. Supported terminal copies and transitive clone links retain the same matrix.
- Cytoplasmic lineage comparison uses `isequal`, matching normalized pedigree key/unique semantics, including NaN and signed-zero labels. ID policy and returned labels remain unchanged.
- Docs explicitly state Gamma group coordinates follow first appearance after pedigree normalization; Gamma itself is not reordered.
- Docs distinguish animal F from leading metafounder F, qualify full-sib D/AA constants by unrelated, non-inbred parents, and state the existing Gamma symmetry/PSD/PD scale and absolute inverse floor.

## 3a. Decisions and rejected alternatives

Used an O(n) scan of existing parent arrays, rather than clone-aware sexual recursion or a new inheritance fitter. Did not forbid valid numeric labels to solve a grouping equality error. Preserved Gamma numerical policy exactly: the existing absolute eigen floor is an acceptance boundary, not a new condition-number claim. Group-order clarity is achieved by prose plus a labelled hand fixture; no API or Gamma-coordinate reorder was added. Retained experimental relationship primitive status and the existing assumption that ramets are recorded with unknown parents.

## 4. Files touched

Only this owned scratch directory: `baseline-pedigree.jl`, `src/pedigree.jl`, `test/pedigree_residual_contracts.jl`, `contracts.md`, `pedigree.patch`, `red.log`, `green.log`, `final-green.log`, `final-run.jl`, `package/`, `replay/`, `pins.json` and this report. No live source, runner, docs/status row, Git index, commit, push or other lane file changed.

## 5. Checks run

The primary test was frozen at SHA-256 `b5340105415224aa1ca2602107c5da4feafddfbeedff84bdd6bde2c78cb00670` before source edits. Baseline run: **25 PASS / 5 FAIL / 0 ERROR**, exit 1, 2.8 s body. All five failures are the intended PD01–PD02 regressions: sire, dam and transitive ramet parenting accepted; NaN lineage diagonal wrong; signed-zero lineages merged.

First prepared source: **30/30 PASS**, exit 0, 2.3 s. Final source after doc formatting: **30/30 PASS** plus existing selected construction testsets **53 cytoplasmic + 15 clonal + 22 dominance + 13 epistatic + 19 metafounder = 122/122 PASS**, combined **152/152**, process exit 0. Final body times 2.4/0.1/0.1/0.0/0.1/0.9 s. `final-run.jl` parses and evaluates only these five non-fitting existing testsets and asserts every selected name was found; it does not execute the complete runner.

Julia 1.10.0, measured JuliaThreads=1 and BLASThreads=1, `--compiled-modules=no --startup-file=no`. Existing Project/Manifest and depot reused without resolve/update. Green and final runs each estimated below two minutes before launch. No optimizer, simulation, inherited stress rerun, campaign, remote compute, GPU, Pkg.test or docs build ran.

Patch apply-check passed against the actual live unchanged base. Independent scratch replay applies exactly and byte-matches both proposed source and test. The proposed source is `6f4661f1e64dd0c079595be5b754813ba66ea998fc301bdcbd5422c5cdf72f86`; patch `3e09499f65e37de33bf91260c156ca65212e004c2dd5d300fddcdeffe9153852`.

## 6. Tests of the tests

The frozen primary test reached all 30 checks against both sources. It failed solely on missing refusal/wrong equality behavior on the baseline. Positive controls include ordinary maternal lineages, no-clone reduction, exact terminal/transitive clone rows, rank/variance and invalid link/cycle cases. Gamma hand diagonals and animal F are independent of wrapper parity; full-sib related-parent constants are derived analytically. Existing signed neighbor testsets keep their original test bodies, covering their existing matrices and guards.

No optimizer convergence metadata or finite matrix result is presented as inheritance fitting evidence. The retained depth-80/20-check and 12,000-chain evidence is unchanged historical evidence, not part of this 152 count.

## 7a. Issue ledger

- PD01: source-level terminal-ramet refusal repaired in proposal; clone-aware sexual parenting remains unsupported.
- PD02: equality inconsistency repaired in proposal while preserving ID policy.
- PD03: normalized Gamma group order clarified and labelled independently tested; a labelled API remains future work.
- PD04: numerical Gamma acceptance boundary stated accurately; eigen/jitter/scale policy unchanged and not broadened.
- PD05: animal/base F and full-sib example wording corrected; general inbred-dominance/epistasis fitting not added.
- Whole E1/A2/V3 and non-GPU inheritance fitting: remain OPEN/queued. No capability promotion follows.

## 8. Consistency audit

Exact body comparisons confirm no numerical edits to normalization, `_numerator_relationship`, heap/inbreeding, ordinary sparse inverse assembly, Mendelian formula, `_validate_gamma`, `_metafounder_combined_A`, metafounder wrappers/combined inverse, dominance or epistasis. All numerical changes are the one equality expression and the explicit clonal input-refusal scan. The clone guard scans sire/dam directly and requires a nonzero clone mapping, so ordinary sexual genets remain valid and clone-link traversal retains its original cycle behavior.

The source contract, frozen tests and report agree on normalized group order, terminal-only clones and preserved Gamma policy. Parent owns eventual matching public status/debt prose after independent review; current live documentation may still describe the known unfenced base defect.

## 9. What did not go smoothly

The dedicated runtime estimate immediately before the red primary invocation was omitted; this is an estimate-discipline lapse, not a source/test failure. The earlier standalone review probe was estimated below one minute, and both green/final launches were estimated below two minutes before launch. The red run was bounded no-fit helper work (2.8 s test body) and ran no campaign. This omission is recorded rather than claimed as compliant.

Graph automatic cache write was sandbox-denied during source context retrieval; exact current spans/pins controlled the review. Source changes from the parent's multivariate integration did not alter pedigree. No unrelated work was reverted.

## 10. Known residuals

Pedigree vector mutation after construction remains caller responsibility. Arbitrary ancestry depth and dense resource guarantees remain unproven beyond retained fixtures/caps. Terminal ramets still must be represented with unknown sexual parents; a future contradictory clone-plus-recorded-parent policy is not certified by this refusal. General breeding through ramets, inbred dominance covariance, labelled metafounder input API, Gamma acceptance broadening, new inheritance fitting/recovery, calibration, bridge/public capability, GPU and releases are outside scope.

## 11. Team learning

A dictionary can correctly recode IDs while downstream grouping uses a different equality relation; use one key equality contract throughout. Refusing an unsupported inheritance path can protect a scientific result without implementing that path. A labelled hand fixture exposes group-coordinate semantics that self-consistency wrapper parity cannot. Historical executed stress evidence should remain explicitly retained rather than repeatedly requested.

This is the author's prepared proposal, not its own independent acceptance review. Parent ownership and existing source-review receipts governed scope; brain history was not used as numerical authority.

## 12. Cross-product coverage and integration

Covers only Julia dense pedigree relationship primitives and their input contracts/documentation. Does not cover R behavior, animal-model variance fitting, broad MME/EBV correctness, inheritance recovery, interval calibration, automatic ranks, performance or release readiness.

Apply `pedigree.patch`, never replace the parent's complete source snapshot. The patch introduces `test/pedigree_residual_contracts.jl`; parent should register it once in a distinct test namespace after independent review. Remeasure composed-tree pins and run required relevant verification after registration. Parent owns consistency updates for terminal-ramet status/debt prose; do not promote any capability from this patch.
