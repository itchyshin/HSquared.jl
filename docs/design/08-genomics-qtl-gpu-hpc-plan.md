# Genomics, QTL, GPU, And HPC Plan

Canonical public plan: `docs/src/genomics-qtl-gpu-hpc.md`.

Status: roadmap. This plan records the intended direction for genomics,
QTL/eQTL/GWAS, GLLVM-style high-dimensional modelling, CPU/GPU backends, and
HPC workflows.

Current implemented Julia capability remains limited to:

- package scaffold;
- control/backend placeholders;
- pedigree normalization;
- direct sparse `Ainv` construction;
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
