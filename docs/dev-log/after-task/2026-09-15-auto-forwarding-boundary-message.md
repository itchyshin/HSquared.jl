# After-task — 2026-09-15 :auto forwarding / boundary-message slice (#343 #347 / PR #348)

## 1. Goal

Record HSquared.jl PR #348 (merged `e25e2831`), which closed follow-on issues #343 and
#347 from the 2026-09-13 H2 fixer campaign: forward `initial`/`iterations` on the opt-in
`:multi_effect` `scale_method = :auto` path, and reword the boundary-refusal message to
name a lever that can actually clear it. This report and the matching `check-log.md` entry
are the records-only pass; the fix itself, tests, and Rose audit were done in a prior
session/worktree (branch `claude/h2-auto-forwarding-20260915`, per `j6-343-347.md`) and
merged before this pass
started.

## 2. Implemented

Records only, in worktree branch `claude/h2-auto-forwarding-records` (base = merged
`main` including PR #348):

- Appended one `check-log.md` entry dated 2026-09-15 describing PR #348's two fixes, the
  Rose pre-merge audit (1 required + 2 minor, applied before merge), the twin context
  (hsquared PR #229 merged, #230 open), and fresh checks run in this worktree.
- Wrote this after-task report.

The PR itself (already on `main`, not re-touched here):

- **#343** — `src/bridge_payload_v2.jl`'s `_dispatch_fit`, `:multi_effect` arm: the
  `multi_effect_kwargs` NamedTuple (already built for the `:dense` branch) is now also
  splatted into the `:auto` branch's `fit_multi_effect(...; method = :auto, ...)` call.
  Empty when both `initial`/`iterations` are `nothing`, so every default call on either
  route stays byte-identical. Docstring updated to name both `:auto` engines' own defaults.
- **#347** — `src/nongaussian.jl`'s `nongaussian_three_field_payload`: the `boundary = true`
  `ArgumentError` no longer advises `restart_check = true` as a fix (that check is
  monotone — it can only turn `boundary` from `false` to `true`); it now names the real
  lever, a different `initial`, which recentres the log-scale search bracket. The
  `fit_laplace_reml` docstring's `restart_check` paragraph carries the same clarification.
  **Rose's required change, applied before merge:** the family gate
  (`fit.family in (:poisson, :bernoulli, :binomial)`) now runs *before* the boundary gate,
  so the `exp(log(sa0) ± 6)` bracket named in the boundary message is exact for every
  family that can reach that line — the jointly-estimated families (`:gamma`, `:nbinom`,
  `:gaussian`, `:ordered_probit` with `K ≥ 3`) stop on a ±8-log-unit rail instead and are
  now caught by the family-unsupported message first, never told the wrong bound.
- Tests: `test/test_343_auto_forwarding.jl` (new — case (a) default-call parity, case (b)
  extreme-`initial`/`iterations=1` parity against a direct `:auto` call); a `case (a)`
  extension to `test/test_327_boundary_flag.jl` asserting the message names `initial`,
  still mentions `restart_check`, and states "cannot clear". Both included from
  `test/runtests.jl`.
- `docs/src/changelog.md`: two `## Unreleased` bullets, one per issue.

## 3a. Decisions and Rejected Alternatives

- **Gate reorder (Rose required change 1, preferred form) vs. dropping the number
  entirely.** Rose's audit offered two fixes for the ±6-bracket overclaim: reorder the
  family/boundary gates (chosen — keeps the message twin-identical with hsquared PR #229's
  wording and makes the number exact by construction), or keep the gate order and drop the
  hard-coded number from the message (rejected — would have made the Julia and R messages
  stop being verbatim twins, and the R twin's own `hs_ng09_boundary()` message also
  hard-codes the same `± 6` figure and stays correct only because it is reachable solely on
  the three-family route). The reorder changes which `ArgumentError` a boundary-flagged
  unsupported-family fit receives (family message, not boundary message) — a refusal-order
  change, not a numerical behaviour change; the changelog's #347 bullet says so explicitly
  rather than the pre-repair "no behaviour change" line.
- **Kept the `(#327)` reference and the "boundary = true" token in the reworded message.**
  The R twin's translated-error test matches on "boundary" and "restart_check" — changing
  either would have silently broken that contract test in the R lane.
- **No version bump, no capability-status/validation-debt row.** #343 is a plumbing fix on
  an already-experimental opt-in route; #347 is message/docstring wording plus one
  refusal-order correction. Neither is an `experimental → covered` move.
- **This records pass does not re-run the Rose audit or re-litigate its verdict** — it
  re-runs the checks fresh (real output, this worktree) and records what already happened,
  per this task's brief.

## 4. Files Touched

This records-only pass, in worktree branch `claude/h2-auto-forwarding-records`:

- `docs/dev-log/check-log.md` — one new entry appended at the end of the file.
- `docs/dev-log/after-task/2026-09-15-auto-forwarding-boundary-message.md` — this report
  (new).

Files touched by PR #348 (already on `main` before this pass started; listed for the
record, not re-touched here): `src/bridge_payload_v2.jl`, `src/nongaussian.jl`,
`test/runtests.jl`, `test/test_327_boundary_flag.jl`, `test/test_343_auto_forwarding.jl`
(new), `docs/src/changelog.md`.

## 5. Checks Run

All run fresh in the `claude/h2-auto-forwarding-records` worktree (= merged `main`,
commit `e25e2831`),
`OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4`:

- `julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'` — run in the
  background via a Monitor until-loop (no sleep chain), tail captured to
  `pkgtest_j6rec.log`. Full suite **passed** (`Testing HSquared tests passed`);
  `grep -c -E "Error|ERROR|Test Failed|error\(s\)"` over the whole log returned **0**.
  Both touched testsets green: `#343 engine controls: initial/iterations on the
  :multi_effect :auto path | 3 3`, `#327 boundary flag: honest search-bound reporting |
  13 13`.
- `julia --project=docs docs/make.jl` — run fresh in this worktree (background, watched
  with a Monitor). Clean VitePress/Documenter build; deployment correctly skipped
  locally (`Documenter could not auto-detect the building environment` — expected with
  no `CI` env set); only the pre-existing "docstrings not included in @docs/@autodocs"
  warning list (unrelated, pre-existing on `main`). `git status --porcelain` clean
  afterward (`docs/build/` is gitignored, so this is not evidence of idempotency by
  itself — but no *tracked* file was dirtied).
- `bash tools/preamble_cap.sh` — `CAP OK -- preamble within budget` (11024 B / ~2756 tok,
  cap 14000 B; 1 snapshot entry, cap 1).
- CI on `main` (`gh run list -R itchyshin/HSquared.jl --branch main -L 4`): the
  `Documenter` run on the merge commit `e25e2831` (run `35034608843`) — `success`
  (confirmed via `gh run view --json status,conclusion`). This repo's `CI` workflow
  (Julia 1 / 1.10 × ubuntu/windows) is `workflow_dispatch`-only (`gh workflow list`
  confirms), not triggered on push to `main`; its most recent run (`34667219579`,
  2026-09-12) predates this merge by three days and is not evidence for commit
  `e25e2831` — stated plainly rather than silently counted as coverage.

## 6. Tests of the Tests

- `test/test_343_auto_forwarding.jl`'s case (b) is a genuine discriminator, verified
  independently by Rose (`rose-j6.md`) rather than taken on the PR body's word: a
  standalone script calling `fit_multi_effect` twice on the test's own fixture showed a
  **702.11**-magnitude gap between the default fit and the extreme-`initial`/`iterations=1`
  fit; pre-fix, the payload probe matched the *default* exactly (`max_rel_diff = 0.0`,
  parity-vs-direct-call gap = 702.11); post-fix, the probe matches the *direct `:auto` call
  with the same controls* to exactly 0.0. So the test would catch a reversion to the
  silent-drop behaviour, not just a crash.
- `test/test_327_boundary_flag.jl`'s extended case (a) was confirmed red against the old
  message text by stashing the `src/nongaussian.jl` fix and re-running: failed exactly on
  the new "cannot clear" assertion (12/13 passed in the testset, old message text visible in
  the failure diff), then restored and re-ran green (13/13).
- The gate-reorder fix (Rose's required change) was checked for test-safety before being
  applied, not just for correctness: `test/a3_three_field.jl`'s `_fit` helper builds fits
  with `boundary = false`, so its `@test_throws ArgumentError` for an unsupported family
  still fires on the family gate either way; `test/test_327_boundary_flag.jl` case (a) uses
  `:poisson` (one of the three supported families, unaffected by gate order); cases (d)/(e)
  never call the payload builder. No test asserted the old gate order, so the reorder could
  not silently break a passing assertion.

## 7a. Issue Ledger

Closed by merged PR #348: HSquared.jl **#343**, **#347**. No new issues opened by this
records pass. Issues named but not touched here (already tracked, unchanged status):
**#340** (`ngen` optimizer parameter count, follow-on to #331, OPEN), **#344**
(`laplace_reml_interval` does not consume `boundary`, follow-on to #327/#342, OPEN),
**#345** (R bridge reads only `converged`, follow-on to #327/#342, OPEN, pointed at twin
issue `itchyshin/hsquared#222`). Twin-repo cross-reference: hsquared PR **#229** (merged
2026-09-15, carries the same reworded boundary message and forwards
`initial`/`restart_check` from R into `HSquared.fit_laplace_reml()`), hsquared **#230**
(open — exposing the boundary flag through `fit_diagnostics()`).

## 8. Consistency Audit

- **Same-class check for the ±6-bracket overclaim.** Rose did not stop at confirming the
  three named families are exact — she traced every branch of `fit_laplace_reml` (nine
  families total) against which bound each one actually stops on, and found the boundary
  gate's placement meant the message was reachable for the four/five families the ±6 figure
  is *false* for (`:gamma`, `:nbinom`, `:gaussian`, `:ordered_probit` K≥3), not merely
  unlikely to be reached. The fix (gate reorder) makes the exactness a structural fact
  ("cannot reach this line" per the new code comment), not a premise about which families
  the payload happens to support.
- **Same-class check for other unretracted `restart_check`-as-rescue advice.** Rose grepped
  `src/` and `docs/src/` for any other live text still advising `restart_check = true` as a
  fix; found none other than the `NonGaussianFit` field docs (purely descriptive) and the
  keyword default.
- **Cross-repo consistency check.** Rose cross-checked the reworded Julia message against
  the merged R twin (hsquared PR #229) token-by-token ("boundary", "restart_check",
  "initial", the `± 6` figure) rather than assuming the twin wording claim in the PR body
  was accurate.
- This records pass re-ran the local checks fresh in a separate worktree rather than
  re-citing the PR body's own evidence claims, and separately confirmed CI success on the
  exact merge commit via `gh run list`/`gh run view`, rather than treating the PR's own
  pre-merge CI (against the pre-merge branch tip) as equivalent to a check against `main`.

## 9. What Did Not Go Smoothly

- This repo's `CI` workflow (the Julia 1 / 1.10 × ubuntu/windows matrix) is
  `workflow_dispatch`-only and does not trigger on push to `main`; only `Documenter` and
  `TagBot` fire automatically on a merge. `gh run list --branch main` therefore does not
  show a fresh `CI` run for this merge commit — its last run predates this PR by three days.
  Recorded plainly rather than treated as silent CI coverage; the `Documenter` success on
  `e25e2831` plus this pass's own fresh local `Pkg.test()` are the operative evidence for
  this commit.
- Otherwise this was a clean records pass: the fix, tests, and Rose audit were all done
  and merged in a prior session, so this pass's only friction was confirming (rather than
  assuming) that the `CI` workflow gap above was a pre-existing repo property and not
  something broken by this merge — resolved by checking `gh workflow list` and the
  workflow's own trigger history rather than treating the absent run as either a pass or
  a failure.

