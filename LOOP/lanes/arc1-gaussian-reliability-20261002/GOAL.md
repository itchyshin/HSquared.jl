# GOAL: H² Gaussian reliability (IMMUTABLE)

## Full approved goal

Deliver reliable ordinary factor-analytic (FA) fitting, evaluate automatic K0/K1 model selection, and validate Gaussian uncertainty through the Julia and R twins. Complete S0–S5 and all original acceptance gates G0–G8. Preserve the existing expert-controlled/default policy unless users opt into `optimizer_policy="arc1_v1"`; preserve existing uncertainty semantics and experimental capability status. Rank frequency is a diagnostic, not interval calibration. Do not invent covariance-recovery tolerances or turn this evidence into a capability promotion or publication claim.

## Approved scientific and computational contract

### FA fit, policy, starts, and score

- Exact spectral REML objective with analytic gradient; BFGS capped at 2,000 iterations per start, optimizer tolerance `1e-8`, and final scaled-gradient infinity norm `≤1e-6`.
- New behavior is opt-in through `optimizer_policy="arc1_v1"`. An omitted policy preserves the legacy path exactly.
- K0 starts from the existing start. K1 uses the existing two starts plus 16 deterministic K0-derived starts: eight sign patterns with the first sign positive, crossed with `a∈{0.1,0.7}`. Set `L_i=a*s_i*sqrt(g_i-1e-4)`, `psi_i=g_i-L_i²`, and carry residual covariance forward.
- Compare with `-2*raw_REML_loglik + 2p`, covariance-parameter counts `p=14` for K0 and `p=18` for K1 (AIC penalty terms 28 and 36). Tie tolerance `1e-6` favors K0. The expanded ordinary-start reference uses best found; accept only when shortfall is `≤1e-4`.

### Repeatability profiles

- Five interval targets: `Va`, `Vpe`, `Ve`, `h²`, and `t`.
- Truth triples `(Va,Vpe,Ve)`: `(0.3,0.2,0.5)`, `(0.3,0.01,0.69)`, `(0.01,0.3,0.69)`; `N=80,160,320`.
- Exact REML; analytic scale where available; explicit zero-component reduced models; likelihood-ratio cutoff `3.841458820694124`.
- Preserve explicit statuses for unconverged fits, unresolved nuisance parameters, singularity, and unbracketed profiles; show disconnected profile sets. Preserve existing uncertainty semantics.

### Selection and FA h² uncertainty

- Selection allocation: 30 development + 30 pilot + 400 confirmation attempts per cell across 9 cells. Expanded reference uses K0 split `{0.05,0.15,0.3,0.5,0.7,0.9}` and K1 8 signs × amplitudes `{0.025,0.1,0.25,0.5,0.7,0.9,0.97,0.995}`; each start uses BFGS 10,000, the top four finite solutions continue through Nelder–Mead 20,000 then BFGS 10,000. Report best found, never global. Expanded reference: 20 preselected confirmation attempts per cell plus every flagged case.
- Pilot numerical screen: at least 29/30 both candidates available per cell and all expanded-reference checks good. Null K1 selection ≤6/30; strong N=320 K1 selection ≥24/30. Failure means HOLD; no automatic extension.
- Per cell, both-candidates-eligible proportion has Wilson 95% lower bound `≥0.90`; under null K1, K1-selection proportion has Wilson 95% upper bound `≤0.20`; strong signal at N=320, K1-selection proportion has Wilson 95% lower bound `≥0.80`. Denominators include all attempts. Weak-signal behavior and covariance recovery are descriptive; no covariance tolerance is authorized.
- FA h² target: four `h²_i=G_ii/(G_ii+R_ii)`. Candidate percentile bootstrap reruns the entire selector in every inner sample. Use fixed B; require at least 0.99 usable interval formation or refuse. Never replace failed attempts.
- FA interval allocation: pilot at N=160 with 30 outer attempts per 3 signals, `B=199`; require ≥29/30 formed and all-target all-attempt coverage in `[0.85,1]` as screening only. Endpoint screening uses 20 designated pilot fits with nested `B=499/999`; require ≥18/20 endpoint differences ≤0.02 and none >0.05. Failed screen means HOLD, no automatic extension. Confirmation uses 400 outer attempts per signal and `B=499` only if qualified.
- For every required target and cell: interval formation `≥0.99`; the 90% Wilson interval for all-attempt coverage lies wholly inside `[0.92,0.98]`; intervals are finite and ordered. Report formed coverage, all-attempt coverage, refusals, and widths separately.

### Five-target univariate repeatability study

- 30 development + 30 pilot + 400 confirmation attempts per cell across 9 cells.
- Exact-zero `Va=0` or `Vpe=0` diagnostics use 200 fits each at N=160; these are diagnostic only, with no nominal coverage claim.

### Pedigree, observation layout, and covariance identities

