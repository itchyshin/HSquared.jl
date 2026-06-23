# After-task — J1 haplodiploid relationship convention (derivation + ratification) — 2026-06-22

## Task goal

Backlog slice **J1** (flagged a "LANDMINE"): the haplodiploid additive-relationship
kernel + canon. The slice's STEP-0 instruction is explicit — **DERIVE the diploidized
recursion from a reference and get Mendel/Falconer sign-off BEFORE writing any engine
code.** This task delivers that derivation and ratification as a docs-only landing; the
kernel is deliberately NOT implemented (it claims a capability and is gated on maintainer
ratification, which my self-merge authorization explicitly excludes). `[JL]` lane.

## Active lenses / spawned agents

Two REAL subagents were spawned and named:
- **Mendel** (`mendel-inheritance-specialist`): produced the congruence-impossibility
  proof of the spec's anchor set and ratified `A = 2θ` with drone diagonal = 2.
- **Falconer** (`falconer-quantgen-interpreter`): gave the variance-scale verdict (a
  drone's genic variance is ½σ²A → diagonal 2 on the `2θ` scale; the spec's hybrid is
  non-PSD-coherent) and confirmed the Brascamp & Bijma colony-model fence.

Review lenses (not spawned): Rose (the claim-vs-evidence gate — no capability shipped, so
the audit is "did the docs over-claim?"), Mrode (textbook anchor canon), Noether
(math/spec consistency).

## What I did + the landmine I defused

- **Confirmed the spec is impossible, not merely wrong.** The design spec proposed a
  female averaging rule, a drone rule with **drone-self = 1**, and a six-anchor target.
  Two independent defects: (1) the female rule gives sire→daughter = 0.5, not the claimed
  1.0; (2) more fundamentally, the six anchors cannot be realized by ANY
  inheritance-respecting matrix — they are a positive-diagonal congruence `A = S·G·S` of
  the unique gametic `G = 2θ`, and solving for `S` forces both `s_D·s_F = 1` and
  `s_D·s_F = 1/√2` (a √2 contradiction). This is why J1 was tagged a landmine: trusting
  the spec would have shipped an inconsistent matrix.
- **Derived and ratified the fix.** On the natural gametic scale `A = 2θ` with
  **haploid-drone self = 2**, the standard female averaging rule is correct and
  sire→daughter = ½(2+0) = 1 falls out automatically. Ratified recursion: Female i
  `A[i,j]=½(A[s,j]+A[d,j])`, `A[i,i]=1+½A[s,d]`; Drone i (dam only) `A[i,j]=A[d,j]`,
  `A[i,i]=2`. Every anchor is reproduced by both the recursion and a gametic/coancestry
  derivation (drone-self 2, sire→daughter 1, queen→daughter 1/2, queen→son 1,
  full-sisters 3/4, drone-brothers 1, half-sisters 1/4).
- **Resolved an inter-lens disagreement.** Mendel and Falconer split on drone-brothers
  (1 vs 1/2). The recursion is authoritative — `A[m1,m2]=A[Q,Q]=1` — so drone-brothers
  = 1 on the `2θ` scale; the spec's 1/2 is wrong.
- **Wrote the decision record** (`docs/dev-log/decisions/2026-06-22-haplodiploid-
  relationship-convention.md`): the impossibility proof, the ratified recursion, the
  verified anchor table, the corrections to the spec's test plan (the
  all-female-reduction test does NOT hold and is dropped), the honest fences, the
  ready-to-implement spec (post-ratification), and lens sign-off.

## Files changed (docs-only)

- `docs/dev-log/decisions/2026-06-22-haplodiploid-relationship-convention.md` — NEW;
  the full derivation/ratification record.
- `docs/design/validation-debt-register.md` — V7-INHERIT row updated: the haplodiploid
  canon-gate it named is now satisfied (derived + dual-lens ratified), implementation
  gated on maintainer ratification; status stays `planned`.
- `docs/design/14-program-backlog.md` — J1 🟡 (convention derived + ratified, kernel
  gated).
- `docs/dev-log/check-log.d/2026-06-22-j1-haplodiploid-derivation.md` — NEW check-log
  entry (used the documented `check-log.d/` convention).

NO `src/` change, NO `test/` change, NO `sim/` change, NO `validation_status()` row, NO
capability-status row.

## Checks run and exact outcomes

