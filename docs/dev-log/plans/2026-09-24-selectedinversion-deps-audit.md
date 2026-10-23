# SelectedInversion.jl: pre-wire dependency / provenance audit

Date: 2026-09-24  
Lane: read-only (GLLVM.jl-s9cov scratch)  
Scope: audit only. No wiring. No package `src/` edits.  
Shinichi asked first: *if we use SelectedInversion.jl we have to describe the iter's dependencies. Check this before moving on.*

G0 STOP below. Verdict in one line at the end.

---

## 1. Package identity (JuliaHub / GitHub / General)

| Field | Value |
| --- | --- |
| Repo | https://github.com/timweiland/SelectedInversion.jl |
| Registry | General (`S/SelectedInversion`), UUID `043bf095-3f01-458a-9f1c-8cf4448fe908` |
| Latest registered | **0.2.1** (`git-tree-sha1` `ef0ac21d…`) |
| Maintainer | **Tim Weiland** (`hello@timwei.land`); near-single-maintainer (69 commits; Dependabot only other) |
| License | **MIT** (Copyright 2025 Tim Weiland and contributors) |
| Julia compat | `1.10` |
| Stars / activity | 5 stars; last push 2026-06-11; 3 open issues |
| Docs | https://timweiland.github.io/SelectedInversion.jl/ |
| CITATION.bib | **absent** (cite algorithm papers from README) |

Algorithm claim (README): SelInv (Lin et al. 2011); simplicial form equivalent to Takahashi (1973) and Erisman-Tinney-style recursions. Interfaces CHOLMOD Cholesky by default; optional LDLFactorizations extension.

---

## 2. Dependency tree (what an adopter would declare)

### 2.1 Hard deps (`Project.toml` `[deps]`)

| Package | Role | License (this audit) | Notes |
| --- | --- | --- | --- |
| `LinearAlgebra` | stdlib | Julia | no extra declare beyond Julia |
| `SparseArrays` | stdlib (CHOLMOD Factor path) | Julia | same |
| `PrecompileTools` | `@setup_workload` | MIT (JuliaLang/PrecompileTools.jl) | pulls `Preferences` |

`Preferences` is a transitive of PrecompileTools (JuliaPackaging; GitHub license metadata NOASSERTION; treat as standard Julia packaging stack, MIT in practice). No `_jll` on the default path.

A hard `[deps]` add pulls SelectedInversion, PrecompileTools, and Preferences. No new SuiteSparse jll beyond what SparseArrays already uses.

### 2.2 Weakdeps / extension (optional)

| Package | Role | License | Transitive |
| --- | --- | --- | --- |
| `LDLFactorizations` 0.10.x | `SelectedInversionLDLFactorizations` ext | **LGPL-3.0** | `AMD` → **`SuiteSparse_jll`** |

Our engines use CHOLMOD SPD factors, not LDLFactorizations. The LGPL arm is avoidable if we never load that extension. Still: Rose must name the LGPL branch so nobody enables it casually in an MIT twin.

### 2.3 Private-struct / ABI exposure (D-271 failure mode)

In `src/selinv.jl`:

```julia
s = unsafe_load(pointer(F))   # F::SparseArrays.CHOLMOD.Factor
if Bool(s.is_super)
    return selinv_supernodal(F; ...)
else
    return selinv_simplicial(F; ...)
end
```

Also uses `F.L` / `F.LD` / `F.p` and supernodal BLAS kernels. CHOLMOD Factor layout is not a stable public Julia API, so this sits in D-271's private-struct class. Breakage across Julia minors is a real risk, independent of speed.

---

## 3. Vault / brain: D-271 and the H² STOP

### 3.1 D-271 (accepted 2026-09-19; amended 2026-09-20)

Source: `memory/DECISIONS.md` D-271 (summary table + long form).

Adopt a speed package only on a number measured on our matrices. The tier follows the package's failure mode.

| Tier | Qualifies when | Ships as |
| --- | --- | --- |
| dependency-free | our own code | any gain |
| optional extension | pre-1.0 **or** single maintainer **or** private-struct | `[weakdeps]` + `ext/`, our fallback, load canary; after **≥10×** kernel win, rtol **1e-10**, **≤2** added packages, **no new `_jll`** |
| hard dependency | ≥1.0 **or** public-API-only; canary green on two Julia minors; regime is a real user default | `[deps]` caret pin; keep fallback one release |
| vendor / port | upstream abandoned / both failed | `src/vendor/` or new kernel |

