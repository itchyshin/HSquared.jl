# Scout — best-in-class algorithms for the production-sparse path (Wave F)

**2026-06-23.** Citation-backed literature pass (3 grounded research agents) requested by
the maintainer ("if you do not have best algorithm and speed — do research and implement;
Takahashi selected inverse, Hadfield & Nakagawa full matrix, etc."). Decisions below feed
Wave F (`docs/design/17-…`). Confirms what is already SOTA, and pins F2.

## 1. Inbreeding & relationship products

- **Keep Meuwissen–Luo (1992)** for all-animals inbreeding (`_meuwissen_luo_inbreeding`,
  F1). It is the textbook-standard, correct, linear-memory method. Faster successors exist
  — Colleau-indirect / **Sargolzaei, Iwaisaki & Colleau (2005)** (1.2–143× over Tier/M–L),
  **Hidalgo et al. (2026)** (8.6 M Holsteins: 103→7.2 s, less depth/family-size sensitive)
  — but at q=300k the Ainv build is **~1 % of fit cost**, so this is **deferred
  optimization, not a correctness gap**. Trigger to revisit: Ainv build > ~5–10 % of fit on
  a real workload. (Logged here, not implemented.)
- **Colleau (2002) indirect `A·v`** (O(n), two sparse triangular solves on the existing
  `A⁻¹`/L⁻¹ factor + D-scale): **high value, but gate on a consumer** — ssGBLUP/single-step
  H, optimal-contribution selection, selection-index PEV, large-pedigree PCA
  (randPedPCA 2025: >10⁴× speed-up), or PCG preconditioning. **Do NOT add to the core REML
  fit** (which absorbs `A⁻¹` directly). ~30 lines when a consumer appears.
- **Correctness caveats to track:** *selfing* (sire==dam) — already validated in F1 (selfing
  chain F=[0,0.5,0.75,0.875], exact vs oracle); *clonal* — zero Mendelian-sampling variance
  breaks the generic two-parent rules → **document as unsupported** in the inbreeding path
  until designed (the repo has `clonal_relationship` but the inbreeding recursion assumes
  meiosis); *deep pedigrees* (M–L degrades past ~12 generations) — add a deep-path test.

## 2. Sparse MME factorization + selected inverse → **this pins F2**

- **Architecture is already the production standard:** supernodal sparse Cholesky
  (CHOLMOD) + **Takahashi/Erisman–Tinney selected inverse** (`src/takahashi_selinv.jl`) for
  PEV/reliability and the REML trace `tr(A⁻¹Cᵘᵘ)`. Takahashi **is** SOTA for the
  diagonal + L+Lᵀ pattern (exact, O(nnz(L))) — keep it.
- **The q=300k super-linear wall is ORDERING, not algorithm class.** Julia's `cholesky(C)`
  defaults to AMD and does **not** reliably trigger CHOLMOD's METIS branch; AMD's fill grows
  faster than nested dissection as q grows (the classic minimum-degree-vs-ND signature).
- **F2 = inject METIS nested-dissection ordering.** What WOMBAT (Meyer) and BLUPF90/YAMS
  (Masuda et al. 2014/15) use at livestock scale. In Julia:
  ```julia
  import Metis
  p, _ = Metis.permutation(C)          # METIS_NodeND
  F = cholesky(C; perm = Vector{Int}(p))
  ```
  Speeds up **both** factorization and the Takahashi pass (both scale with `nnz(L)`).
  **Low risk:** the Takahashi code already reads `ch.p` and is ordering-agnostic (no selinv
  change). Policy: compute `nnz(F.L)` for METIS vs AMD, keep the smaller (reproducing
  CHOLMOD's own min-over-methods that Julia won't trigger). Gate `Metis.jl`/`METIS_jll`
  behind the backend scaffold so the base package stays lean.
- **Second-tier (after the ordering win, only if profiling shows selinv is material):**
  supernodal SelInv (Lin et al. 2011) / inverse-multifrontal (YAMS "up to ~10× on
  inversion") — replaces the simplicial scalar inner loop with BLAS-3 on supernode blocks.
  Bigger effort. **Do NOT** adopt HSS/rank-structured selinv (Xia 2015) — animal-model
  fronts aren't low-rank, and it injects approximation error into PEV. **Do NOT** reach for
  PSelInv/PEXSI unless multi-node.
- **PCG does not replace direct Cholesky for REML** — REML needs the selected inverse +
  `log|C|`, which PCG can't produce. Keep matrix-free PCG strictly for the solutions-only /
  large-genomic EBV lane (Misztal 2017; Vandenplas deflated-PCG 2018).

## 3. Hadfield & Nakagawa "full matrix" → a new capability candidate

- **Most likely meaning:** the dense ("full") phylogenetic covariance among tips vs the
  **sparse augmented-tree ("phantom-parent") inverse** of Hadfield & Nakagawa (2010) —
  the phylogenetic analogue of Henderson's pedigree `A⁻¹` (this is `MCMCglmm::inverseA`,
  `nodes="ALL"` sparse vs `nodes="TIPS"` dense). HSquared.jl has **no phylogenetic path
  yet**, so this is a clean new sibling constructor `phylogenetic_inverse(tree; nodes=:all)`
  feeding the existing REML/Laplace/AI-REML fitters → phylogenetic comparative GLMM +
  phylogenetic meta-analysis. New `experimental`/`partial` capability (Mendel/Falconer +
  Mrode review; external `MCMCglmm`/`ape`/`nadiv` comparator before any `covered`).
- **Secondary reading (relevant to existing `nongaussian_heritability`):** the *multivariate*
  "full" QGglmm integration (de Villemereuil, Schielzeth, Nakagawa & Morrissey 2016,
  `QGmvparams`: `G_obs = Ψ G_ℓ Ψᵀ` via multidimensional cubature over the latent MVN) vs the
  current univariate 1-D Gauss–Hermite. Adopting it closes the standing
  `nongaussian_heritability` debt (no QGglmm/MCMCglmm comparator yet) — highest-leverage
  next step for that limb.

## Key sources
Meuwissen & Luo 1992 *GSE* 24:305; Colleau 2002 *GSE* 34:409; Sargolzaei et al. 2005
*JABG* 122:325; Nilforooshan et al. 2021 *Front. Genet.* 12:655638; randPedPCA 2025 *GSE*;
AMD (Amestoy/Davis/Duff 1996 *SIMAX* 17:886); METIS (Karypis & Kumar); CHOLMOD (Chen et al.
2008 *TOMS* 35); Erisman & Tinney 1975 *CACM* 18:177; SelInv (Lin et al. 2011 *TOMS* 37);
YAMS (Masuda et al. 2014 *JABG* 131:227); WOMBAT (Meyer 2007); Misztal et al. 2017 *animal*
11(5); Hadfield & Nakagawa 2010 *JEB* 23:494 (10.1111/j.1420-9101.2009.01915.x);
de Villemereuil et al. 2016 *Genetics* 204:1281 (10.1534/genetics.115.186536); QGglmm.

## Postscript — measured outcome (2026-06-23)

The F2/METIS recommendation above was **tested and overturned by experiment** on the real
MME (`sim/drac/f2_ordering_experiment.jl`, fir). At q=100k/300k the factorization is
**~0.15 s** and METIS reduces fill by only **~1%** (`nnz(L)` ×1.01) — the half-sib MME has
near-zero fill-in, so AMD is already near-optimal. **METIS was NOT implemented** (it would
optimize a non-bottleneck and add a dependency for ~0 gain). The real q=300k bottleneck was
`fit_ai_reml` running to its 100-iteration cap because the convergence check
(`hypot(score) < 1e-8`) is **not scale-invariant** (the REML score scales with n). **F3**
fixed it with a relative-VC-change criterion: q=300k **36 s/non-converged → 2.3 s/converged**
(15.5×), q=100k 2.8 → 0.88 s. Lesson: the literature correctly describes production practice,
but the *measured* bottleneck here was convergence, not ordering. METIS stays a candidate
ONLY if a deep multi-generation pedigree (real fill-in) re-measures as factorization-bound —
**re-measure before adopting.**
