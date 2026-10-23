# Check receipt: direct Pedigree marker contract

- Candidate: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16` with working-tree changes.
- Reviewer: Henderson, exact-current scoped review, PASS for the constructor marker fix only.
- Source hashes: `src/pedigree.jl` `e8a8378a92026b4e7c00f6033e07e312275fea6c11da22a0e1dacc384767c8d5`; `test/test_pedigree_constructor_contract.jl` `20f223a475553ab47cbe0ee96b2ce4018a6b89a37c2faa58bdf5a52f99e299b0`.
- Focused command: `JULIA_DEPOT_PATH=/private/tmp/hsquared-fa-gllvm-julia-depot:/Users/z3437171/.julia JULIA_PKG_PRECOMPILE_AUTO=0 JULIA_PKG_OFFLINE=true julia --compiled-modules=no --project=. test/test_pedigree_constructor_contract.jl`; exit 0, 20/20.
- Integrated command: `JULIA_DEPOT_PATH=/private/tmp/hsquared-fa-gllvm-julia-depot:/Users/z3437171/.julia JULIA_PKG_PRECOMPILE_AUTO=0 JULIA_PKG_OFFLINE=true julia --compiled-modules=no --project=. -e 'using Pkg; Pkg.test()'`; exit 0, ended `Testing HSquared tests passed`. Project/Manifest mismatch warning retained; no resolve/update.
- Test of tests: pre-fix TDD reproduced acceptance of standard unknown-parent markers and custom-marker round-trip gap. Added assertions reject defaults and verify custom marker semantics.
- `git diff --check` passed. No capability or validation-debt status changed.
- The broad check log and coordination board have active path references from other work. This slice is recorded in a dated check-log shard and does not rewrite those shared files.
- After-task section validation passed. The integrated closeout compiler reports the still-open programme gates A2, E1, and V3; this bounded slice does not close them.
