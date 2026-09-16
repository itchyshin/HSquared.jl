> **Scratch DRAFT PR landing (2026-09-05).** Dropbox write-lane still FOREIGN. Not a Rose verdict, covered flip, G10, or 0.9.0. Version **0.8.0**. Count **7**.

# After-task DRAFT — Julia Gate-6 honesty stack (#305–#308)

**Status:** DRAFT · **not committed** · SHAs filled 2026-09-05 Option B FIRE (4/4 merged)  
**Date prep:** 2026-09-05  
**Lane:** scratch-only prep; commit from Dropbox Julia lane when FOREIGN clears  
**Owner stamp:** Option B paid — #305–#308 all merged; main @ `f8abd105`

> This is a **Definition of Done closeout template**, not evidence that 0.9 is done.
> Do not treat as merged until SHAs below are filled and repo copies land under
> `docs/dev-log/after-task/`.

---

## Stack summary

| Order | PR | Branch (pre-merge) | Merge SHA | Main SHA after merge |
| --- | --- | --- | --- | --- |
| 1 | [#305](https://github.com/itchyshin/HSquared.jl/pull/305) | `cursor/0.9-fa-ss-honesty-wave3` | `652ffb28` | `652ffb28` |
| 2 | [#306](https://github.com/itchyshin/HSquared.jl/pull/306) | `cursor/0.9-sprint-d2-payload-v2-locks` | `523c2553` | `523c2553` |
| 3 | [#307](https://github.com/itchyshin/HSquared.jl/pull/307) | `cursor/0.9-sprint-d2-valdebt-honesty` | `f9e1be55` | `f9e1be55` |
| 4 | [#308](https://github.com/itchyshin/HSquared.jl/pull/308) | `cursor/0.9-sprint-d2-doc-twin-boundary` | `f8abd105` | `f8abd105` |

**Pre-merge heads (2026-09-05):** #305 `7904994d` · #306 `aa826d89` · #307 `81508d9e` · #308 `9352b6f5` (see receipt)

**Merge order critical:** #306 before #307 (shared `bridge_payload_v2.jl`, `runtests.jl`).

---

## Per-PR substance

### #305 — FA/SS wave-3 honesty (roadmap + valdebt)

**Files:** `ROADMAP.md`, `docs/design/validation-debt-register.md`

**Honesty claims (held — no R-public flip):**

- Engine FA/SS **engine-covered ≠ R-public-covered**
- Cross-lane notes; count **7** on engine side

**CI evidence (pre-merge):** Julia 1 + 1.10 pass, docs pass — runs `33965590341` / `33965590334`

---

### #306 — payload-v2 bridge schema locks

**Files:** `src/bridge_payload_v2.jl`, `test/runtests.jl`, `test/test_payload_v2_parity.jl`

**Honesty claims:**

- Fail-closed missing envelope keys + fixture shape locks
- Contract-only; twin of R #180
- No formula activation

**CI evidence (pre-merge):** Julia 1 + 1.10 pass, docs pass — runs `33970555081` / `33970555056`

---

### #307 — valdebt honesty + FA/SS test locks

**Files:** `src/bridge_payload_v2.jl`, `test/runtests.jl`, `test/test_payload_v2_parity.jl`, capability/debt page assertions

**Honesty claims:**

- Test-locks engine-only FA and SS boundaries
- Soft overlap with #306 paths — merge **306 first**

**CI evidence (pre-merge):** Julia 1 + 1.10 pass, docs pass — runs `33972773051` / `33972773015`

---

### #308 — twin-boundary Documenter page (Gate-6 pair with R #183)

**Files:** `docs/src/twin-boundary.md`, `docs/make.jl` (nav entry)

**Honesty claims:**

- Reader-facing engine vs R-public boundary
- Experimental **0.8.0**; count **7**; FA/SS engine-only
- Docs-only; no overlap with #306/#307 test paths

**Receipt:** `~/local-scratch/receipts/hsquared-jl-0.9-sprint-d2-doc-twin-boundary-2026-09-05.md`

**CI evidence (pre-merge):** Julia 1 + 1.10 + Documenter pass (receipt)

---

## Stack-level honesty fences (must remain true after merge)

| Fence | Evidence |
| --- | --- |
| No R-public capability flip from engine work | #305/#307 cross-lane wording |
| `public_covered_count = 7` | #307 test locks + #308 Documenter prose |
| Experimental 0.8.0 | Main README + #308 page |
| Payload-v2 contract locked | #306 + #307 |
| Twin-boundary reader page | #308 (+ R #183) |

---

## Post-merge check route (fill after Dropbox lane free)

```bash
cd "/Users/z3437171/Dropbox/Github Local/HSquared.jl"
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=docs docs/make.jl
bash tools/preamble_cap.sh
```

Record exact outcomes in `docs/dev-log/check-log.md` — see `post-merge-checklist-DRAFT.md`.

---

## Rose audit slot

**NOT PERFORMED in this DRAFT.** After merge + local checks, spawn Rose on merged
Documenter/README surfaces — do not treat scratch index as CLEAN.

---

## Coordination board row (post-merge, Shannon)

Prep text only — append when lane owns Dropbox:

```text
2026-09-05 — Julia Gate-6 honesty stack merged (#305–#308): engine FA/SS honesty,
payload-v2 locks, twin-boundary Documenter page. No R-public flip. Rose pending.
```

---

## References

- Prep ceiling: `~/local-scratch/h2-09-finish-prep-ceiling-PROOF-2026-09-05.md`
- Mergeability: `~/local-scratch/h2-09-finish-draft-mergeability-2026-09-05.md`
- Post-merge checklist: `~/local-scratch/h2-09-finish-postmerge-packets/post-merge-checklist-DRAFT.md`
