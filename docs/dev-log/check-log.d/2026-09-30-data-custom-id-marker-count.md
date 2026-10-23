# Check log: custom-ID marker count

Date: 2026-09-30

- Read-only Curie review passed the focused custom genotype-ID marker-count contract on exact `src/data.jl` and `test/runtests.jl` hashes.
- The current implementation excludes the configured genotype ID column. A competing four-line branch change excludes only literal `id` and would miscount supported custom IDs such as `:sample`.
- Existing regression at `test/runtests.jl:2137-2160` covers the `:sample` NamedTuple case, the default `id` table, and symbol/string-equivalent marker names in a dictionary.
- The reviewer ran no tests or simulations and made no edits. Gaps remain for custom-ID dictionary keys and string-valued `genotype_id`.
- Exact hashes and limitations: `docs/dev-log/source-review/2026-09-30-data-custom-id-marker-count.md`.
