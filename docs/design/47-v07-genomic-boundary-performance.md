# 0.7 genomic boundary performance-localization amendment

**Status:** original preregistration frozen before profiling or implementation at
commit `457b6baf`; Amendment 1 added after local unit implementation but before
any discovery profiling; Amendment 2 records a post-discovery serialization
defect without changing an equivalence threshold. Independent numerical/performance,
preregistration/evidence, and R-contract reviews of the original freeze returned
`CLEAN`; Amendment 1 is reviewed separately below. This is an engineering study
on already-open discovery data, not recovery evidence and not authority to
activate the R route.

**Depends on:** docs 44--46 and the negative endpoint recorded in
`docs/dev-log/recovery-checkpoints/2026-07-13-v07-genomic-boundary-holdout.md`.
Those documents remain unchanged and binding.

## Question and endpoint

The doc-46 candidate matched the independent oracle on all 240 spent holdout
datasets and improved 30 default failures without a loss. It nevertheless failed
the conjunctive gate because `n120_m600_r050` had a candidate/default p95 runtime
ratio of 5.991, above the frozen 3x limit.

This amendment asks whether output-equivalent implementation changes can remove
that overhead without changing the statistical rule, result contract, failure
behavior, or public claim. The engineering endpoint is a newly sealed candidate
that:

1. passes a stricter 2.5x discovery runtime screen in every frozen cell;
2. agrees with the doc-46 reference and independent oracle;
3. passes a fresh untouched five-cell holdout under the original 3x gate; and
4. only then permits the nine-cell public-R recovery campaign to resume.

The 240 offsets `5001:5048` are spent. They may not be read, profiled, summarized,
or used to choose or revise this candidate.

### Amendment 1: retain sparse endpoint result assembly

**Frozen 2026-07-13 after unit implementation and before any discovery profiling.**
The deterministic `boundary_fixture(:upper)` in the testset `v0.7 genomic
closed-boundary resolution (doc 46)` (`test/runtests.jl`) exposed a numerical
distinction that the original preregistration had treated as algebraically
invisible. In one local environment -- Julia 1.10.0, Darwin/aarch64, ILP64
OpenBLAS -- at the `1 - 1e-7` epsilon representation, the eigen and sparse-MME
likelihoods differed by `9.788305277425024e-10` per observation and the fixed
effect by `1.1325918709962087e-11`. At the ordinary interior optimum and all four
frozen finite-difference perturbations, likelihood agreement was at most
`3.552713678800501e-16` per observation and fixed-effect agreement was at most
`8.131192650733818e-18` in that environment.

The upper-endpoint difference is consistent with floating-point cancellation in
the frozen sparse-MME determinant identity; the unit comparison does not by
itself establish which representation is more accurate. Replacing the frozen
sparse reported value with the distinct eigen value would violate this arc's
output-equivalence purpose. Therefore endpoint result assembly remains on
`sparse_reml_loglik`; the reused eigen context is eligible only for
ordinary/rescued interior validation. The four central-
difference evaluations and step remain unchanged. Endpoint output equivalence is
still tested against the reference implementation, rather than by requiring an
unused eigen endpoint evaluator to reproduce sparse cancellation. No discovery
dataset, spent holdout row, or reserved fresh seed was read to make this
amendment.

### Amendment 2: serialize the production boundary ratio

**Frozen 2026-07-13 after discovery v3 failed verification and before the
corrected implementation or any replacement discovery run.** Discovery v3 was
bound to candidate commit `a4729040ba15836c5d45d69787fea4abf076497d`
and driver SHA-256
`2db2ffd71109cc8898cced13688f692430af8426ba9011aedecc3daa7b06a13f`.
All ten cell/scope summary timing gates passed, including the formerly failing
`n120_m600_r050` control ratio (`1.1152031850317943`), but the gate reported
only 48/58 equivalent datasets. The validated v3 summary hashes are:

- equivalence: `6063bf5c8f97f8a8f28b47499e579a3bf173cb92074537d41314d9d830a82eb7`;
- timing: `7cea7894fb8bd229bfe9cb74abbcb8e526b3f3843cacda17355995d2bf096fbd`;
- gate: `034954ce073cbf143151734bbec58692ecc6dae9a8e2150e271f013f02c64996`.

