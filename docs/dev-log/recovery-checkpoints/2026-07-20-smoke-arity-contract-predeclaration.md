# Pre-declaration — recovery-v3 smoke/consumer arity contract test coverage

**Date:** 2026-07-20 · **Lane:** Julia engine (`HSquared.jl`), reviewing R-side sealed source
(`hsquared@5325e95`) · **Author:** Curie (validation/testing lens), solo, planning-only.
**Predecessor:** `docs/design/50-recovery-v3-arity-contract.tsv` (P1, the row-by-row
producer/consumer sweep) and `docs/design/50-recovery-v3-arity-contract.md` (P3, the proposed
contract: named arguments, derived cardinality, a declared corpus producer). This document is
slice P4: the acceptance criteria and test skeleton a future implementation slice must satisfy.
It is a **contract predeclaration**, not an experiment predeclaration — section 1 fixes contract
semantics rather than a data-generating process; section 3 is a code skeleton rather than a
preliminary result.

## 0. What this is

A falsification-shaped test design for the fix P3 specified: replace `recommend_workers()`'s
hardcoded `if (length(paths) < 16L) stop(...)` (`tools/run-v07-genomic-recovery-v3.sh:543`,
`hsquared@5325e95`) with a cardinality **derived** from the manifest, and add executing test
coverage for every `SPECIFIED` row in the P1 TSV. The question this document informs — **for a
future, separately authorized implementation slice, and decided there, not granted here** — is
whether the C1–C6 coverage below can be met as stated; if any criterion cannot be met without
spawning a real fit, reading `/proc/meminfo` on a non-Linux machine, or reproducing the disease
pattern named in Finding 1 of P3, **that is reported as a blocker, not silently narrowed.**

This is not:

- authorization to implement, run, or commit the coverage below to `hsquared`;
- authorization to re-run D1, draw a seed, or touch the retired root
  `/home/snakagaw/hsq_work/d1-reseal4` or seed space `2028000000/101:148` (never read, never
  referenced beyond this sentence);
- a claim that any route, count, or capability moves. The claim ceiling in §4 is unchanged from
  before this document existed.

