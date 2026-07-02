#!/usr/bin/env Rscript
# Same-estimand REML comparator for the direct–maternal 2×2 G_dm estimator
# `fit_direct_maternal_reml` (src/likelihood.jl:1311; V4-DIRECT-MATERNAL covered
# evidence, Leg 2). Fits the SAME pedigree-A correlated direct+maternal model on the
# SAME data (predeclared seed 20264000) with sommer::mmes and checks that
# σ²_ad/σ²_am/σ_dm/σ²e agree with the engine's REML fit.
#
#   1) julia --project=. comparator/prepare_sommer_dm.jl   # writes sommer_dm/*
#   2) Rscript comparator/run_sommer_dm.R
#
# SOMMER CONSTRUCTION (direct–maternal):
#   random = ~ covm( vsm(ism(animal), Gu=A), vsm(ism(dam_id), Gu=A) )
#
# WHY THIS IS THE CORRECT PARAMETERIZATION:
#   The engine model is y_i = μ + a_d[animal(i)] + a_m[dam(i)] + e_i with
#   Var([a_d; a_m]) = G_dm ⊗ A (kron, 2q×2q). The full covariance structure is
#   W·(G_dm ⊗ A)·W' + σ²e·I, where W = [Z_d | Z_m] and Z_d/Z_m are the direct/
#   maternal incidence matrices.
#
#   covm(vsm(ism(animal), Gu=A), vsm(ism(dam_id), Gu=A)) builds exactly this:
#   - vsm(ism(animal), Gu=A): random term for the DIRECT genetic effect a_d.
#     ism(animal) is the n×q incidence matrix Z_d (record→own animal). Gu=A is the
#     pedigree relationship matrix for the q animals.
#   - vsm(ism(dam_id), Gu=A): random term for the MATERNAL genetic effect a_m.
#     ism(dam_id) is the n×q incidence matrix Z_m (record→dam). Gu=A is the SAME A.
#   - covm() merges these two terms and estimates an unstructured 2×2 covariance
#     (σ²_ad, σ_dm, σ²_am) between the two random effects — i.e., G_dm.
#   - sommer then forms the joint covariance as G_dm ⊗ A, matching the engine.
#
#   KEY DIFFERENCE FROM RR: in RR, both leg(t,0) and leg(t,1) coefficients belong
#   to the SAME animal's row in Z. Here, the DIRECT coefficient loads on the record's
#   OWN animal row (column in Z_d), and the MATERNAL coefficient loads on the DAM's
#   row (a DIFFERENT column in Z_m). Both Z_d and Z_m have q columns (the same q
#   pedigree positions), which is why covm() can merge them — the incidence matrices
#   are compatible even though they index DIFFERENT rows per record.
#
#   REFERENCE: sommer 4.4.5 vignette "sommer.qg" §6 Indirect genetic effects:
#   "random = ~ covm( vsm(ism(focal), Gu=Ai), vsm(ism(neighbour), Gu=Ai) )"
#   where `focal` and `neighbour` are different ID columns pointing to different
#   individuals in the dataset — structurally identical to our `animal` vs `dam_id`.
#   The Gu there is Ai (inverse, for henderson=TRUE); here we use raw A because
#   mmes() default is henderson=FALSE (direct inversion), for which Gu must be the
#   RAW covariance matrix, NOT the inverse (sommer docs: "Please DO NOT provide the
#   inverse, but rather the original covariance matrix when using henderson=FALSE").
#
# COLUMN CHECK (mandatory; see run_sommer_rr.R discipline):
#   We identify which varcomp row is σ²_ad (direct, on animal/own id), which is
#   σ²_am (maternal, on dam_id), and which is σ_dm (cross-covariance). The row
#   naming convention is "ran1:ran1", "ran2:ran2", "ran1:ran2" in the unstructured
#   covm block. We verify the ABSOLUTE variance entries, not just the correlation ρ
#   (ρ is invariant to diagonal rescaling → a ρ-only match is a FALSE PASS).
#
# AGREE if all four |rel.diff| < 0.02 (sommer AI-REML vs engine Nelder-Mead REML;
# same estimand, same optimum, different optimizers — ~1e-2 tolerance is standard;
# see run_sommer_rr.R).

suppressMessages(library(sommer))

dir <- "comparator/sommer_dm"
d <- read.csv(file.path(dir, "dm.csv"))
A <- as.matrix(read.csv(file.path(dir, "A.csv"), row.names = 1, check.names = FALSE))
q <- nrow(A)
cat(sprintf("Dataset: n=%d records, q=%d pedigree animals\n", nrow(d), q))