## 10. Known Residuals

- **`:auto`'s `:matrix_free` (Monte-Carlo) half of the forwarding fix is argued from the
  shared `kwargs...` splat and the fitter's own signature, not measured** — the #343 test
  fixture is tiny and routes to `dispatch = :exact` (sparse AI-REML) only. Carried over
  unchanged from the original fix; worth a validation-debt line if `:auto`/matrix-free is
  ever promoted out of experimental.
- **`laplace_reml_interval` still does not consume `NonGaussianFit.boundary`** (#344, OPEN,
  untouched by this PR) — a boundary-riding point estimate still yields a self-consistent
  but uninformative interval with no warning from the interval call itself.
- **The R bridge's generic wrapper still reads only `converged`, not `boundary`**, at the
  generic (non-`ng09`) call sites (#345, OPEN, R-lane work tracked against twin issue
  `itchyshin/hsquared#222`) — hsquared PR #229 fixed the `ng09`-specific route only.
- **No R-side change in this PR or this records pass** — the twin wording match (hsquared
  #229) was a separate, already-merged PR in the sibling repo, cross-checked but not
  altered here.
- This records pass makes no capability-status or validation-debt change, per the
  instructions and the underlying PR's own stated scope.

## 11. Team Learning

- **A required-change audit finding can be a structural fix, not just a wording fix** — the
  chosen resolution for the ±6-bracket overclaim (reordering two gates so the exact family
  set that can reach a message is fixed by construction) is more durable than either
  leaving the number in place with a caveat, or generalizing the wording to cover every
  family, because it makes a future family addition fail loudly (at the family gate) rather
  than silently inheriting a wrong bound in its error text.
- **When a repo's CI workflow is `workflow_dispatch`-only, `gh run list --branch main`
  after a merge will not show fresh coverage** — check `gh workflow list` once per repo to
  know which triggers actually fire on push, rather than assuming an absent recent run means
  CI did not run (it may mean it does not run automatically at all).
- **Cross-repo wording claims should be checked against the twin's merged state, not
  assumed** — this pass independently confirmed hsquared PR #229 is merged and carries
  matching tokens, rather than repeating the PR body's own unverified claim about the R
  side.

## 12. Cross-Product Coverage

Two cross-cutting fixes in this slice; coverage stated per surface, not just per issue.

- **Engine-control forwarding (`initial`/`iterations`) on `fit_payload_v2`'s
  `:multi_effect` arm, #343.** Covers ✓: the `scale_method = :auto` route (both the
  `:exact`/sparse-AI-REML and, by signature/kwargs-splat argument only, the
  `:matrix_free`/Monte-Carlo engine `fit_multi_effect` can select), matching what the
  `:dense` route already had since #337/#212. Does NOT cover ✗: the R-side forwarding of
  these controls into a `scale_method = :auto` call — `:auto` is not the R-facing default
  and this PR does not touch R; `multi_effect_ratio_interval`'s internal refit path, called
  directly from R rather than through `fit_payload_v2` (unchanged, out of scope); any
  measured (as opposed to signature-argued) confirmation that the kwargs reach the
  Monte-Carlo engine correctly, since no test in this PR exercises `dispatch = :matrix_free`.
- **Boundary-message honesty on `nongaussian_three_field_payload`'s refusal, #347.** Covers
  ✓: all nine `fit_laplace_reml` families reachable through the gate reorder — the three
  payload-supported families (`:poisson`, `:bernoulli`, `:binomial`) now receive an exactly
  correct `± 6` bracket message when boundary-flagged, and the six unsupported families
  (`:gamma`, `:nbinom`, `:gaussian`, `:ordered_probit`, `:beta_binomial`,
  `:bernoulli_probit`) are refused by the family message first and never see a boundary
  message that could misstate their bound; the `fit_laplace_reml` docstring's parallel
  `restart_check` paragraph. Does NOT cover ✗: `laplace_reml_interval`, which still does not
  read `boundary` at all (#344, unchanged by this PR); the R bridge's generic (non-`ng09`)
  wrapper, which still reads only `converged` (#345, unchanged by this PR; hsquared's
  `ng09`-specific route was separately fixed in hsquared PR #229); any change to the
  `restart_check` two-start fence's own threshold or sizing evidence (unmeasured for eight
  of nine families, per the pre-existing docstring caveat — untouched by this PR).
