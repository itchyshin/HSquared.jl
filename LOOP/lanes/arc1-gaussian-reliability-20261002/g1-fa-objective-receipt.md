# Gates: Arc 1 exact FA objective milestone

OWNS: src/arc1_fa.jl, test/arc1_exact_objectives.jl

Scope: prove the new spectral FA objective and gradient before optimizer integration. This leaf does not establish fitting reliability or interval coverage.

- [x] G1_FA: exact spectral REML and all covariance-parameter derivatives agree with independent dense and finite-difference oracles
  CHECK: env JULIA_DEPOT_PATH=/private/tmp/h2-arc1-objective/depot:/Users/z3437171/.julia OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 julia --project=. test/arc1_exact_objectives.jl
  EXPECT: ARC1_OBJECTIVES_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl; path=c21224dfb3ce/44 entries; output=ARC1 exact FA spectral objectives and analytic gradients |   70     70  3.5s | ARC1_OBJECTIVES_PASS
