using HSquared
using LinearAlgebra
using Printf
using Random
using Statistics

# Pre-declared known-truth recovery gate for the DIRECT–MATERNAL 2×2 genetic-covariance
# REML estimator (`fit_direct_maternal_reml`, `src/likelihood.jl:1311`) — the doc-16
# substitutable covered gate for a V4-DIRECT-MATERNAL `partial → covered` close, SCOPED to
# the correlated direct (a_d) + maternal (a_m) additive animal model with a 2×2 G_dm.
#
# ============================ THE CONFOUND (design against it) ============================
# a_d and a_m are correlated ACROSS ANIMALS through the SHARED pedigree relationship A
# (Var([a_d;a_m]) = kron(G_dm, A); Cov(a_d[i], a_m[i]) = σ_dm). If the design does not let
# an individual's a_d AND its a_m both enter the data, σ_dm trades off against σ²_ad and the
# estimator returns an ARTIFACTUAL strong-negative r_am (the documented direct–maternal
# identifiability controversy). A DGP that does not break this confound yields a GREEN-BUT-
# VOID gate — a biased estimator passes, or a correct one fails. Getting the confound-
# breaking DGP right IS the job.
#
# WHAT BREAKS IT (all four levers built in):
#   (1) DAMS with BOTH their own record AND several recorded offspring — the single most
#       important lever (separates a female's DIRECT value, seen in her own record, from her
#       MATERNAL value, seen in her offspring's records).
#   (2) >= NOFF (=6) offspring per dam.
#   (3) >= 3 recorded, OVERLAPPING generations — the same individuals are both offspring
#       (a_d via own record) AND parents (a_m via offspring records).
#   (4) sires shared across dams (connectedness): NS sires mate ND dams each generation.
#
# DGP (deterministic pedigree; only the breeding values + residuals are random per seed):
#   founders (NS sires, ND dams; UNRECORDED) → gen1 → gen2 → gen3 (all recorded). Each
#   generation: ND dams (the previous generation's first ND females) × NS sires (round-robin
#   → sires shared) × NOFF offspring, sexes alternating. The dams of gen2 (gen1 females) and
#   of gen3 (gen2 females) are THEMSELVES recorded (own record) AND have NOFF offspring each
#   → these are the σ_dm-IDENTIFYING dams (lever 1). Per-animal [a_d, a_m] ~ N(0, kron(G_dm, A))
#   drawn as chol(A).L · Ξ · chol(G_dm).L' (Ξ q×2 iid-N(0,1)); records
#   y_r = μ + a_d[animal(r)] + a_m[dam(r)] + e_r, e_r ~ N(0, σ²e).
#
# NEGATIVE CONTROL (safeguard iv; run in the 3-seed diagnostic, NOT the 48-seed gate):
#   `build_context(dam_own_records=false)` DROPS the dams' own records (dams appear
#   offspring-only) → ZERO identifying dams. This recreates the classic confounded design.
#   Diagnostic degradation (proving the gate is SENSITIVE to the confound, not blind to it):
#   at the SEVERE-confound scale (n=540/6-off) the NC COLLAPSES — r_am→+1, non-convergence,
#   information conditioning → Inf; at the locked n=960/8-off scale the NC no longer fully
#   collapses (8 offspring/dam still leak maternal info) but σ²am is clearly UNDER-estimated
#   (≈0.38 vs 0.50) and σ_dm shrinks toward 0 — the maternal signal is confounded away.
#
# PRE-DECLARED (see docs/dev-log/recovery-checkpoints/
# 2026-07-01-direct-maternal-recovery-gate-predeclaration.md, committed BEFORE this runs;
# harness byte-identical pre/post):
#   - Truth: σ²_ad = 1.0, σ²_am = 0.5, r_am = -0.3 (σ_dm = -0.3·√(1.0·0.5) ≈ -0.21213),
#     σ²e = 1.0, μ = 2.0. Interior, off any boundary; the negative r_am is REAL and expected.
#   - Design: ND=30 dams, NS=6 sires, NOFF=8 offspring, 4 recorded generations
#     → n = 960 records, q = 996 animals (within the dense fence n² ≤ 1e6), 90 identifying dams.
#     (Chosen after a diagnostic sweep: n=540/6-off/60-dam still COLLAPSED ~1/12 seeds to the
#     r_am=±1 boundary — the unbroken confound; n=960/8-off/90-dam converges 12/12 with NO
#     boundary + finite conditioning. HONEST RESIDUAL: ~1/4 of seeds still show a WELL-CONDITIONED
#     confound artifact — σ_dm swinging strong-negative or a σ²ad/σ²am component inflating — so
#     the strict all-VC bias gate is a GENUINE test that may fail, esp. on σ²am; a 5-gen/100-dam
#     variant merely ROTATED the residual bias onto σ²ad, confirming a dense-scale limit.)
#   - Seeds: 20264000 .. 20264047 (48 cold-start; disjoint from every prior range —
#     two-effect 20260700.., neffect 20260800.., QTL 20260900../20261050../20261100..,
#     RR 20261000.., QTL-rebuild 20263000..; UNSEEN at declaration).
#   - Cold start: `initial = (G_dm = I₂, sigma_e2 = 1.0)` — NOT the truth.
#   - PASS (ALL; NO relaxation): 48/48 converged AND |bias| ≤ 2·MCSE for EACH of σ²_ad,
#     σ²_am, σ_dm (THE HEADLINE covariance) and σ²e; mean direct EBV accuracy ≥ EBV_ACC_D and
#     mean maternal EBV accuracy ≥ EBV_ACC_M; EVERY seed's information condition number <
#     COND_MAX (a DEGENERACY guard — near-singular info = a flat/severe-confound optimum; note
#     the mild residual artifacts at this scale are WELL-conditioned, so this guard flags only
#     degeneracy) and |r_am| < RAM_BOUND (off the ±1 boundary). The design must supply
#     ≥ MIN_IDENT_DAMS identifying dams (asserted once). r_am is REPORTED (skewed ratio), not gated.
#   - Read as NO DETECTABLE across-seed bias (a low-power non-rejection), never "unbiased".
#     A FAILURE is a banked negative — V4-DIRECT-MATERNAL stays partial.
#
#   env OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase4_direct_maternal_recovery_gate.jl
#
# Include-safe: `include`-ing this file defines the functions WITHOUT running the 48-seed
# gate (guarded by the PROGRAM_FILE check at the bottom), so the 3-seed / negative-control
# diagnostic can call `build_context` / `_fit` directly.