- Four traits; mean vector `[0,1,-1,2]`; `rho∈{0,0.15,0.70}`; column vector `L=sqrt(0.5*rho)*[1,1,-1,-1]^T`; `psi=0.5*(1-rho)`; `G=L*L'+Diagonal(psi)` and `diag(G)=0.5`.
- `diag(R)=0.5`; all residual off-diagonals are `0.1`.
- `N∈{80,160,320}` counts observed offspring: `N/8` unrelated sires, two unrelated dams per sire, four offspring per dam; all parents are unphenotyped; total pedigree size `11N/8` (110, 220, 440). Relationship values: diagonal 1, full sib 0.5, half sib 0.25, unrelated 0.
- Record-major ordering: record `i`, then trait; `y=vec(Y')`; `V=B⊗G+I⊗R`; `Xfull=X⊗I4`; rotation across records `U'⊗I4`.
- Parent-provided math candidate to prove before optimizer changes: `B=UDU'`, `z_i=(U'Y)[i,:]'`, `c_i=(U'ones)[i]`, `V_i=d_iG+R`, `W_i=inv(V_i)`, `C=sum(c_i²W_i)`, `b=sum(c_iW_i z_i)`, `beta=C\\b`, `e_i=z_i-c_i beta`, `nll=.5[df*log(2π)+sum(logdet(V_i))+logdet(C)+sum(e_i'W_i e_i)]`, objective `nll/df`. General design uses `C=sum(D_i'W_iD_i)`. Candidate score terms: `a_i=W_i e_i`, `H_i=W_i-W_iD_i C^-1D_i'W_i`, `T_i=(H_i-a_i a_i')/(2df)`, `S_G=sum(d_iT_i)`, `S_R=sum(T_i)`. Retain the full fixed-effect correction and prove the `ones` eigenvector condition where that reduction is used. These are derivation targets, not verified implementation evidence.

### Seeds, R parity, execution, and status

- Fresh, disjoint development, pilot, and confirmation seed namespaces. Frozen namespace: `h2-arc1-gaussian-reliability-20261002-v1`. Seed = UInt64 from the first 16 hex digits of SHA-256 over UTF-8 canonical pipe-joined `[namespace, programme(fa_rank/fa_interval/repeatability/boundary), phase(development/pilot/confirmation/diagnostic), N, signal-label, outer-index, inner-index, stream(data/bootstrap/reference)]`. Indices are 1-based; `inner=0` denotes outer-data generation; different programme labels prevent reuse. S3 generates and validates exact manifests before any scientific replicate. The rule is frozen, but manifest validation remains outstanding. Historical seeds may be inspected but never used for confirmation. A failed pilot holds confirmation; a failed confirmation leaves its gate unmet. Preselect expanded-reference outer indices 1:20 per cell. Endpoint pilot uses the first 20 pooled round-robin signals (null, weak, strong); nested B=199/499/999 prefixes use the same inner seeds.
- S4 validates R controls, live Julia/R parity, interruption, and failure behavior against the same frozen contract.
- Julia source baseline `8fd54b7b`; clean isolated R baseline `/private/tmp/hsquared-auto-fa-r-20261001`, commit `c9b15af350e0c5ca62e5e698716b66101251bcdc`. The original Dropbox R checkout is dirty/protected; Julia `.claude/settings.json` and `.cursor/hooks.json` changes are protected.
- Estimate before every fit/campaign. Planned host is Totoro, four workers × four Julia threads, BLAS one; no GPU or publication. The >3-hour pre-run approval rule still applies to any campaign whose estimate exceeds that threshold.
- User authorization covers scoped implementation, tests, and local commits for this programme. Release, push, publication, default activation, capability promotion, and registry actions remain outside scope.

## Immutable execution record

This lane-local file is the control record for this Arc1 run. The existing `LOOP/GOAL.md` describes a separate, older H² programme and remains untouched. The application goal returned by the goal API is also separate and is not modified here.

The table below preserves the initial execution snapshot. Current implementation, review, compute and ownership status is recorded in [checkpoint.md](checkpoint.md); it supersedes this table's status labels without changing the approved goal or acceptance requirements above.

| Slice | Status | Dependency / exit condition |
|---|---|---|
| S0: freeze mathematics, protocol, seed rule, and ledger | IN PROGRESS | Deterministic contract and seed rule frozen in these records; exact manifest generation/validation is an S3 prerequisite before studies. No fit has been run by S0. |
| S1: exact FA objective and `arc1_v1` policy | IN PROGRESS | Exact objective/gradient source and focused proof tests are present; independent G1 review is pending. Optimizer dispatch and policy integration remain outstanding. |
| S2: five univariate repeatability profile targets `Va`, `Vpe`, `Ve`, `h²`, and `t` | IN PROGRESS | Core profile implementation is underway; population evidence and G5 remain outstanding. |
| S3: independent evidence checker | IN PROGRESS | Exact seed-manifest generation, validation, and evidence checks are underway; scientific studies wait on validated manifests. |
| S4: R controls and live parity | NOT STARTED | Depends on S1–S3 interface and evidence checks. |
| S5: pilots, confirmation, independent review | NOT STARTED | Depends on S0–S4 and fresh disjoint frozen seeds; review all original gates before closeout. |
