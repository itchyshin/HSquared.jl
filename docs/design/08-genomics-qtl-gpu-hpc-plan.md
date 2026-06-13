# Genomics, QTL, GPU, And HPC Plan

Canonical public plan: `docs/src/genomics-qtl-gpu-hpc.md`.

Backend and algorithm execution plan: `docs/src/backend-algorithm-roadmap.md`.

Status: roadmap. This plan records the intended direction for genomics,
QTL/eQTL/GWAS, GLLVM-style high-dimensional modelling, CPU/GPU backends, and
HPC workflows.

The R twin expanded this plan at `hsquared` head `2c18b30`. The Julia mirror
keeps the same status boundary: design target only unless a capability row says
otherwise.

Current implemented or experimental Julia capability remains limited to:

- package scaffold;
- control/backend marker types and status diagnostics;
- pedigree normalization;
- direct sparse `Ainv` construction;
- low-level animal-model spec validation;
- dense validation likelihood and optimizer paths;
- supplied-variance sparse REML identity;
- supplied-variance Henderson MME solve;
- in-memory `HSData` ID map;
- planned syntax/status diagnostics;
- Documenter documentation site.

Public wording rule:

- OK: "planned", "roadmap", "design target", "comparator target",
  "experimental future Julia lane".
- Not OK: "fits genomic models", "runs on GPU", "beats ASReml", "supports
  QTL/eQTL", or "production HPC" until implementation, tests, validation,
  benchmarks, and public claim rows exist.

Bridge rule:

Julia may incubate experimental features before R exposes them, but everything
R exposes must have equivalent Julia semantics. Experimental Julia-only
features must be labelled and cannot silently change the R contract.

Algorithm rule:

- sparse MME and sparse REML/ML come before AI-REML claims;
- Takahashi selected inversion comes after sparse factorization exists;
- APY belongs to genomic and single-step phases, not Phase 1 pedigree fitting;
- GPU belongs first to dense marker, factor, response-matrix, simulation, and
  GLLVM workloads, not pedigree sorting or symbolic sparse factorization.
