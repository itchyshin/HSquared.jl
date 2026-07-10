using HSquared
using LinearAlgebra
using Printf
using Random
using Statistics

# ============================================================================
# Supplied-K / Q escape-hatch — 48-seed recovery SCREEN (pre-declared gate).
#
# Governing pre-registration: docs/design/34-interval-recovery-pre-registration.md
# in the R repo (committed 2026-07-10, honesty anchor). §10 names this campaign as a
# PENDING screening gate and delegates the operational grid/seeds/sbatch to this twin
# driver ("must cite this doc"); §5 is the recovery-leg rule; §11 is the screening tier.
#
# WHAT THIS GATES. The user-supplied relationship/kernel path: the engine simulates and
# fits over an ARBITRARY supplied covariance K (dense symmetric PD, non-pedigree,
# non-genomic). The REML kernel is already covered + generic — V3-NEFFECT-REML fits over
# a supplied precision (Ainv slot), and V2-GREML already exercises a supplied K. This
# SCREEN checks the escape hatch: feed a genuine arbitrary K and confirm the variance
# components / ratio recover with no detectable across-seed bias. (Marker Q is the
# sibling escape hatch named in §10; it is a SEPARATE screen — OUT of scope here.)
#
# FIT ENTRYPOINT (confirmed read-only against src/likelihood.jl:1097 and the committed
# harnesses sim/phase3_neffect_recovery_gate.jl and sim/phase2_genomic_reml_recovery.jl):
#   HSquared.fit_multi_effect_reml(y, X, [(Z, Cinv)]; initial, max_dense_cells)
# The SECOND element of each (Z, ·) pair is the PRECISION (inverse) matrix: the function
# internally forms A = inv(Symmetric(Cinv)) as the model covariance. So a supplied
# covariance C is passed as its inverse Cinv = inv(C). The docstring states the K=1 fit
# recovers the univariate animal-model REML optimum — the exact reduction cell 3 checks.
#
# NOT an include() of the committed harnesses. sim/phase3_neffect_recovery_gate.jl and
# sim/phase2_genomic_reml_recovery.jl call main()/exit() at top level with NO
# PROGRAM_FILE guard, so include()-ing them would EXECUTE them (neffect exits). This is a
# self-contained NEW driver that `using HSquared` and calls the exported entrypoint; the
# minimal helpers (half-sib pedigree, incidence) are re-derived from the READ-confirmed
# harness patterns. It writes a NEW per-seed TSV and never mutates a committed harness/TSV.
#
# DGP (uniform across all three cells; only the covariance C changes):
#   q levels (dim of K), r records/level, n = q·r records, balanced incidence Z (n×q).
#   u ~ N(0, σ²k·C) drawn via chol(C);  e ~ N(0, σ²e·I_n);  y = μ·1 + Z·u + e.
#   RECOVER (the pre-declared parameters):  σ²k,  σ²e,  h²k = σ²k / (σ²k + σ²e).
#   truth (σ²k, σ²e) = (0.6, 0.4), μ = 2.0, h²k = 0.6.  Replication is REQUIRED: with
#   Z=I the σ²k / σ²e split is unidentifiable, so the null cell (C=I) needs r>1.
#
# CELLS (one SLURM array task each; --kind selects the covariance):
#   1. arbK      arbitrary well-conditioned PD K (fixed correlation matrix, factor model
#                + ridge floor, unit diagonal; cond(K) asserted < COND_MAX). scope=new
#                → a FAIL is a banked-negative (a recorded, reusable negative). §5.
#   2. identity  C = I  → reduces to the iid variance-component recovery (a covered scope).
#                scope=inside → a FAIL is R9 STOP-AND-ASK (covered-claim regression), NOT
#                a banked negative. §5 R9.
#   3. pedA      C = A_pedigree (Cinv = the genuine sparse pedigree_inverse) → reduces to,
#                and must match, the pedigree animal-model path (a covered scope).
#                scope=inside → a FAIL is R9 STOP-AND-ASK. §5 R9.
#
# GATE (§5, conditional on convergence). Over the m CONVERGED seeds per cell:
#   bias(θ) = mean(θ̂ − θ_true),  MC-SE(θ) = sd(θ̂)/sqrt(m).
#   Cell PASSES iff EVERY pre-declared θ ∈ {σ²k, σ²e, h²k} has |bias| ≤ 2·MC-SE.
#   Read as: NO DETECTABLE across-seed bias (a low-power non-rejection), never "unbiased".
#   Convergence rate is reported per cell; a thrown seed is caught, banked as a
#   non-converged row, and excluded from the aggregate (never blocks the cell).
#   §2 INTERPRETABILITY FLOOR (doc-34): a cell whose convergence rate is < 0.9 is
#   NON-INTERPRETABLE and can NEVER emit an eligible verdict (PASS / COVERED-ELIGIBLE); the
#   bias gate on a handful of converged seeds would be a vacuous pass via an inflated MC-SE.
#   NON-INTERPRETABLE dominates PASS / FAIL / R9 / banked-negative.
#
# SCREENING TIER (§11). 48 seeds are SCREENING ONLY — direction, not magnitude. A clean
#   screen SCHEDULES a 2000-rep confirm; it CANNOT set a claim level, move
#   public_covered_count, or promote. A public move needs the 2000-rep confirm tier + a
#   real Rose audit + the maintainer's G10.
#
# EXIT CODE ≠ GATE. The gate PASS/FAIL is DATA (GATE line, GATE_JSON, TSV). This process
#   exits 0 iff the run COMPLETED (all requested seeds attempted, TSV written, aggregate
#   printed); it exits non-zero ONLY on a genuine error (SLURM COMPLETED ≠ Julia
#   succeeded). A gate FAIL and a thrown-then-banked seed do NOT set a non-zero code.
#
# SAME-ESTIMAND COMPARATOR (R lane, run SEPARATELY — NOT in this driver). sommer
#   mmer(y ~ 1, random = ~ vsr(id, Gu = K)) with the supplied K, compared at the same
#   variance components / ratio. Documented as the supplied-K comparator; it does not run
#   here (Julia lane) and is not part of this gate.
#
#   env OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 julia --project=. \
#     sim/phase3_supplied_k_recovery_gate.jl --cell=arbK --kind=arbitrary \
#     --out=sim/drac/results/supplied_k/gate_arbK.tsv
# ============================================================================

