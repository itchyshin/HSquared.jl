# 2026-09-07 — Gate-6 Rose audit mirror (engine lane; not 0.9.0)

**Lane:** Julia (`HSquared.jl`) · cross-twin read-only mirror  
**Not** 0.9.0 · Version **0.8.0** · `public_covered_count` **7**

Julia tip **`b571184`**. R tip **`fc7230c`** (Layer B #191 + L-4 #192).

Full command table and verdict: twin R shard
`hsquared/docs/dev-log/check-log.d/2026-09-07-gate6-rose-audit.md`.

| Command | Exit | Result |
| --- | ---: | --- |
| `gh api repos/itchyshin/HSquared.jl/commits/main -q .sha` | 0 | `b571184a2b2d2d1275e82b2c3bfbfb7c05e90267` |
| `gh run view 34050391902 --repo itchyshin/HSquared.jl` | 0 | Documenter **success** (#311 merge) |

Verdict: **CLEAN WITH NITS** —
`~/local-scratch/receipts/gate6/ROSE-GATE6-FRESH-2026-09-07.receipt`.

Does **not** authorize 0.9.0 or any covered flip.
