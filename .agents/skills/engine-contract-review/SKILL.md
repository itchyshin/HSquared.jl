---
name: engine-contract-review
description: Review the HSquared.jl engine contract for input payloads, result shape, storage policy, diagnostics, controls, and numerical assumptions. Use when changing docs or code at the R-Julia boundary or Julia engine API.
---

# Engine Contract Review

## Procedure

1. Read `docs/design/03-engine-contract.md`.
2. Confirm the payload includes only v0.1-supported concepts.
3. Confirm result fields are compact and R-marshalable.
4. Ask Gauss and Karpinski whether the storage and sparse-matrix policy avoids
   accidental densification.
5. Ask Hopper whether the result shape can become an R S3 object.
6. Ask Rose whether docs imply user-selectable algorithms before controls
   exist.

## Output

Return approved payload fields, result fields, deferred fields, and wording
risks.
