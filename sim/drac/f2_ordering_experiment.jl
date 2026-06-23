using HSquared, SparseArrays, LinearAlgebra, Metis, Printf
function halfsib(q)
  nsire=max(2,round(Int,0.04q)); ndam=max(2,round(Int,0.08q)); noff=q-nsire-ndam
  sids=["s$i" for i in 1:nsire]; dids=["d$i" for i in 1:ndam]; oids=["o$i" for i in 1:noff]
  ids=vcat(sids,dids,oids)
  sire=vcat(fill("0",nsire+ndam),[sids[((i-1)%nsire)+1] for i in 1:noff])
  dam=vcat(fill("0",nsire+ndam),[dids[((i-1)%ndam)+1] for i in 1:noff])
  normalize_pedigree(ids,sire,dam)
end
for q in (100000,300000)
  ped=halfsib(q); Ainv=pedigree_inverse(ped); n=length(ped.ids)
  y=[5.0+0.1*sin(i*0.17) for i in 1:n]; X=ones(n,1); Z=sparse(1.0I,n,n)
  spec=animal_model_spec(y,X,Z,Ainv;method=:REML)
  lhs,_,_=HSquared._sparse_mme_system(spec,1.0,1.0); C=Symmetric(lhs)
  GC.gc(); F0=cholesky(C); t0=@elapsed cholesky(C); nl0=nnz(sparse(F0.L))
  GC.gc(); pp,_=Metis.permutation(lhs); pv=Vector{Int}(pp)
  Fm=cholesky(C; perm=pv); tm=@elapsed cholesky(C; perm=pv); nlm=nnz(sparse(Fm.L))
  @printf("q=%d  AMD nnz(L)=%d t=%.2fs  |  METIS nnz(L)=%d t=%.2fs  |  fill x%.2f  speed x%.2f\n", n,nl0,t0,nlm,tm,nl0/nlm,t0/tm)
end
