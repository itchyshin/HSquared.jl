# Retry-7 phenotype-admission gate — chronology audit + zero-seed Julia preflight

**Date:** 2026-07-17
**Role:** Claude solo (live Totoro execution reassigned to Claude for this gate).
**Scope:** admission gate only. No phenotype drawn, no campaign, `public_covered_count` stays **5**.

## Result: gate PASSES; hard stop preserved

The post-bootstrap state is admissible. The R-owned create-once D0F bootstrap
materialization at the canonical root is chronology-clean, and the bound Julia
harness clears its zero-seed preflight against that root with no mutation. This
is provenance/readiness only — it does NOT activate the R route, promote any
capability, or authorize phenotype generation.

## Chronology audit (live Totoro, read-only)

Canonical root: `/home/snakagaw/hsq_work/retry7-preseal-9f7ed27-97681439-c/d0f`,
bound Julia commit `976814393043d3a4af5ce343d8ac4b05c43eac41`, R repair head
`9f7ed27263b19a486a595f81b1c0b1a8b94702f6`.

- **Hash re-verify — PASS.** preseal `be42dc7d…` , manifest `f53967b5…` ,
  sidecar `ac49fb10…` (sidecar content names the manifest hash); bootstrap rows
  `720000` + header.
- **L1 ordering — PASS.** preseal mtime `19:15:12` precedes bootstrap
  `19:16:55`.
- **L2 create-once — PASS.** Single materialization; deterministic bytes.
- **L3 seed-space isolation — PASS.** Only the bootstrap index materialized; no
  phenotype/attempt/fit namespace present.
- **L4 sole ownership — PASS (with recorded finding).** Five sibling preseal
  roots exist under `hsq_work`. Three (`01ad843`, `f77acc0`, suffixless
  `9f7ed27`) hold only innocuous checkout/test-fixture artifacts. Root `-b`
  (`9f7ed27-97681439-b`) holds the **declared zero-fit SYNTHETIC lifecycle**
  (`schema_version=v07-genomic-recovery-v3-synthetic-run-1`, verdict PASS) with
  its **own synthetic** preseal/manifest hashes (`a1b369f7…` / `087913be…`),
  distinct from the canonical real hashes — no collision. **`-b` is retired
  non-evidence; the sole canonical/real root is `-c`.**
- **L5 no live worker — PASS.** `ps -u snakagaw` shows no
  julia/materialize/retry7/bootstrap process running.

## Environment setup (Claude, live Totoro)

The bound `-c/HSquared.jl` checkout (HEAD = bound commit) had no `Manifest.toml`
and the preseal pins `julia_version=1.10.10`, while only 1.12.6 was installed.

- Installed Julia `1.10.10` via `juliaup add 1.10.10`.
- `Pkg.instantiate()` under 1.10.10 → Manifest generated, Optim + HSquared
  precompiled. `Manifest.toml` is gitignored (`.gitignore:5`), so the checkout
  git tree stayed clean before and after (satisfies the harness
  `_require_git_clean` contract).
- Smoke: `using HSquared` → `LOAD_OK`.

## Zero-seed Julia preflight (read-only; proven no-write)

The `preflight` entrypoint's call graph
(`_manifest`/`_preseal`/`_validate_preseal_only_tree`/`_safe_dir`) contains no
filesystem-write primitive; all writes live in replay/summarize/selftest-tempdir
paths. Flag form is `--key=value` (`_option` matches `--$key=`).

```
julia +1.10.10 --project=. sim/phase2_v07_genomic_recovery_v3_stage_replay.jl --mode=selftest
  → PASS (synthetic only; no official RNG or seed consumed)   exit 0
julia +1.10.10 --project=. sim/phase2_v07_genomic_recovery_v3_stage_replay.jl --mode=preflight --stage=d0f --out-dir=<-c/d0f>
  → PASS (sealed inputs only; no official RNG or seed consumed)   exit 0
```

The preflight validated (under the pinned env): manifest; the full preseal
contract incl. `d0f_bootstrap_seed_base=2043000000` and
`d0f_bootstrap_indices_absent_before_preseal=true`; preseal-only tree; Julia and
sibling-R checkouts git-clean and matching the preseal commits; frozen-D0
root/receipt bindings; env `julia_version=1.10.10`.

## No-mutation verification (post-preflight)

- preseal/manifest/sidecar hashes **byte-identical** to pre-run values.
- No new entry in the canonical root; no attempt/phenotype/fit/adjudication dir.
- `-c/HSquared.jl` git tree clean.

## Hard stop

Gate closed. Phenotype generation and the 576-fit campaign (+ base-R recompute,
exact Julia replay, sealed adjudication, receipt) require separate express
authorization and their own ultra-plan. No phenotype was drawn.
