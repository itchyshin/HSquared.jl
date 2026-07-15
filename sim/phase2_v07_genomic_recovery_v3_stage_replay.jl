#!/usr/bin/env julia

# Independent recovery-v3 D0F/D1 Julia replay. Official markers, phenotypes,
# and ordinary-form fits are owned by the R driver. This tool consumes their
# presealed and corpus-locked packets; it never draws an official random number and its direct
# Julia solver invocation is explicitly a replay, not a public route.

using HSquared
using LinearAlgebra
using Printf
using SHA
using SparseArrays
using Statistics

module D0Support
include(joinpath(@__DIR__, "phase2_v07_genomic_recovery_v3_spectral_replay.jl"))
end

const SCHEMA = "v07-genomic-recovery-v3-stage-preseal-2"
const PACKET_SCHEMA = "v07-genomic-recovery-v3-packet-1"
const TRUTH_SCHEMA = "v07-genomic-recovery-v3-truth-1"
const RIDGE = 0.01
const BOUNDARY_EPSILON = 1e-7
const KKT_TOLERANCE = 1e-8
const REPLAY_ROUTE = "julia_profile_replay"
const R_RECOMPUTER_BASENAME = "v07_genomic_recovery_v3_recompute.R"
const R_D0_RECOMPUTER_BASENAME = "v07_genomic_recovery_v3_d0_recompute.R"
const PUBLIC_ROUTE = "ordinary_auto_genomic"
const D0_CORPUS_ROOT_HASHES = (
    manifest="1264e87eeea10bf8dd9d6197a0f2ef865a2cd541e085bde22a655730ef894f61",
    corpus="04f128168747aecab4847848de4498ebfb6efdf4aafb742d2e6f828e0d15c084",
    seal="4a921c039426faa400648752ec59bd3f049939098ec4f42b6faafc9e845b324c",
)
const D0_OFFICIAL_ROOT = "/home/snakagaw/hsq_work/v07-genomic-recovery-v3-d0-official-cdb33dc-4c5e54de"
const D0_RECEIPT_SHA256 = "190b6546fab8caeec24683c4f7bee8063ada671c220852c9372e5db194b2886a"
const D0_DIAGNOSTICS_RELATIVE_PATH = joinpath("r", "d0_packet_diagnostics_base_r.tsv")
const D0_DIAGNOSTICS_SHA256 = "7c1cbc165df90e844bd4fdc7fc6ffb6dcbb8343c0d5ca9e7a588e4ca6d48c370"
const D0F_BLOCKED_ROOT = "/home/snakagaw/hsq_work/v07-genomic-recovery-v3-d0f-official-0a9d882-1a538212"
const D0F_ADJUDICATION_SCHEMA = "v07-genomic-recovery-v3-adjudication-1"
const RESOLVED = ("boundary_lower", "boundary_upper", "interior", "interior_rescued")
const RESOLVED_REASONS = Dict("boundary_lower"=>"boundary_lower","boundary_upper"=>"boundary_upper","interior"=>"ai_interior","interior_rescued"=>"profile_interior")
const D0F_DESIGNS = [
    (id="d0f_n0120_m0600", index=1, n=120, m=600, marker_ratio=5.0, source_cell="n120_m600_r050", source_index=2),
    (id="d0f_n0300_m0150", index=2, n=300, m=150, marker_ratio=0.5, source_cell="n300_m150_r050", source_index=5),
    (id="d0f_n0300_m1000", index=3, n=300, m=1000, marker_ratio=10/3, source_cell="n300_m1000_r050", source_index=8),
]
const D0F_PHENOTYPE_SEED_BASE = 2_036_000_000
const D0F_PARITY_BOOTSTRAP_SHA256 = "e5649184fcee3749203207deb82f20de9fba7183e6a029396ee385c2656975ef"
const N_LEVELS = (120,300,600,1200)
const MARKER_RATIOS = (0.5,10/3,5.0)
const TRUTH_LEVELS = (0.2,0.5,0.8)

const D0F_MANIFEST_COLUMNS = split("stage design_id design_index panel_id panel_rank source_cell_id panel_source_seed phenotype_rank seed n m marker_ratio retained_m truth_sigma_g2 truth_sigma_e2 truth_ratio ridge marker_hash id_hash kernel_hash precision_hash")
const D1_MANIFEST_COLUMNS = split("stage cell_id cell_index seed_offset seed n m marker_ratio marker_ratio_code truth_sigma_g2 truth_sigma_e2 truth_ratio ridge")
const D1_CONSTRUCTION_COLUMNS = split("retained_m marker_hash id_hash kernel_hash precision_hash")
const FULL_RESULT_COLUMNS = split("attempted status error_class converged boundary_status boundary_reason boundary_epsilon scientific_sigma_g2 scientific_sigma_e2 scientific_ratio fitted_total_variance numerical_sigma_g2 numerical_sigma_e2 numerical_ratio profile_loglik lower_derivative_per_observation upper_derivative_per_observation iterations objective gradient_norm runtime_seconds peak_rss_mb scale_denominator eigen_cv_population effective_rank information_r020 se_info_r020 information_r050 se_info_r050 information_r080 se_info_r080 relationship_source relationship_method allele_frequency_source relationship_scale route r_implementation_commit julia_implementation_commit driver_commit preseal_sha256")
const REPLAY_BINDING_COLUMNS = split("source_r_attempt_sha256 source_r_max_abs_difference replay_julia_commit replay_driver_sha256 manifest_sha256 preseal_sha256 corpus_lock_sha256")
const PACKET_PRIMARIES = ["markers.tsv","ids.tsv","phenotype.tsv","truth.tsv","packet_files_lock.tsv"]
const CORPUS_COLUMNS = ["relative_path","sha256"]
const BATCH_SCHEMA = "v07-genomic-recovery-v3-replay-batch-1"
const BATCH_COLUMNS = split("schema_version stage batch_index batch_count manifest_rank group_id seed manifest_sha256 preseal_sha256 corpus_lock_sha256")
const PRESEAL_KEYS = split("schema_version stage doc49_sha256 cell_table_sha256 manifest_sha256 environment_manifest_sha256 d0_output_root d0_adjudication_receipt_sha256 d0_diagnostics_sha256 d0f_adjudication_root d0f_adjudication_receipt_sha256 historical_seed_lock_sha256 d0f_fixed_panel_manifest_sha256 d0f_bootstrap_indices_sha256 fisher_receipt_sha256 noether_receipt_sha256 hopper_receipt_sha256 grace_receipt_sha256 rose_receipt_sha256 r_driver_commit r_recomputer_commit julia_replay_commit r_auto_route_commit julia_candidate_commit r_driver_sha256 r_recomputer_sha256 julia_replay_sha256 d0_recomputer_sha256 output_root official_route replay_route packet_schema_version truth_schema_version relationship_source relationship_method allele_frequency_source relationship_scale ridge boundary_epsilon boundary_kkt_tolerance output_subtrees_absent_before_preseal")
const CELL_TABLE_COLUMNS = split("cell_id cell_index n m marker_ratio marker_ratio_code truth_sigma_g2 truth_sigma_e2 truth_ratio ridge")
const ENVIRONMENT_KEYS = split("stage host r_version r_rng_kind r_normal_kind r_sample_kind julia_version openblas_num_threads julia_num_threads max_workers")
const REVIEWERS = ("fisher","noether","hopper","grace","rose")
const RECEIPT_COLUMNS = split("reviewer verdict doc49_sha256 r_driver_commit r_recomputer_commit julia_replay_commit r_auto_route_commit julia_candidate_commit")
const D0F_ADJUDICATION_COLUMNS = vcat(split("schema_version stage verdict stage_decision attempt_max_diff summary_max_diff preseal_sha256 corpus_lock_sha256 manifest_sha256 r_driver_commit r_recomputer_commit julia_replay_commit r_driver_sha256 r_recomputer_sha256 julia_replay_sha256 base_r_inventory_sha256 julia_replay_inventory_sha256 r_summary_sha256 julia_summary_sha256"),reduce(vcat,[["$(r)_review_path","$(r)_review_sha256"] for r in REVIEWERS]))
const D0F_FIXED_COLUMNS = split("stage design_id design_index source_cell_id panel_rank panel_source_seed n m marker_ratio truth_sigma_g2 truth_sigma_e2 truth_ratio ridge retained_m marker_hash id_hash kernel_hash precision_hash")
const TRUTH_PROVENANCE_COLUMNS = split("packet_schema_version truth_schema_version scale_denominator relationship_source relationship_method allele_frequency_source relationship_scale preseal_sha256 r_implementation_commit julia_implementation_commit driver_commit")
const D0F_BOOTSTRAP_COLUMNS = vcat(split("design_id design_index bootstrap_rep panel_slot panel_rank"),[@sprintf("phenotype_%02d",i) for i in 1:8])
const D0F_SUMMARY_COLUMNS = split("stage design_id design_index n m n_panels phenotypes_per_panel n_expected n_attempted n_converged n_interior n_interior_rescued n_boundary_lower n_boundary_upper n_unresolved n_error failure_classes convergence_rate d0f_status fit_blocker bootstrap_sha256 variance_within variance_within_bootstrap_lower variance_within_bootstrap_upper variance_between variance_between_bootstrap_lower variance_between_bootstrap_upper mean_ratio mcse_mean_ratio empirical_sd_ratio boundary_lower_proportion boundary_upper_proportion mcse_boundary_lower mcse_boundary_upper median_runtime_seconds p95_runtime_seconds median_peak_rss_mb p95_peak_rss_mb")
const D1_SUMMARY_COLUMNS = split("stage cell_id cell_index n m marker_ratio truth_ratio n_expected n_attempted n_converged n_bias_rows n_interior n_interior_rescued n_boundary_lower n_boundary_upper n_unresolved n_error convergence_rate wilson_lower wilson_upper target truth mean_estimate bias mcse bias_ci_lower bias_ci_upper margin rmse mcse_rmse empirical_sd pilot_sd_upper required_n_raw required_n low_convergence summary_nonfinite precision_blocked futility_stopped target_futile cell_eligible cell_status median_runtime_seconds p95_runtime_seconds median_peak_rss_mb p95_peak_rss_mb rms_se_info empirical_sd_over_rms_se_info predicted_boundary_lower predicted_boundary_upper observed_boundary_lower observed_boundary_upper mcse_boundary_lower mcse_boundary_upper mean_spectral_cv mean_effective_rank failure_classes")

struct TSV
    columns::Vector{String}
    rows::Vector{Vector{String}}
end

_sha256(path)=bytes2hex(sha256(read(path)))
_hex(x,n=64)=length(x)==n && all(c->isdigit(c)||c in 'a':'f',x)
_format(x::Bool)=x ? "true" : "false"
_format(x::Integer)=string(x)
_format(x::AbstractFloat)=isnan(x) ? "NA" : isinf(x) ? (x>0 ? "Inf" : "-Inf") : @sprintf("%.17g",x)
_format(x)=string(x)
function _error_class(err)
    x=lowercase(first(split(sprint(showerror,err),'\n')));x=replace(x,r"[^a-z0-9]+"=>"_");x=strip(x,'_');isempty(x) ? "unknown_error" : first(x,min(lastindex(x),120))
end

function _option(args,key;default=nothing)
    p="--$key=";hits=filter(x->startswith(x,p),args);length(hits)<=1||error("--$key occurs more than once")
    isempty(hits) ? default : split(only(hits),"=";limit=2)[2]
end
function _required(args,key)
    x=_option(args,key);x===nothing&&error("--$key is required");String(x)
end
function _safe_dir(path,label)
    isabspath(path)&&normpath(path)==path&&isdir(path)&&!islink(path)&&realpath(path)==path||error("$label must be an absolute canonical plain directory")
    path
end
function _plain(root,path;directory=false)
    ap=abspath(path);prefix=root*Base.Filesystem.path_separator
    (ap==root||startswith(ap,prefix))&&!islink(ap)&&(directory ? isdir(ap) : isfile(ap))&&realpath(ap)==ap||error("invalid or escaping path: $path")
    ap
end
function _verify_pair(root,path)
    path=_plain(root,path);side=_plain(root,path*".sha256")
    read(side,String)=="$(_sha256(path))  $(basename(path))\n"||error("checksum sidecar mismatch: $path")
    path
end
function _verify_external_pair(path,expected)
    isabspath(path)&&normpath(path)==path&&isfile(path)&&!islink(path)&&realpath(path)==path||error("external primary is not a canonical plain file: $path")
    side=path*".sha256"
    isfile(side)&&!islink(side)&&realpath(side)==side||error("external sidecar is not a canonical plain file: $side")
    digest=_sha256(path);digest==expected||error("external primary hash drift: $path")
    read(side,String)=="$digest  $(basename(path))\n"||error("external sidecar mismatch: $path")
    path
end
function _verify_external_pair(path)
    isabspath(path)&&normpath(path)==path&&isfile(path)&&!islink(path)&&realpath(path)==path||error("external primary is not a canonical plain file: $path")
    side=path*".sha256"
    isfile(side)&&!islink(side)&&realpath(side)==side||error("external sidecar is not a canonical plain file: $side")
    digest=_sha256(path)
    read(side,String)=="$digest  $(basename(path))\n"||error("external sidecar mismatch: $path")
    path
end
function _is_nested(a,b)
    a=normpath(a);b=normpath(b);a==b||startswith(a,b*Base.Filesystem.path_separator)||startswith(b,a*Base.Filesystem.path_separator)
end
function _git(root,args...)
    String(readchomp(Cmd(String["git","-C",root,String.(args)...])))
end
_git_success(root,args...)=success(Cmd(String["git","-C",root,String.(args)...]))
function _git_blob_sha256(root,path,commit)
    root=_safe_dir(root,"git root");path=abspath(path);prefix=root*Base.Filesystem.path_separator
    startswith(path,prefix)||error("bound tool is outside git root: $path")
    relative=relpath(path,root);bytes=read(Cmd(String["git","-C",root,"show","$commit:$relative"]))
    bytes2hex(sha256(bytes))
end
function _require_git_clean(root,label)
    output=readchomp(Cmd(String["git","-C",root,"status","--porcelain=v1","--untracked-files=all"]))
    isempty(output)||error("$label checkout has uncommitted or untracked changes anywhere in the repository")
    nothing
end
function _verify_bound_tool(root,path,commit,expected,label)
    _external_file(path,expected,label)
    _git_blob_sha256(root,path,commit)==expected||error("$label live bytes differ from declared commit blob")
    _require_git_clean(root,label)
    path
end
function _require_ancestor(root,ancestor,descendant,label)
    _git_success(root,"merge-base","--is-ancestor",ancestor,descendant)||error("$label ancestry drift")
    nothing
end
function _require_git_unchanged(root,from,to,paths,label)
    relative=relpath.(paths,Ref(root))
    _git_success(root,"diff","--quiet",from,to,"--",relative...)||error("$label changed between declared commits")
    nothing
end
function _scan_tree(root,subtree)
    top=_plain(root,subtree;directory=true);files=String[];dirs=String[];stack=[top]
    while !isempty(stack)
        dir=pop!(stack);entries=readdir(dir;join=true);isempty(entries)&&error("empty directory in exact tree: $dir")
        for path in entries
            islink(path)&&error("symlink in exact tree: $path")
            if isdir(path)
                realpath(path)==path||error("noncanonical directory in exact tree: $path");push!(dirs,relpath(path,top));push!(stack,path)
            elseif isfile(path)
                realpath(path)==path&&filesize(path)>0||error("noncanonical or empty file in exact tree: $path");push!(files,relpath(path,top))
            else
                error("special file in exact tree: $path")
            end
        end
    end
    sort!(files);sort!(dirs);(files=files,dirs=dirs)
end
function _exact_tree(root,subtree,expected_files;complete=true)
    observed=_scan_tree(root,subtree);files=sort(unique(expected_files));length(files)==length(expected_files)||error("duplicate expected tree member")
    dirs=sort(unique(filter(!=("."),dirname.(files))))
    # dirname only returns immediate parents; include their ancestors.
    expanded=String[];for d in dirs;while d!="."&&!isempty(d);push!(expanded,d);d=dirname(d);end;end;dirs=sort(unique(expanded))
    complete ? (observed.files==files&&observed.dirs==dirs||error("exact tree membership drift: $subtree")) :
        (all(in(files),observed.files)&&all(in(dirs),observed.dirs)||error("unexpected partial tree member: $subtree"))
    observed
end
function _root_members(root,expected_files,expected_dirs)
    entries=readdir(root;join=true);seen_files=String[];seen_dirs=String[]
    for path in entries
        islink(path)&&error("symlink at stage root: $path")
        if isfile(path);filesize(path)>0||error("empty stage-root file: $path");push!(seen_files,basename(path))
        elseif isdir(path);isempty(readdir(path))&&error("empty stage-root directory: $path");push!(seen_dirs,basename(path))
        else;error("special stage-root member: $path");end
    end
    sort(seen_files)==sort(expected_files)&&sort(seen_dirs)==sort(expected_dirs)||error("stage-root exact membership drift")
    nothing
end
function _read_tsv(root,path,columns;verify=true)
    path=verify ? _verify_pair(root,path) : _plain(root,path)
    b=read(path);!isempty(b)&&b[end]==0x0a||error("TSV lacks terminal LF: $path");0x0d in b&&error("CR byte in TSV: $path")
    lines=split(chop(String(b);tail=1),'\n';keepempty=true);all(!isempty,lines)||error("blank TSV row: $path")
    header=split(lines[1],'\t';keepempty=true);header==columns||error("schema drift in $path")
    rows=[split(line,'\t';keepempty=true) for line in lines[2:end]];all(r->length(r)==length(columns),rows)||error("malformed TSV row: $path")
    TSV(header,rows)
end
_dict(t::TSV,r)=Dict(t.columns[i]=>r[i] for i in eachindex(t.columns))
function _int(x,name);occursin(r"^-?[0-9]+$",x)||error("$name is not integer");parse(Int,x);end
function _float(x,name;missing=false)
    x in ("NA","NaN") && missing && return NaN
    y=tryparse(Float64,x);y!==nothing&&isfinite(y)||error("$name is not finite numeric");y
end
function _bool(x,name);x=="true"&&return true;x=="false"&&return false;error("$name must be true/false");end

function _write_once(path,text)
    (ispath(path)||ispath(path*".sha256"))&&error("create-once output exists: $path")
    parent=dirname(path);mkpath(parent)
    isabspath(parent)&&normpath(parent)==parent&&isdir(parent)&&!islink(parent)&&realpath(parent)==parent||error("create-once parent is not canonical and symlink-free: $parent")
    tmp=tempname(parent);open(tmp,"w") do io;write(io,text);end
    try Base.Filesystem.hardlink(tmp,path) catch;rm(tmp;force=true);rethrow();end;rm(tmp;force=true)
    side=path*".sha256";tmp=tempname(parent);open(tmp,"w") do io;print(io,"$(_sha256(path))  $(basename(path))\n");end
    try Base.Filesystem.hardlink(tmp,side) catch;rm(tmp;force=true);rethrow();end;rm(tmp;force=true);nothing
end
function _table_text(columns,rows)
    io=IOBuffer();println(io,join(columns,'\t'))
    for row in rows;println(io,join((_format(getproperty(row,Symbol(c))) for c in columns),'\t'));end
    String(take!(io))
end

