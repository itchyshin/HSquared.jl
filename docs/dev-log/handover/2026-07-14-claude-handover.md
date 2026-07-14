# Session Handoff: v0.7 genomic activation arc — live D0F and downstream-contract amendment

Meta: 2026-07-14 05:59 MDT · from Codex to Claude · paused at Shinichi's token limit

## Critical Context

You are Claude, picking up an **unfinished** cross-twin v0.7 genomic GREML
activation arc. Do not read the green draft PRs as recovery evidence. The core
R/Julia candidate code and schema-only contracts are landed, but D0F is still
being independently recomputed, D1-D4 have not run, and the final public route
remains held.

Two working trees intentionally contain carried-over state. **Do not reset,
clean, stash, or overwrite either tree.** The R tree contains a scientifically
necessary prospective contract/preregistration amendment awaiting renewed
review. The Julia tree contains a partial untracked numerical replay scaffold.

The live Totoro process is safe to leave running: 16 single-threaded base-R
recomputation workers, parent `xargs` PID 1705244, output root
`/home/snakagaw/hsq_work/v07-genomic-recovery-v3-d0f-retry-r2-2cb5308-f7ff838`.
At 05:58 MDT it had 432/576 primaries, 432/576 sidecars, and zero partials.

## Mission and endpoint

Deliver a merge-ready, cross-twin 0.7 genomic GREML activation candidate in
which `hsquared()` honestly auto-routes the narrow Gaussian REML
`genomic(1 | id, ...)` model to HSquared.jl, carrying sample-frequency
VanRaden1, `K_lambda = G + 0.01I`, scale-labelled output, exact supplied-Q
linkage, recovery evidence, limitations, and independent audits end-to-end.

The endpoint is not a release and not an automatic merge. `public_covered_count`
remains 5. No D2 seed may be consumed until the prospective amendment,
dedicated numerical validators, renewed plan reviews, and exact D1 validation
are green.

## Mission Control

| Surface | Branch / head | CI and evidence state | Highest-leverage next action |
| --- | --- | --- | --- |
| `hsquared` | `codex/2026-07-13-v07-performance-localization` @ `120d04d` pushed | PR #137 draft; R-CMD-check 29329417997 green; 4-file amendment dirty | Review and land the prospective doc49/contract amendment; then build dedicated R downstream validator |
| `HSquared.jl` | same branch @ `9d1527e9` pushed | PR #274 draft; Julia 1.10/current + Documenter green; one untracked partial scaffold | Preserve scaffold; rebuild only after amended contract is reviewed and landed |
| Totoro D0F | immutable root named above | 576/576 official fits; 432/576 base-R recomputations at checkpoint; zero partials | Monitor to 576, verify sidecars, then run R summary → Julia replay → parity → reviews → adjudication |
| Fir / DRAC | exact code at `/project/6098264/hsq_work/v07-genomic-recovery-v3-code-2cb5308-f7ff838` | R 4.5.0, Julia 1.10.10, libraries and allocation self-test green | Receive the completed D0F root; run D1 only after formal D0F PASS |
| Public activation | held | supplied-Q engine remains covered; raw-marker route remains partial; G5-G10 open | Never merge activation/status or change the count without full chain and explicit G10 |

## What Was Accomplished

- R public genomic ratio wording landed at `d311fef`; adaptive D2 admission
  landed at `670e6ee`; schema-only downstream contract landed at `120d04d`.
- Julia D0F/D1 hardening landed through `f7ff838`; schema-only synthetic mirror
  landed at `9d1527e9`.
- Both latest pushed heads are CI-green.
- Official fresh-D0F fitting finished 576/576 successfully. Independent base-R
  recomputation is live and has valid matching sidecars.
- Fir is fully prepared for D1; no D1 or D2 seed has been consumed.
- Adversarial review found four contract defects and they were fixed in
  `120d04d`: history binding, nonfinite precedence, effective mutation control,
  and fail-closed real D2 authentication.
- Later Noether review found two deeper prospective conflicts. The carried-over
  amendment fixes them: D3 admits one-to-three selected complete triplets while
  D4 requires the exact original three; official attempts no longer contain a
  future corpus-lock hash. It also requires terminal ordered D2 history and
  dedicated validators for all D2-D4 roots.

## Current Working State

### Working / landed

- R head `120d04d2ef6e5c42a152ed289361929a7339bac8`, pushed to PR #137.
- Julia head `9d1527e9e4463c92ea601c5bac3e1f928fb43b8d`, pushed to PR #274.
- R amendment tool self-test and 93 focused assertions pass locally.
- Amended downstream tool SHA:
  `556956873cdd3f2dcd7b5a022a518d021b8dd2edd553f5e0dff6505d5aeb23c6`.

### In progress / carried over

R repo `/Users/z3437171/Dropbox/Github Local/hsquared`:

```text
 M docs/design/49-v07-genomic-recovery-v3-sample-size-ladder.md
 M tests/testthat/test-v07-genomic-recovery-v3-downstream-contract.R
 M tools/v07_genomic_recovery_v3_downstream_contract.R
 M tools/v07_genomic_recovery_v3_downstream_contract.R.sha256
```

