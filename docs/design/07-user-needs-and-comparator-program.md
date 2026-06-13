# User Needs And Comparator Program

`hsquared` / `HSquared.jl` should be useful because it solves real user
problems, not because it exposes clever machinery.

## Core Users

- livestock breeders;
- plant breeders;
- quantitative geneticists;
- evolutionary geneticists;
- ecology/evolution researchers fitting animal models;
- genomic prediction users;
- applied graduate students who need readable diagnostics and examples.

## User Needs

Users need:

- formula syntax that feels familiar from R mixed-model packages;
- clear pedigree, genomic, and custom relationship input rules;
- free, reproducible, benchmarked fitting;
- honest diagnostics when models are weakly identified;
- extractors for breeding values, variance components, heritability, genetic
  correlations, G matrices, and uncertainty;
- examples in livestock, plant breeding, and evolutionary ecology;
- bridge access from R so they can use a Julia engine without becoming Julia
  programmers on day one.

## Comparator Targets

The package should learn from and compare against:

- ASReml;
- BLUPF90;
- DMU;
- WOMBAT;
- sommer;
- MCMCglmm;
- JWAS;
- AGHmatrix;
- nadiv;
- XSim.

These are comparator targets, not public claims of superiority.

## Formula-Parity Requirement

The easiest path for users is:

```r
hsquared(..., engine = "julia")
```

with R syntax that remains stable and Julia code that computes the same model
intent. Any direct Julia syntax should stay close enough to the R syntax that a
user can move between them without relearning the model language.

## Evidence Gate

The long-term ambition is to be a free, open, benchmarked engine that can
compete with proprietary and production animal-breeding software. Public
wording must not say it is faster, more accurate, or a replacement for any
comparator until the claim has benchmark evidence with:

- software versions;
- machine and hardware details;
- data size and pedigree/genomic dimensions;
- number of records, animals, traits, and nonzeros;
- model specification;
- estimator and convergence diagnostics;
- accuracy comparison against the same estimand.