function _cell_table()
    rows=NamedTuple[];idx=0
    for n in N_LEVELS, ratio in MARKER_RATIOS, truth in TRUTH_LEVELS
        idx+=1;m=round(Int,n*ratio);code=ratio==0.5 ? "q0500" : ratio==10/3 ? "q3333" : "q5000"
        truth_e2=truth==0.2 ? 0.8 : truth==0.5 ? 0.5 : truth==0.8 ? 0.2 : error("unsupported canonical truth level")
        id=@sprintf("n%04d_m%04d_%s_r%03d",n,m,code,round(Int,100truth))
        push!(rows,(cell_id=id,cell_index=idx,n=n,m=m,marker_ratio=ratio,marker_ratio_code=code,
            truth_sigma_g2=truth,truth_sigma_e2=truth_e2,truth_ratio=truth,ridge=RIDGE))
    end
    rows
end
_d1_cells(cells=_cell_table())=filter(c->c.truth_ratio==0.5,cells)

function _read_cell_table(root,path;verify=true)
    t=_read_tsv(root,path,CELL_TABLE_COLUMNS;verify=verify);length(t.rows)==36||error("cell table must have 36 rows");rows=NamedTuple[]
    for raw in t.rows
        d=_dict(t,raw);push!(rows,(cell_id=d["cell_id"],cell_index=_int(d["cell_index"],"cell index"),n=_int(d["n"],"n"),m=_int(d["m"],"m"),marker_ratio=_float(d["marker_ratio"],"marker ratio"),marker_ratio_code=d["marker_ratio_code"],truth_sigma_g2=_float(d["truth_sigma_g2"],"truth sg"),truth_sigma_e2=_float(d["truth_sigma_e2"],"truth se"),truth_ratio=_float(d["truth_ratio"],"truth ratio"),ridge=_float(d["ridge"],"ridge")))
    end
    _validate_cell_rows(rows)
    rows
end
function _validate_cell_rows(rows)
    expected=_cell_table();length(rows)==length(expected)||error("cell table denominator drift")
    allunique(getproperty.(rows,:cell_id))||error("cell table ID drift")
    for (observed,canonical) in zip(rows,expected)
        observed.cell_id==canonical.cell_id&&observed.cell_index==canonical.cell_index&&observed.n==canonical.n&&observed.m==canonical.m&&observed.marker_ratio_code==canonical.marker_ratio_code||error("cell table identity drift")
        abs(observed.marker_ratio-canonical.marker_ratio)<=1e-12||error("cell table marker-ratio drift")
        observed.truth_sigma_g2==canonical.truth_sigma_g2&&observed.truth_sigma_e2==canonical.truth_sigma_e2&&observed.truth_ratio==canonical.truth_ratio&&observed.ridge==canonical.ridge||error("cell table truth/ridge drift")
    end
    rows
end

function _manifest(root,stage;exact=true)
    cells=_read_cell_table(root,joinpath(root,"cell_table.tsv"))
    columns=stage=="d0f" ? D0F_MANIFEST_COLUMNS : stage=="d1" ? D1_MANIFEST_COLUMNS : error("stage must be d0f or d1")
    path=joinpath(root,"$(stage)_manifest.tsv");t=_read_tsv(root,path,columns);rows=NamedTuple[]
    for raw in t.rows
        d=_dict(t,raw)
        if stage=="d0f"
            push!(rows,(stage=d["stage"],design_id=d["design_id"],design_index=_int(d["design_index"],"design_index"),
                panel_id=d["panel_id"],panel_rank=_int(d["panel_rank"],"panel_rank"),source_cell_id=d["source_cell_id"],
                panel_source_seed=_int(d["panel_source_seed"],"panel_source_seed"),phenotype_rank=_int(d["phenotype_rank"],"phenotype_rank"),
                seed=_int(d["seed"],"seed"),n=_int(d["n"],"n"),m=_int(d["m"],"m"),
                marker_ratio=_float(d["marker_ratio"],"marker_ratio"),retained_m=_int(d["retained_m"],"retained_m"),
                marker_ratio_code="NA",truth_sigma_g2=_float(d["truth_sigma_g2"],"truth_sigma_g2"),
                truth_sigma_e2=_float(d["truth_sigma_e2"],"truth_sigma_e2"),truth_ratio=_float(d["truth_ratio"],"truth_ratio"),
                ridge=_float(d["ridge"],"ridge"),marker_hash=d["marker_hash"],id_hash=d["id_hash"],
                kernel_hash=d["kernel_hash"],precision_hash=d["precision_hash"]))
        else
            push!(rows,(stage=d["stage"],cell_id=d["cell_id"],cell_index=_int(d["cell_index"],"cell_index"),
                seed_offset=_int(d["seed_offset"],"seed_offset"),seed=_int(d["seed"],"seed"),n=_int(d["n"],"n"),m=_int(d["m"],"m"),
                marker_ratio=_float(d["marker_ratio"],"marker_ratio"),marker_ratio_code=d["marker_ratio_code"],
                truth_sigma_g2=_float(d["truth_sigma_g2"],"truth_sigma_g2"),truth_sigma_e2=_float(d["truth_sigma_e2"],"truth_sigma_e2"),
                truth_ratio=_float(d["truth_ratio"],"truth_ratio"),ridge=_float(d["ridge"],"ridge")))
        end
    end
    exact&&_validate_manifest(rows,stage;cells=cells)
    rows,path
end

function _validate_manifest(rows,stage;cells=_cell_table())
    length(rows)==576||error("$stage manifest must contain 576 rows")
    allunique((stage,r.seed) for r in rows)||error("duplicate manifest seed")
    if stage=="d0f"
        expected=Tuple[]
        for d in D0F_DESIGNS,panel in 1:24,rep in 1:8
            source=2_027_120_000+10_000*d.source_index+7100+panel
            seed=D0F_PHENOTYPE_SEED_BASE+100_000*d.index+1000panel+rep
            push!(expected,(d.id,d.index,@sprintf("%s_p%02d",d.id,panel),panel,d.source_cell,source,rep,seed,d.n,d.m,d.marker_ratio))
        end
        observed=[(r.design_id,r.design_index,r.panel_id,r.panel_rank,r.source_cell_id,r.panel_source_seed,r.phenotype_rank,r.seed,r.n,r.m,r.marker_ratio) for r in rows]
        observed==expected||error("D0F membership/order/seed formula drift")
        all(r->r.stage=="d0f"&&1<=r.retained_m<=r.m&&r.truth_sigma_g2==0.5&&r.truth_sigma_e2==0.5&&r.truth_ratio==0.5&&r.ridge==RIDGE,rows)||error("D0F scientific contract drift")
        all(r->all(_hex(getproperty(r,f)) for f in (:marker_hash,:id_hash,:kernel_hash,:precision_hash)),rows)||error("D0F frozen-panel hash drift")
        for d in D0F_DESIGNS,panel in 1:24
            rr=filter(r->r.design_index==d.index&&r.panel_rank==panel,rows)
            all(f->length(unique(getproperty.(rr,f)))==1,(:panel_source_seed,:retained_m,:marker_hash,:id_hash,:kernel_hash,:precision_hash))||error("D0F panel redrawing/hash drift")
        end
    else
        expected=Tuple[]
        for c in _d1_cells(cells),off in 101:148
            push!(expected,(c.cell_id,c.cell_index,off,2_028_000_000+10_000*c.cell_index+off,c.n,c.m,c.marker_ratio,c.marker_ratio_code))
        end
        observed=[(r.cell_id,r.cell_index,r.seed_offset,r.seed,r.n,r.m,r.marker_ratio,r.marker_ratio_code) for r in rows]
        observed==expected||error("D1 membership/order/seed formula drift")
        all(r->r.stage=="d1"&&r.truth_sigma_g2==0.5&&r.truth_sigma_e2==0.5&&r.truth_ratio==0.5&&r.ridge==RIDGE,rows)||error("D1 scientific contract drift")
    end
    nothing
end

function _external_file(path,expected,label)
    _verify_external_pair(path,expected);filesize(path)>0||error("$label is empty");path
end
function _canonical_text(path,label)
    b=read(path);!isempty(b)&&b[end]==0x0a&&!(0x0d in b)&&!(0x00 in b)||error("$label is not canonical LF text");nothing
end
function _validate_cell_table(root,path)
    _read_cell_table(root,path);nothing
end
function _canonical_host_label(value)
    host=rstrip(lowercase(strip(String(value))),'.')
    isempty(host) ? "" : first(split(host,'.';limit=2))
end
function _host_matches(expected;hostname=gethostname(),cluster=get(ENV,"SLURM_CLUSTER_NAME",""))
    expected=_canonical_host_label(expected)
    lowercase(strip(String(cluster)))==expected||_canonical_host_label(hostname)==expected
end
function _assert_execution_context(;hostname=gethostname(),cluster=get(ENV,"SLURM_CLUSTER_NAME",""),job_id=get(ENV,"SLURM_JOB_ID",""),github_actions=get(ENV,"GITHUB_ACTIONS",""),ci=get(ENV,"CI",""))
    lowercase(strip(String(github_actions)))=="true"&&error("recovery-v3 replay is forbidden on GitHub Actions or CI")
    lowercase(strip(String(ci)))=="true"&&error("recovery-v3 replay is forbidden on GitHub Actions or CI")
    host=_canonical_host_label(hostname);cluster=lowercase(strip(String(cluster)))
    admitted=cluster in ("fir","nibi","rorqual","trillium","narval")&&occursin(r"^[1-9][0-9]*$",strip(String(job_id)))
    (host=="totoro"||admitted)||error("recovery-v3 replay requires Totoro or a live admitted DRAC SLURM allocation")
    nothing
end
function _validate_environment(root,path,stage)
    t=_read_tsv(root,path,["key","value"]);length(t.rows)==length(ENVIRONMENT_KEYS)&&getindex.(t.rows,1)==ENVIRONMENT_KEYS||error("environment key/order drift")
    e=Dict(r[1]=>r[2] for r in t.rows);e["stage"]==stage&&e["host"] in ("totoro","fir","nibi","rorqual","trillium","narval")||error("environment stage/host drift")
    e["r_rng_kind"]=="Mersenne-Twister"&&e["r_normal_kind"]=="Inversion"&&e["r_sample_kind"]=="Rejection"||error("R RNG contract drift")
    e["openblas_num_threads"]=="1"&&e["julia_num_threads"]=="1"||error("thread contract drift")
    1<=_int(e["max_workers"],"max workers")<=96||error("worker cap drift");all(!isempty(e[k]) for k in ("r_version","julia_version"))||error("version manifest drift")
    _host_matches(e["host"])||error("live host differs from environment manifest")
    e["julia_version"]==string(VERSION)&&Threads.nthreads()==1&&get(ENV,"OPENBLAS_NUM_THREADS","")=="1"&&BLAS.get_num_threads()==1||error("live Julia version/BLAS/thread state differs from manifest")
    rstate=split(readchomp(Cmd(String["Rscript","--vanilla","-e","cat(c(as.character(getRversion()), RNGkind()), sep='\\t')"])), '\t')
    length(rstate)==4&&rstate[1]==e["r_version"]&&rstate[2]==e["r_rng_kind"]&&rstate[3]==e["r_normal_kind"]&&rstate[4]==e["r_sample_kind"]||error("live R version/RNG state differs from manifest");nothing
end
function _validate_fixed_panels(root,path,manifest)
    t=_read_tsv(root,path,D0F_FIXED_COLUMNS);length(t.rows)==72||error("D0F fixed-panel manifest must have 72 rows")
    shared=Symbol.(D0F_FIXED_COLUMNS);expected=NamedTuple[]
    for d in D0F_DESIGNS,panel in 1:24
        rr=filter(r->r.design_index==d.index&&r.panel_rank==panel,manifest)
        length(rr)==8&&sort(getproperty.(rr,:phenotype_rank))==collect(1:8)||error("D0F panel phenotype denominator/rank drift")
        all(f->length(unique(getproperty.(rr,f)))==1,shared)||error("D0F panel identity/fingerprint drift")
        push!(expected,only(filter(r->r.phenotype_rank==1,rr)))
    end
    for (raw,row) in zip(t.rows,expected)
        d=_dict(t,raw);values=(stage=row.stage,design_id=row.design_id,design_index=row.design_index,source_cell_id=row.source_cell_id,panel_rank=row.panel_rank,panel_source_seed=row.panel_source_seed,n=row.n,m=row.m,marker_ratio=row.marker_ratio,truth_sigma_g2=row.truth_sigma_g2,truth_sigma_e2=row.truth_sigma_e2,truth_ratio=row.truth_ratio,ridge=row.ridge,retained_m=row.retained_m,marker_hash=row.marker_hash,id_hash=row.id_hash,kernel_hash=row.kernel_hash,precision_hash=row.precision_hash)
        text=filter(c->c in ("stage","design_id","source_cell_id","marker_hash","id_hash","kernel_hash","precision_hash"),D0F_FIXED_COLUMNS);ints=filter(c->c in ("design_index","panel_rank","panel_source_seed","n","m","retained_m"),D0F_FIXED_COLUMNS);floats=filter(c->!(c in text||c in ints),D0F_FIXED_COLUMNS)
        all(c->d[c]==string(getproperty(values,Symbol(c))),text)&&all(c->_int(d[c],c)==getproperty(values,Symbol(c)),ints)&&all(c->abs(_float(d[c],c)-getproperty(values,Symbol(c)))<=1e-12,floats)||error("D0F fixed-panel content/order drift")
    end
    nothing
end
function _validate_receipt(root,path,reviewer,p)
    t=_read_tsv(root,path,RECEIPT_COLUMNS);length(t.rows)==1||error("$reviewer receipt row drift");d=_dict(t,only(t.rows))
    d["reviewer"]==reviewer&&d["verdict"]=="CLEAN"&&d["doc49_sha256"]==p["doc49_sha256"]&&d["r_driver_commit"]==p["r_driver_commit"]&&d["r_recomputer_commit"]==p["r_recomputer_commit"]&&d["julia_replay_commit"]==p["julia_replay_commit"]&&d["r_auto_route_commit"]==p["r_auto_route_commit"]&&d["julia_candidate_commit"]==p["julia_candidate_commit"]||error("$reviewer receipt binding drift")
    nothing
end
function _validate_d0f_predecessor(stage_root,p)
    d0froot=_safe_dir(p["d0f_adjudication_root"],"fresh D0F adjudication root")
    d0froot==D0F_BLOCKED_ROOT&&error("blocked unadjudicated D0F root cannot admit D1")
    _is_nested(stage_root,d0froot)&&error("D1 and fresh D0F roots must be distinct and nonnested")
    expected=p["d0f_adjudication_receipt_sha256"]
    _hex(expected)||error("fresh D0F adjudication receipt hash is invalid")
    path=_verify_external_pair(joinpath(d0froot,"stage_adjudication_receipt.tsv"),expected)
    t=_read_tsv(d0froot,path,D0F_ADJUDICATION_COLUMNS);length(t.rows)==1||error("fresh D0F adjudication receipt row drift")
    d=_dict(t,only(t.rows))
    d["schema_version"]==D0F_ADJUDICATION_SCHEMA&&d["stage"]=="d0f"&&d["verdict"]=="PASS"&&d["stage_decision"]=="COMPLETE"||error("fresh D0F receipt is not PASS/COMPLETE")
    for field in ("attempt_max_diff","summary_max_diff")
        value=_float(d[field],field);0<=value<=1e-10||error("fresh D0F adjudication parity exceeds 1e-10")
    end
    for field in filter(x->endswith(x,"_sha256"),D0F_ADJUDICATION_COLUMNS);_hex(d[field])||error("fresh D0F adjudication hash drift: $field");end
    for field in filter(x->endswith(x,"_commit"),D0F_ADJUDICATION_COLUMNS);_hex(d[field],40)||error("fresh D0F adjudication commit drift: $field");end
    for reviewer in REVIEWERS
        d["$(reviewer)_review_path"]==joinpath("postrun_receipts","$reviewer.tsv")||error("fresh D0F post-run review path drift")
    end
    nothing
end
function _validate_d0f_final_tree(r_recomputer_path,d0froot)
    expression="args <- commandArgs(TRUE); source(args[[1L]], local=.GlobalEnv); v3r_validate_final(args[[2L]], 'd0f')"
    cmd=Cmd(String["Rscript","--vanilla","-e",expression,r_recomputer_path,d0froot])
    success(pipeline(cmd,stdout=devnull,stderr=devnull))||error("fresh D0F exact final-tree validation failed")
    nothing
end
function _preseal_input_files(stage)
    names=["doc49.md","cell_table.tsv","historical_seed_lock.tsv","$(stage)_manifest.tsv","environment_manifest.tsv","stage_preseal.tsv"]
    stage=="d0f"&&append!(names,["d0f_fixed_panel_manifest.tsv","d0f_bootstrap_indices.tsv"])
    vcat(names,names.*".sha256")
end
function _validate_preseal_only_tree(root,stage)
    _root_members(root,_preseal_input_files(stage),["receipts"])
    receipt_files=sort(vcat(["$r.tsv" for r in REVIEWERS],["$r.tsv.sha256" for r in REVIEWERS]))
    _exact_tree(root,joinpath(root,"receipts"),receipt_files)
end
function _validate_preseal_tree(root,stage;postrun=false,replay=false,summary=false,final=false)
    final&& !summary&&error("final tree validation requires both summaries")
    final&&error("final adjudication is owned by the schema-bound operational R adjudicator")
    files=_preseal_input_files(stage);dirs=["receipts"]
    postrun&&(append!(files,["stage_corpus_lock.tsv","stage_corpus_lock.tsv.sha256"]);append!(dirs,["attempts","packets"]))
    replay&&push!(dirs,"julia_replay")
    base_r=joinpath(root,"base_r_recompute");rsummary="$(stage)_summary_r.tsv";jsummary="$(stage)_summary_julia.tsv"
    if summary
        isdir(base_r)||error("final summary tree requires complete base_r_recompute")
        push!(dirs,"base_r_recompute")
        for name in (rsummary,jsummary);append!(files,[name,name*".sha256"]);_verify_pair(root,joinpath(root,name));end
    else
        isdir(base_r)&&push!(dirs,"base_r_recompute")
        if ispath(joinpath(root,rsummary))||ispath(joinpath(root,rsummary*".sha256"))
            isdir(base_r)||error("R summary exists without base_r_recompute")
            append!(files,[rsummary,rsummary*".sha256"]);_verify_pair(root,joinpath(root,rsummary))
        end
        (ispath(joinpath(root,jsummary))||ispath(joinpath(root,jsummary*".sha256")))&&error("Julia summary exists before final summary-tree validation")
    end
    receipt="stage_adjudication_receipt.tsv";receipt_present=ispath(joinpath(root,receipt))||ispath(joinpath(root,receipt*".sha256"))
    receipt_present&&error("adjudication receipt validation is owned by the schema-bound operational R adjudicator")
    _root_members(root,files,dirs)
    receipt_files=sort(vcat(["$r.tsv" for r in REVIEWERS],["$r.tsv.sha256" for r in REVIEWERS]));_exact_tree(root,joinpath(root,"receipts"),receipt_files)
