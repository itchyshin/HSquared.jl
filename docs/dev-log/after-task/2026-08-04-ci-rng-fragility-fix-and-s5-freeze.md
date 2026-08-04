# After-task — CI RNG-fragility fixed as a class; S5 frozen NOT RUN; G10 answered; Rose close-out

**Date:** 2026-08-04 · **Lane:** Julia engine (`HSquared.jl`) · **Branch:**
`codex/2026-07-13-v07-performance-localization` · **Role:** Rose (systems auditor), closing out the
arc that landed commits `7ceaff17` and `33ab68f6`.

## Task goal

Audit two just-landed commits against the repo's own evidence (capability rows, test counts,
docs-vs-code, the frozen predeclaration), record the G10 delegation decision and the S5 freeze hash,
fix a staleness class in the repo's coordination memory ("commits ahead" claims), and write the
check-log + this report — honestly, including a disclosed fence touch and a disclosed test-fixture
coverage narrowing.

Fences respected: nothing promoted; `public_covered_count` stays 5; no capability row flipped; R twin
not edited; quarantined `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` not
opened/staged/edited/hashed by this audit; S5 gate not run by this audit.

## What happened (verified against the repo, not taken on trust)

Szymek handed the Julia lane to Shinichi on 2026-08-04 (`docs/dev-log/handover/2026-08-04-shinichi-handover.md`).
His handover said "all local checks green" and "CI not verifiable (`gh` absent)" — **both true, and
the second is a tooling gap on his machine, not a lapse on his part.** `gh run list --limit 8`
(verified this session) shows CI was in fact green through 2026-07-25 and **failed on both
2026-08-04 runs** (10:51 and 12:40 UTC) — i.e. on the F6 arc, before Shinichi's session's fix commit
(16:13 UTC). Szymek could not have seen this without `gh`, and his own local `Pkg.test()` passed
because the failure was version-specific (see below) and he was not necessarily testing on the exact
Julia minor version CI's red leg used.

**Diagnosis (reproduced independently this session on both installed Julia versions):**

```
1.10.0  hash_y=1681c2cce99015df  exact_sa2=0.248016  converged=false  iterations=200  rel.err 5.45%
1.12.6  hash_y=0ed8df03f84d8621  exact_sa2=0.485196  converged=true   iterations=116  rel.err 0.79%
```

`rng = MersenneTwister(20260728)` generated the entire F6 in-CI dataset (pedigree topology and
phenotypes). Julia's `randn`/`rand` seeded stream is not stable across minor versions, so the two CI
legs were never fitting the same data — the harder 1.10 draw needed more than the 200-iteration EM
cap. **`converged=false` was iteration-cap exhaustion, not the zero-boundary early break.** An
earlier hypothesis, grounded in published REML boundary-failure rates, assumed the latter — **that
hypothesis is FALSIFIED for this instance** (the S5 predeclaration's revision log records this
explicitly, not as a quiet walk-back: `docs/dev-log/recovery-checkpoints/2026-08-04-f6-matfree-tail-recovery-predeclaration.md`,
"Revision log" and the "Why three-way, and why now" callout).

This repo had already hit this exact bug class once (`test/runtests.jl`'s `boundary_fixture` note:
"randn's seeded stream changed between Julia 1.10 and 1.12") and had written a policy against it
(`docs/dev-log/after-task/2026-06-14-phase4b-structured-recovery-harness.md`: "CI remains RNG-free").
F6 violated that policy and the same failure mode recurred, this time in three places, not one.

## Outcome — audit verdict: CLEAR-WITH-CHANGES

The two audited commits (`7ceaff17`, `33ab68f6`) hold up under independent re-verification. No
overclaim was found in either commit's own text. The **CHANGES** are the staleness-class fix and the
new decision/freeze records this report and its sibling commit deliver (see below) — not a defect in
the audited commits themselves. **Post-close-out correction, then a correction OF the
correction:** a peer session challenged a provenance detail in Finding 6 (the SMOKE-defect discovery
attributed to "a Totoro probe"); this report retracted it (`3e00eaae`) — and the **retraction was
itself wrong**. The orchestrator checked the primary run report and reinstated the original
attribution: the Totoro run genuinely did execute the driver and report `GATE: FAIL`. The retraction
had inferred from `git log` that an uncommitted file could not have been run on a server, which does
not follow. See Finding 6 for the settled sequence and the standing lesson.

