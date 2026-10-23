# Julia engine source-review inventory

Pinned baseline: `faed40182cdbba2bf69f3e8dff0c5054be2dd214` (Julia
`origin/main`, 2026-09-27). The current candidate has uncommitted FA and
genetic GLLVM changes. Review packets must name both the baseline and exact
candidate commit before signoff. `git ls-files src` lists 24 tracked files.

| Wave | Files | Required lenses | State |
| --- | --- | --- | --- |
| 1. Sparse Gaussian and genomic | `likelihood.jl`, `iterative_solve.jl`, `sparse_bridge.jl`, `takahashi_selinv.jl`, `genomic.jl` | Gauss, Karpinski, Noether | packet filed; three defects fixed; full likelihood/genomic spans and panel signoff open |
| 2. Multivariate and non-Gaussian | `multivariate.jl`, `genetic_gllvm.jl`, `nongaussian.jl`, `random_regression.jl` | Gauss, Karpinski, Noether, Kirkpatrick, Curie | packet filed; observed-curvature, endpoint, objective-label, PSD, and repeatability-inference defects repaired in scoped paths; remaining findings and panel signoff open |
| 3. Input and public bridge | `pedigree.jl`, `data.jl`, `model_spec.jl`, `bridge_payload_v2.jl`, `control.jl`, `errors.jl`, `HSquared.jl` | Hopper, Boole, Emmy, Henderson | packet filed; pedigree-ID ordering regression repaired; full-wave signoff open |
| 4. Extraction and support | `postfit.jl`, `evolvability.jl`, `plotting_ext.jl`, `validation_status.jl`, `backends.jl`, `placeholders.jl`, `planned_terms.jl`, `gpu_ext.jl` | Hopper, Karpinski, Grace, Rose | packet filed; G-geometry defects repaired in scoped paths; planned-term/GPU wording and status audit in progress; full-wave signoff open |

Each wave is capped at four working days and needs a file-span ledger,
findings, fixes or explicit carry, tests, and panel signoff. `src/gpu_ext.jl`
receives a static interface review only; this programme performs no GPU
execution and makes no GPU completion claim. A wave may split further if its
time box expires. This inventory is a plan, not evidence that a file passed.