const MU = 2.0
const S_AD = 1.0                       # σ²_ad  (direct additive variance)
const S_AM = 0.5                       # σ²_am  (maternal additive variance)
const R_AM = -0.3                      # target direct–maternal genetic correlation
const S_DM = R_AM * sqrt(S_AD * S_AM)  # σ_dm ≈ -0.21213  (THE HEADLINE covariance)
const G_TRUTH = [S_AD S_DM; S_DM S_AM]
const SE = 1.0
const SEEDS = 20264000:20264047

# ---- design (deterministic pedigree) ----
const ND = 30      # dams per generation
const NS = 6       # sires per generation (shared across dams: round-robin)
const NOFF = 8     # recorded offspring per dam
const NGEN = 4     # recorded generations (founders unrecorded)

# ---- pre-declared safeguard thresholds (fixed from the diagnostic below; see predecl) ----
const MIN_OFFSPRING = 5      # a dam is "identifying" with own record AND >= this many offspring
const MIN_IDENT_DAMS = 72    # structural floor on identifying dams (this design gives 90)
const COND_MAX = 1.0e4       # per-seed information condition ceiling: a DEGENERACY guard (flat
                             # ridge → near-singular info → Inf, as the severe-confound n=540 NC
                             # showed); the well-conditioned main range is ~20-160, huge margin
const RAM_BOUND = 0.99       # fitted |r_am| must be off the ±1 boundary
const EBV_ACC_D = 0.55       # mean DIRECT EBV accuracy floor (bounded by h²_direct≈0.44 with one
                             # record/animal; diagnostic mean ≈0.65, so 0.55 is a margin floor)
