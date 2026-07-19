# Session Handoff — v0.7 genomic recovery-v3 **D1 lane** → Codex

**Meta:** 2026-07-19 · from **Claude** (solo Julia-lane session) · to **Codex** (new session) ·
branch `codex/2026-07-13-v07-performance-localization`. **You are Codex, picking up a live campaign.**
This doc stands alone — you will not see the authoring chat. Read `AGENTS.md` (native) first, then this.

---

## Critical Context (read or you will go wrong)

1. **A D0F re-seal (`reseal3`) is RUNNING DETACHED on Totoro right now** (~5–8 h). It is the *only* thing
   gating D1. Do **not** start anything downstream until it lands. Poll `~/hsq_work/reseal3_all.DONE`.
2. **The branch is PUSHED and fully landed** (Shinichi authorised it 2026-07-19):
   `origin/codex/2026-07-13-v07-performance-localization` @ **`36c73e22`**, ahead 0. Every commit described
   here — the three blocker fixes, the sidecar regeneration, this handover — is on `origin`. **A fresh clone
   works**; you are not tied to Shinichi's local checkout. Verify with
   `git rev-parse --short origin/codex/2026-07-13-v07-performance-localization` → `36c73e22`.
   No PR opened; **do not merge to `main`** without Shinichi.
3. **ZERO official seed has ever been drawn.** Every D1 blocker so far was caught **pre-draw, fail-closed**.
   `public_covered_count` **STAYS 5** — D1 authorises no route/count move. Rose gates every public claim.
4. **The irreversible DRAW stays LAST**, behind a GREEN adversarial pre-draw panel **and** Shinichi's
   explicit GO. His standing authorisation is *conditional*: **auto-proceed IF the panel is fully GREEN;
   halt on any flag.** The draw (`smoke-n-ladder`) is the first irreversible seed — root-forfeit discipline.
5. **This is live-toolchain work — your lane.** The whole campaign runs the real R/TMB + Julia toolchain on
   Totoro via the Totoro-side orchestrator. That is exactly what Codex is for. Claude planned/diagnosed/
   fixed; you execute the live pipeline.
6. **Totoro needs NO Duo.** Connect over the passwordless ControlMaster socket (form in Gotchas). DRAC (if
   ever needed) uses Shinichi's morning-Duo sockets (brain D-64).

---

## What Was Accomplished (this session)

Found + fixed **three latent D1-only blockers**, all pre-draw, fail-closed, **zero seed drawn**:

| # | Blocker | Root cause | Fix (commit) |
|---|---|---|---|
| 1 | `recompute.R:278` self-path | R recomputer path `= script` not derived by name | hsquared `5325e95` → re-seal `reseal-d0f`/`0f5fbb54` (DONE, Rose-confirmed) |
| 2 | `marker_ratio` float drift | Julia `_validate_manifest` D1 branch used exact `==` on `10/3` (R writes 14 vs 17 sig figs) | HSquared.jl local `8f214eb3` / Totoro `fa409fe6` (tolerant `≤1e-12`, matching `_read_cell_table`) |
| 3 | Stale `.sha256` sidecar | commit #2 edited `stage_replay.jl` but never regenerated its git-tracked integrity pin → `preseal` refused | HSquared.jl local `512d7ca7` / Totoro `8092fcb6` (sidecar regenerated to `36a264b2`) |

Then **relaunched the D0F re-seal as `reseal3`** at the corrected Julia head `8092fcb6`; verified it cleared
`prepare` + `preseal` (the stage that failed) + `materialize-bootstrap` and is in the pipeline.

Rose-swept **every** `.sha256` sidecar in both repos after #3: only `stage_replay`'s was stale; the sibling
`confirm_replay` + 8 review-TSV sidecars are all OK.

---

## Current Working State

- **Working:** `reseal3` pipeline advancing on Totoro; both local + deployed repos git-clean at their heads;
  all sidecars verified OK; env `ok=TRUE`, seed-lock `v07s_selftest` PASS (done earlier this arc).