The immutable local evidence remains at
`/home/snakagaw/hsq_work/v07_boundary_performance_20260713/results/discovery-v3/`.
The ten false rows had no status, reason, convergence, termination, or
profile-ratio mismatch. Their largest reference/candidate derived numerical-ratio
difference was `1.3234889800848443e-23`; the reconstructed values differed from
the canonical endpoint by zero to two ulps and therefore failed the exact
semantic gate. Their largest component difference was
`8.8817841970012523e-16`, likelihood difference per observation was
`4.7369515717340012e-16`, and derivative difference was
`7.1054273576010019e-10`; those three were inside their frozen tolerances. One false row had
identical reference and candidate scientific-result digests. The defect was in
the profiler's result serialization: it reconstructed `numerical_ratio` as
`sigma_g2 / (sigma_g2 + sigma_e2)` after the epsilon components had been
multiplied, introducing zero-to-two-ulp drift, while the exact semantic field
already exists as `result.boundary.numerical_ratio`.

The correction is to serialize `boundary.numerical_ratio` directly. Exact
endpoint comparison remains exact; no equivalence or timing tolerance changes.
The pre-existing total-variance and derived-ratio arithmetic-consistency checks
remain unchanged. V3 is preserved as `VERIFIER_INVALID`, never re-labelled
PASS. Because
the result preimages, digests, driver SHA, and candidate commit change, all 870
discovery attempts must be rerun under a new create-once admission. The
replacement discovery packet schema is
`v07-genomic-boundary-performance-v2` and must bind this Amendment 2 commit and
SHA-256 separately from the original freeze and Amendment 1. Mutation tests must
show that identical endpoint records are reflexive, that replacing the canonical
epsilon with `prevfloat` or `nextfloat` fails exact comparison, and that the
component-derived adjacent Float64 cannot substitute for the production boundary
field. The spent holdout and reserved fresh seeds remain prohibited.

### Amendment 3: bind the selected candidate and close the packet-identity tolerance

**Frozen 2026-07-13 after the complete discovery-v4 rerun and before the
create-once fresh-holdout seal or any offset-6001 dataset was generated.** The
`v07-genomic-boundary-performance-v2` replacement discovery bound candidate commit
`fc9d39df650b20aa09d769d9f9528eed1b606f1e`, performance-driver SHA-256
`046eeee7e22032dafd90e0601ac9c688f30f901468e3f7fff269a7bafebc1397`,
and the unchanged 58-dataset discovery digest
`33c31a474fc2f0e996d3bd6489a53d055cc753727b69f0625fc30811777c7caf`.
The frozen summarizer returned `DISCOVERY_SELECTION_PASS`, and the separate full
validator returned `discovery profiler validation PASS`: 870 attempted timings,
58/58 scientific equivalences, no error class, and all ten cell/scope timing gates green. The
selected discovery-v4 summary hashes are:

- equivalence: `1e5217d9f12d57ada0e6c9b0b8b66585bf960a6991e897df3361b10eb65caf25`;
- timing: `e1581626c588b6d65240f5a35fbac0ebf4ed442210de15ad2157d29345480101`;
- selection gate: `62bd5f2016a00289b66a6d30cbc0ed6b4917d6b561b735c48daedca7a5e548c6`;
- admission lock: `d7783c84e0ea8d3824c7c9a98dc8e51daef4bf4caa7e4427d83c5f67d246501b`;
- summary lock: `d73b73245985617a48cbbdb31ffa8afa65edb01d6cb26a0d862cdcc506a7180a`;
- sorted digest of all 870 raw attempt lock files:
  `daa0353237ef00e62c286cb15534a847413f3fe597fdb511aed9f062e035e81a`.

The raw-lock aggregate preimage is exactly 870 UTF-8 lines, one for each
`attempts/**/files.sha256.tsv`, encoded as
`relative_path<TAB>sha256(file bytes)<LF>` and bytewise sorted by relative path
before SHA-256. Paths are relative to the discovery-v4 output root and use `/`
separators. No sidecar or result file is substituted for its enclosing raw lock.