end
function _preseal(root,stage,manifest,manifest_path)
    path=joinpath(root,"stage_preseal.tsv");t=_read_tsv(root,path,["key","value"])
    length(t.rows)==length(PRESEAL_KEYS)&&getindex.(t.rows,1)==PRESEAL_KEYS&&allunique(getindex.(t.rows,1))||error("stage preseal key/order drift")
    p=Dict(r[1]=>r[2] for r in t.rows)
    p["schema_version"]==SCHEMA&&p["stage"]==stage&&p["output_root"]==root||error("stage preseal schema/stage/root drift")
    p["official_route"]==PUBLIC_ROUTE&&p["replay_route"]==REPLAY_ROUTE&&p["packet_schema_version"]==PACKET_SCHEMA&&p["truth_schema_version"]==TRUTH_SCHEMA||error("route or packet/truth schema drift")
    p["relationship_source"]=="markers"&&p["relationship_method"]=="vanraden1"&&p["allele_frequency_source"]=="sample"&&p["relationship_scale"]=="K_lambda"||error("relationship contract drift")
    p["ridge"]=="0.01"&&p["boundary_epsilon"]=="1e-07"&&p["boundary_kkt_tolerance"]=="1e-08"&&p["output_subtrees_absent_before_preseal"]=="true"||error("numeric/preseal absence contract drift")
    for k in filter(x->endswith(x,"_sha256")&&p[x]!="NA",PRESEAL_KEYS);_hex(p[k])||error("invalid preseal hash $k");end
    for k in filter(x->endswith(x,"_commit"),PRESEAL_KEYS);_hex(p[k],40)||error("invalid preseal commit $k");end
    p["d0_output_root"]==D0_OFFICIAL_ROOT&&p["d0_adjudication_receipt_sha256"]==D0_RECEIPT_SHA256&&p["d0_diagnostics_sha256"]==D0_DIAGNOSTICS_SHA256||error("frozen D0 root/receipt/diagnostics drift")
    d0root=_safe_dir(p["d0_output_root"],"D0 output root");_is_nested(root,d0root)&&error("stage and D0 roots must be distinct and nonnested")
    _verify_external_pair(joinpath(d0root,"receipt","d0-check-log.md"),D0_RECEIPT_SHA256)
    _verify_external_pair(joinpath(d0root,D0_DIAGNOSTICS_RELATIVE_PATH),D0_DIAGNOSTICS_SHA256)
    bindings=Dict("doc49_sha256"=>"doc49.md","cell_table_sha256"=>"cell_table.tsv","manifest_sha256"=>"$(stage)_manifest.tsv","environment_manifest_sha256"=>"environment_manifest.tsv","historical_seed_lock_sha256"=>"historical_seed_lock.tsv")
    for reviewer in REVIEWERS;bindings["$(reviewer)_receipt_sha256"]="receipts/$reviewer.tsv";end
    if stage=="d0f"
        bindings["d0f_fixed_panel_manifest_sha256"]="d0f_fixed_panel_manifest.tsv";bindings["d0f_bootstrap_indices_sha256"]="d0f_bootstrap_indices.tsv"
        p["d0f_adjudication_root"]=="NA"&&p["d0f_adjudication_receipt_sha256"]=="NA"||error("D0F must not bind a D0F predecessor")
    else
        p["d0f_fixed_panel_manifest_sha256"]=="NA"&&p["d0f_bootstrap_indices_sha256"]=="NA"||error("D1 must not bind D0F inputs")
        _validate_d0f_predecessor(root,p)
    end
    for (key,name) in bindings;_sha256(_verify_pair(root,joinpath(root,name)))==p[key]||error("preseal primary binding drift: $key");end
    _canonical_text(joinpath(root,"doc49.md"),"doc49 copy");_canonical_text(joinpath(root,"historical_seed_lock.tsv"),"historical seed lock");_validate_cell_table(root,joinpath(root,"cell_table.tsv"));_validate_environment(root,joinpath(root,"environment_manifest.tsv"),stage)
    stage=="d0f"&&_validate_fixed_panels(root,joinpath(root,"d0f_fixed_panel_manifest.tsv"),manifest)
    for reviewer in REVIEWERS;_validate_receipt(root,joinpath(root,"receipts","$reviewer.tsv"),reviewer,p);end
    replay_tool=abspath(@__FILE__);julia_root=_git(dirname(replay_tool),"rev-parse","--show-toplevel");_git(julia_root,"rev-parse","HEAD")==p["julia_replay_commit"]||error("Julia checkout differs from preseal")
    _require_ancestor(julia_root,p["julia_candidate_commit"],p["julia_replay_commit"],"Julia candidate/replay")
    _verify_bound_tool(julia_root,replay_tool,p["julia_replay_commit"],p["julia_replay_sha256"],"Julia replay tool")
    julia_surfaces=joinpath.(Ref(julia_root),["src","ext","Project.toml","Manifest.toml"])
    _require_git_unchanged(julia_root,p["julia_candidate_commit"],p["julia_replay_commit"],julia_surfaces,"Julia candidate implementation")
    _require_git_clean(julia_root,"Julia bound implementation")
    rroot_expected=joinpath(dirname(julia_root),"hsquared");_safe_dir(rroot_expected,"deployed sibling R root")
    r_driver_path=joinpath(rroot_expected,"tools","v07_genomic_recovery_v3.R");r_recomputer_path=joinpath(rroot_expected,"tools",R_RECOMPUTER_BASENAME);r_d0_recomputer_path=joinpath(rroot_expected,"tools",R_D0_RECOMPUTER_BASENAME)
    rroot=_git(dirname(r_driver_path),"rev-parse","--show-toplevel");_git(dirname(r_recomputer_path),"rev-parse","--show-toplevel")==rroot&&_git(dirname(r_d0_recomputer_path),"rev-parse","--show-toplevel")==rroot||error("R tools are not in one git root")
    head=_git(rroot,"rev-parse","HEAD");head==p["r_driver_commit"]&&head==p["r_recomputer_commit"]||error("R deployed checkout differs from preseal")
    _require_ancestor(rroot,p["r_auto_route_commit"],p["r_driver_commit"],"R auto-route/driver")
    _verify_bound_tool(rroot,r_driver_path,p["r_driver_commit"],p["r_driver_sha256"],"R driver")
    _verify_bound_tool(rroot,r_recomputer_path,p["r_recomputer_commit"],p["r_recomputer_sha256"],"R recomputer")
    _verify_bound_tool(rroot,r_d0_recomputer_path,p["r_recomputer_commit"],p["d0_recomputer_sha256"],"R D0 recomputer")
    r_surfaces=joinpath.(Ref(rroot),["R","DESCRIPTION","NAMESPACE"])
    _require_git_unchanged(rroot,p["r_auto_route_commit"],p["r_driver_commit"],r_surfaces,"R auto-route implementation")
    _require_git_clean(rroot,"R bound implementation")
    if stage=="d1"
        _validate_d0f_final_tree(r_recomputer_path,p["d0f_adjudication_root"])
    end
    external_doc=joinpath(rroot,"docs","design","49-v07-genomic-recovery-v3-sample-size-ladder.md");_sha256(external_doc)==p["doc49_sha256"]||error("stage doc49 copy differs from deployed R repo")
    _sha256(joinpath(rroot,"docs","design","v07_genomic_recovery_v3_cell_table.tsv"))==p["cell_table_sha256"]||error("stage cell table differs from deployed R repo")
    _sha256(joinpath(rroot,"docs","design","historical_seed_lock.tsv"))==p["historical_seed_lock_sha256"]||error("stage historical seed lock differs from deployed R repo")
    p,path,d0root
end

function preflight(root,stage)
    root=_safe_dir(root,"output root")
    manifest,manifest_path=_manifest(root,stage)
    _preseal(root,stage,manifest,manifest_path)
    _validate_preseal_only_tree(root,stage)
    println("v0.7 genomic recovery-v3 $stage Julia preflight: PASS (sealed inputs only; no official RNG or seed consumed)")
end

function _group(row,stage);stage=="d0f" ? row.design_id : row.cell_id;end
function _key(row,stage);(_group(row,stage),row.seed);end
function _find_manifest(rows,stage,group,seed)
    hits=filter(r->_group(r,stage)==group&&r.seed==seed,rows);length(hits)==1||error("requested packet is not exactly one manifest member");only(hits)
end
function _attempt_columns(stage)
    stage=="d0f" ? vcat(D0F_MANIFEST_COLUMNS,FULL_RESULT_COLUMNS) :
        vcat(D1_MANIFEST_COLUMNS,D1_CONSTRUCTION_COLUMNS,FULL_RESULT_COLUMNS)
end
_replay_columns(stage)=vcat(filter(!=("preseal_sha256"),_attempt_columns(stage)),REPLAY_BINDING_COLUMNS)
function _attempt_path(root,stage,row);joinpath(root,"attempts",stage,_group(row,stage),"$(row.seed).tsv");end
function _packet_dir(root,stage,row);joinpath(root,"packets",stage,_group(row,stage),string(row.seed));end
function _replay_path(root,stage,row);joinpath(root,"julia_replay",stage,_group(row,stage),"$(row.seed).tsv");end

function _official_tree(root,stage,manifest)
    attempts=String[];packets=String[]
    for row in manifest
        ar=relpath(_attempt_path(root,stage,row),joinpath(root,"attempts"));append!(attempts,[ar,ar*".sha256"])
        packet=_packet_dir(root,stage,row)
        for name in PACKET_PRIMARIES;pr=relpath(joinpath(packet,name),joinpath(root,"packets"));append!(packets,[pr,pr*".sha256"]);end
    end
    _exact_tree(root,joinpath(root,"attempts"),attempts);_exact_tree(root,joinpath(root,"packets"),packets);nothing
end
function _replay_tree(root,stage,manifest;complete=true)
    files=String[];for row in manifest;rp=relpath(_replay_path(root,stage,row),joinpath(root,"julia_replay"));append!(files,[rp,rp*".sha256"]);end
    _exact_tree(root,joinpath(root,"julia_replay"),files;complete=complete)
end
_verify_replay_tree_quiescent(root,stage,manifest)=_replay_tree(root,stage,manifest;complete=true)
function _base_r_tree(root,stage,manifest)
    files=String[];for row in manifest;rp=joinpath(stage,_group(row,stage),"$(row.seed).tsv");append!(files,[rp,rp*".sha256"]);end
    _exact_tree(root,joinpath(root,"base_r_recompute"),files)
end
function _corpus_lock(root,stage,manifest,preseal_path)
    path=joinpath(root,"stage_corpus_lock.tsv");t=_read_tsv(root,path,CORPUS_COLUMNS)
    paths=String[preseal_path,joinpath(root,"$(stage)_manifest.tsv")]
    for row in manifest
        push!(paths,_attempt_path(root,stage,row));packet=_packet_dir(root,stage,row)
        append!(paths,joinpath.(Ref(packet),PACKET_PRIMARIES))
    end
    expected=sort([[relpath(p,root),_sha256(_verify_pair(root,p))] for p in paths];by=first)
    t.rows==expected||error("current corpus differs from post-run lock");_official_tree(root,stage,manifest)
    t,path
end

function _corpus_digest_map(lock::TSV)
    paths=getindex.(lock.rows,1);allunique(paths)||error("duplicate corpus-lock member")
    all(r->length(r)==2&&!isempty(r[1])&&_hex(r[2]),lock.rows)||error("malformed corpus-lock digest row")
    Dict(r[1]=>r[2] for r in lock.rows)
end
function _verify_locked_pair(root,path,digests)
    relative=relpath(path,root);haskey(digests,relative)||error("seed input is absent from corpus lock: $relative")
    _sha256(_verify_pair(root,path))==digests[relative]||error("seed input differs from retained corpus-lock digest: $relative")
    path
end
function _verify_locked_seed_inputs(root,stage,row,digests)
    _verify_locked_pair(root,_attempt_path(root,stage,row),digests)
    packet=_packet_dir(root,stage,row)
    for name in PACKET_PRIMARIES;_verify_locked_pair(root,joinpath(packet,name),digests);end
    nothing
end

function _batch_partition(manifest,batch_index,batch_count)
    1<=batch_count<=min(96,length(manifest))||error("batch count must be in 1:min(96, manifest rows)")
    1<=batch_index<=batch_count||error("batch index must be in 1:batch_count")
    [(rank=rank,row=manifest[rank]) for rank in batch_index:batch_count:length(manifest)]
end
_batch_basename(stage,batch_index,batch_count)=@sprintf("%s-batch-%03d-of-%03d.tsv",stage,batch_index,batch_count)
function _batch_rows(stage,manifest,batch_index,batch_count;manifest_sha,preseal_sha,corpus_sha)
    [(schema_version=BATCH_SCHEMA,stage=stage,batch_index=batch_index,batch_count=batch_count,manifest_rank=x.rank,
        group_id=_group(x.row,stage),seed=x.row.seed,manifest_sha256=manifest_sha,preseal_sha256=preseal_sha,
        corpus_lock_sha256=corpus_sha) for x in _batch_partition(manifest,batch_index,batch_count)]
end
function _write_batch_manifests(root,stage,batch_dir,batch_count)
    root=_safe_dir(root,"output root");batch_dir=_safe_dir(batch_dir,"external batch directory")
    _is_nested(root,batch_dir)&&error("batch directory must be external to the evidence root")
    isempty(readdir(batch_dir))||error("external batch directory must be empty before deterministic batch generation")
    manifest,mpath=_manifest(root,stage);_,ppath,_=_preseal(root,stage,manifest,mpath);_,cpath=_corpus_lock(root,stage,manifest,ppath)
    _batch_partition(manifest,1,batch_count) # validate before the first external write
    manifest_sha=_sha256(mpath);preseal_sha=_sha256(ppath);corpus_sha=_sha256(cpath)
    for batch_index in 1:batch_count
        path=joinpath(batch_dir,_batch_basename(stage,batch_index,batch_count))
        rows=_batch_rows(stage,manifest,batch_index,batch_count;manifest_sha=manifest_sha,preseal_sha=preseal_sha,corpus_sha=corpus_sha)
        _write_once(path,_table_text(BATCH_COLUMNS,rows))
    end
    println("wrote $batch_count deterministic external Julia $stage replay batch manifests rows=$(length(manifest))")
end
function _read_batch_manifest(root,path,stage,manifest;manifest_sha,preseal_sha,corpus_sha)
    isabspath(path)||error("batch manifest must be absolute")
    path=normpath(path);_is_nested(root,path)&&error("batch manifest must be external to the evidence root")
    _verify_external_pair(path)
    t=_read_tsv(dirname(path),path,BATCH_COLUMNS);isempty(t.rows)&&error("batch manifest is empty")
    firstrow=_dict(t,first(t.rows));batch_index=_int(firstrow["batch_index"],"batch index");batch_count=_int(firstrow["batch_count"],"batch count")
    basename(path)==_batch_basename(stage,batch_index,batch_count)||error("batch manifest filename is not deterministic")
    expected=_batch_rows(stage,manifest,batch_index,batch_count;manifest_sha=manifest_sha,preseal_sha=preseal_sha,corpus_sha=corpus_sha)
    expected_text=_table_text(BATCH_COLUMNS,expected)
    read(path,String)==expected_text||error("batch manifest membership, uniqueness, order, or binding drift")
    (rows=[manifest[x.manifest_rank] for x in expected],batch_index=batch_index,batch_count=batch_count,path=path)
end

function _batch_target_prefix(root,stage,rows;resume_complete_prefix=true)
    prefix=0;missing_seen=false
    for row in rows
        path=_replay_path(root,stage,row);primary=ispath(path);sidecar=ispath(path*".sha256")
        primary==sidecar||error("partial replay primary/sidecar pair: $path")
        if primary
            resume_complete_prefix||error("create-once replay target exists: $path")
            missing_seen&&error("existing replay is not a complete resumable prefix: $path")
            _verify_pair(root,path);t=_read_tsv(root,path,_replay_columns(stage));length(t.rows)==1||error("resumable replay row count drift")
            d=_dict(t,only(t.rows));d["stage"]==stage&&d[stage=="d0f" ? "design_id" : "cell_id"]==_group(row,stage)&&_int(d["seed"],"resumable seed")==row.seed||error("resumable replay identity drift")
            prefix+=1
        else
            missing_seen=true
        end
    end
    prefix
end

_truth_columns(stage)=vcat(stage=="d0f" ? D0F_MANIFEST_COLUMNS : vcat(D1_MANIFEST_COLUMNS,D1_CONSTRUCTION_COLUMNS),TRUTH_PROVENANCE_COLUMNS)
function _packet(root,stage,row,preseal,preseal_sha)
    dir=_packet_dir(root,stage,row);actual=sort(readdir(_plain(root,dir;directory=true)))
    actual==sort(vcat(PACKET_PRIMARIES,PACKET_PRIMARIES.*".sha256"))||error("packet file-set drift")
    lock=_read_tsv(root,joinpath(dir,"packet_files_lock.tsv"),["file","sha256"])
    length(lock.rows)==4&&getindex.(lock.rows,1)==PACKET_PRIMARIES[1:4]||error("packet lock drift")
    for (i,name) in enumerate(PACKET_PRIMARIES[1:4]);lock.rows[i][2]==_sha256(_verify_pair(root,joinpath(dir,name)))||error("packet inner-lock drift");end
    ids_t=_read_tsv(root,joinpath(dir,"ids.tsv"),["index","id"]);length(ids_t.rows)==row.n||error("ID denominator drift")
    ids=String[];for (i,r) in enumerate(ids_t.rows);_int(r[1],"ID index")==i&&!isempty(r[2])||error("ID order drift");push!(ids,r[2]);end;allunique(ids)||error("duplicate ID")
    marker_path=_verify_pair(root,joinpath(dir,"markers.tsv"));b=read(marker_path);!isempty(b)&&b[end]==0x0a&&!(0x0d in b)||error("marker TSV byte drift")
    lines=split(chop(String(b);tail=1),'\n';keepempty=true);header=split(lines[1],'\t';keepempty=true);header[1]=="id"||error("marker schema drift")
    names=header[2:end];length(lines)-1==row.n&&!isempty(names)&&allunique(names)&&all(x->occursin(r"^m[0-9]{6}$",x),names)||error("marker denominator/name drift")
    M=Matrix{Float64}(undef,row.n,length(names));for i in 1:row.n
        f=split(lines[i+1],'\t';keepempty=true);length(f)==length(header)&&f[1]==ids[i]||error("marker row drift")
        for j in eachindex(names);M[i,j]=_float(f[j+1],"dosage");M[i,j] in (0.0,1.0,2.0)||error("non-hard-call dosage");end
    end
    ph=_read_tsv(root,joinpath(dir,"phenotype.tsv"),["index","id","y"]);length(ph.rows)==row.n||error("phenotype denominator drift")
    y=Float64[];for (i,r) in enumerate(ph.rows);_int(r[1],"phenotype index")==i&&r[2]==ids[i]||error("phenotype order drift");push!(y,_float(r[3],"phenotype"));end
    manifest_columns=stage=="d0f" ? D0F_MANIFEST_COLUMNS : D1_MANIFEST_COLUMNS
    truth=_read_tsv(root,joinpath(dir,"truth.tsv"),_truth_columns(stage));length(truth.rows)==1||error("truth row drift")
    td=_dict(truth,only(truth.rows));mv=_manifest_values(row,stage)
    for c in manifest_columns
        string(getproperty(mv,Symbol(c)))==td[c]||_format(getproperty(mv,Symbol(c)))==td[c]||error("truth/manifest mismatch in $c")
    end
    retained=_int(td["retained_m"],"retained_m");retained==size(M,2)&&1<=retained<=row.m||error("retained-marker drift")
    all(j->length(unique(view(M,:,j)))>1,axes(M,2))||error("retained marker is monomorphic")
    p=vec(sum(M,dims=1))./(2row.n);W=M.-2 .* transpose(p);k=2sum(p.*(1 .- p));k>0||error("nonpositive VanRaden denominator")
    abs(_float(td["scale_denominator"],"truth k")-k)<=1e-10||error("truth scale drift")
    K=(W*transpose(W))./k+RIDGE*I;Q=Matrix(inv(Symmetric(K)));maximum(abs.(Q*K-I))<=1e-10||error("QK drift")
    marker_hash=D0Support._marker_hash(M,ids,names);id_hash=D0Support._id_hash(ids);kernel_hash=D0Support._matrix_hash("K_lambda",K,ids);precision_hash=D0Support._matrix_hash("Q_lambda",Q,ids)
    for (field,value) in (("marker_hash",marker_hash),("id_hash",id_hash),("kernel_hash",kernel_hash),("precision_hash",precision_hash));td[field]==value||error("truth packet $field drift");end
    td["packet_schema_version"]==PACKET_SCHEMA&&td["truth_schema_version"]==TRUTH_SCHEMA&&td["relationship_source"]=="markers"&&td["relationship_method"]=="vanraden1"&&td["allele_frequency_source"]=="sample"&&td["relationship_scale"]=="K_lambda"||error("truth schema/relationship drift")
    td["preseal_sha256"]==preseal_sha&&td["r_implementation_commit"]==preseal["r_auto_route_commit"]&&td["julia_implementation_commit"]==preseal["julia_candidate_commit"]&&td["driver_commit"]==preseal["r_driver_commit"]||error("truth preseal/implementation drift")
    spectrum=D0Support._spectral((Matrix(inv(Symmetric(Q)))+transpose(Matrix(inv(Symmetric(Q)))))/2,D0Support._helmert(row.n))
    (M=M,ids=ids,names=names,y=y,k=k,K=Matrix(K),Q=Q,retained_m=retained,marker_hash=marker_hash,id_hash=id_hash,kernel_hash=kernel_hash,precision_hash=precision_hash,spectrum=spectrum)