- **In progress:** `reseal3` — the 3rd D0F re-seal, at Julia `8092fcb6` + R `5325e95`. Byte-identical fits
  expected (all three fixes are validation-only; none touches D0F fits). ETA ~5–8 h.
- **Blocked / pending:** D1 admission (`prepare d1` → `preseal` → `preflight`) is HELD until `reseal3` mints
  the new D0F predecessor. Two R-twin items owed (below). (Origin push: **done** — branch is on `origin`.)

---

## Key Decisions & Rationale

- **Every Julia/R fix that prepares D1 forces a fresh D0F re-seal.** The D1 admission hard-binds *deployed
  head == D0F predecessor's sealed head*. Fixing a D1 bug moves a head → the old D0F seal no longer matches
  → re-seal at the new head. Hit 3× now (recompute.R:278, marker_ratio, sidecar). Byte-identical fits, new
  receipt identity each time.
- **Maintainer chose the Julia tolerance fix** for blocker #2 (over an R-precision change) — keeps the fix
  in the engine lane, membership/order/seed still pinned exactly (`n`, `m` fully determine `marker_ratio`).
- **public_covered_count stays 5** — a clean D1 moves nothing public; a route/count move needs the full
  D0→D4 ladder + G1–G7 + a separate maintainer G10 + doc-44 amendment.
- **Julia lane edits only `HSquared.jl`.** Seed-lock retirement + doc-49 mirror = R-twin coordination.

---

## Landing State (git ledger)

> The handoff-gate script mis-resolves this repo by name (`HSquared.jl: not a git repo` → false PASS);
> assessed manually below.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `HSquared.jl` `codex/2026-07-13-v07-performance-localization` `36c73e22` | y | **y** | none (do not merge) | **LANDED** — `origin` @ `36c73e22`, ahead 0 |
| Sidecar fix `512d7ca7` · blocker-3 docs `2ebd8b56` · this handover `36c73e22` | y | y | none | LANDED |
| Totoro `reseal3` live state (`~/hsq_work/reseal3_all.sh`, `reseal3-d0f/`, `reseal3-reviews/`, deployed `HSquared.jl@8092fcb6`, `hsquared@5325e95`) | n/a (compute) | n/a | n/a | **LIVE on Totoro** — not in git; reach via ssh |
| 2 protected retry5 `M` docs + 2 untracked files (see below) | n | n | none | **CARRIED-OVER by design** — protected/foreign state, deliberately never staged |