# ---- pre-declared defaults (the operational predeclaration for §10 supplied-K) --------
const Q_DEFAULT        = 500        # levels = dim(K)
const RECORDS_DEFAULT  = 2          # records/level → n = q·r = 1000 (well-powered)
const SK_DEFAULT       = 0.6        # σ²k truth
const SE_DEFAULT       = 0.4        # σ²e truth  → h²k = 0.6
const MU_DEFAULT       = 2.0
const FACTORS_DEFAULT  = 1000       # arbitrary-K factor model rank (= 2q → well-conditioned)
const RIDGE_DEFAULT    = 0.10       # PD floor: λ_min(S) ≥ ridge before correlation-normalizing
const KSEED_DEFAULT    = 20260701   # fixed K-construction seed (distinct from sim seeds)
const NSIRE_DEFAULT    = 25         # half-sib pedigree for the pedA cell: 25+50+425 = 500 = q
const NDAM_DEFAULT     = 50
const NOFF_DEFAULT     = 425
const SEEDS_DEFAULT    = 20266000:20266047   # 48 cold-start seeds; UNSEEN at declaration.
                                             # Block 20266000..047 is DISJOINT from EVERY committed
                                             # sim/ seed block — incl. the QTL phase-5 gates at
                                             # …900..969 that the prior 20260900 base COLLIDED with —
                                             # and from the repeatability block 20265000..047 and the
                                             # C8 re-seed (…20270001..500). Bumped 2026-07-10.
const INIT             = [1.0, 1.0]  # neutral cold start (NOT at truth 0.6/0.4)
const MAX_DENSE        = 4_000_000   # dense-oracle guard (n≲2000 regime per the docstring)
const COND_MAX         = 200.0       # "well-conditioned" is asserted, not assumed
const MIN_CONVERGED    = 3           # below this, MC-SE is not meaningful → INCONCLUSIVE
const MIN_CONV_RATE    = 0.9         # §2 interpretability floor: rate < 0.9 → NON-INTERPRETABLE

const COLUMNS = ["cell", "kind", "scope", "seed", "q", "records", "n", "mu",
    "sk_true", "se_true", "h2_true", "cond_k",
    "converged", "iterations", "loglik", "sk_hat", "se_hat", "h2_hat",
    "factors", "ridge", "kseed"]   # factors/ridge/kseed banked so --resume can drift-guard them

