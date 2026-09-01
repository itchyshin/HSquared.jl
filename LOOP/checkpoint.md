GOAL: see LOOP/GOAL.md.   STATE: **Block 1 — B2–B5 partial; B4 bridge slices landed.**

ARCS DONE (verified):
- A01–A03 (B0) — `~/local-scratch/h2-twin-b0-receipt.md`
- A04–A06 (B1) — barrier **PROCEED**
- **A08 (B2)** — CAP-EXHAUSTED ≤4/48 (`4ad2c87b`)
- **A10 (B3)** — F5 doc path R `2cc13d2`
- **A14–A16 (B4)** — R `7193e9a` → `07399a9`; receipt `~/local-scratch/h2-b4-a15-a16-receipt.md`
- **A15** — engine=julia smoke S2/S3 + F8 (`07399a9`)
- **A16** — Tier 0 bridge CI contracts (`3dbf486`)

BATCH PARTIAL:
- **B2** — A08 done; **A07 S5 gated** (approval packet only, **NOT RUN**); A09 dossiers `~/local-scratch/h2-g10-dossiers/`
- **B3** — A10 done; **A12 done** R `2d52a48` + Julia `cce9a961`; receipt `~/local-scratch/h2-a12-fixtures-receipt.md`; A11 skeleton; A13 draft manifest
- **B4** — A14–A16 done; **barrier pending** (Hopper, Boole, Emmy, Fisher)
- **B5** — A17 phase 1 `a2dd54c`; **phase 2** `1e0fe06` pkgdown navbar; phase 3 README I2 + limits page todo
- **B6 prep** — A19 checklist Julia `294cdcb`; register ASK owner

ARC NEXT (parallel-safe):
- **A11** — finish 7-target harness
- **A11** — finish 7-target harness (A12 index landed)
- **A13** — Darwin review real-data manifest
- **A17** — phase 3: README I2, full limits page, function-map (plan `h2-a17-docs-ia-plan.md`)
- **B4 barrier** — lens review after A15/A16 receipt

GATED:
- **A07 S5 Totoro** — ASK before run; no duplicate probes
- **G10** — Shinichi signs dossiers
- **A19 register** — owner ASK after B6 green
- **Push** — owner ASK when locally green

TRUTH: Julia LOOP `~/local-scratch/lanes/HSquared.jl-h2-twin-20260901` · R twin same branch · MC vault `435d1fb`

RESUME: LOOP/GOAL.md → this file → arcs.md. One S5 compute owner (A07, gated).
