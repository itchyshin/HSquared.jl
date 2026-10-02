# Arc 1 checker foundation receipt

The parent independently reran 24 adversarial Python tests and the complete manifest verifier on 2026-10-02. Both exited zero. The verifier printed `ARC1_MANIFEST_VERIFIED`; it enumerated 644,480 unique keys and seeds, comprising 10,060 outer rows and 634,420 nested bootstrap seeds. These checks validate the current deterministic allocations and receipt arithmetic. Scientific studies and proof that the pinned source executed remain pending.

Commands:

```sh
env PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s test -p 'test_arc1_receipt_adversaries.py'
```

The independent manifest check imported `verify_manifest` from `tools/arc1_manifest.py`, called it on `sim/arc1/manifests/arc1_seed_manifest.json`, and emitted the success marker only after it returned.

| Artifact | SHA-256 |
|---|---|
| Candidate scientific contract | 447c5234ca8a898c525606777d821265cc0c3aaa6f252866fe411edc7727111e |
| Outer seed CSV | 4c2b834f43c3203d8748fc2fc6e0f383b8905a34bc332ea879889a55c1da13bf |
| Manifest tool | 99c5bda6ab8a7a9bd0e46e1a2507b0736f0422f81320eb64079e1e2cb38ec563 |
| Receipt checker | 6d6e8fcedac1474dd7af688bd412dddbd2c7fba2f47357ff754d8477907cd0d7 |
| Adversarial test source | 9a1e1e521899de8fdda50fbf6addefca65fad8d85f5d5ebdd6628205363af4d7 |

The historical audit is limited to accessible tracked paths and seed-context literals. The manifest descriptor must be refreshed and independently verified after protocol or audited source changes. The guarded Hager-Zhang restart details remain to be added to the canonical contract before study admission. All original acceptance gates remain unmet.

The parent also rechecked the two protected Julia configuration hashes and all 38 baseline hashes for dirty tracked R files. All matched their initial receipt. The R original checkout remains protected.
