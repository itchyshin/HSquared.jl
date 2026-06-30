# After-task — V5 add-one threshold BROADER-DESIGN sweep: PASS, leg hardened (2026-06-30)

Under the maintainer `/goal` "finish all of v0.5". The #203 add-one gate established type-I control at ONE
design; this slice HARDENS that into a design GRID. **GATE PASS at all three (n, m) points; NOTHING promoted.**
This addresses the "broader designs" calibration item; the two REMAINING v0.5 legs (an external comparator and
the R `gwas()` activation) are structurally out of this Julia lane / blocked — see "Remaining v0.5 legs" below.
Claude solo, branch `feat/2026-06-30-v5-addone-design-sweep`.

## Live phase snapshot

- **As of 2026-06-30 (V5 add-one BROADER-DESIGN sweep PASS — calibration leg hardened, nothing promoted;
  branch `feat/2026-06-30-v5-addone-design-sweep`, PR pending; `main` @ `8d9de557`/#203).**
  Followed the #203 single-design add-one gate PASS. A PRE-DECLARED design-grid sweep
  (`sim/phase5_qtl_addone_design_sweep.jl`; predeclaration committed `fa159abc` BEFORE the run) applied the same
  one-sided-upper (not-anti-conservative) `mean type-I − α ≤ 2·MCSE` criterion across (n, m) ∈ {(200,100),
  (300,200), (500,300)} (10 cold seeds each, 20260940..20260969, nperm=2000, α=0.05) — **PASS at ALL THREE**
  (mean type-I 0.068/0.058/0.061, each within 2·MCSE of α). The conservative add-one rule controls family-wise
  type-I across small/medium/larger designs. STAYS `partial`/`experimental`; `validation_status()` = 48 rows /
  covered 7 / partial 37 UNCHANGED; public-covered FITTING = 1; R `gwas()` wording stays HELD. **v0.5 covered
  STILL owes (i) an external comparator (PLINK `max(T)` / GCTA / GenABEL) and (ii) the R `gwas()`/`marker_scan()`
  activation — doc-18's NEEDS-EXTERNAL and NEEDS-R/BRIDGE [Codex] legs.** START HERE: this report.

## What changed

- NEW `sim/phase5_qtl_addone_design_sweep.jl` (reuses `run_addone_calibration` verbatim across a (n,m) grid) +
  predeclaration `docs/dev-log/recovery-checkpoints/2026-06-30-v5-qtl-addone-design-sweep-predeclaration.md`
  (committed `fa159abc` with RESULT: PENDING → filled with the PASS).
- Evidence APPENDED (status UNCHANGED) to V5-MARKER-THRESHOLD across `src/validation_status.jl`,
  `docs/design/validation-debt-register.md`, `docs/design/capability-status.md`.

## Checks run and exact outcomes

- Sweep: `JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase5_qtl_addone_design_sweep.jl` →
  3/3 design points PASS (means 0.068/0.058/0.061, each ≤ 2·MCSE of α), exit 0.
- `Pkg.test()` → **"Testing HSquared tests passed"** (exit 0).
- `validation_status()` independently = 48 rows / covered 7 / partial 37 — UNCHANGED.
- Documenter: unaffected.

## Public claim audit (Rose)

Real `rose-systems-auditor` audit on the committed slice → **PROMOTE** (clean; one soft non-blocking wording
caveat, applied). Verified INDEPENDENTLY: (1) `git diff fa159abc 2202d5be -- sim/phase5_qtl_addone_design_sweep.jl`
is EMPTY and the included `run_addone_calibration` source is unchanged → no post-hoc relaxation; (2) Rose
**re-ran the sweep** and reproduced GATE PASS to the digit (means 0.068/0.058/0.061); (3) NO status flip —
`validation_status()` independently 48/covered 7/partial 37, V5 stays `partial`, surfaces frame this as
hardening "type-I CONTROL," not a covered/calibrated claim, and the means-above-α point is stated honestly not
hidden; (4) blocker map verified (`which plink plink2 gcta64 gemma` → none; R `gwas()` leg is the Codex/hsquared
lane), and the report nowhere claims v0.5 "covered/finished"; (5) honest-scope fence intact (one LD scheme,
intercept-only, type-I only — no power/LD-architecture claim). Rose's soft caveat (leg-1 "✅ DONE" marginally
stronger than "type-I-control done") was applied verbatim — leg 1 now reads "type-I-control DONE."

## Tests of the tests

- Genuine pre-registration: criterion (one-sided upper, design grid, seeds, nperm) fixed at `fa159abc` before
  any seed ran; no post-hoc relaxation.
- Construction-justified one-sidedness, identical to #203 (the add-one rule targets an upper bound on type-I).
- The per-design means sit slightly above α (0.058–0.068) but within 2·MCSE — a low-power non-rejection of
  "type-I ≤ α", read as "consistent with valid level control across designs," not "exactly calibrated." The
  (200,100) point has the widest MCSE (smaller n), correctly the most variable.

## Remaining v0.5 legs (honest blocker map under the "finish all of v0.5" goal)

v0.5 (QTL) covered requires three legs (doc-18 line 100/120-122). Their true status:

1. **Calibrated genome-wide thresholds (null-DGP sims)** — ✅ type-I-control DONE in this lane: the #203
   single-design add-one gate PASS + this design-grid sweep PASS. Type-I control of the add-one rule is
   established at four designs. (The FULL "calibrated thresholds" leg also entails the external comparator,
   below — so this is the type-I-control half, not the whole leg.)
2. **External comparator (PLINK `max(T)` / GCTA / GenABEL)** — ⛔ BLOCKED in this session. No comparator binary
   is installed (`which plink plink2 gcta64 gemma` → none; matches hsquared #83's recorded blocker). Obtaining
   one requires downloading + running an external binary, which the auto-mode classifier DENIED under the
   general goal — it needs the maintainer's explicit authorization. This is a real external-tooling block, not
   a lane-internal gap.
3. **R `gwas()` / `marker_scan()` activation** — ⛔ OUT OF THIS LANE. doc-18 line 121 marks this NEEDS-R/BRIDGE
   [Codex]; it lives in the `hsquared` R repo, which this Julia lane must not edit. The covered FLIP is gated
   on it (line 120: "calibrated thresholds → R gwas()"). This is a cross-lane Codex handoff + maintainer G10.

**Conclusion:** the Julia engine lane has now taken v0.5's calibration leg as far as it can (single design →
design grid, both PASS). The covered close is NOT achievable from this lane alone — it is gated on an
external-binary comparator (needs maintainer auth) and the R-lane `gwas()` activation (Codex). Nothing here was
promoted; honest status discipline holds.

## Next actions

1. **Maintainer decision: authorize the external comparator?** If yes, download PLINK 1.9 and run `--mperm`
   max(T) on the same NULL design to confirm the genome-wide threshold / add-one p agrees with an independent
   implementation (the NEEDS-EXTERNAL leg). I can execute this immediately given permission.
2. **Cross-lane handoff to Codex/R:** activate `marker_scan()`/`gwas()` in `hsquared` against the now-hardened
   calibration evidence (the NEEDS-R/BRIDGE leg; the covered flip + G10 follow).
