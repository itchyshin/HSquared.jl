# Check log shard: errors and planned terms source review

- Date: 2026-09-29.
- Candidate: `codex/hsquared-fa-gllvm-20260927`, HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- `src/errors.jl`: exact SHA `6ebb3635c308097213b1581fae26e94089969f34a07cbf5b735a5ee945d44fba`; read-only scoped PASS; no code change.
- `src/planned_terms.jl`: exact SHA `a47d953d72565f347db805b5d0c7bdc86d5440dedaa6454c674f6e48c9607d5c`; read-only scoped PASS; no code change.
- Full `Pkg.test()` after this branch's latest Julia changes: exit 0, ending `Testing HSquared tests passed`.
- `docs/src/model-spec-grammar.md` SHA at review: `6320c1916e26683a6d2825955434ae74125179c57cb99efa7449cf11abf2229c`. Lane preflight reports three foreign refs with unmerged differences; left untouched.
- Carried: `showerror` route-string assertion and full `formula_status()` row-to-document wording consistency test. These do not block the scoped source PASS, but remain relevant to E1 exact-current disposition.
