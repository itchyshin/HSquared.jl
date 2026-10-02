# Profile candidate review checkpoint

The exact paired-record core passed 76 deterministic tests. The real-package five-target diagnostic at source `70dd13a4eb40dfbc17e3af23649ebfb742d82db45f7934160c39b4a0dfbfb743` completed in 165.6 seconds. Only the repeatability interval formed. The heritability and three raw-variance intervals remain unverified.

| Target | Result | Target evaluations |
|---|---|---:|
| Additive variance | Search budget exhausted | 4097 |
| Permanent-environment variance | Search budget exhausted | 4097 |
| Residual variance | Search budget exhausted | 4097 |
| Heritability | Reported search-budget status requires correction | 1815 |
| Repeatability | Finite grid resolved; interval formed | 1847 |

The point fit was available, and no constrained fit exceeded its likelihood. The raw tail screens passed, but the returned scan domains omitted already-evaluated tail points. Astra identified a dimensional error: positive raw-variance gaps were measured in octaves and compared against a variance-scale root tolerance. Root tolerance had also been applied across an entire cutoff band. A depth-first refinement then replaced the complete grid with a visited prefix when its budget was exhausted. Separate nuisance, root, gap and budget failures must retain their actual causes.

The full serialized diagnostic occupies 71,271,562 bytes, SHA-256 `d10e9464b6afbed153ea3449aad394b4def3802902791f6272890e7cdebbab68`. It and the readable log are retained locally under `.unlazy/arc1-gaussian-reliability/evidence/profile-candidate-70dd13a4/`. This directory is ignored by Git. The diagnostics need bounded storage before a campaign, while preserving failure counts, selected fits and unresolved mechanisms.

Next: finish Astra's source review, implement the grid and status repairs with Luna, then rerun focused adversaries and the full wrapper within a measured bound. The approved resolution, likelihood-ratio cutoff and scientific acceptance criteria remain unchanged. G5 remains unmet.
