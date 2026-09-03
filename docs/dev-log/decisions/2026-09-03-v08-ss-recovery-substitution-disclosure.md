# 2026-09-03 — V2-SSHINV second-comparator honesty (preGSf90 / blupf90+ absent)

**Status: DISCLOSED · NOT AGREE · NOT a covered flip · NOT Rose CLEAN.**  
Lane: `cursor/08-ss-20260903` (WT `~/local-scratch/lanes/HSquared.jl-08-ss-20260903`,
PR [#295](https://github.com/itchyshin/HSquared.jl/pull/295)).  
Evidence tip this note attaches to: **`6f8e851b`** (Darwin unsigned sheet;
recovery PASS recorded at `0533e9da`).  
Construction AGREE: AGHmatrix::Hmatrix Martini, n=6, τ=ω=1 (`0b03d67e`).  
Recovery gate: n=240, 48/48 PASS, freeze **`8e6e038b`**.  
Gap list: `~/local-scratch/h2-08-ss-flip-gap-2026-09-03.md`.

```
PLATFORM: cursor | LANE: cursor/08-ss-g5-disclosure-20260903
OTHER LANES: cursor/08-fa #292 (WOMBAT substitution already on disk) ·
             cursor:g5-stale-copy #296 holds capability-status ·
             H1/H3 #294 · Codex DRAFT #137/#274 cite-only
Active lenses: Rose (this disclosure) · Ada/Shannon fence
Spawned subagents: none
Current lane: Julia SS #295 — design-41 §3 #2 artifact only
```

This is the written **recovery-substitution / construction-vs-fit** disclosure
that design-41 §3 #2 allows when no free same-estimand *second* tool can be
run. It is **not** a preGSf90 AGREE, **not** a blupf90+ ssGBLUP AGREE, and it
does **not** invent fit-level numbers from the n=240 recovery PASS.

Precedent: FA wrote the same class of note for WOMBAT
(`docs/dev-log/decisions/2026-09-03-v08-fa-recovery-substitution-disclosure.md`
on #292). Same rule, different missing binary.

## 1. Missing tools (measured, not assumed)

`preGSf90`, `blupf90+`, `airemlf90`, and `renumf90` are **not installed**.
Rechecked 2026-09-03 after the n=240 GATE PASS, before writing this note:

| Host | How | Result |
|---|---|---|
| Laptop | `command -v` on `preGSf90` / `blupf90+` / `blupf90` / `airemlf90` / `renumf90`; common install paths; `mdfind -name preGSf90` and `mdfind -name 'blupf90+'` | Not on PATH. Spotlight empty. No `~/blupf90*` / `/Applications/blupf90*` tree. |
| Totoro | ControlMaster attach to `totoro.biology.ualberta.ca` (socket live, dated 31 Aug; no Duo). `command -v`; `type`; `find /opt /usr/local /usr /home /opt/software ~/apps ~/local ~/hsq_work -maxdepth 5` for those exact executable names | Host reachable (`hostname=totoro`, loadavg 0.15). **No binary.** `module` absent. `comparator/blupf90_multitrait` is a README-only scaffold, not an install. Hits named `*blupf90*` are Julia wrapper scripts, not Misztal executables. |

The 2026-09-03 gap list already said “PATH empty here.” This note
re-measured laptop **and** Totoro. It does not install BLUPF90 (owner §5:
ask before accounts/binaries).

No thin AGREE path was started, because there is nothing to run.

## 2. Split the estimands (do not let G3 stand in for G11)

| Leg | Tool | State | Same-estimand? |
|---|---|---|---|
| H / H⁻¹ construction | AGHmatrix::Hmatrix Martini τ=ω=1 | **AGREE** n=6, `max\|Hinv Δ\| = 4.24e-12` (AGHmatrix 3.0.1), packet `comparator/aghmatrix_hmatrix/` | Yes (**construction**) |
| H / H⁻¹ construction #2 | BLUPF90 `preGSf90` | **not provisioned** (laptop + Totoro) | Yes *if* run |
| REML (σ²a, σ²e) | `blupf90+` / `airemlf90` ssGBLUP | **not run** (binaries absent) | Yes (**fit**) |
| REML fallback | this recovery-substitution | **this file** | Allowed when no free same-estimand *fit* tool exists |

AGHmatrix closed **construction**. It is not a REML comparator. Re-badging
that AGREE as fit parity, or treating JWAS/MCMCglmm as REML parity, is
**not allowed**.

## 3. G11 path used

**Recovery-only for the estimator. Kind still REML.**

- Estimator kind: REML (`fit_single_step_reml` on true covariance `H`,
  `G ≠ A₂₂`). Bayesian agreement is **not** a substitute.
- Second-construction / fit-level comparator clause: **not executed.**
  There is no `preGSf90` H-builder output and no `blupf90+` ssGBLUP REML
  output on disk.
- Recovery clause: the pre-declared n=240 gate **did** run, and **PASS**ed
  48/48. That is the substitute named by design-41 §3 #2 for the
  **estimator**. Construction remains on the one executed AGHmatrix leg.

This is closer to the V2-GREML / V4-MV-REML “one same-estimand tool +
passing recovery” pattern than FA’s WOMBAT note was — **except** those
one-tool legs were **fit-level** (`blupf90+` AI-REML). SS’s one executed
external tool is **construction**. The recovery PASS is what gates
(σ²a, σ²e). Treating the AGHmatrix packet as if it were that missing
ssGBLUP run would be a fake AGREE.

What this disclosure *does* claim: design-41 §3 #2’s “or an explicitly
disclosed recovery-substitution where no free same-estimand tool exists”
is now a committed artifact for `V2-SSHINV`. The **fit-level** and
**second-construction** comparator **debt remains**.

## 4. Banked known-truth n=240 (the substitute evidence)

| Item | Live |
|---|---|
| Freeze | `8e6e038b`. Driver `sim/v08_ss_s2_recovery.jl`. SHA-256 `c010249bf46c2824b2c576137731b629b7e3c1da1a33de99c943997e05bd3d86`. Seeds `20265000..20265047`. n=240 half-sib; last gen 50% genotyped; `G = A₂₂ + 0.05 I` (same estimand as the AGHmatrix packet, **not** VanRaden); τ=ω=1, blend=ridge=0. Not edited after freeze. |
| Result | Totoro, Julia 1.10.0, 1 thread. **48/48 converged. GATE PASS.** Banked at tip **`0533e9da`**. |
| σ²a | mean 1.0441 vs 1.00; bias +0.0441; MCSE 0.0516; \|bias\|/MCSE 0.86 |
| σ²e | mean 1.4586 vs 1.50; bias −0.0414; MCSE 0.0466; \|bias\|/MCSE 0.89 |
| h² | reported 0.4147 vs 0.40; **not a PASS object** (design-41 §3.3) |
| Checkpoint | `docs/dev-log/recovery-checkpoints/2026-09-03-v08-ss-n-recovery-gate-predeclaration.md` |
| Raw | `totoro:~/hsq_work/results/v08_ss_s2_n240_8e6e038b/` |

PASS = no detectable across-seed bias. **Never “unbiased”.** It does **not**
license preGSf90 parity, blupf90+ ssGBLUP parity, `V2-SSHINV` covered,
count 8, or 0.8.0.

## 5. What preGSf90 / blupf90+ would have meant (had the binaries existed)

A thin same-estimand path would have been:

1. **Construction #2 (`preGSf90`):** same n=6 Martini defaults (τ=ω=1,
   blend=ridge=0), same `A`/`G`/genotyped set as
   `comparator/aghmatrix_hmatrix/`. Pre-declare `max|Hinv Δ|` / Frobenius
   tolerances **before** reading `preGSf90` output. Bank under
   `comparator/` or a recovery-checkpoint.
2. **Fit (`blupf90+` / `airemlf90` ssGBLUP):** same estimands (σ²a, σ²e)
   as `fit_single_step_reml` on a cheap identified fixture (not n=6).
   Kind: REML vs REML. Pre-declared absolute or relative tolerances
   **before** reading BLUPF90 output.

Those runs do not exist. This paragraph is a description of the missing
legs, not a stand-in for their numbers.

## 6. What this does **not** discharge

| Gate | Status after this note |
|---|---|
| design-41 §3 #2 (2nd comparator AGREE **or** written recovery-substitution) | **HOLD** — this file is the substitution. Fit-level / 2nd-construction debt **retained**. |
| §3 #1 n≫6 recovery PASS | already HOLD (`8e6e038b` / `0533e9da`) |
| §3 #3 derived estimands (h² identity + locked citation) | **FENCED 2026-09-03** — `docs/dev-log/decisions/2026-09-03-v08-ss-h2-fence.md`. h² reported, not claim-gated. Identity+citation still OPEN if a later sentence names h² as covered. |
| §3 #4 textbook / no-anchor | already HOLD (Mrode Ch.11 NO-ANCHOR on the AGHmatrix packet) |
| §3 #5 Darwin SIGN | unsigned sheet on disk (`6f8e851b`); still no ink — do not invent |
| §3 #6 Boole `single_step()` freeze | **FROZEN 2026-09-03** — `docs/design/56-single-step-grammar-freeze.md` (ordinary defaults; maintainer nod still pending) |
| §3 #8 R↔engine parity | still OPEN (R already opt-in partial; element-wise catch-up owed) |
| Rose CLEAN | **NOT CLEAN.** This note is one artifact, not a re-audit. |

`public_covered_count` stays **7**. Experimental version stays **0.7.0**.
`V2-SSHINV` stays **partial**. No capability-status / `validation_status()`
field-4 edit in this slice (`capability-status.md` is another lane’s lease;
a missing-string edit is not a flip and is not done here).

## 7. Retained comparator debt (word this, do not retire it)

Until `preGSf90` and/or `blupf90+` (or another independent ssGBLUP REML
lineage) is installed and an AGREE run is banked:

- do not write “preGSf90 parity”, “blupf90+ ssGBLUP AGREE”, “fit-level
  comparator passed”, or “two construction tools agree” for `V2-SSHINV`;
- do not treat AGHmatrix construction AGREE as REML parity;
- do not treat JWAS / MCMCglmm as that missing reml leg;
- a later covered flip, if it ever happens, must still name this
  substitution in the covered sentence and keep `preGSf90` / `blupf90+`
  in `missing`.

G7 (τ/ω/blend/ridge beyond defaults) stays **retained debt**. The claim
fence remains τ=ω=1, blend=ridge=0.

## Explicit non-claims

- Not preGSf90 AGREE. Not blupf90+ ssGBLUP AGREE. Not a forged comparator table.
- Not `V2-SSHINV` covered. Not count 7→8. Not experimental 0.8.0. Not 1.0 /
  CRAN / Julia General.
- Not Rose CLEAN. Not clean-with-limitations.
- Not Darwin SIGN (unsigned sheet only). Boole ordinary-default freeze is a later #295 commit, not this file.
- AGHmatrix `COMPARATOR: AGREE` remains **construction only**.
- The n=240 48/48 PASS is **not** a second H-builder.