const EBV_ACC_M = 0.65       # mean MATERNAL EBV accuracy floor (progeny-tested dams; diag mean ≈0.77)

# ---------- deterministic multi-generation maternal pedigree ----------
function build_maternal_pedigree(; nd::Int = ND, ns::Int = NS, noff::Int = NOFF,
                                 ngen::Int = NGEN, dam_own_records::Bool = true)
    ids = String[]; sirev = String[]; damv = String[]; sex = Char[]
    dam_of = Dict{String,String}()
    function add!(id, s, d, x)
        push!(ids, id); push!(sirev, s); push!(damv, d); push!(sex, x); dam_of[id] = d
    end
    fsires = ["fs$i" for i in 1:ns]
    fdams = ["fd$i" for i in 1:nd]
    for s in fsires; add!(s, "0", "0", 'M'); end
    for d in fdams;  add!(d, "0", "0", 'F'); end

    born = String[]              # all recorded-candidate (non-founder) ids
    counter = 0
    prev_dams = fdams; prev_sires = fsires
    for g in 1:ngen
        thisF = String[]; thisM = String[]
        for (j, dam) in enumerate(prev_dams)
            sire = prev_sires[((j - 1) % length(prev_sires)) + 1]   # sires shared (lever 4)
            for k in 1:noff                                          # >= NOFF offspring (lever 2)
                counter += 1
                oid = "g$(g)_$(counter)"
                x = isodd(k) ? 'F' : 'M'
                add!(oid, sire, dam, x)
                push!(born, oid)
                x == 'F' ? push!(thisF, oid) : push!(thisM, oid)
            end
        end
        length(thisF) >= nd || error("gen $g: only $(length(thisF)) females (< $nd dams)")
        length(thisM) >= ns || error("gen $g: only $(length(thisM)) males (< $ns sires)")
        prev_dams = thisF[1:nd]      # next generation's dams (recorded → identifying, levers 1+3)
        prev_sires = thisM[1:ns]
    end

    # recorded set: main = all candidates; negative control drops the dams' OWN records
    off_count = Dict{String,Int}()   # recorded offspring per dam
    for oid in born
        d = dam_of[oid]
        off_count[d] = get(off_count, d, 0) + 1
    end
    recorded = dam_own_records ? born :
               [oid for oid in born if get(off_count, oid, 0) == 0]
    recset = Set(recorded)
    # identifying dam = has its OWN record AND >= MIN_OFFSPRING recorded offspring
    ident = [id for id in recorded if get(off_count, id, 0) >= MIN_OFFSPRING]
    return (ids = ids, sire = sirev, dam = damv, dam_of = dam_of,
            recorded = recorded, ident_dams = ident)
end

# ---------- fixed context (pedigree / A / chol(A); identical every seed) ----------
function build_context(; nd::Int = ND, ns::Int = NS, noff::Int = NOFF,
                       ngen::Int = NGEN, dam_own_records::Bool = true)
    raw = build_maternal_pedigree(; nd, ns, noff, ngen, dam_own_records)
    ped = normalize_pedigree(raw.ids, raw.sire, raw.dam)     # TOPOLOGICALLY REORDERS
    idset = Dict(id => i for (i, id) in enumerate(ped.ids))  # canonical row lookup
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    LA = Matrix(cholesky(Symmetric(A)).L)
    animal_rows = [idset[id] for id in raw.recorded]               # record → own animal row
    dam_rows = [idset[raw.dam_of[id]] for id in raw.recorded]      # record → dam row
    ident_rows = [idset[id] for id in raw.ident_dams]
    return (ped = ped, idset = idset, Ainv = Ainv, A = A, LA = LA, q = q,
            animal_rows = animal_rows, dam_rows = dam_rows, ident_rows = ident_rows,
            n = length(raw.recorded), n_ident = length(raw.ident_dams))
end