The formerly failing `n120_m600_r050` matched-control p95 ratio is
`1.1222112441902519` versus default and `0.92806565212558356` versus the
reference boundary wrapper. This is engineering-selection evidence only; it is
not recovery or public-capability evidence.

Doc 47 originally required the v2 packet readers to verify the `Q*K` identity
“within the frozen tolerance” without naming that tolerance. The missing value
is now frozen as

```text
maximum(abs.(Q * K - I)) <= 1e-10
```

using the deserialized packet matrices in their sealed ID order. Julia and the
independent base-R reader must both recompute this quantity, the ID-order hash,
the `K_lambda` hash, and the `Q_lambda` hash. Changing `1e-10`, omitting either
matrix, trusting metadata instead of recomputing the hashes, or accepting a
row/column permutation must turn the v2 gate red. This amendment changes no
estimator, timing threshold, scientific tolerance, seed, or public claim. The
fresh offsets `6001:6048` remained unopened when it was written.

## Frozen reference and unchanged contracts

The scientific reference is Julia commit
`ecc058f380be71058c9cfde373c345ab7a2f6aba`. Later merged changes that repaired
launcher argument wiring, fixed-effect rank fail-closure, cross-version test
fixtures, documentation, and evidence do not change the reference likelihood or
boundary rule.

The following remain byte-for-byte or value-for-value unchanged:

- Gaussian REML, one genomic random intercept, identity `Z`, full-rank `X`;
- sample-frequency VanRaden1 marker construction and ridge `0.01`;
- canonical marker and supplied-`Ginv` routing through the same precision;
- grid `0:0.0025:1`, refinement tolerance `1e-12`, tie tolerance `n*1e-10`;
- derivative step `1e-6`, KKT tolerance `1e-8` per observation;
- endpoint adjacency and numerical MME epsilon `1e-7`;
- the `n <= 2000` dense limit and every doc-46 fail-closed precondition;
- exact endpoint versus epsilon-representation semantics;
- suppression of boundary uncertainty, GEBV, PEV, reliability, and accuracy;
- genomic variance-ratio wording on the declared `K_lambda` scale; and
- every public/default-route, capability, count, G10, and release hold.

The optimized code may not branch on cell, seed, role, truth, oracle class, or a
post-hoc runtime threshold. No public optimizer control or Julia export is added.

## Allowed discovery corpus

Use exactly the 58 doc-45 discovery datasets already materialized under:

```text
/home/snakagaw/hsq_work/v07_localization_20260712/results/discovery-5d14acd1023d
```

They comprise 29 historical engine failures and their 29 preregistered matched
controls across the five frozen cells. Before profiling, verify:

- `discovery_manifest.tsv` SHA-256
  `c1f5e1a284ed815a4457ac214372fb37382ade07fef3eb4abce331343bdd820a`;
- discovery digest
  `33c31a474fc2f0e996d3bd6489a53d055cc753727b69f0625fc30811777c7caf`;
- all packet sidecars, file sets, roles, seeds, and marker/ID/kernel hashes; and
- 58 independent-oracle outputs with no unresolved classification.

No other pilot, confirmation, holdout, or generated dataset may guide the
implementation. Discovery results remain permanently excluded from doc-44 G5/G6
recovery summaries and all public claims.

## Performance mechanisms in scope

Only output-equivalent implementation mechanisms are eligible:

- reuse an already validated precision factorization or eigendecomposition;
- reuse preallocated profile workspaces;
- remove repeated matrix/vector allocation and repeated small factorizations;
- batch or specialize profile evaluation when the generic and specialized paths
  retain the same formula and tolerances;
- evaluate interior validation from the already-built eigen context rather than
  rebuilding the sparse MME when numerical equivalence is demonstrated; and
- avoid repeated result-independent conversions or hashes within one fit.

Changing the grid, reducing the 401 points, loosening optimization or scientific
tolerances, skipping closed-domain classification, weakening provenance checks,
or changing the AI estimator is out of scope. An optimization that changes a
status, reason, scientific endpoint, tie/KKT outcome, public field, or fail-closed
decision is ineligible even when faster.

## Component profiler

The profiler is diagnostic. Uninstrumented whole-wrapper timing selects a
candidate; component timing and allocation counts only explain the mechanism.

