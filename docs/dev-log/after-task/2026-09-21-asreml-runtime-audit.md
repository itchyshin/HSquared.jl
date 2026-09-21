# After-task — 2026-09-21 measured runtime audit against ASReml, and one docs fix

## 1. Goal

Two things, in order. (a) Rehydrate and deal with whatever the repo state showed — which turned
out to be a red `main`. (b) Owner: "audit Julia runtime against the ASReml-R's on great tit data
(ASReml 2s). I want a clear picture of where we stand with runtime efficiency before we move
further."

## 2. Implemented

**(a) Documenter fix — `#373`, PR open and fully green, NOT merged.** `main` had been red since
`25531235` (`#370`). `#362` split `multi_effect_variance_component_covariance` into a private
`_`-prefixed implementation plus a thin public wrapper and left the docstring on the private
half; `#370` then added the public name to `docs/src/api.md`, which is the first thing that ever
asked for that binding. Docstring moved verbatim onto the public wrapper; private definition
keeps a plain comment. Also re-pointed one pre-existing stale ledger citation
(`capability-status.md:95` → `test/runtests.jl:7237`), the **third** re-point of that same anchor.

**(b) Runtime audit — measurement only, no engine code changed.** Harness committed at
`docs/dev-log/scripts/2026-09-21-asreml-runtime-audit/`, deliberately, because the 2026-09-21
post-fit arc's scripts were not and its numbers could not be re-run by anyone else.

Findings in `docs/dev-log/check-log.d/2026-09-21-asreml-runtime-audit.md`. The three that matter:

1. **The baseline was wrong by 3.2×** (`#376`). The notebook gives ASReml the full 111,645-row
   pedigree and hsquared the pruned 10,937-row one. ASReml: 1.82 s full, **0.57 s pruned**,
   identical estimates and loglik, 7 iterations either way. The "~2 s" is the full-pedigree run.
2. **We are 2.1× off that corrected baseline**, and the gap is not where anyone looked.
   Marshalling is 0.020 s both directions; A⁻¹ construction **beats** ASReml (0.012 vs 0.019);
   per iteration we are **faster** (63 ms vs 71 ms). The gap is post-fit uncertainty (0.552 s,
   of which 0.387 s is duplication `hsquared#238` already removes) plus iteration count.
3. **`selinv_block_traces` is 45.8 ms of each 61 ms iteration — 75%** (`#375`), ~38% of shipped
   runtime, and worth more than `#238`, `initial = :auto` and `tol` combined.

## 3a. Decisions and Rejected Alternatives

- **Ran ASReml rather than accepting the reported figure.** The post-fit arc closed with "no
  ASReml run of our own — the ~2 s figure remains the owner's report", correctly fenced. ASReml
  4.2 turned out to be installed with a live licence. Running it is what exposed `#376`; had I
  kept the fence and reasoned from 2 s, I would have reported us comfortably ahead when we are
  2.1× behind. **"Licence-absent" in `docs/design/52-...` is now stale on this machine** — the
  governance rule (not a covered leg) is unchanged, the factual premise is not.
- **Rejected: reporting the pedigree path as a 19× deficit.** The first profile timed
  `normalize_pedigree` + `pedigree_inverse` on their FIRST call and got 0.370 s against ASReml's
  0.019 s. That was JIT compilation. Warm it is 0.012 s and we win. Caught before it reached the
  owner, but it had already been written into one message.
- **Rejected: changing any default.** `initial = :auto` and `tol = 1e-6` together reach parity,
  and neither was touched — both move a converged estimate's last bits against checkpoints run
  at `(1,…,1)` / `tol = 1e-8`. Measured and handed back as evidence decisions (`#372`).
- **Rejected: editing the R twin.** `#376`'s notebook fix and `hsquared#238`'s merge are R-lane;
  flagged in issues, not done from here (`CLAUDE.md`).
- **Chose a PR over a direct push** for the docs fix, because `CI.yml` has no `push` trigger
  (`#367`) — a push would have proved nothing.

## 4. Files Touched

- `src/likelihood.jl` — docstring relocation only, no behaviour (`#373` branch).
- `docs/design/capability-status.md` — one citation anchor (`#373` branch).
- `docs/dev-log/check-log.d/2026-09-21-api-docstring-binding-fix.md` (new, `#373` branch).
- `docs/dev-log/check-log.d/2026-09-21-asreml-runtime-audit.md` (new).
- `docs/dev-log/scripts/2026-09-21-asreml-runtime-audit/` (new: 10 scripts + README).
- This report.

**No engine source changed by the audit.**

## 5. Checks Run

- `Pkg.test()` — **passed**, exit 0, 176 summaries, 0 failures / 0 errors / 0 broken, Julia 1.13.0.
- `docs/make.jl` — clears **every Documenter stage** after the fix (zero `docs_block`,
  `cross_references`, `no docs found`, `Cannot resolve @ref`); then dies at
  `npm … vitepress build` exit 127, the pre-existing local condition the `#370` report verified
  is identical from `main` in this checkout. Linking `docs/node_modules` into `docs/build` does
  not help — DocumenterVitepress wipes `docs/build` at the start of the run. **Full render
  unverified locally.**
- **`#373` CI — all green**: Julia 1 and 1.10 × ubuntu and windows, plus Documenter;
  `documenter/deploy` reports "Documentation build succeeded". That is the confirming leg the
  local build could not supply.
- `preamble_cap.sh` **CAP OK**; `check_capability_citations.py` **OK, 82 verified**;
  `build_check_log.sh --check` well-formed.