File hashes at handoff:

```text
da581fbd6d924ad924620ead5d7af92a650a2976096dd5f69f674e4432ab9cd3  docs/design/49-v07-genomic-recovery-v3-sample-size-ladder.md
556956873cdd3f2dcd7b5a022a518d021b8dd2edd553f5e0dff6505d5aeb23c6  tools/v07_genomic_recovery_v3_downstream_contract.R
fcfbce7c32348b1d087b9ca7bedf363f0a613c6bcd4a65ce1ba5cf69e5cfd62e  tests/testthat/test-v07-genomic-recovery-v3-downstream-contract.R
```

Julia repo `/Users/z3437171/Dropbox/Github Local/HSquared.jl`:

```text
?? sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl
SHA-256 30838979b9f3aad7d3442204fb4a4a30345f24950000d7ecb23a20d63cad6155
```

This Julia file is an interrupted scaffold, not reviewed, not sidecar-bound,
not tested, and not evidence.

### Not working / blocked

- Real D2-D4 history authentication deliberately fails closed until these
  dedicated tools exist and reconstruct the full final tree:

```text
hsquared/tools/v07_genomic_recovery_v3_downstream_recompute.R
  --mode=validate-final --output-root=<root> --stage=d2|d3|d4

HSquared.jl/sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl
  --mode=validate-final --output-root=<root> --stage=d2|d3|d4
```

- Three final amendment reviews (Noether, Hopper, Fisher) were interrupted at
  Shinichi's explicit request to stop. They produced no verdict. Restart them.

## Key Decisions and Rationale

- D3 retains the preregistered exact-cell endpoint and therefore allows
  one-to-three complete selected triplets. Only D4 is an exactly-three original
  triplet campaign and only D4 can discharge G5.
- D3/D4 require terminal ordered D2 history. Early snapshots, omitted batches,
  reordered histories, and caller-selected validators are invalid.
- Official attempts are written before the corpus lock and cannot contain its
  hash. Post-lock independent R/Julia rows may bind it.
- The Julia confirmation mirror stays synthetic-only and evidence-ineligible.
- D0F estimates are mechanism evidence only and never enter D1-D4 sizing.
- Raw results stay local; simulations never run on GitHub Actions.

## Landing State

The handoff gate was run for both repos and returned nonzero exactly because of
the declared carried-over files below. It also listed many unrelated historical
unpushed branches; those pre-existed and were not modified in this session.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `hsquared` branch @ `120d04d` | yes | yes | #137 draft | LANDED |
| `HSquared.jl` branch @ `9d1527e9` | yes | yes | #274 draft | LANDED |
| R four-file prospective amendment on same branch | no | no | #137 working tree only | CARRIED-OVER — awaiting renewed Noether/Hopper/Fisher review; resume with `cd '/Users/z3437171/Dropbox/Github Local/hsquared' && git status -sb && git diff --check` |
| Julia downstream numerical replay scaffold | no | no | #274 working tree only | CARRIED-OVER — interrupted scaffold; resume with `cd '/Users/z3437171/Dropbox/Github Local/HSquared.jl' && git status -sb && sed -n '1,260p' sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` |
| Totoro D0F independent recomputation root | local compute | n/a | none | CARRIED-OVER — live 16-worker job; monitor command below |

## Next Immediate Steps

1. Rehydrate both repos and verify the two dirty trees exactly; do not clean.
2. Monitor D0F until 576 base-R primaries and sidecars exist with zero partials.
3. When complete, run the sealed D0F R summary, Julia replay, parity, reviews,
   adjudication, and `validate-final` commands below.
4. Restart Noether, Hopper, and Fisher reviews of the exact R amendment. Fix all
   blockers, rerun the self-test and focused tests, update its sidecar, then
   commit/push the four R files.
5. Only after the amended R contract is frozen, inspect the Julia scaffold and
   implement the dedicated R and Julia numerical validators with adversarial
   tests. Do not spend a D2 seed.
6. If D0F is formally `PASS`/`COMPLETE`, copy its final root byte-identically to
   Fir and run D1 smoke/official/replay/adjudication from the exact clean deploy.
7. D2-D4 proceed only through the amended terminal-history protocol. Finish
   Fisher/Darwin/Noether/Hopper/Grace/Rose reviews, G6-G7, and explicit G10.

## Exact D0F continuation commands

Monitor:

```sh
SOCK="$HOME/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22"
ssh -o BatchMode=yes -o ConnectTimeout=12 \
  -o ControlPath="$SOCK" -o ControlMaster=no totoro '
ROOT=/home/snakagaw/hsq_work/v07-genomic-recovery-v3-d0f-retry-r2-2cb5308-f7ff838/base_r_recompute/d0f
printf "primary="; find "$ROOT" -type f -name "*.tsv" | wc -l
printf "sidecar="; find "$ROOT" -type f -name "*.tsv.sha256" | wc -l
printf "partials="; find "$ROOT" -type f -name "*.partial*" | wc -l
pgrep -af "v07_genomic_recovery_v3_recompute.R --args --mode=recompute-one" | grep d0f || true
'
```