- **None run, by design** — docs-only; no source, test, or sim file was touched, so
  `Pkg.test()` / `docs/make.jl` are unchanged from the C6 merge (`6ca0ff80`). No
  Documenter pages were added (the decision/check-log/after-task files are dev-log, not
  in the `docs/src` tree), so there is no dead-link surface. CI on the PR will confirm.

## Public claim audit (real `rose-systems-auditor` audit)

A REAL `rose-systems-auditor` subagent audited the branch: verdict **PROMOTE-WITH-CHANGES**.
Rose independently reproduced the impossibility proof (and strengthened it — the spec's
hybrid 3×3 has a negative eigenvalue −0.118, so it fails PSD framing-independently, not
only via the √2 congruence argument), re-derived every ratified anchor on a concrete
9-individual pedigree (all match), confirmed the citations are honest, and confirmed NO
capability is claimed (`src/validation_status.jl` untouched, V7-INHERIT stays `planned`,
no capability-status row). Two required changes + one optional, dispositions:

- **APPLIED** — decision-doc anchor table: split the ambiguous `2 / 1` cell into two rows
  (drone self = 2; queen/worker-female self = 1).
- **APPLIED (optional)** — decision-doc §problem item 2: softened "Any inheritance-
  respecting rescaling" → "Any inheritance-respecting *per-individual* rescaling", carving
  out the non-diagonal colony-`D` reparameterization explicitly.
- **REJECTED (with verification)** — Rose claimed `validation_status()` has 46 rows and the
  after-task's "47" was stale. I verified the ground truth: `test/runtests.jl:174` asserts
  `length(validation) == 47`, C6 (#175) merged with green CI (so main passes at 47), and
  there are exactly 47 row-tuple openers in `VALIDATION_STATUS_DATA` (incl. the H-slice
  additions V6-BETABINOMIAL / V6-PROBIT / V6-NS-H2). **47 is correct; Rose miscounted.**
  Kept "47". (Applying the "fix" would have introduced the stale-count error Rose guards
  against — hence verifying factual Rose claims rather than rubber-stamping them.)

Net: no capability claimed; `validation_status()` UNCHANGED at 47 rows; capability-status
untouched; V7-INHERIT stays `planned`. The decision doc is explicit that this is a
CONSTRUCTION PRIMITIVE (not the honeybee-BLUP covariance) and states the scale, the
comparator debt, and the uncovered inbreeding cases. The one claim — "the convention is
derived and dual-lens ratified" — is backed by the two real subagent sign-offs.

## What did not go smoothly

- The spec was not just imprecise but internally impossible; the time went into proving
  that (the congruence argument) rather than coding. This is the correct outcome for a
  landmine — the prior handover's "J1 proved a spec can be wrong" applies literally.
- Mendel/Falconer disagreed on one anchor; resolved by deferring to the recursion rather
  than to either lens's verbal argument.
- The Rose audit's one factual flag (a 46-vs-47 row count) was itself wrong; caught by
  verifying against the test assertion + green CI + a direct row count rather than applying
  it blindly. Net cost: a few checks; net benefit: no stale-count error introduced.

## Known limitations / retained debt

- **Kernel NOT implemented** — gated on maintainer ratification of (a) the `A = 2θ` /
  drone-diagonal-2 scale and (b) the construction-only / not-BLUP-covariance fence.
- No external comparator yet (`nadiv::makeS` dosage-compensated is the standing analog;
  no off-the-shelf honeybee per-individual-A comparator exists).
- Inbreeding edge cases (inbred queens, diploid males from brother–sister matings, male
  inbreeding) are out of scope of the ratified convention.
- The downstream-use caveat for the maintainer: if the intended use is a fitted honeybee
  animal model, the per-individual `2θ` A is the wrong object (the field fits the colony
  model with non-diagonal `D`); scope J1 strictly as a construction primitive.

## Next actions

1. Commit the docs-only branch, open a PR, self-merge on green CI (no capability claim).
2. **Maintainer decision required** before any kernel lands: ratify (or revise) the
   `A = 2θ` / drone-diagonal-2 scale and the construction-only fence. On ratification,
   implementation is mechanical (spec is in the decision doc) and splits V7-INHERIT into
   a `partial` `V3-HAPLODIPLOID` row + capability-status experimental row.
3. With J1 landed as derived-and-spec'd, the six-slice backlog (H2/H3/H6/H7/C2/C6) is
   complete and the J1 landmine is resolved to the plan's sanctioned state.
