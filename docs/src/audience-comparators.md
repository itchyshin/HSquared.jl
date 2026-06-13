# Audience And Comparators

`HSquared.jl` is being built for people who need quantitative-genetic models to
work on real breeding and evolutionary data.

## Who It Is For

- livestock and aquaculture breeders;
- plant breeders;
- evolutionary geneticists;
- ecological quantitative geneticists;
- genomic prediction users;
- applied students and analysts who need readable errors and extractors.

## What They Need

The package should make common work straightforward:

- fit pedigree and genomic animal models from R;
- construct relationship precision matrices without hidden dense conversions;
- extract breeding values, variance components, heritability, genetic
  correlations, G matrices, and uncertainty;
- compare models with diagnostics that distinguish weak evidence from software
  failure;
- move from R syntax to a Julia engine through a bridge.

## Comparator Discipline

`HSquared.jl` should be tested against the software users already trust:
ASReml, BLUPF90, DMU, WOMBAT, sommer, MCMCglmm, JWAS, AGHmatrix, nadiv, and
XSim-based simulations where appropriate.

The ambition is to become a free, open, benchmarked engine for pedigree,
genomic, livestock, plant-breeding, and evolutionary quantitative genetics.
That is a roadmap goal. It is not yet a benchmark claim.

Any public speed or superiority claim must report the machine, software
versions, model, data size, number of records, animals, traits, nonzeros,
memory use, convergence diagnostics, and the exact comparator estimand.
