# Artifact whitespace provenance

isolated-testthat.R is the verified R-generated deparse artifact. Its line-ending spaces are retained to preserve its recorded SHA-256. The actual authored package regression has no flagged trailing whitespace. The staged prose/code whitespace check excludes this one raw generated file, raw runtime logs, raw TSV delimiters and patch context. No source or test semantics changed during packaging.
