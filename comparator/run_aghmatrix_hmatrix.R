#!/usr/bin/env Rscript
# v0.8 S1 — AGHmatrix::Hmatrix same-estimand construction comparator
# OPT-IN, OUT of CI. Does NOT flip V2-SSHINV.
#
# Same estimand: Martini / Legarra H at tau=1, omega=1 (default Aguilar
# single-step). Compare inv(H_AGH) to engine single_step_inverse H⁻¹ after
# aligning by ID (AGHmatrix reorders).
#
#   1) julia --project=. comparator/prepare_aghmatrix_hmatrix.jl
#   2) Rscript comparator/run_aghmatrix_hmatrix.R
#
# Exits 0 on SKIP (AGHmatrix missing) or AGREE. Exits 1 on DISAGREE.

dir <- "comparator/aghmatrix_hmatrix"
if (!dir.exists(dir)) {
  stop("missing packet ", dir, " — run prepare_aghmatrix_hmatrix.jl first")
}

if (!requireNamespace("AGHmatrix", quietly = TRUE)) {
  cat("SKIP: AGHmatrix not installed (CRAN). Not a fail. Not a flip.\n")
  cat("COMPARATOR: SKIP\n")
  quit(status = 0L)
}

suppressMessages(library(AGHmatrix))

read_labeled <- function(path) {
  m <- as.matrix(read.csv(path, row.names = 1, check.names = FALSE))
  storage.mode(m) <- "double"
  m
}

A <- read_labeled(file.path(dir, "A.csv"))
G <- read_labeled(file.path(dir, "G.csv"))
Hinv_engine <- read_labeled(file.path(dir, "engine_hinv.csv"))

cat("AGHmatrix version:", as.character(packageVersion("AGHmatrix")), "\n")
cat("method=Martini tau=1 omega=1 (Legarra 2009 / Aguilar default)\n")

H_agh <- Hmatrix(A = A, G = G, method = "Martini", tau = 1, omega = 1)
ids <- rownames(Hinv_engine)
# AGHmatrix may reorder; compare in engine ID order.
missing <- setdiff(ids, rownames(H_agh))
if (length(missing)) {
  stop("AGHmatrix H is missing IDs: ", paste(missing, collapse = ","))
}
H_agh <- H_agh[ids, ids, drop = FALSE]
Hinv_agh <- solve(H_agh)

max_abs <- max(abs(Hinv_agh - Hinv_engine))
fro <- sqrt(sum((Hinv_agh - Hinv_engine)^2))
# Also H vs engine inv(Hinv)
H_engine <- read_labeled(file.path(dir, "engine_H.csv"))
max_abs_H <- max(abs(H_agh - H_engine))

tol <- 1e-8
agree <- is.finite(max_abs) && max_abs < tol && is.finite(max_abs_H) && max_abs_H < tol

out <- file.path(dir, "result.txt")
lines <- c(
  sprintf("AGHmatrix %s  method=Martini tau=1 omega=1", packageVersion("AGHmatrix")),
  sprintf("max|Hinv_agh - Hinv_engine| = %.6e", max_abs),
  sprintf("frobenius(Hinv delta)       = %.6e", fro),
  sprintf("max|H_agh - H_engine|       = %.6e", max_abs_H),
  sprintf("tol = %.1e", tol),
  sprintf("COMPARATOR: %s", ifelse(agree, "AGREE", "DISAGREE")),
  "NOT a covered flip. Mrode Ch.11 = explicit NO-ANCHOR."
)
writeLines(lines, out)
cat(paste(lines, collapse = "\n"), "\n", sep = "")
quit(status = ifelse(agree, 0L, 1L))
