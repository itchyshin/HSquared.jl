# H3 Totoro feasibility receipt — read-only

## Scope

This is a connectivity and provisioning observation only.  It is not a smoke,
fit, simulation, transfer, precompile, promotion, or release action.

## Live observation

Using the existing reuse-only Totoro ControlMaster socket on 2026-09-09:

- host responded as `totoro`;
- Julia launcher: `/home/snakagaw/.juliaup/bin/julia`;
- Julia version: `1.12.6`;
- existing `~/hsq_work/HSquared.jl` commit:
  `3762eff09144f1da88de4f83ba872ffff7507d80`.

## Consequence

The existing checkout is not the H3 candidate `82f836f3`, and the local sealed
lock was generated under Julia 1.10.0.  A later separately authorized smoke
must therefore transfer a hash-verified sealed candidate bundle plus the
ignored local `Manifest.toml`, precompile exactly once on Totoro, retain that
receipt, and then run only the ratified one-thread PATH_ONLY command.  This
receipt authorizes none of those later actions.
