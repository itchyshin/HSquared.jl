# After-task — v0.7 Smoke-Gate Contract Remediation (PLANNING-ONLY; D1 stays paused)

**Date:** 2026-07-20 · **Lane:** Julia engine (`HSquared.jl`) docs, reviewing R-side sealed source
(`hsquared@5325e95`) read-only · **Executor:** Claude (user-authorized; SOLO platform).
**Authority:** Shinichi authorized a **planning-only** remediation on 2026-07-20 — full-sweep scope,
artifacts in `HSquared.jl`, `hsquared` untouched. **No implementation, no campaign, no seed.**

## Task goal

The D1 recovery-v3 campaign burned four official smoke seeds and died `RC=21`
(`fewer than 16 completed smoke attempts`). The static cause is
`SMOKE_N_LADDER_RECOMMEND_WORKERS_CARDINALITY_MISMATCH`. Goal: sweep **every** producer/consumer
row-cardinality pair across **all** modes of the sealed launcher, name arity as **data** rather than
as independent literals on each side, and pre-declare falsifiable acceptance criteria a future
implementation slice must satisfy — without touching `hsquared`, the retired root, or any seed.

The deliverable is a **declared arity contract (data)**, not a behavioural composed test. A composed
`smoke-n-ladder → recommend-workers` test is **impossible as a shipped check**: `run_official_pairs`
(`tools/run-v07-genomic-recovery-v3.sh:397-407`) spawns real fits and would consume real seeds, and
`recommend_workers` reads Linux-only `/proc/meminfo` (`:571`). That impossibility is recorded, not
worked around.

## Outcome (met, planning-only)

Four artifacts. An 11-row arity contract table covering every mode: **1 MISMATCH** (the
`smoke-n-ladder`/`recommend_workers` defect that killed D1), **1 MESSAGE-MISMATCH** (`smoke-16`'s
`>= 16` predicate carrying a `die` message reading "exactly 16"), **3 SPECIFIED**, **4 UNSPECIFIED**,
**2 DEAD** (`run_base_r_pairs`, `run_julia_pairs` — reported, not removed).

Three findings, in ascending depth:

1. **The fix is a generalization, not an invention.** All three `SPECIFIED` rows already use the
   correct pattern — *count what was produced, don't assert what was expected*. Two sites lack it.
2. **The broken contract is cross-mode.** `recommend_workers` is never called from the
   `smoke-n-ladder` case body; no single-mode test can ever exercise both sides. The sequencing
   knowledge lived entirely in `d1_reseal4_campaign.sh`, which **is committed to neither repository
   and appears in neither `git log --all`**.
3. **The deepest defect is an undeclared corpus.** All four `UNSPECIFIED` rows share one root: four
   consumer modes read `$out/attempts/$stage/**/*.tsv` written by *whatever wrote them*. "4 != 16"
   is where this surfaced; a cell design yielding sixteen rows would have passed **by coincidence**
   with the same defect in place.

**This satisfies exactly ONE of six successor preconditions** — "launcher contract investigation"
(`docs/dev-log/handover/2026-07-20-d1-reseal4-postdraw-retirement.md:27-28`). The other **five**
remain open: a new root, a disjoint allocation, a new pre-registration, fresh mutation
controls/reviews/preseal, and explicit authorization. **D1 remains PAUSED.**

`attempts_per_rung = 4` is an **OWNER DECISION of 2026-07-20, not recovered intent.** Nothing in
either repository establishes what row count the failed campaign intended. That `4 × 4 = 16`
reproduces the sealed script's existing literal is a consistency check, never evidence of prior
intent.

## Active lenses and spawned agents

Actually spawned as subagents (not used as review perspectives): **P1** (arity table), **P2**
(provenance), **P3** (contract spec), **P4** (predeclaration), **P5-rose** / **P5-gauss** /
**P5-fisher** (adversarial review, parallel), **P6-verify** (mechanical verification), and this
**Rose** close-out (Opus, adversarial, default-NOT-DONE).

P5 verdicts and what each changed:

- **Rose — CLEAN-WITH-LIMITATIONS.** 4 fixes: a scope fence travelling with the TSV (it is read in
  isolation); a local caveat on the "Proposed contract" section; the `attempts_per_rung=4`
  owner-decision caveat placed **at its definition**; P4 §4 retitled "Status: NO-GO".
