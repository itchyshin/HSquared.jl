# Check log — published validation-status table made generated (drift class closed)

**2026-08-04 · Claude lane · branch `codex/2026-07-13-v07-performance-localization` · Szymek (owner-directed wrap-up)**

Discharges the carried-forward item the 2026-07-28 handover left unscheduled: the hand-maintained
table in `docs/src/validation-status.md` had drifted from `validation_status()`.

**Docs-only. No `src/` change, no test change, no capability flip, no new claim.**
`public_covered_count` stays **5**; row count stays **56**; every status string is the engine's own.

## What was checked

| Check | Command / method | Result |
|---|---|---|
| Extent of the drift | `validation_status()` dumped and diffed against the published table | **worse than recorded** — the handover named 4 missing rows; the table carried **33 of 56**, i.e. **23 missing** (see Finding 1) |
| Status-level drift | same diff, on the `status` column | **`V5-MARKER-THRESHOLD` published as `partial`; the engine says `covered`** (see Finding 2) |
| Field availability | `fieldnames(ValidationStatusRow)` | `(:id, :capability, :phase, :status, :evidence, :missing, :claim_boundary)` — a `claim_boundary` field exists, so the 5th column can be generated rather than hand-copied |
| Table-safety of the generated cells | scan all 56 rows × 5 rendered fields for `\n` and `\|` | **no newlines**; **4 rows contain pipes** → `cell()` escapes `\|` (and `\\` first, so the escape itself cannot be mangled) |
| Docs build | `julia --project=docs docs/make.jl` | **exit 0**; vitepress `build complete`; same 6 pre-existing/environmental warnings (undocumented internal helpers; logo/favicon/deploy) — no new warning |
| Rendered row count | `grep -c` data rows in `docs/build/.documenter/validation-status.md` | **56** |
| Rendered ids vs engine ids | `diff` of sorted id lists | **IDENTICAL** to `validation_status()` — no row invented, none dropped |
| Corrected statuses actually render | grep the built intermediate | `V5-MARKER-THRESHOLD` → `covered`; `V1-MATFREE-REML` → `partial`, present |
| Full suite | `julia --project=. -e 'using Pkg; Pkg.test()'` | **PASSED**, `Testing HSquared tests passed`, zero failures/errors suite-wide |
| Preamble cap | `bash tools/preamble_cap.sh` | **CAP OK** — 8717 B / 14000 B (~2179 tok), 1 snapshot entry / cap 1 |
| Status cache | `julia --project=. tools/gen_status_json.jl --refresh-count` | `rows=56 covered=13 public_covered=5` — **every count byte-identical**; only `refreshed_at` 07-28→08-04 and `refreshed_from_head` `07b3399a`→`67b60d8b` moved |
| Registry cross-check | debt-register ids vs `validation_status()` ids | 37 debt ids have no ladder row and 11 ladder ids have no debt row — **namespaces differ by design**, not drift; one genuine inconsistency isolated (Finding 3) |

## Findings

**Finding 1 — the recorded drift understated the real drift by 19 rows.** The 2026-07-28 handover
named four omissions (`V1-EIGEN-REML`, `V1-MATFREE-REML`, `V6-ORDINAL`, `V6-GAMMA`). The table
actually carried 33 of 56 rows. A hand-audited list of what a hand-maintained table is missing is
itself hand-maintained, and drifts the same way. This is why the fix is *generation*, not a resync:
re-copying 56 rows would have restarted the same clock.

**Finding 2 — one published status was not merely missing but WRONG.** `V5-MARKER-THRESHOLD` was
published as `partial` while the engine, the debt register (`covered (scoped)`), and its promotion
checkpoint all say `covered`. A missing row understates; a wrong status misinforms. It rendered
correctly the moment the table became generated.

**Finding 3 — `V1-EIGEN-REML` has a debt row but NO `validation_status()` row.** Its sibling
`V1-MATFREE-REML` has both. Both are experimental engine fitters staged for the same G10. So the
published validation ladder shows one of the three staged fitters and not the other. **NOT fixed
here** — adding a ladder row is a `src/` change that moves the published row count 56→57 and the
`length(validation) == 56` test assertion, which is a claim-surface change needing its own slice and
its own review, not a silent rider on a docs cleanup. **Handed to Shinichi as an open item.**

**Finding 4 — the first repair reproduced the defect it was fixing.** The initial edit kept the
stale 33-row table on the page under a "Superseded Hand-Maintained Rows" heading. That leaves a
wrong `V5-MARKER-THRESHOLD` status *published*, under a heading most readers would not read as
"ignore this". Removed entirely; git history is the archive. This is the 2026-07-28 lesson
("fixing a defect on a page does not fix the same defect elsewhere on that page") recurring on the
very page it was recorded about.

## Claim-vs-evidence check (Rose as a review LENS — no subagent was spawned)

**Stated plainly, per `AGENTS.md`: no `rose-systems-auditor` subagent ran for this slice.**
The lens questions and their answers:

- *Does this make any new capability claim?* No. Every rendered string is the engine's own
  already-reviewed `claim_boundary`; the fix removes hand-copies and changes no source of truth.
- *Does anything move toward `covered`?* No. `public_covered_count` = 5, unchanged and re-verified
  by the cache refresh. No flip, so gate **S4** (fresh promote-specific Rose) is not triggered.
- *Does the page now claim MORE than before?* It publishes 23 previously-hidden rows — but 22 are
  `partial`/`planned` and one (`V5-MARKER-THRESHOLD`) corrects an understatement to its already-
  audited scoped-covered wording. Net effect is more disclosed limitation, not more claim.
- *Residual risk:* the generated table inherits whatever `validation_status()` says. That is the
  intent — one source of truth — but it means a wrong `claim_boundary` in `src/` now reaches the
  published page directly, with no hand-written second opinion. Recorded as the deliberate trade.

## Bounds respected

`public_covered_count` **5** · nothing promoted · no `src/`, test, or fixture change · R twin
untouched (separate repo) · D1 lane untouched and still PAUSED · quarantined
`sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` untouched · no seed drawn · no ASReml run
and no timing claim (§4 fence not engaged) · not pushed.

Full report: `docs/dev-log/after-task/2026-08-04-validation-status-table-generated.md`.