# ---------- observed-information condition number at the optimum (confound detector) ----------
# 4×4 observed information = −Hessian of the REML loglik in the NATURAL VC parameterization
# [σ²ad, σ²am, σ_dm, σ²e] (central finite differences). A flat σ²ad↔σ_dm ridge (the unbroken
# confound) → a near-singular information → a large condition number.
function _info_cond(y, X, Zd, Zm, A, theta; fd = 1e-4)
    ll(t) = HSquared._direct_maternal_dense(y, X, Zd, Zm, A, [t[1] t[3]; t[3] t[2]], t[4])[1]
    h = fd .* max.(abs.(theta), 1e-3)
    H = zeros(4, 4)
    try
        for i in 1:4, j in 1:4
            ei = zeros(4); ei[i] = h[i]; ej = zeros(4); ej[j] = h[j]
            H[i, j] = (ll(theta .+ ei .+ ej) - ll(theta .+ ei .- ej) -
                       ll(theta .- ei .+ ej) + ll(theta .- ei .- ej)) / (4 * h[i] * h[j])
        end
    catch err
        (err isa PosDefException || err isa SingularException) && return Inf
        rethrow()
    end
    info = Symmetric(-H)
    (all(isfinite, H) && isposdef(info)) || return Inf
    return cond(Matrix(info))
end

# ---------- one seed ----------
function _fit(seed, ctx)
    rng = MersenneTwister(seed)
    q = ctx.q
    LG = Matrix(cholesky(Symmetric(G_TRUTH)).L)
    acoef = ctx.LA * randn(rng, q, 2) * transpose(LG)   # q×2: [:,1]=a_d, [:,2]=a_m (canonical order)
    a_d = acoef[:, 1]; a_m = acoef[:, 2]
    n = ctx.n
    Zd = zeros(n, q); Zm = zeros(n, q); y = Vector{Float64}(undef, n)
    for r in 1:n
        ia = ctx.animal_rows[r]; idm = ctx.dam_rows[r]
        Zd[r, ia] = 1.0; Zm[r, idm] = 1.0
        y[r] = MU + a_d[ia] + a_m[idm] + sqrt(SE) * randn(rng)
    end
    X = ones(n, 1)
    t = @elapsed fit = fit_direct_maternal_reml(y, X, Zd, Zm, ctx.Ainv;
        initial = (G_dm = Matrix(1.0I, 2, 2), sigma_e2 = 1.0), iterations = 200, ids = ctx.ped.ids)
    vc = fit.variance_components
    adh = fit.direct_effects.values; amh = fit.maternal_effects.values
    acc_d = cor(a_d[ctx.animal_rows], adh[ctx.animal_rows])              # direct: over recorded animals
    acc_m = length(ctx.ident_rows) >= 2 ? cor(a_m[ctx.ident_rows], amh[ctx.ident_rows]) : NaN  # maternal: over dams
    condn = _info_cond(y, X, Zd, Zm, ctx.A, [vc.sigma_ad, vc.sigma_am, vc.sigma_dm, vc.sigma_e2])
    return (converged = fit.converged, sigma_ad = vc.sigma_ad, sigma_am = vc.sigma_am,
            sigma_dm = vc.sigma_dm, sigma_e2 = vc.sigma_e2, r_am = fit.genetic_correlation,
            acc_d = acc_d, acc_m = acc_m, cond = condn, t = t)
end

