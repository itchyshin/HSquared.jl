<!-- slop-ok: short G0 decision brief; Status/Date labels intentional -->
# Julia LA stack sort-out (GLLVModels / DRModels / HSquared)

**PARKED sibling:** R/TMB next-arc (`2026-09-23-r-side-speed-next-arc.md`) waits until Julia B+C G0 work below lands a verdict.
**Status:** G0 ACCEPTED **B+C** (Shinichi 2026-09-24) · B = bench only · C = share **ours** · #463 merge-when-green in flight
**Date:** 2026-09-24
**Active lenses:** Shannon, Ada, Rose (perspectives). Spawned subagents: none.
**Plan:** `2026-09-24-ultra-plan-B-C-selinv.md` · deps audit `2026-09-24-selectedinversion-deps-audit.md`

Vault (ask-brain): **D-271** accepted 2026-09-19 (SelectedInversion first application; 2026-09-20 amendment = gate at **one BLAS thread**). Related scout notes under Julia speed star / Fable panel 2026-09-18.

---

## LOCKED NEXT ORDER (2026-09-24 · Shinichi G0 **B+C** · do not drop)

Shinichi paste: try **B** and **C**. Clarification same day: own SIMD is good; **B is a benchmark only** (do not switch production to SelectedInversion unless it clearly wins D-271); **C = share our selinv** across the three, not SelectedInversion.

1. **Finish GLLVModels #463**: set `diag_precision_kernel` default **OFF** on `main` (policy restore; hygiene; no science). Merge when required Julia shards + Documenter are green; Frozen R smoke is advisory (`continue-on-error`). Confirm defaults `false` on `main` after merge.
2. **B — SelectedInversion bake-off in H² (oracle only):** re-measure SelectedInversion.jl vs in-tree Takahashi/SIMD at **one BLAS thread** on the banked fill≈471 cell (or documented stand-in). Identity + wall. Report honestly even under the historical ≥10× bar. **Do not** add SelectedInversion to package `Project.toml` / `ext/` / production default in this arc. Do not wire into DRM/GLLVM from B alone.
3. **C — share the winning kernel (ours if B loses):** extract/sync **our** Takahashi/SIMD across GLLVM / DRM / H². Prefer measured H² SIMD → one-cell DRM or GLLVM identity pilot, not a big-bang shared package and **not** SelectedInversion in all three. If B somehow clears D-271, still require a separate G0 before any weakdeps wire; C does not mean force the package everywhere.
4. **R arc stays PARKED** until Shinichi explicitly unparks (`2026-09-23-r-side-speed-next-arc.md`).

---

## ELSE (ideas only · ranked · do not start)

Scouted from the three-package speed report, Szymek findings, open issues, and Julia scout notes. Beside or after the LOCKED four. No implementation from this list without a fresh G0.

