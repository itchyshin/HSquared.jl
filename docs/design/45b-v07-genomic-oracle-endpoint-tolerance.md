# 45b — v0.7 oracle endpoint-adjacency tolerance amendment

> **Status:** frozen before execution. This amendment resolves a base-R
> \`optimize()\` machine-precision constraint discovered by the oracle self-test
> before any authoritative discovery or holdout run.
>
> **Parents:**
>
> - doc 45 commit \`e2b4b23957ab4075205a7399214daae186a04bcb\`,
>   SHA-256
>   \`4eb8b7012140d6f5f30d7c4cfbaf46f974ef5a3caa7b0c4f14e002ddf8657f50\`;
> - doc 45a commit \`1ce3720ab31eb2108acd842fdd74f6c1ddbc45ec\`,
>   SHA-256
>   \`f88509b2aa715c5836bbc387284e94e3fcc6904d66ec00290f71b2e099f18182\`.

## Constraint observed

Although doc 45 requests \`optimize(..., tol=1e-12)\`, base R's bounded
double-precision optimizer cannot place its returned point arbitrarily close to
a closed endpoint. On the pre-run boundary self-test it returned
\(r=0.9999999849\), approximately \(1.51\\times10^{-8}\) below 1, with an
endpoint/refined likelihood gap of only \(1.46\\times10^{-11}\) per
observation. Doc 45a's \(10^{-8}\) endpoint-adjacency rule would therefore call
the numerical optimizer artifact a distinct interior tie and make the boundary
fixture unresolved.

## Frozen resolution

Replace only doc 45a's endpoint-adjacency distance with

\[
\delta_{\mathrm{adj}}=10^{-7}.
\]

A refined candidate with \(r\le10^{-7}\) or \(r\ge1-10^{-7}\) is
endpoint-adjacent, is excluded from distinct-interior tie logic, and is never
classified `interior_oracle`. This amendment therefore replaces doc 45's
strict-interior interval with \(r\in(10^{-7},1-10^{-7})\). The exact endpoint
is classified as a boundary only if it:

1. equal or exceed every distinct interior candidate within the frozen
   \(10^{-10}\)-per-observation likelihood tolerance; and
2. satisfies the frozen one-sided KKT derivative sign and tolerance.

If an endpoint-adjacent refined candidate exists but the exact endpoint fails
either gate, return `oracle_unresolved`; do not call the candidate interior or
the endpoint a boundary.

A refined candidate farther than \(10^{-7}\) from both endpoints remains a
distinct interior candidate. A likelihood tie with such a candidate is still
\`oracle_unresolved\`.

The \(10^{-7}\) rule is fixed for Julia 1.10/base R 4.5 double-precision
execution and is mutation-tested symmetrically near both endpoints at
\(0.5\\times10^{-7}\) (endpoint-adjacent), exactly \(10^{-7}\)
(endpoint-adjacent), and \(2\\times10^{-7}\) (distinct interior candidate). It
is a numerical classification tolerance, not a change to the estimand, recovery
threshold, convergence denominator, candidate order, or public boundary
semantics.

## Binding

Execution metadata must bind doc 45b's commit and SHA-256 in addition to doc 45
and doc 45a. The exact metadata keys are appended after \`doc45a_sha256\`:

\`\`\`text
doc45b_commit
doc45b_sha256
\`\`\`

followed by the existing \`execution_commit\` key. All other packet and oracle
schema fields remain byte-for-byte as frozen in doc 45a.
