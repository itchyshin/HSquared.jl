# v0.7 genomic activation — fresh exact-kernel BLUPF90 comparator (2026-07-12)

This checkpoint replaces a proposed transitive reuse of the 2026-06-30 packet with a fresh,
hash-pinned run. The older run remains valid as fixed-precision solver evidence, but its generated
packet had no contemporaneously banked precision checksum and its simulation covariance used a
different ridge. It therefore could not support the exact raw-markers-to-supplied-precision link
required by the v0.7 activation contract.

## Frozen model and construction

`comparator/prepare_blupf90_genomic.jl` generated one deterministic fixture (seed `20260630`,
`n = 300`, `m = 1000`) using the activation construction exactly:

```text
p_j = mean(M[:,j]) / 2
W = M - 2p
k = 2 sum(p_j (1-p_j))
G = WW' / k
K_lambda = G + 0.01 I
Q_lambda = inv(K_lambda)
u ~ N(0, 0.6 K_lambda), e ~ N(0, 0.4 I)
```

BLUPF90 received all upper-triangular entries of that exact `Q_lambda` at `%.17g`; no numerical
thresholding was applied. It fitted the same intercept-only Gaussian REML model from neutral
variance starts `(1.0, 1.0)`.

## Executable and immutable identities

- Julia: 1.10.0.
- `blupf90+`: 2.60, Mac x86_64 under Rosetta.
- BLUPF90 binary SHA256: `31c5a0f227d517a6a41b018dbb61fbb06b8aa022b4c6f3fd1c4476db888da5b3`.
- marker fingerprint: `566212f7e4b24ea8b4937e50abeeec5620f540ae9667ae008c4b19dbb72af5e5`.
- kernel fingerprint: `0c2f8d17783f4805cb1966e153cc8181eab6675d27482885c76ea273aefabed1`.
- precision fingerprint: `4542182ab8cf25d98f898c3a78eb3f439e51db9580787b3e41d8b2c79c7a4024`.
- emitted `ginv.txt` SHA256: `a8219695c57b36f99bdb916ad585e10d3cda4601cfa25c391e00de9898b343d7`.
- captured BLUPF90 log SHA256: `841b27cf4b2328713017d3116c5137d23ab2a6b8ece219097247c18e147428d9`.
- BLUPF90 solutions SHA256: `11691d702a037d537a0a27e879d27ee3cf9786101b082ab5511ff199ea10cb29`.

The generated packet and raw output remain local and git-ignored. These hashes, the tracked
generator, and the compact numerical result are the durable evidence.

## Agreement

| Quantity | HSquared.jl | BLUPF90+ 2.60 | absolute difference |
|---|---:|---:|---:|
| genomic coefficient variance | 0.580074164750 | 0.58007 | 4.16e-06 |
| residual variance | 0.389692330915 | 0.38969 | 2.33e-06 |
| genomic variance ratio | 0.598158595232 | 0.598158307210 | 2.88e-07 |

BLUPF90 converged independently from neutral starts. Its variance-component stdout is printed to
five significant figures, so the observed component differences are bounded by that printout
resolution. The ratio shown above is derived from those printed components.

## Evidence chain and boundary

This run closes the previously missing exact-precision link:

```text
raw markers -> frozen VanRaden1 + 0.01I -> fingerprinted Q_lambda
            -> HSquared.jl supplied-Q REML == BLUPF90 supplied-Q REML
```

It is one same-estimand point-estimate comparison. It is not a recovery campaign, interval
calibration, production-scale claim, unregularized SNP-BLUP equivalence, or evidence that every
external package uses this construction by default. It does not change a capability row or a
public covered count. Broad R activation still requires the preregistered nine-cell recovery gate,
cross-twin live tests, and final Rose/G10 decisions.

## Reproduce

```sh
OPENBLAS_NUM_THREADS=1 julia --project=. comparator/prepare_blupf90_genomic.jl
cd comparator/blupf90_genomic
echo renf90.par | arch -x86_64 ~/blupf90_bin/blupf90+
```

