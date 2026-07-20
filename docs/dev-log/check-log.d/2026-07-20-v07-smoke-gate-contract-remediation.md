# Check log — v0.7 Smoke-Gate Contract Remediation (planning-only)

**Date:** 2026-07-20 · **Slice:** full-sweep arity contract for the recovery-v3 launcher ·
**Lane:** Julia engine (`HSquared.jl`) docs; `hsquared` read-only at seal `5325e95`.

## Goal

Sweep every producer/consumer row-cardinality pair across all modes of
`tools/run-v07-genomic-recovery-v3.sh` at `hsquared@5325e95`, declare arity as data rather than as
independent literals, and pre-declare falsifiable acceptance criteria for a future implementation
slice. Planning-only: no implementation, no campaign, no seed, no `hsquared` modification.

## Commands run

Read-only, all against the seal or the local `HSquared.jl` tree:

```sh
# sealed launcher + tests, read WITHOUT checking out the hsquared working tree
git show 5325e95:tools/run-v07-genomic-recovery-v3.sh
git show 5325e95:tests/testthat/test-v07-genomic-recovery-v3-launcher.R

# controller provenance (both repositories, full history)
git log --all -S"smoke-n-ladder"
grep -rln "smoke-n-ladder"

# claim-ceiling concurrence
grep -n "public_covered_count\|ordinary_auto_genomic\|V2-GRM\|V2-GINV" \
  docs/design/capability-status.md docs/design/validation-debt-register.md

# NEW in this slice: intra-repo cross-reference range sweep across all four artifacts
python3 /tmp/xref.py
```

No Totoro or DRAC connection. No remote. No retired-root read. No seed allocation. No PR opened,
updated, or merged.

## Results

**Arity sweep — 11 rows across every launcher mode.** 1 MISMATCH (`smoke-n-ladder` emits
`|unique(manifest$n)|` = 4 rows; `recommend_workers` requires `>= 16` — the D1 `RC=21` cause),
1 MESSAGE-MISMATCH (`smoke-16`: `(( count >= 16 ))` predicate, `die` message reads "exactly 16"),
3 SPECIFIED, 4 UNSPECIFIED, 2 DEAD.

**Sealed-source citations — all verified exact.** Independently re-derived in the Rose close-out:

| Citation | Verified content |
| --- | --- |
| `:543` | `if (length(paths) < 16L) stop("fewer than 16 completed smoke attempts", call. = FALSE)` |
| `:556-557` | coverage guard, `setequal(observed_n, unique(as.integer(manifest$n)))` |
| `:571` | `memory <- readLines("/proc/meminfo", warn = FALSE)` — Linux-only |
| `:575` | `workers <- min(96L, preseal_cap, floor(0.7 * available_mb / max(rss)))` |
| `:576-578` | floor stop `"smoke RSS cannot support one admitted worker"` |
| `:633` | `printf '%s\n' "${smoke_rows[@]:0:16}" \| run_official_pairs "$workers"` |
| `:449` | `batch_size=$(( (missing + workers - 1) / workers ))` |
| `:78-81` | `require_smoke_missing_count`: `(( count >= 16 ))` vs "exactly 16" message |
| `:613-621` | `smoke-n-ladder` case body: `workers=${1:-1}`, no row-count assertion |

**hsquared test file at seal** (346 lines): `:307` is the named `test_that` block, `:335` its close,
`:320-324` the "exactly 16" `expect_match`. Claim "all 7 assertions in 308-334 are `expect_match`"
verified — `grep -c` returns **7**.

**Controller provenance:** `d1_reseal4_campaign.sh` exists in neither working tree nor either
repository's full history. Contradiction recorded, not investigated (owner directive).

**Cross-reference sweep — 3 defects found and corrected.** This check had **not** previously been
run; the prior verification was scoped to sealed-source citations only
(`scratchpad/citation-evidence.txt` contains zero intra-artifact references). All three were
introduced **by the P5 review fixes**, which shifted line numbers in files that other artifacts
cite:

| Stale citation | Landed on | Corrected to |
| --- | --- | --- |
| TSV "lines 16, 19, 21" (the SPECIFIED rows) | scope-fence header prose | **25, 28, 30** |
| P3 `:195-211` ("Why derived beats literal") | `--attempts` gap block | **`:231-247`** |
| P3 `:250-259` (`guard-selftest` precedent) | RSS risk block | **`:305-314`** |

After correction: **12/12 intra-repo citations resolve in range.**

**Fourth correction — gate scope.** Fisher added **C5**, but the document still defined its gate as
"C1–C4" in four places including the section heading and the no-relaxation clause. An implementer
would have read C5 — the fix for Finding 3, the deepest defect — as outside the gate. Corrected to
C1–C5 at lines 19, 75, 80, 324, 335, 366; line 198 left as C1–C4 (historical: Fisher's verdict *was*
on C1–C4 as first drafted).

**Fifth correction — authorization-shaped wording.** P4 §0 read "an implementer may proceed to write
the C1–C4 coverage ONLY IF it can be met as stated" — a conditional grant when read in isolation.
Rewritten to name the decision as belonging to a future authorized slice.

**Not run:** `Pkg.test()` / `docs/make.jl` — no `src/` change, no docs build input touched.

## Claim boundary

**No capability, route, or count moves.** `public_covered_count = 5`; `ordinary_auto_genomic` held;
V2-GRM/V2-GINV partial; D1 paused and unadjudicated. Confirmed concurrent with
`docs/design/capability-status.md:17,55-57,66` and
`docs/dev-log/handover/2026-07-20-d1-reseal4-postdraw-retirement.md:26`.

This slice satisfies **exactly ONE of six** successor preconditions — "launcher contract
investigation" (`docs/dev-log/handover/2026-07-20-d1-reseal4-postdraw-retirement.md:27-28`). The
other **five remain OPEN**: a new root, a disjoint allocation, a new pre-registration, fresh
mutation controls/reviews/preseal, and explicit authorization.

`attempts_per_rung = 4` is an **owner decision of 2026-07-20, not recovered intent.**

The deliverable is a **declared arity contract (data)**, not a behavioural composed test — a
composed test is impossible as a shipped check (`run_official_pairs` spawns real fits and consumes
seeds; `recommend_workers` reads Linux-only `/proc/meminfo`).

**D1 remains PAUSED.** Nothing here authorizes implementation, a campaign, a seed draw, or a
successor. `hsquared` was not modified. The retired root and seed space were not read.
