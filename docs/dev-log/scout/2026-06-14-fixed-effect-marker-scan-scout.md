# 2026-06-14 Fixed-Effect Marker-Scan Scout

## Question

What is the honest first Phase 5 marker-scan slice for the Julia lane?

## Sources Checked

- `ROADMAP.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- local quantgen scout package map in `quantgen-scout/references/packages.md`

## Takeaway

The comparator ecosystem for marker scans and genomic prediction includes
sommer, JWAS, BLUPF90-family tools, ASReml, and related genomic-relationship
packages. Those tools set the future parity target for mixed-model marker
scans, QTL/eQTL intervals, relationship correction, and genomic prediction.

A first Julia slice should therefore be smaller: a deterministic fixed-effect
Gaussian utility that screens centered markers after residualizing against
fixed effects. That utility is useful engine substrate and testable without RNG,
but it is not mixed-model GWAS/QTL/eQTL and not public R formula support.

## Action

Implement `single_marker_scan` as direct Julia engine evidence only. Keep
`marker_scan()` public formula support, p-values/LOD scores, multiple-testing
correction, LOCO, relatedness/population-structure correction, and comparator
parity as explicit validation debt.
