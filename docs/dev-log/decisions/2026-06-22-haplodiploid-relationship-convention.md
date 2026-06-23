# Decision — haplodiploid additive-relationship convention (J1, derivation + ratification)

Date: 2026-06-22 · lane: Julia engine (`HSquared.jl`) · status: **convention DERIVED
and dual-lens RATIFIED; engine implementation GATED on maintainer ratification (NOT
yet implemented).**

This is the STEP-0 derivation the J1 "LANDMINE" backlog item requires ("DERIVE the
diploidized haplodiploid recursion from a reference + get Mendel/Falconer sign-off
BEFORE implementing"). No engine code ships with this record — it captures the
resolution so implementation, once the maintainer ratifies the scale, is mechanical.

## The problem (why J1 is a landmine)

The design spec (`docs/design/15-backlog-wave-execution-plan.md`, `/tmp/backlog_specs.md`)
proposed, for a Hymenoptera (honeybee) arrhenotokous pedigree — diploid females (sire =
haploid drone, dam = diploid queen); haploid males (drones) from unfertilized eggs (dam
only, no sire) — this recursion + anchor set:

- Female i: `A[i,j] = ½(A[s,j]+A[d,j])`, `A[i,i] = 1 + ½·A[s,d]`.
- Drone i (dam d, no sire): `A[i,j] = A[d,j]`, `A[i,i] = 1`.
- Claimed anchors: father(drone)→daughter = 1; full sisters = 3/4; queen→drone-son = 1;
  queen→daughter = 1/2; drone-brothers = 1/2; **drone self = 1**.

**Two inconsistencies, both confirmed:**

1. The stated female rule gives father→daughter = `½(A[DS,DS]+A[Q,DS]) = ½(1+0) = 0.5`,
   NOT the claimed 1.0 (the contradiction the prior handover flagged).
2. The anchor set is INTERNALLY IMPOSSIBLE. Any inheritance-respecting *per-individual*
   rescaling (a single rescaled `A`, as opposed to a non-diagonal Mendelian-sampling
   reparameterization — the colony `D` carved out below) is a positive diagonal
   congruence `A = S·G·S` of the unique gametic matrix `G = 2θ`.
   Solving for `S` to hit the spec's anchors: drone-self=1 ⇒ `s_D² = 0.5`; full-sisters
   =3/4 & queen→daughter=1/2 ⇒ `s_F = 1`; but father→daughter=1 & queen→son=1 demand
   `s_D·s_F = 1`, while the diagonals force `s_D·s_F = 1/√2`. **Contradiction by √2** —
   no matrix realizes the six anchors at once (Mendel's congruence-impossibility proof).
   The spec mixed the natural `2θ` scale (the female-involving anchors) with a
   diploidized-rescaled male diagonal.

## The resolution (ratified convention: A = 2θ, drone diagonal = 2)

The contradiction DISSOLVES with one correction: the **haploid-drone self-relationship
is 2, not 1.** On the natural numerator scale `A = 2θ` (the companion of the engine's
existing `_numerator_relationship`), the *standard* female averaging rule is correct and
father→daughter = 1 emerges automatically because `A[drone,drone] = 2`:
`½(A[DS,DS] + A[Q,DS]) = ½(2 + 0) = 1`.

**Ratified recursion** (topological order; `s`/`d` = sire/dam indices, 0 = unknown):
- **Female i** (sire = drone, dam = queen): `A[i,j] = ½(A[s,j] + A[d,j])`;
  `A[i,i] = 1 + ½·A[s,d]` (founder female: 1).
- **Drone i** (dam only, no sire): `A[i,j] = A[d,j]`; **`A[i,i] = 2`** (founder drone: 2).

**Verified anchors** (all reproduced by the recursion AND a gametic/coancestry
`A = 2θ` derivation):

| pair | coefficient |
|---|---|
| drone (haploid male) self | 2 |
| queen / worker-female self | 1 |
| drone-father → daughter | 1 |
| queen → daughter | 1/2 |
| queen → drone-son | 1 |
| full sisters (shared drone father + queen) | 3/4 |
| drone-brothers (share queen, no sire) | 1 |
| half-sisters (share queen only) | 1/4 |

**Inter-lens tiebreak — drone-brothers = 1 (not 1/2).** Mendel and Falconer disagreed
on drone-brothers (Mendel: 1; Falconer: 1/2, using θ=1/4). The recursion settles it:
`A[m1,m2] = A[dam(m1),m2] = A[Q,m2] = A[m2,Q] = A[dam(m2),Q] = A[Q,Q] = 1`. So
drone-brothers = 1 (= `2θ` with θ[m1,m2] = 1/2 for two meiotic gametes of a non-inbred
queen). The spec's 1/2 is wrong on the `2θ` scale.

## What does NOT hold (corrections to the spec's test plan)

- **No reduction to `additive_relationship`.** The spec's reduction test (an all-female
  pedigree giving `haplodiploid_relationship == additive_relationship`) does NOT hold
  under the correct convention: a drone is fundamentally non-diploid (diagonal 2, full
  transmission), so whenever males are present the matrices differ; and the guards
  (a known sire must be male) forbid an all-female pedigree with sires. Drop that test.

## Honest fences (both lenses, mandatory for any `partial` shipping)

- **State the scale in the docstring/rows:** "gametic `A = 2θ`; haploid drone self = 2;
  a drone transmits his whole genome so sire→daughter = 1." A "haplodiploid relationship
  matrix" claim without a named scale is a Rose-flaggable over-claim (the literature has
  no single convention).
