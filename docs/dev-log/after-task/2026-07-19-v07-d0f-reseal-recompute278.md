# After-task — v0.7 D0F RE-SEAL (recompute.R:278 fix, C_fix 5325e95): PASS/COMPLETE, identical fits

**Date:** 2026-07-19 · **Lane:** Julia engine (HSquared.jl) docs + R lane (hsquared) fix, executed on
Totoro · **Executor:** Claude (user-authorized; SOLO platform).

## Task goal

Re-seal the v0.7 D0F stage to fold in the hsquared `recompute.R:278` fix (derive `r_recomputer_path` by
name instead of `= script`) that a zero-seed D1 admission step surfaced as a latent blocker. Because two
unconditional git-identity gates bind the sealed R head, the fix cannot be applied without re-sealing D0F.
Produce a **new** byte-reproducible D0F adjudication receipt that reproduces retry8's fits exactly (new
receipt identity, identical science), re-confirm PASS/COMPLETE via `validate-final` + a spawned-Rose
close-out, supersede every live citation of the old receipt identity, and keep `public_covered_count` at 5.
No seed is drawn by the re-seal (D0F seeds `2042`/`2043` reproduce deterministically).

## Outcome (met)

New receipt `reseal-d0f/stage_adjudication_receipt.tsv`: **verdict PASS, stage_decision COMPLETE**, sha
`0f5fbb5437b30a09cd80e62e0ebd017e4b0b54121d259a1f8fd07dc06c87cd56` (supersedes retry8
`04cc074071a02b58fa269f3a4b65a8455314bb40b97b2b9c7b6af91f485d7e80`). `adjudicate` and `validate-final`
emitted the **same** sha (RC=0) — the new receipt is byte-reproduced within-run.

**Identical fits, new receipt identity** (NOT byte-identical to `04cc0740`):
- `attempt_max_diff = 3.1832314562052488e-12` — **bit-identical to retry8** (17 sig figs); fit-level
  triple parity reproduced exactly.
- Fit tally **556 interior / 10 boundary_lower / 10 boundary_upper** over 576 fits — identical to retry8
  (designs: 173+192+191 interior, 9+0+1 lower, 10+0+0 upper).
- `manifest_sha256`, `r_driver_sha256 = d1a7d930` (driver bytes unchanged), `julia_replay_commit = 976814`,
  `julia_replay_sha256 = fb5d5dff` — all unchanged.
- 5 bound post-run reviews (fisher/noether/hopper/grace/rose) all **CLEAN**.
- Receipt identity fields advanced **by design**: `r_driver_commit`/`r_recomputer_commit` `a23b15b→5325e95`,
  `r_recomputer_sha256` `cef0b993→eb29c8f4`, `preseal_sha256` `7dafa2b7→b209ec0c`, `adjudication_key_sha256`
  `→88d4cf2f`, plus every downstream content-hash that folds in the new recomputer identity/timing.

Per the pre-registration this COMPLETE receipt **only opens D1/D2**. `public_covered_count` stays **5**;
no route/count move; `ordinary_auto_genomic` not activated; V2-GRM/V2-GINV stay partial.

## Active lenses and spawned agents

