# Recovery-v3 launcher arity contract — design specification

**Status:** design specification for future implementation review only. Written
against the producer/consumer arity sweep in
`docs/design/50-recovery-v3-arity-contract.tsv` (P1) and the sealed source
`hsquared@5325e95` (`tools/run-v07-genomic-recovery-v3.sh`, read via
`git show 5325e95:<path>`; the hsquared working tree was not checked out or
modified while writing this document). This document authorizes no campaign,
no code change, and no re-run of D1. It satisfies exactly one of six
preconditions the handover names for any successor: **launcher contract
investigation**. The other five — a new root, a disjoint allocation, a new
pre-registration, fresh mutation controls/reviews/preseal, and explicit
authorization — remain open
(`docs/dev-log/handover/2026-07-20-d1-reseal4-postdraw-retirement.md:27-28`).

**Depends on:** `docs/design/50-recovery-v3-arity-contract.tsv` (P1, the
row-by-row producer/consumer sweep this document argues from) and the D1
reseal4 post-draw terminal retirement
(`docs/dev-log/handover/2026-07-20-d1-reseal4-postdraw-retirement.md`,
`docs/dev-log/check-log.d/2026-07-20-v07-d1-reseal4-postdraw-smoke-retirement.md`).
D1 remains paused per `ROADMAP.md`; nothing here reopens it.

## What this is / what it is not

This is a specification of a contract change for a **future** implementation
slice: how producer and consumer functions inside
`tools/run-v07-genomic-recovery-v3.sh` should agree on row counts, and how a
controller should be able to check that agreement before spending an official
seed. It is not:

- a patch to the sealed script (the hsquared working tree was not touched);
- authorization to re-run D1, D0F, or any smoke/official draw;
- a claim that any capability, route, or count moves — the claim ceiling at
  the end of this document is unchanged from before this document existed;
- a resolution of the `--print-plan` compute-context question below — both
  options are presented, neither is chosen.

## Three findings

### Finding 1 — the fix is a generalization, not an invention

The TSV marks three rows `SPECIFIED` and four rows `UNSPECIFIED`/`MISMATCH`/
`MESSAGE-MISMATCH`. The difference is not that the specified rows use some
mechanism absent from the broken rows — it is that in every specified row, the
**consumer re-derives its expected row count from an artifact the producer
itself wrote**, rather than asserting an independent literal:

- **`run-official` / `manifest_pairs`.** `manifest_pairs()`
  (`tools/run-v07-genomic-recovery-v3.sh:345-360`) emits one `group seed` pair
  per manifest row by reading the manifest's own `design_id`/`cell_id` and
  `seed` columns via `awk`. `run_official_pairs()`
  (`tools/run-v07-genomic-recovery-v3.sh:397-407`) consumes that stream
  directly through `xargs -r -P "$workers" -n 2` — the row count `run-official`
  acts on **is** `nrow(manifest)` by direct pipe, not a separately asserted
  number. The `run-official` case body wires this at
  `tools/run-v07-genomic-recovery-v3.sh:644-654`.
- **The base-R batch-plan regime.** `prepare_base_r_batch_plan()`
  (`tools/run-v07-genomic-recovery-v3.sh:441-462`) writes a plan file with a
  `batch_id` column, sized from `missing` and `workers`
  (`batch_size=$(( (missing + workers - 1) / workers ))`,
  `tools/run-v07-genomic-recovery-v3.sh:449`). `run_base_r_batches()`
  (`tools/run-v07-genomic-recovery-v3.sh:464-481`) does not re-assert `missing`
  or `workers` — it re-derives the batch count with
  `awk … !seen[$batch_col]++ { print $batch_col }` directly over the plan file
  it was just handed (`tools/run-v07-genomic-recovery-v3.sh:469-475`).
