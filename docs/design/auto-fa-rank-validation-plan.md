# Automatic genetic FA-rank validation plan

Status: predeclared plan for later implementation and validation, 2026-10-01. This design arc executes no fits, simulations, benchmark or campaign. [Contract](auto-fa-rank-contract.md) defines the proposed T4 complete-response pedigree Gaussian comparison. The frozen fixed-rank 200-seed campaign remains untouched.

## Acceptance ladder

| Stage | Evidence required | Honest completion statement |
| --- | --- | --- |
| V0 design | Independent model/user/claim review; criterion, failures and limits explicit. | Design ready for a bounded implementation proposal. |
| V1 deterministic implementation | Independent dense objective and penalty references, comparator shape/floor, policy/refusal/interrupt tests, source review and fixed-rank compatibility. | Selector mechanics implemented at the tested cell. |
| V2 pre-run | Non-empty ordinary-start results, readable attempt tables, expected engineered witnesses and measured cost. | Ready to size a separate diagnostic study. |
| V3 diagnostic study | Frozen scenarios, truth, seeds, denominators and outputs; all attempts retained. | Measured selection behavior for the declared cells. |
| V4 twin integration | Same-input R/Julia fixtures, serialized complete ledger, exact-current tests/docs and independent audit. | Bounded experimental expert route integrated. |

No rung automatically changes covered count or public defaults. Public activation or a reliability/calibration claim requires its own stated evidence and owner-approved scope. A mechanically correct selector can still choose poorly under weak signals.

## Deterministic tests and tests of the tests

| ID | Independent oracle or controlled witness | Required outcome / negative control |
| --- | --- | --- |
| O1 shape/floor | Direct G=LL'+diag(psi); K0 psi=c+exp(theta), K1 same c. | qG=4/8, qR=10; fixed public diagonal remains exp(theta). Deliberately unmatched floor must fail comparator conformance. |
| O2 vector/order | Record-major Kronecker covariance constructed independently in base R and Julia. | Input labels and V agree; trait/animal permutation mapped back. Deliberate order swap must fail. |
| O3 objective | Dense Cholesky GLS and explicit REML formula, independent of selector helper. Evaluate identical returned G/R, not a truth-start optimum. | Returned loglik discrepancy <=1e-8 for each moderate-scale witness; altered normalisation or fixed design must fail. |
| O4 penalty/score | Hand-calculated q={14,18}, C={-2ell0+28,-2ell1+36}, D=8-2deltaell. | Algebra/sign match. A wrong penalty or sign must change the manufactured winner and be detected. |
| O5 ties | Manufactured ell differences below, exactly at and above 4, including score offsets just inside/outside tau=1e-6. | Exact/numerical tie selects0; D below -tau selects1; no loss of either row. Changed tie policy must fail. |
| O6 failure table | Inject nonfinite, nonconverged, non-PD, failed and unattempted outcomes at each rank/start. | Any unavailable rank means unavailable selection; preserve all actual start rows, both candidate-summary rows and reasons. Preflight creates no synthetic start rows. Sole survivor must not silently win. |
| O7 retry/nesting | L=0 objective equals the matched diagonal covariance; manufactured non-monotonic FA result and better-unconverged attempt. | The mixed converged-plus-better-unconverged case must invoke the single allowed FA retry. At most four optimizer starts, then unavailable if unresolved. A zero-gradient L=0 initializer must be refused as the retry start. |
| O8 identifiability | One-record A=I, Z=I gives V=I⊗(G+R); create distinct G/R pairs with same V. Also use half-sibs A=(1-rho)I+rho*11' with trait intercepts: project through Q'X_full=0 and show proportional REML genetic/residual kernels. | Refuse automatic selection and preserve design-identification reason. Screen the projected REML covariance kernels, not raw relatedness; freeze the numerical rank criterion before real fit use. |
| O9 scope/compatibility | Complete T4 pedigree intercept-only route plus each forbidden family/rank/missingness/provider/design. | Clear preflight refusals; original fixed-rank outputs and guards unchanged. |
| O10 interruption | Controlled interruption during each start and between candidates. | Prompt cancellation; partial ledger retained, remaining rows unattempted; never an apparently completed winner. |
| O11 transport | Plain-data serialization fixtures in both twins, including missing criterion/reason fields. | Same selected rank, covariances, score difference, labels, complete table and warnings; no row dropped during data-frame conversion. |

Pure score/policy tests are independent of Julia fitting. Engine integration tests must require the real bridge rather than silently pass after skips. The earlier fixed-covariance base-R reference and FA unit/order harness are scaffolding; their truth-informed optimizer start and fixed-rank scope do not constitute selector recovery evidence. Existing files are cited in the [engine receipt](../dev-log/scout/2026-10-01-auto-fa-rank-design/engine-contract.md).

A test of the score does not prove the optimizer finds its maximum. Retain within-rank default/balanced attempts and objective/covariance disagreement separately from cross-rank choice.

## Future pre-run, not launched