# ---- tiny arg parsing -----------------------------------------------------------------
function _arg(args, key, default)
    prefix = "--$key="
    for a in args
        startswith(a, prefix) && return String(split(a, "="; limit = 2)[2])
    end
    return default
end
_argf(args, key, d) = (v = _arg(args, key, nothing); v === nothing ? d : parse(Float64, v))
_argi(args, key, d) = (v = _arg(args, key, nothing); v === nothing ? d : parse(Int, v))
_argb(args, key, d) = (v = _arg(args, key, nothing); v === nothing ? d : lowercase(v) in ("1", "true", "yes"))
function _argseeds(args, d)
    v = _arg(args, "seeds", nothing)
    v === nothing && return collect(d)
    return [parse(Int, strip(s)) for s in split(v, ",") if !isempty(strip(s))]
end

# ---- covariance builders (each returns the model covariance C and its precision Cinv) --
# Half-sib pedigree, re-derived from sim/phase3_neffect_recovery_gate.jl (READ-only).
function _halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$i" for i in 1:nsire]
    dam_ids = ["d$i" for i in 1:ndam]
    off_ids = ["o$i" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam),
                [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring])
    dam = vcat(fill("0", nsire + ndam),
               [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring])
    return normalize_pedigree(ids, sire, dam)
end

# Arbitrary well-conditioned PD correlation matrix. S = B·B'/factors + ridge·I has
# λ_min ≥ ridge (a hard PD floor); correlation-normalizing gives a unit diagonal (natural
# for a relationship kernel). With factors = 2q the Marchenko–Pastur edge bounds cond(S)
# modestly; cond is asserted < COND_MAX at build so "well-conditioned" is enforced.
function _arbitrary_correlation_K(q, factors, ridge, seed)
    rng = MersenneTwister(seed)
    B = randn(rng, q, factors)
    S = (B * transpose(B)) ./ factors .+ ridge .* Matrix(1.0I, q, q)
    d = sqrt.(diag(S))
    Kc = S ./ (d * transpose(d))
    return Matrix(Symmetric((Kc .+ transpose(Kc)) ./ 2))
end

# Returns (C::Matrix, Cinv, cond_k). C is the model covariance; Cinv the precision fed to
# the fit (fit forms inv(Symmetric(Cinv)) internally, so inv(C) round-trips to C).
function build_covariance(kind, q; factors, ridge, kseed, nsire, ndam, noffspring)
    if kind == "arbitrary"
        C = _arbitrary_correlation_K(q, factors, ridge, kseed)
        ck = cond(Symmetric(C))
        ck < COND_MAX || error("arbitrary K is ill-conditioned: cond=$(ck) ≥ COND_MAX=$(COND_MAX); " *
                               "raise --ridge or --factors, or change --kseed")
        return (C, inv(Symmetric(C)), ck)
    elseif kind == "identity"
        C = Matrix(1.0I, q, q)
        return (C, Matrix(1.0I, q, q), 1.0)
    elseif kind == "pedigree"
        nsire + ndam + noffspring == q ||
            error("pedigree cell needs nsire+ndam+noffspring == q ($(nsire)+$(ndam)+$(noffspring) ≠ $(q))")
        ped = _halfsib_pedigree(nsire, ndam, noffspring)
        length(ped.ids) == q || error("pedigree has $(length(ped.ids)) animals ≠ q=$(q)")
        Ainv = pedigree_inverse(ped)                       # the genuine pedigree precision
        A = inv(Symmetric(Matrix(Ainv)))                   # model covariance
        return (Matrix(A), Ainv, cond(Symmetric(Matrix(A))))
    else
        error("unknown --kind=$(kind) (expected arbitrary | identity | pedigree)")
    end
end

# Balanced incidence: r consecutive records per level; n = q·r rows.
function _incidence(q, records)
    n = q * records
    Z = zeros(Float64, n, q)
    for i in 1:q, j in 1:records
        Z[(i - 1) * records + j, i] = 1.0
    end
    return Z
end

