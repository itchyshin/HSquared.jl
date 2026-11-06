# M0/H0 final exact-hash planning review

Date: 2026-10-04. Scope: completeness, currentness, dependency mapping, and bounded next leaves for the non-GPU Julia/R capability inventory. This is planning-readiness evidence only.

## Reviewed artifacts

| Artifact | SHA-256 |
|---|---|
| Parent H2 completion plan | `dc30a25a1f052dadff19684537e4628e1ef24d480e9354932d2caa9eb2368d92` |
| M0 route crosswalk | `78a0693290e93a17deb3af1494a90ba78fc6b206944635ba80c358a9790c0091` |
| M0 acceptance map | `7c7664fb5432688c00ce10e429fc087af0b042d05199111ecd4ce773ca26d10a` |
| MV status correction | `95acee57f5bbb20dbf5bd767aa50fc395c8b12372ff3b16ee2bcae9f9e6d036f` |
| Preclosure root ledger | `13487a008e4ade3157c554bb161818d1fe27e047fd1842abcff126d8c4a70908` |

## Independent decisions

- Astra (`astra_completion_plan_challenge`) returned PASS for planning readiness. It verified the exact hashes, corrected sequence, covered k=2 boundary, retained Julia matrix-free evidence, both R Monte Carlo auto routes, and the planning-only scope.
- Rose (`m0_julia_inventory`) returned PASS for H0 readiness. It verified the exact hashes, current source pins, M0-08 and M0-12 next leaves, the Julia evidence split, and both R entry routes.
- Earlier read-only R inventory review found that `target = "multi_effect", scale_method = "auto"` and `target = "repeatability", scale_method = "auto"` may dispatch above the dense-infeasible threshold. Existing live R fixtures establish exact sparse execution only; no required-live test proves Monte Carlo dispatch, MCSE/provenance, accuracy, or failure behavior. This gap is assigned to M0-19b.

## Scope conclusions

M0 covers 20 route groups and seven separate file-format/encoding cases. VCF and BCF remain distinct fixtures. CPU and thread dispatch remain in scope; GPU execution alone is excluded. Existing supported scopes and retained evidence are preserved without promoting capability status. The next candidate validation work is the ordinary-start MV+PE paired-source/protocol freeze and independent review; the completed scoped unstructured-MV cell is not repeated absent source-regression evidence. Random regression retains the covered k=2 homogeneous-residual route and identifies an owed extension rather than repeating the completed gate.

## Limits

No Julia or R test suite, fit, pilot, or confirmation study ran in this review. The H0 pass closes inventory planning only. H1-H9, every route runtime gate, Arc 1 G0-G8, all capability-status changes, and the user approval required before any over-three-hour campaign remain open. The accepted source and test trees remain dirty and were not frozen by this review.
