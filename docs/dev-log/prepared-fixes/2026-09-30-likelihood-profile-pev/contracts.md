# Frozen helper contracts (before implementation)

Base likelihood SHA-256: 90cc76897c2b977f4bebc456d1e6c8d8f2647a7bb7ec6e8c9135884da0f17e30.

1. Profile inversion: T(anchor)<0; all evaluated T and both coordinates must be finite. If T(bound)<=0 return the evaluated bound; otherwise preserve the negative/positive bracket until a finite crossing is resolved. NaN/Inf is failure, never evidence for an endpoint. Continuity and a scientifically justified maximum remain caller assumptions.
2. Reliability for caller IDs j: r_j=1-p_j/(VA*A_jj). PEV is finite nonnegative, VA and A_jj finite strictly positive after Float64 conversion. PEV IDs must be a bijection of spec IDs, and output follows caller order. Products need not themselves fit Float64 if the ratio does; reject nonfinite final ratios. Negative reliability remains visible, never clipped.
3. Gaussian h²=VA/(VA+VE)=(VA/s)/(VA/s+VE/s), s=max(VA,VE). Components must be finite nonnegative Float64, at least one positive. The estimand is unchanged; component/total arithmetic cannot turn (1.2e308,.8e308) into zero.
4. Bootstrap accepted-refit components must be finite strictly positive after Float64 conversion and refit converged. A summed overflow alone does not invalidate a finite h² ratio. Original-fit convergence, per-replicate failure taxonomy, inference validity and calibration remain separate debts.

No DGP or new estimand is introduced. Independent truths: profile quadratic crossings .3/.7; relationship diagonal [1,.5,.25] from diagonal precision [1,2,4]; exact rational h²=3/5; BigFloat ratio oracle for exponent extremes. Tests are constructed supplied-variance containers, not fitted-model evidence.
