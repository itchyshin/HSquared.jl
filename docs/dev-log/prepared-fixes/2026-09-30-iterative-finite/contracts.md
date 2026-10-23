# Frozen finite arithmetic contracts, before implementation

Base: iterative_solve.jl a4adfe04fe736fd55039b329d9d1d1fa4083b02478dc33c60181c7c453c42132.

I1: All observed y and supplied X/Z entries must be finite before and after Float64 conversion, independently of structural zeros hiding values from an MME product. This is an input contract, not a rank or identification test. Existing sparse rank and precision helpers must remain byte-identical.

I2: Successful finite data evaluation requires finite PCG operands/returned solution, likelihood and information entries. An unsupported intermediate/final Float64 range must produce a clear ArgumentError, not a numeric Inf masquerading as a result. Standalone finite unconverged PCG results remain inspectable. MCSE with one probe remains undefined (NaN), and intentionally skipped fit likelihood remains NaN.

I3: With s=max(theta), r_i=(theta_i/s)/sum(theta/s). Final MC-fit ratios and boundary flags use this mathematically identical scale-safe ratio. Finite components 1.2e308 and7.2e307 yield .625, regardless of an unrepresentable unscaled total.

I4: For finite sample vector t, mean and MCSE are scale-safe evaluations of mean(t) and sqrt(sum((t-mean(t))^2)/(n-1)/n). Identical samples1.2e308 have mean1.2e308 and MCSE0. Scaling must preserve ddof=1 and undefined n=1 MCSE.

Truth/control alignment: zero incidence means C=Q/a, u=0, trace(Q*C^-1)=a, P=I/e; the independent ordinary Gaussian likelihood and AI follow immediately. Large scalar ratio uses BigFloat oracle. One fixed-point update is a deterministic constructed arithmetic fixture, not a recovery/calibration claim. Final BLUP and trace diagnostics are evaluated at returned variances. Invalid update proposals currently retain the previous valid iterate with converged=false; failure-reason metadata is not expanded in this repair.
