# Likelihood uncertainty repair: mathematical contract

## Full ratio with inactive components fixed

Let the reported ratio be r(theta) = theta_i / T, where T = sum_j theta_j. Let A be the retained component indices and B the inactive indices. The inactive values are held at their supplied estimates, not removed from T. For k in A,

    dr/dtheta_k = (1{k=i} T - theta_i) / T^2.

The information subblock I_AA corresponds to conditional covariance C_A = inverse(I_AA) when inactive coordinates have no sampling variation. The delta variance is g_A' C_A g_A. The repaired gradient applies the existing conditional-information construction to the reported full-denominator estimand. It does not claim that an arbitrarily selected inactive component is scientifically known, or that boundary intervals are calibrated.

For theta = [2, 1, 3], boundary_tol = .2 retains coordinates 1 and 3. Coordinate 2 is fixed at 1. The estimate is 1/3 and g_A = [4, -2]/36. With I = identity, SE = sqrt(20)/36 = 0.12422599874998833. Removing coordinate 2 from the denominator instead defines a different ratio, 2/5; that estimand is not the reported result. Central numerical derivatives with the inactive coordinate unchanged independently reproduce the full-ratio derivative. At an exact zero inactive component, the denominator agrees with the corresponding reduced model.

## Summed selector

For a nonempty set S of unique integer component indices, N = sum_{i in S} theta_i and r = N/T. The derivative is (1{k in S} T - N)/T^2. Duplicate indices previously counted multiple times in N but only once in the indicator. Rejecting duplicate, noninteger, Boolean, empty and out-of-range selectors makes the numerator and derivative use one declared set. Reversed unique indices preserve the result and do not reorder the variance vector.

## Average information docstring

For a Gaussian REML model with covariance V linear in variance components and residual projection P, define V_i = dV/dtheta_i. Observed information is

    I_observed,ij = y' P V_i P V_j P y - trace(P V_i P V_j)/2.
    I_expected,ij = trace(P V_i P V_j)/2.
    I_average,ij = y' P V_i P V_j P y / 2.

The working-variate quadratic therefore equals the arithmetic average of observed and expected information in this linear covariance parameterization. It need not equal the observed information itself. This statement does not supply a non-Gaussian Laplace information identity.

## Remaining numerical limits

Finite original and converted positive inputs are ingress requirements. Stable finite differences and identifiable variances require separate evidence. The component step must also remain finite and positive. Cancellation, large but finite perturbations, boundary behavior, nonconverged estimates and inference calibration remain conditional limitations. A finite supplied-point covariance is not evidence of an optimized or identifiable model.