# Both `animal` and `dam_id` must share the SAME q-level factor set so that
# covm() gets two incidence matrices of the same width (q columns each). Without
# this, covm() would see different ncol and throw "matrices should have the same
# dimensions". Integer codes 1..q are used (written by prepare_sommer_dm.jl).
d$animal <- factor(as.character(d$animal), levels = as.character(1:q))
d$dam_id <- factor(as.character(d$dam_id), levels = as.character(1:q))

stopifnot(nlevels(d$animal) == q, nlevels(d$dam_id) == q)
cat(sprintf("Factor levels: animal=%d dam_id=%d (both must equal q=%d) OK\n",
            nlevels(d$animal), nlevels(d$dam_id), q))

# ── (1) COLUMN CHECK: identify the two incidence columns in sommer ────────────────
# For mmes (henderson=FALSE), sommer uses Gu = raw A (not inverse). When covm()
# merges vsm(ism(animal), Gu=A) and vsm(ism(dam_id), Gu=A), it builds a joint
# incidence matrix [Z_d | Z_m] and estimates an unstructured 2×2 G_dm. The varcomp
# names follow the pattern: the first vsm() term is "ran1", the second is "ran2".
# In sommer 4.4.5 the covm varcomp rows are named:
#   "...(ran1):(ran1)"  = σ²_ad  (direct variance, on animal / own id)
#   "...(ran2):(ran2)"  = σ²_am  (maternal variance, on dam_id)
#   "...(ran1):(ran2)"  = σ_dm   (direct–maternal covariance, can be negative)
# We verify that these names contain the term "animal" for ran1 and "dam_id" for ran2.

cat("\n=== COLUMN CHECK (which varcomp row = direct vs maternal vs covariance) ===\n")
cat("  - ran1 = vsm(ism(animal), Gu=A)  → σ²_ad (direct on OWN animal row)\n")
cat("  - ran2 = vsm(ism(dam_id), Gu=A)  → σ²_am (maternal on DAM's row)\n")
cat("  - ran1:ran2                       → σ_dm  (direct–maternal covariance)\n")
cat("  These point to DIFFERENT incidence columns per record (own vs dam row).\n")
cat("  Both Z matrices have q=", q, " columns (same pedigree level set) → covm OK.\n")

# ── (2) sommer REML fit: correlated direct + maternal with shared pedigree A ─────
# mmes default: henderson=FALSE (direct inversion). Gu must be the raw A matrix.
# nIters=100: standard for sommer AI-REML convergence on this problem size.
cat("\n=== Fitting sommer mmes (covm direct–maternal) ===\n")
cat("  random = ~ covm( vsm(ism(animal), Gu=A), vsm(ism(dam_id), Gu=A) )\n")
cat("  (mmes henderson=FALSE; Gu = raw A as required by direct-inversion mode)\n")
cat("  This may take a few minutes for q=996 ...\n")
flush.console()

fit_dm <- mmes(y ~ 1,
               random = ~ covm(vsm(ism(animal), Gu = A),
                                vsm(ism(dam_id),  Gu = A)),
               rcov = ~ units,
               data = d, verbose = FALSE,
               nIters = 100,
               dateWarning = FALSE)

vc <- summary(fit_dm)$varcomp
rn <- rownames(vc)
cat("\n=== sommer varcomp rows ===\n")
print(vc)

# ── (3) Extract the four components and perform the column check ──────────────────
# In sommer 4.4.5, covm() merges both vsm() names into a single compound row label.
# VERIFIED EMPIRICALLY from the output of this fit: all three G_dm rows contain
# BOTH "animal" AND "dam_id" in their names (because the merged covm term combines
# both factor names). The discriminating suffix is :ran1:ran1 / :ran1:ran2 / :ran2:ran2:
#   "animal:A:dam_id:ran1:ran1"  = σ²_ad  (direct variance, ran1 × ran1)
#   "animal:A:dam_id:ran1:ran2"  = σ_dm   (covariance, ran1 × ran2; can be negative)
#   "animal:A:dam_id:ran2:ran2"  = σ²_am  (maternal variance, ran2 × ran2)
# ran1 = vsm(ism(animal), Gu=A)  → direct effect, records → OWN animal row
# ran2 = vsm(ism(dam_id), Gu=A)  → maternal effect, records → DAM row
pick_first <- function(pat) {
  hits <- vc$VarComp[grepl(pat, rn, ignore.case = TRUE)]
  if (length(hits) == 0) NA_real_ else hits[1]
}

# Direct variance σ²_ad: suffix :ran1:ran1
s_ad <- pick_first(":ran1:ran1$")

# Maternal variance σ²_am: suffix :ran2:ran2
s_am <- pick_first(":ran2:ran2$")

# Cross-covariance σ_dm: suffix :ran1:ran2
s_dm <- pick_first(":ran1:ran2$")