- **The Julia batch-dir regime.** `prepare_julia_batch_dir()`
  (`tools/run-v07-genomic-recovery-v3.sh:501-514`) invokes Julia's
  `write-batch-manifests` mode once to populate a directory.
  `validate_julia_batch_inventory()`
  (`tools/run-v07-genomic-recovery-v3.sh:483-499`) re-derives the expected
  count with `find "$dir" … -name "$stage-batch-*-of-*.tsv" | wc -l` and checks
  `entries == 2 * count` — reading the batch files actually on disk, not the
  `--batch-count=workers` argument that asked Julia to write them.

This is the same declaration pattern in all three cases: **count what was
produced, don't assert what was expected.** The four `UNSPECIFIED`/
`MISMATCH` rows all share the opposite pattern: `recommend_workers()`
(`tools/run-v07-genomic-recovery-v3.sh:533-581`) hard-codes
`if (length(paths) < 16L) stop(...)`
(`tools/run-v07-genomic-recovery-v3.sh:543`) against a `list.files()` glob over
`$out/attempts/$stage` (`tools/run-v07-genomic-recovery-v3.sh:538-542`) —
an independent literal compared to a count nothing in the same invocation
produced. `smoke-16`'s die message
(`"smoke-16 requires exactly 16 previously missing rows"`,
`tools/run-v07-genomic-recovery-v3.sh:78-81`) is the same pattern in reverse: an
independent literal (`16`) embedded in prose, checked against a predicate
(`>= 16`) that does not actually mean "exactly," and then followed by an
uncontested hardcoded slice `${smoke_rows[@]:0:16}`
(`tools/run-v07-genomic-recovery-v3.sh:633`).

The central argument of this specification is therefore not "add a new
mechanism." It is: **the launcher already contains the correct pattern in
three places; generalize it to the two places (`recommend_workers`, and the
`smoke-16` literal-16 collision) where it is absent.**

### Finding 2 — the broken contract is cross-mode

`recommend_workers()` is never called from the `smoke-n-ladder` case body
(`tools/run-v07-genomic-recovery-v3.sh:613-621`) — that body calls
`require_workers`, `require_preseal_worker_cap`,
`validate_d0f_predecessor_once`, `manifest_n_ladder | run_official_pairs`, and
the driver's `verify-phase` mode, and nothing else. `recommend_workers` is
invoked only from four *other* modes: `run-official`
(`tools/run-v07-genomic-recovery-v3.sh:649`), `recompute-base-r`
(`tools/run-v07-genomic-recovery-v3.sh:663`), `replay-julia`
(`tools/run-v07-genomic-recovery-v3.sh:680`), and the standalone
`recommend-workers` mode (`tools/run-v07-genomic-recovery-v3.sh:642`). The
TSV's `guard_firing_order` for the `smoke-n-ladder` row records the boundary
explicitly: `… 6:verify-phase [cross-mode boundary]
7:recommend_workers-count-gate(>=16)`.

The consequence is structural, not incidental. `manifest_n_ladder`
(`tools/run-v07-genomic-recovery-v3.sh:362-378`) emits exactly
`|unique(manifest$n)|` rows — four, for the D0F/D1 cell design — and that
count is only ever checked against `recommend_workers`'s literal `16` in a
**later, separate process invocation**, after `smoke-n-ladder` has already
exited. No single mode, and therefore no single-mode test of this script, ever
exercises both sides of the mismatch in one run. The knowledge that these
modes must be invoked in this sequence — smoke first, then an official mode
that gates on `recommend_workers` — lived entirely in the campaign controller.
That controller, `d1_reseal4_campaign.sh`
(named at `docs/dev-log/check-log.d/2026-07-20-v07-d1-reseal4-postdraw-smoke-retirement.md:9`),
does not exist in the `hsquared` or `HSquared.jl` working trees or in either
repository's git history (`git log --all` over both repos for the filename
returns nothing). Cross-mode sequencing is currently unrepresented anywhere in
version control. That is the structural reason a four-line change in one
mode's output was invisible until an official campaign burned four seeds to
discover it three modes later.

