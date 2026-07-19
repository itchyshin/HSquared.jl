# D1 blocker #2 — marker_ratio float-precision drift (Julia validator fix, no seed spent)

**2026-07-19. Caught fail-closed at D1 `preflight`; ZERO seed drawn or retired (pre-draw blocker).**
Sibling of the `recompute.R:278` blocker: a latent **D1-only** contract bug that only fires when D1's
`_validate_manifest` runs for real (D0F never exercises it — D0F validates against `D0F_DESIGNS` constants,
not the cell table). Retries 4–7 died earlier, so this path had never executed.

## What happened

D1 admission passed `prepare` ✅ (D0F predecessor re-validated COMPLETE against `reseal-d0f`/`0f5fbb54`) and
`preseal` ✅, then `preflight` aborted:
```
ERROR: D1 membership/order/seed formula drift  (_validate_manifest, stage_replay.jl:369)
```

## Root cause (confirmed by direct evidence)

R serializes the derived `marker_ratio` (`m/n`, e.g. `10/3`) at **different precision** in the two files it
writes during `prepare`:
- `cell_table.tsv`: `3.33333333333333` (14 sig figs)
- `d1_manifest.tsv`: `3.3333333333333335` (full Float64)

Julia's `_read_cell_table` **tolerates** the ~3.5e-15 gap (`abs(diff)<=1e-12`, stage_replay.jl:311), so the
cell table is accepted. But `_validate_manifest` built its `expected` from the (14-digit) cell table and
compared `marker_ratio` against the (17-digit) manifest with **exact `==`** (:369) → drift. `cell_index`,
`n`, `m`, `seed` — the fields that actually define membership/order/seed — all matched exactly; only the
derived, inherently-imprecise `marker_ratio` float tripped it.

## Fix (Julia lane, HSquared.jl) — chosen by maintainer over the R-precision alternative

`_validate_manifest` (D1 branch) now drops `marker_ratio` from the exact tuple `==` and compares it with the
**same `<=1e-12` tolerance `_read_cell_table` already uses**; `cell_id`/`cell_index`/`seed_offset`/`seed`/
`n`/`m`/`marker_ratio_code` stay exact. No numeric/scientific change; membership/order/seed still pinned
exactly (n & m fully determine `marker_ratio = m/n`).
- Local canonical commit: `8f214eb3` (HSquared.jl).
- Deployed on Totoro (`retry8-prep/HSquared.jl`) as hotfix head **`fa409fe6`**, git-clean.
- **Verified:** `_manifest(d1,'d1';exact=true)` with the fixed validator PASSED against the real failing tree
  before deploy.

## Re-seal impact: REQUIRED (my earlier "none" prediction was WRONG — corrected by the fail-closed re-run)

I predicted no re-seal from reading `_validate_d0f_predecessor` (stage_replay.jl:432-450, which validates the
D0F *receipt* fields, not the deployed head). But re-launching the D1 admission with the fixed Julia
`fa409fe6` aborted immediately in `prepare` (R side):
```
Error: julia_replay deployed commit differs from the preseal
```
So there IS a hard gate: **the D1 admission requires the deployed Julia head to equal the D0F predecessor's
sealed `julia_replay_commit` (`976814`).** Any code change that moves the Julia (or R) head therefore forces
the D0F predecessor to be **re-sealed at the fixed head** — the same pattern as the `recompute.R:278`
blocker. This is the empirical value of the fail-closed re-run: it caught what static reasoning missed. No
seed drawn.

**Correct path (a 3rd D0F re-seal, at `fa409fe6` + R `5325e95`):** re-run the full D0F stage with the fixed
Julia to mint a new D0F receipt (byte-identical fits — the fix is validation-only, replay numbers unchanged;
new receipt identity), then bind THAT receipt as the D1 predecessor. Cost ≈ the prior D0F re-seal (~several
hours; the 5 post-run reviews can be parallelized to shave it). Every fix to this D1 bug (R or Julia) incurs
this, because both heads are bound into the D0F seal.

## Status

D1 admission ABORTED in `prepare` (rc=11, `julia_replay deployed commit differs from the preseal`); no seed
drawn; old `d1/`+`d1-reviews/` already removed. The marker_ratio fix is correct + verified + deployed
(`fa409fe6`), but running D1 needs the D0F predecessor re-sealed at that Julia head first.
`public_covered_count` stays **5**.

## Blocker #3 — stale `.sha256` integrity-pin sidecar (the incomplete tail of fix #2; no seed)

The re-seal at `fa409fe6` (reseal2) then aborted at **`preseal`** (rc=12), ~1 min in, fail-closed:
```
Error: sidecar mismatch: .../HSquared.jl/sim/phase2_v07_genomic_recovery_v3_stage_replay.jl
```
**Root cause:** `stage_replay.jl` carries a **git-tracked** companion pin
`phase2_v07_genomic_recovery_v3_stage_replay.jl.sha256`. Commit `fa409fe6` (and its local twin `8f214eb3`)
edited the `.jl` (new hash `36a264b2…`) but **did not regenerate the sidecar**, which still pinned the
pre-fix hash `fb5d5dff…`. `preseal` verifies the sidecar against the file's actual bytes → mismatch. Not a
new logical bug — the *incomplete commit of blocker #2*. Rose sweep of ALL `.sha256` sidecars in both repos:
exactly this one stale, sibling `confirm_replay.jl.sha256` + 8 review-TSV sidecars all OK.
**Fix:** regenerated the sidecar to `36a264b2…` and committed in **both** repos (Totoro `8092fcb6`, local
`512d7ca7`); the commit moves the Julia head once more (`fa409fe6`→`8092fcb6` on Totoro). Re-seal relaunched
as **reseal3** (`reseal3_all.sh`, OUT `reseal3-d0f`, pins `JREPLAY=JCAND=8092fcb6`, `JREPSHA=36a264b2`); it
cleared `prepare`+`preseal`+`materialize-bootstrap` and is in the pipeline. `public_covered_count` stays **5**.

## Owed follow-ups (not blocking the run)

- Unit test for the `marker_ratio` tolerance path in `_validate_manifest`.
- Gauss/Rose lens on the validation-contract change; capability-status/validation-debt note.
- Reconcile the Totoro hotfix head `fa409fe6` with a pushed canonical commit (`8f214eb3`) — alongside the
  already-held origin push.
- D1 pre-reg PRE-4 names Julia head `976814`; it is now `fa409fe6` (+ the marker_ratio fix) — amend when the
  D1 receipt lands.