All source claims below were re-verified directly against `hsquared@5325e95` via
`git show 5325e95:<path>` in this session (not merely copied from the TSV or from P3's prose);
line numbers are exact as of that re-check.

## 1. Frozen contract semantics (the arity fix under test)

- **`attempts_per_rung = 4` is fixed here, today, 2026-07-20, as a declared decision — not as
  intent recovered from the retired D1 controller or the failed campaign.** The controller that
  actually ran D1 (`d1_reseal4_campaign.sh`) is not committed to `hsquared` or `HSquared.jl` and
  does not exist in either repository's `git log --all`
  (`docs/design/50-recovery-v3-arity-contract.md:120-128`); a same-day diagnosis checkpoint
  further records an unresolved contradiction about whether a controller comment was ever
  legitimately read at all
  (`docs/dev-log/recovery-checkpoints/2026-07-20-d1-smoke-contract-arity-diagnosis.md`,
  "Correction note (appended 2026-07-20)" section). Nothing in either repository can honestly
  establish what row count the failed campaign *intended*. `attempts_per_rung = 4` is chosen here
  because it reconstructs the D0F/D1 four-rung cell design's existing `16`
  (`4 rungs × 4 attempts = 16`, matching `recommend_workers`'s current literal), not because any
  source document recovers it as a prior target.
- **`rows = attempts_per_rung * |unique(manifest$n)|`** replaces the hardcoded `16L` at
  `tools/run-v07-genomic-recovery-v3.sh:543`. For the four-rung D1 manifest
  (`n ∈ {120, 300, 600, 1200}`) this evaluates to `4 * 4 = 16` — the same number the sealed script
  already hardcodes — but as a **derived expression over `manifest$n`**, never a literal, matching
  the pattern P3 identifies as already correct in the three `SPECIFIED` TSV rows
  (`docs/design/50-recovery-v3-arity-contract.md:40-94`, "Finding 1").
- **Why derived beats literal** (restated from P3 §(ii), `docs/design/50-recovery-v3-arity-contract.md:231-247`,
  verified against source):
  1. It survives a manifest with a different rung count. The `16` is only correct for the D0F/D1
     cell design's specific four rungs; a manifest with three or five distinct `n` values would
     silently desynchronize an independent literal without touching the code that needs to change.
     A derived expression tracks `manifest$n` automatically.
  2. It makes the rung-coverage guard automatic given the count guard. The count guard
     (`tools/run-v07-genomic-recovery-v3.sh:543`) fires strictly before the coverage guard
     (`tools/run-v07-genomic-recovery-v3.sh:555-558`,
     `if (!setequal(observed_n, unique(as.integer(manifest$n)))) stop(...)`). If the count guard
     reads `length(paths) == attempts_per_rung * |unique(manifest$n)|` rather than an unrelated
     `>= 16`, passing it already constrains the attempt set to be `attempts_per_rung`-many files per
     rung, so the coverage check becomes a corroborating assertion on the same derived quantity
     rather than an independent, coincidentally related check.
- This section fixes the semantics under test; it does not itself change
  `tools/run-v07-genomic-recovery-v3.sh`. No hsquared file was modified to produce this document.

## 2. Acceptance criteria C1–C6 (the implementation gate)

These criteria are pre-declared, falsifiable, and fixed now. **C5 was added by the P5 review
(Fisher) and is part of the gate, not an advisory addendum** — the gate is C1–C6, and a slice that
ships C1–C4 while leaving C5 open has not met it. Per the standing no-post-hoc-relaxation rule
(`docs/dev-log/decisions/2026-06-14-calibration-failure-response.md`): they may
not be softened, narrowed, or reinterpreted after an implementer sees whether their coverage
passes or fails against them. A slice that cannot meet C1–C6 as stated must report which criterion
failed and why — not quietly ship coverage that satisfies a weaker version of the same name.

**C1 — every `SPECIFIED` row gets an executing count-equality check, zero `expect_match` in the
new coverage.**
The P1 TSV marks exactly three rows `SPECIFIED`
(`docs/design/50-recovery-v3-arity-contract.tsv` lines 25, 28, 30 — `run-official`/`manifest_pairs`,
`recompute-base-r`/batch-plan, `replay-julia`/batch-dir). Each needs an executing assertion that
the producer's emitted row count equals its `emitted_rows_expr`:

  1. `manifest_pairs()` (`tools/run-v07-genomic-recovery-v3.sh:345-360`) emits exactly
     `nrow(manifest)` rows.
  2. The batch-id count `run_base_r_batches()` re-derives via `awk`
     (`tools/run-v07-genomic-recovery-v3.sh:469-475`) equals `ceil(missing / workers)`, the value
     `prepare_base_r_batch_plan()` used to size the plan
     (`tools/run-v07-genomic-recovery-v3.sh:449`).
  3. `validate_julia_batch_inventory()` (`tools/run-v07-genomic-recovery-v3.sh:483-499`) accepts a
     fixture directory with exactly `count` matching files and `2*count` total entries, and rejects
     one with either off.

None of these require `expect_match(launcher_text, ...)` against the script's source text — each
is a behavioral count comparison against a fabricated fixture. If the new coverage contains any
`expect_match` call whose only claim is "the string appears somewhere in the launcher," C1 is not
met, regardless of how many such calls exist.

**C2 — one negative case proving `recommend_workers`'s two guards are independently reachable.**
`recommend_workers()` (`tools/run-v07-genomic-recovery-v3.sh:533-581`) is the sole consumer with
two sequential validation guards in firing order: the count guard
(`tools/run-v07-genomic-recovery-v3.sh:543`, `if (length(paths) < 16L) stop("fewer than 16
completed smoke attempts", ...)`) fires before the coverage guard
(`tools/run-v07-genomic-recovery-v3.sh:555-558`, `if (!setequal(observed_n, unique(as.integer(
manifest$n)))) stop("smoke attempts do not cover every preregistered n", ...)`). A negative-control
fixture must supply `attempts_per_rung * |unique(manifest$n)|` attempt files (satisfying the count
guard) whose `n` values do **not** `setequal` the manifest's rungs (violating the coverage guard),
and the test must assert the failure message is the coverage guard's
(`"smoke attempts do not cover every preregistered n"`), not the count guard's (`"fewer than 16
completed smoke attempts"`). This is the only way to prove both guards are reachable in the same
invocation — under the sealed script's own D1 manifest (four rungs, literal `16`), the count guard
was never satisfiable at four rows, so the coverage guard was unreachable in practice; the fix must
make it reachable, and this test must prove it.

> **C3 STRENGTHENED after P5 review (Fisher, INSUFFICIENT verdict).** As first drafted, C3 was a
> manual, unshipped, one-time procedure with no evidence artifact, no named independent executor,
> and no constraint on fixture values — i.e. unauditable self-report, structurally the same
> unfalsifiable claim as the `expect_match` disease it exists to prevent. It is replaced by:
>
> **C3 — mutation-kill evidence: committed, reviewable, and not self-certified.** For each
> `emitted_rows_expr`, an implementer *or an independent reviewer* must (a) choose fixture values
> such that the mutation is **not masked by a degenerate boundary** — e.g. for
> `batch_size=$(( (missing + workers - 1) / workers ))` (`:449`), `missing` must NOT be an exact
> multiple of `workers`, since with `missing=8, workers=4` both `-1` and `-2` yield `2` and the
> mutation is invisible; (b) apply exactly one single-token mutation; (c) rerun and **commit a
> record** — check-log entry or PR text quoting the diff hunk and the resulting failure message —
> that the suite went red; (d) revert. **C3 is not met until that record exists in the repo, not
> when someone asserts it happened.**

**C3 (ORIGINAL WORDING, SUPERSEDED BY THE BLOCK ABOVE) — a single-token mutation of any `emitted_rows_expr` must turn
the suite red.**
Take each `emitted_rows_expr` this coverage encodes (`nrow(manifest)`, `ceil(missing/workers)`,
`attempts_per_rung * |unique(manifest$n)|`, `count`/`2*count`) and mutate exactly one token in the
implementation (e.g. change a `+` to `-`, an operand, an off-by-one bound). If the suite stays
green under any such mutation, the coverage is textual in effect and C1 is not met, regardless of
what it appears to test. **Why this criterion exists:** the original defect this whole contract
traces to is a test block *already named for exactly this purpose* —
`tests/testthat/test-v07-genomic-recovery-v3-launcher.R:307-335`
(`test_that("launcher requires both smoke denominator and n-ladder coverage", ...)`, re-verified at
`hsquared@5325e95`) — which asserts only that specific strings occur in the launcher's source text:
all 7 assertions in that block (lines 308-334) are `expect_match(launcher_text, "...", fixed =
TRUE)` calls, with no fixture, no invocation of any launcher function, and no comparison of an
emitted count to anything. That block would stay green under the exact defect this
contract fixes; a mutation to the guard's numeric literal does not change what string appears in the
file. C3 is the only criterion in this document that mechanically distinguishes coverage from the
*appearance* of coverage — it is not a stylistic preference, it is the specific failure mode being
guarded against.

> **C4 STRENGTHENED after P5 review (Fisher).** As drafted, C4 permitted **bare deletion**: an
> implementer could delete the diseased block and add only C1/C2's narrower coverage, leaving the
> worker-cap-exceeded paths and the `smoke-16` predicate/message pair with **zero** coverage —
> not even the wrong kind. Replaced by:
>
> **C4 — the diseased block is removed, AND every true behavioural claim it gestured at is
> replaced by an equivalent-or-stronger executing check.** The block's 7 assertions gesture at
> `recommend_workers`'s two guard messages, `manifest_missing_pairs` /
> `manifest_missing_recompute_pairs`, the `smoke-16` message, and two worker-cap-exceeded
> messages. **Bare deletion without replacement coverage for the worker-cap-exceeded paths and
> the `smoke-16` predicate/message pair does not satisfy C4.**

**C4 (ORIGINAL WORDING, SUPERSEDED BY THE BLOCK ABOVE) — the diseased block is deleted or rewritten behaviorally, not left beside new coverage.**
`tests/testthat/test-v07-genomic-recovery-v3-launcher.R:307-335` must be removed or rewritten to
assert behavior, not merely supplemented. Adding a new block beside it reproduces the disease
under a different name: the block currently pins a **wrong string as if it were correct behavior**.
`require_smoke_missing_count()` (`tools/run-v07-genomic-recovery-v3.sh:78-81`) tests
`(( count >= 16 ))` — an at-least predicate — but its `die` message reads `"smoke-16 requires
exactly 16 previously missing rows"` — worded as an exact-equality requirement the code does not
enforce. The test block asserts that exact (wrong) message string is present
(`tests/testthat/test-v07-genomic-recovery-v3-launcher.R:320-324`,
`expect_match(launcher_text, "smoke-16 requires exactly 16 previously missing rows", fixed =
TRUE)`), which certifies the misleading wording, not the predicate's actual behavior. Leaving this
block in place after adding behavioral coverage elsewhere would leave a passing test that continues
to certify a false statement about the code's own behavior.

**C5 (ADDED after P5 review, Fisher) — the attempts corpus gets a declared producer, tested.**
Whichever mode populates `$out/attempts/$stage/**/*.tsv` must write a manifest of what it wrote
(group/seed pairs, count, stage); consumers — `recommend_workers` and its callers — must read that
declaration rather than re-globbing the directory from scratch; and a test must assert that a
consumer invoked **without** a matching declaration **fails closed**. Until C5 exists, Finding 3
(the undeclared corpus, `docs/design/50-recovery-v3-arity-contract.md`) must be reported as an
**unaddressed blocker** in every downstream status document, never omitted.

**C2 addendum (P5, Fisher/Gauss) — pin the guard order as a named invariant.** C2's macOS
portability depends on the coverage guard (`:557`) firing before the Linux-only `/proc/meminfo`
read (`:571`). Nothing currently records that this ordering is load-bearing, so a future reorder
would surface as an unexplained macOS crash rather than a named regression. Implementation must add
a comment at `tools/run-v07-genomic-recovery-v3.sh:571` marking the order load-bearing and citing
this predeclaration, plus a matching note in the test.

### The composed seed-free regression test — DESIGNED HERE (C6), with the regression case constructible against sealed source today

The original goal named a **"composed seed-free regression test"** proving, pre-draw, that the
producer's emitted rows satisfy the consumer's `>=16` denominator **and** all-rung coverage. This is
that design. An earlier draft of this section overstated the obstacle as "impossible / deferred to
`--print-plan`"; that was the session's own narrower-than-its-name error, in reverse. The
regression-catching direction is constructible **now**, seed-free, on the macOS dev machine, because
the producer's cardinality stage is pure.

**Why the producer stage is seed-free.** `manifest_n_ladder`
(`tools/run-v07-genomic-recovery-v3.sh:362-378`) is `awk` over `$manifest`, emitting one
`(group, seed)` pair per first-seen distinct `n` (`!seen[$n_col]++`). It spawns no process, fits
nothing, draws no seed; its only non-builtin dependency is `die`
(`tools/run-v07-genomic-recovery-v3.sh:43-46`, a 3-line `echo`+`exit`). The fit-spawning is entirely
in the *separate* stage `run_official_pairs` (`:397-407`), which the composed regression test never
invokes. What is *not* separately invocable is the whole `smoke-n-ladder` **mode** (`:613-621`) —
the script has no `BASH_SOURCE`/`main` guard (`:1-6`), and the mode pipes producer→fits. The test
reaches the pure producer *function* around that, not through the mode.

**Guard reachability on macOS (verified at source).** `recommend_workers`'s guards fire in order:
count `<16L` (`:543`) → schema → rung-coverage `setequal` (`:556`) → RSS → preseal-cap →
`readLines("/proc/meminfo")` (`:571`, Linux-only). So a producer emitting **fewer** than the
required rows trips the count guard at `:543` and **returns before `:571`** — the regression case
runs to completion on macOS. A producer emitting the full 16 rows passes count+coverage and *then*
reaches `:571`, so the **positive-confirmation** case is Linux-gated (Totoro/DRAC), not a dev-machine
check. The direction that catches the D1 bug is the seed-free, locally-runnable one.

**C6 — composed producer→consumer regression check (a current-gate design; three constructions,
ranked).** The test feeds the *real* producer's emitted row set into the *real* consumer's
requirement and asserts rejection when the producer under-emits:

1. **Construction A — function extraction (constructible against sealed `5325e95` today, no launcher
   change).** `sed -n '/^manifest_n_ladder()/,/^}/p'` and `/^die()/,/^}/p'` out of the launcher,
   `source` only that fragment, set `manifest`/`stage`, invoke the real `manifest_n_ladder` against a
   4-rung fixture manifest → capture 4 emitted rows → assert `4 < 16` would trip
   `recommend_workers`'s count guard (`:543`), i.e. the consumer rejects pre-draw. Seed-free,
   macOS-runnable, zero fits. **Brittle** (extraction breaks if the function is re-edited) — record
   that limitation; it is the price of testing a non-sourceable script without changing it.
2. **Construction B — one-line source guard (cleanest; a 1-line launcher change).** Add
   `[[ "${BASH_SOURCE[0]}" == "${0}" ]] || return 0` before the top-level dispatch so the script is
   sourceable; then unit-invoke `manifest_n_ladder` directly and compose against the extracted
   count guard. Removes Construction A's brittleness. Requires the implementation slice.
3. **Construction C — via `--print-plan` (most capable; needs the P3 proposal).** `smoke-n-ladder
   --print-plan` emits the plan + count executing nothing; the composed check asserts the count
   equals `attempts_per_rung × |unique(manifest$n)|` and thereby satisfies both consumer conditions
   by construction. Also enables the **positive** case without `/proc/meminfo` if `--print-plan`
   exits before `recommend_workers`.

**C6 acceptance (fixed here, no post-hoc relaxation):** the regression case (Construction A, or B/C
if the implementation slice adopts them) must exist as an executing test that (a) invokes the real
producer stage seed-free, (b) asserts a 4-rung manifest's emitted count is rejected by the consumer's
count guard **pre-draw**, and (c) includes the mutation check of C3 on the producer's
`emitted_rows_expr`. The positive-confirmation case is explicitly **Linux-gated** and scheduled on
Totoro/DRAC, not required on the dev machine. C6 is a design deliverable of *this* slice; its
Construction-A form depends on nothing unimplemented.

### What an implementer can satisfy completely and STILL get wrong

Recorded verbatim from the P5 adversarial review (Fisher, verdict **INSUFFICIENT** on C1–C4 as
first drafted). This list is part of the gate: it must be carried forward, not dropped.

1. **`smoke-16`'s hardcoded slice is untouched.** `${smoke_rows[@]:0:16}` (`:633`) and its guard
   `(( count >= 16 ))` (`:78-81`) never call `recommend_workers` — disjoint code paths. Fixing the
   `:543` guard has **zero** effect there. P3's Finding 1 names **two** sites needing the identical
   derived-cardinality fix; §1 above fixes **one**. A manifest with a different rung count would
   reproduce the D1 disease inside `smoke-16`, unguarded. **This document quietly narrowed scope;
   the narrowing is now recorded rather than hidden.**
2. **The undeclared attempts corpus is fully open** until C5 ships — four consumer modes still trust
   anonymous external state.
3. **The `smoke-16` message-wording bug can ship forever.** `die "requires exactly 16"` at a `>= 16`
   predicate; C4 only forbids the old block from certifying it as correct.
4. **Cross-mode sequencing is untouched by construction.** `guard-selftest` is single-process;
   nothing in C1–C6 exercises a multi-invocation sequence, which is the actual empirical shape of
   the D1 failure.
5. **`--print-plan` remains unresolved** — even after this ships, there is still no pre-draw plan
   check, so a future campaign can still discover a cardinality mismatch only after spending seeds.
6. **The RSS order-statistic risk is unquantified** (Gauss) — 4 draws per rung raise expected
   `max(rss)`, lowering recommended workers and increasing exposure to the `workers < 1` floor stop.

## 3. Skeleton (SKELETON — never executed, not committed to hsquared by this slice)

The launcher already has a place for exactly this kind of fixture-based, cross-machine-portable
check: `guard-selftest` (`tools/run-v07-genomic-recovery-v3.sh:159-212`, dispatched **before**
`assert_compute_context` at line 325 — the same precedent P3 names for `--print-plan`,
`docs/design/50-recovery-v3-arity-contract.md:305-314` — so it already runs off Totoro/DRAC, on any
machine including a laptop). Its established negative-control idiom is
`( fn args ) >/dev/null 2>&1 && die "..."` (e.g. line 169-170,
`( require_smoke_missing_count 15 ) >/dev/null 2>&1 && die "smoke-16 count negative control
failed"`), and its established fixture idiom is exactly the `emit_missing_pair_if_needed` block
(lines 185-208): build a throwaway path under a `mktemp -d` root, call the real function against
it, assert on the outcome, clean up. The skeleton below extends that same idiom; an implementer's
job becomes "add lines matching the TSV rows in this shape," not "invent a fixture rig."

```bash
# --- appended within guard-selftest, before `echo "... PASS"; exit 0` (line 210) ---
# SKELETON ONLY. Illustrative shape; not executed by this predeclaration.

# C1.1 -- run-official / manifest_pairs: emitted rows == nrow(manifest)
fx_manifest="$pair_root/fixture_manifest.tsv"
printf 'cell_id\tseed\tn\n1\t100\t120\n1\t101\t120\n2\t200\t300\n2\t201\t300\n' > "$fx_manifest"
: > "$fx_manifest.sha256"
expected=4   # nrow(manifest) excluding header: the fixture above has FOUR data rows.
             # NOTE (Fisher, P5 review): this read `expected=3` as first drafted, which would
             # have failed on CORRECT code. The skeleton offered as the exemplar of executing
             # coverage was itself never dry-run -- the same defect class this predeclaration
             # exists to close, reproduced inside the cure. Corrected 2026-07-20 and retained
             # as a worked example: a fixture's expected value must be derived from the
             # fixture, and any skeleton shipped as a pattern must be executed before it is
             # offered as one.
observed=$(manifest="$fx_manifest" stage=d1 manifest_pairs | wc -l | tr -d ' ')
[[ "$observed" == "$expected" ]] || die "C1.1 manifest_pairs row-count mismatch"

# C1.2 -- recompute-base-r / batch-plan: unique(plan$batch_id) == ceil(missing/workers)
# (invokes prepare_base_r_batch_plan's plan-writing Rscript calls -- write-batch-plan /
# validate-batch-plan -- which write and check a TSV; these are NOT model fits and do not
# consume a seed. Does NOT invoke run_base_r_batches's dispatch half.)
fx_plan=$(prepare_base_r_batch_plan "$workers_fixture" "$missing_fixture")
derived=$(awk -F'\t' 'NR==1{for(i=1;i<=NF;i++) if($i=="batch_id") c=i; next}
                       !seen[$c]++{n++} END{print n}' "$fx_plan")
expected=$(( (missing_fixture + workers_fixture - 1) / workers_fixture ))
[[ "$derived" == "$expected" ]] || die "C1.2 batch-id count mismatch"

# C1.3 -- replay-julia / batch-dir: validate_julia_batch_inventory accepts count/2*count
fx_dir=$(mktemp -d "$pair_root/juliabatch.XXXXXX")
for i in 1 2 3; do
  : > "$fx_dir/d1-batch-$(printf '%03d' "$i")-of-003.tsv"
  : > "$fx_dir/d1-batch-$(printf '%03d' "$i")-of-003.tsv.sha256"
done
stage=d1 validate_julia_batch_inventory "$fx_dir" || die "C1.3 rejected a complete fixture"
rm "$fx_dir"/d1-batch-002-of-003.tsv.sha256
( stage=d1 validate_julia_batch_inventory "$fx_dir" ) >/dev/null 2>&1 && \
  die "C1.3 negative control: incomplete inventory was accepted"

# C2 -- recommend_workers: count-guard-passes/coverage-guard-fails is reachable and correctly
# ordered. Fixture uses 16 = attempts_per_rung(4) * |unique(manifest$n)|(4) attempt files, all
# reporting the SAME n -- satisfies the (fixed) count guard, violates setequal(observed_n, ...).
# Because R's stop() at the coverage guard fires before the /proc/meminfo read later in the same
# function, this fixture does not require a Linux host.
fx_attempts="$pair_root/attempts/d1/fixture_cell"
mkdir -p "$fx_attempts"
for i in $(seq 1 16); do
  printf 'n\tpeak_rss_mb\n120\t500\n' > "$fx_attempts/$i.tsv"
done
fx_manifest_4rung="$pair_root/d1_manifest.tsv"   # n in {120,300,600,1200}, per D1 cell design
printf 'cell_id\tseed\tn\n1\t1\t120\n2\t2\t300\n3\t3\t600\n4\t4\t1200\n' > "$fx_manifest_4rung"
err_out=$(out="$pair_root" stage=d1 recommend_workers 2>&1 >/dev/null)
[[ "$err_out" == *"smoke attempts do not cover every preregistered n"* ]] || \
  die "C2 negative control did not fail on the coverage guard"
[[ "$err_out" != *"fewer than 16 completed smoke attempts"* ]] || \
  die "C2 negative control incorrectly failed on the count guard"
```

**C3's mutation check is a procedure, not a permanent block:** after implementation, an
implementer or reviewer changes exactly one token in each derived expression under test (e.g.
`ceil(missing/workers)` to `floor(missing/workers)`, or `attempts_per_rung * |unique(manifest$n)|`
to `(attempts_per_rung + 1) * |unique(manifest$n)|`), reruns the suite, and confirms it goes red.
This is verification of the coverage itself, run once per mutation at review time — it is not code
that ships in `guard-selftest`.

**CRITICAL HONESTY NOTE — what this skeleton deliberately does NOT invoke, and why:**

- **`run_official_pairs()`** (`tools/run-v07-genomic-recovery-v3.sh:397-407`) is
  `xargs -r -P "$workers" -n 2 sh -c 'exec Rscript --vanilla "$V3_DRIVER" --mode=run-one ...'` —
  it spawns real fits and would consume real seeds if invoked against real group/seed pairs. No
  criterion above calls it. C1.1 tests `manifest_pairs()`'s emitted row count directly, capturing
  its stdout without piping it onward to `run_official_pairs`.
- **`recommend_workers()`** (`tools/run-v07-genomic-recovery-v3.sh:533-581`) reads
  `/proc/meminfo` at line 571 (verified: `memory <- readLines("/proc/meminfo", warn = FALSE)`),
  which does not exist on the macOS dev machine. C2's fixture is deliberately constructed so
  execution never reaches line 571: the coverage guard at lines 555-558 calls `stop()`
  unconditionally on a mismatched fixture, and R does not continue past a fired `stop()`. This is
  verified from the source's control flow (`stop()` calls in this heredoc are not wrapped in
  `tryCatch` — the guard sequence is strictly linear), not assumed. If a future implementer changes
  `recommend_workers`'s guard order such that anything reads `/proc/meminfo` before the coverage
  check, this fixture would stop being portable and C2 would need re-design; that dependency should
  be treated as fragile, not permanent.
- **`run_base_r_batches()`'s dispatch half** (`tools/run-v07-genomic-recovery-v3.sh:476-480`, the
  `| xargs ... exec Rscript --mode=recompute-batch`) and **`run_julia_batches()`**
  (`tools/run-v07-genomic-recovery-v3.sh:516-530`, `xargs -0 ... exec ... --mode=replay-batch`) are
  never invoked. C1.2 stops after obtaining the plan file from `prepare_base_r_batch_plan()` (whose
  own Rscript calls write/validate/authenticate a plan — not a fit); C1.3 fabricates the batch
  directory's end state directly rather than calling `prepare_julia_batch_dir()`'s real
  `write-batch-manifests` invocation, and calls only the pure-filesystem
  `validate_julia_batch_inventory()`.