### Finding 3 — the deepest defect is an undeclared corpus

All four `UNSPECIFIED` rows in the TSV — `run-official`'s `recommend_workers`
gate, `recompute-base-r`'s, `replay-julia`'s, and the standalone
`recommend-workers` mode — share one root cause, not four different ones.
`recommend_workers()`'s row count
(`tools/run-v07-genomic-recovery-v3.sh:538-542`) is
`list.files(file.path(root, "attempts", stage), pattern = "[.]tsv$", recursive
= TRUE, …)`: every `.tsv` file (excluding `.sha256` sidecars) already sitting
on disk under `$out/attempts/$stage`, from **whatever wrote them**. Nothing in
`run-official`, `recompute-base-r`, `replay-julia`, or `recommend-workers`
itself writes those files before calling `recommend_workers` — in
`run-official`, for instance, `recommended=$(recommend_workers)` at
`tools/run-v07-genomic-recovery-v3.sh:649` runs strictly before
`manifest_pairs | run_official_pairs` at
`tools/run-v07-genomic-recovery-v3.sh:652`, so the attempts `recommend_workers`
counts must already exist from a prior, different invocation (in practice,
`smoke-n-ladder` or `smoke-16`).

The smoke attempt corpus under `$out/attempts/$stage/**/*.tsv` is therefore
**external state with no declared producer**: four consumer modes read it,
none of them declares having written it, and none of them names which earlier
invocation was supposed to. "4 != 16" is where this surfaced — the D1
campaign's cell design happened to produce four distinct `n` values against a
consumer that wanted sixteen files — but the undeclared corpus is what it
actually *is*. A cell design that happened to produce sixteen distinct-`n`
rows would have passed the count gate by coincidence, with the same undeclared
producer/consumer relationship still in place.

**A second, distinct integrity gap in the same glob.** `recommend_workers()`'s
`list.files(..., pattern = "[.]tsv$", recursive = TRUE)`
(`tools/run-v07-genomic-recovery-v3.sh:538-542`) trusts every `.tsv` it finds under
`attempts/$stage` **without requiring a verified `.sha256` sidecar** — unlike
`resumable_pair_state()` (`:83-95`), used elsewhere in the same script, which requires
both-present-or-both-absent and dies otherwise. A partially-written or corrupted smoke attempt
can therefore silently feed both `max(rss)` (`:559`) and the `n`-coverage check (`:556`). This
is separate from the undeclared-producer defect above and is not addressed by declaring the
corpus alone.

Fixing the literal without
fixing the missing declaration would leave the same class of defect available
under a different manifest shape.

## Proposed contract

> **Unauthorized specification, not implemented behaviour.** Everything in this section
> describes what the launcher *should* do under a future, separately authorized
> implementation slice. None of it is present at `hsquared@5325e95`, none of it has been
> written, and this document authorizes no code change, no campaign, and no D1 re-run.
> Read every "should", "becomes", and "define" below as proposal, never as description.

### (i) Argument naming: `--workers=N` and `--attempts=N`, always named

Every mode's positional `WORKERS` argument
(`smoke-n-ladder`/`smoke-16` optional at
`tools/run-v07-genomic-recovery-v3.sh:614-615,623-624`; `run-official`/
`recompute-base-r`/`replay-julia` required at
`tools/run-v07-genomic-recovery-v3.sh:644-648,659-664,676-681`) should become
`--workers=N`: parallelism only, never a row count, matching what it already
means everywhere it appears. Separately, a new `--attempts=N` argument should
be introduced for modes that need an explicit attempt-row count.

> **Open gap — `--attempts=N` is proposed with no validation, and that reintroduces this
> document's own anti-pattern one layer up.** No `require_attempts` analogue to
> `require_workers` is specified, and nothing states whether a caller-supplied `--attempts`
> must equal, may exceed, or is ignored in favour of the manifest-derived
> `attempts_per_rung × |unique(manifest$n)|` of section (ii). A free-standing `--attempts`
> that can disagree with the derived value is a CLI literal contradicting a derived
> constant — structurally the same defect as the hardcoded `16L` this document exists to
> remove. Before implementation, `--attempts` must either be dropped in modes where the row
> count is manifest-derived, or `die` on mismatch against the derived value.

