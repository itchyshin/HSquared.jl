# Phase 1G Henderson MME Validation Fixture

Date: 2026-06-13

Active lenses: Ada, Henderson, Mrode, Gauss, Fisher, Curie, Rose.

Spawned subagents: none.

## Scope

Add a deterministic validation fixture that compares dense marginal outputs
against Henderson mixed-model equations at supplied variance components.

This is validation infrastructure only. It is not a full Mrode textbook
reproduction and not an external comparator run.

## Implementation

Added a test-only MME solver:

```text
[X'R^-1X   X'R^-1Z      ] [beta] = [X'R^-1y]
[Z'R^-1X   Z'R^-1Z+G^-1] [u   ]   [Z'R^-1y]
```

where `G^-1 = Ainv / sigma_a2` and `R^-1 = I / sigma_e2`.

The fixture uses:

- five normalized pedigree IDs;
- founders and offspring;
- a sparse animal-effect design `Z`;
- repeated observations for one animal;
- a two-column fixed-effect design;
- supplied additive and residual variance components.

## Tests

The test compares:

- fixed effects;
- breeding values;
- fitted values;
- heritability.

Local check:

- `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 105 checks.

## Documentation

Updated validation canon, capability status, validation debt, public claims
register, changelog, check log, and this after-task report.

## Rose Audit

Verdict: clean with limitations.

Allowed wording:

- dense output-path extractors are cross-checked against a Henderson MME
  fixture.

Blocked wording:

- Mrode textbook validation is complete;
- external comparator validation is complete;
- sparse production MME solving is implemented.

## Next Work

1. Add a real Mrode example with source-recorded expected values.
2. Add cross-repo R-to-Julia marshalling tests.
3. Start sparse production MME or AI-REML design.
