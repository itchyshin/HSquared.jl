# 45 — v0.7 genomic GREML optimizer and boundary localization

> **Status:** frozen before execution. This is a diagnostic policy-selection study,
> not recovery evidence and not authority to activate the R default route.
>
> **Parent contract:** `docs/design/44-v07-genomic-public-activation.md`.
>
> Freeze two identities: (1) the original preregistration commit and this file's
> SHA-256; and (2) the later clean execution commit containing the reviewed
> driver and instrumentation. The execution commit must descend from the
> preregistration commit, and this preregistration file must remain byte-
> identical. A run from an uncommitted tree, a non-descendant, or a changed
> preregistration blob is invalid.

## Question

The 432-seed diagnostic pilot had 29 non-converged fits in the five blocker
cells. This study separates five explanations:

1. the 100-iteration AI-REML cap;
2. sensitivity to the initial variance split;
3. benefit from a short EM-REML warm start;
4. an engine termination defect at an interior REML optimum; and
5. a legitimate finite-sample optimum on the closed variance boundary.

It does not change the marker DGP, estimand, sample-frequency VanRaden1
construction, ridge `0.01`, failed-seed denominator, or activation thresholds.
The two cells' required-confirmation-N values are not used to select an
optimizer policy. Their three nonconverged discovery datasets remain in the
optimizer study like every other original failure.

Before this preregistration was frozen, an explicitly exploratory local probe
replayed eight failures under AI caps 100/300, EM warm-ups 0/10/50, a
truth-start diagnostic, and sparse Nelder–Mead. It suggested that several
failures are closed-domain boundaries rather than iteration-cap failures. Those
fits are excluded permanently from discovery/holdout summaries and cannot
select a candidate; they only motivated the independent oracle and the exact
branching rule below.

## Immutable inputs

### Discovery failures

All 29 original failed seeds are replayed:

| cell | seeds |
| --- | --- |
| `n120_m600_r020` | 2027130002, 0006, 0009, 0012, 0014, 0018, 0019, 0025, 0028, 0030, 0032, 0036 |
| `n120_m600_r050` | 2027140037, 0038 |
| `n120_m600_r080` | 2027150011, 0013, 0016, 0020, 0022, 0039, 0045, 0046 |
| `n300_m1000_r020` | 2027190021, 0030, 0040, 0042, 0044, 0046 |
| `n300_m1000_r080` | 2027210013 |

The abbreviated values inherit the cell prefix; for example `0006` in the
first row is seed `2027130006`.

### Discovery controls

Add 29 originally converged controls from the same five cells. Within each cell,
rank its converged pilot seeds by SHA-256 of the UTF-8 string
`"<cell_id>|<seed>"`; take the same number as the failed seeds in that cell.
The selected list is written once to the discovery manifest before any fit runs.

Every replay must reproduce the original marker, ID-order, and kernel hashes.
Any mismatch stops the study.

### Sealed holdout

After one candidate policy is selected and sealed, open these disjoint 48-seed
blocks:

| cell | holdout seeds |
| --- | --- |
| `n120_m600_r020` | 2027135001:2027135048 |
| `n120_m600_r050` | 2027145001:2027145048 |
| `n120_m600_r080` | 2027155001:2027155048 |
| `n300_m1000_r020` | 2027195001:2027195048 |
| `n300_m1000_r080` | 2027215001:2027215048 |

These seeds are not recovery-pilot or confirmation seeds and may not be used to
revise the selected policy.

Manifest creation must assert:

- every discovery control/failure is an original pilot offset `1:48`;
- localization holdout offsets `5001:5048` have empty intersection with
  original pilot offsets `1:48` and original/future confirmation offsets
  `1001:3000`; and
- the holdout block has empty intersection with every discovery row.

The holdout block may overlap no discovery row. Any nonempty intersection stops
before a manifest is written.

## Discovery arms

Run the paired 2 × 2 × 4 factorial on all 58 discovery datasets:

- AI iteration cap: `100` or `1000`;
- EM warm-up: `0` or `5`;
- start: current `(1,1)`, or one of three truth-blind data-scaled starts with
  \(r_0\in\{0.1,0.5,0.9\}\).

For the scaled starts:

\[
s_y^2=\frac{\lVert y-X\hat\beta_{OLS}\rVert^2}{n-p},
\qquad
d=\operatorname{mean}\{\operatorname{diag}(K_\lambda)\},
\]

\[
t_0=\frac{s_y^2}{r_0d+(1-r_0)},
\qquad
(\sigma_{g,0}^2,\sigma_{e,0}^2)
=(r_0t_0,(1-r_0)t_0).
\]

No start may use the simulated truth. A deterministic multistart candidate is
also evaluated: run the three scaled starts and retain the finite fit with the
largest REML likelihood while retaining all losing attempts in the raw record.

## Independent closed-domain oracle

Base R independently profiles the same REML likelihood over
\(r\in[0,1]\):