This is new surface, not a rename of existing behavior. **No mode in the
sealed script accepts an attempt count as an argument at all.**
`smoke-16`'s `16` is a hardcoded slice,
`${smoke_rows[@]:0:16}` (`tools/run-v07-genomic-recovery-v3.sh:633`), fixed in
the script body regardless of what is passed on the command line; the mode
takes an optional `[WORKERS]` and nothing else
(`tools/run-v07-genomic-recovery-v3.sh:622-624`). `smoke-n-ladder` similarly
takes only `[WORKERS]`
(`tools/run-v07-genomic-recovery-v3.sh:613-621`). Introducing `--attempts=N`
means adding a parameter, not renaming one.

### (ii) Cardinality derived, not literal

> **`attempts_per_rung = 4` is a DECLARED OWNER DECISION (Shinichi, 2026-07-20) — NOT
> recovered intent.** The failed scripts establish no target: `smoke-n-ladder` never took an
> attempt count, and `smoke-16`'s `16` was a hardcoded slice `${smoke_rows[@]:0:16}`
> (`tools/run-v07-genomic-recovery-v3.sh:633`), not a contract. That `4 × 4 = 16` happens to
> reproduce the sealed script's existing `16L` is a consistency check, **not** evidence that
> anyone originally intended four attempts per rung. An implementer coding from this section
> must treat `4` as a choice that can be revisited by its owner, never as a derived constant.

Define `attempts_per_rung = 4` and `rows = attempts_per_rung *
|unique(manifest$n)|`, replacing the hardcoded `16L` at
`tools/run-v07-genomic-recovery-v3.sh:543`. `|unique(manifest$n)|` is already
computed once, correctly, by `manifest_n_ladder`
(`tools/run-v07-genomic-recovery-v3.sh:362-378`); `recommend_workers` should
read the same manifest the same way rather than embedding an unrelated
literal.

Why derived beats literal:

- **It survives a manifest with a different rung count.** The `16` is only
  correct because the D0F/D1 cell design happens to have four distinct `n`
  values and someone once intended four attempts per rung. Any change to the
  cell design's rung count silently breaks the literal without touching the
  code that would need to change. A derived expression tracks the manifest
  automatically.
- **It makes the rung-coverage guard automatic given the count guard.** The
  count guard at `tools/run-v07-genomic-recovery-v3.sh:543` fires before the
  rung-coverage guard at `tools/run-v07-genomic-recovery-v3.sh:556`
  (`if (!setequal(observed_n, unique(as.integer(manifest$n)))) stop(...)`),
  in that order. If the count guard is `length(paths) == attempts_per_rung *
  |unique(manifest$n)|` rather than an unrelated `>= 16`, then passing it
  already constrains the attempt set to be attempts-per-rung-many files per
  rung — the rung-coverage check becomes a corroborating assertion on the same
  derived quantity rather than an independent, coincidentally-related check.

> **RESOLVED 2026-07-20 — MEASURED, SAFE-AS-IS.** A 48-fit Totoro characterization
> (`docs/dev-log/recovery-checkpoints/2026-07-21-smoke-rss-order-statistic-characterization-predeclaration.md`,
> RESULT) confirms the order-statistic inflation is real but small: top-rung peak RSS is 783 MB
> (sd 11), the 4-vs-1 inflation is ~12 MB (1.5%), and on Totoro the RSS-derived worker count (~365)
> stays ~4× below the 96 cap — RSS is not the binding term. `attempts_per_rung = 4` stands. Bounded-
> memory caveat: RSS only binds below ~106 GB available, and the `workers<1` floor only below ~1.1 GB.
> The original (pre-measurement) risk statement is retained below for the record.

