Sys.setenv(HSQUARED_JULIA_PROJECT = Sys.getenv("JL_DIR"))
Sys.setenv(PATH = paste("/Users/szymek/.juliaup/bin", Sys.getenv("PATH"), sep=":"))
suppressMessages({library(hsquared); library(JuliaCall); library(Matrix)})
S <- Sys.getenv("AUDIT_DIR"); P <- readRDS(file.path(S,"prepared.rds"))
dat <- P$dat_cs; ped <- P$ped_analysis
X <- model.matrix(~ year_f + round_f + exp_manip + female.age, data = dat)
y <- dat$clutch_size
ids <- ped$id
pos <- match(as.character(dat$animal), ids)
Z <- sparseMatrix(i = seq_along(y), j = pos, x = 1, dims = c(length(y), length(ids)))

julia_setup(JULIA_HOME = "/Users/szymek/.juliaup/bin", verbose = FALSE)
julia_command(sprintf('import Pkg; Pkg.activate("%s"); using HSquared, SparseArrays, LinearAlgebra', Sys.getenv("JL_DIR")))
tt <- function(f, n=3) min(sapply(seq_len(n), function(i) system.time(f())["elapsed"]))

assign_all <- function() {
  julia_assign("hsq_y", as.numeric(y)); julia_assign("hsq_X", as.matrix(X))
  julia_assign("hsq_id", as.character(ids))
  julia_assign("hsq_sire", ifelse(is.na(ped$sire), "0", as.character(ped$sire)))
  julia_assign("hsq_dam",  ifelse(is.na(ped$dam),  "0", as.character(ped$dam)))
  julia_assign("hsq_Zi", as.integer(seq_along(y))); julia_assign("hsq_Zj", as.integer(pos))
  julia_command(sprintf("hsq_Z = sparse(hsq_Zi, hsq_Zj, ones(%d), %d, %d);", length(y), length(y), length(ids)))
}
t_marshal <- tt(assign_all)
t_setup <- tt(function() julia_command(paste(
  "hsq_ped = HSquared.normalize_pedigree(hsq_id, hsq_sire, hsq_dam);",
  "hsq_Ainv = HSquared.pedigree_inverse(hsq_ped);",
  "hsq_Ipe = spdiagm(0 => ones(size(hsq_Ainv,1)));",
  "hsq_eff = [(hsq_Z, hsq_Ainv), (hsq_Z, hsq_Ipe)];")))
t_fit <- tt(function() julia_command("hsq_fit = HSquared.fit_multi_effect(hsq_y, hsq_X, hsq_eff; method=:auto, verbose=false);"))
t_post3 <- tt(function() julia_command(paste(
  "hsq_vcse = HSquared.multi_effect_variance_component_standard_errors(hsq_y,hsq_X,hsq_eff,hsq_fit.variance_components.sigmas,hsq_fit.variance_components.sigma_e2);",
  "hsq_rse = HSquared.multi_effect_ratio_standard_errors(hsq_y,hsq_X,hsq_eff,hsq_fit.variance_components.sigmas,hsq_fit.variance_components.sigma_e2);",
  "hsq_ri = HSquared.multi_effect_sum_ratio_interval(hsq_y,hsq_X,hsq_eff,hsq_fit.variance_components.sigmas,hsq_fit.variance_components.sigma_e2; which=1:2);")))
t_post1 <- tt(function() julia_command("hsq_unc = HSquared.multi_effect_uncertainty(hsq_y,hsq_X,hsq_eff,hsq_fit.variance_components.sigmas,hsq_fit.variance_components.sigma_e2);"))
t_extract <- tt(function() julia_eval(paste(
  "let s=hsq_fit.variance_components.sigmas, e=hsq_fit.variance_components.sigma_e2;",
  "Dict(\"sigma_a2\"=>s[1],\"sigma_pe2\"=>s[2],\"sigma_e2\"=>e,",
  "\"beta\"=>collect(Float64,hsq_fit.beta),",
  "\"animal_ids\"=>string.(hsq_ped.ids[collect(hsq_fit.effects[1].ids)]),",
  "\"animal_values\"=>collect(Float64,hsq_fit.effects[1].values),",
  "\"pe_ids\"=>string.(hsq_ped.ids[collect(hsq_fit.effects[2].ids)]),",
  "\"pe_values\"=>collect(Float64,hsq_fit.effects[2].values),",
  "\"loglik\"=>hsq_fit.loglik,\"converged\"=>hsq_fit.converged) end")))
cat(sprintf("\n--- bridge stage split (best of 3, warm) ---\n"))
cat(sprintf("R->Julia marshalling (y,X,Z,ped)   %6.3f s\n", t_marshal))
cat(sprintf("pedigree + Ainv + effects          %6.3f s\n", t_setup))
cat(sprintf("fit_multi_effect                   %6.3f s\n", t_fit))
cat(sprintf("post-fit: three calls (R main)     %6.3f s\n", t_post3))
cat(sprintf("post-fit: one call (#238)          %6.3f s\n", t_post1))
cat(sprintf("Julia->R result extraction         %6.3f s\n", t_extract))
cat(sprintf("TOTAL, R main path                 %6.3f s\n", t_marshal+t_setup+t_fit+t_post3+t_extract))
cat(sprintf("TOTAL, with #238                   %6.3f s\n", t_marshal+t_setup+t_fit+t_post1+t_extract))