\[
H(r)=rK_\lambda+(1-r)I,
\qquad
\hat t(r)=\frac{y^\top P_{H(r)}y}{n-p}.
\]

The oracle may not call package construction or fitting helpers. It uses a fixed
grid

\[
\mathcal G=\{0,0.0025,0.005,\ldots,0.9975,1\}.
\]

For each \(r\), define

\[
P_H=H^{-1}-H^{-1}X(X^\top H^{-1}X)^{-1}X^\top H^{-1},
\qquad
\hat t(r)=\frac{y^\top P_Hy}{n-p},
\]

and the exact profiled REML log-likelihood

\[
\ell_p(r)=-\frac12\left[
(n-p)\{1+\log(2\pi\hat t(r))\}
+\log|H(r)|
+\log|X^\top H(r)^{-1}X|
\right].
\]

After evaluating the full grid, base R `optimize(..., maximum=TRUE,
tol=1e-12)` refines the interval one grid step on either side of the best
interior grid point. Both endpoints are then compared explicitly with the
refined interior candidate. Arm objectives are re-evaluated with this same
oracle formula; raw Julia likelihood values are recorded but not mixed into the
oracle-gap calculation.

Two candidates are tied when their absolute log-likelihood difference divided
by \(n\) is at most \(10^{-10}\); a tie involving an endpoint is
`oracle_unresolved`. The one-sided endpoint derivatives use
\(\delta=10^{-6}\):

\[
D_0=\{\ell_p(\delta)-\ell_p(0)\}/\delta,
\qquad
D_1=\{\ell_p(1)-\ell_p(1-\delta)\}/\delta.
\]

After division by \(n\), the KKT tolerance is \(10^{-8}\). A lower-boundary
maximum requires \(D_0/n\le10^{-8}\); an upper-boundary maximum requires
\(D_1/n\ge-10^{-8}\). A strict interior classification requires a refined
\(r\in(10^{-8},1-10^{-8})\), improvement over both endpoints larger than the
tie tolerance, and neither endpoint KKT classification.

For each dataset it returns:

- `interior_oracle`: a strict interior maximum;
- `lower_boundary`: \(r=0\) maximizes the closed profile and satisfies the
  one-sided KKT sign;
- `upper_boundary`: \(r=1\) maximizes the closed profile and satisfies the
  one-sided KKT sign; or
- `oracle_unresolved`: grid/refinement or numerical checks disagree.

An oracle boundary is never relabelled ordinary interior convergence. Any
boundary-support change requires a versioned contract amendment, a distinct
terminal status, tests, and public diagnostics.

## Atomic output

One row per dataset and arm records:

`phase, cell_id, seed, role, cap, em_warmup, start_id, start_sigma_g2,
start_sigma_e2, converged, termination_reason, iterations, em_steps,
factorizations, step_halvings, estimate_sigma_g2, estimate_sigma_e2,
estimate_ratio, objective, ai_score_norm, fd_log_gradient_norm,
last_relative_change, smallest_component, runtime_seconds, peak_rss_mb,
oracle_class, oracle_ratio, oracle_sigma_g2, oracle_sigma_e2,
oracle_objective, objective_gap_per_observation, marker_hash, id_hash,
kernel_hash, error_class`.

The engine must expose real termination reasons and counters; inferring them
after the run is insufficient.

For an interior oracle, agreement requires:

- finite positive components;
- oracle-formula objective gap
  \(|\ell_{arm}-\ell_{oracle}|/n\le10^{-8}\);
- for each ratio or variance quantity,
  \(|\hat\theta-\theta_*|\le10^{-8}+10^{-5}|\theta_*|\); and
- normalized finite-difference log-gradient \(\le10^{-8}\), defined as the
  Euclidean norm of the central difference in the two log-variance parameters
  with step \(h=10^{-5}\), divided by \(n\).

## Candidate selection

Reject any policy that:

- calls an oracle-boundary case ordinary interior convergence;
- disagrees with an interior oracle;
- worsens an originally converged control beyond the tolerances above;
- changes a frozen hash or drops/replaces an attempt; or
- depends on truth, cell identity, or post-hoc thresholds.

The 20 eligible policy IDs, in frozen selection order, are:

| order | policy IDs | exact rule |
| ---: | --- | --- |
| 1–4 | `C100_E0`, `C1000_E0`, `C100_E5`, `C1000_E5` | current `(1,1)` start; cap/EM encoded in the ID |
| 5–8 | `S050_C100_E0`, `S050_C1000_E0`, `S050_C100_E5`, `S050_C1000_E5` | single data-scaled \(r_0=0.5\) start |
| 9–12 | `S010_C100_E0`, `S010_C1000_E0`, `S010_C100_E5`, `S010_C1000_E5` | single data-scaled \(r_0=0.1\) start |
| 13–16 | `S090_C100_E0`, `S090_C1000_E0`, `S090_C100_E5`, `S090_C1000_E5` | single data-scaled \(r_0=0.9\) start |
| 17–20 | `M_C100_E0`, `M_C1000_E0`, `M_C100_E5`, `M_C1000_E5` | run \(r_0=0.5,0.1,0.9\) scaled starts and retain the largest finite REML likelihood |