# Residual σ²e
s_e <- pick_first("^units")

cat("\n=== COLUMN CHECK RESULT ===\n")
# In sommer 4.4.5 covm() output, ALL three G_dm rows contain both factor names
# (animal and dam_id) because the merged row label combines both vsm() terms.
# Discrimination is by the :ran1:ran1 / :ran1:ran2 / :ran2:ran2 suffix.
ad_row <- rn[grepl(":ran1:ran1$", rn)]
am_row <- rn[grepl(":ran2:ran2$", rn)]
dm_row <- rn[grepl(":ran1:ran2$", rn)]
cat(sprintf("  σ²_ad row name (:ran1:ran1): %s\n", if (length(ad_row)>0) ad_row[1] else "MISSING"))
cat(sprintf("  σ²_am row name (:ran2:ran2): %s\n", if (length(am_row)>0) am_row[1] else "MISSING"))
cat(sprintf("  σ_dm  row name (:ran1:ran2): %s\n", if (length(dm_row)>0) dm_row[1] else "MISSING"))
# Verify ran1 = animal (direct), ran2 = dam_id (maternal) from the merged names
ran1_is_animal <- length(ad_row) > 0 && grepl("animal", ad_row[1])
ran2_is_dam    <- length(am_row) > 0 && grepl("dam_id", am_row[1])
if (ran1_is_animal && ran2_is_dam) {
  cat("  COLUMN CHECK PASSED: ran1=animal (direct/own row), ran2=dam_id (maternal/dam row)\n")
} else {
  cat("  COLUMN CHECK WARN: ran1/ran2 assignment unclear — verify row names above.\n")
}
if (any(is.na(c(s_ad, s_am, s_dm, s_e)))) {
  cat("  WARN: one or more components NOT FOUND in varcomp — check row names above.\n")
  cat(sprintf("  s_ad=%s  s_am=%s  s_dm=%s  s_e=%s\n",
              format(s_ad), format(s_am), format(s_dm), format(s_e)))
} else {
  cat(sprintf("  σ²_ad (direct, animal row): %.6f\n", s_ad))
  cat(sprintf("  σ²_am (maternal, dam row):  %.6f\n", s_am))
  cat(sprintf("  σ_dm  (cross-covariance):  %.6f\n", s_dm))
  cat(sprintf("  σ²e   (residual):           %.6f\n", s_e))
}

# ── (4) Engine target ─────────────────────────────────────────────────────────────
tg <- read.csv(file.path(dir, "engine_target.csv"), stringsAsFactors = FALSE)
val <- function(k) as.numeric(tg$value[tg$quantity == k])
e_ad <- val("sigma_ad")
e_am <- val("sigma_am")
e_dm <- val("sigma_dm")
e_e  <- val("sigma_e2")

reldiff <- function(a, b) abs(a - b) / max(abs(a), abs(b), 1e-8)

cat("\n=== ENGINE vs SOMMER (absolute variance entries) ===\n")
rows <- list(
  c("sigma_ad", e_ad, s_ad),
  c("sigma_am", e_am, s_am),
  c("sigma_dm", e_dm, s_dm),
  c("sigma_e2", e_e,  s_e)
)
cat(sprintf("%-10s %12s %12s %10s\n", "component", "engine", "sommer", "rel.diff"))
rds <- numeric(length(rows))
for (i in seq_along(rows)) {
  eng <- as.numeric(rows[[i]][2]); som <- as.numeric(rows[[i]][3])
  rds[i] <- reldiff(eng, som)
  cat(sprintf("%-10s %12.6f %12.6f %10.2e\n", rows[[i]][1], eng, som, rds[i]))
}
# Genetic correlation (reported, not the pass criterion)
r_am_e <- e_dm / sqrt(e_ad * e_am)
r_am_s <- if (!any(is.na(c(s_ad, s_am, s_dm)))) s_dm / sqrt(s_ad * s_am) else NA
cat(sprintf("  r_am: engine=%.6f  sommer=%.6f  (REPORTED; not the pass criterion)\n",
            r_am_e, r_am_s))

# ── (5) Agreement verdict ─────────────────────────────────────────────────────────
tol <- 0.02
all_found  <- !any(is.na(c(s_ad, s_am, s_dm, s_e)))
agree_vc   <- all_found && all(is.finite(rds)) && all(rds < tol)
cat(sprintf("\nCOMPARATOR: %s  (all found=%s; max rel.diff %.2e on σ²_ad/σ²_am/σ_dm/σ²e, tol %.0e)\n",
            ifelse(agree_vc, "AGREE", "DISAGREE"),
            ifelse(all_found, "TRUE", "FALSE"),
            max(rds, na.rm = TRUE), tol))
quit(status = ifelse(agree_vc, 0L, 1L))