## Evidence

| Check | Result |
|---|---|
| Capability rows | `fit_matrix_free_reml` stays `experimental`; `V1-MATFREE-REML` / `V3-NEFFECT-MATFREE-FIT` stay `partial` in both `docs/design/capability-status.md` and `docs/design/validation-debt-register.md`, before and after — confirmed by reading the literal diff, not the commit message |
| `public_covered_count` | **5**, `tools/status_cache.json` unchanged (`refreshed_from_head=67b60d8b`, predates both audited commits, neither touches this file) |
| In-CI test count 32→28 | **Confirmed at the runtime-executed-assertion level** (not naive static-line count — one `for spec,cap in (…),(…) @test … end` loop executes its single line 4×; accounting for that, PRE=19+13=32, CUR=16+12=28, exact match) |
| Docs-vs-code (in-CI vs opt-in) | Confirmed: current in-CI F6 testsets contain no `MersenneTwister`/`randn`/`rand`; `sim/f6_matfree_recovery.jl`'s fixture builder is a verbatim copy of the removed in-CI RNG code (same seed 20260728) — "SAME fixture/seed" holds |
| SMOKE fix | Confirmed in `sim/f6_matfree_recovery.jl`: boundary handling reports `NaN`+`ANOMALY` relative to trait scale; `SMOKE` gates on plumbing only |
| Predeclaration self-consistency | Read in full (404 lines) + script head/tail; internally consistent, explicitly "PROMOTES NOTHING", states its own caveats and one OWNER-REVISABLE judgment call (A3's bound) |
| S5 not run | `git show 33ab68f6 --stat`: only the predeclaration doc + script committed, no result TSV |
| Fence-touch metadata | `ls -la` (no content read/hash by this audit): quarantined file untracked, **size 14421 B, mtime Jul 14 05:41** — matches disclosure, unchanged |
| `Pkg.test()` Julia 1.10.0 | **PASSED** — independently re-run this session (`julia +release`), `HSquared tests passed`, exit 0, zero Fail/Error lines across 146 testsets |
| `Pkg.test()` Julia 1.12.6 | **PASSED** — independently re-run this session (`julia +1.12`), `HSquared tests passed`, exit 0, zero Fail/Error lines across 146 testsets (grep-verified) — same testset count as 1.10.0 |
| Docs build | **exit 0**; vitepress `build complete`; same 6 pre-existing/environmental warnings, none new |
| `preamble_cap.sh` | **CAP OK** both before (8595 B) and after (9485 B) this audit's edits; cap 14000 B, 1 snapshot entry / cap 1 |
| Staleness sweep | True state **2 commits ahead of origin `42572f91`** (`7ceaff17`, `33ab68f6`); both `AGENTS.md`'s "8 commits ahead" and `coordination-board.md`'s stale "2 docs commits ahead" corrected (see Findings) |

Both Julia versions were run to completion in this session (not merely re-quoted from the audited
commit's own message): `julia +release --project=. -e 'using Pkg; Pkg.test()'` (juliaup channel
`release`→1.10.0) and `julia +1.12 --project=. -e 'using Pkg; Pkg.test()'` (→1.12.6), each ending in
`Testing HSquared tests passed` / `EXIT_CODE=0`, each independently grep-scanned for stray
`Fail`/`Error` tokens outside expected `@test_throws`/error-name matches (zero found), each reporting
146 testsets.

## Findings, most notable first

**1. `AGENTS.md`'s "8 commits ahead of origin, UNPUSHED" was wrong even when written** — not stale,
wrong. At no point in this arc did `git log origin/<branch>..HEAD` show 8. The true count at the time
that entry was written (`2c1f4917`) was 2. Root cause not traced further (out of this audit's scope:
the entry predates both audited commits, and neither touches `AGENTS.md`). **Fixed** via the normal
one-entry rotation: the wrong entry is preserved **verbatim** in
`docs/dev-log/phase-snapshot-archive.md` (prepended, matching that file's established newest-first
convention — confirmed by inspecting how the two prior rotations, `67b60d8b` and `2c1f4917`, inserted
their archived entries), and a new entry with the verified count replaces it in `AGENTS.md`.

**2. `coordination-board.md`'s "2 docs commits are ahead" was correct when Szymek wrote it, and went
stale from subsequent events — a different failure mode than Finding 1, so given a different fix.**
It accurately described his handoff (`fa53b573`+`2c1f4917` ahead of origin `67b60d8b`). Since then
those 2 were pushed, and 2 new ones (`7ceaff17`, `33ab68f6`) landed — the number "2" now coincidentally
still looks plausible while describing entirely different commits. Rewriting Szymek's number in place
would misattribute this session's commits to his handoff. **Fixed** with an explicit
`[SUPERSEDED same day]` addendum immediately after the stale line (both in `coordination-board.md`
and in `docs/dev-log/handover/2026-08-04-shinichi-handover.md`'s equivalent top-line claim),
preserving the historical accuracy of what Szymek reported while pointing forward to current truth —
mirroring the non-destructive-correction principle this repo already applied on this same day to the
validation-status page (delete-and-regenerate for a *data table*; here, annotate-and-supersede for a
*point-in-time narrative claim*, since the two kinds of staleness call for different remedies). A new
dated section recording this session's actual work was appended to `coordination-board.md` (that
file's own convention is oldest-first/append, confirmed by its chronological entry ordering — the
opposite convention from `phase-snapshot-archive.md`, so each file was edited per its own rule).
Older genuinely-historical "commits ahead"/"not pushed" mentions elsewhere in `docs/dev-log/` (e.g.
the 2026-07-28 handover's "6 commits ahead", June entries) were **left untouched** — they are
point-in-time log entries, consistent with how this repo already treats history elsewhere (e.g.
`docs/dev-log/handover/2026-07-16-codex-handover.md`'s explicit `CARRIED-OVER` framing for old
unpushed branches). A repo-wide re-grep after all edits confirms no other live-state instance of the
wrong claim remains.

**3. The 32→28 reconciliation needed the runtime, not static, count.** A naive `grep -c '^\s*@test'`
over the touched testsets gives 29→25 — same Δ4 direction, wrong absolute numbers. One loop
(`for spec in (lowfill, highfill), cap in (100, 20_000)`, unchanged by this fix, present in the
`:auto` opt-in-fence testset both before and after) executes its single `@test` line 4 times at
runtime. Accounting for that resolves to the exact claimed 32→28. Recorded in the check-log so a
future auditor does not have to re-derive it.

**4. A fence touch, disclosed by the brief and independently confirmed here.** During slice C an
agent ran `md5` on the quarantined `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` while
checking git status — contrary to D-68/D-71's quarantine and the repo's D-84 rule ("never inspect,
stage, edit, or hash it"). **Verified via metadata only** (this audit ran `ls -la`, never content-read
or hashed the file): still untracked, size **14421 B**, mtime **Jul 14 05:41** — unchanged from
before the touch. **No impact.** Recorded here plainly, per the brief's explicit instruction not to
bury it, and because "assume there are ten more of the same kind" argues for surfacing every fence
touch, impactful or not.

**5. A coverage nuance, disclosed by the brief and independently confirmed here.** F6's K=2 sibling
in-CI testset (`test/runtests.jl:3491`, "Matrix-free MC-EM-REML fit recovers exact AI-REML (v0.8-S2
fit)") changed its fixture from random-mating (high fill) to a deterministic half-sib pedigree (low
fill) as part of the RNG-determinism fix. The assertions this testset retains are structural
(estimator tag, shapes, `trace_mcse` positivity and its shrinkage with more probes, two
`ArgumentError` guards) — fill-in is irrelevant to what they check, so this is not a coverage loss for
those specific assertions. Separately, the adjacent `:auto` opt-in-fence testset independently builds
its own `lowfill`/`highfill` n×fill grid via its own generator (`_ped(n; window, seed=11)`), so
:auto's routing behavior is still exercised across both fill regimes in-CI. **But the high-fill
numeric-recovery fixture itself now lives ONLY in the opt-in drivers** —
`sim/f6_matfree_recovery.jl` for the K=1 case, `sim/v08_s2fit_recovery_scale.jl` for the K=2 case —
not in CI at all, for either sibling. Stated explicitly because "in-CI" no longer means "exercises
high fill" for either of these two testsets, and that is a real (intended, disclosed) narrowing of
what a green CI run demonstrates.

**6. The SMOKE defect, verified. NOTE: this Finding was retracted once and the retraction was itself
wrong; the original attribution stands.** Sequence of the record, kept visible because the error is
instructive: this report first said the defect was "found via a Totoro probe at `nm=60`". A peer
session (Melissa) challenged that, this audit retracted it, and the retraction was committed
(`3e00eaae`). **The orchestrator then re-checked against primary evidence and reinstated the original
attribution.** The retraction's reasoning was: `git log --all -- sim/f6_matfree_recovery.jl` returns
exactly one commit, so "no earlier, unfixed version was ever committed, therefore the bug cannot have
been found by running the script on Totoro." **That inference is invalid** — the driver existed in the
*working tree*, uncommitted, and was copied to Totoro as a single file. Git history cannot see that.

Primary evidence (the Totoro run report, step 3 of that slice's brief):
`HSQ_F6_SMOKE=1 OPENBLAS_NUM_THREADS=1 ~/hsq_work/julia-1.10.0/bin/julia --project=. sim/f6_matfree_recovery.jl`
→ `host=totoro julia=1.10.0`, `exact: sigma_a2=0.0000 ... GATE: FAIL`, with the report stating
explicitly that this internal gate failure "is a substantive finding, not a plumbing failure."

**Settled sequence:** slice-C saw the `rel_a≈980` symptom in a *local* SMOKE run, judged it acceptable
against F5-v2 precedent, and did not fix it → the Totoro SMOKE run surfaced it again, to the
orchestrator → the orchestrator wrote the fix and verified it on Julia 1.10.0 and 1.12.6 → it was
committed. Both accounts were partly right; neither agent held the run report.

**How to falsify this yourself — the evidence is checkable, not just quoted.** A transcript pasted
into a commit message is a citation, not a primary artifact; that objection was raised and it was
fair. The deployed copy is still on Totoro:

```sh
SOCK=$(ls ~/.ssh/cm-*totoro* | head -1)
ssh -o ControlPath="$SOCK" -o ControlMaster=no -o BatchMode=yes totoro \
  'ls -la ~/hsq_work/grace-f6smoke/sim/; grep -c "on_boundary\|ANOMALY" ~/hsq_work/grace-f6smoke/sim/f6_matfree_recovery.jl'
```

Expected: `f6_matfree_recovery.jl`, 5810 B, **Aug 4 09:13**, and the grep returns **0**. That zero is
the decisive fact — the fix introduced `on_boundary`/`safe_rel`/`ANOMALY`, and the Totoro copy
contains none of them, so it is provably the **pre-fix** version. It was deployed and run before the
fix existed. The current in-repo file contains all three.

**The decisive evidence is IN THE REPO and needs no Totoro access.** The fix's own source comment,
committed in `7ceaff17` and written at fix time — before any of this was disputed — records both
numbers and attributes them correctly:

```
git show 7ceaff17:sim/f6_matfree_recovery.jl | sed -n '73,78p'
  # ... Measured on Totoro 2026-08-04 at the smoke size nm=60, the exact fit
  # returns sigma_a2 = 0 and the naive ratio reports rel_a ≈ 4e4 ...
  # ... an absolute 1e-8 cutoff would miss it and print rel.err = 980 as if it meant something.
```

`4e4` is **40925.4**, the Totoro run. `980` is the *later local* run. The author of the fix could
only have written "on Totoro … 4e4" while looking at Totoro's output — the local run never produced
that figure. This is a fingerprint internal to the commit under dispute, predating the dispute, and
verifiable with one `git show`. (Independently corroborated afterwards: the run was reproduced on
Totoro byte-for-byte against the still-deployed sha256-verified copy, with the output persisted this
time to `~/hsq_work/grace_f6_smoke_reproduction.log` — the original run's missing standalone log was
a real gap, acknowledged rather than argued around.)

**Two different rel.err figures, kept distinct:** Totoro's original run reported
`rel.err sigma_a2 = 40925.4` (naive absolute denominator). The ≈980 figure quoted elsewhere is a
*later local* run, after the first edit introduced an absolute `1e-8` cutoff that was still too tight.
Same defect, two denominators, two runs — they are not the same measurement and should not be merged.

**Standing lesson:** two independent agents converged confidently on a wrong conclusion by reasoning
from git history alone about work that was still uncommitted. Absence from `git log` is not absence
from the session. Prefer the primary artifact over an inference about it — and when you cite one,
say where it lives and how to check it. **What the defect was, and its fix, both hold:**
before the fix, the opt-in driver's SMOKE mode reported a meaningless `GATE: FAIL` at `nm=60` because
the exact fit at that shrunken size lands on the variance boundary (`sigma_a2 ≈ 4e-5` against
`sigma_e2 ≈ 0.70`) and a naive relative-error denominator collapses (measured rel.err ≈ 980, and
separately ≈ 4e4 with an absolute-vs-relative boundary test). **Fixed:** SMOKE is now explicitly
plumbing-only (asserts finite output from both fitters, not recovery), and any boundary case — in
SMOKE or full mode — reports an explicit `ANOMALY` (NaN) judged relative to trait scale rather than a
spurious FAIL. Confirmed by reading `sim/f6_matfree_recovery.jl`'s
`on_boundary`/`safe_rel`/`plumbing_ok`/`gate` logic in full.

## Decisions recorded this session

- **G10 is NOT delegated to Szymek — confirmed 2026-08-04, stays with Shinichi.** Open since the
  2026-07-24 onboarding note (`docs/dev-log/handover/2026-07-24-szymek-onboarding.md:68-71`), flagged
  unanswered in two subsequent handovers, now closed. Practical effect: none — every agent had already
  defaulted to treating G10 as Shinichi's in the absence of an answer, so this confirms rather than
  changes the standing sign-off rows S1/S2/S3. Recorded:
  `docs/dev-log/decisions/2026-08-04-g10-not-delegated-and-s5-freeze-record.md`.
- **S5 predeclaration frozen at commit `33ab68f6`. STATUS: NOT RUN.** Following the convention of the
  F5 v2 gate (frozen `4fb6fb66`) and the v08 gate (PREDECL `66ac9521` BEFORE the run). Recorded in the
  same decision doc above, alongside the `docs/design/capability-status.md` / recovery-checkpoints
  citations already in place.

## Capability status / validation debt

**No row changed in either register.** `docs/design/capability-status.md` and
`docs/design/validation-debt-register.md` were touched by the audited commit `7ceaff17` only to
correct the in-CI test count and name the opt-in driver as the recovery-claim's home — not to change
any `status` cell. Verified by literal diff read (see Evidence table).

## Open items / still OWED for any covered flip

`V1-MATFREE-REML` (and by extension the case for wiring `:auto`) still owes, unchanged by this
session:

- **S5 — the full 48(Leg A)+8(Leg X)-seed run.** Frozen, not run.
- **S6 — the at-scale external comparator.** The existing ASReml agreement is at q=2000 / fill 75.2,
  below the measured crossover of 150 — the wrong regime.
- **S4 — a FRESH promote-specific Rose (G8).** This audit is a claim-vs-evidence close-out of a
  CI-fix + freeze arc, not a promotion audit; it does not discharge S4.
- **S3 / G10 — the sign-off itself.** The delegation question is now answered (not delegated), but
  Shinichi's actual covered/not-covered decision for `fit_matrix_free_reml` remains open, as it does
  for `fit_ai_reml` (S1) and `fit_eigen_reml` (S2).
- **S7 — the R bridge.** Separate repo; not this lane's to implement.

Also still open, carried from the prior session and unaffected by this one: `V1-EIGEN-REML` has a
debt-register row but no `validation_status()` row while `V1-MATFREE-REML` has both (deliberately not
fixed here — a `src/` change belongs to its own slice).

## Bounds respected

`public_covered_count` **5** · nothing promoted · no capability row flipped · no `src/`, test, or
fixture change from this audit (docs-only) · R twin untouched (separate repo) · D1 untouched, still
PAUSED · quarantined `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` NOT opened, edited, or
hashed by this audit (a prior fence touch during slice C is disclosed above, not repeated here) · S5
gate NOT run by this audit · ASReml estimand-only fence (§4) not engaged, no new comparator run · not
pushed (PR #274 stays draft; the maintainer merges).

## What was NOT done, and why

- **The S5 gate itself was not run.** Out of scope for this audit by the brief's explicit fence, and
  by the repo's freeze-then-run doctrine — running it is a separate, later, deliberate action.
- **No fresh promote-specific Rose (S4).** Not triggered: no capability flip occurred or is proposed
  by this session's work.
- **The R bridge (S7) was not touched.** Separate repo; this lane edits only `HSquared.jl`.
- **`ROADMAP.md` was checked (grep, no match for the stale claim) but not edited** — it carries no
  push-state claim to correct.

Handover pointer for the next session: this report + `AGENTS.md`'s rotated Live Phase Snapshot entry.
