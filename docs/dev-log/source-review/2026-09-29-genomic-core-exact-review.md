# Exact-current component review: genomic construction and scan contracts

## Candidate and reviewers

- Candidate HEAD: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- `src/genomic.jl` SHA-256 at review and after reproduction: `72423bd1523dbcf25ef55081d89328c12004797637d8506e17e5ff574a87c021`.
- Gauss (GPT-6 Astra, high): lines 15-457 plus 458-459, genomic construction, provenance, APY, and LOCO. Component verdict: multiple defects reproduced; E1 remains open.
- Karpinski (GPT-6 Sol, high): lines 639-1157, single, mixed and LOCO scan core and result helpers. No algebra defect found in the reviewed projection; performance and stability risks need measurement.
- No source edits were made. Henderson's proposed single-step span review could not be dispatched because the agent thread limit was reached; lines 2417-2616 remain unreviewed in this slice.

## Reproduced numerical defects

All probes were local, tiny deterministic checks. They took under one minute and did not run model fits or GPU code.

1. Weighted VanRaden construction can produce tiny asymmetry, then the inverse rejects the result. A deterministic `8 x 11` genotype matrix and continuous marker weights produced maximum `|G-G'| = 8.326672684688674e-17`; `genomic_relationship_inverse(G; ridge=0.1)` threw `ArgumentError("G must be symmetric")`. Gauss reproduced the same construction with a different deterministic seed and obtained `1.1102230246251565e-16`. Existing weighted tests do not exercise the construction-to-inverse composition.
2. APY accepts nonfinite inputs and silently returns singular precision. With `G=[2.0 0.5; 0.5 2.0]`, core `[1]`, and `ridge=Inf`, it returned diagonal `[0.0, 0.5]`. With `G=diag(1, Inf)` and core `[1]`, it returned `[1.0, 0.0]` on the diagonal.
3. APY's absolute `1e-12` conditional-variance cutoff rejects a well-conditioned positive-definite matrix solely because of its units. `1e-13 * [2.0 0.5; 0.5 2.0]`, core `[1]`, ridge zero throws the non-positive-conditional-variance error although the conditional variance is positive and its reciprocal is representable.
4. Zero-ridge marker activation returns a numerically unusable inverse for a singular sample-centered relationship matrix. On the exact four-animal fixture in `test/runtests.jl:8004-8008`, `rank(G)=3`, `cond(G)=1.9417e16`, `maximum(abs,Q)=2.8572e15`, and `opnorm(K*Q-I,Inf)=2.4465`. The existing test currently expects zero-ridge construction to succeed and checks fingerprints, not inverse quality.
5. Supplied allele frequency `[1e-310]` with marker column `[0.0,2.0]` passes input range checks but produces `Inf` in both VanRaden methods.
6. LOCO group labels are stringified before absence is checked. `Any["chr1","chr2",missing]` is accepted and returns a key named `"missing"`.

## Scan component review

The independent dense GLS projection matched the existing oracle on a small fixture. Static risks remain, without a measured regression: LOCO precision lookup uses `Dict{String,Any}`; mixed and LOCO paths densify and retain per-group caches; the fixed scan repeats a crossproduct solve; and both fixed and mixed routes use crossproducts plus an absolute near-collinearity cutoff. Existing LOCO parity uses one marker per group, so same-group cache reuse is not tested. No benchmarks were run and no sparse-scale performance claim is supported.

## Ownership and disposition

Preflight found six refs with `src/genomic.jl` changes absent from this checkout. In particular, `origin/codex/handover-0910-20260907` removes the exact-symmetry guards that cause the weighted-construction failure and also edits adjacent genomic fitter contracts. Other referenced branches include `claude/h2-fixer-j5` and `claude/h2-fixer-j3`. These overlap the reviewed source and proposed repairs. Per lane ownership rules, this review does not edit `src/genomic.jl` or shared tests. The reproduced findings are carried for a user ownership decision before repair. This component review does not clear whole-file E1.