end

function _manifest_values(row,stage)
    if stage=="d0f"
        (stage=row.stage,design_id=row.design_id,design_index=row.design_index,panel_id=row.panel_id,panel_rank=row.panel_rank,source_cell_id=row.source_cell_id,panel_source_seed=row.panel_source_seed,phenotype_rank=row.phenotype_rank,seed=row.seed,n=row.n,m=row.m,marker_ratio=row.marker_ratio,retained_m=row.retained_m,truth_sigma_g2=row.truth_sigma_g2,truth_sigma_e2=row.truth_sigma_e2,truth_ratio=row.truth_ratio,ridge=row.ridge,marker_hash=row.marker_hash,id_hash=row.id_hash,kernel_hash=row.kernel_hash,precision_hash=row.precision_hash)
    else
        (stage=row.stage,cell_id=row.cell_id,cell_index=row.cell_index,seed_offset=row.seed_offset,seed=row.seed,n=row.n,m=row.m,marker_ratio=row.marker_ratio,marker_ratio_code=row.marker_ratio_code,truth_sigma_g2=row.truth_sigma_g2,truth_sigma_e2=row.truth_sigma_e2,truth_ratio=row.truth_ratio,ridge=row.ridge)
    end
end

function _read_attempt(root,stage,row,preseal,preseal_sha,packet)
    path=_attempt_path(root,stage,row);t=_read_tsv(root,path,_attempt_columns(stage));length(t.rows)==1||error("attempt row count drift")
    d=_dict(t,only(t.rows));mv=_manifest_values(row,stage)
    for c in (stage=="d0f" ? D0F_MANIFEST_COLUMNS : D1_MANIFEST_COLUMNS)
        string(getproperty(mv,Symbol(c)))==d[c] || (_format(getproperty(mv,Symbol(c)))==d[c]) || error("attempt/manifest mismatch in $c")
    end
    attempted=_bool(d["attempted"],"attempted");converged=_bool(d["converged"],"converged");attempted||error("attempted=false")
    d["route"]==PUBLIC_ROUTE&&d["r_implementation_commit"]==preseal["r_auto_route_commit"]&&d["julia_implementation_commit"]==preseal["julia_candidate_commit"]&&d["driver_commit"]==preseal["r_driver_commit"]&&d["preseal_sha256"]==preseal_sha||error("attempt route/implementation/preseal drift")
    d["relationship_source"]=="markers"&&d["relationship_method"]=="vanraden1"&&d["allele_frequency_source"]=="sample"&&d["relationship_scale"]=="K_lambda"||error("attempt relationship provenance drift")
    for (field,value) in (("marker_hash",packet.marker_hash),("id_hash",packet.id_hash),("kernel_hash",packet.kernel_hash),("precision_hash",packet.precision_hash));d[field]==value||error("attempt packet $field drift");end
    _int(d["retained_m"],"retained_m")==packet.retained_m&&abs(_float(d["scale_denominator"],"scale")-packet.k)<=1e-10||error("attempt construction drift")
    spectral=(("eigen_cv_population",packet.spectrum.cv),("effective_rank",packet.spectrum.effective_rank),("information_r020",packet.spectrum.information[1]),("se_info_r020",packet.spectrum.se[1]),("information_r050",packet.spectrum.information[2]),("se_info_r050",packet.spectrum.se[2]),("information_r080",packet.spectrum.information[3]),("se_info_r080",packet.spectrum.se[3]))
    all(abs(_float(d[f],f)-v)<=1e-10 for (f,v) in spectral)||error("attempt spectral packet drift")
    runtime=_float(d["runtime_seconds"],"runtime");rss=_float(d["peak_rss_mb"],"rss");runtime>=0&&rss>=0||error("attempt runtime/RSS drift")
    good=d["status"]=="success";good==converged&&(good ? d["error_class"]=="none" : d["error_class"]!="none")||error("attempt status drift")
    good ? _validate_resolved(d) : _validate_unsuccessful(d)
    (dict=d,path=path,good=good)
end

function _validate_resolved(d)
    status=d["boundary_status"];status in RESOLVED||error("unresolved successful attempt")
    d["boundary_reason"]==RESOLVED_REASONS[status]||error("resolved boundary reason drift")
    ratio=_float(d["scientific_ratio"],"scientific_ratio");nr=_float(d["numerical_ratio"],"numerical_ratio");total=_float(d["fitted_total_variance"],"total")
    sg=_float(d["scientific_sigma_g2"],"scientific sg");se=_float(d["scientific_sigma_e2"],"scientific se")
    ng=_float(d["numerical_sigma_g2"],"numerical sg");ne=_float(d["numerical_sigma_e2"],"numerical se")
    d0=_float(d["lower_derivative_per_observation"],"lower derivative");d1=_float(d["upper_derivative_per_observation"],"upper derivative")
    status=="boundary_lower"&&(ratio==0&&nr==BOUNDARY_EPSILON&&d0<=KKT_TOLERANCE)||status=="boundary_upper"&&(ratio==1&&nr==1-BOUNDARY_EPSILON&&d1>=-KKT_TOLERANCE)||status in ("interior","interior_rescued")&&(0<ratio<1&&d0>KKT_TOLERANCE&&d1< -KKT_TOLERANCE)||error("boundary/KKT representation drift")
    abs(sg-ratio*total)<=1e-12&&abs(se-(1-ratio)*total)<=1e-12&&abs(ng+ne-total)<=1e-12&&abs(nr-ng/(ng+ne))<=1e-12||error("scientific/numerical component drift")
    _float(d["boundary_epsilon"],"boundary epsilon")==BOUNDARY_EPSILON||error("boundary epsilon drift")
    for f in ("profile_loglik","objective","gradient_norm");isfinite(_float(d[f],f))||error("nonfinite successful $f");end
    _int(d["iterations"],"iterations")>=0||error("negative successful iterations")
    true
end
function _validate_unsuccessful(d)
    d["status"]=="fit_error"||error("unsuccessful status drift")
    fitmissing=split("scientific_sigma_g2 scientific_sigma_e2 scientific_ratio fitted_total_variance numerical_sigma_g2 numerical_sigma_e2 numerical_ratio iterations objective gradient_norm")
    all(f->d[f]=="NA",fitmissing)||error("unavailable fit outputs must be canonical NA")
    boundary=(d["profile_loglik"],d["lower_derivative_per_observation"],d["upper_derivative_per_observation"])
    if d["boundary_status"]=="boundary_unresolved"
        d["boundary_reason"]!="NA"&&!isempty(d["boundary_reason"])&&_float(d["boundary_epsilon"],"boundary epsilon")==BOUNDARY_EPSILON||error("unresolved boundary metadata drift")
        (all(==("NA"),boundary)||all(x->isfinite(_float(x,"unresolved boundary evidence")),boundary))||error("partial unresolved boundary evidence")
    else
        d["boundary_status"]=="NA"&&d["boundary_reason"]=="NA"&&d["boundary_epsilon"]=="NA"&&all(==("NA"),boundary)||error("ordinary error boundary fields must be canonical NA")
    end
    true
end
function _validate_generated_replay(result)
    validation=Dict(string(k)=>_format(v) for (k,v) in pairs(result))
    result.status=="success" ? _validate_resolved(validation) : _validate_unsuccessful(validation)
    result
end

function _profile_replay(row,packet)
    started=time_ns();rss0=Sys.maxrss();s=packet.spectrum
    base=(attempted=true,status="fit_error",error_class="unclassified_replay_error",converged=false,boundary_status="NA",boundary_reason="NA",boundary_epsilon=NaN,
        scientific_sigma_g2=NaN,scientific_sigma_e2=NaN,scientific_ratio=NaN,fitted_total_variance=NaN,numerical_sigma_g2=NaN,numerical_sigma_e2=NaN,numerical_ratio=NaN,profile_loglik=NaN,lower_derivative_per_observation=NaN,upper_derivative_per_observation=NaN,iterations=NaN,objective=NaN,gradient_norm=NaN)
    result=base
    try
        spec=animal_model_spec(packet.y,ones(row.n,1),sparse(1.0I,row.n,row.n),packet.Q;ids=packet.ids,method=:REML)
        provenance=(relationship_source="markers",id_order_fingerprint=packet.id_hash,precision_fingerprint=packet.precision_hash,kernel_fingerprint=packet.kernel_hash)
        out=HSquared._fit_ai_reml_genomic_boundary(spec;provenance=provenance,kernel=packet.K)
        b=out.boundary;status=String(b.status);fit=out.fit
        if fit===nothing
            status=="boundary_unresolved" ? (result=merge(base,(error_class=String(b.reason),boundary_status=status,boundary_reason=String(b.reason),boundary_epsilon=Float64(b.boundary_epsilon),profile_loglik=b.profile_loglik===nothing ? NaN : Float64(b.profile_loglik),lower_derivative_per_observation=b.lower_derivative_per_observation===nothing ? NaN : Float64(b.lower_derivative_per_observation),upper_derivative_per_observation=b.upper_derivative_per_observation===nothing ? NaN : Float64(b.upper_derivative_per_observation)))) : (result=merge(base,(error_class=String(b.reason),)))
        else
            vc=fit.variance_components;total=vc.sigma_a2+vc.sigma_e2;nr=vc.sigma_a2/total
            pr=b.profile_ratio===nothing ? NaN : Float64(b.profile_ratio);good=status in RESOLVED&&fit.converged&&isfinite(pr)&&isfinite(total)&&total>0
            grad=hasproperty(out.ai_diagnostics,:ai_score_norm) ? Float64(out.ai_diagnostics.ai_score_norm) : NaN
            if good
                result=(attempted=true,status="success",error_class="none",converged=true,boundary_status=status,boundary_reason=String(b.reason),boundary_epsilon=Float64(b.boundary_epsilon),scientific_sigma_g2=pr*total,scientific_sigma_e2=(1-pr)*total,scientific_ratio=pr,fitted_total_variance=total,numerical_sigma_g2=vc.sigma_a2,numerical_sigma_e2=vc.sigma_e2,numerical_ratio=nr,profile_loglik=b.profile_loglik===nothing ? NaN : Float64(b.profile_loglik),lower_derivative_per_observation=b.lower_derivative_per_observation===nothing ? NaN : Float64(b.lower_derivative_per_observation),upper_derivative_per_observation=b.upper_derivative_per_observation===nothing ? NaN : Float64(b.upper_derivative_per_observation),iterations=fit.iterations,objective=-fit.likelihood.loglik,gradient_norm=grad)
                _validate_resolved(Dict(string(k)=>_format(v) for (k,v) in pairs(result)))
            else
                result=merge(base,(error_class="replay_not_resolved",))
            end
        end
    catch err
        result=merge(base,(error_class=_error_class(err),))
    end
    runtime=(time_ns()-started)/1e9;rss=max(rss0,Sys.maxrss())/1024^2
    final=merge(result,(runtime_seconds=runtime,peak_rss_mb=rss,retained_m=packet.retained_m,scale_denominator=packet.k,
        eigen_cv_population=s.cv,effective_rank=s.effective_rank,information_r020=s.information[1],se_info_r020=s.se[1],information_r050=s.information[2],se_info_r050=s.se[2],information_r080=s.information[3],se_info_r080=s.se[3],relationship_source="markers",relationship_method="vanraden1",allele_frequency_source="sample",relationship_scale="K_lambda",marker_hash=packet.marker_hash,id_hash=packet.id_hash,kernel_hash=packet.kernel_hash,precision_hash=packet.precision_hash,route=REPLAY_ROUTE))
    _validate_generated_replay(final)
end

function _numeric_difference(text,value,field)
    if text=="NA"
        return value isa AbstractFloat&&isnan(value) ? 0.0 : Inf
    end
    value isa Real&&isfinite(value)||return Inf
    abs(_float(text,field)-Float64(value))
end
function _source_difference(attempt,replay)
    d=attempt.dict
    d["status"]==replay.status&&d["error_class"]==replay.error_class&&_bool(d["converged"],"converged")==replay.converged&&d["boundary_status"]==replay.boundary_status&&d["boundary_reason"]==replay.boundary_reason||return Inf
    fields=("boundary_epsilon","scientific_sigma_g2","scientific_sigma_e2","scientific_ratio","fitted_total_variance","numerical_sigma_g2","numerical_sigma_e2","numerical_ratio","profile_loglik","lower_derivative_per_observation","upper_derivative_per_observation","iterations","objective","gradient_norm","scale_denominator","eigen_cv_population","effective_rank","information_r020","se_info_r020","information_r050","se_info_r050","information_r080","se_info_r080")
    maximum(_numeric_difference(d[f],getproperty(replay,Symbol(f)),f) for f in fields)
end
function _summary_performance(source,replay_runtime,replay_rss)
    replay_runtime>=0&&replay_rss>=0||error("replay runtime/RSS drift")
    runtime=_float(source.dict["runtime_seconds"],"source R runtime");rss=_float(source.dict["peak_rss_mb"],"source R RSS")
    runtime>=0&&rss>=0||error("source R runtime/RSS drift")
    (runtime_seconds=runtime,peak_rss_mb=rss,replay_runtime_seconds=Float64(replay_runtime),replay_peak_rss_mb=Float64(replay_rss))
end

function _validate_d0f_source(d0root,row,packet)
    _safe_dir(d0root,"D0 evidence root")
    path=joinpath(d0root,D0_DIAGNOSTICS_RELATIVE_PATH);table=_read_tsv(d0root,path,D0Support.PACKET_COLUMNS)
    hits=filter(raw->raw[1]==row.source_cell_id&&_int(raw[3],"D0 diagnostic seed")==row.panel_source_seed,table.rows)
    length(hits)==1||error("D0F source diagnostic is not exactly one frozen D0 row")
    _validate_d0f_diagnostic_row(_dict(table,only(hits)),row,packet)
end
function _validate_d0f_diagnostic_row(d,row,packet)
    d["cell_id"]==row.source_cell_id&&_int(d["seed"],"D0 diagnostic seed")==row.panel_source_seed&&_int(d["cell_index"],"D0 diagnostic cell index") in 1:9||error("D0F source diagnostic identity drift")
    _int(d["n"],"D0 diagnostic n")==row.n&&_int(d["m"],"D0 diagnostic m")==row.m&&_float(d["truth_ratio"],"D0 diagnostic truth ratio")==row.truth_ratio&&_int(d["retained_m"],"D0 diagnostic retained_m")==row.retained_m&&_float(d["ridge"],"D0 diagnostic ridge")==row.ridge||error("D0F source diagnostic scientific contract drift")
    for field in (:marker_hash,:id_hash,:kernel_hash,:precision_hash)
        value=d[string(field)];_hex(value)&&getproperty(row,field)==value&&getproperty(packet,field)==value||error("D0F fixed-panel $field drift")
    end
    nothing
end

function replay_one(root,stage,group,seed)
    root=_safe_dir(root,"output root");manifest,mpath=_manifest(root,stage);preseal,ppath,d0root=_preseal(root,stage,manifest,mpath);lock,cpath=_corpus_lock(root,stage,manifest,ppath)
    row=_find_manifest(manifest,stage,group,seed);digests=_corpus_digest_map(lock)
    _replay_prepared_one(root,stage,row,preseal,mpath,ppath,cpath,d0root,digests)
end

function _prepared_replay_row(root,stage,row,preseal,mpath,ppath,cpath,d0root,digests)
    _verify_locked_seed_inputs(root,stage,row,digests)
    preseal_sha=_sha256(ppath);corpus_sha=_sha256(cpath);packet=_packet(root,stage,row,preseal,preseal_sha);stage=="d0f"&&_validate_d0f_source(d0root,row,packet)
    attempt=_read_attempt(root,stage,row,preseal,preseal_sha,packet);replay=_profile_replay(row,packet);diff=_source_difference(attempt,replay);isfinite(diff)&&diff<=1e-10||error("official route and Julia replay differ beyond 1e-10")
    replay=merge(replay,(r_implementation_commit=preseal["r_auto_route_commit"],julia_implementation_commit=preseal["julia_candidate_commit"],driver_commit=preseal["julia_replay_commit"],preseal_sha256=preseal_sha))
    common=merge(_manifest_values(row,stage),replay,(source_r_attempt_sha256=_sha256(attempt.path),source_r_max_abs_difference=diff,replay_julia_commit=preseal["julia_replay_commit"],replay_driver_sha256=_sha256(abspath(@__FILE__)),manifest_sha256=_sha256(mpath),preseal_sha256=preseal_sha,corpus_lock_sha256=corpus_sha))
    (columns=_replay_columns(stage),row=common,diff=diff)
end

function _replay_prepared_one(root,stage,row,preseal,mpath,ppath,cpath,d0root,digests)
    outpath=_replay_path(root,stage,row);(ispath(outpath)||ispath(outpath*".sha256"))&&error("create-once replay exists")
    prepared=_prepared_replay_row(root,stage,row,preseal,mpath,ppath,cpath,d0root,digests)
    columns=prepared.columns;common=prepared.row;diff=prepared.diff
    _write_once(outpath,_table_text(columns,[common]));_verify_pair(root,outpath)
    println("wrote Julia $stage replay $(_group(row,stage))/$(row.seed) source_max_abs_difference=$(_format(diff))")
    nothing
end

function _validate_resumable_row(observed,columns,expected_row)
    length(observed)==length(columns)||error("resumable replay row width drift")
    expected=split(chomp(_table_text(columns,[expected_row])),'\n')[2]
    expected=split(expected,'\t';keepempty=true)
    for (index,column) in enumerate(columns)
        column in ("runtime_seconds","peak_rss_mb")&&continue
        observed[index]==expected[index]||error("resumable replay differs from fresh recomputation in $column")
    end
    values=Dict(zip(columns,observed))
    for column in ("runtime_seconds","peak_rss_mb")
        value=_float(values[column],"resumable $column")
        isfinite(value)&&value>=0||error("resumable replay $column is invalid")
    end
    nothing