Within a multistart policy, likelihood ties satisfying the \(10^{-10}\)-per-
observation rule select starts in the fixed order \(0.5,0.1,0.9\). Every atomic
fit remains in the raw output. The first policy in the table that resolves all
oracle-interior discovery failures without violating a rejection rule is
selected; total factorizations and runtime are descriptive because the table is
already a total order.

Multistart policy cost is the complete serial wrapper cost: the sum of all three
atomic-attempt wall times and factorization counts plus deterministic selection
overhead. The selected winner's atomic cost is also recorded but is never used
for the policy-level runtime gate.

Any `oracle_unresolved` discovery dataset yields `NO_POLICY_SELECTED`.
If any original failure is an oracle boundary, no optimizer-only policy can
resolve that row. The study then yields `BOUNDARY_POLICY_REQUIRED`: first
freeze a versioned boundary-aware terminal-status contract, then treat that
contract as a separate candidate on the still-sealed holdout. It is never folded
silently into ordinary convergence.

If no policy qualifies for any other reason, the result is
`NO_POLICY_SELECTED`. Write the selected policy (or exact negative outcome)
and discovery-output digest to a create-once seal before any holdout file is
opened.

## Holdout gate

Run only the old default, sealed candidate, and independent oracle on all 240
holdout datasets. A default-policy change is justified only when:

- there are zero oracle disagreements or false interior-convergence calls;
- no case valid under the old default is lost;
- every cell has at least 95% valid termination among its oracle-interior cases;
- the pooled paired superiority gate below passes;
- all interior objective/parameter/gradient tolerances pass; and
- candidate p95 policy runtime is no more than three times the old default;
  multistart uses the aggregate three-attempt cost defined above, never the
  winning attempt alone.

Define a valid paired outcome as follows:

- at an interior oracle, the arm must report ordinary convergence and satisfy
  every oracle-agreement tolerance;
- at a boundary oracle, an optimizer-only arm is invalid, while a
  boundary-aware candidate is valid only if it returns the matching distinct
  boundary status and satisfies its separately frozen objective/KKT gate.

Pool all 240 datasets. A win \(W\) is candidate-valid/default-invalid; a loss
\(L\) is default-valid/candidate-invalid. Require zero losses, at least one
discordant pair, and the exact one-sided 95% Clopper–Pearson lower bound for
\(W/(W+L)\) to exceed 0.5. Report \((W-L)/240\) and cell-stratified win/loss
counts. Oracle-boundary cases remain in the 240-row denominator. An
optimizer-only candidate with any oracle-boundary holdout case cannot support
activation.

An `oracle_unresolved` holdout case blocks policy selection. If the sealed
candidate fails any holdout gate, stop; do not revise it using opened holdout
results. A new candidate requires a versioned preregistration and entirely new,
previously sealed holdout seeds.

## Mutation controls

The study must turn red when:

- an original failure or matched control is removed/replaced;
- holdout results are read before the candidate seal exists;
- a cap, EM, start, role, or candidate-selection label is changed;
- a truth-informed start is substituted;
- ridge or any provenance hash changes;
- an endpoint KKT sign is reversed;
- a boundary case is counted as ordinary convergence;
- a failed attempt is removed from a denominator;
- candidate complexity order is changed; or
- an objective, termination reason, oracle class, or seed is mutated.

## Compute and evidence policy

- Local smoke first; production on Totoro with at most 16 workers for discovery
  and RAM-derived concurrency for holdout.
- One process per dataset/arm; Julia and BLAS threads fixed to one.
- Raw output stays outside both repositories and is never an Actions artifact.
- Commit only preregistration, manifests, seals, compact summaries, hashes,
  failure classifications, commands, and environment records.
- Before manifest creation require a clean exact commit and record the
  preregistration commit, driver SHA-256, `Project.toml`, resolved
  `Manifest.toml`, Julia/R versions, and host. Require an external empty output
  directory, create-once discovery and holdout manifests/seals, exact sealed
  file-set verification, and full-field resume validation.

Discovery and holdout rows are permanently excluded from doc-44 G5/G6 recovery
summaries. They cannot size confirmation, move capability/status/count language,
or support a public claim, and their seeds may never enter a future recovery
pilot or confirmation block.

## Downstream boundary

A successful localization policy is not recovery evidence and does not activate
R. Before the authoritative recovery campaign:

1. freeze the selected optimizer/boundary policy in a versioned amendment;
2. propagate it identically through marker and supplied-`Ginv` routes;
3. create the exact held default-auto-route R commit;
4. run the fresh campaign through the ordinary public R formula in a separate R
   process per seed; and
5. retain every gate in doc 44.

Even after a successful activation campaign, `public_covered_count` remains 5.
