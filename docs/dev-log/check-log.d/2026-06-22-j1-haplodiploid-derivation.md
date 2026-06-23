# Check Log — J1 haplodiploid relationship convention (derivation + ratification)

## 2026-06-22 — Backlog J1 (LANDMINE): haplodiploid additive-relationship convention

**Docs-only deliverable. No engine code, no capability claim, no test/sim run** —
this is the J1 STEP-0 the backlog requires ("DERIVE the diploidized recursion from a
reference + get Mendel/Falconer sign-off BEFORE implementing"). Landed as the plan's
sanctioned "derived + spec'd, awaiting maintainer ratification" outcome.

- **Landmine confirmed.** The design spec's haplodiploid anchor set is INTERNALLY
  IMPOSSIBLE: any inheritance-respecting rescaling is a positive-diagonal congruence
  `A = S·G·S` of the unique gametic `G = 2θ`; the spec's six anchors force both
  `s_D·s_F = 1` (sire→daughter=1, queen→son=1) and `s_D·s_F = 1/√2` (drone-self=1 with
  the female diagonals) — a √2 contradiction. No matrix realizes them at once. The spec
  ALSO mis-states sire→daughter under its own female rule (gives 0.5, claims 1.0).
- **Resolution (Mendel + Falconer dual-lens ratified).** Adopt the natural gametic scale
  `A = 2θ` with **haploid-drone self = 2**. The standard female averaging rule is then
  correct and sire→daughter = ½(2+0) = 1 emerges automatically. Ratified recursion:
  Female i `A[i,j]=½(A[s,j]+A[d,j])`, `A[i,i]=1+½A[s,d]`; Drone i (dam only)
  `A[i,j]=A[d,j]`, `A[i,i]=2`. Anchors verified by BOTH the recursion and a gametic/
  coancestry derivation: drone-self 2, sire→daughter 1, queen→daughter 1/2, queen→son 1,
  full-sisters 3/4, drone-brothers 1, half-sisters 1/4.
- **Inter-lens tiebreak settled.** Mendel said drone-brothers = 1, Falconer said 1/2
  (using θ=1/4). The recursion is authoritative: `A[m1,m2]=A[Q,Q]=1` → drone-brothers = 1
  on the `2θ` scale.
- **Spec test correction.** The spec's "all-female pedigree ⇒ haplodiploid == additive"
  reduction does NOT hold under the correct convention (a drone is non-diploid:
  diagonal 2, full transmission) and the male-sire guard forbids the construction. Drop it.
- **Honest fences recorded** (mandatory for any eventual `partial`): name the scale in
  every claim; this is a CONSTRUCTION PRIMITIVE, NOT the honeybee-BLUP covariance
  (Brascamp & Bijma 2014 carry haploidy in a non-diagonal Mendelian-sampling `D`); the
  `2θ` kernel must NOT be fed to `pedigree_inverse` and called a breeding-value
  evaluation; `nadiv::makeS` (dosage-compensated) is the standing external comparator
  debt; inbred-queen / diploid-male edge cases uncovered. Cite Brascamp & Bijma (2014);
  do NOT cite "Smith & Allaire 1985" for the coefficients.
- **Funnel:** `docs/dev-log/decisions/2026-06-22-haplodiploid-relationship-convention.md`
  (full derivation, impossibility proof, ratified recursion, anchor table, fences, gate,
  ready-to-implement spec, lens sign-off). `V7-INHERIT` validation-debt row updated to
  record the canon-gate is satisfied (derived + ratified) with implementation gated on
  maintainer ratification; status stays `planned`. doc-14 J1 🟡. **NO `V3-HAPLODIPLOID`
  row, NO capability-status row, NO `validation_status()` change — no capability shipped.**
- **Checks:** none run — docs-only, no source/test/sim touched. (`Pkg.test()` /
  `docs/make.jl` unchanged from the C6 merge; no Documenter pages added.)
- **The gate:** the kernel waits for maintainer ratification of (a) the `A = 2θ` /
  drone-diagonal-2 scale and (b) the construction-only / not-BLUP-covariance fence. On
  ratification, implementation is mechanical (spec in the decision doc); it then splits
  `V7-INHERIT` into a `partial` `V3-HAPLODIPLOID` row + capability-status experimental row.
- `[JL]` lane; no R repo edit. Self-merge authorized (docs-only, no capability claim);
  the kernel itself is explicitly OUT of self-merge authority (it claims a capability →
  needs maintainer ratification).