- **Gauss — SOUND-WITH-GAPS.** Added the RSS order-statistic risk (4 draws per rung raise expected
  `max(rss)`, **lowering** recommended workers and increasing exposure to the `workers < 1` floor
  stop at `:576-578` — the count-guard fix may simply relocate the failure to the resource guard);
  the `--attempts` validation gap (an unvalidated `--attempts` reintroduces this document's own
  anti-pattern one layer up); the broader off-cluster platform gap; the unquantified 4× smoke cost;
  the sha256-sidecar integrity gap in the same glob; and a TSV correction.
- **Fisher — INSUFFICIENT on C1–C4 as drafted.** C3 rewritten to require **committed** mutation-kill
  evidence with non-degenerate fixtures (as drafted it was unauditable self-report — structurally
  the same unfalsifiable claim as the `expect_match` disease it exists to prevent). C4 rewritten to
  forbid bare deletion without replacement coverage. **C5 added.** Guard-order invariant pinned. A
  "what an implementer can satisfy completely and still get wrong" list added — including the
  admission that the predeclaration fixes **one** of the **two** sites needing the identical fix
  (`smoke-16`'s hardcoded `${smoke_rows[@]:0:16}` at `:633` is untouched).

## Files changed

Created:

- `/Users/z3437171/Dropbox/Github Local/HSquared.jl/docs/design/50-recovery-v3-arity-contract.tsv`
- `/Users/z3437171/Dropbox/Github Local/HSquared.jl/docs/design/50-recovery-v3-arity-contract.md`
- `/Users/z3437171/Dropbox/Github Local/HSquared.jl/docs/dev-log/recovery-checkpoints/2026-07-20-smoke-arity-contract-predeclaration.md`
- `/Users/z3437171/Dropbox/Github Local/HSquared.jl/docs/dev-log/after-task/2026-07-20-v07-smoke-gate-contract-remediation.md` (this file)
- `/Users/z3437171/Dropbox/Github Local/HSquared.jl/docs/dev-log/check-log.d/2026-07-20-v07-smoke-gate-contract-remediation.md`

Modified:

- `docs/dev-log/recovery-checkpoints/2026-07-20-d1-smoke-contract-arity-diagnosis.md` — appended
  "Correction note" recording an unresolved controller-provenance contradiction (per owner
  directive: note it, do not investigate it).
- `ROADMAP.md`, `docs/dev-log/coordination-board.md` — D1 wording records the precondition satisfied
  **and that five remain open**.

**`hsquared` NOT modified.** The sealed source was read only via `git show 5325e95:<path>`; the
working tree was never checked out. The retired root `/home/snakagaw/hsq_work/d1-reseal4` and seed
space `2028000000/101:148` were not read. No remote connection; no seed allocation; no PR touched.

**DO-NOT-TOUCH, and untouched** (verified by `git status`): the two protected retry-5 files, the
untracked two-lever note, and the `sim/` scaffold — all foreign carried-over work, unstaged.

## Checks run and exact outcomes

- **Sealed-source citation verification** — every load-bearing launcher citation re-derived from
  `git show 5325e95:tools/run-v07-genomic-recovery-v3.sh`. Spot-checked independently in this
  close-out: `:543` (`if (length(paths) < 16L) stop("fewer than 16 completed smoke attempts")`),
  `:556-557`, `:571`, `:575`, `:576-578`, `:633` (`${smoke_rows[@]:0:16}`), `:449`, `:78-81`,
  `:613-621`. **All match exactly.**
- **hsquared test-file citations** — `tests/testthat/test-v07-genomic-recovery-v3-launcher.R` at
  seal: `:307` is the named `test_that` block, `:335` its close, `:320-324` the
  "exactly 16" `expect_match`. The claim "all 7 assertions in 308-334 are `expect_match`" verified:
  `grep -c` returns **7**. File is 346 lines; all citations in range.
- **NEW — full intra-repo cross-reference sweep** (written and run in this close-out; **this check
  had not previously been run**): every `path:NN` citation across all four artifacts resolved
  against the target file's actual length. **Found 3 stale references; corrected; re-ran; 12/12 now
  resolve in-range.** See "Tests of the tests".
- **Claim ceiling concurrence** — `docs/design/capability-status.md:17,55-57,66` and
  `docs/dev-log/handover/2026-07-20-d1-reseal4-postdraw-retirement.md:26` concur:
  `public_covered_count=5`, `ordinary_auto_genomic` held, V2-GRM/V2-GINV partial.
- **Not run, and why:** `Pkg.test()` / `docs/make.jl` — this slice changes no `src/` and no docs
  build input; it is documentation only.

## Public claim audit

- `public_covered_count` = **5**, unchanged. `ordinary_auto_genomic` held. V2-GRM/V2-GINV partial.
  D1 paused and unadjudicated. **No route, count, or capability moves.**
- Every artifact carries an explicit non-authorization fence; the TSV's fence is embedded in the
  file itself because a TSV is read in isolation and the fence must travel with it.
- **Adversarial read for authorization-shaped wording — the specific risk this close-out existed to
  catch: a document set that reads as clearing a successor campaign when it clears one precondition
  of six.** One instance found and corrected: P4 §0 read "**an implementer may proceed to write the
  C1–C4 coverage ONLY IF it can be met as stated**". In isolation that is a conditional grant. It
  was fenced four lines later and contradicted by §4's NO-GO, but the sentence was rewritten to name
  the decision as belonging to a future authorized slice rather than granted here.
- P4 §4 explicitly **declines** to claim a second precondition: test-and-acceptance-criteria design
  for a contract fix is part of investigating that contract, not a separate deliverable. That
  self-denial is the correct instinct and is preserved verbatim.

## Tests of the tests

- **The P6 mechanical verifier returned six PASS results. Its conclusion was CORRECT but
  UNEVIDENCED.** Its citation check reported finding 73 citations, printed evidence for **3**, and
  asserted "0 mismatches" for the remaining 70. The distinction matters and is recorded precisely:
  the verifier was **not wrong — it was unevidenced.** A PASS whose evidence covers 3/73 of its own
  scope is an assertion, not a verification.
- **Deterministic re-check.** The orchestrator re-ran it: 46 distinct cited line numbers, 0 out of
  range, all load-bearing ones semantically matching sealed source; evidence artifact at
  `scratchpad/citation-evidence.txt`.
- **This close-out found that re-check's scope was narrower than "citation check" implies.**
  `citation-evidence.txt` contains **zero** intra-artifact cross-references — `grep -c
  "arity-contract"` returns **0**. It verified citations into the **sealed launcher** only. The
  artifacts also cite **each other**, and those were never checked. Writing that sweep found **3
  stale references**, all caused by the P5 fixes themselves:
  - P4 cited the three `SPECIFIED` rows as "TSV lines 16, 19, 21" → Rose's scope fence inserted 9
    header lines, shifting them to **25, 28, 30**. The stale numbers pointed at the fence prose.
  - P4 cited P3 `:195-211` for "Why derived beats literal" → actually **`:231-247`** after Gauss's
    inserted blocks.
  - P4 cited P3 `:250-259` for the `guard-selftest` precedent → actually **`:305-314`**.
  The fixes were correct; **the fixes broke the citations to themselves, and the verification's
  scope could not see it.**
- **The mutation-kill criterion (C3) is itself defended against degenerate fixtures** — Fisher
  required `missing` not be an exact multiple of `workers`, since at `missing=8, workers=4` both
  `-1` and `-2` yield `2` and the mutation is invisible. A mutation test that cannot fail is the
  same defect one level up.

## Coordination notes

- **`hsquared` untouched by design.** Every claim about the launcher derives from
  `git show 5325e95:<path>`.
- **The R twin must mirror before any implementation.** The contract described is a change to an
  **R-repo** file. This lane may specify it; it may not implement it. A successor slice requires the
  R lane to mirror the contract first, per the standing twin-boundary rule.
- **Version-control mandate carried forward:** any successor controller must be committed in-repo
  **before use**. `d1_reseal4_campaign.sh` — the sole controller that actually ran D1 and died — is
  in neither repository nor either history. The artifact that failed cannot be inspected, only
  reconstructed from its terminal log line.
- **Controller provenance remains an open, deliberately uninvestigated contradiction** per owner
  directive. `SMOKE_N_LADDER_RECOMMEND_WORKERS_CARDINALITY_MISMATCH` does **not** depend on the
  disputed controller citation — it is provable from the sealed launcher plus the known manifest.

## What did not go smoothly

**This session produced SEVEN instances of one defect class: a check that looks complete but is
not. Four were the orchestrator's own.** Recorded in full because the tally is the finding — the
slice was *about* this defect class and kept reproducing it:

1. The original `smoke-n-ladder` bug — a producer and a consumer each holding an independent
   literal. The defect under study.
2. A test block **named for exactly this contract** that only grepped error strings. It would have
   stayed green under the precise defect it was named for.
3. **(orchestrator)** Truncated a `grep` with `head -5` and nearly overwrote two agents' correct
   citations with the truncated result.
4. **(orchestrator)** Wrote a brain note without specifying `project`, creating an orphan in the
   wrong repo.
5. **(orchestrator)** The skeleton offered as *the exemplar of executing coverage* had a fixture
   with 4 data rows and `expected=3`. **It would have failed on correct code, and was never
   dry-run.** Deliberately **retained in the artifact as a worked example** rather than silently
   corrected — the cure reproducing the disease is the most instructive artifact in the set.
6. **(orchestrator)** The P6 verifier's unevidenced PASS (above).
7. **(this close-out)** The three stale cross-references — introduced **by the P5 fixes** and
   invisible to a verification scoped to sealed-source citations only.

The pattern across all seven: **a check whose scope is narrower than its name.** Instances 3, 5, 6,
and 7 were each found by a *later, differently-scoped* reader — never by the check itself.

## Known limitations

- **The predeclaration fixes ONE of the TWO sites needing the identical derived-cardinality fix.**
  `smoke-16`'s `${smoke_rows[@]:0:16}` (`:633`) and its `(( count >= 16 ))` guard (`:78-81`) never
  call `recommend_workers` — disjoint paths. Fixing `:543` has **zero** effect there. A manifest with
  a different rung count would reproduce the D1 disease inside `smoke-16`, unguarded.
- **The RSS order-statistic risk is unquantified** and **must be quantified before the 16-row layout
  is adopted** — the count-guard fix may relocate the failure to the resource guard.
- **The undeclared attempts corpus stays fully open** until C5 ships.
- **The `smoke-16` message-wording bug can ship forever** — C4 only forbids the old block from
  certifying it as correct.
- **Cross-mode sequencing is untouched by construction** — nothing in C1–C5 exercises a
  multi-invocation sequence, which is the actual empirical shape of the D1 failure.
- **`--print-plan` remains unresolved** (Option A / Option B both stated, neither chosen) — so a
  future campaign can still discover a cardinality mismatch only *after* spending seeds.
- **`--mode=verify-phase` counting logic is unswept** — it runs after every official draw mode and
  was not reviewed.
- **The 4× smoke cost is unestimated.**
- **The success path is untestable off-cluster** — `recommend_workers`'s worker arithmetic sits
  behind Linux-only `/proc/meminfo` with **no injection point**, verifiable only by a live run.
- **C2's macOS portability is fragile, not permanent** — it depends on the coverage guard firing
  before the `/proc/meminfo` read. Now pinned as a named invariant.

**What this slice does NOT do:** it does not implement anything, modify `hsquared`, draw or allocate
any seed, contact any remote, unpause D1, satisfy any precondition beyond "launcher contract
investigation", move `public_covered_count` off 5, activate `ordinary_auto_genomic`, or change
V2-GRM/V2-GINV.

## Next actions

None authorized. D1 remains PAUSED pending a separately authorized, pre-registered successor plan.

Should a successor ever be authorized, the five open preconditions must be satisfied
**independently**: a new root; a disjoint allocation; a new pre-registration; fresh mutation
controls/reviews/preseal; and explicit authorization. Additionally, before implementation: the R
twin must mirror the contract; the RSS order-statistic risk must be quantified; `--attempts` must be
dropped or made to `die` on mismatch; and the `--print-plan` compute-context question must be
decided with its own Gauss/Karpinski + Rose review.