- **supersede-inventory workflow** (`wf_d9271830-011`, 39 agents): inventoried 19 candidate docs @Sonnet,
  adversarially verified every MOVE/KEEP classification @Opus, + a D1 pre-reg structural audit (GREEN).
  Caught 3 real traps a naive find/replace would have hit (frozen retry8 pre-reg mis-flagged for MOVE; the
  blocker note's supersede-ledger tokens; a wrong line-anchor in the predraw audit).
- **Gauss** (numerical): root-caused the `summary_max_diff` move (see Known limitations); certification
  that `recompute.R:278` is identity-only HOLDS.
- **Rose** (spawned close-out): **CONFIRMED-WITH-CAVEATS** — PASS holds, supersede ledger sound; required
  the summary-figure update in 2 docs + the Gauss caveat here.
- **body-doc editor** (Sonnet): applied the mechanical token/figure/reword supersede to 6 body docs.

## Files changed (this commit; Julia lane only)

- `AGENTS.md` — Live Phase Snapshot replaced (retry8 entry archived verbatim first); new-receipt identity,
  summary figure `2.27e-13`, "identical fits" wording.
- `docs/dev-log/phase-snapshot-archive.md` — retry8 2026-07-18 entry appended verbatim.
- `ROADMAP.md`, `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`,
  `docs/dev-log/coordination-board.md`, `docs/dev-log/2026-07-18-d1-campaign-preregistration.md`,
  `docs/dev-log/2026-07-18-d1-predraw-readiness-audit.md` — live citations `04cc0740→0f5fbb54`,
  `a23b15b→5325e95`; capability-status + AGENTS also `summary 7.11e-15→2.27e-13`; "byte-identical"
  phrasings reworded to "identical fits, new receipt identity".
- `docs/dev-log/after-task/2026-07-19-v07-d0f-reseal-recompute278.md` (this file) +
  `docs/dev-log/check-log.d/2026-07-19-v07-d0f-reseal-recompute278.md` + `docs/dev-log/check-log.md` append.
- **R lane (separate repo, already committed):** `hsquared` `5325e95` — `recompute.R:278` + regenerated
  `recompute.R.sha256` sidecar (`cef0b993→eb29c8f4`).

**DO-NOT-TOUCH, and untouched:** the blocker note, both handovers, the 2026-07-17 retry7/retry8 pre-regs,
the retry8 after-task + its check-log.d sibling, and all archive/frozen dated records (verified by
`git status` = only the intended files modified).

## Checks run and exact outcomes

- Field-by-field old-vs-new receipt diff on Totoro: scientific/verdict fields reproduce (attempt_max_diff
  bit-identical, verdict/decision/tally identical); ~18 provenance/identity/timing-derived fields changed
  by design; `summary_max_diff` `7.11e-15→2.27e-13`.
- `validate-final` re-derived the new receipt sha `0f5fbb54…` byte-identical (RC=0).
- Power-of-two check: `7.1054273576010019e-15 == 2^-47` and `2.2737367544323206e-13 == 2^-42` (both True;
  ratio exactly 32 = 2^5) — confirms the summary move is a single-ULP reshuffle.
- Residual-token grep across the 6 edited body docs: only the 2 deliberately-kept tokens remain (the D1
  pre-reg frozen ancestry fact; the predraw-audit illustrative "not pinned" example). No old token outside
  the inventoried `.md` docs (`git grep` of non-md tracked files empty).
- (Deferred to D1 pre-draw: `Pkg.test()` / `docs/make.jl` — no `src/` change in this commit; docs-only.)

## Public claim audit

- `public_covered_count` = **5** (capability-status L17/L56/L132, ROADMAP, validation-debt-register concur);
  the re-seal is a receipt-identity move, not a route/count move.
- Wording discipline enforced repo-wide: **"identical fits, new receipt identity"**; the within-run
  "validate-final re-derived the NEW receipt `0f5fbb54` byte-identical" is TRUE and retained; the
  cross-run phrasing "receipt 04cc0740 re-derived byte-identical" appears nowhere.
- New receipt id is not falsely labelled `04cc0740`; every live old-identity citation moved.

## Tests of the tests

- The supersede was not a blind find/replace: every classification was adversarially verified, and the
  verify pass **overrode** the inventory on 3 files (frozen retry8 pre-reg, blocker-note ledger tokens,
  predraw-audit anchor) — the exact MOVE-vs-FROZEN failure mode Rose warned about.
- The `summary_max_diff` flag was not waved past: Gauss traced it to source (which columns the summary
  parity maxes over), and the power-of-two identity was independently re-verified by arithmetic, turning a
  suspected anomaly into a closed, benign mechanism.

## Coordination notes

- R lane owns the fix commit `5325e95` (already in `hsquared`); this Julia-lane commit is docs-only and
  does not change the R↔Julia contract. The D1 pre-reg predecessor is now repointed to `0f5fbb54`.
- Origin push of the R-lane fix `5325e95` was earlier flagged by Grace as a reproducibility gap — still
  awaiting explicit user OK before pushing (carried over).

## What did not go smoothly

- D0F re-seal Block 3 needed two relaunches earlier (a missing `write-route-lineage` stage → RC=31, no
  receipts, corpus intact) before completing cleanly; each review stage runs ~45–57 min under machine load.
- The close-out workflow's first Gauss agent hit the StructuredOutput retry cap (a `{"raw":…}` envelope
  quirk), but the investigation was complete — salvaged from the transcript, re-verified, and Rose re-run
  as a plain agent.

## Known limitations

**summary_max_diff (7.11e-15 → 2.27e-13) — Gauss caveat (verbatim):** The forced re-run (recompute.R byte
change → tripped the sealed `r_recomputer_sha256` git-identity gate) re-measured `runtime_seconds`/
`peak_rss_mb`, which are inside the summary parity set (they are excluded only from `attempt_max_diff`). The
max parity cell is a runtime/RSS median where R `(a+b)/2` and Julia `a+0.5(b−a)` differ by exactly 1 ULP
(both values exact powers of two; ratio 32). This is a benign 1-ULP reshuffle on a re-measured operational
field, ~450× inside the 1e-10 gate — not a numeric-path change. `recompute.R:278` remains identity-only; no
scientific quantity moved. `attempt_max_diff` (the fit-level parity) is bit-identical to retry8. The claim
is **"identical fits, new receipt identity"**, never "byte-identical receipt" and never "receipt 04cc0740
re-derived byte-identical".

- Two pre-existing stray tool-call artifacts remain out of scope (a follow-up cleanup): near
  `coordination-board.md` L65 and `ROADMAP.md` L24-25.
- doc-49 §D1 prose (R lane) still names schema `adjudication-1` while the code constant + receipt are
  `adjudication-2` — non-blocking (enforced schema is the code constant), owed R-twin reconciliation.
- Seed-lock still labels bases `2042/2043` "reserved D0F_RETRY7" though Retry-8 spent them — owed R-twin
  retirement amendment; verified non-blocking for D1 (no collision with `2_028_000_000`).

**What this re-seal does NOT do:** it does not draw any seed, does not move `public_covered_count` off 5,
does not activate `ordinary_auto_genomic`, and does not change V2-GRM/V2-GINV dispositions or the R↔Julia
contract. It only re-mints the D0F receipt identity at C_fix with reproduced fits.

## Next actions

D1 (open): repoint verified (pre-reg predecessor now `0f5fbb54`) → `preflight` (PRE-1–5 green-gate,
seed-lock `v07s_selftest`, dry `validate-final`) → adversarial pre-draw panel → **if fully GREEN, the
irreversible 576-fit draw** (base `2_028_000_000`, offsets 101:148 × 12 interior cells) → same validated
pipeline (official → base_r → summarize-r → replay-julia → julia_summary → lineage → 5 reviews →
adjudicate → validate-final) → spawned-Rose close-out. Halt-and-surface on any panel flag.