First application named in D-271: SelectedInversion.jl v0.2.1 for HSquared.jl.

Applied once (2026-09-19) on Szymek kernel `b9f30a64`, q=20k fill~474, one BLAS thread, Totoro: package ~287× on the selinv trace vs then-current ours; agreement ~1e-13; tier chosen = optional extension. That 287× row is against a superseded kernel.

Amendment (2026-09-20, HSquared.jl#364): the gate is evaluated at one BLAS thread (campaign pins, R-twin default, usability). After Szymek #361/#363 kernel work, Mac Studio at fill 471: package only ~4.5× over ours at 1 thread (under the 10× bar). At 4 to 8 threads the package clears 10× because it rides CHOLMOD supernodal BLAS-3 and ours does not. Expected once Totoro thread-sweep records: keep ours, close #353. Next own-kernel step proposed: thread recursion over independent elimination-tree subtrees.

D-271 also names DRModels.jl#771 and GLLVModels.jl#426: on tree precisions CHOLMOD stays simplicial, so the expected outcome is leave and close with a measured number.

### 3.2 What blocked wiring (exact STOP stack)

License is fine (MIT on the default path). What blocks is measurement, honesty, and tier:

1. D-271 10× @ 1 BLAS thread fails on the post-#361/#363 kernel (~4.5× Mac). Totoro sweep still open (#364).  
2. Failure-mode tier stays optional extension even if speed cleared: pre-1.0, single maintainer, and `unsafe_load(pointer(Factor))`.  
3. HSquared.jl#378 (PR merged 2026-09-23) banks wall receipts and fences `projected_selinv` TSV/plan rows: they are proxies, not wired end-to-end package speedups. Explicit: *Not a D-271 SelectedInversion packaging decision.* `src/` untouched; Project.toml untouched.  
4. Three-package speedup report (2026-09-23) still says SelectedInversion STOP; projected SelectedInversion.jl stays unwired (#378).

Describe-dependencies obligation: before any wire (even `weakdeps`), write down (a) hard vs weak tree, (b) MIT vs LGPL branch, (c) private-struct risk, (d) projected wall cells remain proxies. This memo is that write-down. It is not a new decision ID.

---

## 4. What HSquared.jl / DRM / GLLVM would need to declare if they depend

Assume D-271 optional-extension shape (the only legal tier today for this package).

### 4.1 `Project.toml`

- `[weakdeps] SelectedInversion = "043bf095-…"` with compat pin (e.g. `=0.2.1` until API trust).  
- `[extensions] OurPkgSelectedInversionExt = "SelectedInversion"`.  
- **Do not** add LDLFactorizations unless a separate Rose pass accepts LGPL-3.0 into the install graph.  
- Hard `[deps]` is **out** until SelectedInversion ≥1.0 **and** public-API-only (or private-struct risk retires) **and** canary across two Julia minors.

### 4.2 Docs / CITATION / acknowledgments

- Documenter or design note: optional backend; fallback is in-tree Takahashi; `:auto` / load-canary behaviour.  
- Cite: Lin et al. 2011 (SelInv); Takahashi 1973; Erisman & Tinney 1975 as used today; package attribution to Tim Weiland / SelectedInversion.jl MIT.  
- No upstream `CITATION.bib` to import; do not invent a paper claim for the package.

### 4.3 Rose provenance checklist

- License chain default path: MIT (SelectedInversion) + MIT (PrecompileTools) + Preferences + Julia stdlib. Clean for MIT twins.  
- Forbidden silent path: enabling LDLFactorizations ext without LGPL disclosure.  
- Private-struct canary: CI load of Factor on Julia 1.10 and current stable; fail closed to our kernel.  
- Claim fence: never equate kernel-arm or `projected_selinv` cells with a multi-iter fit (#378).  
- Capability / validation rows: no `covered` flip from wiring alone; need agreement fixtures + wall cells.

### 4.4 Per-repo note

| Repo | Why SelectedInversion might help | Why D-271 currently says leave |
| --- | --- | --- |
| **HSquared.jl** | AI-REML selinv share can dominate at high fill; PEV diag | 1-thread 10× miss after own-kernel speedups; #364 Totoro owed |
| **DRM.jl / GLLVModels.jl** | sparse phylo / Laplace selinv | tree / simplicial regimes: package slower or irrelevant; need own measured number (#771 / #426) |

---

## 5. In-tree Takahashi / "SIMD" provenance (comparison)

### 5.1 Provenance chain (today)

| Repo | File | Provenance header |
| --- | --- | --- |
| **DRM.jl** | `src/takahashi_selinv.jl` | In-house MIT; written for sparse phylo gradient / EM (`sparse_phy_grad`, `em_phylo`); Takahashi 1973 / Erisman-Tinney 1975 math. Same content family as GLLVM. |
| **GLLVModels.jl** | `src/takahashi_selinv.jl` | Same in-house header as DRM (byte-comparable for the WHY/math block). |
| **HSquared.jl** | `src/takahashi_selinv.jl` | **Adapted near-verbatim from DRM.jl** (MIT, Copyright 2026 Shinichi Nakagawa), attributed in-file; used for MME `C⁻¹` diag (PEV / reliability) and AI-REML traces. |

No third-party selected-inversion package is vendored. No GPL source. Algorithm literature only.

### 5.2 SIMD

Current `takahashi_selinv.jl` files in H² / DRM / GLLVM list no `SIMD.jl`, LoopVectorization, or similar. Recent H² gains cited in D-271 (#361 ~28×, #363 ~76× at fill 471) are own-kernel edits. Talk of "SIMD selinv" means micro-optimising our recursion; it is not a declared dependency.

### 5.3 Contrast with SelectedInversion

| | In-tree Takahashi | SelectedInversion.jl |
| --- | --- | --- |
| License into our tree | Already MIT ours | MIT package + optional LGPL LDL path |
| Struct risk | Uses public-ish `sparse(ch.L)`, `ch.p` (same Factor surface our code already touches) | **`unsafe_load(pointer(F))`** for supernodal vs simplicial |
| Supernodal BLAS-3 | No (scalar recursion; flat under thread count) | Yes (wins when BLAS threads > 1) |
| Dep count | 0 beyond Julia | +1..3 packages; optional `_jll` via LDL |
| Simplicial / tree | Native regime | README/D-271: often slower than ours |

---

## 6. G0 recommendation

**DON'T-USE-YET** for HSquared.jl, DRM.jl, and GLLVModels.jl.

Reasons (ordered):

1. **D-271 speed gate at 1 BLAS thread fails** on the current H² kernel (~4.5× < 10×). The old 287× row is obsolete. Totoro thread sweep (#364) is still owed before any re-open.  
2. **Even a win would be weakdeps-only:** pre-1.0, single maintainer, and private Factor ABI via `unsafe_load`. Hard `[deps]` is not on the table.  
3. #378 honesty fence still blocks reading projected SelectedInversion walls as shipped speed. Wiring needs its own packaging PR.  
4. DRM / GLLVM lack a fresh measured win on their matrices; D-271 already predicts leave on simplicial tree precisions.  
5. Dependencies are now described (this file). That was the pre-move obligation. No further discovery blocks the decision; the decision is wait.

NEED-MORE only if Shinichi wants a re-open packet: Totoro 1-thread confirmation at fill 471 on current main tip, plus an explicit weakdeps design sketch. Optional work. No green light.

USE is not available under D-271 today.

---

## Sources (retrieved 2026-09-24)

- GitHub `timweiland/SelectedInversion.jl` (Project.toml 0.2.1, LICENSE, README, `src/selinv.jl`)  
- Julia General registry `S/SelectedInversion`  
- LDLFactorizations / AMD / PrecompileTools Project.toml + license metadata  
- Vault `memory/DECISIONS.md` D-271 (incl. 2026-09-20 amendment)  
- HSquared.jl issues/PRs #353 (CLOSED evaluate), #364 (OPEN thread sweep), #378 (MERGED projected fence)  
- In-tree headers: `HSquared.jl` / `DRM.jl` / `GLLVM.jl` `src/takahashi_selinv.jl`  
- Lane plan: `2026-09-23-three-package-speedup-report.md` (SelectedInversion STOP)

---

## One-sentence verdict

DON'T-USE-YET: SelectedInversion.jl is MIT and dep-light on the CHOLMOD path, but D-271's 1-thread 10× bar fails after our own kernel work, the package is pre-1.0 / private-Factor / weakdeps-only, and #378 still fences projected walls as unwired.
