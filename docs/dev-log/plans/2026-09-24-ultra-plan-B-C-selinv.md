<!-- slop-ok: G0 ultra-plan; GOAL block labels intentional -->
# Ultra-plan: B (SelectedInversion bake-off) then C (share our selinv)

**Status:** G0 ACCEPTED (Shinichi 2026-09-24) · B = benchmark only · C = share **ours**
**Date:** 2026-09-24
**Lane:** `cursor:HSquared-selinv-B` @ `~/local-scratch/lanes/HSquared.jl-selinv-bakeoff-B-20260924`
**Tip pin:** HSquared `origin/main` `d1eb566b`
**Active lenses:** Shannon, Ada, Rose (perspectives). Spawned subagents: none.

Authority: `2026-09-24-julia-la-stack-sort-out.md` (LOCKED NEXT) · deps audit
`2026-09-24-selectedinversion-deps-audit.md` · D-271 (one BLAS thread, ≥10× optional-ext bar).

---

## GOAL

| | |
|---|---|
| **Solo platform** | Cursor (this lane). No Claude/Codex overlap on H² `bench/` / plan docs. |
| **Deliverable** | (1) Fresh one-thread bake-off receipt: ours vs SelectedInversion.jl on the banked fill≈471 cell (or documented Mac stand-in). (2) Written fork: if B loses, C still means share **our** Takahashi/SIMD, never force SelectedInversion into the three. (3) C starts as a **one-cell** port/copy-sync pilot of the winning kernel (ours if B fails), not a big-bang package. |
| **HEADLINE** | Own SIMD stays production. SelectedInversion is oracle-only unless it clears D-271. |
| **IN PARALLEL** | Finish GLLVModels **#463** merge-when-green (Latte default OFF). R arc stays PARKED. |
| **DEFER** | Hard `[deps]` SelectedInversion; weakdeps/ext wire into H²/DRM/GLLVM; LDLFactorizations; threading elim-tree (sort-out ELSE #1); R/TMB speed arc. |
| **DISCIPLINE** | Never edit package `Project.toml` for SelectedInversion in this arc. Bench env only. No `git add -A`. Worktrees under `~/local-scratch/lanes/`. Report × honestly even under the 10× bar. |

---

## Fork (locked by Shinichi clarification)

```
B: SelectedInversion.jl = BENCHMARK / oracle only
   - Compare wall + identity vs in-tree Takahashi (post #361/#363 SIMD)
   - Do NOT switch production default to SelectedInversion
   - Wire into DRM/GLLVM only if B wins D-271 AND a later G0 confirms (not this arc)

C: share OUR selinv across GLLVM / DRM / H²
   - If B loses (expected under bar): C = extract/share own SIMD Takahashi
   - If B wins: still prefer weakdeps+fallback in H² first; C does not mean
     "force SelectedInversion into all three" without per-matrix remeasure
```

STOP before large C extract of SelectedInversion. Prefer measured H² SIMD → DRM/GLLVM port on **ONE** cell first.

---

## Slice table

| ID | Slice | Repo / path | Done when | G0 stop |
|---|---|---|---|---|
| **B0** | Port prior `bench/selinv_arms.jl` into tip worktree as separate env | HSquared worktree `bench/` | `julia --project=bench` loads; package `Project.toml` untouched | No package dep |
| **B1** | Identity gate at 1 BLAS thread | same | max abs err ≤ 1e-10 (trace/diag) on banked cell | Fail → fix harness, not tolerances |
| **B2** | Wall record at 1 BLAS thread | same | TSV with tip SHA, fill, `S_c_trace`, host | Report even if ≪10× |
| **B3** | D-271 verdict note | `docs/dev-log/after-task/` + check-log.d | Explicit KEEP-OURS or rare WIRE-WEAKDEPS | No production flip without new G0 |
| **C0** | Scope decision (this plan §C) | plans/ | Written: winning kernel = **ours** unless B3 says otherwise | — |
| **C1** | One-cell pilot: H² SIMD ↔ DRM (or GLLVM) identity on one sparse factor | DRM or GLLVM worktree | rtol agreement on one cell; no board claim | No big-bang shared pkg yet |
| **C2** | Copy-sync or tiny shared module plan | design note | Owner + sync rule if C1 green | Implementation needs fresh G0 |

---

## B detail (HSquared.jl)

**Cell:** Totoro `--totoro-arm` / banked fill≈471 (#361 family; prior TSV
`selinv_arms_*_totoro_q20000_fill471.tsv`). Mac Studio stand-in allowed for
smoke (`OPENBLAS_NUM_THREADS=1`); D-271 verdict prefers Totoro one-thread table.

**Arms:**
- (a) ours: `selinv_trace_against` / `takahashi_diag`
- (c) package: `SelectedInversion.selinv` / `selinv_diag` (bench Project.toml only)

**Deps (if ever wiring later; NOT this arc):** see
`2026-09-24-selectedinversion-deps-audit.md` (MIT default path; avoid LGPL LDL
ext; private Factor ABI; weakdeps-only tier).

**Expected outcome (prior evidence):** Mac ~4.5× package over ours at 1 thread
after #361/#363 → under 10× bar → KEEP-OURS. Re-measure tip honestly.

---

## C detail (all three)

**Winning kernel default assumption:** in-tree Takahashi (H² SIMD lineage from
DRM MIT port). Three copies today: `src/takahashi_selinv.jl` in each twin.

**C is NOT:** SelectedInversion as a shared dependency across three repos.

**C IS:**
1. Pick one owner file (prefer H² tip if B2 confirms it is the fastest measured
   SIMD among the three, else keep DRM/GLLVM copies until measured).
2. Pilot: port/sync to **one** DRM or GLLVM cell (identity first, wall second).
3. Only then consider a tiny shared module or documented copy-sync; not day-1.

---

## G0 stops (must not cross)

1. Do not add SelectedInversion to any package `Project.toml` / `ext/` in this arc.
2. Do not change H² / DRM / GLLVM production selinv default to SelectedInversion.
3. Do not start R/TMB implementation (PARKED).
4. Do not big-bang replace all three Takahashi files without C1 identity.
5. #463 is hygiene only; do not fold Latte into this PR.

---

## Acceptance (B)

- [ ] Bench env exists; package deps unchanged (`rg SelectedInversion Project.toml` empty)
- [ ] One-thread receipt with tip SHA + fill + walls + err
- [ ] Written KEEP-OURS or WIRE-WEAKDEPS (D-271)
- [ ] Sort-out LOCKED NEXT points at B+C with this fork
- [ ] Rose: no public speed claim from projected/proxy cells

## Acceptance (C start)

- [ ] Scope decision filed: ours vs package (see fork)
- [ ] C1 target cell named; identity gate written before edit
- [ ] No SelectedInversion in DRM/GLLVM from this lane