- **Broader platform gap — the success path is untestable off-cluster.** None of C1–C6
  exercises `recommend_workers()`'s actual success-path arithmetic, `workers <- min(96L,
  preseal_cap, floor(0.7 * available_mb / max(rss)))`
  (`tools/run-v07-genomic-recovery-v3.sh:575`), because it sits behind the Linux-only
  `readLines("/proc/meminfo")` (`:571`) with **no injection point** — no env var or path
  override for `available_mb`. C2's negative control is macOS-portable only because it stops
  earlier, at the coverage guard (`:557`); that is a narrow exemption, not general coverage.
  The worker-recommendation arithmetic — including the RSS order-statistic risk recorded in
  `docs/design/50-recovery-v3-arity-contract.md` (4 draws per rung raise expected `max(rss)`,
  lowering recommended workers) — remains verifiable **only by a live run on Totoro/DRAC**,
  never by any coverage proposed here.
- **If any of C1–C6 turn out, at implementation time, to be unmeetable without one of the above,**
  that must be reported back as a blocker on this predeclaration, not quietly narrowed to a weaker
  version that still uses the same criterion name.

## 4. Status: NO-GO (authorizes no implementation, no campaign, no seed draw)

**This predeclaration authorizes no implementation, no campaign, and no seed draw.** It is a
specification of acceptance criteria and a code skeleton for a future, separately authorized
implementation slice.

It contributes to exactly the same one of the six successor preconditions P3 names —
**launcher contract investigation** — that P3 already satisfies
(`docs/dev-log/handover/2026-07-20-d1-reseal4-postdraw-retirement.md:27-28`: "a new root, disjoint
allocation, new pre-registration, launcher contract investigation, fresh mutation controls/
reviews/preseal, and explicit authorization"). It does **not** newly satisfy a second, distinct
precondition: test-and-acceptance-criteria design for a contract fix is part of investigating that
contract, not a separate deliverable from it. The other five preconditions — a new root, a disjoint
allocation, a new pre-registration, fresh mutation controls/reviews/preseal, and explicit
authorization — remain open. D1 remains paused pending a separately authorized, pre-registered
successor plan; nothing here reopens it.

**What does not change:**

- `public_covered_count=5`; `ordinary_auto_genomic` held; V2-GRM/V2-GINV partial; D1 paused and
  unadjudicated.
- No line of `hsquared` was modified to produce this document. The sealed source at
  `hsquared@5325e95` was read only, via `git show 5325e95:<path>`; the hsquared working tree was
  never checked out.
- The retired root `/home/snakagaw/hsq_work/d1-reseal4` and seed space `2028000000/101:148` were
  not read, referenced as evidence, or touched.
- Per the standing no-post-hoc-relaxation rule
  (`docs/dev-log/decisions/2026-06-14-calibration-failure-response.md`), C1–C6 are fixed as of this
  document's date and may not be relaxed, narrowed, or reinterpreted after an implementer sees
  whether coverage written against them passes or fails.