## 6. Tests of the Tests

- **A JIT artefact nearly became a finding.** See §3a. The fix in method was to make every
  reported number best-of-3 or better, and the README now documents the trap.
- **R's lazy evaluation faked a 0.000 s result.** `min(replicate(n, system.time(e)))` forces the
  promise once and reuses it, so `ainverse()` appeared to cost nothing. Rewritten to pass a
  function and call it. Documented in the harness README, because the failure mode is silent and
  reads as a *good* result.
- **The audit's own correctness leg is estimate agreement, not timing.** Every arm is required to
  reproduce 0.5954004 / 0.5252307 / 1.3727602; the Julia reconstruction also reproduces
  n = 11,856, q = 10,937, p = 63 and 10 iterations, matching the post-fit arc's record exactly.
  A fast run of the wrong model would otherwise look like a win.
- **The docstring fix was verified by binding audit, not by eye**: every `HSquared.*` line in
  `api.md` checked through `Docs.meta` — 1 missing before, 0 after, and it was the only one.

## 7a. Issue Ledger

**Opened:** `#375` (selinv_block_traces, the dominant lever, with the ASReml per-iteration
target), `#376` (claim-audit: the 3.2× inflated baseline).
**Commented:** `#372` (audit answers its decisions 1–3 with measurements), `#359` (a real-pedigree
external-comparator measurement now exists at validation scale — narrows, does not close),
`#364` (the thread sweep is now more valuable: the top cost has only ever been measured at 1
thread), `#367` (it let a red `main` through for two PRs; stacked PRs get no CI at all).
**Referenced, not changed:** `#353` (CLOSED under D-271 at fill 471 — untested at clique 17.7),
`#361`/`#363` (measured irrelevant at this clique size), `#366` (coverage calibration, untouched),
`#357`, `#358`.
**Cross-lane:** `hsquared#238` (open; worth 0.387 s and no estimand — the only free step toward
parity), and the notebook fix in `#376`.

## 8. Consistency Audit

Review lenses applied as PERSPECTIVES. **No subagent was spawned.**

- **Gauss / Karpinski.** Every number is best-of-N warm, with the stage split measured through
  the bridge's own calls rather than inferred by subtraction. The one inferred quantity — ~0.25 s
  of R-side overhead above the Julia total — is labelled as inferred.
- **Rose.** No capability row moved, `public_covered_count` stays **7**, version stays `0.9.0`,
  no `validation_status()` row added or removed. ASReml is fenced as development-only everywhere
  it appears, and `#376` states plainly that no public claim was wrong because no runtime claim
  was ever published — the earlier fence held.
- **Grace.** The docs fix went through a PR precisely because pushing proves nothing here, and
  `#367` now carries the concrete cost.
- **Fisher.** The ASReml-vs-FD SE difference (0.066322 vs 0.069573) is reported as support for
  the post-fit arc's estimand reasoning, explicitly **not** as validation of either.

## 9. What Did Not Go Smoothly

- **`graft` was unavailable again** (MCP server `ENOENT`, no CLI on `PATH`), though `CLAUDE.md`
  requires it before grepping. Same residual as the `#370` report. Fell back to direct reading.
- **The first docs build "succeeded" with exit code 0 reported by the task runner** while the
  log contained `ERROR ... ProcessExited(127)`. The compound command's `echo` was what exited 0.
  Checked the log rather than the status, which is the only reason it was caught.
- **`ainverse()` failed three different ways** before working: on the 8-column `prepPed` output,
  and again after an RDS round-trip. Neither is documented; the harness works around both by
  subsetting to `[, 1:3]` and rebuilding from source rather than from cache.

## 10. Known Residuals

- **`#373` is green but NOT merged, so `main`'s Documenter is still red.** Owner call.
- **`selinv_block_traces` is untouched** (`#375`). Nothing in this session made anything faster.
- **The audit is one machine, one dataset, one trait, single-run cells**, 1 Julia thread /
  8 BLAS. No seeds, no pre-declaration, no MCSE, no second architecture, no thread sweep.
- **Nothing measured above q = 10,937.** `#358` / `#359` are untouched at large scale.
- **`AGENTS.md`'s Live Phase Snapshot is still stale** (dated 2026-09-07, says version 0.8.0 and
  "0.9.0 NOT authorized" while `Project.toml` is 0.9.0 and `v0.9.0` is tagged). Flagged by the
  `#370` report too. Out of scope again — it requires archiving the current entry verbatim first.
- **`docs/design/52-v07-exact-G-comparator-recipe.md:21` calls ASReml "licence-absent"**, which
  is no longer true on this machine. The governance conclusion is unaffected; the premise is stale.

## 11. Team Learning

- **The cheapest way to be wrong about performance is to trust the baseline.** Three sessions of
  careful profiling optimised against a comparator figure nobody had run. The measurements inside
  those sessions were sound; the reference point was inflated 3.2×, and no amount of internal
  rigour would have surfaced that. When a comparator number frames a whole arc, running it once
  is worth more than another round of profiling.
- **A correct fence can still mislead.** "~2 s is the owner's report, not our measurement" was
  honest, explicit, and repeated — and it still let the number function as a target for three
  sessions. Fencing a figure marks it as unverified; it does not stop it steering work.
- **JIT and lazy evaluation both fail toward the answer you want.** A cold Julia call reports
  ~30× the real cost; R's `replicate` over a promise reports zero. One invents a finding, the
  other hides one.