> **ORIGINAL OPEN-RISK STATEMENT (now discharged by the measurement above). The 16-row layout may trade the count guard
> for the RSS floor guard.** `recommend_workers()`'s `max(rss)`
> (`tools/run-v07-genomic-recovery-v3.sh:559,575`) is a maximum over *every* attempt
> counted, not a per-`n` maximum. RSS at fixed `n` is a random variable (allocator jitter,
> GC timing, co-resident load on a shared Totoro node), so by order statistics the maximum
> of 4 independent draws at `n=1200` is weakly stochastically **greater** than the maximum
> of 1 draw. Moving from one attempt per rung to four therefore is expected to **raise**
> observed `max(rss)`, which **lowers** `workers <- min(96L, preseal_cap, floor(0.7 *
> available_mb / max(rss)))` (`:575`), which **increases** exposure to the floor stop
> `"smoke RSS cannot support one admitted worker"` (`:576-578`). This has not been
> quantified against real Totoro/DRAC RSS variance and **must be before the 16-row layout
> is adopted** — otherwise the fix for the count guard may simply relocate the failure to
> the resource guard.

> **Unquantified cost.** This document does not estimate the wall-clock or memory cost of
> moving from a 4-attempt to a 16-attempt smoke corpus on Totoro/DRAC, nor whether it
> materially extends an already multi-hour campaign. A 4× increase in smoke fits should be
> estimated from D0F/D1's existing per-attempt logs before the layout is adopted.

### (iii) A declared producer for the attempts corpus

Whichever mode is responsible for populating
`$out/attempts/$stage/**/*.tsv` — today, `smoke-n-ladder` and `smoke-16` both
write into it via `run_official_pairs`
(`tools/run-v07-genomic-recovery-v3.sh:397-407`), called from
`tools/run-v07-genomic-recovery-v3.sh:619,633` — should record what it wrote:
group/seed pairs, count, and stage, in a form a later mode can read as a
declaration. Consumers (`recommend_workers`, and by extension `run-official`,
`recompute-base-r`, `replay-julia`) should read that declaration instead of
re-globbing `$out/attempts/$stage` from scratch. This closes Finding 3
directly: the corpus stops being anonymous external state and becomes an
artifact with a named producer, in the same spirit as the plan file
(`base-r-$stage.tsv`, `tools/run-v07-genomic-recovery-v3.sh:446`) and the batch
directory (`julia-$stage`, `tools/run-v07-genomic-recovery-v3.sh:505`) already
are for their respective regimes.

## `--print-plan` proposal (PROPOSAL — never run, never implemented)

Every mode, given a manifest, would emit its planned `(group, seed)` rows and
a count to stdout, executing nothing and drawing no seed, so a controller
could assert `plan_rows == expected` **before** any official draw — the check
that, had it existed, would have caught the D1 mismatch before four official
seeds were spent rather than after.

**Honest obstacle:** `assert_compute_context`
(`tools/run-v07-genomic-recovery-v3.sh:123-130`) is called unconditionally at
`tools/run-v07-genomic-recovery-v3.sh:325`, after argument parsing
(`tools/run-v07-genomic-recovery-v3.sh:289-294`) but **before** the mode
dispatch `case "$mode" in` begins at `tools/run-v07-genomic-recovery-v3.sh:583`.
Every mode reachable through that path — including read-only modes like
`recommend-workers` (`tools/run-v07-genomic-recovery-v3.sh:640-643`) — is
gated on running on Totoro or an admitted DRAC allocation
(`compute_context_ok`, `tools/run-v07-genomic-recovery-v3.sh:107-121`) before
it can do anything, even print a number. A plan-only path faces two options,
neither of which this document resolves:

