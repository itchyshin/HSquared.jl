using HSquared, SparseArrays, LinearAlgebra, DelimitedFiles, Printf
S = ENV["AUDIT_DIR"]
yid,_=readdlm(joinpath(S,"yid.csv"),',',header=true); Xr,_=readdlm(joinpath(S,"X.csv"),',',header=true)
pedr,_=readdlm(joinpath(S,"ped.csv"),',',String,header=true)
y=Float64.(yid[:,1]); aid=string.(yid[:,2]); X=Float64.(Xr)
miss(v)=[isempty(s)||s=="NA" ? "0" : s for s in v]
ped=normalize_pedigree(strip.(pedr[:,1]), miss(strip.(pedr[:,3])), miss(strip.(pedr[:,2])))
Ainv=pedigree_inverse(ped); q=size(Ainv,1)
pos=Dict(string(v)=>i for (i,v) in enumerate(ped.ids))
Z=sparse(1:length(y),[pos[a] for a in aid],ones(length(y)),length(y),q)
eff=[(Z,Ainv),(Z,spdiagm(0=>ones(q)))]
best(f,n=5)=minimum(@elapsed(f()) for _ in 1:n)

ws = HSquared._multi_reml_workspace(y,X,eff)
s=[0.5954004,0.5252307]; se2=1.3727602
Ainvs = [e[2] for e in eff]
lhs, rhs = HSquared._assemble_lhs_rhs!(ws, s, se2)
factor = HSquared._factorize!(ws)
nf = size(X,2); offsets = [nf, nf+q]

t_asm  = best(()->HSquared._assemble_lhs_rhs!(ws,s,se2))
t_fac  = best(()->HSquared._factorize!(ws))
t_sol  = best(()->(factor \ rhs))
t_sel  = best(()->HSquared.selinv_block_traces(factor, Ainvs, offsets))
@printf("--- inside ONE AI-REML iteration (best of 5) ---\n")
@printf("_assemble_lhs_rhs!         %6.1f ms\n", 1000t_asm)
@printf("_factorize! (cholesky!)    %6.1f ms\n", 1000t_fac)
@printf("one MME solve (factor\\rhs) %6.1f ms\n", 1000t_sol)
@printf("selinv_block_traces        %6.1f ms   <-- \n", 1000t_sel)
@printf("sum of the four            %6.1f ms\n", 1000*(t_asm+t_fac+t_sol+t_sel))
@printf("\nmeasured whole iteration   ~61.0 ms\n")
@printf("nnz(lhs)=%d  size=%d\n", nnz(lhs), size(lhs,1))