end

function _validate_existing_batch_replay(root,stage,row,preseal,mpath,ppath,cpath,d0root,digests)
    prepared=_prepared_replay_row(root,stage,row,preseal,mpath,ppath,cpath,d0root,digests)
    path=_replay_path(root,stage,row);t=_read_tsv(root,path,prepared.columns);length(t.rows)==1||error("resumable replay row count drift")
    _validate_resumable_row(only(t.rows),prepared.columns,prepared.row)
    nothing
end

function replay_batch(root,stage,batch_manifest_path;resume_complete_prefix=true)
    root=_safe_dir(root,"output root")
    manifest,mpath=_manifest(root,stage)
    preseal,ppath,d0root=_preseal(root,stage,manifest,mpath)
    lock,cpath=_corpus_lock(root,stage,manifest,ppath) # exactly one full corpus validation for this batch
    digests=_corpus_digest_map(lock)
    batch=_read_batch_manifest(root,batch_manifest_path,stage,manifest;manifest_sha=_sha256(mpath),preseal_sha=_sha256(ppath),corpus_sha=_sha256(cpath))
    prefix=_batch_target_prefix(root,stage,batch.rows;resume_complete_prefix=resume_complete_prefix)
    for (index,row) in enumerate(batch.rows)
        if index<=prefix
            _validate_existing_batch_replay(root,stage,row,preseal,mpath,ppath,cpath,d0root,digests)
        else
            _replay_prepared_one(root,stage,row,preseal,mpath,ppath,cpath,d0root,digests)
        end
    end
    println("completed Julia $stage replay batch $(batch.batch_index)/$(batch.batch_count) rows=$(length(batch.rows)) resumed_prefix=$prefix")
    nothing
end

function _validate_replay_bindings(d;source_sha,replay_commit,replay_sha,manifest_sha,preseal_sha,corpus_sha)
    d["source_r_attempt_sha256"]==source_sha&&d["replay_julia_commit"]==replay_commit&&d["replay_driver_sha256"]==replay_sha&&d["manifest_sha256"]==manifest_sha&&d["preseal_sha256"]==preseal_sha&&d["corpus_lock_sha256"]==corpus_sha||error("replay binding drift")
    true
end

function _read_replays(root,stage,manifest,preseal,mpath,ppath,cpath,d0root)
    columns=_replay_columns(stage);rows=NamedTuple[];preseal_sha=_sha256(ppath);corpus_sha=_sha256(cpath)
    for mr in manifest
        path=_replay_path(root,stage,mr);t=_read_tsv(root,path,columns);length(t.rows)==1||error("replay row count drift");d=_dict(t,only(t.rows));mv=_manifest_values(mr,stage)
        for c in (stage=="d0f" ? D0F_MANIFEST_COLUMNS : D1_MANIFEST_COLUMNS);d[c] in (string(getproperty(mv,Symbol(c))),_format(getproperty(mv,Symbol(c))))||error("replay/manifest mismatch in $c");end
        packet=_packet(root,stage,mr,preseal,preseal_sha);stage=="d0f"&&_validate_d0f_source(d0root,mr,packet)
        source=_read_attempt(root,stage,mr,preseal,preseal_sha,packet)
        for (field,value) in (("retained_m",string(packet.retained_m)),("marker_hash",packet.marker_hash),("id_hash",packet.id_hash),("kernel_hash",packet.kernel_hash),("precision_hash",packet.precision_hash));d[field]==value||error("replay packet $field drift");end
        d["route"]==REPLAY_ROUTE&&d["r_implementation_commit"]==preseal["r_auto_route_commit"]&&d["julia_implementation_commit"]==preseal["julia_candidate_commit"]&&d["driver_commit"]==preseal["julia_replay_commit"]||error("replay route/implementation drift")
        d["relationship_source"]=="markers"&&d["relationship_method"]=="vanraden1"&&d["allele_frequency_source"]=="sample"&&d["relationship_scale"]=="K_lambda"||error("replay relationship provenance drift")
        _validate_replay_bindings(d;source_sha=_sha256(source.path),replay_commit=preseal["julia_replay_commit"],replay_sha=_sha256(abspath(@__FILE__)),manifest_sha=_sha256(mpath),preseal_sha=preseal_sha,corpus_sha=corpus_sha)
        converged=_bool(d["converged"],"converged");good=d["status"]=="success";good==converged&&(good ? d["error_class"]=="none" : d["error_class"]!="none")||error("replay status drift");good ? _validate_resolved(d) : _validate_unsuccessful(d)
        replay_runtime=_float(d["runtime_seconds"],"replay runtime");replay_rss=_float(d["peak_rss_mb"],"replay RSS");performance=_summary_performance(source,replay_runtime,replay_rss)
        parsed=(attempted=_bool(d["attempted"],"attempted"),status=d["status"],error_class=d["error_class"],converged=converged,boundary_status=d["boundary_status"],boundary_reason=d["boundary_reason"],boundary_epsilon=_float(d["boundary_epsilon"],"boundary epsilon";missing=true),scientific_sigma_g2=_float(d["scientific_sigma_g2"],"sg";missing=true),scientific_sigma_e2=_float(d["scientific_sigma_e2"],"se";missing=true),scientific_ratio=_float(d["scientific_ratio"],"ratio";missing=true),fitted_total_variance=_float(d["fitted_total_variance"],"total";missing=true),numerical_sigma_g2=_float(d["numerical_sigma_g2"],"nsg";missing=true),numerical_sigma_e2=_float(d["numerical_sigma_e2"],"nse";missing=true),numerical_ratio=_float(d["numerical_ratio"],"nr";missing=true),profile_loglik=_float(d["profile_loglik"],"profile";missing=true),lower_derivative_per_observation=_float(d["lower_derivative_per_observation"],"lower";missing=true),upper_derivative_per_observation=_float(d["upper_derivative_per_observation"],"upper";missing=true),iterations=_float(d["iterations"],"iterations";missing=true),objective=_float(d["objective"],"objective";missing=true),gradient_norm=_float(d["gradient_norm"],"gradient";missing=true),runtime_seconds=performance.runtime_seconds,peak_rss_mb=performance.peak_rss_mb,replay_runtime_seconds=performance.replay_runtime_seconds,replay_peak_rss_mb=performance.replay_peak_rss_mb,retained_m=packet.retained_m,scale_denominator=_float(d["scale_denominator"],"scale"),eigen_cv_population=_float(d["eigen_cv_population"],"CV"),effective_rank=_float(d["effective_rank"],"rank"),information_r020=_float(d["information_r020"],"info020"),se_info_r020=_float(d["se_info_r020"],"se020"),information_r050=_float(d["information_r050"],"info050"),se_info_r050=_float(d["se_info_r050"],"se050"),information_r080=_float(d["information_r080"],"info080"),se_info_r080=_float(d["se_info_r080"],"se080"))
        parsed.attempted||error("replay attempted drift")
        diff=_source_difference(source,parsed);stored=_float(d["source_r_max_abs_difference"],"source diff");isfinite(diff)&&diff<=1e-10&&abs(stored-diff)<=1e-12||error("replay source comparison drift")
        push!(rows,merge(parsed,(manifest=mr,dict=d,path=path)))
    end
    length(rows)==length(manifest)||error("replay denominator drift");rows
end

function verify_replay(root,stage)
    root=_safe_dir(root,"output root");manifest,mpath=_manifest(root,stage);preseal,ppath,d0root=_preseal(root,stage,manifest,mpath);_,cpath=_corpus_lock(root,stage,manifest,ppath)
    _verify_replay_tree_quiescent(root,stage,manifest);_validate_preseal_tree(root,stage;postrun=true,replay=true)
    rows=_read_replays(root,stage,manifest,preseal,mpath,ppath,cpath,d0root)
    println("verified complete quiescent Julia $stage replay rows=$(length(rows))")
    rows
end

function _external_indices(path,expected,columns)
    _verify_external_pair(path,expected)
    root=dirname(path);_read_tsv(root,path,columns;verify=false)
end

function _quantile7(x,p);y=sort(Float64.(x));h=(length(y)-1)*p+1;lo=floor(Int,h);hi=ceil(Int,h);lo==hi ? y[lo] : y[lo]+(h-lo)*(y[hi]-y[lo]);end
function _d0f_summary_impl(rows,indices,bootstrap_sha,bootstrap_reps)
    bootstrap_reps isa Int&&bootstrap_reps>=1||error("D0F bootstrap replicate count drift")
    length(rows)==576||error("D0F replay denominator drift");length(indices.rows)==3*bootstrap_reps*24||error("D0F bootstrap row count drift");cursor=1;out=NamedTuple[]
    corpus_complete=all(x->x.converged&&isfinite(x.scientific_ratio),rows)
    for d in D0F_DESIGNS
        rr=filter(x->x.manifest.design_index==d.index,rows);length(rr)==192||error("D0F design denominator drift")
        matrix=fill(NaN,24,8);for x in rr;matrix[x.manifest.panel_rank,x.manifest.phenotype_rank]=x.scientific_ratio;end
        within=corpus_complete ? mean(var(view(matrix,k,:);corrected=true) for k in 1:24) : NaN;between=corpus_complete ? var(vec(mean(matrix;dims=2));corrected=true)-within/8 : NaN
        bw=Float64[];bb=Float64[]
        for rep in 1:bootstrap_reps
            draw=Matrix{Float64}(undef,24,8)
            for slot in 1:24
                row=indices.rows[cursor];cursor+=1;row[1]==d.id&&_int(row[2],"design index")==d.index&&_int(row[3],"bootstrap rep")==rep&&_int(row[4],"panel slot")==slot||error("D0F bootstrap order drift")
                panel=_int(row[5],"panel rank");panel in 1:24||error("bootstrap panel range")
                for j in 1:8;ph=_int(row[5+j],"phenotype rank");ph in 1:8||error("bootstrap phenotype range");corpus_complete&&(draw[slot,j]=matrix[panel,ph]);end
            end
            if corpus_complete;w=mean(var(view(draw,k,:);corrected=true) for k in 1:24);push!(bw,w);push!(bb,var(vec(mean(draw;dims=2));corrected=true)-w/8);end
        end
        conv=count(x->x.converged,rr);counts=Dict(s=>count(x->x.converged&&x.boundary_status==s,rr) for s in RESOLVED);unresolved=count(x->!x.converged&&x.boundary_status=="boundary_unresolved",rr);nerror=count(x->!x.converged&&x.boundary_status!="boundary_unresolved",rr)
        sum(values(counts))+unresolved+nerror==192||error("D0F classification totals do not equal 192")
        runt=getproperty.(rr,:runtime_seconds);rss=getproperty.(rr,:peak_rss_mb)
        classes=join(["$x=$(count(r->r.error_class==x,rr))" for x in sort(unique(getproperty.(rr,:error_class)))],";");panelmeans=corpus_complete ? vec(mean(matrix;dims=2)) : Float64[]
        lower_panels=corpus_complete ? [count(j->rr[(k-1)*8+j].boundary_status=="boundary_lower",1:8)/8 for k in 1:24] : Float64[];upper_panels=corpus_complete ? [count(j->rr[(k-1)*8+j].boundary_status=="boundary_upper",1:8)/8 for k in 1:24] : Float64[]
        push!(out,(stage="d0f",design_id=d.id,design_index=d.index,n=d.n,m=d.m,n_panels=24,phenotypes_per_panel=8,n_expected=192,n_attempted=192,n_converged=conv,n_interior=counts["interior"],n_interior_rescued=counts["interior_rescued"],n_boundary_lower=counts["boundary_lower"],n_boundary_upper=counts["boundary_upper"],n_unresolved=unresolved,n_error=nerror,failure_classes=classes,convergence_rate=conv/192,d0f_status=corpus_complete ? "COMPLETE" : "D0F_FIT_BLOCKER",fit_blocker=!corpus_complete,bootstrap_sha256=bootstrap_sha,variance_within=within,variance_within_bootstrap_lower=corpus_complete ? _quantile7(bw,.025) : NaN,variance_within_bootstrap_upper=corpus_complete ? _quantile7(bw,.975) : NaN,variance_between=between,variance_between_bootstrap_lower=corpus_complete ? _quantile7(bb,.025) : NaN,variance_between_bootstrap_upper=corpus_complete ? _quantile7(bb,.975) : NaN,mean_ratio=corpus_complete ? mean(matrix) : NaN,mcse_mean_ratio=corpus_complete ? std(panelmeans)/sqrt(24) : NaN,empirical_sd_ratio=corpus_complete ? std(vec(matrix)) : NaN,boundary_lower_proportion=corpus_complete ? counts["boundary_lower"]/192 : NaN,boundary_upper_proportion=corpus_complete ? counts["boundary_upper"]/192 : NaN,mcse_boundary_lower=corpus_complete ? std(lower_panels)/sqrt(24) : NaN,mcse_boundary_upper=corpus_complete ? std(upper_panels)/sqrt(24) : NaN,median_runtime_seconds=_quantile7(runt,.5),p95_runtime_seconds=_quantile7(runt,.95),median_peak_rss_mb=_quantile7(rss,.5),p95_peak_rss_mb=_quantile7(rss,.95)))
    end
    cursor==length(indices.rows)+1||error("D0F bootstrap cursor drift")
    out
end
_d0f_summary(rows,indices,bootstrap_sha)=_d0f_summary_impl(rows,indices,bootstrap_sha,10_000)

# Dependency-free distribution helpers, retained here so summary decisions are
# independent of the R state machine.
function _loggamma(z)
    c=(0.99999999999980993,676.5203681218851,-1259.1392167224028,771.32342877765313,-176.615029162079,12.507343278686905,-0.13857109526572012,9.984369578019572e-6,1.5056327351493116e-7)
    z<0.5&&return log(pi)-log(sinpi(z))-_loggamma(1-z);x=c[1];q=z-1;for i in 2:length(c);x+=c[i]/(q+i-1);end;t=q+7.5;0.5log(2pi)+(q+.5)*log(t)-t+log(x)
end
function _betacf(a,b,x)
    qab=a+b;qap=a+1;qam=a-1;c=1.0;d=1-qab*x/qap;abs(d)<floatmin(Float64)&&(d=floatmin(Float64));d=1/d;h=d
    for m in 1:10000;m2=2m;aa=m*(b-m)*x/((qam+m2)*(a+m2));d=1+aa*d;abs(d)<floatmin(Float64)&&(d=floatmin(Float64));c=1+aa/c;abs(c)<floatmin(Float64)&&(c=floatmin(Float64));d=1/d;h*=d*c;aa=-(a+m)*(qab+m)*x/((a+m2)*(qap+m2));d=1+aa*d;abs(d)<floatmin(Float64)&&(d=floatmin(Float64));c=1+aa/c;abs(c)<floatmin(Float64)&&(c=floatmin(Float64));d=1/d;del=d*c;h*=del;abs(del-1)<2e-15&&break;end;h
end
function _ibeta(a,b,x);x<=0&&return 0.0;x>=1&&return 1.0;bt=exp(_loggamma(a+b)-_loggamma(a)-_loggamma(b)+a*log(x)+b*log1p(-x));x<(a+1)/(a+b+2) ? bt*_betacf(a,b,x)/a : 1-bt*_betacf(b,a,1-x)/b;end
_tcdf(t,df)=t==0 ? .5 : t>0 ? 1-.5*_ibeta(df/2,.5,df/(df+t*t)) : .5*_ibeta(df/2,.5,df/(df+t*t))
function _tquantile(p,df);lo,hi=-1.0,1.0;while _tcdf(lo,df)>p;lo*=2;end;while _tcdf(hi,df)<p;hi*=2;end;for _ in 1:120;mid=(lo+hi)/2;_tcdf(mid,df)<p ? (lo=mid) : (hi=mid);end;(lo+hi)/2;end
function _gamma_p(a,x)
    x==0&&return 0.0
    if x<a+1;ap=a;term=sum=1/a;for _ in 1:10000;ap+=1;term*=x/ap;sum+=term;abs(term)<=abs(sum)*2e-15&&break;end;return sum*exp(-x+a*log(x)-_loggamma(a));end
    b=x+1-a;c=1/floatmin(Float64);d=1/b;h=d;for i in 1:10000;an=-i*(i-a);b+=2;d=an*d+b;abs(d)<floatmin(Float64)&&(d=floatmin(Float64));c=b+an/c;abs(c)<floatmin(Float64)&&(c=floatmin(Float64));d=1/d;delta=d*c;h*=delta;abs(delta-1)<=2e-15&&break;end;1-exp(-x+a*log(x)-_loggamma(a))*h
end
_chisq_cdf(x,df)=_gamma_p(df/2,x/2)
function _chisq_quantile(p,df);lo=0.0;hi=max(1.0,Float64(df));while _chisq_cdf(hi,df)<p;hi*=2;end;for _ in 1:140;mid=(lo+hi)/2;_chisq_cdf(mid,df)<p ? (lo=mid) : (hi=mid);end;(lo+hi)/2;end
function _wilson(k,n);z=1.959963984540054;p=k/n;den=1+z^2/n;center=(p+z^2/(2n))/den;half=z*sqrt(p*(1-p)/n+z^2/(4n^2))/den;(center-half,center+half);end
function _percentile(x,p);_quantile7(x,p);end