For `reference_boundary` and `candidate_boundary`, write one immutable component
row for each dataset, timed repeat, and frozen component. Do not invent
inapplicable component rows for `default_ai`. The component schema is:

```text
schema_version
cell_id
seed
role
implementation_id
repeat_id
timed_order
component
backend
call_count
elapsed_ns
allocated_bytes
gc_time_ns
marker_hash
id_hash
kernel_hash
precision_hash
result_digest
error_class
```

`result_digest` is the one canonical scientific-result digest for that
dataset/implementation and is repeated unchanged on every component and selection
row. File/row sidecars, not `result_digest`, detect partial writes or row mutation.
Cross-implementation floating-point agreement is decided by the explicit numerical
rules below.

Freeze the component vocabulary:

```text
precheck
ai_fit
q_to_k
eigendecomposition
rotation
grid_401
refinement
endpoint_derivatives
classification
interior_validation_fd
final_likelihood_and_result_assembly
candidate_total
```

`candidate_total` includes precheck, unchanged AI, profile construction and
evaluation, classification, and final likelihood/result assembly. Dataset loading,
packet validation, compilation warm-up, TSV writing, independent-oracle work, and
R result construction are outside the timer. There is no prediction-assembly
component in this Julia holdout path: boundary predictions are suppressed and the
old timer did not include `_fit_row` or R payload assembly.

All component rows except `candidate_total` are exclusive; `candidate_total` is
the inclusive authoritative wrapper timer. `precheck` excludes `q_to_k`,
`eigendecomposition`, and `rotation`. `grid_401` records `call_count=401` ratio
evaluations even if one batched helper executes them. `interior_validation_fd`
records the number of unprofiled likelihood evaluations, not helper invocations:
four for ordinary interior validation, eight when the candidate also validates a
rescued interior, and zero for an endpoint. Refinement, endpoint derivatives, and
classification are exclusive rows. Component rows must be nonnegative and
complete. `final_likelihood_and_result_assembly` records its actual backend
(`sparse_mme`, `eigen_context`, or `none`) and may have `call_count=0` only when
the production wrapper performs no final likelihood rebuild. Any removed sparse
rebuild requires the explicit sparse/eigen parity gate below. `candidate_total`
still includes every operation the production wrapper actually performs. Component
totals may not replace uninstrumented selection timing in any decision.

Separately write one uninstrumented selection row for every dataset, repeat, and
implementation in `{default_ai, reference_boundary, candidate_boundary}`:

```text
schema_version cell_id seed role repeat_id order_index timed_order
implementation_id elapsed_ns allocated_bytes gc_time_ns marker_hash id_hash
kernel_hash precision_hash result_digest error_class
```

An error or slow row remains in this table and denominator.

Before writing profiler/timing rows, compute one `scientific_result_v1` digest per
dataset and implementation. Its exact ordered preimage fields are:

```text
digest_version status reason converged termination profile_ratio numerical_ratio
t_hat profile_loglik d0 d1 sigma_g2 sigma_e2 marker_hash id_hash kernel_hash
precision_hash relationship_source relationship_method allele_frequency_source
ridge relationship_scale
```

Encode them as UTF-8 `field=value\n` lines in that order and SHA-256 the bytes;
the digest field itself is excluded. Finite floats use `%.17g`, missing values use
`NA`, booleans use lowercase `true`/`false`, and strings are literal UTF-8 with
tab/newline forbidden. `default_ai` uses digest version `default_ai_result_v1` and
encodes all inapplicable boundary fields as `NA`. These digests identify result
preimages; sidecars own file integrity and the explicit equivalence rules own
cross-implementation comparison.

Write one equivalence row per dataset with frozen schema:

```text
schema_version cell_id seed role marker_hash id_hash kernel_hash oracle_class
reference_precision_hash candidate_precision_hash
reference_relationship_source candidate_relationship_source
reference_relationship_method candidate_relationship_method
reference_allele_frequency_source candidate_allele_frequency_source
reference_ridge candidate_ridge reference_relationship_scale
candidate_relationship_scale
reference_status candidate_status reference_reason candidate_reason
reference_converged candidate_converged reference_termination candidate_termination
reference_profile_ratio candidate_profile_ratio reference_numerical_ratio
candidate_numerical_ratio reference_t_hat candidate_t_hat reference_profile_loglik
candidate_profile_loglik reference_d0 candidate_d0 reference_d1 candidate_d1
reference_sigma_g2 candidate_sigma_g2 reference_sigma_e2 candidate_sigma_e2
max_component_difference profile_loglik_difference_per_observation
max_derivative_difference reference_result_digest candidate_result_digest
equivalent error_class
```

## Timing protocol and discovery screen

- Host: Totoro, using a clean dedicated checkout; do not reuse the dirty detached
  historical checkout.
- Julia `1.10.10`; one Julia thread and one BLAS/OMP/vecLib thread.
- Fixed non-study compilation warm-up before any timing.
- One orchestration unit per dataset/repeat launches three fresh Julia child
  processes sequentially, one from each exact default/reference/candidate
  worktree. Each child performs the same fixed warm-up and then times only its
  assigned implementation. This isolates package versions while preserving a
  paired dataset/repeat comparison.
- Run five timed repeats per dataset and implementation after warm-up.
- Set `cycle = mod(seed + repeat_id, 3)`. Across the child launches, cycle 0 is
  `(default_ai, reference_boundary, candidate_boundary)`, cycle 1 is
  `(reference_boundary, candidate_boundary, default_ai)`, and cycle 2 is
  `(candidate_boundary, default_ai, reference_boundary)`. Record both cycle and
  one-based `order_index`; any ordering mutation invalidates selection.
- Collapse repeats within dataset/method by the median, never the minimum or a
  winning repeat.
- Compute per-cell p95 as `sort(x)[ceil(0.95*length(x))]` over dataset medians.
- Record all attempts; no retry may replace a failed or slow attempt.

A candidate passes discovery only when:

1. all 58 scientific results pass the equivalence rules below;
2. no hash, status, reason, or fail-closed behavior changes;
3. among the matched-control (oracle-interior) datasets, every cell has
   `p95(candidate) <= 2.5 * p95(default_ai)`;
4. across all discovery datasets, every cell also has
   `p95(candidate) <= 2.5 * p95(default_ai)`; and
5. every cell has `p95(candidate) <= 1.10 * p95(reference_boundary)`.

The 2.5x screen is deliberately stricter than the untouched 3x holdout gate.
The control-only screen is binding because mixed-cell p95 values can be dominated
by slow default boundary failures and thereby hide fixed profile overhead on the
interior fits that determine the later 48-seed p95.
The matched-control denominators are frozen as 12, 2, 8, 6, and 1 for
`n120_m600_r020`, `n120_m600_r050`, `n120_m600_r080`,
`n300_m1000_r020`, and `n300_m1000_r080`, respectively. A missing control
invalidates selection. Report these N values explicitly: the one-control cell is a
deterministic engineering filter, not inferential evidence.
Allocation or call-count improvement without this total-runtime result is not a
selectable candidate. Iteration on these discovery datasets is allowed, but every
candidate attempt and decision must remain in the local audit trail.

## Output-equivalence gate

For every discovery dataset, compare reference, candidate, and independent oracle.
Require:

- exact boundary status, reason, convergence, termination, and endpoint class;
- exact endpoint scientific ratios `0` or `1` and exact epsilon representation;
- unchanged AI-interior variance components within `1e-10`;
- interior ratio and component agreement within `1e-8 + 1e-5*abs(reference)`;
- endpoint `t_hat` and epsilon components within `1e-8 + 1e-7*abs(reference)`;
- profile likelihood agreement within `1e-8` per observation;
- both endpoint derivatives within absolute `1e-8` per observation;
- exact ID, marker, kernel, precision, scale, ridge, and construction provenance;
- no prediction or uncertainty output at a boundary; and
- every doc-46 independent-oracle and dense-versus-eigen check green.

