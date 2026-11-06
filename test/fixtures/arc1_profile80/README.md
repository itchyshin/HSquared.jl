# Retained N80 profile engineering input

These TSV files are a portable export of the retained Julia 1.10.0 engineering
input `profile80/input.jls` (SHA-256
`95167a1e92d7dcadfa4b3fb5107d2ba6237e0cb85906091db7db89d263152377`).
The artifact was read from the original Totoro engineering run; no seed was
regenerated during export. Response values were written with Julia's
round-trip `repr(Float64)` format. The retained response's 12-digit fingerprint
is `2852964d10287545877a0396a5eacd72e5d9a54417a2929be846f5a701cd5708`.

| File | SHA-256 |
| --- | --- |
| records.tsv | `74e987ba12cb5d2564a784bbc2cb21956d9d65b236b45152d66ad5bef06b58f1` |
| pedigree.tsv | `75ccb4c464b78c882fb50e8185b42336b4ae3e6d8c49c907f67835de552a34cf` |
| observed_ids.tsv | `2946b046516be54720a74bfd431b3315e25bb3a63cc0393820fb57daf90bc5b4` |

The exporter verified that the retained design is an intercept and that its
incidence matrix is reconstructed by the record and pedigree rows. The old
review reported small floating-point differences between a same-seed
reconstruction and the recorded data. This fixture makes no claim that the
new test execution is historically identical or earns scientific gate credit.

The exact export script is preserved in the private Arc 1 evidence bundle;
its SHA-256 is
`0764a9ad55b067bb0b3577022d247f6f7e04ca51c5c595868d0ece425c0c6c07`.
The seed value in the test is source metadata, not an independent seed check.
