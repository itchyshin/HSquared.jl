# Arc1 seed-manifest revisions

The protocol identity is the SHA-256 of the canonical scientific contract, separate from the manifest/CSV byte hashes and any run-time source pins.

| State | Protocol SHA-256 | Outer CSV SHA-256 | Reason |
|---|---|---|---|
| Superseded draft | `137b5e03a6992d5784323561e37836f16715c595595c403e968bc70e2deca28d` | `9a4a1846d3794813442a9aad99d305f4aacc7868e299051d4816a9629a4576cd` | Incomplete scientific contract; included unnecessary reference-seed rows. |
| Superseded draft | `d8ab5320a3ceee98628f964e05328f7ac08ea9d7bcc3776680b14f7ed381018b` | `4c2b834f43c3203d8748fc2fc6e0f383b8905a34bc332ea879889a55c1da13bf` | Added contract details but did not yet freeze the final raw q/AIC-penalty distinction and Hager–Zhang method label. |
| Superseded draft | `e3b67cc9e110f0e549c149f3099e29520d14474fb2fa2fa67e1777ab2a042878` | `4c2b834f43c3203d8748fc2fc6e0f383b8905a34bc332ea879889a55c1da13bf` | Full contract before the expanded-reference threshold was clarified as raw log-likelihood shortfall. |
| Current frozen manifest | `447c5234ca8a898c525606777d821265cc0c3aaa6f252866fe411edc7727111e` | `4c2b834f43c3203d8748fc2fc6e0f383b8905a34bc332ea879889a55c1da13bf` | Full DGP, RNG/version, optimizer/profile, allocation, scoring, and explicitly raw-log-likelihood reference shortfall; no reference RNG rows; repeatability labels explicitly encoded. |

A protocol hash identifies a scientific contract, not execution or fitted evidence. No campaign results are represented by these manifests.
