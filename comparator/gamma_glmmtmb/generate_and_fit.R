# Gamma (log-link) same-estimand comparator: glmmTMB leg.
# Generates a seeded Gamma GLMM dataset with an IID animal effect (== an A=I animal
# model), fits glmmTMB Gamma(link="log") + (1|id), and writes the data packet + the
# glmmTMB estimates for the Julia engine (`fit_laplace_reml(family=:gamma)`) to match.
suppressMessages(library(glmmTMB))
set.seed(20260701)
q <- 40; reps <- 4; n <- q * reps               # 40 animals × 4 records = 160 obs
id <- rep(1:q, each = reps)
sigma2a <- 0.35                                  # true animal (log-scale) variance
shape <- 3.0                                     # true Gamma shape ν
u <- rnorm(q, 0, sqrt(sigma2a))                  # animal effects
mu <- exp(0.6 + u[id])                           # intercept 0.6
y <- rgamma(n, shape = shape, rate = shape / mu) # mean = mu, shape = ν
d <- data.frame(y = y, id = factor(id))

m <- glmmTMB(y ~ 1 + (1 | id), family = Gamma(link = "log"), data = d)
animal_var <- as.numeric(VarCorr(m)$cond$id[1, 1])   # σ²a estimate
shape_hat  <- 1 / sigma(m)^2                          # glmmTMB Gamma dispersion → shape
intercept  <- as.numeric(fixef(m)$cond[1])

dir.create("comparator/gamma_glmmtmb/packet", showWarnings = FALSE, recursive = TRUE)
write.csv(data.frame(y = y, id = id), "comparator/gamma_glmmtmb/packet/data.csv", row.names = FALSE)
writeLines(c(
  sprintf("truth_sigma2a %.10f", sigma2a),
  sprintf("truth_shape %.10f", shape),
  sprintf("truth_intercept %.10f", 0.6),
  sprintf("glmmtmb_sigma2a %.10f", animal_var),
  sprintf("glmmtmb_shape %.10f", shape_hat),
  sprintf("glmmtmb_intercept %.10f", intercept),
  sprintf("n %d", n), sprintf("q %d", q)
), "comparator/gamma_glmmtmb/packet/glmmtmb_est.txt")
cat("glmmTMB: sigma2a=", round(animal_var, 5), " shape=", round(shape_hat, 4),
    " intercept=", round(intercept, 4), "\nGENERATE_OK\n")
