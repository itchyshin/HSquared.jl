# Arcs — H² twin Block 1 (A01–A23)

Status: `todo` · `doing` · `done` · `paused` · `blocked`  
Batch barriers: B0–B9 (ultra-plan §6).

| Arc | Batch | Name | Status | Gate? |
|-----|-------|------|--------|-------|
| A01 | B0 | Lane extraction — worktrees | done | — |
| A02 | B0 | v07 fog / base decision | done | — |
| A03 | B0 | Claim-surface sweep | done | — |
| A04 | B1 | Enumerate 5 covered rows (F2) | done | B1 |
| A05 | B1 | R↔Julia parity table (F3) | done | B1 |
| A06 | B1 | Test/runtime baseline | done | B1 + Totoro full suite `73a4db0b` |
| A07 | B2 | S5 tail-scale REML gate q=25k | done | **PASS** Totoro ~44m; receipt `h2-a07-s5-receipt.md` |
| A08 | B2 | CAP-EXHAUSTED ≤4/48 threshold (F4) | done | Q2 fixed pre-run |
| A09 | B2 | G10 S1/S2/S3 dossiers (no sign) | doing | dossiers updated post-S5; **owner sign** |
| A10 | B3 | BLUPF90 wire or document (F5) | done | R `2cc13d2` — doc path |
| A11 | B3 | Comparator harness 7 targets | doing | skeleton `cf069956`; receipt `h2-b3-comparator-receipt.md` |
| A12 | B3 | sommer/ASReml R fixtures | done | R `2d52a48` + Julia `cce9a961`; receipt `h2-a12-fixtures-receipt.md` |
| A13 | B3 | Real-data 3-tier manifest | doing | draft `h2-a13-realdata-manifest.md` |
| A14 | B4 | Bridge payload v2 contract | done | R `7193e9ad` phase 1; receipt `h2-b4-a14-receipt.md` |
| A15 | B4 | engine=julia smoke + F8 | done | R `07399a9` — receipt `h2-b4-a15-a16-receipt.md` |
| A16 | B4 | Bridge parity test → CI | done | R `3dbf486` phase 1 Tier 0 contracts |
| A17 | B5 | Docs IA rebuild both sites | doing | phase 1 `a2dd54c`; phase 2 navbar `1e0fe06`; phase 3 README/limits |
| A18 | B5 | CI/deploy hygiene + status gen | todo | — |
| A19 | B6 | Julia General registry (F7) | doing | prep `294cdcb` checklist; ASK before register |
| A20 | B6 | hsquared 0.5.0 CRAN local gate | todo | — |
| A21 | B7 | Estimand + claim ceiling panel | todo | Opus ceiling |
| A22 | B8 | unlazy reverify + Melissa reconcile | todo | — |
| A23 | B9 | D-43 completion panel | todo | Opus ceiling |

## Batch status

| Batch | Status | Barrier lenses |
|-------|--------|----------------|
| B0 | done | Shannon, Rose — receipt `h2-twin-b0-receipt.md` |
| B1 | done | Fisher, Rose — barrier `~/local-scratch/h2-twin-b1-barrier.md` PROCEED |
| B2 | **partial** | Gauss, Fisher, Ada — A07/A08 done; A09 dossiers refreshed; G10 sign owner |
| B3 | **partial** | Curie, Mrode, Jason, Darwin — A10/A12 done; A11 skeleton; A13 draft |
| B4 | **done** | Hopper, Boole, Emmy, Fisher — barrier **PROCEED** `~/local-scratch/h2-b4-barrier.md` |
| B5 | **partial** | Grace, Karpinski, Pat, Darwin, Florence — A17 phases 1–2 R (`a2dd54c`, `1e0fe06`); phase 3 todo |
| B6 | **partial** | Grace, Rose — A19 prep checklist `294cdcb`; register ASK |
| B7 | todo | Opus A21 |
| B8 | todo | Melissa → Rose |
| B9 | todo | Opus A23 |
