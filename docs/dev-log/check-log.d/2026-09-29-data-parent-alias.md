# Check receipt: one-sided raw pedigree parent aliases

- Focused command: Julia 1.10, `test/test_data_empty_marker_status.jl`; empty-map assertions 2/2 and raw-parent alias assertions 13/13 passed.
- Negative control: before the source change, father-plus-sex and sex-plus-mother each failed both the known-parent and missing-parent expectations (4 failures total).
- Full command: `JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using Pkg; Pkg.test()'`.
- Result: passed; final output was `Testing HSquared tests passed`. The full run also exercised the in-tree FA and GLLVM tests. The existing Project/Manifest mismatch warning was emitted; no dependency resolution or manifest update was run.
- Independent bridge review: passed at source SHA-256 `ec49b48db4142a4d6bab80cfb7c63aa8115af9f045baa5cc8df25b36c3991846` and test SHA-256 `82ffbb1cbb11466adef918ada7da2fb193c202a4289f7dc352b4cd48b43111b1`.
- Scope: Julia raw-parent diagnostics only. No R parity, capability promotion, simulation, GPU, hosted CI, release, registry submission, or tag.