function _d1_summary(rows)
    out=NamedTuple[]
    cells=NamedTuple[];seen=Set{String}();for x in rows;if !(x.manifest.cell_id in seen);push!(seen,x.manifest.cell_id);push!(cells,x.manifest);end;end
    length(cells)==12||error("D1 summary cell-table projection drift")
    for c in cells
        rr=filter(x->x.manifest.cell_id==c.cell_id,rows);length(rr)==48||error("D1 cell denominator drift")
        good=filter(x->x.converged&&all(isfinite,(x.scientific_sigma_g2,x.scientific_sigma_e2,x.scientific_ratio,x.se_info_r050)),rr);n=length(good);rate=n/48;wl,wu=_wilson(n,48)
        counts=Dict(s=>count(x->x.boundary_status==s&&x.converged,rr) for s in RESOLVED);unresolved=count(x->!x.converged&&x.boundary_status=="boundary_unresolved",rr);nerror=count(x->!x.converged&&x.boundary_status!="boundary_unresolved",rr)
        sum(values(counts))+unresolved+nerror==48||error("D1 classification totals do not equal 48")
        stats=NamedTuple[]
        for (target,field,truth,margin) in (("sigma_g2",:scientific_sigma_g2,c.truth_sigma_g2,0.05 * c.truth_sigma_g2),("sigma_e2",:scientific_sigma_e2,c.truth_sigma_e2,0.05 * c.truth_sigma_e2),("ratio",:scientific_ratio,c.truth_ratio,0.02))
            vals=Float64[getproperty(x,field) for x in good];mn=n>=2 ? mean(vals) : NaN;bias=mn-truth;sdv=n>=2 ? std(vals) : NaN;mcse=sdv/sqrt(n);q=n>=2 ? _tquantile(.975,n-1) : NaN;lo=bias-q*mcse;hi=bias+q*mcse
            rmse=n>0 ? sqrt(mean((vals.-truth).^2)) : NaN;sq=(vals.-truth).^2;mcser=rmse==0 ? (all(==(0),sq) ? 0.0 : NaN) : n>=2 ? std(sq)/(2rmse*sqrt(n)) : NaN
            su=n>=2 ? sdv*sqrt((n-1)/_chisq_quantile(.05,n-1)) : NaN;raw=isfinite(su) ? ceil(Int,(1.959963984540054*su/(margin/2))^2) : typemax(Int)
            fut=isfinite(lo)&&isfinite(hi)&&(lo>=margin||hi<=-margin);push!(stats,(target=target,truth=truth,mean=mn,bias=bias,mcse=mcse,lo=lo,hi=hi,margin=margin,rmse=rmse,mcser=mcser,sd=sdv,su=su,raw=raw,futile=fut))
        end
        required=maximum(s.raw for s in stats);recompute_ok=all(x->x.attempted,rr)&&sum(values(counts))+unresolved+nerror==48
        runt=getproperty.(rr,:runtime_seconds);rss=getproperty.(rr,:peak_rss_mb);rmsse=n>0 ? sqrt(mean(abs2,getproperty.(good,:se_info_r050))) : NaN;ratio_sd=n>=2 ? std(getproperty.(good,:scientific_ratio)) : NaN
        seall=getproperty.(rr,:se_info_r050);predlower=mean(D0Support._normal_cdf(-c.truth_ratio/se) for se in seall);predupper=mean(D0Support._normal_upper((1-c.truth_ratio)/se) for se in seall);obslower=counts["boundary_lower"]/48;obsupper=counts["boundary_upper"]/48
        derived=(rmsse,ratio_sd,ratio_sd/rmsse,predlower,predupper)
        summary_nonfinite=!(all(s->all(isfinite,(s.mean,s.bias,s.mcse,s.lo,s.hi,s.margin,s.rmse,s.mcser,s.sd,s.su)),stats)&&all(isfinite,derived)&&all(x->isfinite(x)&&x>0,seall)&&all(isfinite,runt)&&all(isfinite,rss)&&all(x->isfinite(x)&&x>=0,getproperty.(rr,:eigen_cv_population))&&all(x->isfinite(x)&&x>0,getproperty.(rr,:effective_rank)))
        low=n<46;precision=required!=typemax(Int)&&required>2000;futility=any(s.futile for s in stats)
        recompute_ok&&!(summary_nonfinite&&!low)||error("stage RECOMPUTATION_BLOCKER: D1 summary inputs are nonfinite or inconsistent")
        eligible=!low&&!summary_nonfinite&&!precision&&!futility;status=low ? "STOP_LOW_PILOT_CONVERGENCE" : summary_nonfinite ? error("stage RECOMPUTATION_BLOCKER: D1 summary is nonfinite") : precision ? "PRECISION_BLOCKER" : futility ? "FUTILITY_STOP" : "ELIGIBLE"
        classes=join(["$x=$(count(r->r.error_class==x,rr))" for x in sort(unique(getproperty.(rr,:error_class)))],";")
        common=(stage="d1",cell_id=c.cell_id,cell_index=c.cell_index,n=c.n,m=c.m,marker_ratio=c.marker_ratio,truth_ratio=c.truth_ratio,n_expected=48,n_attempted=48,n_converged=n,n_bias_rows=n,n_interior=counts["interior"],n_interior_rescued=counts["interior_rescued"],n_boundary_lower=counts["boundary_lower"],n_boundary_upper=counts["boundary_upper"],n_unresolved=unresolved,n_error=nerror,convergence_rate=rate,wilson_lower=wl,wilson_upper=wu,cell_eligible=eligible,cell_status=status,median_runtime_seconds=_percentile(runt,.5),p95_runtime_seconds=_percentile(runt,.95),median_peak_rss_mb=_percentile(rss,.5),p95_peak_rss_mb=_percentile(rss,.95),rms_se_info=rmsse,empirical_sd_over_rms_se_info=ratio_sd/rmsse,predicted_boundary_lower=predlower,predicted_boundary_upper=predupper,observed_boundary_lower=obslower,observed_boundary_upper=obsupper,mcse_boundary_lower=sqrt(obslower*(1-obslower)/48),mcse_boundary_upper=sqrt(obsupper*(1-obsupper)/48),mean_spectral_cv=mean(getproperty.(rr,:eigen_cv_population)),mean_effective_rank=mean(getproperty.(rr,:effective_rank)),failure_classes=classes)
        for s in stats;push!(out,merge(common,(target=s.target,truth=s.truth,mean_estimate=s.mean,bias=s.bias,mcse=s.mcse,bias_ci_lower=s.lo,bias_ci_upper=s.hi,margin=s.margin,rmse=s.rmse,mcse_rmse=s.mcser,empirical_sd=s.sd,pilot_sd_upper=s.su,required_n_raw=s.raw==typemax(Int) ? Inf : s.raw,required_n=required==typemax(Int) ? Inf : max(200,required),low_convergence=low,summary_nonfinite=summary_nonfinite,precision_blocked=precision,futility_stopped=futility,target_futile=s.futile)));end
    end
    out
end

function summarize(root,stage;bootstrap=nothing)
    root=_safe_dir(root,"output root");manifest,mpath=_manifest(root,stage);preseal,ppath,d0root=_preseal(root,stage,manifest,mpath);_,cpath=_corpus_lock(root,stage,manifest,ppath);_verify_replay_tree_quiescent(root,stage,manifest)
    isdir(joinpath(root,"base_r_recompute"))||error("Julia summary requires complete base_r_recompute")
    _base_r_tree(root,stage,manifest);_verify_pair(root,joinpath(root,"$(stage)_summary_r.tsv"));_validate_preseal_tree(root,stage;postrun=true,replay=true)
    rows=_read_replays(root,stage,manifest,preseal,mpath,ppath,cpath,d0root)
    path=joinpath(root,"$(stage)_summary_julia.tsv");(ispath(path)||ispath(path*".sha256"))&&error("create-once summary exists")
    if stage=="d0f"
        canonical=joinpath(root,"d0f_bootstrap_indices.tsv");bootstrap!==nothing&&bootstrap!=canonical&&error("D0F summary accepts only the canonical stage-root bootstrap manifest")
        idx=_external_indices(canonical,preseal["d0f_bootstrap_indices_sha256"],D0F_BOOTSTRAP_COLUMNS);summary=_d0f_summary(rows,idx,preseal["d0f_bootstrap_indices_sha256"]);_write_once(path,_table_text(D0F_SUMMARY_COLUMNS,summary))
    else
        summary=_d1_summary(rows);_write_once(path,_table_text(D1_SUMMARY_COLUMNS,summary))
    end
    _validate_preseal_tree(root,stage;postrun=true,replay=true,summary=true);println("wrote Julia $stage summary rows=$(length(summary)) sha256=$(_sha256(path))")
end

function validate_final(root,stage)
    error("validate-final is owned by the schema-bound operational R adjudicator")
end

function _canonical_r_d0f_parity_text(component)
    component in ("bootstrap","summary")||error("unsupported canonical R D0F parity component")
    julia_root=_git(dirname(abspath(@__FILE__)),"rev-parse","--show-toplevel");rroot=joinpath(dirname(julia_root),"hsquared")
    _safe_dir(rroot,"sibling R parity root")
    code=join([
        "source(\"tools/v07_genomic_recovery_v3_preseal.R\")",
        "h64 <- function(x) paste(rep(x, 64L), collapse = \"\")",
        "h40 <- function(x) paste(rep(x, 40L), collapse = \"\")",
        "b <- list(preseal_sha256=h64(\"e\"), manifest_sha256=h64(\"f\"), corpus_lock_sha256=h64(\"a\"), r_auto_route_commit=h40(\"a\"), julia_candidate_commit=h40(\"b\"), r_driver_commit=h40(\"c\"), julia_replay_commit=h40(\"d\"), julia_replay_sha256=h64(\"b\"))",
        "fixture <- v3p_d0f_summary_parity_fixture(b)",
        "cat(v07d_tsv_text(fixture\$$component))",
    ],"\n")
    read(Cmd(Cmd(String["Rscript","--vanilla","-e",code]);dir=rroot),String)
end
function _canonical_r_d1_parity_text()
    julia_root=_git(dirname(abspath(@__FILE__)),"rev-parse","--show-toplevel");rroot=joinpath(dirname(julia_root),"hsquared")
    _safe_dir(rroot,"sibling R parity root")
    code=join([
        "source(\"tools/v07_genomic_recovery_v3_preseal.R\")",
        "h64 <- function(x) paste(rep(x, 64L), collapse = \"\")",
        "h40 <- function(x) paste(rep(x, 40L), collapse = \"\")",
        "b <- list(preseal_sha256=h64(\"e\"), manifest_sha256=h64(\"f\"), corpus_lock_sha256=h64(\"a\"), r_auto_route_commit=h40(\"a\"), julia_candidate_commit=h40(\"b\"), r_driver_commit=h40(\"c\"), julia_replay_commit=h40(\"d\"), julia_replay_sha256=h64(\"b\"))",
        "cat(v07d_tsv_text(v3p_d1_summary_parity_fixture(b)\$summary))",
    ],"\n")
    read(Cmd(Cmd(String["Rscript","--vanilla","-e",code]);dir=rroot),String)
end
function _parse_tsv_text(text,columns)
    !isempty(text)&&endswith(text,'\n')&&!occursin('\r',text)||error("canonical R parity TSV byte drift")
    lines=split(chop(text;tail=1),'\n');split(first(lines),'\t';keepempty=true)==columns||error("canonical R parity schema drift")
    rows=[split(line,'\t';keepempty=true) for line in lines[2:end]];all(r->length(r)==length(columns),rows)||error("canonical R parity row drift")
    rows
end
function _parity_field_equal(actual,expected)
    actual isa Bool&&return expected==_format(actual)
    actual isa Integer&&return expected==string(actual)
    if actual isa AbstractFloat
        expected in ("NA","NaN")&&return isnan(actual)
        parsed=tryparse(Float64,expected);return parsed!==nothing&&isfinite(actual)&&isfinite(parsed)&&abs(Float64(actual)-parsed)<=1e-10
    end
    expected==string(actual)
end
function _verify_full_r_d0f_parity(summary)
    text=_canonical_r_d0f_parity_text("summary")
    expected=_parse_tsv_text(text,D0F_SUMMARY_COLUMNS);length(summary)==length(expected)==3||error("R/Julia D0F parity denominator drift")
    for (i,(actual,row)) in enumerate(zip(summary,expected)),(j,column) in enumerate(D0F_SUMMARY_COLUMNS)
        _parity_field_equal(getproperty(actual,Symbol(column)),row[j])||error("R/Julia D0F parity mismatch row=$i field=$column")
    end
    true
end
function _verify_full_r_parity(summary)
    text=_canonical_r_d1_parity_text()
    expected=_parse_tsv_text(text,D1_SUMMARY_COLUMNS);length(summary)==length(expected)==36||error("R/Julia D1 parity denominator drift")
    for (i,(actual,row)) in enumerate(zip(summary,expected)),(j,column) in enumerate(D1_SUMMARY_COLUMNS)
        _parity_field_equal(getproperty(actual,Symbol(column)),row[j])||error("R/Julia D1 parity mismatch row=$i field=$column")
    end
    true
end

function _must_fail(label,f);failed=false;try f() catch;failed=true end;failed||error("mutation stayed green: $label");end
function batch_selftest()
    manifest=[(stage="d1",cell_id=@sprintf("synthetic_%02d",i),seed=9000+i,truth_ratio=.5) for i in 1:12]
    partitions=[_batch_partition(manifest,i,5) for i in 1:5]
    ranks=reduce(vcat,[[x.rank for x in part] for part in partitions])
    sort(ranks)==collect(1:12)&&allunique(ranks)||error("focused batch exact-union selftest")
    reversed=reduce(vcat,[[x.rank for x in part] for part in reverse(partitions)])
    Dict(i=>(manifest[i].cell_id,manifest[i].seed,manifest[i].truth_ratio) for i in ranks)==Dict(i=>(manifest[i].cell_id,manifest[i].seed,manifest[i].truth_ratio) for i in reversed)||error("focused batch order-invariance selftest")
    resume_columns=["stage","scientific_ratio","runtime_seconds","peak_rss_mb"]
    resume_expected=(stage="d1",scientific_ratio=.5,runtime_seconds=1.0,peak_rss_mb=2.0)
    _validate_resumable_row(["d1","0.5","99","88"],resume_columns,resume_expected)
    _must_fail("focused resumed scientific mutation") do;_validate_resumable_row(["d1","0.6","99","88"],resume_columns,resume_expected);end
    _must_fail("focused resumed invalid runtime") do;_validate_resumable_row(["d1","0.5","NA","88"],resume_columns,resume_expected);end
    dir=mktempdir()
    try
        root=realpath(dir);evidence=joinpath(root,"evidence");external=joinpath(root,"external");mkdir(evidence);mkdir(external)
        mh=repeat("a",64);ph=repeat("b",64);ch=repeat("c",64);index=2;count=5
        rows=_batch_rows("d1",manifest,index,count;manifest_sha=mh,preseal_sha=ph,corpus_sha=ch)
        path=joinpath(external,_batch_basename("d1",index,count));_write_once(path,_table_text(BATCH_COLUMNS,rows))
        parsed=_read_batch_manifest(evidence,path,"d1",manifest;manifest_sha=mh,preseal_sha=ph,corpus_sha=ch)
        parsed.rows==[x.row for x in _batch_partition(manifest,index,count)]||error("focused batch parse selftest")
        function bad_manifest(name,badrows)
            sub=joinpath(root,name);mkdir(sub);p=joinpath(sub,_batch_basename("d1",index,count));_write_once(p,_table_text(BATCH_COLUMNS,badrows));p
        end
        duplicate=copy(rows);duplicate[2]=duplicate[1]
        _must_fail("focused duplicate batch") do;_read_batch_manifest(evidence,bad_manifest("duplicate",duplicate),"d1",manifest;manifest_sha=mh,preseal_sha=ph,corpus_sha=ch);end
        unknown=copy(rows);unknown[1]=merge(unknown[1],(seed=typemax(Int),))
        _must_fail("focused unknown batch") do;_read_batch_manifest(evidence,bad_manifest("unknown",unknown),"d1",manifest;manifest_sha=mh,preseal_sha=ph,corpus_sha=ch);end
        _must_fail("focused reversed batch") do;_read_batch_manifest(evidence,bad_manifest("reversed",reverse(rows)),"d1",manifest;manifest_sha=mh,preseal_sha=ph,corpus_sha=ch);end
        inside=joinpath(evidence,_batch_basename("d1",index,count));_write_once(inside,_table_text(BATCH_COLUMNS,rows))
        _must_fail("focused batch wrong root") do;_read_batch_manifest(evidence,inside,"d1",manifest;manifest_sha=mh,preseal_sha=ph,corpus_sha=ch);end

        locked=joinpath(root,"locked");mkdir(locked);lockrow=manifest[1]
        locked_paths=[_attempt_path(locked,"d1",lockrow);joinpath.(_packet_dir(locked,"d1",lockrow),PACKET_PRIMARIES)]
        for p in locked_paths;_write_once(p,"$(basename(p))\n");end
        digests=Dict(relpath(p,locked)=>_sha256(p) for p in locked_paths);_verify_locked_seed_inputs(locked,"d1",lockrow,digests)
        mutated=joinpath(_packet_dir(locked,"d1",lockrow),"markers.tsv");write(mutated,"mutated after preparation\n");write(mutated*".sha256","$(_sha256(mutated))  $(basename(mutated))\n")
        _must_fail("focused post-preparation mutation") do;_verify_locked_seed_inputs(locked,"d1",lockrow,digests);end

        targets=joinpath(root,"targets");mkdir(targets);targetrows=manifest[1:2];columns=_replay_columns("d1")
        values=Dict(c=>"NA" for c in columns);values["stage"]="d1";values["cell_id"]=targetrows[1].cell_id;values["seed"]=string(targetrows[1].seed)
        target_text=join(columns,'\t')*"\n"*join([values[c] for c in columns],'\t')*"\n"
        _write_once(_replay_path(targets,"d1",targetrows[1]),target_text)
        _batch_target_prefix(targets,"d1",targetrows;resume_complete_prefix=true)==1||error("focused resumable-prefix selftest")
        _must_fail("focused existing target") do;_batch_target_prefix(targets,"d1",targetrows;resume_complete_prefix=false);end
        partial=_replay_path(targets,"d1",targetrows[2]);mkpath(dirname(partial));write(partial,"partial\n")
        _must_fail("focused partial pair") do;_batch_target_prefix(targets,"d1",targetrows;resume_complete_prefix=true);end

        nonprefix=joinpath(root,"nonprefix");mkdir(nonprefix);values["cell_id"]=targetrows[2].cell_id;values["seed"]=string(targetrows[2].seed)
        target_text=join(columns,'\t')*"\n"*join([values[c] for c in columns],'\t')*"\n";_write_once(_replay_path(nonprefix,"d1",targetrows[2]),target_text)
        _must_fail("focused non-prefix existing target") do;_batch_target_prefix(nonprefix,"d1",targetrows;resume_complete_prefix=true);end
    finally
        rm(dir;recursive=true,force=true)
    end
    println("v0.7 genomic recovery-v3 Julia replay batching selftest: PASS (synthetic only; no official RNG or seed consumed)")
