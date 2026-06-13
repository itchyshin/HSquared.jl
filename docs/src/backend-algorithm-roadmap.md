# Backend And Algorithm Roadmap

This page records the Julia execution strategy behind the broader genomics,
QTL, GLLVM, GPU, and HPC roadmap.

Status: roadmap. `HSquared.jl` currently exposes backend marker types,
`HSControl`, and `backend_info()` as status and control metadata only. It does
not dispatch model fitting to GPU, probe runtime device availability, benchmark
backends, or test CPU/GPU numerical agreement yet.

## Backend Vocabulary

The shared R/Julia backend names are:

| Julia marker | R/backend name | Current status | Intended first use | Not yet |
| --- | --- | --- | --- | --- |
| `CPUBackend()` | `cpu` | selectable metadata only | trusted baseline for every supported model | production sparse optimizer |
| `ThreadsBackend()` | `threads` | selectable metadata only | threaded CPU loops, BLAS-heavy dense work, simulation batches | threaded fitting dispatch |
| `CUDABackend()` | `cuda` | future optional-extension marker | NVIDIA HPC dense marker, factor, and response-matrix workloads | CUDA execution, tests, benchmarks |
| `AMDGPUBackend()` | `amdgpu` | future optional-extension marker | ROCm/HPC accelerator lane after hardware tests | AMD GPU execution, tests, benchmarks |
| `MetalBackend()` | `metal` | future optional-extension marker | Mac development smoke tests and dense accelerator experiments | Metal execution, tests, benchmarks |
| `OneAPIBackend()` | `oneapi` | future optional-extension marker | Intel accelerator experiments where hardware exists | oneAPI execution, tests, benchmarks |
| `AutoBackend()` | `auto` | selection metadata only | later benchmark- and capability-aware default choice | runtime probing, auto selection |

`backend_info()` is the authoritative status diagnostic for the current package.
All backend rows are selectable, execution unavailable, and planned.

## Optional Extension Policy

CPU must remain reliable and always available. GPU packages must not become hard
dependencies for ordinary animal models.

Potential Julia extension layout:

```text
ext/HSquaredCUDAExt.jl
ext/HSquaredAMDGPUExt.jl
ext/HSquaredMetalExt.jl
ext/HSquaredOneAPIExt.jl
```

The extension gate is stricter than type availability:

1. package extension loads;
2. tiny numerical fixture passes;
3. backend-specific diagnostics report device, precision, and memory;
4. CPU/backend agreement test passes at declared tolerance;
5. public claim row and validation-debt row are updated.

Until those gates exist, backend names are roadmap vocabulary only.

## Work Placement

| Work class | Primary backend | Reason | Current status |
| --- | --- | --- | --- |
| Pedigree validation, sorting, ID recoding | CPU | irregular graph and table work | partially implemented on CPU |
| Sparse `Ainv` construction | CPU | sparse pedigree graph structure | implemented CPU utility |
| Symbolic sparse factorization | CPU | irregular sparse structure and mature CPU libraries | planned |
| Small univariate animal models | CPU | transfer overhead dominates accelerator benefit | experimental dense and supplied-variance sparse paths |
| Sparse MME solves | CPU first, hybrid later | sparse direct/iterative solvers need robust preconditioners | supplied-variance solve only |
| Dense genomic matrix operations | GPU-friendly | large dense matrix products and reductions | planned |
| Marker matrix multiplication | GPU-friendly | high arithmetic intensity and batch structure | planned |
| Factor-analytic G matrices | GPU-friendly later | repeated low-rank dense updates | planned |
| GLLVM likelihood blocks | GPU-friendly later | large response matrices and low-rank factors | planned |
| Simulation, bootstrap, cross-validation | GPU-friendly later | independent batches | planned |
| Single-step with sparse `A` and dense `G` | hybrid | sparse pedigree plus dense genomic block | planned |

Do not assume GPU is faster. Backend choice must be benchmarked on the target
model, data shape, precision, and hardware.

## Algorithm Leads

These are development leads, not implemented algorithms unless a capability
row says otherwise.

| Lead | Intended role | First gate | Current status |
| --- | --- | --- | --- |
| Sparse Henderson MME | Phase 1 equation system and BLUP/EBV path | Mrode-style supplied-variance and fitted-model fixtures | supplied-variance solve exists |
| Sparse REML/ML objective | production univariate animal-model likelihood | dense/sparse equality plus Mrode validation | supplied-variance sparse REML identity exists |
| AI-REML | production variance-component optimizer candidate | stable sparse objective, score, information, and step safeguards | planned |
| EM or PX-EM warm starts | robust starting values for fragile variance components | convergence and bias checks on simulations | planned |
| Newton or trust-region refinement | faster local convergence after stable starts | objective, gradient, information consistency checks | planned |
| PCG and block preconditioners | huge mixed-model systems | identical estimand against direct solves on smaller fixtures | planned |
| Takahashi selected inversion | selected inverse entries, PEV, and reliability after sparse factorization | factorization exists and selected entries match dense inverse on tiny fixtures | planned |
| Woodbury and determinant lemma | low-rank G matrices and GLLVM-style likelihood blocks | equality to dense path on small matrices | planned |
| APY approximation | large genomic and single-step relationship inverse approximation | genomic/single-step phase with comparator evidence | planned |

Local reference rule:

- `DRM.jl/src/takahashi_selinv.jl` is an algorithm lead for selected sparse
  inverse entries after `HSquared.jl` has sparse factorizations.
- `GLLVM.jl/src/fit.jl` and `GLLVM.jl/src/structured_schur.jl` are design
  leads for low-rank, profiled, Woodbury, and structured precision machinery.

These are not automatic copy sources. Any code reuse needs explicit license,
provenance, tests, and fit-for-purpose review.

## Numerical Policy

Default precision should be `Float64` for REML and publication-quality variance
components.

`Float32` and mixed precision are later accelerator options for exploratory
huge GLLVM, genomic, and scan workloads. They need explicit agreement tests,
documented tolerances, seed handling, and nondeterminism notes before public
use.

Every backend comparison should record:

- hardware and operating system;
- backend package and version;
- precision;
- records, animals, traits, markers, and nonzeros;
- wall time and memory;
- device memory where relevant;
- log-likelihood, parameter, EBV, heritability, and G-matrix differences;
- convergence status and gradient diagnostics.

## Claim Gates

Allowed wording today:

- backend names are recorded;
- `backend_info()` reports planned/unavailable backend status;
- CPU is the trusted default;
- GPU, APY, AI-REML, Takahashi selected inverse, and GLLVM acceleration are
  roadmap targets.

Blocked wording today:

- GPU execution works;
- backend auto-selection works;
- CPU and GPU agree;
- `HSquared.jl` is faster than ASReml, JWAS, GLLVM.jl, or other comparators;
- APY, AI-REML, or Takahashi selected inversion is implemented;
- genomic/QTL/GLLVM models are fitted.

Rose audit rule: any future backend or algorithm promotion must update tests,
Documenter, capability status, validation debt, the public claims register,
check-log evidence, and an after-task report in the same slice.
