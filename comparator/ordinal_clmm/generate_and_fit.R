# Ordinal (cumulative probit) same-estimand comparator: ordinal::clmm leg.
# glmmTMB CANNOT fit cumulative-link ordinal models; `ordinal::clmm` (Laplace-ML) is the
# correct same-estimand tool. Generates seeded K=3 ordered-probit data with an IID animal
# effect (== an A=I animal model) + repeated records, fits clmm(link="probit") + (1|id),
# and writes the packet for the engine `fit_laplace_reml(family=:ordered_probit)` to match.
suppressMessages(library(ordinal))
set.seed(20260701)
q <- 80; reps <- 4; n <- q * reps               # 80 animals × 4 records = 320 obs (informative)
id <- rep(1:q, each = reps)
sigma2a <- 0.5                                  # true animal (probit-latent) variance
u <- rnorm(q, 0, sqrt(sigma2a))
# latent liability l = u + e, e ~ N(0,1); cutpoints on the latent scale
cut <- c(-0.4, 0.8)                             # true K-1=2 thresholds (clmm convention, no intercept)
l <- u[id] + rnorm(n)
ycat <- 1 + (l > cut[1]) + (l > cut[2])          # categories 1..3
d <- data.frame(y = ordered(ycat), id = factor(id))

m <- clmm(y ~ 1 + (1 | id), data = d, link = "probit")
th <- as.numeric(m$Theta)                        # clmm thresholds θ_1, θ_2
s2 <- as.numeric(m$ST[[1]])^2                     # clmm random-effect variance (SD^2)

write.csv(data.frame(y = ycat, id = id), "comparator/ordinal_clmm/packet/data.csv", row.names = FALSE)
writeLines(c(
  sprintf("truth_sigma2a %.10f", sigma2a),
  sprintf("truth_cut1 %.10f", cut[1]), sprintf("truth_cut2 %.10f", cut[2]),
  sprintf("clmm_sigma2a %.10f", s2),
  sprintf("clmm_theta1 %.10f", th[1]), sprintf("clmm_theta2 %.10f", th[2]),
  sprintf("n %d", n), sprintf("q %d", q)
), "comparator/ordinal_clmm/packet/clmm_est.txt")
cat("clmm: sigma2a=", round(s2, 5), " thresholds=", round(th, 4),
    " spacing=", round(th[2]-th[1], 4), "\nGENERATE_OK\n")