end
function selftest()
    length(_d1_cells())==12&&length(_cell_table())==36||error("cell-table selftest")
    julia_root=_git(dirname(abspath(@__FILE__)),"rev-parse","--show-toplevel");rroot=joinpath(dirname(julia_root),"hsquared");actual_cell_table=joinpath(rroot,"docs","design","v07_genomic_recovery_v3_cell_table.tsv");_read_cell_table(dirname(actual_cell_table),actual_cell_table;verify=false)
    _validate_cell_rows(_cell_table());_must_fail("sub-tolerance truth mutation") do;x=copy(_cell_table());x[1]=merge(x[1],(truth_ratio=x[1].truth_ratio+5e-13,));_validate_cell_rows(x);end
    marker_tolerance=copy(_cell_table());marker_tolerance[1]=merge(marker_tolerance[1],(marker_ratio=marker_tolerance[1].marker_ratio+5e-13,));_validate_cell_rows(marker_tolerance)
    length(PRESEAL_KEYS)==41&&PRESEAL_KEYS[9]=="d0_diagnostics_sha256"&&PRESEAL_KEYS[10]=="d0f_adjudication_root"&&D0_DIAGNOSTICS_RELATIVE_PATH==joinpath("r","d0_packet_diagnostics_base_r.tsv")&&D0_DIAGNOSTICS_SHA256=="7c1cbc165df90e844bd4fdc7fc6ffb6dcbb8343c0d5ca9e7a588e4ca6d48c370"||error("frozen D0/D0F predecessor preseal binding drift")
    RECEIPT_COLUMNS==split("reviewer verdict doc49_sha256 r_driver_commit r_recomputer_commit julia_replay_commit r_auto_route_commit julia_candidate_commit")||error("review receipt schema drift")
    R_RECOMPUTER_BASENAME=="v07_genomic_recovery_v3_recompute.R"&&R_RECOMPUTER_BASENAME!="v07_genomic_recovery_v3_preseal.R"||error("operational R recomputer binding drift")
    R_D0_RECOMPUTER_BASENAME=="v07_genomic_recovery_v3_d0_recompute.R"||error("R D0 recomputer binding drift")
    _host_matches("totoro";hostname="totoro.biology.ualberta.ca",cluster="")&&_host_matches("fir";hostname="compute-node",cluster="fir")&&_host_matches("fir";hostname="fir.alliancecan.ca",cluster="")&&!_host_matches("totoro";hostname="laptop",cluster="")&&!_host_matches("fir";hostname="notfir-laptop",cluster="notfir")||error("live host binding selftest")
    _assert_execution_context(hostname="totoro",cluster="",job_id="",github_actions="false",ci="false")
    _assert_execution_context(hostname="cn001",cluster="fir",job_id="123456",github_actions="false",ci="false")
    _must_fail("DRAC login-node execution") do;_assert_execution_context(hostname="login1",cluster="fir",job_id="",github_actions="false",ci="false");end
    _must_fail("malformed SLURM allocation") do;_assert_execution_context(hostname="cn001",cluster="fir",job_id="interactive",github_actions="false",ci="false");end
    _must_fail("GitHub Actions execution") do;_assert_execution_context(hostname="totoro",cluster="",job_id="",github_actions="true",ci="false");end
    _must_fail("generic CI execution") do;_assert_execution_context(hostname="totoro",cluster="",job_id="",github_actions="false",ci="TRUE");end
    BLAS.get_num_threads()==1||error("selftest requires one live BLAS thread")
    allunique(_attempt_columns("d0f"))&&allunique(_attempt_columns("d1"))&&allunique(_replay_columns("d0f"))&&allunique(_replay_columns("d1"))&&allunique(_truth_columns("d0f"))&&allunique(_truth_columns("d1"))||error("ordered schema duplicates")
    length(D0F_BOOTSTRAP_COLUMNS)==13||error("24x8 D0F bootstrap schema drift")
    D0F_PHENOTYPE_SEED_BASE==2_036_000_000||error("fresh D0F phenotype seed-base drift")
    d0f=NamedTuple[]
    for d in D0F_DESIGNS,panel in 1:24,rep in 1:8
        source=2_027_120_000+10_000*d.source_index+7100+panel;seed=D0F_PHENOTYPE_SEED_BASE+100_000*d.index+1000panel+rep
        hashes=(marker_hash=bytes2hex(sha256("marker-$(d.index)-$panel")),id_hash=bytes2hex(sha256("ids-$(d.index)-$panel")),kernel_hash=bytes2hex(sha256("kernel-$(d.index)-$panel")),precision_hash=bytes2hex(sha256("precision-$(d.index)-$panel")))
        push!(d0f,(stage="d0f",design_id=d.id,design_index=d.index,panel_id=@sprintf("%s_p%02d",d.id,panel),panel_rank=panel,source_cell_id=d.source_cell,panel_source_seed=source,phenotype_rank=rep,seed=seed,n=d.n,m=d.m,marker_ratio=d.marker_ratio,retained_m=d.m,truth_sigma_g2=.5,truth_sigma_e2=.5,truth_ratio=.5,ridge=RIDGE,hashes...))
    end
    _validate_manifest(d0f,"d0f")
    _must_fail("D0F seed") do;x=copy(d0f);x[1]=merge(x[1],(seed=x[1].seed+1,));_validate_manifest(x,"d0f");end
    _must_fail("D0F source panel") do;x=copy(d0f);x[1]=merge(x[1],(panel_source_seed=x[1].panel_source_seed+1,));_validate_manifest(x,"d0f");end
    _must_fail("D0F duplicate/missing phenotype rank") do;x=copy(d0f);x[2]=merge(x[2],(phenotype_rank=1,));_validate_manifest(x,"d0f");end
    _must_fail("D0F non-rank1 repeated-panel hash") do;x=copy(d0f);x[8]=merge(x[8],(kernel_hash=repeat("0",64),));_validate_manifest(x,"d0f");end
    _must_fail("D0F ridge") do;x=copy(d0f);x[1]=merge(x[1],(ridge=.02,));_validate_manifest(x,"d0f");end
    d0f_fixed=[begin
        row=only(filter(r->r.design_index==d.index&&r.panel_rank==panel&&r.phenotype_rank==1,d0f))
        NamedTuple{Tuple(Symbol.(D0F_FIXED_COLUMNS))}(Tuple(getproperty(row,Symbol(c)) for c in D0F_FIXED_COLUMNS))
    end for d in D0F_DESIGNS for panel in 1:24]
    d1=NamedTuple[];for c in _d1_cells(),off in 101:148;push!(d1,(stage="d1",cell_id=c.cell_id,cell_index=c.cell_index,seed_offset=off,seed=2_028_000_000+10_000*c.cell_index+off,n=c.n,m=c.m,marker_ratio=c.marker_ratio,marker_ratio_code=c.marker_ratio_code,truth_sigma_g2=.5,truth_sigma_e2=.5,truth_ratio=.5,ridge=RIDGE));end;_validate_manifest(d1,"d1")
    _must_fail("D1 seed") do;x=copy(d1);x[1]=merge(x[1],(seed=x[1].seed+1,));_validate_manifest(x,"d1");end
    _must_fail("D1 stage") do;x=copy(d1);x[1]=merge(x[1],(stage="d2",));_validate_manifest(x,"d1");end
    _must_fail("D1 cell") do;x=copy(d1);x[1]=merge(x[1],(cell_id="mutated",));_validate_manifest(x,"d1");end
    _must_fail("D1 ridge") do;x=copy(d1);x[1]=merge(x[1],(ridge=.02,));_validate_manifest(x,"d1");end
    partitions=[_batch_partition(d1,i,7) for i in 1:7]
    ranks=reduce(vcat,[[x.rank for x in part] for part in partitions]);sort(ranks)==collect(1:length(d1))&&allunique(ranks)||error("batch partitions are not an exact disjoint manifest union")
    reversed_ranks=reduce(vcat,[[x.rank for x in part] for part in reverse(partitions)]);sort(reversed_ranks)==sort(ranks)||error("reversed batch order changed scientific membership")
    canonical_science=Dict(i=>(_group(d1[i],"d1"),d1[i].seed,d1[i].truth_ratio) for i in ranks)
    reversed_science=Dict(i=>(_group(d1[i],"d1"),d1[i].seed,d1[i].truth_ratio) for i in reversed_ranks)
    canonical_science==reversed_science||error("batch execution order changed scientific inputs")
    _must_fail("batch count over worker cap") do;_batch_partition(d1,1,97);end
    _must_fail("zero batch count") do;_batch_partition(d1,1,0);end
    _must_fail("unknown batch index") do;_batch_partition(d1,0,7);end
    d0f_parity=NamedTuple[]
    phenotype_effect=collect(range(-.015,.015;length=8));panel_effect=collect(range(-.01,.01;length=24))
    for mr in d0f
        estimate=.5+phenotype_effect[mr.phenotype_rank]+panel_effect[mr.panel_rank]
        push!(d0f_parity,(manifest=mr,converged=true,boundary_status="interior",error_class="none",scientific_ratio=estimate,runtime_seconds=.1,peak_rss_mb=100.0))
    end
    d0f_bootstrap_text=_canonical_r_d0f_parity_text("bootstrap");d0f_bootstrap=TSV(D0F_BOOTSTRAP_COLUMNS,_parse_tsv_text(d0f_bootstrap_text,D0F_BOOTSTRAP_COLUMNS))
    d0f_summary=_d0f_summary_impl(d0f_parity,d0f_bootstrap,D0F_PARITY_BOOTSTRAP_SHA256,5);length(D0F_SUMMARY_COLUMNS)==38||error("D0F summary width drift");_verify_full_r_d0f_parity(d0f_summary)
    _must_fail("D0F full typed R parity mutation") do;x=copy(d0f_summary);x[1]=merge(x[1],(variance_between=x[1].variance_between+1e-4,));_verify_full_r_d0f_parity(x);end
    C=D0Support._helmert(8);M=[Float64(mod(i+j,3)) for i in 1:8,j in 1:12];ids=[@sprintf("g%06d",i) for i in 1:8];p=vec(sum(M,dims=1))./16;W=M.-2 .* transpose(p);k=2sum(p.*(1 .- p));K=(W*transpose(W))./k+RIDGE*I;Q=Matrix(inv(Symmetric(K)));s=D0Support._spectral(Matrix(K),C)
    packet=(M=M,ids=ids,names=[@sprintf("m%06d",j) for j in 1:12],y=[-1.2,.2,.8,-.4,1.1,-.7,.5,-.3],k=k,K=Matrix(K),Q=Q,retained_m=12,marker_hash=D0Support._marker_hash(M,ids,[@sprintf("m%06d",j) for j in 1:12]),id_hash=D0Support._id_hash(ids),kernel_hash=D0Support._matrix_hash("K_lambda",K,ids),precision_hash=D0Support._matrix_hash("Q_lambda",Q,ids),spectrum=s)
    d0row=merge(d0f[1],(retained_m=packet.retained_m,marker_hash=packet.marker_hash,id_hash=packet.id_hash,kernel_hash=packet.kernel_hash,precision_hash=packet.precision_hash))
    diagnostic=Dict("cell_id"=>d0row.source_cell_id,"cell_index"=>"2","seed"=>string(d0row.panel_source_seed),"n"=>string(d0row.n),"m"=>string(d0row.m),"truth_ratio"=>_format(d0row.truth_ratio),"retained_m"=>string(d0row.retained_m),"ridge"=>_format(d0row.ridge),"marker_hash"=>d0row.marker_hash,"id_hash"=>d0row.id_hash,"kernel_hash"=>d0row.kernel_hash,"precision_hash"=>d0row.precision_hash)
    _validate_d0f_diagnostic_row(diagnostic,d0row,packet);_must_fail("D0F frozen diagnostic packet hash") do;x=copy(diagnostic);x["precision_hash"]=repeat("0",64);_validate_d0f_diagnostic_row(x,d0row,packet);end
    replay=_profile_replay(d1[1],packet);replay.route==REPLAY_ROUTE&&replay.relationship_method=="vanraden1"||error("profile replay selftest")
    parity=NamedTuple[]
    for mr in d1
        rep=mr.seed_offset-100;dev=(rep-24.5)*1e-4;boundary=rep==1 ? "boundary_lower" : rep==2 ? "boundary_upper" : rep==3 ? "interior_rescued" : "interior";ratio=rep==1 ? 0.0 : rep==2 ? 1.0 : .5+dev
        push!(parity,(manifest=mr,attempted=true,converged=true,status="success",error_class="none",boundary_status=boundary,scientific_sigma_g2=ratio,scientific_sigma_e2=1-ratio,scientific_ratio=ratio,fitted_total_variance=1.0,runtime_seconds=Float64(rep),peak_rss_mb=100.0+rep,se_info_r050=.1,eigen_cv_population=.5,effective_rank=50.0))
    end
    function performance_rows(source_shift,replay_shift)
        [begin
            source=(dict=Dict("runtime_seconds"=>_format(x.runtime_seconds+source_shift),"peak_rss_mb"=>_format(x.peak_rss_mb+source_shift)),)
            perf=_summary_performance(source,x.runtime_seconds+replay_shift,x.peak_rss_mb+replay_shift)
            merge(x,perf)
        end for x in parity]
    end
    performance_baseline=performance_rows(0.0,1000.0);performance_replay_mutation=performance_rows(0.0,2000.0);performance_source_mutation=performance_rows(1.0,1000.0)
    _table_text(D1_SUMMARY_COLUMNS,_d1_summary(performance_baseline))==_table_text(D1_SUMMARY_COLUMNS,_d1_summary(performance_replay_mutation))||error("replay performance leaked into scientific summary")
    _table_text(D1_SUMMARY_COLUMNS,_d1_summary(performance_baseline))!=_table_text(D1_SUMMARY_COLUMNS,_d1_summary(performance_source_mutation))||error("source R performance mutation did not change scientific summary")
    ps=_d1_summary(parity);req=maximum(x.required_n_raw for x in ps[1:3]);length(ps)==36&&all(x->x.required_n==max(200,req)&&x.cell_status=="ELIGIBLE"&&x.failure_classes=="none=48",ps)||error("D1 summary parity fixture decision drift")
    firstps=ps[1];firstps.n_interior==45&&firstps.n_interior_rescued==1&&firstps.n_boundary_lower==1&&firstps.n_boundary_upper==1&&firstps.n_unresolved==0&&firstps.n_error==0&&firstps.median_runtime_seconds==24.5||error("D1 summary parity fixture count/runtime drift")
    firstps.observed_boundary_lower==1/48&&firstps.observed_boundary_upper==1/48&&abs(firstps.mcse_boundary_lower-sqrt((1/48)*(47/48)/48))<1e-15||error("D1 boundary summary parity drift")
    # Independent base-R fixture (36 x 56 TSV; SHA-256
    # 945ab4576b534420688190f6649d83cc476d3dfb0e4b6e56b35af1b1d5cb8087).
    # These anchors make the synthetic cross-language decision gate executable
    # without requiring R during the Julia selftest.
    sg,se,ratio=ps[1:3]
    (sg.target,se.target,ratio.target)==("sigma_g2","sigma_e2","ratio")||error("D1 summary target order differs from base R")
    anchors=((sg.mean_estimate,0.50009583333333330),(se.mean_estimate,0.49990416666666665),(sg.bias,9.5833333333335328e-05),(se.bias,-9.5833333333335328e-05),(sg.mcse,0.014888490577275508),(se.mcse,0.014888490577275513),(sg.bias_ci_lower,-0.029855946349255667),(sg.bias_ci_upper,0.030047613015922341),(se.bias_ci_lower,-0.030047613015922351),(se.bias_ci_upper,0.029855946349255678),(sg.rmse,0.10207039390783204),(sg.mcse_rmse,0.035695288022528769),(sg.empirical_sd,0.10315048851140665),(se.empirical_sd,0.10315048851140668),(sg.pilot_sd_upper,0.12449065181588032),(se.pilot_sd_upper,0.12449065181588034),(sg.predicted_boundary_lower,2.8665157187919391e-07),(sg.predicted_boundary_upper,2.8665157192353519e-07),(sg.mcse_boundary_lower,0.020615177234440826))
    all(abs(actual-expected)<=1e-10 for (actual,expected) in anchors)||error("D1 Julia summary differs from independent base-R fixture")
    (sg.required_n_raw,se.required_n_raw,ratio.required_n_raw)==(382,382,596)&&all(x->x.required_n==596,(sg,se,ratio))||error("D1 Julia sizing decision differs from independent base R")
    length(D1_SUMMARY_COLUMNS)==56||error("D1 summary width drift")
    _verify_full_r_parity(ps)
    all(x->x.required_n_raw isa Integer,ps)||error("D1 target required_n_raw is not an integer ceiling")
    for successes in (0,1)
        low=copy(parity)
        for i in (successes+1):48
            low[i]=merge(low[i],(converged=false,status="fit_error",error_class="synthetic_low_convergence",boundary_status="NA",scientific_sigma_g2=NaN,scientific_sigma_e2=NaN,scientific_ratio=NaN,fitted_total_variance=NaN))
        end
        low_summary=_d1_summary(low)[1:3]
        all(x->x.low_convergence&&x.summary_nonfinite&&!x.precision_blocked&&!x.futility_stopped&&!x.cell_eligible&&x.cell_status=="STOP_LOW_PILOT_CONVERGENCE"&&isinf(x.required_n),low_summary)||error("D1 $successes-success low-convergence semantics drift")
    end
    _must_fail("zero SE_info summary") do;x=copy(parity);for i in 1:48;x[i]=merge(x[i],(se_info_r050=0.0,));end;_d1_summary(x);end
    _must_fail("nonfinite SE_info/predicted boundary") do;x=copy(parity);x[1]=merge(x[1],(se_info_r050=NaN,));_d1_summary(x);end
    _bool("true","x")&&!_bool("false","x")||error("Boolean selftest");_must_fail("logical TRUE") do;_bool("TRUE","x");end
    _must_fail("fingerprint mutation") do;packet.marker_hash==repeat("0",64)||error("fingerprint");end
    failfields=split("scientific_sigma_g2 scientific_sigma_e2 scientific_ratio fitted_total_variance numerical_sigma_g2 numerical_sigma_e2 numerical_ratio iterations objective gradient_norm");unresolved=Dict(f=>"NA" for f in failfields);merge!(unresolved,Dict("status"=>"fit_error","boundary_status"=>"boundary_unresolved","boundary_reason"=>"profile_flat","boundary_epsilon"=>"9.9999999999999995e-08","profile_loglik"=>"-12","lower_derivative_per_observation"=>"0","upper_derivative_per_observation"=>"0"));_validate_unsuccessful(unresolved)
    ordinary=copy(unresolved);for f in ("boundary_status","boundary_reason","boundary_epsilon","profile_loglik","lower_derivative_per_observation","upper_derivative_per_observation");ordinary[f]="NA";end;_validate_unsuccessful(ordinary)
    _must_fail("partial unresolved evidence") do;x=copy(unresolved);x["profile_loglik"]="NA";_validate_unsuccessful(x);end
    malformed_generated=merge(replay,(status="fit_error",error_class="synthetic_failure",converged=false))
    _must_fail("generated replay failure retains successful fields") do;_validate_generated_replay(malformed_generated);end
    generated_failure=merge(replay,(status="fit_error",error_class="profile_flat",converged=false,boundary_status="boundary_unresolved",boundary_reason="profile_flat",boundary_epsilon=BOUNDARY_EPSILON,scientific_sigma_g2=NaN,scientific_sigma_e2=NaN,scientific_ratio=NaN,fitted_total_variance=NaN,numerical_sigma_g2=NaN,numerical_sigma_e2=NaN,numerical_ratio=NaN,profile_loglik=-12.0,lower_derivative_per_observation=0.0,upper_derivative_per_observation=0.0,iterations=NaN,objective=NaN,gradient_norm=NaN))
    _validate_generated_replay(generated_failure);source_failure=(dict=Dict(string(k)=>_format(v) for (k,v) in pairs(generated_failure)),good=false)
    _source_difference(source_failure,generated_failure)==0||error("identical unresolved evidence differs")
    _source_difference(source_failure,merge(generated_failure,(profile_loglik=-11.0,)))>0||error("unresolved profile evidence was not compared")
    h=repeat("a",64);binding=Dict("source_r_attempt_sha256"=>h,"replay_julia_commit"=>repeat("b",40),"replay_driver_sha256"=>h,"manifest_sha256"=>h,"preseal_sha256"=>h,"corpus_lock_sha256"=>h);_validate_replay_bindings(binding;source_sha=h,replay_commit=repeat("b",40),replay_sha=h,manifest_sha=h,preseal_sha=h,corpus_sha=h)
    _must_fail("forged replay binding") do;x=copy(binding);x["source_r_attempt_sha256"]=repeat("0",64);_validate_replay_bindings(x;source_sha=h,replay_commit=repeat("b",40),replay_sha=h,manifest_sha=h,preseal_sha=h,corpus_sha=h);end
    dir=mktempdir();try
        root=realpath(dir);p=joinpath(root,"x.tsv");_write_once(p,"x\n");_verify_pair(root,p);_must_fail("create once") do;_write_once(p,"x\n");end
        open(p,"w") do io;write(io,"mutated\n");end;_must_fail("checksum") do;_verify_pair(root,p);end;rm(p;force=true);rm(p*".sha256";force=true)
        fixed=joinpath(root,"d0f_fixed_panel_manifest.tsv");_write_once(fixed,_table_text(D0F_FIXED_COLUMNS,d0f_fixed));_validate_fixed_panels(root,fixed,d0f)
        bad_fixed=copy(d0f_fixed);bad_fixed[1]=merge(bad_fixed[1],(precision_hash=repeat("0",64),));bad_fixed_path=joinpath(root,"d0f_fixed_panel_manifest_bad.tsv");_write_once(bad_fixed_path,_table_text(D0F_FIXED_COLUMNS,bad_fixed));_must_fail("D0F fixed-panel hash") do;_validate_fixed_panels(root,bad_fixed_path,d0f);end
        bad_ranks=copy(d0f);bad_ranks[2]=merge(bad_ranks[2],(phenotype_rank=1,));_must_fail("D0F fixed validator duplicate/missing phenotype rank") do;_validate_fixed_panels(root,fixed,bad_ranks);end
        bad_nonrank1=copy(d0f);bad_nonrank1[8]=merge(bad_nonrank1[8],(precision_hash=repeat("0",64),));_must_fail("D0F fixed validator non-rank1 identity") do;_validate_fixed_panels(root,fixed,bad_nonrank1);end
        tree=joinpath(root,"tree");mkdir(tree);_write_once(joinpath(tree,"a.tsv"),"a\n");_exact_tree(root,tree,["a.tsv","a.tsv.sha256"])
        _write_once(joinpath(tree,"extra.tsv"),"extra\n");_must_fail("extra exact-tree member") do;_exact_tree(root,tree,["a.tsv","a.tsv.sha256"]);end
        sy=joinpath(root,"sy.tsv");open(sy,"w") do io;write(io,"sy\n");end;side_target=joinpath(root,"side.txt");open(side_target,"w") do io;print(io,"$(_sha256(sy))  sy.tsv\n");end;symlink(side_target,sy*".sha256")
        _must_fail("symlinked sidecar") do;_verify_pair(root,sy);end
        function synthetic_d0f_predecessor(name;decision="COMPLETE",verdict="PASS")
            pred=joinpath(root,name);mkdir(pred);values=Dict(c=>repeat("a",64) for c in D0F_ADJUDICATION_COLUMNS)
            values["schema_version"]=D0F_ADJUDICATION_SCHEMA;values["stage"]="d0f";values["verdict"]=verdict;values["stage_decision"]=decision
            values["attempt_max_diff"]="0";values["summary_max_diff"]="0"
            for field in filter(x->endswith(x,"_commit"),D0F_ADJUDICATION_COLUMNS);values[field]=repeat("b",40);end
            for reviewer in REVIEWERS;values["$(reviewer)_review_path"]=joinpath("postrun_receipts","$reviewer.tsv");end
            row=NamedTuple{Tuple(Symbol.(D0F_ADJUDICATION_COLUMNS))}(Tuple(values[c] for c in D0F_ADJUDICATION_COLUMNS))
            path=joinpath(pred,"stage_adjudication_receipt.tsv");_write_once(path,_table_text(D0F_ADJUDICATION_COLUMNS,[row]));(root=pred,sha=_sha256(path))
        end
        d1stage=joinpath(root,"d1-stage");mkdir(d1stage);valid_pred=synthetic_d0f_predecessor("d0f-predecessor")
        _validate_d0f_predecessor(d1stage,Dict("d0f_adjudication_root"=>valid_pred.root,"d0f_adjudication_receipt_sha256"=>valid_pred.sha))
        r_recomputer=joinpath(rroot,"tools",R_RECOMPUTER_BASENAME)
        _must_fail("forged receipt-only D0F predecessor") do;_validate_d0f_final_tree(r_recomputer,valid_pred.root);end
        failed_pred=synthetic_d0f_predecessor("d0f-failed";decision="D0F_FIT_BLOCKER")
        _must_fail("non-COMPLETE D0F predecessor") do;_validate_d0f_predecessor(d1stage,Dict("d0f_adjudication_root"=>failed_pred.root,"d0f_adjudication_receipt_sha256"=>failed_pred.sha));end
        _must_fail("wrong D0F predecessor hash") do;_validate_d0f_predecessor(d1stage,Dict("d0f_adjudication_root"=>valid_pred.root,"d0f_adjudication_receipt_sha256"=>repeat("0",64)));end
        nested_stage=joinpath(valid_pred.root,"nested-d1");mkdir(nested_stage)
        _must_fail("nested D0F/D1 roots") do;_validate_d0f_predecessor(nested_stage,Dict("d0f_adjudication_root"=>valid_pred.root,"d0f_adjudication_receipt_sha256"=>valid_pred.sha));end
        stage_root=joinpath(root,"stage");mkdir(stage_root);mkdir(joinpath(stage_root,"receipts"))
        for name in ("doc49.md","cell_table.tsv","historical_seed_lock.tsv","d1_manifest.tsv","environment_manifest.tsv","stage_preseal.tsv");_write_once(joinpath(stage_root,name),"x\n");end
        for reviewer in REVIEWERS;_write_once(joinpath(stage_root,"receipts","$reviewer.tsv"),"x\n");end
        _validate_preseal_only_tree(stage_root,"d1")
        for name in ("attempts","packets","base_r_recompute","julia_replay")
            path=joinpath(stage_root,name);mkdir(path);_write_once(joinpath(path,"unexpected.tsv"),"x\n")
            _must_fail("preflight rejects $name subtree") do;_validate_preseal_only_tree(stage_root,"d1");end
            rm(path;recursive=true)
        end
        for name in ("d1_summary_r.tsv","d1_summary_julia.tsv","stage_corpus_lock.tsv","stage_adjudication_receipt.tsv")
            _write_once(joinpath(stage_root,name),"x\n")
            _must_fail("preflight rejects $name") do;_validate_preseal_only_tree(stage_root,"d1");end
            rm(joinpath(stage_root,name));rm(joinpath(stage_root,name*".sha256"))
        end
        for name in ("attempts","packets","julia_replay");dirpath=joinpath(stage_root,name);mkdir(dirpath);_write_once(joinpath(dirpath,"member.tsv"),"x\n");end
        _write_once(joinpath(stage_root,"stage_corpus_lock.tsv"),"x\n");_validate_preseal_tree(stage_root,"d1";postrun=true,replay=true)
        _must_fail("final summary without base-R tree") do;_validate_preseal_tree(stage_root,"d1";postrun=true,replay=true,summary=true);end
        _write_once(joinpath(stage_root,"d1_summary_r.tsv"),"x\n");_must_fail("R summary without base-R subtree") do;_validate_preseal_tree(stage_root,"d1";postrun=true,replay=true);end
        base_r=joinpath(stage_root,"base_r_recompute");mkdir(base_r);_write_once(joinpath(base_r,"member.tsv"),"x\n");_write_once(joinpath(stage_root,"d1_summary_julia.tsv"),"x\n")
        _validate_preseal_tree(stage_root,"d1";postrun=true,replay=true,summary=true);_must_fail("final admission remains R-owned") do;_validate_preseal_tree(stage_root,"d1";postrun=true,replay=true,summary=true,final=true);end
        _write_once(joinpath(stage_root,"stage_adjudication_receipt.tsv"),"x\n");_must_fail("arbitrary adjudication receipt") do;_validate_preseal_tree(stage_root,"d1";postrun=true,replay=true,summary=true,final=true);end
        operational=joinpath(root,"operational");mkdir(operational);oprow=d1[1];op_preseal=joinpath(operational,"stage_preseal.tsv");op_manifest=joinpath(operational,"d1_manifest.tsv");_write_once(op_preseal,"preseal\n");_write_once(op_manifest,"manifest\n")
        op_attempt=_attempt_path(operational,"d1",oprow);_write_once(op_attempt,"attempt\n");op_packet=_packet_dir(operational,"d1",oprow)
        for name in PACKET_PRIMARIES;_write_once(joinpath(op_packet,name),"$name\n");end
        locked=vcat([op_preseal,op_manifest,op_attempt],joinpath.(Ref(op_packet),PACKET_PRIMARIES));lock_rows=sort([(relative_path=relpath(path,operational),sha256=_sha256(path)) for path in locked];by=x->x.relative_path);_write_once(joinpath(operational,"stage_corpus_lock.tsv"),_table_text(CORPUS_COLUMNS,lock_rows));_corpus_lock(operational,"d1",[oprow],op_preseal)
        open(joinpath(op_packet,"markers.tsv"),"w") do io;write(io,"mutated packet\n");end;_must_fail("operational corpus packet mutation") do;_corpus_lock(operational,"d1",[oprow],op_preseal);end
        locked=joinpath(root,"locked-row");mkdir(locked);lockrow=d1[1]
        locked_paths=[_attempt_path(locked,"d1",lockrow);joinpath.(_packet_dir(locked,"d1",lockrow),PACKET_PRIMARIES)]
        for path in locked_paths;_write_once(path,"$(basename(path))\n");end
        locked_map=Dict(relpath(path,locked)=>_sha256(path) for path in locked_paths);_verify_locked_seed_inputs(locked,"d1",lockrow,locked_map)
        mutated=joinpath(_packet_dir(locked,"d1",lockrow),"markers.tsv");write(mutated,"post-preparation mutation\n");write(mutated*".sha256","$(_sha256(mutated))  $(basename(mutated))\n")
        _must_fail("post-preparation primary plus regenerated sidecar") do;_verify_locked_seed_inputs(locked,"d1",lockrow,locked_map);end

        batch_evidence=joinpath(root,"batch-evidence");mkdir(batch_evidence);batch_external=joinpath(root,"batch-external");mkdir(batch_external)
        mh=repeat("a",64);ph=repeat("b",64);ch=repeat("c",64);batch_count=7;batch_index=3
        valid_batch_rows=_batch_rows("d1",d1,batch_index,batch_count;manifest_sha=mh,preseal_sha=ph,corpus_sha=ch)
        valid_batch=joinpath(batch_external,_batch_basename("d1",batch_index,batch_count));_write_once(valid_batch,_table_text(BATCH_COLUMNS,valid_batch_rows))
        parsed_batch=_read_batch_manifest(batch_evidence,valid_batch,"d1",d1;manifest_sha=mh,preseal_sha=ph,corpus_sha=ch)
        parsed_batch.rows==[x.row for x in _batch_partition(d1,batch_index,batch_count)]||error("valid batch parse changed canonical members")
        function malformed_batch(name,rows)
            dir=joinpath(root,name);mkdir(dir);path=joinpath(dir,_batch_basename("d1",batch_index,batch_count));_write_once(path,_table_text(BATCH_COLUMNS,rows));path
        end
        duplicate_rows=copy(valid_batch_rows);duplicate_rows[2]=duplicate_rows[1]
        _must_fail("duplicate batch member before writes") do;_read_batch_manifest(batch_evidence,malformed_batch("batch-duplicate",duplicate_rows),"d1",d1;manifest_sha=mh,preseal_sha=ph,corpus_sha=ch);end
        unknown_rows=copy(valid_batch_rows);unknown_rows[1]=merge(unknown_rows[1],(group_id="unknown",))
        _must_fail("unknown batch member before writes") do;_read_batch_manifest(batch_evidence,malformed_batch("batch-unknown",unknown_rows),"d1",d1;manifest_sha=mh,preseal_sha=ph,corpus_sha=ch);end
        _must_fail("reversed batch order before writes") do;_read_batch_manifest(batch_evidence,malformed_batch("batch-reversed",reverse(valid_batch_rows)),"d1",d1;manifest_sha=mh,preseal_sha=ph,corpus_sha=ch);end
        inside=joinpath(batch_evidence,_batch_basename("d1",batch_index,batch_count));_write_once(inside,_table_text(BATCH_COLUMNS,valid_batch_rows))
        _must_fail("batch manifest inside evidence root") do;_read_batch_manifest(batch_evidence,inside,"d1",d1;manifest_sha=mh,preseal_sha=ph,corpus_sha=ch);end

        targets=joinpath(root,"batch-targets");mkdir(targets);target_rows=d1[1:2];h=repeat("a",64)
        target_replay=merge(_manifest_values(target_rows[1],"d1"),replay,(r_implementation_commit=repeat("b",40),julia_implementation_commit=repeat("c",40),driver_commit=repeat("d",40),preseal_sha256=h,
            source_r_attempt_sha256=h,source_r_max_abs_difference=0.0,replay_julia_commit=repeat("d",40),replay_driver_sha256=h,manifest_sha256=h,corpus_lock_sha256=h))
        _write_once(_replay_path(targets,"d1",target_rows[1]),_table_text(_replay_columns("d1"),[target_replay]))
        _batch_target_prefix(targets,"d1",target_rows;resume_complete_prefix=true)==1||error("complete replay prefix is not resumable")
        _must_fail("existing target before writes") do;_batch_target_prefix(targets,"d1",target_rows;resume_complete_prefix=false);end
        partial=_replay_path(targets,"d1",target_rows[2]);mkpath(dirname(partial));write(partial,"partial\n")
        _must_fail("partial replay pair before writes") do;_batch_target_prefix(targets,"d1",target_rows;resume_complete_prefix=true);end
        quiescent=joinpath(root,"quiescent-replay");mkdir(quiescent);quiescent_rows=d1[1:2];for row in quiescent_rows;_write_once(_replay_path(quiescent,"d1",row),"replay\n");end
        own_pair=_replay_path(quiescent,"d1",quiescent_rows[1]);inflight=joinpath(quiescent,"julia_replay","d1","other-worker");mkdir(inflight);write(joinpath(inflight,"primary-without-sidecar.tsv"),"in flight\n");_verify_pair(quiescent,own_pair)
        _must_fail("quiescent in-flight replay window") do;_verify_replay_tree_quiescent(quiescent,"d1",quiescent_rows);end;rm(inflight;recursive=true)
        _verify_replay_tree_quiescent(quiescent,"d1",quiescent_rows)
        unexpected=joinpath(quiescent,"julia_replay","unexpected.tsv");_write_once(unexpected,"unexpected\n");_must_fail("quiescent unexpected replay member") do;_verify_replay_tree_quiescent(quiescent,"d1",quiescent_rows);end;rm(unexpected);rm(unexpected*".sha256")
        empty=joinpath(quiescent,"julia_replay","empty");mkdir(empty);_must_fail("quiescent empty replay directory") do;_verify_replay_tree_quiescent(quiescent,"d1",quiescent_rows);end
        repo=joinpath(root,"repo");mkdir(repo);run(Cmd(String["git","-C",repo,"init","--quiet"]));run(Cmd(String["git","-C",repo,"config","user.email","synthetic@example.invalid"]));run(Cmd(String["git","-C",repo,"config","user.name","synthetic"]));mkdir(joinpath(repo,"src"));mkdir(joinpath(repo,"ext"));mkdir(joinpath(repo,"R"));engine=joinpath(repo,"src","engine.jl");write(engine,"engine v1\n");write(joinpath(repo,"ext","extension.jl"),"extension v1\n");write(joinpath(repo,"R","surface.R"),"surface v1\n");write(joinpath(repo,"Project.toml"),"name = \"Synthetic\"\n");write(joinpath(repo,"Manifest.toml"),"manifest_format = \"2.0\"\n");write(joinpath(repo,"DESCRIPTION"),"Package: synthetic\n");write(joinpath(repo,"NAMESPACE"),"exportPattern(\"^[^.]\")\n");tool=joinpath(repo,"replay.jl");_write_once(tool,"replay v1\n");run(Cmd(String["git","-C",repo,"add","src","ext","R","Project.toml","Manifest.toml","DESCRIPTION","NAMESPACE","replay.jl","replay.jl.sha256"]));run(Cmd(String["git","-C",repo,"commit","--quiet","-m","candidate"]));candidate=_git(repo,"rev-parse","HEAD")
        note=joinpath(repo,"replay-note.txt");write(note,"replay layer\n");run(Cmd(String["git","-C",repo,"add","replay-note.txt"]));run(Cmd(String["git","-C",repo,"commit","--quiet","-m","replay"]));replay_commit=_git(repo,"rev-parse","HEAD");tool_hash=_sha256(tool)
        candidate isa String&&replay_commit isa String||error("git helper must return a concrete String")
        substring_root=SubString(repo,firstindex(repo),lastindex(repo));_git_blob_sha256(substring_root,tool,replay_commit)==tool_hash||error("SubString git root regression")
        _require_ancestor(repo,candidate,replay_commit,"synthetic candidate");_must_fail("reversed candidate ancestry") do;_require_ancestor(repo,replay_commit,candidate,"synthetic candidate");end
        _verify_bound_tool(repo,tool,replay_commit,tool_hash,"synthetic replay tool");_require_git_unchanged(repo,candidate,replay_commit,[engine],"synthetic engine")
        unrelated=joinpath(repo,"unrelated.tmp");write(unrelated,"untracked\n");_must_fail("untracked unrelated repository file") do;_require_git_clean(repo,"synthetic repository");end;rm(unrelated)
        side=tool*".sha256";side_text=read(side,String);rm(side);_must_fail("bound tool missing sidecar") do;_verify_bound_tool(repo,tool,replay_commit,tool_hash,"synthetic replay tool");end;write(side,side_text)
        rm(joinpath(repo,"R","surface.R"));run(Cmd(String["git","-C",repo,"add","-u","R"]));run(Cmd(String["git","-C",repo,"commit","--quiet","-m","delete R surface"]));r_deleted=_git(repo,"rev-parse","HEAD")
        _must_fail("deleted R implementation surface") do;_require_git_unchanged(repo,candidate,r_deleted,joinpath.(Ref(repo),["R","DESCRIPTION","NAMESPACE"]),"synthetic R implementation");end
        rm(joinpath(repo,"ext","extension.jl"));run(Cmd(String["git","-C",repo,"add","-u","ext"]));run(Cmd(String["git","-C",repo,"commit","--quiet","-m","delete Julia surface"]));julia_deleted=_git(repo,"rev-parse","HEAD")
        _must_fail("deleted Julia implementation surface") do;_require_git_unchanged(repo,replay_commit,julia_deleted,joinpath.(Ref(repo),["src","ext","Project.toml","Manifest.toml"]),"synthetic Julia implementation");end
        write(engine,"dirty engine\n");_must_fail("dirty bound implementation") do;_require_git_clean(repo,"synthetic engine");end
    finally rm(dir;recursive=true,force=true);end
    abs(_tquantile(.975,47)-2.0117405137297655)<1e-12&&abs(_chisq_quantile(.05,47)-32.2676215299732)<1e-10||error("distribution selftest")
    println("v0.7 genomic recovery-v3 D0F/D1 Julia stage replay selftest: PASS (synthetic only; no official RNG or seed consumed)")
