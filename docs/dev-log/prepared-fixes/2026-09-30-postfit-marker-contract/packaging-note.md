# Marker proposal packaging

The unified patch contains the55 focused additions to the existing test entry point. The independent standalone `check_marker_contract.jl` and runtime logs are retained separately. A temporary copied whole test tree was moved intact to `/private/tmp/hsq-marker-packaging-original-test-copy-20260930`; it is unrelated duplication and is excluded from this review packet. Original proposals and their pins remain in `original-proposal/`.

Parent `git apply --check` passes against the actual current dirty candidate, not merely a committed baseline. Source edits are five additions/one deletion in postfit and four additions/two deletions in genomic. No live source or test entry point was edited by packaging.