After exactly 576/576 and zero partials:

```sh
CODE=/home/snakagaw/hsq_work/v07-genomic-recovery-v3-code-2cb5308-f7ff838
R_ROOT=$CODE/hsquared
JULIA_ROOT=$CODE/HSquared.jl
LAUNCH=$R_ROOT/tools/run-v07-genomic-recovery-v3.sh
D0F=/home/snakagaw/hsq_work/v07-genomic-recovery-v3-d0f-retry-r2-2cb5308-f7ff838

"$LAUNCH" summarize-r "$D0F" d0f "$R_ROOT" "$JULIA_ROOT"
"$LAUNCH" replay-julia "$D0F" d0f "$R_ROOT" "$JULIA_ROOT" 16
"$LAUNCH" verify-replay "$D0F" d0f "$R_ROOT" "$JULIA_ROOT"
"$LAUNCH" summarize-julia "$D0F" d0f "$R_ROOT" "$JULIA_ROOT"
```

Write genuine post-run reviews only after inspecting the completed evidence:

```sh
"$LAUNCH" write-postrun-review "$D0F" d0f "$R_ROOT" "$JULIA_ROOT" fisher VERDICT ACTUAL_UTC
"$LAUNCH" write-postrun-review "$D0F" d0f "$R_ROOT" "$JULIA_ROOT" noether VERDICT ACTUAL_UTC
"$LAUNCH" write-postrun-review "$D0F" d0f "$R_ROOT" "$JULIA_ROOT" hopper VERDICT ACTUAL_UTC
"$LAUNCH" write-postrun-review "$D0F" d0f "$R_ROOT" "$JULIA_ROOT" grace VERDICT ACTUAL_UTC
"$LAUNCH" write-postrun-review "$D0F" d0f "$R_ROOT" "$JULIA_ROOT" rose VERDICT ACTUAL_UTC
"$LAUNCH" adjudicate "$D0F" d0f "$R_ROOT" "$JULIA_ROOT"
"$LAUNCH" validate-final "$D0F" d0f "$R_ROOT" "$JULIA_ROOT"
```

D1 is admitted only if the final receipt says `PASS` / `COMPLETE` and attempt
and summary parity maxima are at most `1e-10`.

## Compute deployment already prepared

- Totoro exact code:
  `/home/snakagaw/hsq_work/v07-genomic-recovery-v3-code-2cb5308-f7ff838`
- Fir exact code:
  `/project/6098264/hsq_work/v07-genomic-recovery-v3-code-2cb5308-f7ff838`
- Fir R library: `/project/6098264/hsq_work/Rlib-4.5`
- Fir Julia depot: `/project/6098264/julia_depot`
- Modules: `StdEnv/2023 r/4.5.0 julia/1.10.10`
- Account: `def-snakagaw_cpu`
- Receipt root present on both hosts:
  `/home/snakagaw/hsq_work/v07-reviews-r2-2cb5308-f7ff838`
- Fir setup jobs 48736091 and 48736109 succeeded; launcher allocation
  self-test job 48737129 passed.

## Blockers / Open Questions

- No user input is required. The blockers are executable gates, not ambiguity.
- The full positive endpoint was estimated at 22-38 elapsed hours at pause.
- If a preregistered cell fails, finish the honest negative-path packaging;
  never relax a threshold or delete a failed seed.

## Gotchas and Failed Approaches

- Do not reuse the blocked first D0F root or any retired recovery-v2 seed.
- Do not use PR greenness as recovery evidence.
- Do not use the synthetic Julia mirror as an operational validator.
- Do not add `corpus_lock_sha256` to official attempts.
- Do not allow D3/D4 from a D2 prefix/snapshot.
- Do not label the genomic ratio ordinary/pedigree heritability.
- Totoro load fluctuated above 400; keep this job at 16 workers and never kill
  unrelated `gllvm` work.
- The unified local SSH session handle closed, but remote parent PID 1705244
  and its workers remained healthy. Monitor the remote tree, not the old handle.

## How to Resume

From Shinichi's authenticated terminal:

```sh
cd '/Users/z3437171/Dropbox/Github Local/HSquared.jl' && \
claude "Rehydrate from docs/dev-log/handover/2026-07-14-claude-handover.md plus the AGENTS.md snapshot. Preserve both dirty working trees and the live Totoro D0F job, then execute Next Immediate Steps autonomously. Do not spend a D1 seed before formal D0F PASS, and do not spend any D2 seed before the amended contract and dedicated validators are reviewed, committed, and green."
```

Claude should run the repository rehydration procedure, read this handoff plus
doc 49, capability status, validation debt, and both draft PRs, and invoke Rose
before any public claim. Claude owns the same live work despite the usual
toolchain preference; if its environment cannot execute a live R/Julia step,
leave a turnkey command rather than weakening the gate.