end

function main(args=ARGS)
    mode=_option(args,"mode";default="replay");mode=="selftest"&&return selftest()
    mode=="batch-selftest"&&return batch_selftest()
    _assert_execution_context()
    stage=lowercase(_required(args,"stage"));stage in ("d0f","d1")||error("--stage must be d0f or d1")
    root=_required(args,"out-dir")
    if mode=="preflight"
        preflight(root,stage)
    elseif mode=="write-batch-manifests"
        batch_dir=_required(args,"batch-dir");batch_count=parse(Int,_required(args,"batch-count"))
        _write_batch_manifests(root,stage,batch_dir,batch_count)
    elseif mode=="replay-batch"
        batch_manifest=_required(args,"batch-manifest")
        resume=_bool(_option(args,"resume-complete-prefix";default="true"),"resume-complete-prefix")
        replay_batch(root,stage,batch_manifest;resume_complete_prefix=resume)
    elseif mode=="replay"
        group=_required(args,stage=="d0f" ? "design" : "cell");seed=parse(Int,_required(args,"seed"))
        replay_one(root,stage,group,seed)
    elseif mode=="verify-replay"
        verify_replay(root,stage)
    elseif mode=="summarize"
        summarize(root,stage;bootstrap=_option(args,"bootstrap-indices"))
    elseif mode=="validate-final"
        validate_final(root,stage)
    else
        error("--mode must be preflight, write-batch-manifests, replay-batch, replay, verify-replay, summarize, validate-final, or selftest")
    end
end

abspath(PROGRAM_FILE)==abspath(@__FILE__)&&main()
