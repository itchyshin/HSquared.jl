# 45a — v0.7 optimizer-localization exchange-schema amendment

> **Status:** frozen before execution. This amendment resolves an implementation
> ambiguity discovered after doc 45 was committed and before any authoritative
> discovery or holdout run.
>
> **Parent:** `docs/design/45-v07-genomic-optimizer-localization.md` at
> preregistration commit `e2b4b23957ab4075205a7399214daae186a04bcb`,
> file SHA-256
> `4eb8b7012140d6f5f30d7c4cfbaf46f974ef5a3caa7b0c4f14e002ddf8657f50`.

## Ambiguity resolved

Doc 45 requires a final per-dataset/per-arm atomic output but does not separate
the Julia engine's raw objective from the base-R oracle's independently
re-evaluated likelihood. It also does not state whether the oracle writes a
compact dataset-level row or the final atomic join.

The frozen interpretation is:

1. Julia writes a sealed dataset packet and raw per-arm rows.
2. Base R reads the sealed packet and raw arms, independently profiles the
   closed-domain likelihood, re-evaluates every arm, and writes the **final
   per-arm atomic joined rows**.
3. Julia independently verifies that every copied raw field is byte/value
   identical to `arms.tsv` before summarizing.

No compact alternative oracle schema is authoritative.

## Endpoint-refinement clarification

Doc 45's one-grid-step `optimize()` bracket may include 0 or 1. Because
`optimize()` approaches but does not evaluate a closed endpoint, a genuine
boundary maximum can otherwise be declared tied with an arbitrarily
endpoint-adjacent numerical candidate and make boundary classification
unreachable.

Keep the frozen one-step bracket, but a refined candidate with
\(r\le10^{-8}\) or \(r\ge1-10^{-8}\) is **endpoint-adjacent**, not a distinct
interior candidate. It is excluded from endpoint-tie logic. Boundary
classification compares the exact endpoint against all distinct interior grid
and refined candidates and still requires the frozen one-sided KKT sign. An
endpoint tie is `oracle_unresolved` only when it is with a distinct candidate
\(r\in(10^{-8},1-10^{-8})\). This preserves a genuine near-boundary interior
optimum while making a true closed-domain boundary reachable.

## Dataset packet

Each external packet is:

```text
datasets/<phase>/<cell_id>/<seed>/
  y.tsv
  X.tsv
  K.tsv
  metadata.tsv
  arms.tsv
  files.sha256.tsv
```

`files.sha256.tsv` is create-once and hashes the other five files. Metadata
binds schema version, phase, cell, seed, dimensions, ridge, marker/ID/kernel
hashes, original doc-45 preregistration commit/file SHA, this amendment's
commit/file SHA, and the clean descendant execution commit.

The oracle writes outside the sealed packet:

```text
oracle/<phase>/<cell_id>/<seed>.tsv
oracle/<phase>/<cell_id>/<seed>.tsv.sha256
```

Both files are create-once.

## Objective fields

The final atomic row refines doc 45's generic `objective` field into:

- `julia_objective`: the negative raw Julia REML log-likelihood recorded by
  the arm;
- `oracle_arm_loglik`: the arm's two fitted variance components evaluated
  independently with the base-R full REML likelihood below;
- `oracle_loglik`: the maximum closed-domain base-R profile likelihood; and
- `objective_gap_per_observation =
  abs(oracle_arm_loglik - oracle_loglik) / n`.

For \(a=\sigma_g^2\) and \(e=\sigma_e^2\), define

\[
V(a,e)=aK_\lambda+eI,
\qquad
P_V=V^{-1}-V^{-1}X(X^\top V^{-1}X)^{-1}X^\top V^{-1},
\]

\[
\ell_R(a,e)=-\frac12\left[
(n-p)\log(2\pi)+\log|V|+\log|X^\top V^{-1}X|+y^\top P_Vy
\right].
\]

Then `oracle_arm_loglik =
ell_R(estimate_sigma_g2, estimate_sigma_e2)`;
`oracle_loglik = max_{r in [0,1]} ell_p(r)` under doc 45; and
`objective_gap_per_observation =
abs(oracle_arm_loglik - oracle_loglik) / n`.
`oracle_fd_log_gradient_norm` is the doc-45 central difference of this full
\(\ell_R\) in the two log-variance coordinates, divided by \(n\). Any Julia
diagnostic gradient remains a separate copied field,
`julia_fd_log_gradient_norm`.

The remaining raw fields and counters from doc 45 are copied exactly. The final
row additionally carries `oracle_class`, `oracle_ratio`,
`oracle_sigma_g2`, `oracle_sigma_e2`, both endpoint derivatives, and the
oracle tie/KKT diagnostics needed to reproduce the classification.

The exact final header, in order, is:

```text
phase
cell_id
seed
role
arm_id
cap
em_warmup
start_id
start_sigma_g2
start_sigma_e2
converged
termination_reason
iterations
em_steps
factorizations
step_halvings
estimate_sigma_g2
estimate_sigma_e2
estimate_ratio
julia_objective
ai_score_norm
julia_fd_log_gradient_norm
last_relative_change
smallest_component
runtime_seconds
peak_rss_mb
error_class
marker_hash
id_hash
kernel_hash
oracle_class
oracle_ratio
oracle_sigma_g2
oracle_sigma_e2
oracle_arm_loglik
oracle_loglik
objective_gap_per_observation
oracle_fd_log_gradient_norm
lower_derivative_per_observation
upper_derivative_per_observation
interior_agreement
dataset_files_digest
```

