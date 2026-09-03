# 2026-09-03 — V4-FA recovery-substitution disclosure (WOMBAT absent)

**Status: DISCLOSED · NOT AGREE · NOT a covered flip · NOT Rose CLEAN.**  
Lane: `cursor/08-fa-20260903` (WT `~/local-scratch/lanes/HSquared.jl-08-fa-20260903`,
PR [#292](https://github.com/itchyshin/HSquared.jl/pull/292)).  
Evidence tip this note attaches to: **`d8148a3a`**.  
Rose packet: `~/local-scratch/h2-08-fa-rose-packet-2026-09-03.md` (NOT CLEAN).

```
PLATFORM: cursor | LANE: cursor/08-fa-rose-g11-20260903
OTHER LANES: cursor/08-fa Boole freeze (design-54) · cursor/08-fa no-anchor
             (design-55) · cursor/08-ss #295 cite-only · G5 #157/#291 cite-only
Active lenses: Rose (this disclosure) · Ada/Shannon fence
Spawned subagents: none
Current lane: Julia FA #292 — §3 #2 artifact only
```

This is the written **recovery-substitution** that design-41 §3 #2 allows when
no free same-estimand FA REML tool can be run. It is **not** a WOMBAT AGREE
and it does **not** invent comparator numbers from S4.

## 1. Missing tool (measured, not assumed)

WOMBAT is **not installed**. Rechecked 2026-09-03 after S4 PASS, before writing
this note:

| Host | How | Result |
|---|---|---|
| Laptop | `command -v wombat/WOMBAT/wombat64`; common install paths; `mdfind -name wombat` | Not on PATH. Spotlight hit is an unrelated Claude plan file, not a binary. |
| Totoro | ControlMaster attach to `totoro.biology.ualberta.ca` (socket live; no Duo). `command -v`; `find ~ /opt /usr/local /home -maxdepth 4 -iname '*wombat*'`; `module` | Host reachable (`loadavg` 0.13). Binary **absent**. No module system. Home /opt /usr/local /home: no WOMBAT tree. |

S1–S4 after-tasks already said “WOMBAT absent on Totoro PATH.” This note
re-measured that claim. It does not install WOMBAT (S0b: ask before
accounts/cost).

No thin AGREE path was started, because there is nothing to run.

## 2. G11 path used

**Recovery-only. Kind still REML.**

- Estimator kind: REML (`fit_multivariate_reml(...; genetic_structure =
  :factor_analytic)`). Bayesian agreement (MCMCglmm / JWAS) is **not** a
  substitute and is not re-badged here.
- Comparator clause: **not executed.** There is no FA same-estimand REML
  output on disk.
- Recovery clause: the pre-declared S2 gate **did** run, and S4 **PASS**ed.
  That is the substitute named by design-41 §3 #2.

This is **not** the V4-MV-REML design-16 path (b) as written. Path (b) is
“one existing same-estimand REML leg **plus** a passing recovery gate”
(sommer was already on disk for unstructured `G0`/`R0`). FA has **no**
executed same-estimand FA REML leg. sommer unstructured MV is a 0.6
baseline only (S0b: **not** FA parity). Treating S4 as if it sat *on top of*
a missing WOMBAT run would be a fake AGREE.

What this disclosure *does* claim: design-41 §3 #2’s “or an explicitly
disclosed recovery-substitution where no free same-estimand tool exists”
is now a committed artifact. The comparator **debt remains**.

## 3. Banked known-truth S4 (the substitute evidence)

| Item | Live |
|---|---|
| S2 freeze | `eff57e3d`. Cell `t=4 K=1`, `ledermann_slack=4`, `min(ψ̂) ≥ 1e-4` first-class. Seeds `20260914:20260923`. Bar **8/10** `ok_recovery`. Driver blob `370cf697`, SHA-256 `47a1b619e83b468cec28dae57918f755064a32528f16bf775943b8b7e36b4b83`. Not edited after freeze. |
| S3 engine | `3d1de490`. `ψ = 1e-4 + exp(θ)`; slack ≤ 0 refused as a covered-flip cell. |
| S4 run | Totoro, Julia 1.10.0, 1 thread. Fit SHA `3d1de490`. Banked at tip **`d8148a3a`**. **8/10 `ok_recovery` · PASS.** |
| Misses | 20260915 `unclassified` (5000-iter cap, `min(ψ̂)=1.010e-4`); 20260916 `sampling_vs_threshold`. **0 Heywood / 0 optimizer-miss.** |
| Checkpoint | `docs/dev-log/recovery-checkpoints/2026-09-03-v08-s4-fa-d4-k1.md` + `.tsv` |
| Pass objects | Rotation-invariant `G`, `R`, `ψ` only. Loadings are not a pass object (2026-06-19). |

S4 licenses banking known-truth recovery for this cell. It does **not**
license WOMBAT parity, `V4-FA` covered, `cov = fa`, loadings+SE, count 8,
or 0.8.0.

## 4. What WOMBAT would have meant (had the binary existed)

S0b (`~/local-scratch/h2-08-S0b-comparator-recipe-2026-09-03.md`) named
WOMBAT reduced-rank / FA AI-REML as the **primary** same-estimand leg.

A thin AGREE path would have been:

1. Same model: multi-trait animal model, FA genetic covariance
   `G = ΛΛᵀ + Ψ`, unstructured residual `R`, same pedigree / incidence as
   the S2 `d4-k1` cell (or a serialized fixture derived from it).
2. Same estimands: rotation-invariant functionals of `G`, plus `R` and
   interior uniqueness `ψ`. **Not** loadings.
3. Kind: REML vs REML (Meyer AI-REML vs this engine). Pre-declared
   absolute or relative tolerances **before** reading WOMBAT output.
4. One executed run, banked under `comparator/` or a recovery-checkpoint,
   cited from the `V4-FA` row.

That run does not exist. This paragraph is a description of the missing
leg, not a stand-in for its numbers.

## 5. What this does **not** discharge

| Gate | Status after this note |
|---|---|
| design-41 §3 #2 (WOMBAT AGREE **or** written recovery-substitution) | **HOLD** — this file is the substitution. Comparator debt **retained**. |
| §3 #1 S4 PASS | already HOLD (`d8148a3a`) |
| §3 #3 derived estimands | still OPEN |
| §3 #4 textbook / no-anchor | still a blocker on the other FA slice (do not invent here) |
| §3 #5 Darwin SIGN | still a blocker — do not invent |
| §3 #6 Boole `cov = fa` freeze | still a blocker on the other FA slice — do not invent |
| §3 #8 R↔engine parity | still a blocker (R FA planned) |
| Rose CLEAN | **NOT CLEAN.** This note is one artifact, not a re-audit. |

`public_covered_count` stays **7**. Experimental version stays **0.7.0**.
`V4-FA` stays **partial**. No capability-status / `validation_status()`
field-4 edit in this slice (those files are other lanes’ leases).

## 6. Retained comparator debt (word this, do not retire it)

Until WOMBAT (or another independent FA REML lineage: ASReml FA /
equivalent) is installed and an AGREE run is banked:

- do not write “WOMBAT parity”, “external FA REML AGREE”, or
  “same-estimand comparator passed” for `V4-FA`;
- do not treat sommer unstructured or MCMCglmm as that missing leg;
- a later covered flip, if it ever happens, must still name this
  substitution in the covered sentence and keep the comparator in
  `missing`.

## Explicit non-claims

- Not WOMBAT AGREE. Not a forged comparator table.
- Not `V4-FA` covered. Not count 7→8. Not experimental 0.8.0. Not 1.0 /
  CRAN / Julia General.
- Not Rose CLEAN. Not clean-with-limitations.
- Not Darwin SIGN. Not Boole freeze. Not a no-anchor disclosure (separate
  slice).
- S4 8/10 is **not** the old Phase 4B 8/10.
