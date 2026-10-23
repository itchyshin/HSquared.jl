# VS1-VS5 ledger synchronization preparation

Date: 2026-09-30. Reviewer: bounded Emmy/Hopper/Boole source-contract lane.

## 1. Result

PASS for scratch preparation and mechanical verification. Independent wording approval and live integration remain pending. The missing capability/debt edits are now authored, together with a dated objective note and a separate non-Gaussian docstring patch. E1 and all capability statuses remain unchanged.

## 2. Ownership

Only `/private/tmp/hsq-validation-ledger-sync-sol-20260930/` was written. The prior Luna scratch directory was read and preserved verbatim. Its useful objective interpretation was expanded in the requested design note. The approved FA source freeze was respected; no live code, tests, docs, metadata records, fits, campaigns, GPU runs, or external actions changed.

## 3. Deliverables

- `docs.patch`: two existing ledgers plus new `docs/design/legacy-laplace-objective-clarification.md`.
- `nongaussian-docstring.patch`: source docstring only, replacing original 643-648 inside the requested 640-648 block.
- `original/` and `proposed/`: exact before/after files.
- `hashinventory.json`: complete original/result pins, patch pins, row-signature pins, and changed lines.
- `prepare.py`, `verify.py`, and `apply-check/`: deterministic scratch authoring and independent application checks.
- `added-prose.md`: new wording extracted for prose lint.

## 4. Exact pins

The approved input source-wording patch remains `e2d76592dc28faa99c36808d063619e2cc80e25da107f2ef9794687a08cba042`. Applying it to a scratch copy produces the independently approved source hash `1d1d444bea3a5dc7a2dfccf5549b4d3082acfe3bf48761fe203a9d5f993c5316`. This reference source was used to synchronize the ledgers; it is excluded from these new patches.

| Artifact | SHA-256 |
|---|---|
| docs.patch | 5462382c48f55702cf04ac974370b94ec24dfc52544aca20a5afb68d5f0b0ba7 |
| nongaussian-docstring.patch | 4b702a972ea1f79c929614791b4849190d224c94783a857ea7e73b4f5a6d35a1 |
| Original capability ledger | daf32aaaa16834a148d2240336990ef835befe8a6df298be6007ce91288b3e01 |
| Result capability ledger | 10037f7361da6b71579e6eed2a0a940da2286772d9dd5288ebe5c427fd399bf3 |
| Original debt ledger | df409aab18c1de885acdabcbc84eacebac6956bc3bb2ef0ce936da1f5a41f46e |
| Result debt ledger | 6c72e93e45c3746d0b8e573d71eb2e9e15983b151c4a38aa6132f24e22cfb662 |
| New objective note | ad94ca5c1018f0174e1d14960bedc7d0662745fbc44ae20bad1cf3a85ed0a89a |
| Original nongaussian source | 24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00 |
| Result docstring-only source | a46ef8662b42d0acdff6b76ba949c556780d55ff54d52c3ae716684992333731 |

## 5. Changed lines and qualifications

Capability rows: 87, 88, 102, 122, 123, 131, 151, 152. Debt rows: 70, 85, 86, 94, 107, 108, 113, 114. Existing ledger line counts remain 170 and 127.

VS1: stochastic REML score fixed-point iteration; seed repeatability; relative component-change stopping without stationarity/unique-optimum/precision proof; trace-probe MCSE excluding PCG error; SLQ MCSE excluding finite-Lanczos bias and PCG error; AI limited by PCG accuracy; single-effect exact likelihood evaluated at the returned estimate even without convergence, with NaN when disabled.

VS2: historical q=860 and q=4060 comparisons retained, with the large-fixture exact-infeasible external comparator explicitly still owed. No universal external-software impossibility claim is introduced.

VS3: obsolete live counts 1 and 6 replaced with the already recorded 7. Dated historical counts elsewhere are untouched; no family/R activation or count expansion occurs.

VS4: July Ordinal/Gamma comparisons are cross-objective numerical proximity. External fixed effects are profiled; the engine integrates fixed and genetic effects jointly. Same-objective parity and causes of differences remain unproved. Historical owner-approved labels and recovery evidence remain. Ordinal has K−2 free spacings and K−1 returned cutpoints; supplied-family cutpoints remain K−1.

VS5: G/Ginv construction evidence and separately implemented supplied-precision fitted routes are distinguished. The supplied-variance repeatability solve points to separately implemented, partial/experimental REML estimation. No row inherits a neighboring covered status.

## 6. Historical measurements preserved

A numeric-token comparison of every changed row found no removed historical measurements, dates, sample sizes, tolerances, interpreter versions, job IDs, or original pins. Removed numeric tokens belong only to obsolete current counts, the redundant v0.1 count qualifier, or the obsolete second-comparator ordinal. Historical S5 actually ran and passed on 2026-09-01 at frozen `33ab68f6`; its 48/48 denominator, 0.0016/0.0007 truth differences, 0.0090/0.0052 exact-fit comparison, 0.0142 second-arm result, 3.5x margin, original interpreters, and open S6/S4/S7/S3 gates remain intact. The q=4060 values added to the two ledgers come from the independently approved source wording and its existing dated receipt.

## 7. Source-docstring scope

The prepared source patch defines density-one flat dβ in supplied X coordinates, normalized pedigree Gaussian integration, the joint observed-curvature Hessian, and `F - log|G|/2 + p*log(2π)/2 - log|H_joint|/2`. It distinguishes profiled-fixed-effect Laplace-ML, proper-integral requirements, Gaussian REML reduction, and compatibility naming.

Removing only the edited docstring from original and proposed files yields byte-identical source. The endpoint helper at original 609-637 is unchanged. The separately prepared Gauss endpoint patch must be composed and repinned by its owner; this result hash describes the docstring patch alone.

## 8. Mechanical checks

`verify.py` passed: live originals still match, both patches pass `git apply --check`, applying them to untouched scratch copies reproduces every proposed result hash, all existing table ID/title/status fields and row ordering match exactly, new-note links resolve to existing historical receipts, and the approved reference patch/result pins match. Table-row signature hashes and counts are recorded in `hashinventory.json`.

Absolute-path `slop_check.py` passed with zero findings on `added-prose.md` and the full new note. Both contain zero em dashes. Existing long ledger prose retains its original style outside the bounded edits; neither ledger adds an em dash.

## 9. Limits

This prepares documentation and a docstring. It supplies no fresh fits, objective equality tests, recovery, inference calibration, endpoint propriety proof, GPU evidence, or broad comparator approval. The approved source-wording patch had independent approval; these newly authored ledger/docstring patches still need the parent's independent wording review and composition check. No current-source S5 replay is implied by retained historical evidence.

## 10. Navigation and process

Existing named reviews and the independently approved scratch source supplied wording authority. Graft skeleton/ask supplied the exact non-Gaussian entrypoint, and current 640-648 and 722-736 were inspected. The `graft ask` call reports approximately 182,337 tokens saved; that is a whole-file-baseline tool estimate. The earlier skeleton output was truncated by a combined command, so its unretained estimate is excluded from this subtotal.

## 11. Parent next action

Review `docs.patch` and `nongaussian-docstring.patch` against the pinned originals. Keep the current source frozen while the approved FA campaign runs. When integration is authorized, compose these patches with the approved status-source wording and Gauss endpoint repair, repin the combined source, and regenerate/inspect the validation page. The parent owns report integration and E1 disposition.
