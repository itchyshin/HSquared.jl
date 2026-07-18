# Retry-8 D0F genomic-recovery-v3 — adjudication receipt PASS/COMPLETE (byte-reproducible)

**Date:** 2026-07-18 · **Executor:** Claude (user-authorized, both lanes this session) ·
**Outcome:** first COMPLETE D0F adjudication receipt across the v0.7 genomic-recovery arc —
**verdict PASS**, byte-identical on re-derivation, survived its own `validate-final`.
**`public_covered_count` stays 5** (route not activated; only D1/D2 opened).

## The receipt (Totoro: `retry8-prep/d0f/stage_adjudication_receipt.tsv`)

- `schema_version = v07-genomic-recovery-v3-adjudication-2`, `stage = d0f`, `verdict = PASS`,
  `stage_decision = COMPLETE`.
- Triple parity: `attempt_max_diff = 3.183e-12`, `summary_max_diff = 7.105e-15` (both ≤ 1e-10).
- Bound seals (all live-hash-verified against the receipt + own sidecars): manifest `73656022…`,
  corpus_lock `262aedb6…`, preseal `7dafa2b7…`; r_driver/r_recomputer commit `a23b15bc…`,
  julia_replay commit `976814393043…`; summaries `52d9a0a8…`/`48d667c1…`, route-lineage `75120ab9…`;
  5 post-run reviews (fisher/noether/hopper/grace/rose).
- **Receipt sha256 `04cc074071a02b58fa269f3a4b65a8455314bb40b97b2b9c7b6af91f485d7e80`**; `validate-final`
  re-derived the SAME sha and returned `RC=0` (`validated d0f final receipt decision=COMPLETE`).

## The campaign

Full validated pipeline in driver-enforced phase order (the handover's order was corrected: `summarize-r`
must precede `replay-julia`): run-official (576 fits, all `status=success`/`converged=true` — 556 interior,
10 boundary-lower, 10 boundary-upper, all finite `scientific_ratio`) → lock-corpus → recompute-base-r (576) →
summarize-r → replay-julia (576, replay-vs-official ~1e-13) → verify-replay → summarize-julia →
write-route-lineage → write-postrun-review ×5 (all CLEAN) → adjudicate → validate-final. One transient
interruption of hopper's review was recovered by a clean re-run (`RC=0`); the review binds a deterministic
receipt, so it does not affect byte-reproducibility.

## The 8-retry blocker: root-caused and fixed (no seal change)

Prior sessions spent ~17 attempts on TMPDIR/mkpidlock — a symptom, not the cause. Embedded `hs_julia_setup`
(`Pkg.activate(julia_root); using HSquared` inside JuliaCall) failed because JuliaCall loads **RCall from the
global env** (pinned OrderedCollections **1.8.2**) while the engine `julia_root` resolves OrderedCollections
**2.0.1** (via Optim→StatsBase→DataStructures 0.19.6). The two majors cannot co-load → "already loaded and
incompatible" → forced embedded recompile → worker death. Standalone always worked because RCall/1.8.2 is
never loaded there — which is why "standalone works, embedded fails" held and TMPDIR never touched it.

**Fix (seal-respecting):** (1) reverted the prior session's contamination of the tracked
`julia_root/Project.toml` back to sealed `976814` (git-clean, byte-identical to HEAD); (2) regenerated the
**gitignored** `julia_root/Manifest.toml` RCall-free (so `hs_julia_setup` no longer re-syncs RCall into
Project.toml on load); (3) bumped the **non-sealed** global bridge env OrderedCollections 1.8.2→2.0.1 to match
the engine. RCall is marshalling-only → fit numerics unaffected. Manifest is gitignored → no tracked mutation
→ the draw's `v3p_git_clean` gate passes on every cell. Environment snapshot archived at
`retry8-prep/../envfix/env-snapshot/`.

## Pre-draw discipline

Three rounds of an adversarial 4-lens verification panel gated the draw. Panels 1 & 2 caught two REAL pre-draw
blockers (the git-dirty deployed tree; then load-time re-dirtying via the RCall-bearing Manifest) with **no
seed spent** — both fixed before the draw. Panel 3 returned GO (all lenses GREEN, both roots pristine). Seed
bases 2042000000 (phenotype) / 2043000000 (bootstrap) reused per the pre-registration (the earlier `-c`/Retry-7
blockers were pre-draw; seed space unspent).

## Bounds and close-out

Per the pre-registration a COMPLETE D0F PASS **only opens D1/D2**: no `ordinary_auto_genomic` activation, no
V2-GRM/V2-GINV discharge (both stay partial), `public_covered_count` stays **5**. Both deployed lanes remain
git-clean at their sealed heads. Spawned-Rose close-out (fresh context) **CONFIRMED** the claim is fully
evidence-backed and correctly bounded, with no overstatement.
