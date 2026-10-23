# Independent VS1–VS5 documentation synchronization review

Date: 2026-09-30. Verdict: **PASS for isolated ledger wording, interpretation note and docstring synchronization**. Source E1, composition, live integration and generated-page review remain open. No fit or mathematical proof was rerun.

## Exact artifacts

Prepared root: `/private/tmp/hsq-validation-ledger-sync-sol-20260930`. Independent applied copy: `/private/tmp/e1-validation-ledger-sync-independent-20260930`.

| Artifact | SHA-256 |
| --- | --- |
| Docs patch | `5462382c48f55702cf04ac974370b94ec24dfc52544aca20a5afb68d5f0b0ba7` |
| Docstring patch | `4b702a972ea1f79c929614791b4849190d224c94783a857ea7e73b4f5a6d35a1` |
| Result capability ledger | `10037f7361da6b71579e6eed2a0a940da2286772d9dd5288ebe5c427fd399bf3` |
| Result debt ledger | `6c72e93e45c3746d0b8e573d71eb2e9e15983b151c4a38aa6132f24e22cfb662` |
| New interpretation note | `ad94ca5c1018f0174e1d14960bedc7d0662745fbc44ae20bad1cf3a85ed0a89a` |
| Result docstring-only nongaussian | `a46ef8662b42d0acdff6b76ba949c556780d55ff54d52c3ae716684992333731` |
| Approved reference validation source | `1d1d444bea3a5dc7a2dfccf5549b4d3082acfe3bf48761fe203a9d5f993c5316` |

Original ledgers independently match live frozen docs: capability `daf32aaaa16834a148d2240336990ef835befe8a6df298be6007ce91288b3e01`, debt `df409aab18c1de885acdabcbc84eacebac6956bc3bb2ef0ce936da1f5a41f46e`. Original nongaussian source matches `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00`. Both patch hashes and all proposed-file hashes match inventory; scratch apply checks and application reproduce every result byte-for-byte. Candidate source tree remains `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` at the authorized `9c10f09c` HEAD. No live files changed.

## Bounded wording verdict

| Item | Reviewed current spans | Disposition |
| --- | --- | --- |
| VS1 matrix-free iteration and uncertainty | capability 87–88; debt 113–114 | Score fixed-point iteration replaces the EM description. Fixed probes provide seed repeatability; relative component-change stopping supplies no stationarity, unique/global optimum or parameter-precision proof. Trace MCSE excludes PCG error and parameter uncertainty; SLQ MCSE excludes finite-Lanczos bias and PCG error. Information is limited by PCG accuracy. Single-effect exact loglik is evaluated at the returned estimate even without convergence; disabling it returns NaN. |
| VS2 comparator scope | capability 87–88; debt 113–114 | q=860 and added historical q=4060 comparisons remain validation-scale evidence. Large-fixture, exact-infeasible external comparator debt remains explicit; no general external-software infeasibility claim appears. |
| VS3 public count | capability 131,151–152; debt 94,107–108,113 | Generic current counts become seven. All status fields remain identical; no activation or promotion follows. |
| VS4 legacy objective and ordinal parameterization | capability 151–152; debt 107–108; new note 5–35; original docstring 643–648 | July comparisons become cross-objective numerical proximity, with no demonstrated cause of differences. Flat density-one dβ in supplied X coordinates, normalized genetic Gaussian density, joint observed curvature and proper-integral requirements are explicit. Gaussian REML reduction is scoped to the same measure/normalization; general non-Gaussian REML/AI-REML is not established. Ordinal optimizes K−2 free spacings and returns K−1 cutpoints; supplied cutpoints still number K−1. |
| VS5 neighboring evidence | capability 102,122–123; debt 70,85–86 | G/Ginv construction stays separate from supplied-precision fitting. Existing supplied-variance repeatability solving points to separately implemented partial/experimental REML estimation. No neighboring covered status is inherited. |

The new note's integrated-Laplace formula retains the approved Astra qualifications: joint mode, normalized G prior, p*log(2π)/2 and joint observed-curvature determinant; profiled fixed effects generally optimize a different objective. The proper-integral caveat and unestablished same-objective comparator remain visible. This review checks the synchronization against the prior approved source wording and mathematical review; it supplies no new objective equivalence proof.

## Preservation and mechanical evidence

All 98 capability-table rows and 85 debt-table rows preserve their identifying fields, statuses and ordering. Existing ledger line counts remain 170 and 127. Exactly eight rows change in each ledger: capability 87,88,102,122,123,131,151,152; debt 70,85,86,94,107,108,113,114. Source metadata IDs and executable capability behavior receive no change through these patches.

An independent numeric-token multiset check for each changed row found no removed historical measurements. Removed numbers are only obsolete current counts, the redundant v0.1 qualifier and obsolete second-comparator ordinal. S5's 48/48 denominator, dated interpreters, frozen 33ab68f6 pin, truth differences 0.0016/0.0007, exact-fit differences 0.0090/0.0052, second-arm 0.0142 and 3.5x margin remain. July Ordinal/Gamma measurements remain; historical covered labels are preserved with current comparator qualification. Full token deltas are saved in the independent scratch directory.

All four historical receipt links in the new note resolve. The patches modify only the two existing ledgers, add the note, and alter the target docstring. No July receipt is included in the patches. Removing that single laplace_marginal_loglik docstring from original and proposed nongaussian yields byte-identical source, confirming no executable or endpoint-helper change.

The initial scratch command could not launch because its working directory did not yet exist; no command ran. Creating the owned directory and repeating the metadata checks completed successfully within the stated under-30-second estimate. No numerical run was needed. Exact file spans and approved reference evidence were already available, so no new Graft query was needed.

## Remaining gates

No wording blocker found. After the running-source freeze is released, compose the approved validation-source wording, this docstring and the separately reviewed endpoint guard, repin combined files, then regenerate and inspect the validation page. These isolated patches do not supply new recovery, inference calibration, GPU evidence, public-count expansion or completed E1 integration. Parent owns those dispositions.
