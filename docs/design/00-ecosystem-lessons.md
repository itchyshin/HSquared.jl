# Ecosystem Lessons

Phase -1 exists so `HSquared.jl` learns before it builds.

## Borrowed From drmTMB

- Keep fitted, experimental, planned, and missing support visibly separate.
- Pair syntax with equations and interpretation.
- Treat check logs, after-task reports, and capability tables as part of the
  product.
- Do not let roadmap language count as implementation.

## Borrowed From DRM.jl

- Treat the Julia package as a faithful engine twin of an R-facing package.
- Use a named team constitution and a Rose pre-publication audit.
- Keep R parity and bridge behavior explicit rather than implicit.
- Preserve license boundaries: use generated outputs and conceptual lessons,
  not copied incompatible source.

## Borrowed From gllvmTMB

- Keep reader-first documentation and long/wide data-shape gates.
- Maintain validation rows before public claims.
- Teach covariance structures with stable symbols, syntax, and extractors.
- Restore or publish articles only when examples, diagnostics, and status rows
  agree.

## Borrowed From GLLVM.jl

- Make performance claims only after measured benchmarks.
- State limitations plainly.
- Use Julia-native tests and quality gates before widening the public surface.
- Exploit sparse and low-rank structure where the model allows it.

## Adapted For hsquared

`hsquared` needs stronger animal-model and quantitative-genetic lenses:
Henderson, Mendel, Falconer, Kirkpatrick, and Mrode are added to the standing
review culture.

## Refused

- No copied statistical claims from sibling projects.
- No dense relationship matrices by default.
- No public fitting examples until fitting exists.
- No R syntax promises that Julia cannot yet satisfy.