**Resume command for the branch:**
`git fetch origin && git checkout codex/2026-07-13-v07-performance-localization` — HEAD must be `36c73e22`.
(Shinichi's local checkout is at the same sha; a fresh clone is equally valid now that it is pushed.)

**Never commit / never touch** (untracked or protected — leave alone):
`sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` (D2/D3/D4, not D1) ·
`docs/dev-log/2026-07-18-two-lever-news-fit-laplace-reml-is-the-cox-reid-lever.md` (untracked WIP) ·
the two `M` retry5 docs (`2026-07-15-v07-d0f-retry5-post-preseal-tree-blocker.md` under `after-task/` +
`check-log.d/` — protected state).

---

## Next Immediate Steps (ordered)

1. **Wait + verify `reseal3`.** Poll `cat ~/hsq_work/reseal3_all.DONE` → `RC=0`. Then verify
   `reseal3-d0f/stage_adjudication_receipt.tsv`: `verdict=PASS`, `stage_decision=COMPLETE`,
   `julia_replay_commit=8092fcb6`, `attempt_max_diff` bit-identical to `0f5fbb54` (~`3.18e-12`), tally
   **556 interior / 10 lower / 10 upper**, `adjudicate` sha == `validate-final` sha. Spawned-Rose close-out.
   If `RC≠0`, read `~/hsq_work/reseal3_all.log` for the failed stage (fail-closed; no seed — D0F seeds
   reproduce deterministically). It may be **blocker #4** — same "fix → re-seal" loop applies.
2. **Supersede** `reseal-d0f`/`0f5fbb54`/`976814` → `reseal3-d0f`/`<new sha>`/`8092fcb6` in the live docs
   (pattern: `scratchpad/d0f-reseal-supersede-applylist.md` if present, else the D1 pre-reg + coordination
   board). Update D1 pre-reg **PRE-4** (`976814`→`8092fcb6`) and the canonical-D0F-root (`reseal-d0f`→`reseal3-d0f`).
3. **D1 admission.** Edit `~/hsq_work/d1_admission.sh`: `D0F_ADJ=~/hsq_work/reseal3-d0f`, `JCC=8092fcb6…`,
   and the pre-run-review `JREPLAY=8092fcb6…` / `JREPSHA=36a264b2…`. Launch detached → build `d1-reviews`
   → `prepare d1` → `preseal` → `preflight`. **`preflight` should now PASS** (marker_ratio tolerance + head
   match). D1 seeds: `2_028_000_000 + 10_000·cell_index + offset`, offsets `101:148`, 12 interior cells =
   **576 fits, no bootstrap**.
4. **PRE-1…6 green-gate + adversarial pre-draw panel** (Rose + Curie + Gauss + Shannon lenses — each hunts a
   REAL pre-draw defect: git-dirty tree, load-time re-dirtying, seed collision, predecessor mis-binding,
   phase-order trap). **If fully GREEN → Shinichi's conditional-GO fires → the DRAW** → full pipeline
   (official 576 → locked → base_r → summarize-r → replay-julia → julia_summary → lineage → 5 reviews →
   adjudicate → validate-final) → D1 receipt → Rose close-out. **Halt and ask on any flag.**

**Driver-enforced phase order (do NOT reorder):** `official → locked → base_r → summarize-r → replay-julia
→ julia_summary → lineage → review → final`. `summarize-r` MUST precede `replay-julia`.

---

## Blockers / Open Questions

- ~~Origin push HELD~~ → **RESOLVED 2026-07-19**: Shinichi authorised it; branch pushed, `origin` @
  `36c73e22`. No PR opened — **do not merge to `main`** without him.
- **Possible blocker #4** — unknown until `reseal3` completes and D1 admission/preflight runs for real. The
  three so far were each invisible until the fail-closed pipeline hit them.
- **R-twin owed (coordination, not this repo):** (a) seed-lock `v07_genomic_recovery_v3_seed_lock.R` still
  labels bases `2042/2043` as reserved `D0F_RETRY7` though Retry-8 spent them — retirement amendment owed,
  **verified non-blocking** for D1's `2028000000` space. (b) D1 R deployment must be the sanctioned
  `retry8-prep/{hsquared@5325e95, HSquared.jl@8092fcb6}` tree — **RESOLVED**, that tree is on Totoro.
- **Owed follow-ups (non-blocking):** unit test for the `marker_ratio` tolerance path in
  `_validate_manifest`; Gauss/Rose lens on the validation-contract change; capability-status + validation-
  debt rows; reconcile Totoro `8092fcb6` ↔ pushed `512d7ca7` via GitHub (branch is now on `origin`).

---

## Gotchas & Failed Approaches

- **Totoro ssh — use the LITERAL allowlist form** (a `$SOCK` variable breaks the settings.json allowlist and
  falls to the flapping opus-4-8 Bash classifier):
  `ssh -o ControlPath=/Users/z3437171/.ssh/cm-snakagaw@totoro.biology.ualberta.ca:22 -o ControlMaster=no -o BatchMode=yes -o ConnectTimeout=20 totoro <cmd>`.
  Keep `<cmd>` simple (no `;`/`$()`/pipe); for multi-step, write a Totoro-side script and invoke `bash script.sh`.
- **The sidecar trap (blocker #3):** editing ANY sealed sim file (`sim/*_replay.jl`) requires regenerating
  its `.sha256` companion **and committing it** (a git-identity gate checks a clean tree; `preseal` checks
  the pin vs the bytes). After any sim edit, re-run the Rose sweep:
  `for s in $(git ls-files '*.sha256'); do f="${s%.sha256}"; [ "$(cut -d' ' -f1 "$s")" = "$(sha256sum "$f"|cut -d' ' -f1)" ] || echo "STALE $s"; done`
- **Cosmetic:** `reseal3_all.log` banner echoes "`@ Julia fa409fe6`" — a leftover sed label; the real
  `JL HEAD=8092fcb6` line is correct. Not worth restarting a long run.
- **Every heavy stage detached** (`nohup … > log 2>&1 &`) with a completion marker + log poll — survives the
  intermittent opus-4-8 classifier outages. Write scripts to disk on Totoro; don't stream heredocs through ssh.
- **Do not chase TMPDIR / OrderedCollections** — env already certified `ok=TRUE`.
- **Leftover `fit_one_sensitivity.R` jobs on Totoro are UNRELATED — do not touch.**

---

## How to Resume (Codex-tuned)

**Rehydrate order:** `AGENTS.md` (native — read first) → **this doc** → `ROADMAP.md` ·
`docs/design/capability-status.md` · `docs/dev-log/coordination-board.md` ·
`docs/dev-log/2026-07-18-d1-campaign-preregistration.md` ·
`docs/dev-log/2026-07-19-d1-blocker-2-marker-ratio-precision.md` (incl. §"Blocker #3") ·
`docs/dev-log/handover/2026-07-19-claude-handover-d1-blocker2-reseal.md` (full step-by-step recipe;
**substitute `reseal3` / `8092fcb6` for its `reseal2` / `fa409fe6`**).

**Team:** `.codex/agents/*.toml` — **Rose audit mandatory** before any public claim; Gauss/Karpinski/Noether
for `src/` numerics; Curie/Fisher/Mrode for validation evidence.

**Live-env (Totoro side, already set in the scripts):**
`export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=1` ·
`export TMPDIR=/home/snakagaw/hsq_work/jltmp` · workers `≤16` (shared box). Deployed trees:
`~/hsq_work/retry8-prep/{hsquared@5325e95, HSquared.jl@8092fcb6}`; orchestrator
`~/hsq_work/retry8-prep/hsquared/tools/run-v07-genomic-recovery-v3.sh`.

**One-command resume** (paste into a fresh Codex session started in the repo root — it reads `AGENTS.md`
natively):

```
Rehydrate from docs/dev-log/handover/2026-07-19-codex-handover.md + the AGENTS.md snapshot,
then continue with the Next Immediate Steps: wait for ~/hsq_work/reseal3_all.DONE (RC=0),
verify the reseal3-d0f receipt, supersede, then run D1 admission — draw stays behind the GREEN
panel + Shinichi's explicit GO.
```

---

## Mission-control summary

| Repo | Branch / origin / CI | What shipped this session | Plan by leverage |
|---|---|---|---|
| **HSquared.jl** (Julia engine) | `codex/2026-07-13-…` @ `36c73e22` · **PUSHED to origin, ahead 0** · CI n/a (docs-only) | 3 D1 blockers found+fixed (all pre-draw, 0 seed); sidecar regenerated; `reseal3` D0F re-seal relaunched at `8092fcb6` | **1.** `reseal3` → new D0F predecessor · **2.** D1 admission → preflight · **3.** panel → conditional draw → D1 receipt · **4.** (later) D2 downstream |
| **hsquared** (R twin) | same branch; deployed `5325e95` | — (Julia-lane session) | owed: seed-lock 2042/2043 retirement amendment (non-blocking) |

**Covered surface:** `public_covered_count = 5` (unchanged; D1 authorises no move). Engine ~70% / R public
~40% toward a first JSS-grade public release (see `docs/dev-log/2026-07-19-arcs-to-first-publishable-release.md`).
