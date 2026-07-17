# After-task — Retry-7 phenotype-admission gate (chronology audit + zero-seed preflight)

## 1. Goal

Close the Retry-7 phenotype-admission gate (authorized via `/goal`): produce a
recorded, repo-visible gate verdict — chronology audit + zero-seed Julia
preflight — with a hard stop before phenotype admission. No phenotype, no
campaign, `public_covered_count` stays 5.

## 2. Implemented

- Rose read-only pre-admission audit (ADMISSIBLE) and live-Totoro chronology
  audit L1–L5 (all PASS).
- Environment unblock: installed Julia `1.10.10` (preseal-pinned) via juliaup;
  `Pkg.instantiate()` the bound `-c/HSquared.jl` checkout; smoke `using HSquared`
  → LOAD_OK; git tree stayed clean (Manifest gitignored).
- Ran the zero-seed Julia preflight against the canonical `-c/d0f` root:
  `--mode=selftest` PASS and `--mode=preflight --stage=d0f` PASS ("sealed inputs
  only; no official RNG or seed consumed"), both exit 0.
- No-mutation verification: preseal/manifest/sidecar hashes byte-identical;
  no new artifacts; checkout clean.
- Recorded the verdict in a check-log entry; refreshed the AGENTS.md snapshot;
  banner-superseded the Codex handover; committed docs-only; Rose final claim
  audit → PROMOTE.

## 3a. Decisions and Rejected Alternatives

- **Ran preflight against the canonical root directly** (not a scratch copy) —
  rejected the copy because the call graph was proven write-free
  (`_manifest`/`_preseal`/`_validate_preseal_only_tree`/`_safe_dir` + verify
  helpers contain no filesystem-write; writes live only in
  replay/summarize/selftest-tempdir).
- **Installed 1.10.10 rather than running under 1.12.6** — the preseal
  `_validate_environment` pins `julia_version=1.10.10`; no alternative.
- **Corrected flag form to `--key=value`** — the arg parser matches `--$key=`;
  space-separated flags were silently ignored (caught by smoke).
- **Claude executed the live legs** — user explicitly reassigned live execution
  (normally Codex's lane); confirmed via AskUserQuestion before the heavier env
  setup.
- **Deferred the 576-fit campaign** — unauthorized; fenced for its own ultra-plan.

## 4. Files Touched

- `docs/dev-log/check-log.d/2026-07-17-retry7-admission-gate-preflight.md` (new)
- `docs/dev-log/handover/2026-07-17-codex-handover.md` (new earlier this session; superseded-banner added)
- `docs/dev-log/after-task/2026-07-17-retry7-admission-gate-preflight.md` (this file)
- `AGENTS.md` (Live Phase Snapshot replaced)
- `docs/dev-log/phase-snapshot-archive.md` (prior snapshot archived verbatim)
- No `src/`, `test/`, or `docs/design/capability-status.md` changes.
- Totoro-side (not in repo): `juliaup add 1.10.10`; `Manifest.toml` generated in
  the `-c/HSquared.jl` deploy (gitignored; not committed anywhere).

## 5. Checks Run

- `juliaup add 1.10.10` → installed; `julia +1.10.10 --version` → 1.10.10.
- `Pkg.instantiate()` → INSTANTIATE_OK (Optim + HSquared precompiled).
- `using HSquared` → LOAD_OK.
- `--mode=selftest` → PASS, exit 0.
- `--mode=preflight --stage=d0f --out-dir=<-c/d0f>` → PASS, exit 0.
- Post-run hashes: preseal `be42dc7d…`, manifest `f53967b5…`, sidecar
  `ac49fb10…` — unchanged; `-c/HSquared.jl` git clean.
- `bash tools/preamble_cap.sh` → CAP OK (1 snapshot entry).
- Rose final claim audit (actual subagent) → PROMOTE.

## 6. Tests of the Tests

The preflight is itself the contract test: it fail-closed on the wrong Julia
(package load error under 1.12.6) and on the wrong flag form (`--stage is
required`) before I corrected each — evidence the harness's guards actually
fire rather than passing vacuously. The selftest additionally exercises the
validators against a mutated tempdir sandbox (`_must_fail("checksum")`), proving
the checksum/tree validators reject tampering.

## 7a. Issue Ledger

- **Finding (recorded, not a defect):** 5 sibling preseal roots exist; `-b` holds
  the declared zero-fit SYNTHETIC lifecycle with its own distinct synthetic
  hashes — retired non-evidence, no collision with canonical `-c`. Recorded in
  the check-log.
- **Env gap (resolved):** the `-c` deploy was never instantiated for the pinned
  Julia; resolved by install + instantiate.
- No open issues from this gate.

## 8. Consistency Audit

Walked the neighbourhood: confirmed `public_covered_count` still 5 and the R
no-control route still not activated (`docs/design/capability-status.md:112`);
AGENTS snapshot matches the check-log; prior snapshot archived verbatim; Codex
handover carries a do-not-re-run banner; commit is docs-only; working tree
carries only the declared carried-over protected paths (untouched). The other
four sibling roots checked for competing bootstrap/phenotype output — only `-b`
had synthetic material, and it is distinct-hashed.

## 9. What Did Not Go Smoothly

- First preflight attempt failed at package load (Julia 1.12.6 vs pinned 1.10.10,
  no Manifest) — an environment gap, not a contract failure.
- Second attempt failed on flag form (`--mode selftest` ignored; parser wants
  `--mode=selftest`). Both caught by smoke-first and reading output immediately.
- Subagent-spawn classifier had a transient outage early, so the pre-admission
  Rose pass ran as the review lens; the final Rose audit ran as an actual
  subagent (PROMOTE).

## 10. Known Residuals

- The live PASS is repo-recorded, not independently re-runnable from the repo
  alone (it depends on the Totoro deploy) — expected for live evidence.
- The next arc (phenotype generation + 576-fit campaign + replay + adjudication)
  is deferred and unauthorized; needs express authorization and its own
  ultra-plan.

## 11. Team Learning

- Loaded/shaped by: the codex-handover plan, AGENTS.md hard-stop discipline, the
  Rose claim-vs-evidence gate, and the smoke-first guardrail (which caught both
  the env and flag-form failures before any wasted campaign compute).
- Reusable: the bound Julia harness exposes read-only `--mode=selftest` and
  `--mode=preflight --stage=d0f --out-dir=<root>` (flag form `--key=value`) that
  validate the full sealed-input contract with zero RNG — the correct admission
  gate before any phenotype draw.

Memory receipt: loaded and applied the codex-handover plan, AGENTS.md hard-stop
discipline, the Rose claim-vs-evidence gate, the smoke-first guardrail (caught
the Julia-version and flag-form failures), and the Totoro passwordless-socket
runbook. The evidence-first "repo state is truth" rule shaped every verdict.

Golden Set: not in scope — this gate is a Julia-lane provenance/readiness check,
not a statistical estimator change; no known-mistake regression class applied.

## 12. Cross-Product Coverage

Julia-lane (HSquared.jl) only. The R twin (`hsquared`) owns the D0F materializer
and preseal; this gate consumed its sealed outputs read-only and made no R-lane
change. No cross-twin contract was altered.

Cross-cutting flags touched — **genomic engine / REML / D0F-provenance**. This
arc COVERS: the read-only zero-seed preflight contract (manifest, preseal incl.
`d0f_bootstrap_seed_base`/`bootstrap-indices-absent`, preseal-only tree,
git-clean bound Julia+R checkouts, env pin) against the canonical `-c/d0f` root,
plus the chronology audit of the sealed bootstrap-index materialization.

It **does NOT cover**: phenotype generation; the 576-fit official campaign; the
base-R recompute or exact Julia replay of any fit; sealed adjudication or receipt
minting; activation/merge/release of the ordinary no-control R route; production
sparse genomic fitting, APY, `V2-GRM`/`V2-GINV`, or calibrated intervals. The
R-public surface `public_covered_count` is unchanged at 5 and is NOT advanced by
this gate.
