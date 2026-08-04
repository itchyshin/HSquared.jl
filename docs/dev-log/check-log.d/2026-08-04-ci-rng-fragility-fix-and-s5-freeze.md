# Check log — CI RNG-fragility fixed as a class; S5 frozen NOT RUN; G10 answered; Rose close-out

**2026-08-04 · Claude lane (Rose audit) · branch `codex/2026-07-13-v07-performance-localization`**

Audits commits `7ceaff17` (CI fix) and `33ab68f6` (S5 freeze), records the G10 decision and the
freeze hash, corrects a staleness class in the repo's own coordination memory, and closes the arc.

**No capability flip. `public_covered_count` stays 5.** S5 gate NOT RUN (frozen only).

## What was checked

| Check | Command / method | Result |
|---|---|---|
| No capability row flipped | `git show 7ceaff17 -- docs/design/capability-status.md docs/design/validation-debt-register.md` | `fit_matrix_free_reml` row stays `experimental`; `V1-MATFREE-REML` and `V3-NEFFECT-MATFREE-FIT` rows stay `partial`; both text bodies explicitly restate `public_covered_count unchanged (5)` before and after |
| `public_covered_count` | `cat tools/status_cache.json` | `5`; `refreshed_from_head=67b60d8b`, unchanged by either audited commit (not in either commit's file list) |
| In-CI test-count claim (32→28) | boundary lines via `grep -n '@testset "'`, then `sed -n | grep -c '^\s*@test(_throws)?\b'` on both the F6 K=1 testset and its adjacent `:auto` opt-in-fence testset, pre-image (`git show 42572f91:test/runtests.jl`) vs current HEAD, then reconciled against Julia's runtime-executed-assertion count (the `for spec in (lowfill,highfill), cap in (100,20_000)` loop executes its one `@test` line 4×) | static-line count PRE=29/CUR=25 (Δ-4, matches direction); **runtime-executed count PRE=19+13=32, CUR=16+12=28 — exact match to the claimed 32→28** |
| Docs description matches code (in-CI vs opt-in) | read `test/runtests.jl` F6 K=1 + K=2 testsets in full (current + pre-image) and `sim/f6_matfree_recovery.jl` in full | confirmed: current in-CI testsets contain no `MersenneTwister`/`randn`/`rand`; `sim/f6_matfree_recovery.jl`'s `highfill_fixture()` is a verbatim copy of the REMOVED in-CI RNG fixture-construction code (same seed 20260728, same generator) — "SAME fixture/seed" claim holds |
| SMOKE-mode fix | read `sim/f6_matfree_recovery.jl` in full | `on_boundary`/`safe_rel` functions report `NaN`+`ANOMALY` when the exact fit is on the variance boundary (relative to trait scale, not an absolute cutoff); `SMOKE` gate is `plumbing_ok` only, does not assert recovery |
| Predeclaration self-consistency | read `docs/dev-log/recovery-checkpoints/2026-08-04-f6-matfree-tail-recovery-predeclaration.md` in full (404 lines) + `sim/phase_s5_matfree_tail_recovery_gate.jl` head/tail | internally consistent with its own commit message; explicit "PROMOTES NOTHING"; states its own caveats (n=1 feasibility probe, 48-way untested, Leg X not separately timed); OWNER-REVISABLE clause scoped to A3 only; script's own header repeats "do not run the 48+8-seed campaign until frozen" |
| S5 not run | `git show 33ab68f6 --stat` (only the predeclaration doc + script added, no result TSV); script header comment | confirmed — no `s5_recovery.tsv`/`smoke_s5.tsv` committed |
| Frozen predeclaration promises nothing undeliverable | re-read Leg A/Leg X criteria against what `fit_matrix_free_reml`'s documented interface actually returns (`converged`, `iterations`, `variance_components`) | all referenced fields exist on the fitter's return type per `docs/design/capability-status.md:91`; no criterion depends on unimplemented behavior |
| CI actually red pre-fix | `gh run list --limit 8` | two 2026-08-04 CI runs both `completed failure` (10:51 and 12:40 UTC, before the 16:13 UTC fix commit); last green run 2026-07-25 |
| `gh` absence claim | n/a (documentary) | consistent with `docs/dev-log/handover/2026-08-04-shinichi-handover.md:114` ("`gh` is not installed on Szymek's machine") and the 2026-07-24 onboarding note's compute section |
| Fence-touch disclosure | `ls -la sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` (metadata only — no read/hash performed by this audit) | untracked (`git status -sb` `??`), size **14421 B**, mtime **Jul 14 05:41** — matches the disclosed state exactly; not touched by this audit |
| Independent re-run: `Pkg.test()` Julia 1.10.0 | `julia +release --project=. -e 'using Pkg; Pkg.test()'` (juliaup channel `release`→1.10.0) | **PASSED** — `HSquared tests passed`, exit 0, zero Fail/Error lines across 146 testsets (grep-verified) |
| Independent re-run: `Pkg.test()` Julia 1.12.6 | `julia +1.12 --project=. -e 'using Pkg; Pkg.test()'` | **PASSED** — see after-task for the same zero-Fail/Error verification |
| Docs build | `julia --project=docs docs/make.jl` | **exit 0**; vitepress `build complete`; same class of 6 pre-existing/environmental warnings (38 undocumented docstrings, chunk-size, no-logo, no-favicon, no-package.json, no-deploy-env-detected) — none new |
| Preamble cap | `bash tools/preamble_cap.sh` | **CAP OK** before this audit's edits (8595 B) and after (9485 B), cap 14000 B; 1 snapshot entry / cap 1 both times |
| Staleness sweep | `git status -sb`; `git log --oneline origin/codex/2026-07-13-v07-performance-localization..HEAD`; repo-wide `grep -rniE "commits? ahead\|not pushed\|unpushed"` | true state: **2 commits ahead of origin `42572f91`** (`7ceaff17`, `33ab68f6`); `AGENTS.md`'s "8 commits ahead" was wrong even when written; `coordination-board.md`'s "2 docs commits ahead" was correct when Szymek wrote it but is now stale (those 2 got pushed; 2 different commits are ahead now) — both corrected, see Findings |

## Findings

**Finding 1 — `AGENTS.md`'s Live Phase Snapshot claim ("8 commits ahead of origin, UNPUSHED") was
wrong at the time it was written**, not merely stale. `git log origin/<branch>..HEAD` never showed 8
at any point in this arc's recent history; the true count when that entry was written (at `2c1f4917`)
was 2. Root cause not fully traced (out of scope for this audit — the entry predates both audited
commits and neither touches `AGENTS.md`), but likely inherited/miscounted during a prior rotation.
Fixed by the normal snapshot-rotation mechanism: the wrong entry is preserved **verbatim** in
`docs/dev-log/phase-snapshot-archive.md` (errors and all — historical record, not silently cleaned),
and a new entry with the verified-true count replaces it.

**Finding 2 — `coordination-board.md`'s "2 docs commits are ahead" was correct when written, then
went stale from subsequent events, not from being wrong.** Szymek's entry accurately described his
own handoff state (`fa53b573`+`2c1f4917` ahead of origin `67b60d8b`). Between then and this audit,
those 2 commits were pushed AND 2 new ones (`7ceaff17`, `33ab68f6`) landed — so the same NUMBER "2"
is now accidentally still numerically plausible-looking while describing entirely different commits.
Because this is genuinely a different failure mode than Finding 1 (natural staleness from subsequent
work, not a miscount), it is corrected with an explicit **`[SUPERSEDED same day]`** addendum rather
than a silent number edit — preserving Szymek's accurate self-report while flagging it stale, per the
same non-destructive-correction principle applied on 2026-08-04 to the validation-status page
(`docs/dev-log/check-log.d/2026-08-04-validation-status-table-generated.md`, Finding 4). Same
treatment applied to `docs/dev-log/handover/2026-08-04-shinichi-handover.md`'s identical line. A new
dated entry recording this session's actual work was appended to `coordination-board.md`.

**Finding 3 — the "32 → 28" in-CI test-count claim is correct, but only reconciles at the
runtime-executed-assertion level, not a naive static-line count.** One loop
(`for spec in (lowfill, highfill), cap in (100, 20_000) @test ... end`, present unchanged in both the
pre- and post-fix `:auto` opt-in-fence testset) executes its single `@test` line 4 times at runtime.
Static grep of `@test`-prefixed lines gives 29→25 (same Δ-4, wrong absolute numbers); accounting for
the loop's 3 extra iterations in both counts gives the exact claimed 32→28. Recorded here so a future
auditor does not have to re-derive this.

**Finding 4 (fence touch, disclosed by the brief, independently confirmed) — `md5` was run on the
quarantined `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` during slice C, contrary to
D-84.** Confirmed via metadata-only inspection (`ls -la`, no content read/hash performed by this
audit): the file is still untracked, size 14421 B, mtime Jul 14 05:41 — unchanged. **No impact.**
Recorded plainly, not buried, per the brief's explicit instruction.

**Finding 5 (coverage nuance, disclosed by the brief, independently confirmed) — F6's in-CI fixture
changed from random-mating (high fill) to half-sib (low fill) for the K=2 sibling testset.** Verified
in the `test/runtests.jl` diff: the retained K=2 assertions are structural (estimator tag, shapes,
`trace_mcse` positivity/shrinkage, guards), so fill is irrelevant to what they check; the `:auto`
opt-in fence testset independently builds its own `lowfill`/`highfill` grid (both fill regimes) via
its own `_ped(n; window, seed=11)` generator, unaffected by this change. **The high-fill fixture now
lives ONLY in the opt-in driver** (`sim/f6_matfree_recovery.jl`, K=1 case) and
`sim/v08_s2fit_recovery_scale.jl` (K=2 case) — stated explicitly here because "in-CI" no longer means
"exercises high fill" for either testset.

## Claim-vs-evidence check (Rose, real spawned audit)

- *Does this make any new capability claim?* No. `fit_matrix_free_reml` stays `experimental`;
  `V1-MATFREE-REML`/`V3-NEFFECT-MATFREE-FIT` stay `partial`. Verified by direct diff read, not by
  trusting the commit message.
- *Does anything move toward `covered`?* No. `public_covered_count=5`, confirmed unchanged in
  `tools/status_cache.json` and un-mentioned in either commit's file list.
- *Does the S5 freeze commit itself claim a result?* No — verified the predeclaration's own banner
  ("STATUS: FROZEN... NOT RUN") and confirmed no result TSV was committed alongside it.
- *Is the "falsified hypothesis" claim honest, or is it quietly walking back an earlier claim without
  saying so?* Checked: the predeclaration doc's own revision log (v1→v2→v3) states the zero-boundary
  hypothesis explicitly as **falsified for this instance**, not merely revised, and gives the
  reproduced evidence (converged=false + iterations=200 + non-boundary sigma values) supporting that.
- *Residual risk:* the S5 predeclaration's A3 cap-exhaustion bound (≤4/48) is explicitly flagged
  OWNER-REVISABLE by the predeclaration itself — a genuine judgment call with no in-repo precedent,
  not evidence of overreach; already disclosed, not newly found.

## Bounds respected

`public_covered_count` **5** · nothing promoted · no `src/` change beyond the audited commits
(this audit is docs-only) · R twin untouched (separate repo) · D1 untouched, still PAUSED ·
quarantined `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` NOT opened/edited/hashed by
this audit (metadata-only `ls -la`) · S5 gate NOT run by this audit · not pushed.

Full report: `docs/dev-log/after-task/2026-08-04-ci-rng-fragility-fix-and-s5-freeze.md`.