# ---- one seed: simulate under C and fit via the supplied precision Cinv ---------------
function _sim_fit(seed, L, Z, X, Cinv, sk, se, mu, q, maxdense)
    rng = MersenneTwister(seed)
    u = (L * randn(rng, q)) .* sqrt(sk)     # u ~ N(0, σ²k·C), since C = L·L'
    e = randn(rng, size(Z, 1)) .* sqrt(se)
    y = mu .+ Z * u .+ e
    fit = HSquared.fit_multi_effect_reml(y, X, [(Z, Cinv)];
                                         initial = INIT, max_dense_cells = maxdense)
    skh = fit.variance_components.sigmas[1]
    seh = fit.variance_components.sigma_e2
    return (converged = fit.converged, sk_hat = skh, se_hat = seh,
            h2_hat = skh / (skh + seh), iterations = fit.iterations, loglik = fit.loglik)
end

# ---- resume: read seeds already banked for THIS cell, guarding against config drift ----
# The guard covers EVERY field that changes the DGP or the arbitrary-K definition: kind, scope,
# q, records, sk, se, mu, factors, ridge, kseed. A resume with a changed --kseed (or --factors/
# --ridge/--mu/--scope) is a DIFFERENT arbitrary K / DGP and MUST hard-error, never silently merge.
function _existing_seeds(out, cell, kind, scope, q, records, sk, se, mu, factors, ridge, kseed)
    isfile(out) || return Set{Int}()
    seen = Set{Int}()
    open(out) do io
        header = split(strip(readline(io)), '\t')
        idx = Dict(header[i] => i for i in eachindex(header))
        for ln in eachline(io)
            f = split(strip(ln), '\t')
            length(f) < length(COLUMNS) && continue
            f[idx["cell"]] == cell || continue
            (f[idx["kind"]] == kind &&
             f[idx["scope"]] == scope &&
             parse(Int, f[idx["q"]]) == q &&
             parse(Int, f[idx["records"]]) == records &&
             isapprox(parse(Float64, f[idx["sk_true"]]), sk) &&
             isapprox(parse(Float64, f[idx["se_true"]]), se) &&
             isapprox(parse(Float64, f[idx["mu"]]), mu) &&
             parse(Int, f[idx["factors"]]) == factors &&
             isapprox(parse(Float64, f[idx["ridge"]]), ridge) &&
             parse(Int, f[idx["kseed"]]) == kseed) ||
                error("resume config drift in $(out) for cell=$(cell): existing rows do not " *
                      "match kind/scope/q/records/sk/se/mu/factors/ridge/kseed — use a NEW --out, do not silently merge")
            push!(seen, parse(Int, f[idx["seed"]]))
        end
    end
    return seen
end

