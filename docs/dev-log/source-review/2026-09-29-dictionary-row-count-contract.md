# Exact-current source review: dictionary row counts for explicit source IDs

- Candidate HEAD: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- Scope: `_row_count(::AbstractDict)` and explicit genotype/expression ID length validation.
- Exact files: `src/data.jl` SHA-256 `91ab80b4140459eb406547974876b1d15169d4fb5a2c3676ddaaf9ce3f16541a`; `test/test_data_dict_id_lengths.jl` SHA-256 `530e0f3914a722fdf70c5ba94e5bc93ed95120d6fc0a87c7c81a7c217be257b8`; `test/runtests.jl` SHA-256 `e60e5ba2c968076604369d5b5313e736f82f7d73802cdb18c757a41faf77852a`.
- Review: two read-only input-contract and validation reviews inspected the candidate bytes. Both found the ID handling consistent on covered cases; the source-contract reviewer reproduced the missing dictionary row-count check. This is a bounded component review, not full-file E1 signoff.

## Finding and repair

Explicit genotype or expression IDs were length-checked only when `_row_count` could determine the source size. Dictionary-backed data had no `_row_count` method, so mismatched IDs could pass construction and later produce `not_available` row-count diagnostics. Dictionary row counts now derive from column lengths, reject inconsistent columns, and feed the existing explicit-ID length check.

## Evidence and limits

The focused Julia test file passed 8/8 assertions, covering genotype ID mismatch, expression ID mismatch, matching dictionary row counts, inconsistent dictionary columns, exact-type distinction between integer `1` and string `"1"`, and rejection of an empty phenotype table. Full Julia `Pkg.test()` passed on these final bytes, ending `Testing HSquared tests passed`. The first full run exposed one stale expected status value: with row-count support, a dictionary containing consistently sized but duplicate-named marker columns now reports the known row count `2`; the legacy expectation was updated. `git diff --check` passed. Julia warned that project dependencies or compat requirements differ from the manifest; no resolve or update was run. The Julia process used a task-local writable depot because the default compiled cache is outside the authorized workspace.

The two follow-up cases identified during review are now covered by direct tests. Dictionary row-count diagnostics also now report a known row count even when marker names are duplicated; marker-name duplication remains separately diagnosed. No capability, validation-debt, covered-count, release, or GPU status changed. E1 remains open.


## Exact-current follow-up: NamedTuple and unsupported columns

At Julia candidate `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`, the row-count
contract includes NamedTuple and AbstractDict inputs. Current SHA-256 pins:

- `src/data.jl`: `39efaac183375e0f735836e5c3d398a1b8f59fffb5b7e7f3b616678b01d727b8`
- `test/test_data_dict_id_lengths.jl`: `f589690d9d58c945c287103837cfa81a0395b87a37567c7540027d744ab54c37`
- `test/test_data_empty_marker_status.jl`: `82ffbb1cbb11466adef918ada7da2fb193c202a4289f7dc352b4cd48b43111b1`
- `test/runtests.jl`: `b4802d82a430abc10134485a21bf387d9497d72bb2643c25afbbb6ec0cdc4691`

The focused dictionary/typed-ID test passes 14/14; the neighboring empty-marker
and pedigree-status test passes 15/15. Curie reviewed the added malformed-column
branches and tests. Rose found no capability promotion and recorded E1 as open.
The earlier 8/8 evidence above applies to the prior Dict-only test version; these
current pins supersede that narrow test count. A custom column with an applicable
but throwing `length` method may still surface its own exception. This remains a
component review, not full `src/data.jl` or E1 signoff.
