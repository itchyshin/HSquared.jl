# Expanded-reference source review

Astra reviewed source `631cb34c3c2801771c4ab72a815695fa67b553e767b352fc2068568f2bed784f` and tests `a5fdbf8a7b3353fa670ba75399f5b72405d41a5aa2dcc9f614e9c22d14b3f0fc`. The 46 controlled assertions did not establish the frozen reference contract. No real reference fit was run. Luna high owns the following repairs before the next source review.

1. Apply floor-aware K0 starts: v=max(phen,2c), g=max(f*v,2c), R=Diag((1-f)*v). Tests must include tiny positive sample variances and a supplied matrix with nonzero off-diagonals.
2. Complete all K0 initial and refinement stages before constructing K1. Choose the best finite model-admissible point across those stages, regardless of optimizer acceptance; tie by earliest schedule index. Test both a refinement winner and a finite unaccepted winner.
3. Use an explicit vector of eight reference signs with s4 changing fastest. Test all eight literal patterns. A multidimensional Julia comprehension iterates in a different order and is unsuitable for this frozen schedule.
4. Retain valid intermediate maxima and parameters from BFGS, Nelder-Mead, terminal evaluation and independent gradient probes, even if a later evaluation throws. The default BFGS bypasses the reference objective wrapper, requiring the separately approved observation hook through BFGS, assessment and gradient sweeps. Test an intermediate improvement followed by a worse return or exception; the improvement must affect the 1e-4 audit comparison.
5. Preserve accepted, line_search_success, status and assessment reason. Failed line search must not be relabeled admissible. Finite unaccepted evidence still contributes to the best-found reference.
6. An available ordinary rank with no valid reference maximum is unresolved. Not-applicable is reserved for an unavailable ordinary rank; it must not silently pass an applicable audit.
7. A single invalid K1 mapping retains its own scheduled failure row and does not discard the other starts. No replacement or schedule shrinkage is allowed.

The nominal six/64 counts, four refinements per rank, 10,000/20,000/10,000 budgets, sample-variance convention, raw likelihood subtraction and best-found wording were consistent. They remain unchanged. The exact observation-hook decision and regressions are recorded in the design document. A fresh review and a bounded engineering smoke are required after repairs; this review supplies no reliability evidence.

## Fresh review of repaired source

Astra reviewed reference `d39ea56b73b0aca8b79c896de97a192b6851310ab8e35bff9f6f870d9ba2b609`, tests `70df6cdf5137568c8c0d63e006b965f0337823d3bff9d3ae5121ccb9184d8784` and engine hook `1c6f063656c123825c3115364979caecb29127c4600302d4a8d88477ee46231d`. The hook preserves ordinary numerical settings and covers initialization, cache misses, terminal assessment and gradient probes. The reference remains blocked on four repairs:

1. The default Nelder-Mead adapter receives the tracked objective but passes its untracked outer closure. Use the tracked argument and test the default adapter with a controlled Optim backend, without replacing the adapter itself.
2. Equal cross-stage likelihoods must choose the smaller schedule index, preserving the first observation within that index. Test a refinement of start 1 tying an earlier result from start 6.
3. Terminal admissibility requires a valid evaluation, optimizer convergence, independent gradient acceptance, no explicit line-search failure and no explicit optimizer rejection. Finite intermediate maxima remain reference evidence independently of terminal acceptance.
4. Save optimizer status and iteration metadata immediately after return, before assessment can throw. A throwing assessor must retain its better probe and completed optimizer metadata.

Luna high owns the reference source/test repairs only. The engine hook is frozen. No fits or test reruns were performed by Astra. Worker tests and fresh review are required before an engineering reference fit.

## Accepted repair and engineering replay

Astra accepted reference `894e477df9365af289d6eca48bcd7d6597344366d4ebd2fe31770a14ef369fa8` and tests `e461fae6bf116a962cf38b86740143e294aceec1647c1ab37b1717e133859dd1` after the four repairs. The engine hook remained `1c6f0636`. The parent independently reproduced 143 assertions in 11.80 seconds with unchanged hashes.

The first real expanded-reference run reused the retained Totoro N=80 strong-association engineering dataset. It completed 86 initial/refinement rows in 10.36 seconds of fitting, 12.29 seconds total. K0 and K1 likelihood shortfalls were 2.2737367544323206e-13 and 1.7053025658242404e-13, both within 1e-4. The source manifest and log hashes matched after retrieval; all processes exited zero. Full result, comparisons and resource log are retained under `.unlazy/arc1-gaussian-reliability/evidence/totoro-engineering-reference/retained/`. This is one best-found numerical comparison; scientific reliability gates remain open.