function main()
    ctx = build_context(; dam_own_records = true)   # the MAIN confound-broken design
    ctx.n_ident >= MIN_IDENT_DAMS ||
        error("design broke: only $(ctx.n_ident) identifying dams (< $MIN_IDENT_DAMS); confound not structurally broken")

    sad = Float64[]; sam = Float64[]; sdm = Float64[]; se = Float64[]
    ram = Float64[]; accd = Float64[]; accm = Float64[]; condv = Float64[]; tv = Float64[]
    nconv = 0
    for seed in SEEDS
        r = _fit(seed, ctx)
        r.converged && (nconv += 1)
        push!(sad, r.sigma_ad); push!(sam, r.sigma_am); push!(sdm, r.sigma_dm); push!(se, r.sigma_e2)
        push!(ram, r.r_am); push!(accd, r.acc_d); push!(accm, r.acc_m); push!(condv, r.cond); push!(tv, r.t)
    end
    N = length(SEEDS)

    results = Tuple{String,Bool,Float64,Float64,Float64}[]
    report(name, v, truth) = begin
        mn = mean(v); bias = mn - truth; mcse = std(v) / sqrt(N)
        ok = abs(bias) <= 2 * mcse
        @printf("  %-9s mean=%+.4f truth=%+.4f bias=%+.4f MCSE=%.4f |bias|/MCSE=%.2f  %s\n",
                name, mn, truth, bias, mcse, abs(bias) / mcse, ok ? "PASS" : "FAIL")
        push!(results, (name, ok, bias, mcse, mn))
        return ok
    end

    println("Direct–maternal 2×2 G_dm recovery gate — $N seeds ($(first(SEEDS))..$(last(SEEDS))), converged=$nconv/$N")
    @printf("  DGP: %d recorded gens, ND=%d dams NS=%d sires NOFF=%d/dam → n=%d records, q=%d animals, %d identifying dams\n",
            NGEN, ND, NS, NOFF, ctx.n, ctx.q, ctx.n_ident)
    okad = report("σ²_ad", sad, S_AD)
    okam = report("σ²_am", sam, S_AM)
    okdm = report("σ_dm", sdm, S_DM)      # THE HEADLINE
    oke  = report("σ²e", se, SE)
    mram = mean(ram); maccd = mean(accd); maccm = mean(accm)
    maxcond = maximum(condv); maxram = maximum(abs.(ram))
    @printf("  %-9s mean=%+.4f truth=%+.4f  (REPORTED, not bias-gated; ratio of estimates)\n", "r_am", mram, R_AM)
    @printf("  EBV accuracy: direct mean=%.3f (min %.3f, floor %.2f)  maternal mean=%.3f (min %.3f, floor %.2f)\n",
            maccd, minimum(accd), EBV_ACC_D, maccm, minimum(accm), EBV_ACC_M)
    @printf("  conditioning: max cond=%.3e (ceiling %.1e)   |r_am| max=%.4f (boundary %.2f)\n",
            maxcond, COND_MAX, maxram, RAM_BOUND)
    @printf("  per-seed wall-time: mean=%.2fs min=%.2fs max=%.2fs total=%.1fs\n",
            mean(tv), minimum(tv), maximum(tv), sum(tv))

    ok_accd = maccd >= EBV_ACC_D
    ok_accm = maccm >= EBV_ACC_M
    ok_cond = maxcond < COND_MAX
    ok_ram  = maxram < RAM_BOUND
    gate = (nconv == N) && okad && okam && okdm && oke && ok_accd && ok_accm && ok_cond && ok_ram
    println("GATE: ", gate ? "PASS" : "FAIL",
            "  (converged $nconv/$N; |bias|≤2·MCSE ad=$okad am=$okam dm=$okdm σe²=$oke;",
            " EBVacc d=$ok_accd m=$ok_accm; cond=$ok_cond; r_am-interior=$ok_ram)")
    js = "{\"gate_pass\":$gate,\"seeds\":$N,\"converged\":$nconv," *
         "\"r_am_mean\":$(round(mram,digits=5)),\"r_am_truth\":$R_AM," *
         "\"acc_direct_mean\":$(round(maccd,digits=4)),\"acc_maternal_mean\":$(round(maccm,digits=4))," *
         "\"cond_max\":$(round(maxcond,sigdigits=5)),\"ram_abs_max\":$(round(maxram,digits=5))," *
         "\"walltime_mean_s\":$(round(mean(tv),digits=3))," *
         "\"n_records\":$(ctx.n),\"q\":$(ctx.q),\"n_ident_dams\":$(ctx.n_ident),\"params\":{" *
         join(["\"$(r[1])\":{\"bias\":$(round(r[3],digits=5)),\"mcse\":$(round(r[4],digits=5)),\"mean\":$(round(r[5],digits=5))}" for r in results], ",") * "}}"
    println("GATE_JSON ", js)
    exit(gate ? 0 : 1)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