The `p == 1` specialization applies to any full-rank one-column rotated
`context.X`, not merely an intercept in the original basis. It must use the
actual rotated `x_i` values, a local per-fit workspace, no global mutable buffer,
no `@fastmath`, and no deliberately reordered reduction. The generic `p > 1`
path remains. At all 401 ratios, specialized and generic `loglik` and `t_hat`
must agree with `atol=1e-10, rtol=0`, with identical grid argmax and refinement
bracket. Test both constant and nonconstant original one-column `X`, plus
synthetic near-tie and near-KKT cases that would expose a classification flip.

An eigen-context finite-difference validator must retain the same central
difference in both log-variance parameters, step `h=1e-5`, and exactly four
likelihood evaluations per validation. Before it replaces sparse validation for
an interior result, the eigen and `sparse_reml_loglik` values must agree at the
interior representation and all four perturbed points: log likelihood within
`1e-10` per observation, fixed-effect coefficients within absolute `1e-10`, and
gradient norm within absolute `1e-10`. The ordinary AI-interior fit and variance
components remain unchanged; only its validator may use the reused eigen context.
Lower- and upper-epsilon result assembly remains on `sparse_reml_loglik` under
Amendment 1 and must remain output-equivalent to the reference implementation.

Run all 72 boundary tests, full Julia tests on 1.10 and 1.12, deliberate mutations,
and the independent R oracle before sealing. Any new specialized path must have a
generic-path parity test and must be mutation-tested so bypassing it or changing
its algebra turns the gate red.

## R-twin boundary

If Julia signatures and result fields remain output-equivalent, the R delta is
limited to:

1. exact Julia implementation-commit rebind;
2. `hs_v07_genomic_boundary_contract()$candidate_id` and its literal unit
   assertion changed to exactly `doc47_boundary_performance_v1`;
3. that same candidate ID bound in the Julia driver and independent R oracle;
4. campaign candidate/driver/oracle metadata updated in lockstep; and
5. the full engine-free suite, oracle self-test, and exact-commit zero-skip live
   genomic gate.

Do not alter the R parser, payload, extractors, default rejection, controls,
genomic scale/ridge/provenance, endpoint display, prediction suppression, claims,
capability rows, or public count. The live gate must fail unless
`hs_v07_genomic_boundary_contract()$julia_implementation_commit` equals its
`EXPECTED_JULIA_COMMIT` checkout and the helper candidate ID equals
`doc47_boundary_performance_v1`. Historical commits and artifacts retain their
old IDs; on the new branch the R bridge helper, R literal assertion, Julia
driver, and R oracle must all bind the new ID exactly.

## Fresh holdout reservation

Reserve offsets `6001:6048` in each of the same five cells:

| Cell | Fresh holdout seeds |
| --- | --- |
| `n120_m600_r020` | `2027136001:2027136048` |
| `n120_m600_r050` | `2027146001:2027146048` |
| `n120_m600_r080` | `2027156001:2027156048` |
| `n300_m1000_r020` | `2027196001:2027196048` |
| `n300_m1000_r080` | `2027216001:2027216048` |

The formula is
`2027120000 + 10000*cell_index + 6001:6048`. Manifest creation must prove
disjointness from pilot `1:48`, recovery confirmation `1001:3000`, spent holdout
`5001:5048`, all discovery rows, and every registered campaign seed. These seeds
may not be generated, smoke-tested, or inspected before the create-once seal.

## Create-once candidate seal

Before any fresh holdout materialization, bind in a create-once seal:

- this preregistration commit and SHA-256;
- clean exact reference and candidate Julia commits;
- clean exact R bridge/oracle commit and independent-oracle SHA-256;
- driver, launcher, exchange-schema, profiler, and candidate IDs and SHA-256s;
- precision/kernel/ID hash algorithms, domain tags, canonical encodings, and the
  exact construction implementation commit (not unknown per-seed hash values);
- every unchanged doc-46 constant and dense limit;
- verified discovery manifest, raw lock, oracle, profile-summary, and candidate-
  decision digests;
- output-equivalence rules and exact default/reference/candidate definitions;
- fresh seed formula and 240-row manifest-preimage SHA-256;
- warm-up, ordering, repeats, median, p95, 2.5x discovery, and 3x holdout rules;
- Project/Manifest/toolchain/host/CPU/thread environment; and
- `holdout_absent_before_seal=true` plus explicit spent-block exclusion.

