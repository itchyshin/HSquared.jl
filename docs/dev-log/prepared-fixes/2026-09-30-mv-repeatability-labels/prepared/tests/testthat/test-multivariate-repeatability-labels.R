test_that("MV repeatability rejects conflicting labels and preserves valid results", {
  normalize <- hsquared:::hs_normalize_multivariate_repeatability_result
  e <- list(
    repeatability.hsquared_fit = hsquared:::repeatability.hsquared_fit,
    permanent_effects.hsquared_fit = hsquared:::permanent_effects.hsquared_fit
  )
  payload <- list(
    Y = matrix(c(1, NA, 3, 4), 2L), X = matrix(1, 2L, 1L),
    ids = c("a", "b"), pedigree = list(id = c("a", "b")),
    metadata = list(trait_names = c("height", "mass"), fixed_colnames = "Intercept")
  )
  raw <- list(
    traits = c("height", "mass"), breeding_ids = c("a", "b"),
    pe_ids = c("a", "b"), breeding_traits = c("height", "mass"),
    pe_traits = c("height", "mass"),
    genetic_covariance = diag(c(2, 3)), permanent_covariance = diag(c(1, 2)),
    residual_covariance = diag(c(4, 5)), genetic_correlation = diag(2),
    permanent_correlation = diag(2), residual_correlation = diag(2),
    beta = matrix(c(10, 20), 1L),
    breeding_values = matrix(c(101, 102, 201, 202), 2L),
    pe_values = matrix(c(301, 302, 401, 402), 2L),
    heritability = c(.2, .3), repeatability = c(.4, .5),
    converged = TRUE, iterations = 1L, loglik = -20
  )
  check <- function(ok, label) {
    expect_true(ok, info = label)
  }
  check_error <- function(expr, field, fragment, label) {
    msg <- tryCatch({ force(expr); NULL }, error = conditionMessage)
    check(!is.null(msg) && grepl(field, msg, fixed = TRUE) &&
      grepl(fragment, msg, fixed = TRUE), label)
  }
  z <- normalize(raw, payload)
  check(identical(z$breeding_values$id, c("a", "b", "a", "b")), "positive animal IDs")
  check(identical(z$breeding_values$trait, c("height", "height", "mass", "mass")), "positive traits")
  check(identical(z$breeding_values$value, c(101, 102, 201, 202)), "positive breeding values unchanged")
  check(identical(z$permanent_effects$value, c(301, 302, 401, 402)), "positive PE values unchanged")
  check(identical(z$fixed_effects$estimate, c(10, 20)), "positive fixed effects unchanged")
  check(identical(z$fixed_effects$trait, c("height", "mass")), "positive fixed trait labels")
  check(identical(unname(z$genetic_covariance), raw$genetic_covariance), "positive G unchanged")
  check(identical(unname(z$permanent_covariance), raw$permanent_covariance), "positive P unchanged")
  check(identical(unname(z$residual_covariance), raw$residual_covariance), "positive R unchanged")
  check(identical(colnames(z$genetic_covariance), raw$traits), "positive covariance labels")
  check(identical(z$heritability$estimate, raw$heritability), "positive heritability unchanged")
  check(identical(z$repeatability$estimate, raw$repeatability), "positive repeatability unchanged")
  check(identical(z$nobs, 3L) && identical(z$df, 11L), "observed trait record count and df")
  check(identical(z$loglik, -20) && z$converged, "likelihood and convergence retained")
  fit <- structure(list(result = z), class = "hsquared_fit")
  check(identical(e$repeatability.hsquared_fit(fit), z$repeatability), "actual repeatability extractor method")
  check(identical(e$permanent_effects.hsquared_fit(fit), z$permanent_effects), "actual PE extractor method")
  check(identical(z$diagnostics$component_names, c("animal", "permanent", "residual")), "optional component names legacy fallback")
  check(identical(z$diagnostics$status, "experimental"), "optional status legacy fallback")
  check(identical(z$diagnostics$target, "multivariate_repeatability_reml"), "optional estimator legacy fallback")

  # Every result label field is always emitted by the dedicated current caller.
  for (field in c("traits", "breeding_ids", "pe_ids", "breeding_traits", "pe_traits")) {
    expected <- raw[[field]]
    cases <- list(
      missing = NULL, reversed = rev(expected), duplicate = rep(expected[[1]], 2L),
      short = expected[1L], extra = c(expected, "extra"),
      missing_value = c(expected[1L], NA_character_), empty = c(expected[1L], ""),
      zero_length = character()
    )
    for (kind in names(cases)) {
      bad <- raw
      bad[[field]] <- cases[[kind]]
      fragment <- if (kind == "missing") "missing" else if (
        kind %in% c("duplicate", "missing_value", "empty")
      ) "unique, nonmissing and nonempty" else "same order"
      check_error(normalize(bad, payload), field, fragment, paste(field, kind))
    }
  }
  # Original four-assertion probe: conflicting effect labels and reversed global labels.
  bad <- raw
  bad$breeding_traits <- bad$pe_traits <- rev(raw$traits)
  check_error(normalize(bad, payload), "breeding_traits", "same order", "original effect-trait conflict")
  bad <- raw
  bad$traits <- rev(raw$traits)
  bad$breeding_ids <- rev(raw$breeding_ids)
  check_error(normalize(bad, payload), "traits", "same order", "original combined reversed labels")

  # Keep the caller's request-trait defaults, including response column names.
  p2 <- payload
  p2$metadata$trait_names <- NULL
  colnames(p2$Y) <- raw$traits
  check(identical(normalize(raw, p2)$breeding_values, z$breeding_values), "request colname trait fallback")
  p2 <- payload
  p2$metadata$trait_names <- NULL
  r2 <- raw
  r2$traits <- r2$breeding_traits <- r2$pe_traits <- c("trait1", "trait2")
  check(identical(normalize(r2, p2)$breeding_values$trait, rep(r2$traits, each = 2L)), "request generated trait fallback")

  # All normalized pedigree IDs are expected, including an unobserved ancestor.
  p3 <- payload
  p3$ids <- p3$pedigree$id <- c("a", "b", "ancestor")
  r3 <- raw
  r3$breeding_ids <- r3$pe_ids <- p3$ids
  r3$breeding_values <- matrix(c(101, 102, 103, 201, 202, 203), 3L)
  r3$pe_values <- matrix(c(301, 302, 303, 401, 402, 403), 3L)
  z3 <- normalize(r3, p3)
  check(identical(z3$breeding_values$id, rep(p3$ids, 2L)), "request pedigree IDs include ancestor")
  r3$pe_ids <- c("a", "b")
  check_error(normalize(r3, p3), "pe_ids", "same order", "PE observed subset cannot replace pedigree IDs")

  for (field in c("traits", "ids")) {
    pbad <- payload
    if (field == "traits") pbad$metadata$trait_names <- c("height", "height") else pbad$ids <- c("a", "a")
    check_error(normalize(raw, pbad), if (field == "traits") "trait" else "IDs", "Internal bridge error", paste("duplicate request", field))
  }
})