- **Option A — hoist `--print-plan` above line 325**, following the precedent
  already set by `guard-selftest`
  (`tools/run-v07-genomic-recovery-v3.sh:159-212`) and `selftest`
  (`tools/run-v07-genomic-recovery-v3.sh:214-226`), both of which are
  dispatched before `assert_compute_context` and never reach it. This lets a
  controller check `plan_rows == expected` from any host, including a laptop
  or CI runner, with no compute-context restriction. Trade-off: a read-only
  planning path would exist that can run somewhere an official draw never
  could, which changes what "every path that touches `$out`" currently
  guarantees uniformly.
- **Option B — leave `--print-plan` inside the general dispatch**, inheriting
  the same Totoro/DRAC requirement as every other mode. This preserves the
  invariant that nothing touching recovery-v3 artifacts runs off admitted
  compute, but means a controller cannot cheaply pre-validate a plan without
  first provisioning the same compute an official draw would need — narrowing,
  though not eliminating, the value of checking before spending a seed.

This document takes no position between the two. Whichever is chosen, it
needs its own review (Gauss/Karpinski for the guard interaction; Rose before
any public-facing change) before implementation, which is out of scope here.

## Version-control mandate

Any successor controller — the script that sequences `prepare` → `preseal` →
`preflight` → `smoke-n-ladder`/`smoke-16` → `run-official` →
`recompute-base-r` → `replay-julia` → … → `validate-final` across process
invocations — must be committed in-repo before use, in either `hsquared` or
`HSquared.jl` as appropriate.

Empirical rationale: `d1_reseal4_campaign.sh`, the sole Totoro controller that
actually ran D1 and died `RC=21`
(named at `docs/dev-log/check-log.d/2026-07-20-v07-d1-reseal4-postdraw-smoke-retirement.md:9`;
its done-marker `d1_reseal4_campaign.DONE` is separately named at
`docs/dev-log/after-task/2026-07-20-v07-d1-reseal4-postdraw-smoke-retirement.md:25`
and its `RC=21` at `docs/dev-log/handover/2026-07-20-d1-reseal4-postdraw-retirement.md:5-6`),
exists in neither the `hsquared` nor `HSquared.jl` working tree, nor anywhere
in either repository's git history — `git log --all` against the filename
returns nothing in both repos. The artifact that actually sequenced the modes
and actually failed cannot be inspected, only reconstructed from its terminal
log line and this TSV's reverse-engineering of the launcher it drove. Finding
2's structural claim — that cross-mode sequencing is unrepresented in version
control — is not a hypothetical risk; it is why this specification cannot cite
the controller directly and had to derive its behavior from the launcher it
called.

## Known unswept surface

- **`--mode=verify-phase` counting logic** lives in
  `tools/v07_genomic_recovery_v3.R`, dispatched to `v3d_verify_phase()`
  (defined at `tools/v07_genomic_recovery_v3.R:1321`, dispatched at
  `tools/v07_genomic_recovery_v3.R:1439-1440`). It runs after every official
  draw mode (`smoke-n-ladder:620`, `smoke-16:634`, `run-official:653`) but was
  **not reviewed** for this specification — its own counting/arity behavior is
  unswept and would need a separate pass before any implementation touches it.
- **Two dead functions are reported, not removed.** `run_base_r_pairs`
  (`tools/run-v07-genomic-recovery-v3.sh:409-416`) and `run_julia_pairs`
  (`tools/run-v07-genomic-recovery-v3.sh:418-430`) are defined but never
  called from any `case` arm — `recompute-base-r`
  (`tools/run-v07-genomic-recovery-v3.sh:659-670`) uses the batch-plan regime
  instead, and `replay-julia`
  (`tools/run-v07-genomic-recovery-v3.sh:676-687`) uses the batch-dir regime
  instead. Removal is not this slice's authority; it is named here so a
  future implementation slice does not rediscover it from scratch.

## Claim ceiling

`public_covered_count=5`; `ordinary_auto_genomic` held; V2-GRM/V2-GINV
partial; D1 paused and unadjudicated. No route, count, or capability moves.
This document is a specification for review, not evidence, and changes none
of the above.
