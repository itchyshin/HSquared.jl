# 2026-09-29 supplemental source-review findings

This note records independent, read-only findings from several candidate
snapshots. Its original FA subsection was pinned to `src/multivariate.jl`
SHA-256 `a28d88c349412d08d480c505032201dcde5c0b8ab237bf819dbf07ad692cb474`,
which is historical relative to current `fc41...` source. Do not read that FA
disposition as a current-source review; see
`2026-09-29-fa-exact-current-review.md` for the exact-current panel and
comparator record. This file does not close A2 or E1. Reviewers did not edit
code or run simulations in those reviews.

## Gaussian FA identification and interpretation

The review is pinned to Julia HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`
and `src/multivariate.jl` SHA-256
`a28d88c349412d08d480c505032201dcde5c0b8ab237bf819dbf07ad692cb474`.
Kirkpatrick's disposition is **CONDITIONAL** for the bounded T=4, K=1 cell.

The identification note and registered counterexample distinguish generic
local identification from universal uniqueness identification. Fixing K does
not identify every uniqueness vector: a rank-7 Jacobian example preserves G
with different uniqueness values. The generic identified case and global
loading-sign ambiguity are explained, and the fitted payload labels uniqueness
identification as not assessed. Identification of G from observations remains
separate from identifying its FA decomposition. A positive uniqueness floor
also changes the model under trait-unit rescaling.

The leading eigenvector is not unique when the leading eigenvalue is repeated.
The reviewed `genetic_pca` wording could imply that the leading axis is exempt;
`g_max` also needed the repeated-eigenvalue caveat. Both docstrings now direct
users to interpret the full repeated eigenspace. The edit was limited to those
two docstrings after checking the other refs, whose hunks do not alter them.

The two deterministic starts are a sensitivity check, not recovery evidence.
Current multistart diagnostics compare G and R; equal G can conceal different
uniqueness decompositions. Trait-permutation behavior for fitted optima,
covariance-map information under sparse loadings or genetic-residual
confounding, and uncertainty/LRT calibration remain open. Existing algebraic
tests and one independent same-model fixture support the narrow cell. They do
not support those broader claims.

## Sparse AI-REML warm-start wording

For working `src/likelihood.jl` SHA-256
`8c60feea113e703e156561ae39a1af1131d356d7c457b1c1d23451d627e47058`, Noether
found that the warm-start code is hybrid. The animal variance update is the
exact REML EM update. The residual variance update zeros the current residual
REML score while holding fitted quantities fixed; it shares the EM fixed point
but is not the exact EM M-step away from that point. Therefore the comment that
the step is monotone and “never overshoots” is unsupported. Recommended
description: an EM update for the animal variance and a score fixed-point update
for the residual variance. No code edit or test was made. The exact source file
has changes in other refs, so the comment repair remains with its owning lane.

## Pedigree and metafounder input contract

Henderson reviewed the committed candidate at `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
The classical pedigree normalization, numerator relationship recursion,
Meuwissen-Luo inbreeding, and sparse Henderson A-inverse formulas were
internally consistent in that commit. Existing tests cover small dense-oracle
fixtures, one-parent and inbred cases, a 12,000-animal reverse-listed chain,
and inbreeding comparisons. This source-level review does not assess animal-model
fit results. The reviewer could not certify the current dirty working-tree
`src/pedigree.jl` SHA `6bea72fffbd47d10b701d200145fa9b664a6dfc045199f6d604d78f0749a173f`.

The metafounder path has an input-contract blocker in the reviewed commit. A
positive-semidefinite Gamma matrix alone does not guarantee valid induced
Mendelian sampling variances or a positive-definite animal block. With two
animals whose unknown sire and dam slots both map to one group, Gamma=[3]
produces `[[2.5, 3], [3, 2.5]]`, which is indefinite; Gamma=[2] makes the block
singular. Forward and inverse construction need consistent validity checks
and boundary tests before those spans can pass. Depth beyond the existing
12,000-animal chain is also unvalidated for any unbounded-scale claim.

## Genomic sparse and scale behavior

Karpinski reviewed the committed `src/genomic.jl` at the same HEAD. The working
file SHA `d9ae83d623b84508d599950df8cb18cbd9102c295ee580868850f00a1ed2bcad`
matches the post-fix hash recorded in the Wave 4 input-contract note. The
reviewed committed blob SHA was
`66403cf51622b813d9cf5a0362b708fbe4419cf9d425cd2ba5856b6e63522d60`.

Disposition is **CONDITIONAL** for dense validation-scale use and **HOLD** for
sparse or large-population performance claims. Sparse precision provenance
densifies the matrix and writes all n-squared entries into an in-memory hash
buffer. Both SNP-BLUP routes allocate a dense marker-sized identity matrix.
APY forms dense G and G-inverse matrices; LOCO retains dense inverses by group,
and scan caches densify designs, precision, and covariance. Absolute APY and
scan cutoffs make behavior scale-sensitive. The direct scan solves through
X'X without assessing conditioning; near-collinearity can therefore yield
poor statistics, and repeated solves may refactor X'X per marker.

These are source facts plus scaling risks inferred from allocations and
operations. No benchmark was run. Sparse-versus-dense allocation, scale
equivariance, and a near-collinear QR/SVD comparison are needed before wider
claims. CUDA and GPU behavior were outside this review.

## Gate disposition

These findings keep the relevant FA-engine and full-source-review gates open.
The fitted opt-in cells and focused tests recorded elsewhere remain in force;
these reviews add conditions and carryover, not capability promotion.