function main()
    args = ARGS
    cell     = _arg(args, "cell", "arbK")
    kind     = _arg(args, "kind", "arbitrary")
    scope    = _arg(args, "scope", kind == "arbitrary" ? "new" : "inside")
    q        = _argi(args, "q", Q_DEFAULT)
    records  = _argi(args, "records", RECORDS_DEFAULT)
    sk       = _argf(args, "sk", SK_DEFAULT)
    se       = _argf(args, "se", SE_DEFAULT)
    mu       = _argf(args, "mu", MU_DEFAULT)
    factors  = _argi(args, "factors", FACTORS_DEFAULT)
    ridge    = _argf(args, "ridge", RIDGE_DEFAULT)
    kseed    = _argi(args, "kseed", KSEED_DEFAULT)
    nsire    = _argi(args, "nsire", NSIRE_DEFAULT)
    ndam     = _argi(args, "ndam", NDAM_DEFAULT)
    noff     = _argi(args, "noffspring", NOFF_DEFAULT)
    maxdense = _argi(args, "max-dense-cells", MAX_DENSE)
    resume   = _argb(args, "resume", false)
    seeds    = _argseeds(args, SEEDS_DEFAULT)
    out      = _arg(args, "out", "")

    n = q * records
    h2_true = sk / (sk + se)
    isempty(out) &&
        error("--out is required so the per-seed draws are banked to a NEW TSV and the " *
              "aggregate is computed over the banked union (screening evidence must persist)")
    n * n <= maxdense ||
        error("dense oracle would form $(n)×$(n) V ($(n*n) cells) > max_dense_cells=$(maxdense); " *
              "reduce q/records or raise --max-dense-cells (n≲2000 is the oracle regime)")

    # Build the (fixed) covariance, its Cholesky factor, incidence, and design once.
    C, Cinv, cond_k = build_covariance(kind, q; factors = factors, ridge = ridge,
                                       kseed = kseed, nsire = nsire, ndam = ndam,
                                       noffspring = noff)
    L = cholesky(Symmetric(C)).L
    Z = _incidence(q, records)
    X = ones(n, 1)

    @printf("supplied-K screen — cell=%s kind=%s scope=%s  q=%d records=%d n=%d  truth(σ²k,σ²e,h²k)=(%.2f,%.2f,%.2f)  cond(K)=%.3g  seeds=%d (%d..%d)\n",
            cell, kind, scope, q, records, n, sk, se, h2_true, cond_k,
            length(seeds), first(seeds), last(seeds))

    # Resume: skip seeds already banked (guarded against config drift).
    seen = (resume && !isempty(out)) ?
           _existing_seeds(out, cell, kind, scope, q, records, sk, se, mu, factors, ridge, kseed) :
           Set{Int}()
    todo = [s for s in seeds if !(s in seen)]
    !isempty(seen) && @printf("resume: %d of %d declared seeds already present; %d new\n",
                              length(seen), length(seeds), length(todo))

    # Open the NEW per-seed TSV. resume=true APPENDS (skipping seeds already banked); resume=false
    # must NOT append to an existing non-empty TSV — `seen` is empty when resume=false, so every
    # declared seed would be re-banked and the convergence-conditional aggregate (which re-reads the
    # whole TSV) would count the OLD rows PLUS the freshly duplicated rows (m inflated, MC-SE halved
    # → a vacuous PASS). On resume=false we TRUNCATE to a fresh file instead.
    io = nothing
    if !isempty(out)
        mkpath(dirname(out))
        if !resume && isfile(out) && filesize(out) > 0
            @printf("resume=false: truncating existing non-empty %s to prevent seed double-count\n", out)
        end
        mode = resume ? "a" : "w"
        io = open(out, mode)
        fresh = mode == "w" || filesize(out) == 0
        fresh && (println(io, join(COLUMNS, '\t')); flush(io))
    end
    write_row(r) = io === nothing ? nothing : (println(io, join(r, '\t')); flush(io))

    # Per-seed loop: one throw is caught and banked as a non-converged row (never blocks
    # the cell); everything else is a genuine error and is allowed to propagate.
    for s in todo
        row = try
            r = _sim_fit(s, L, Z, X, Cinv, sk, se, mu, q, maxdense)
            [cell, kind, scope, s, q, records, n, mu, sk, se, h2_true,
             @sprintf("%.6g", cond_k), r.converged, r.iterations,
             @sprintf("%.8g", r.loglik), @sprintf("%.8g", r.sk_hat),
             @sprintf("%.8g", r.se_hat), @sprintf("%.8g", r.h2_hat),
             factors, ridge, kseed]
        catch err
            @printf("  seed %d THREW (%s) — banked as non-converged\n", s, typeof(err))
            [cell, kind, scope, s, q, records, n, mu, sk, se, h2_true,
             @sprintf("%.6g", cond_k), false, -1, "NaN", "NaN", "NaN", "NaN",
             factors, ridge, kseed]
        end
        write_row(row)
    end
    io === nothing || close(io)

    # Aggregate CONDITIONAL ON CONVERGENCE over the full declared seed set (re-read the
    # TSV union when resuming; otherwise use this run's rows only if no --out was given).
    skv = Float64[]; sev = Float64[]; h2v = Float64[]; ndecl = length(seeds); nconv = 0
    seen_agg = Set{Int}()   # DEDUP on (cell, seed): a duplicated row can NEVER inflate m / halve MC-SE
    open(out) do fio
        header = split(strip(readline(fio)), '\t')
        idx = Dict(header[i] => i for i in eachindex(header))
        declset = Set(seeds)
        for ln in eachline(fio)
            f = split(strip(ln), '\t')
            length(f) < length(COLUMNS) && continue
            f[idx["cell"]] == cell || continue
            sd = tryparse(Int, f[idx["seed"]])
            sd === nothing && continue
            sd in declset || continue
            sd in seen_agg && continue          # first row for this seed wins; drop any duplicate
            push!(seen_agg, sd)
            if lowercase(f[idx["converged"]]) == "true"
                a = tryparse(Float64, f[idx["sk_hat"]]); b = tryparse(Float64, f[idx["se_hat"]])
                c = tryparse(Float64, f[idx["h2_hat"]])
                (a === nothing || b === nothing || c === nothing) && continue
                (isfinite(a) && isfinite(b) && isfinite(c)) || continue
                push!(skv, a); push!(sev, b); push!(h2v, c); nconv += 1
            end
        end
    end

    m = nconv
    conv_rate = ndecl == 0 ? NaN : m / ndecl
    @printf("CONVERGENCE cell=%s kind=%s converged=%d/%d rate=%.3f\n",
            cell, kind, m, ndecl, conv_rate)

    results = Tuple{String,Bool,Float64,Float64,Float64}[]
    bias_pass = false
    if m < MIN_CONVERGED
        @printf("  INCONCLUSIVE: only %d converged seed(s) (< %d) — MC-SE not meaningful\n",
                m, MIN_CONVERGED)
    else
        report(name, v, truth) = begin
            mn = mean(v); bias = mn - truth; mcse = std(v) / sqrt(m)
            ok = abs(bias) <= 2 * mcse
            @printf("  %-4s mean=%.4f truth=%.2f bias=%+.4f MCSE=%.4f |bias|/MCSE=%.2f  %s\n",
                    name, mn, truth, bias, mcse, mcse == 0 ? Inf : abs(bias) / mcse,
                    ok ? "PASS" : "FAIL")
            push!(results, (name, ok, bias, mcse, mn))
            return ok
        end
        okk = report("σ²k", skv, sk)
        oke = report("σ²e", sev, se)
        okh = report("h²k", h2v, h2_true)
        bias_pass = okk && oke && okh
    end

    # §2 INTERPRETABILITY FLOOR (doc-34): a cell whose convergence rate is below MIN_CONV_RATE is
    # NON-INTERPRETABLE and can NEVER emit an eligible verdict, regardless of the bias check above —
    # a "pass" on a handful of converged seeds is a vacuous pass via an inflated MC-SE. This verdict
    # DOMINATES PASS / FAIL / INCONCLUSIVE / R9 / banked-negative. Only gate_pass == (verdict=="PASS")
    # is eligible; the raw per-parameter bias check stays in GATE_JSON as a diagnostic.
    interpretable = (ndecl > 0) && (conv_rate >= MIN_CONV_RATE)
    verdict = !interpretable ? "NON-INTERPRETABLE" :
              m < MIN_CONVERGED ? "INCONCLUSIVE" :
              bias_pass ? "PASS" : "FAIL"
    gate_pass = verdict == "PASS"

    @printf("GATE: %s cell=%s scope=%s (converged %d/%d rate=%.3f; screening tier — §11)\n",
            verdict, cell, scope, m, ndecl, conv_rate)
    interp = !interpretable ?
                 @sprintf("NON-INTERPRETABLE: convergence rate %.3f < %.2f (§2 interpretability floor) — no eligible verdict; report the rate",
                          conv_rate, MIN_CONV_RATE) :
             verdict == "INCONCLUSIVE" ? "INCONCLUSIVE (insufficient convergence — not a result)" :
             gate_pass ? "COVERED-ELIGIBLE (screening only — schedule a 2000-rep confirm; §11)" :
             scope == "inside" ? "R9 STOP-AND-ASK: covered-claim regression (reduction anchor failed; §5 R9)" :
             "BANKED-NEGATIVE (recorded, reusable negative; §5)"
    println("INTERPRETATION: ", interp)

    js = "{\"cell\":\"$(cell)\",\"kind\":\"$(kind)\",\"scope\":\"$(scope)\"," *
         "\"verdict\":\"$(verdict)\",\"interpretable\":$(interpretable),\"gate_pass\":$(gate_pass)," *
         "\"conv_rate\":$(ndecl == 0 ? "null" : round(conv_rate, digits = 5))," *
         "\"seeds\":$(ndecl),\"converged\":$(m)," *
         "\"cond_k\":$(round(cond_k, digits = 5))," *
         "\"truth\":{\"sk\":$(sk),\"se\":$(se),\"h2k\":$(round(h2_true, digits = 5))}," *
         "\"params\":{" *
         join(["\"$(r[1])\":{\"bias\":$(round(r[3], digits = 6)),\"mcse\":$(round(r[4], digits = 6))," *
               "\"mean\":$(round(r[5], digits = 6)),\"pass\":$(r[2])}" for r in results], ",") *
         "}}"
    println("GATE_JSON ", js)
    @printf("RUN_COMPLETE cell=%s kind=%s scope=%s converged=%d/%d rate=%.3f verdict=%s\n",
            cell, kind, scope, m, ndecl, conv_rate, verdict)
end

main()
