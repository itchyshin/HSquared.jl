# Exact-current source review: direct Pedigree marker contract

- Candidate HEAD: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- Scope: direct `Pedigree` constructor IDs versus normalized unknown-parent markers; construction invariants and custom-marker round-trip.
- Exact files: `src/pedigree.jl` SHA-256 `e8a8378a92026b4e7c00f6033e07e312275fea6c11da22a0e1dacc384767c8d5`; `test/test_pedigree_constructor_contract.jl` SHA-256 `20f223a475553ab47cbe0ee96b2ce4018a6b89a37c2faa58bdf5a52f99e299b0`.
- Reviewer: Henderson, exact-current scoped review, PASS for this fix. Review spans were constructor and normalization contracts, including lines 101-287 and 346-804 in the reviewed file. This is not full-file E1 signoff.

## Finding and repair

Direct construction previously accepted IDs equal to standard unknown-parent markers, while `normalize_pedigree` rejected them. It also had no way to preserve a caller's custom marker set through construction. The constructor now accepts `missing_values`, defaults to the standard set, and rejects matching IDs. Normalization passes its marker set through. Tests cover default markers, a custom marker, and an ID that is a default marker but valid under a different custom set.

## Evidence and limits

The focused command `JULIA_DEPOT_PATH=/private/tmp/hsquared-fa-gllvm-julia-depot:/Users/z3437171/.julia JULIA_PKG_PRECOMPILE_AUTO=0 JULIA_PKG_OFFLINE=true julia --compiled-modules=no --project=. test/test_pedigree_constructor_contract.jl` exited 0 with 20/20 assertions. Full `Pkg.test()` also exited 0 against these source and test bytes; it ended with `Testing HSquared tests passed`. Julia warned that the modified project dependencies or compat do not match the manifest. No resolve or update was run. `git diff --check` passed.

The review confirms only constructor marker consistency for this exact change. It does not establish full-file pedigree review, arbitrary pedigree guarantees, model fitting, or E1 completion. No capability, validation-debt, covered-count, release, or GPU status changed.
