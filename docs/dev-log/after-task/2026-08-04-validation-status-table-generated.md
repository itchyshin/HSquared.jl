# After-task — published validation-status table made generated; session wrap-up for handover

**Date:** 2026-08-04 · **Lane:** Julia engine (`HSquared.jl`) · **Branch:**
`codex/2026-07-13-v07-performance-localization` · **Owner:** Szymek (directed this session; wrapping
up for handover to Shinichi).

## Task goal

Rehydrate, then do **what is actually doable on this machine** and close the session cleanly for
handover. The 2026-07-28 handover's ordered next steps are all blocked on cluster access (**S8**),
which Szymek does not have. The one carried-forward item that needed no compute and no gate was the
drifted `docs/src/validation-status.md` table.

Fences carried in: `public_covered_count` stays **5**; no flip without a FRESH promote-specific Rose
(**S4**) + owner **G10**; ASReml estimand-only (§4); D1 PAUSED; R twin not edited; quarantined sim
file untouched.

## Outcome

**Done, and the defect was larger than recorded.** Docs-only; nothing promoted; no new claim.

The handover said the table "omits `V1-EIGEN-REML`, `V1-MATFREE-REML`, `V6-ORDINAL`, `V6-GAMMA`".
Dumping `validation_status()` and diffing showed the table carried **33 of 56 rows — 23 missing** —
and that one published status was not just absent but **wrong**: `V5-MARKER-THRESHOLD` was published
`partial` while the engine, the debt register (`covered (scoped)`), and its own promotion checkpoint
all say `covered`.

That changed the fix. Resyncing 56 rows by hand would have restarted exactly the clock that produced
the drift — and the hand-audited list of omissions had itself already drifted, which is the tell.
`ValidationStatusRow` carries a `claim_boundary` field, so the whole table can be **generated**:

```@eval
using HSquared
using Markdown
cell(x) = replace(replace(string(x), "\\" => "\\\\"), "|" => "\\|")
# ... emits the markdown table from validation_status() ...
```

The page now cannot disagree with the engine. The drift class is closed, not the drift instance.

## Evidence

| Check | Result |
|---|---|
| Docs build (`julia --project=docs docs/make.jl`) | **exit 0**, vitepress `build complete`; same 6 pre-existing/environmental warnings, none new |
| Rendered data rows | **56** |
| Rendered ids vs `validation_status()` ids | **IDENTICAL** (sorted `diff` empty) — nothing invented, nothing dropped |
| Corrected statuses in the built output | `V5-MARKER-THRESHOLD` → `covered`; `V1-MATFREE-REML` → `partial`, now present |
| Cell hygiene | 0 newline-bearing fields; **4 pipe-bearing rows**, escaped (`\\` escaped before `\|`) |
| `Pkg.test()` | **passed**, zero failures/errors suite-wide |
| `bash tools/preamble_cap.sh` | **CAP OK** — 8717 B / 14000 B, 1 snapshot entry / cap 1 |
| Status cache refresh | `rows=56 covered=13 public_covered=5` — **every count byte-identical**; only `refreshed_at` and `refreshed_from_head` moved |

## Two things worth not repeating

**A hand-maintained list of what a hand-maintained table is missing drifts too.** The handover's
four-row omission list was itself six times short. Any audit finding recorded as prose about a
mechanical fact should be re-derived mechanically before it is acted on — it took one Julia
one-liner to find the real number.

**The first repair reproduced the defect it was repairing.** The initial edit parked the stale
33-row table under a "Superseded Hand-Maintained Rows" heading. That still *publishes* a wrong
`V5-MARKER-THRESHOLD` status, under a heading a reader has no reason to treat as void. Deleted
outright; git history is the archive. This is the 2026-07-28 lesson recurring — on the very page it
was written about.

## Claim-vs-evidence (Rose as a LENS — no subagent ran)

Stated explicitly per `AGENTS.md`: **no `rose-systems-auditor` subagent was spawned for this slice.**
No capability flipped, so **S4** (the fresh promote-specific Rose) is not triggered. Every rendered
string is the engine's own already-reviewed `claim_boundary`. The page now discloses 23 previously
hidden rows, 22 of them `partial`/`planned` — net *more* disclosed limitation, not more claim.

**Deliberate trade recorded:** the generated table inherits `validation_status()` verbatim, so a
wrong `claim_boundary` in `src/` now reaches the published page with no hand-written second opinion.
That is the point of a single source of truth, and it is the cost of it.

## Capability status / validation debt

**No row changed in either register, and that is correct** — this slice altered no capability and no
evidence. `docs/design/capability-status.md` and `docs/design/validation-debt-register.md` are
untouched. The published-page fix is recorded here and in the check log.

## OPEN item handed onward

**`V1-EIGEN-REML` has a debt-register row but no `validation_status()` row**, while its sibling
`V1-MATFREE-REML` has both — so the published validation ladder shows one of the three staged engine
fitters and not the other. Not fixed here on purpose: adding a ladder row is a `src/` change that
moves the published row count 56→57 and the `length(validation) == 56` test assertion. That is a
claim-surface change and deserves its own slice and review, not a silent rider on a docs cleanup.

## Bounds respected

`public_covered_count` **5** · nothing promoted · no `src/`, test, or fixture change · R twin
untouched (separate repo) · D1 untouched, still PAUSED · quarantined
`sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` untouched · no seed drawn · no ASReml run,
no timing claim · **not pushed** (PR #274 stays draft; the maintainer merges).

## What was NOT done, and why

Everything else in the 2026-07-28 next-steps list is blocked on **S8 (Totoro/DRAC access)**, which
is Shinichi's to grant and which Szymek does not have:

- **S5** — the pre-declared known-truth recovery gate at `n > 20 000`. Drafting is possible; the
  doctrine is **freeze-then-run**, so freezing a predeclaration before compute is confirmed would
  invert the gate's whole point. Deliberately not started.
- **S6** — the at-scale external comparator (the ASReml run sits at q=2000, *below* the crossover).
- **S7** — the R bridge: a different repo, and this lane must not edit it.
- **S1/S2/S3** — G10 sign-offs, all Shinichi's.

Handover: `docs/dev-log/handover/2026-08-04-shinichi-handover.md`.