The fresh packet schema is `v07-genomic-boundary-holdout-v2`. Compared with the
historical v1 schema, packet metadata adds `doc47_commit` and `doc47_sha256` and
retains exact Julia and R implementation commits. It also adds `precision_hash`,
`relationship_source`, `relationship_method`, `allele_frequency_source`, `ridge`,
and `relationship_scale`; these values are part of the scientific-result digest
preimage. The v2 sealed packet file set adds `ids.tsv` and `Q.tsv` alongside
`K.tsv`, `X.tsv`, `y.tsv`, fits, and metadata. Julia and the independent R oracle
must recompute the ID, kernel, and precision hashes from those packet preimages,
verify `Q*K` identity within the frozen tolerance, compare every result with
metadata, and bind all files through the packet sidecar.

The candidate seal cannot contain the 240 unknown per-seed precision hashes
without illegally generating reserved seeds. It instead binds the exact hash
algorithm/domain tag/schema and construction code. Each per-dataset precision
hash and `scientific_result_v1` digest becomes immutable only when its post-seal
packet is created. The oracle must still read the seal and fail closed unless the
packet candidate ID, doc-47 commit/SHA, Julia/R implementation commits, hash
algorithms, and construction/scale constants equal the sealed values. Merely
checking commit-string/digest shape or trusting a digest whose preimage is not
independently read is insufficient.

The external output root must be absent or empty before sealing. All files are
create-once with sidecars and full-field resume validation. Once any offset-6001
result is opened, the candidate is spent.

## Fresh holdout gate

Run unchanged default AI, the sealed optimized candidate, and the unchanged
independent base-R oracle on all 240 fresh datasets. Preserve every doc-45/46
scientific gate and denominator, including:

- zero unresolved or oracle-disagreeing datasets;
- zero loss of a default-valid case;
- at least 95% valid oracle-interior termination in every cell;
- all interior and endpoint objective/component/ratio/gradient/KKT tolerances;
- zero losses, at least one discordant pair, and one-sided 95% Clopper--Pearson
  lower bound greater than 0.5;
- all attempted seeds retained; and
- candidate p95 runtime at most 3x unchanged default in **every** cell.

Timing exactly mirrors the historical holdout: one fresh Julia process per seed;
one fixed non-holdout compilation warm-up; unchanged default and sealed candidate
each timed once; odd seeds run default then candidate and even seeds run candidate
then default. Dataset construction, packet validation/writing, `_fit_row`, and the
independent R oracle remain outside both timers. Every cell contains exactly 48
timings per method, and p95 is exactly `sort(x)[ceil(0.95*48)]`.

Scientific and runtime gates are conjunctive. Any failure produces a new negative
endpoint. Do not relax a threshold, remove a cell, replace a seed, or revise the
candidate after opening the holdout.

## Mutation controls

The profiler, selector, seal, and holdout must turn red when any of these occur:

- discovery row, role, seed, or hash deletion/replacement;
- spent/fresh holdout overlap or any pre-seal fresh-seed access;
- component deletion/rename, `grid_401 != 401`, or call-count drift;
- negative/nonfinite timing or allocation data;
- total timing excludes AI, profile, or final assembly;
- a minimum/winning repeat replaces the median/full wrapper;
- warm-up, ordering, repeat count, p95 rule, 2.5x, or 3x changes;
- any status, reason, ratio, `t_hat`, likelihood, derivative, component, tie,
  KKT, ridge, epsilon, grid, refinement, provenance, or hash mutation;
- boundary output is counted as ordinary convergence or closed-domain
  classification is skipped for an AI-converged fit;
- failed/slow attempts are removed or replaced;
- candidate code branches on seed, cell, role, truth, or oracle class;
- checksum, file-set, seal, or resume fields disagree; or
- the prior xargs argument-wiring defect is restored.

## Downstream decision

A positive fresh holdout permits the preregistered nine-cell campaign through the
ordinary public R formula. It does not itself activate default routing. Activation
still requires all nine cells, independent R/Julia recomputation, tests-of-tests,
full Julia and R checks, live cross-twin parity, and independent Fisher, Darwin,
Noether, Hopper, Grace, and Rose review. `public_covered_count` remains 5 and G10
remains a separate maintainer decision.
