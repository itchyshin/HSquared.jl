# 2026-07-12 — repeatability ratio-bias mechanism analysis

- Goal: test the post-hoc finite-sample ratio-nonlinearity hypothesis using only the
  already-banked 2,000-seed TSVs; no new fits, seeds, resampling, or gate movement.
- Active lenses: Ada/Shannon (Julia-lane scope), Gauss (symbolic Hessian), Fisher/Curie
  (Monte Carlo decomposition), Rose (no-rescue wording). Read-only Fisher/Curie and
  Rose/Gauss plan reviews both approved with strict descriptive corrections.
- Symbolic-first target: exact identity
  `B_total = B_mean + B_nonlinear` for `g(s,e)=s/(s+e)`, plus divisor-`m`
  Hessian/covariance diagnostic and influence-function Monte Carlo intervals.
- Input integrity: SHA-256 pinned for the repeatability pooled TSV and all three supplied-K
  confirm TSVs; unique expected seed blocks; constant truth/config; 1,999/2,000 repeatability
  convergence; 2,000/2,000 per supplied-K cell; stored ratios reconstructed from components.
- Original gate reproduced before decomposition: repeatability bias `-0.00120188`, MCSE
  `0.00056574`, `gate_pass=false`; excluded seed `20280439` not imputed.
- Repeatability result: plug-in mean shift `-0.00012399` (10.3%); nonlinear averaging
  `-0.00107789` (89.7%, influence-function 95% MC interval
  `[-0.00115355,-0.00100222]`); second-order diagnostic `-0.00108957`, remainder
  `+0.00001168`.
- Supplied-K controls: negative nonlinear terms in all three cells (`-0.0007610` to
  `-0.0013731`) offset by positive mean shifts; the analysis-only ratio criteria pass. The
  original banked full gates passed separately and are not recomputed here. Contrast only,
  not repeatability validation or engine exoneration.
- Independent implementation: base-R recomputation of `m`, total bias, plug-in mean shift,
  and nonlinear term matched the Julia TSV to `<5e-11` for all four rows.
- Tests of tests: initial finite-difference Hessian self-test failed on Julia's `2f0`
  Float32-literal parse and was corrected before data access; stored-ratio serialization
  tolerance was calibrated from `%.10g` output (`2e-8`) and a `1e-6` mutation still fails;
  deliberately wrong SHA-256 exits 1; constant/proportional/order/permutation/Hessian
  self-tests pass.
- Package-isolation negative controls: the first full `Pkg.test()` reached the new testset and
  failed successively because `SHA` and `Statistics` were absent from the isolated test target.
  Added both explicitly to `[extras]`/`test`; the clean full-suite rerun passes.
- Local checks: full `Pkg.test()` PASS, including the new pure-logic ratio-decomposition
  testset; deterministic full rerun byte-identical at output SHA-256
  `e247d525bb0eed937dc52bb23f193a608ccf90094eb0a9bcc638b484ea3b5e05`;
  `git diff --check`, preamble cap, Rose pattern scan, after-task structure validator, and
  closeout compiler all PASS.
- Claim audit: post hoc, descriptive, convergence-conditional. V3-REPEAT-REML remains
  experimental/partial; doc-34 result remains failed; `public_covered_count` remains 5.
- Independent final Fisher/Rose audit: PROMOTE-WITH-CHANGES; numerical and inferential
  calculations independently matched to `3.8e-15`. Applied both requested precision fixes:
  exact ordered headers are now enforced and the analysis-only boolean is named
  `ratio_bias_pass`, not `gate_pass`.
