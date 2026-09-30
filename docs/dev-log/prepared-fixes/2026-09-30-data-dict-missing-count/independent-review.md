# Independent dictionary missing-cell review

Date: 2026-09-30. Verdict: **PASS for isolated D1 correction**. Live source unchanged; integration and test registration remain open.

## Pins and scope

Prepared root: `/private/tmp/hsq-data-dict-missing-fix-20260930`. All supplied inventory entries independently matched, including the original red/green logs and receipt.

| Artifact | SHA-256 |
| --- | --- |
| Patch | `7f8255c686f74c097b4787d85742c0cc4c9a7dcaefea001fba98ad7e27ff26c1` |
| Frozen data source | `39efaac183375e0f735836e5c3d398a1b8f59fffb5b7e7f3b616678b01d727b8` |
| Prepared data source | `5ac87d115a0b8c41822f38cfb54cbdffc3f298578bbf1ddb9aec0edc6c823012` |
| Regression test | `080b4bb5e72a93d0585bfa52c2782ec4abde7ce3238bda5ad08bc3b1227c1bcb` |

The two-line change in prepared src/data.jl:1077–1079 uses source[name] for AbstractDict and retains existing _column access for other protocols. The names originate from physical dictionary keys, so Symbol/string names that normalize equally can still address their own values. ID exclusion at 1076 remains before value access. Matrix dispatch at 1067–1069 is unchanged. Graft literal lookup confirms the visible _data_genotype_status caller at 1027; the overload-ambiguous caller lookup alone was insufficient.

## Evidence

The supplied test's oracle at test/data_dict_missing_count_regression.jl:14–15 iterates original key/value pairs and directly counts missing/nothing; it does not call _column or the corrected helper. Four colliding-label cases include reversed missingness, combined missing/nothing and a no-missing case. Assertions at 19–23 check helper count, visible missing metric, retained duplicate count, physical marker-column count and input immutability. Lines 27–48 retain string-only, Symbol-only, custom ID, named tuple, matrix and ID-only controls.

Independent run in `/private/tmp/e1-data-dict-missing-independent-20260930` passed **29/29 in 1.1 seconds**, exit 0. Estimate stated beforehand: under one minute; Julia 1.10.0, one Julia/BLAS thread, --startup-file=no --compiled-modules=no, copied Manifest and parent-approved depot order. No fitting or simulation ran. Supplied original red log records 22 pass / 7 fail; this review reproduced green and verified the pinned red log rather than rerunning that baseline.

ID-only control values are nonmissing. A missing ID-cell exclusion control is absent, although the unchanged exclusion branch precedes counting. Input immutability is asserted for all four colliding-label cases. Arbitrary dictionary key protocols, table-shape validation, inferred ID behavior, genotype construction and downstream fitting remain outside D1.

## Disposition and next step

No critical defect found. Land this exact patch after the source freeze and register the focused test. Source freeze, capability rows, gates and public count receive no new approval. This report and owned check directory are the only review writes.

Graft reported 22,364 tokens saved for the data caller and literal lookups. No whole-source audit was repeated.
