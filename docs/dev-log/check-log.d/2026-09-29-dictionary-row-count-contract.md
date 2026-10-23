# Dictionary source row-count contract

The focused `test/test_data_dict_id_lengths.jl` file passed 8/8 assertions on the exact current `src/data.jl` bytes. The additional tests confirm integer ID `1` and string ID `"1"` remain distinct in overlap diagnostics and the constructor rejects an empty phenotype table. The full Julia `Pkg.test()` passed on the final source/test bytes and ended `Testing HSquared tests passed`. Its first run exposed an outdated `not_available` expectation for duplicate-named, equal-length dictionary columns; the assertion now expects the known row count. `git diff --check` passed. Both test commands used `JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:$HOME/.julia`, `JULIA_NUM_THREADS=1`, and `OPENBLAS_NUM_THREADS=1`.

The package suite emitted its existing warning that project dependency or compatibility metadata differs from the manifest; no resolve or update was run. The source-review receipt is `docs/dev-log/source-review/2026-09-29-dictionary-row-count-contract.md`; E1 remains open. No capability, validation-debt, covered-count, release, or GPU status changed.


## 2026-09-30 exact-current follow-up

At Julia HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`, the dictionary/typed-ID
file passed 14/14 and the neighboring empty-marker/pedigree-status file passed
15/15. Current source/test hashes and review limits are in
`docs/dev-log/source-review/2026-09-29-dictionary-row-count-contract.md`. E1 stays
open; no capability, debt, covered-count, GPU, or release status changed.