After a separate implementation approval and V1 pass, propose four ordinary-start datasets on a small informative pedigree: diagonal genetic truth, clear one-factor truth, weak one-factor truth and uniqueness close to the matched floor. Use 50 observed animals initially, four complete traits and one observation per animal. Truth files must specify all pedigree IDs, founders/parents, X/Z, B, L, psi and R; generate genetic effects with A and residual effects independently. Do not center drawn genetic effects or delete their sampling variation.

Pre-run output is one manifest plus full candidate/start rows, selected/unavailable outcome, score difference, covariance error, floor/start flags, objective reevaluation, elapsed time and peak memory per dataset. The first file must be inspected immediately. All failed fits remain visible; blank/NA-only outputs stop the probe. The weak-factor dataset has no promised rank winner; it tests whether the system reports ambiguity rather than whether a noisy selector gets truth right.

Cost is not yet measured for the new selector. Prior fixed-rank full-suite receipts around eight minutes are not a per-dataset runtime estimate. Before launching, use the new implementation's first single dataset with a ten-minute owned timeout to measure fit cost; state this ten-minute cap, one Julia and one BLAS thread, and stop/re-report if it overruns. Only then estimate the remaining three datasets from observed elapsed time and memory. This is a future measurement proposal, not a run authorized by this design arc.

A few bounded fixtures may run locally. Serious replicated recovery belongs on Totoro, capped at 150 cores and normally one Julia/BLAS thread per replicate; DRAC is an alternative if queue/array needs justify it. Never compute on a DRAC login node, trigger Duo or run a campaign on GitHub Actions. For a projected run over three hours, show the pre-run result and complete simulation plan to Shinichi before full execution. No remote run is approved here.

## Proposed later scenario grid

Use informative pedigrees and complete T4 data, with observed-animal sample-size rungs 50,150,400 and a larger easy rung only if the pre-run permits a realistic compute budget. Four truths are primary: diagonal G (shared-factor K0), weak K1, clearly separated K1, and near-floor K1. A separately labelled G=0 witness is deliberate model misspecification because the fitted families require positive uniqueness. Uninformative and weak-information pedigree cases are separate identification/availability cells, not excluded fits that disappear from the denominator.

For every truth/sample-size cell, retain selected0, selected1, unavailable, interruption, timeout, failure mechanism, unattempted cases, criterion margins, eligible fractions, start/floor flags, covariance recovery and runtime/memory. Always report correct-rank fraction over all declared datasets, and separately the conditional fraction among selections. Unavailable counts as not correctly selected in the first fraction. Genetic covariance rank remains four in both strictly positive-uniqueness candidates; report shared-factor count rather than matrix rank.

Run real alternate starts, trait permutations, animal orderings and unit transforms as paired witnesses, not independent extra datasets. Test moderate rescaling away from the floor and deliberate crossing of the absolute floor separately. Equivalent score differences are required for cases whose parameter constraints map bijectively and whose reference objective agrees. A scale change that alters the feasible floor set must be reported as a contract limitation; it cannot be called invariance. No hidden standardization is allowed.

## Before a replicated study

Freeze the exact generating covariance/relationship files, numerical and optimizer controls, retry initializer, seeds, replicate count, sample-size ladder, machine/thread cap, command and observed runtime estimate. Freeze all denominator and failure classes before reading aggregate results. Do not choose a success cutoff after seeing a selection distribution or restart the old fixed-rank campaign.

The first later study is descriptive, with no promised universal correct-rank percentage. Choose replicate count from a prespecified Monte Carlo precision target and measured cost; for example, a worst-case binomial MCSE target of five percentage points requires at least 100 independent datasets per primary cell. This follows sqrt(0.25/m), not a statistical validity claim for the selector. The final grid and budget require a separate pre-run-supported campaign proposal.

Engineering acceptance requires every deterministic policy/reference witness to pass or be explicitly removed from supported scope. Clear-signal easy cells must demonstrate the deciding likelihood improvement against an independent same-model reference before descending to weak/small-sample cells. If they fail, classify simulator, objective, optimizer, criterion or bridge mechanisms before enlarging a study. Empirical rank frequency has no universal acceptance threshold in this design; reported results determine the strength and scope of any later usability claim.

Intervals and standard errors are conditional on selected rank. Coverage across a selected model requires its own predeclared inferential study; this plan supplies no confidence-level or biological-rank probability claim.

## Deliverables and ownership

Implementation proposal: exact narrow source/test changes, new internal floor-matched diagonal route, candidate wrapper/ledger, retry and identification checks, pure score tests and same-data references. It must identify ownership in both twins before editing either.

Diagnostic proposal: retained JSON/CSV truth/attempt manifests, per-cell tables and failed logs, explicit fixed-rank compatibility, source/runtime freeze, independent review and after-task report. R grammar remains reserved until a separate parity and public-contract decision. Protected GLLVM/gllvmTMB lanes and release/submission/GPU work are excluded.

V0 design closure is the present task's only acceptance claim. No V1-V4 implementation or performance evidence is produced here.