1. **Thread H² own Takahashi** over independent elim-tree subtrees (Szymek; dependency-free). Next measured own-kernel step after SIMD if minutes still hurt at one BLAS thread.
2. **DRM soft (beta-block / Gst·v)**: largest remaining Julia-vs-Julia soft centre on q4 (~24% beta_trace at p=5k). Prep done (`2026-09-23-drm-soft-prep-g0-rank2.md`); needs its own G0 before `src/`.
3. **GLLVM phylo EM as a public / default path**: board shows ~26-460× Julia-vs-Julia on EM cells, but EM is **not** the public default fitter. Product decision + identity gate, not a silent flip.
4. **More post-fit / bridge honesty**: H² bridge overhead and remaining dense helpers; DRM/gllvmTMB engine=julia and profile-cost docs (#1319/#1320 class). Keep fit walls and post-fit walls in separate columns.
5. **Public README/NEWS speed claims**: still **withheld** until Rose signs a claim surface. Board and 68-row report are inventory, not marketing.
6. **Mac vs Totoro discipline (and optional Totoro re-time)**: never form × across hosts; optional Totoro re-time of Mac-only H² animal/PEV rows if a same-host column is needed for readers.
7. **ASReml-beat question (parallel scout, 2026-09-24):** early Discord "ASReml crushing H²" mixed fit with dense post-fit helpers; after selinv defaults + Takahashi + workspace/post-fit reuse, great-tit R-shaped total ~1.3 s vs ~2 s ASReml *reported*, but **no paired ASReml ladder receipt** and the speed board still gates that comparator. Do not claim "beat ASReml" until a paired same-host receipt + Rose wording.
8. **DRM conjugate-EM / sparse phylo public routing**: already the admitted Gaussian phylo mean baseline in DRM; further polish is correctness/UX, not a new Takahashi story.
9. **#463 hygiene completion**: once green, merge-when-green restores Latte default OFF; until then no default-ON Latte public wall.

---

## 1. Current state (from evidence)

Shared substrate everywhere: **SuiteSparse CHOLMOD** via Julia `SparseArrays.CHOLMOD.Factor`. No package depends on SelectedInversion.jl today (`Project.toml` / `ext/` empty of it).

| Twin | Sparse factor | Selected inverse | Dense inv | Notes |
|---|---|---|---|---|
| **HSquared.jl** | CHOLMOD on MME / relationship blocks | **Own** `src/takahashi_selinv.jl` (~243 lines); 28× (#361) then 76× SIMD (#363) at fill≈471 Totoro | Still present: `reliability` / PEV default `method=:dense`; `:selinv` is the scalable path | **SelectedInversion STOP**: projected fit × fenced (#378 MERGED); D-271 one-thread Mac ~4.5× under 10× bar; #353 CLOSED keep-ours branch expected once Totoro one-thread table is the record. No optional `ext/` wired. |
| **DRModels.jl** | CHOLMOD on augmented PLSM / structured Gaussian | **Own** `src/takahashi_selinv.jl` (~248 lines); used in Laplace / REML / LSS / crossed | Dense fallback only when factor is not CHOLMOD (e.g. crossed helper) | Tree / phylo precisions are typically **simplicial**; D-271 already predicted "leave, close with the number" for SelectedInversion here. |
| **GLLVModels.jl** | CHOLMOD on grouped Laplace / phylo sparse | **Own** `src/takahashi_selinv.jl` (~260 lines); phylo grad still has denser leaf-block work in places | Not the animal-MME dense story | **Latte** = `diag_precision` / `diag_precision_kernel` (diagonal Hf/Ho factor skip). Policy KEEP default **OFF** (#449/#452). Reality: **#453 MERGED** flipped defaults **ON**; restore PR **#463 OPEN**. |

**Three Takahashi copies.** Same recursion family, three files, not a shared package. That is drift risk, not yet a measured win from unification.

**What "SelectedInversion STOP" means.** Do not treat projected TSV rows (~95× / ~300×) as wired speedups. Do not add the dependency until a new D-271 measurement clears the one-thread 10× gate (or Shinichi overrides the thread rule). Own kernel stays the production path.

---

## 2. Is "same best stack" a good goal?

**Honest: mostly the wrong goal if it means one kernel API for all three.**

- Model classes differ. H² cares about high-fill MME selinv inside AI-REML. DRM cares about O(p) selected inverse on augmented Laplace / structured Gaussian. GLLVM cares about grouped non-Gaussian Laplace plus phylo; Latte is a **diagonal-structure** shortcut, not a Takahashi substitute.
- Shared ethos that *is* good: CHOLMOD factor once; never dense-invert a data-sized matrix on the hot path; measure before depending (D-271); identity/rtol before wall quotes.
- Unifying selinv behind one internal helper *can* be good later for maintenance, but only after one package proves a kernel change and the others re-measure on **their** matrices. Copy-paste today is three small files; a premature shared package is coordination tax.

Verdict: align **policy and measurement**, not force one implementation.

---

## 3. G0 options (pick one)

**A)** Leave package-specific kernels; document shared ethos only (CHOLMOD + no dense on hot path + D-271). Lowest risk; accepts three Takahashi files.

**B)** Unpark SelectedInversion only in H²: optional `[weakdeps]` + `ext/` behind own fallback, after a fresh **one-thread** Totoro table clears D-271 (≥10× kernel, rtol 1e-10). Then reconsider DRM/GLLVM only if their matrices look supernodal and win. Matches D-271's "first application" wording; currently evidence points to keep-ours unless a new number appears.

**C)** Extract a shared Julia selinv helper (tiny package or `src/vendor/` copy with one owner) used by all three. Maintenance win; needs identity gates per twin before any wall claim; does not by itself beat SelectedInversion.

**D)** Other: (i) Thread H²'s own Takahashi over independent elim-tree subtrees (Szymek proposal; stays dependency-free). (ii) Close the Latte default honesty gap (#463) before any Latte wall is a public default claim. (iii) Hybrid: A now + D(i) for H² kernel; revisit B only if threading still loses to the package at one thread.

**Recommendation to weigh (not a paste):** **A + D(ii)** for coordination honesty this week; H² kernel work as **D(i)** if minutes still hurt; **B** only with a new one-thread Totoro receipt that clears 10×.

---

## 4. What #463 blocks vs independent

| Work | Blocked on #463 (Latte default OFF restore)? | Independent? |
|---|---|---|
| Public / default-path Latte wall quotes; any "Latte is ON by default" README/NEWS | **YES** until #463 merges (or Shinichi OVERRIDE to keep ON) | |
| Opt-in Latte (`diag_precision_kernel=true`) identity + #452 walls | | **YES** (already measured) |
| H² own Takahashi / AI-REML / reliability `:selinv` | | **YES** |
| SelectedInversion re-measure or optional ext (B) | | **YES** (different package; D-271) |
| DRM Takahashi / speed board cells | | **YES** |
| Shared selinv helper extract (C) | | **YES** (but do not default Latte in the same PR) |
| R/TMB ultra-plan / implementation | Parked until this G0; not gated on #463 itself | Wait for Julia G0 |

---

## 5. STOP

No R implementation. No new Julia dependency. No merge from this brief.

Paste G0 as one of: **A** · **B** · **C** · **D** (name the hybrid if D).