- **This is a CONSTRUCTION PRIMITIVE, NOT the honeybee-BLUP covariance.** The honeybee
  genetic-evaluation mainstream (Brascamp & Bijma 2014, *GSE* 46:53) keeps a common σ²A
  across castes and carries haploidy in a NON-DIAGONAL Mendelian-sampling matrix `D`
  (full-sib workers share the father's whole genome → correlated Mendelian sampling),
  NOT in a rescaled diagonal. The `2θ` kernel must NOT be fed to `pedigree_inverse` and
  called a breeding-value evaluation. Cite Brascamp & Bijma (2014) as the eventual
  fitting target / comparator; do NOT cite "Smith & Allaire 1985" for the coefficients
  (it is a mate-selection paper invoked only for the gametic-matrix concept; a honeybee
  "Liu & Smith" coefficient paper could not be confirmed).
- **External comparator is standing debt.** The runnable analog is `nadiv::makeS`
  (sex-linked hemizygous), whose default (`ngdc`) is the single-dose scale (hemizygous
  diagonal 0.5) — to confront the `2θ` kernel you must use a dosage-compensated model
  (diagonal 2) and account for the ×2 / √2 scale differences. No off-the-shelf honeybee
  per-individual-A comparator exists.
- **Inbreeding edge cases NOT covered** (inbred queens, diploid males from
  brother–sister matings, male inbreeding) — name as retained debt.

## Ready-to-implement spec (post-ratification)

`haplodiploid_relationship(pedigree::Pedigree, sex; max_relationship_cache = 10_000)`
+ a `(ids, sire, dam, sex)` convenience, mirroring `clonal_relationship`; internal
`_haplodiploid_relationship` holding the ratified recursion above (drone diagonal = 2).
`sex` aligned to `pedigree.ids` (like `clone_of`). Guards: `length(sex) == n`; sex codes
parse to `:female`/`:male`; every male has an unknown sire; a known sire is male and a
known dam is female; `n ≤ max_relationship_cache`. Tests: the hand-checked anchor table
above, an independent direct-formula oracle, symmetry + the female=1/drone=2 diagonals,
the `(ids,sire,dam,sex)` convenience, and the guards. Funnel: a new `partial`
`V3-HAPLODIPLOID` register row (split from `V7-INHERIT`, keep polyploid planned) + a
capability-status experimental row, both carrying the scale + not-BLUP-covariance fence.

## The gate (why no code ships here)

Per the J1 STEP-0 instruction and both lenses, **maintainer ratification of (a) the
`A = 2θ` scale choice with drone diagonal = 2, and (b) the construction-only /
not-the-BLUP-covariance fence is required before the kernel lands.** Mendel + Falconer
have ratified the convention; Rose must audit the eventual claim; the maintainer must
ratify the scale. Until then this is "derived + spec'd, awaiting ratification" — the
plan's sanctioned J1 landing. Open question for the maintainer: if the intended
downstream use is a fitted honeybee animal model, the per-individual `2θ` A is the wrong
object (the field fits the colony model with non-diagonal `D`); scope J1 strictly as a
construction primitive with that limitation stated.

## Lens sign-off

- **Mendel** (`mendel-inheritance-specialist`): congruence-impossibility proof of the
  spec's anchors; ratified `A = 2θ` with drone diagonal = 2; female rule correct as
  written for this scale; Brascamp & Bijma citation; nadiv `makeS` empirically checked.
- **Falconer** (`falconer-quantgen-interpreter`): variance-scale verdict — a drone's
  genic variance is `½σ²A`, represented on `2θ` as diagonal 2; the spec's hybrid is
  non-PSD-coherent (drone self=1 with full maternal transmission has a negative
  eigenvalue); cite Brascamp & Bijma (2014) + the colony model's non-diagonal `D`.
