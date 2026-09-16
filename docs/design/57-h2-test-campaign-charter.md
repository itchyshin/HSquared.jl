# 57 — H² twin independent test campaign: charter

Status: **campaign charter, opened 2026-09-13.** Ratifies the shared rules for an independent,
multi-lane test campaign against both H² twins. Proposes and constrains; fits nothing, flips no
capability row, changes no default route. Modelled on the DRM twin campaign (six tester lanes,
issues as the spine, testers never push fixes).

## 1. Purpose and non-goals

**Purpose.** Attack the same claims from six independent angles — simulation recovery, real-data
fitting, cold documentation, symbolic-math adjudication, export-level code honesty, and a labelled
speed opinion — and turn every genuine finding into a GitHub issue or cluster comment with a
concrete repro, on both `hsquared` and `HSquared.jl`.

**Non-goals.** This campaign does not fix anything it finds (a separate fixer campaign, later); does
not change `capability-status.md`, `validation-debt-register.md`, `Project.toml`, or `DESCRIPTION`;
does not bump a version, cut a tag, or touch Julia General/CRAN; does not make or repeat any public
speed or ASReml claim; does not touch the R repo's source, tests, or docs from this (Julia) lane.

## 2. Scope

- Repos: `HSquared.jl` (main `b1f8f14`) and `hsquared` (main `4ec4cfb`).
- The 7 R-public covered routes under test: `gryphon` (the default univariate Gaussian animal
  model, default engine and `engine = "julia"`), `multivariate` (`cbind()`, t=2, routed on the
  default path), `genomic` (`target = "genomic"`), `common_env` (`target = "two_effect"`,
  common-environment leg), `multi_effect` (arbitrary-N independent `(1 | g)`,
  `target = "multi_effect"`), `random_regression` (k = 2), and `direct_maternal`.
  `permanent` / `target = "repeatability"` is **not** among them: both twins mark repeatability
  experimental (`HSquared.jl/docs/design/capability-status.md:89-90`, whose 2,000-seed confirm is
  a banked negative; `hsquared/vignettes/articles/model-status.Rmd:240-241`, filed under "Opt-in
  and experimental (not the default)"). Exercising it is still in scope as a bridge-liveness
  check, but a PASS there means the call completed and returned the documented shape, never
  that the route is covered. (Correction 2026-09-13, Rose audit of wave 1: the first version of
  this list named `permanent` in place of `multi_effect`.)
- The 89 non-covered R exports (96 total exports minus the 7 covered routes) as a coverage target
  for the Code Reviewer lane — each export is a ship / blocked / stop verdict, not a promotion.
- Cold documentation (both twins' install-through-first-fit path) and the standing question "is the
  Julia engine nearly as fast as ASReml", answered only as a labelled internal opinion.

## 3. Shared invariants

- Testers never modify `src/`, `R/`, `test/`, `tests/`, docs, `Project.toml`, `DESCRIPTION`, or any
  branch of either repo. Repros live in `projects/H2-twin/repros/`.
- One concrete repro per NEW draft (data · call · expected · observed · versions · host · SHAs
  `b1f8f14` / `4ec4cfb`). Same class → comment draft on the cluster, not a new draft. Rose's rule:
  one seen ⇒ assume ten; report pattern + exemplars.
- Numerical agreement with comparators is in scope; wall-clock is in scope **only** inside the Speed
  lane and never leaves the vault as a claim. No ASReml timing assertion anywhere public.
- Labels: existing programme set + `test-campaign`. Draft filename =
  `issue-drafts/<repo>-<cluster>-<n>.md` with front-matter `repo · cluster · labels · twin(s) ·
  repro path`.
- Every receipt ends with **"NOT COVERED"**.
- Threads: `OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=4`; ≤5 lanes live; each lane ≤4 cores.
- Worktree paths: `/private/tmp/h2camp-jl` (Julia, `b1f8f14`) and `/private/tmp/h2camp-r` (R,
  `4ec4cfb`). Testers work only in these two worktrees, never in the Dropbox checkouts.

## 4. Roles

- **W1-B bridge gate.** Loads both fresh worktrees and confirms `engine = "julia"` actually works
  before anything else runs. Fits the gryphon anchor on the default engine and on `engine =
  "julia"`, then one `engine = "julia"` call per remaining covered route. An ERROR on gryphon stops
  the Data Fitter and Speed lanes for that wave; the other four lanes proceed regardless.
- **L1 Simulator.** ADEMP-style receipts on hostile grids the 48-seed gates never used — small n,
  extreme h², deep inbreeding, phantom founders, malformed IDs, `r_g → ±1`, degenerate GLM cells.
  Estimands: bias, interval coverage and CI-existence rate, convergence honesty, R↔Julia parity on
  identical seeds. Pre-runs one cell before any full grid.
- **L2 Data Fitter.** Fits one public dataset at a time end-to-end on both twins plus a reference
  fitter on the same model (gryphon, `MCMCglmm::BTdata`, `nadiv::warcolak`, `pedigreemm::milk`,
  `sommer::DT_cpdata`, AGHmatrix pedigrees, Mrode textbook tables). Files only true gaps; a package
  gap is `SKIP`, not a finding. Gated on W1-B PASS.
- **L3 Doc Reader.** Three hats on cold documentation: (a) an ecology-PhD's install → vignette →
  gryphon walk on both twins; (b) a statistician's estimand/claim audit against doc 19 and de
  Villemereuil et al. 2016; (c) a consistency sweep for the 7/6/engine-row count drift and
  R↔Julia doc parity. Reports three labelled batches; never rewrites the docs itself.
- **L4 Mathematician.** Frames, never fits. Adjudicates the three-field h² equations, the Willham
  h²_T denominator, PEV/reliability/accuracy definitions, and profile-LRT interval claims against
  the corpus. Opens a new math draft only when the twins disagree *and* a cited source says which
  side is right.
- **L5 Code Reviewer.** Tabulates, for each of the 96 exports, whether it works on a covered model,
  errors honestly outside one, or returns something misleading; audits the 28
  `hs_skip_live_julia()` skip-as-pass files and SE/CI honesty. Output is ship / blocked / stop per
  pile, plus at most three proposed "finishes" as drafts, never new features.
- **L6 Speed.** Runs the agreement-first, timing-second protocol (a disagreeing cell yields no
  timing) against `pedigreemm`, `sommer`, and `MixedModels.jl` on a gryphon → `milk` → half-sib
  ladder, cold and warm, then states an AGENT-INFERRED opinion on ASReml parity from algorithm
  class + cited literature + the measured ladder. Never posts a number publicly. Gated on W1-B
  PASS.
- **Mission Control** (this campaign's vault record, `projects/H2-twin/MISSION-CONTROL.md`).
  Tracks wave state, roster, the stopping rule, and the running log; updated between every wave,
  never mid-wave.

## 5. Issue policy

Nothing is posted before Rose's claim-vs-evidence audit marks a draft **KEEP**. MERGE folds a
draft into an existing cluster's comment instead of a new issue; DROP means the finding does not
survive the audit and is never posted. KEEP items are filed with the `test-campaign` label plus
the repo's existing programme labels. File one repro per NEW item; a second finding of the same
class is a comment on the existing cluster, never a second issue. Titles carry the suffix
`[cluster: <name>]`. Every posted body has a `## Repro` section and a `Cluster:` line. No posted
item is worded as a capability claim or a speed claim — Rose confirms this before KEEP.

## 6. Receipt contract

Every lane receipt lands in the vault at
`projects/H2-twin/updates/YYYY-MM-DD-<lane>-w<N>.md`, with YAML front-matter:

```yaml
---
title: <lane> w<N> receipt
type: receipt
status: live
tags: [h2-twin, <lane>, receipt]
date: YYYY-MM-DD
lane: <lane>
wave: <N>
engine_shas: {julia: b1f8f14, r: 4ec4cfb}
host: <hostname>
versions: {julia: <ver>, r: <ver>, hsquared: <ver>, HSquared: <ver>}
---
```

Body sections, in order: **What ran** · **Agreed** · **Blew or gaps** · **Issues** (drafts and
their cluster) · **NOT COVERED** (mandatory, last).

## 7. Waves and STOPPING RULE

Wave N+1 starts only after wave N's V1 (mechanical verify), V2 (Rose claim-vs-evidence), and V3
(Melissa plan-vs-actual reconcile) are green. The campaign stops at the first of:

1. a wave whose KEEP set adds fewer than 3 new clusters across both repos (diminishing returns);
2. wave 4 complete;
3. cumulative posted issues + comments reach 60;
4. a MUST STOP trigger (§9).

Between waves: `MISSION-CONTROL.md` is updated and a one-paragraph informational report is
written for Shinichi.

## 8. Compute rule

Compute is local by default. Pre-run every grid before committing to a full run. Cap is 2 h per
lane per wave (8 h per wave in total). If a pre-run projects more, move that grid to Totoro
(≤150 cores, existing ControlMaster socket, no Duo) without asking; running overnight is fine if a
wave needs it. DRAC is never used by this campaign.

## 9. Pre-authorisation envelope and MUST STOP

```
PRE-AUTHORISED AFTER G0:
  GitHub (both repos): post issues and comments that Rose marks KEEP, with `test-campaign` + programme labels;
    create the `test-campaign` label; edit or close our own posted issues when a later wave supersedes them;
    merge-when-green of docs-only PRs this lane opens (Julia: check-log entry + charter; R: a docs-only charter
    pointer or coordination-board note, after `lane_preflight.sh ../hsquared`); merge PR #325.
  Repos: branch claude/h2-test-campaign-20260913; two scratch worktrees under /private/tmp; Pkg.instantiate and
    devtools::load_all; reap the dead lease once lane_liveness_check confirms; `git worktree prune` only for
    worktrees git already reports prunable (never delete a branch).
  Compute: local fits and ladders up to 2 h per lane per wave after a pre-run written into the receipt; if the
    pre-run projects more, move that grid to Totoro (≤150 cores, existing ControlMaster socket, no Duo) without
    asking; run overnight if a wave needs it.
  Waves: continue to the STOPPING RULE without further sign-off; between waves update Mission Control and write
    an informational report.
  Vault: everything under projects/H2-twin/, memory/DECISIONS.md, memory/AGENT_LOG.md, docs/dev-log/plan-actual/,
    the .unlazy ledger; local vault commits (D-37: local-only is landed).
  Model routing: Ada's call — Haiku/Sonnet/Opus per slice, ≤5 live, ≤1 ceiling child per checkpoint; a 7th child
    or a 2nd ceiling child per checkpoint is allowed when the reason is written in the routing receipt.
OPTIONAL REMOTE AUTHORITY: as above; nothing beyond docs-only PRs and issue traffic.
MUST STOP (the only things that wait for Shinichi): any release, tag, version bump, capability-status or
  validation-debt row change, Julia General registration, CRAN submission; any speed/ASReml wording in repo docs,
  README, vignettes, or an issue title framed as a claim; any edit to src/, R/, test/, tests/ of either repo
  (fixes are a separate campaign); DRAC (Duo); `git clean` / `reset --hard` / branch deletion / force-push
  anywhere; anything that would put personal data in a public issue; compute beyond 2 h per lane per wave or 8 h
  per wave in total; evidence the campaign itself is producing wrong findings (two Rose DROPs of the same lane in
  a row ⇒ that lane pauses and is re-briefed; the others continue).
```

## 10. Provenance

Adapted from the vault's DRM-twin campaign (`~/shinichi-brain/projects/DRM-twin/MISSION-CONTROL.md`
and its `updates/` receipts), re-scoped from the compiler-model twins to the quantitative-genetic
twins. Approved plan:
`/Users/z3437171/.claude/plans/read-agents-md-and-docs-dev-log-handover-lexical-falcon.md`
(2026-09-13). Design slot **57** was the next free design-doc number across all refs at plan
approval time (`lane_preflight.sh` verdict, Phase 0.2 of the plan) — the numbering carries no
other meaning.