`interior_agreement` is `true` only for an `interior_oracle` row that
satisfies every objective, parameter, ordinary-convergence, and gradient gate.
It is `false` for a boundary, unresolved oracle, failed arm, or interior
disagreement. Boundary correctness is adjudicated separately from
`oracle_class`, the distinct engine terminal status, objective gap, and KKT
fields.

The exact ordered raw `arms.tsv` header is the first 30 final-header fields:

```text
phase	cell_id	seed	role	arm_id	cap	em_warmup	start_id	start_sigma_g2	start_sigma_e2	converged	termination_reason	iterations	em_steps	factorizations	step_halvings	estimate_sigma_g2	estimate_sigma_e2	estimate_ratio	julia_objective	ai_score_norm	julia_fd_log_gradient_norm	last_relative_change	smallest_component	runtime_seconds	peak_rss_mb	error_class	marker_hash	id_hash	kernel_hash
```

Its primary key is the ordered tuple
`(phase, cell_id, seed, role, arm_id)`. Discovery packets contain exactly the
16 atomic arm IDs from doc 45 in doc-45 policy order 1–16. Holdout packets
contain `C100_E0` first, followed by the sealed candidate's atomic arm(s) in
their doc-45 order, with an identical duplicate omitted. A multistart candidate
therefore contributes its three scaled-start atomic rows; policy-level selection
and aggregate cost are derived without deleting any of them.

The exact `metadata.tsv` keys are:

```text
schema_version
phase
cell_id
seed
role
n
p
m
ridge
marker_hash
id_hash
kernel_hash
doc45_commit
doc45_sha256
doc45a_commit
doc45a_sha256
execution_commit
```

## Canonical packet serialization

All packet files are UTF-8, tab-delimited, unquoted, and LF-terminated, including
the final line. Fields may contain no tab, CR, or LF. Finite Float64 values use
lowercase `Printf.@printf("%.17g", value)` round-trip tokens; zero is
canonicalized to `0`. Nonfinite tokens, only where allowed below, are exactly
`NaN`, `Inf`, or `-Inf`. Integers use base-10 without padding, and Boolean
tokens are lowercase `true`/`false`.

- `y.tsv` header is `row	y`; rows are `1:n`.
- `X.tsv` header is `row	x1	...	xp`; rows are `1:n`.
- `K.tsv` header is `row	k1	...	kn`; rows are `1:n`.
- Matrices are interpreted by file row, then column, exactly as displayed; no
  language-specific column-major flattening is used.
- `metadata.tsv` header is `key	value`, followed by the keys above in that
  exact order.
- `files.sha256.tsv` header is `relative_path	sha256`, followed in exact
  order by `K.tsv`, `X.tsv`, `arms.tsv`, `metadata.tsv`, `y.tsv`.
- `dataset_files_digest` is SHA-256 of the canonical bytes of
  `files.sha256.tsv`.

The final oracle file uses the exact 42-column header above and the same token
rules. Its primary key and row order must match `arms.tsv` exactly.

## Allowed nonfinite values

For a successful arm (`converged=true`, `error_class=none`), variance
estimates, ratio, both objectives, both gradient norms, score norm, smallest
component, runtime, RSS, oracle optimum, endpoint derivatives, and objective gap
must be finite. `last_relative_change` alone may be `NaN` if the score gate
converged before the first update.

For a failed arm, only these copied/computed fields may be nonfinite:

- `estimate_sigma_g2`, `estimate_sigma_e2`, `estimate_ratio`;
- `julia_objective`, `ai_score_norm`,
  `julia_fd_log_gradient_norm`, `last_relative_change`,
  `smallest_component`;
- `oracle_arm_loglik`, `objective_gap_per_observation`, and
  `oracle_fd_log_gradient_norm`.

A failed arm must have `converged=false`, a nonempty non-`converged`
termination reason, and `error_class != none`. Runtime and RSS remain finite
and nonnegative; starts remain finite and positive. `iterations=-1` is allowed
only for an error before fitting; otherwise counters are nonnegative.
Dataset-level oracle optimum fields and endpoint derivatives must be finite even
when `oracle_class=oracle_unresolved`; an oracle that cannot produce them
writes no final file and fails closed.

## Fail-closed join

The oracle and Julia verifier reject:

- missing, extra, duplicated, or reordered arm rows;
- any changed raw arm field: copied string/integer/Boolean tokens must be byte-
  exact, and copied numeric tokens must be byte-exact canonical tokens whose
  parsed Float64 bit patterns are identical (canonical `NaN` compares by token);
- a changed packet checksum or metadata identity;
- a nonfinite value outside a field where the schema explicitly permits it;
- a missing create-once sidecar; or
- output written before both preregistration identities and the clean execution
  commit are recorded.

This schema amendment changes no scientific threshold, candidate order, seed,
estimand, DGP, ridge, boundary rule, recovery gate, status, or public claim.
