# After-task: T4 dense/sparse loglik convention (#365)

Date: 2026-09-24
Lane: Julia `cursor/post366-t4-loglik-365` (+ thin R mirror `cursor/post366-t4-loglik-365-r`)
Fence: experimental 0.9.0 / `public_covered_count` 7; no covered flip

## What landed

HSquared.jl #365 made user-reachable: dense `fit_repeatability_reml` /
`fit_multi_effect_reml` / `fit_two_effect_reml` omit `−½(n−p)log(2π)`; sparse
`fit_sparse_multi_effect_aireml` / `fit_multi_effect` include it. Absolute
logliks differ by that constant; variance components are unaffected.

Chose honesty metadata rather than rewriting dense absolute loglik (overnight
preference; AIC/LRT safe once converted):

- `loglik_convention` ∈ `{:reml_omit_2pi, :reml_full_constant}`
- `loglik_full_constant_offset` (add to `loglik` for the full-constant scale)
- `loglik_comparable_across_routes` (false on dense omit)
- exported `comparable_loglik(fit)`, `reml_full_constant_offset(n, p)`

R thin mirror: bridge passes the three fields into `diagnostics`; `?hs_control`
names them and points at `comparable_loglik`. Pinned R offset test left intact
(absolute gap still present).

## Checks

See `docs/dev-log/check-log.d/2026-09-24-t4-loglik-convention-365.md`
(21/21 focused).

## Not done

- Full dense absolute-loglik alignment to the full-constant convention
  (would update the R pin; deferred until an owner ask)
- Live R julia-bridge test (T1 holds `tests/testthat/` lease)

## Rose

No public claim change; no count flip. Claim surface still says logliks are
not comparable across `scale_method` on raw `loglik`; the fit now also carries
the convention fields so conversion is explicit.
