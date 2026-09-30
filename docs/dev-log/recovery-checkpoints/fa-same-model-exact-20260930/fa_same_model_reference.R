set.seed(20260927)
q <- 12L; n <- 2L*q; tt <- 4L
sire <- c(rep(0L,4), 1L,1L,2L,3L,5L,5L,6L,7L)
dam  <- c(rep(0L,4), 2L,3L,3L,4L,6L,7L,8L,8L)
A <- diag(q)
for (i in 5:q) {
  s <- sire[i]; d <- dam[i]
  for (j in 1:(i-1L)) A[i,j] <- A[j,i] <- (A[s,j]+A[d,j])/2
  A[i,i] <- 1 + A[s,d]/2
}
Z <- matrix(0,n,q)
for (i in 1:n) Z[i,ceiling(i/2)] <- 1
B <- Z %*% A %*% t(Z)
lambda_true <- c(1.0,0.8,0.65,0.5)
psi_true <- c(.35,.4,.5,.45)
G_true <- tcrossprod(lambda_true)+diag(psi_true)
R_true <- matrix(c(1,.12,0,0, .12,.9,.08,0, 0,.08,.85,.07, 0,0,.07,.8),4,4)
U <- t(chol(A)) %*% matrix(rnorm(q*tt),q,tt) %*% chol(G_true)
E <- matrix(rnorm(n*tt),n,tt) %*% chol(R_true)
Y <- matrix(rep(c(.3,-.4,.5,1.0),each=n),n,tt) + Z%*%U + E
write.csv(Y,'/private/tmp/fa-same-model-exact-20260930/fa_ref_Y.csv',row.names=FALSE)
write.csv(A,'/private/tmp/fa-same-model-exact-20260930/fa_ref_A.csv',row.names=FALSE)
write.csv(Z,'/private/tmp/fa-same-model-exact-20260930/fa_ref_Z.csv',row.names=FALSE)

y <- as.vector(t(Y))
D <- kronecker(matrix(1,n,1),diag(tt))
ii <- diag(n)
lowidx <- lower.tri(matrix(0,tt,tt),diag=TRUE)
encode_R <- function(R) {
  L <- t(chol(R)); x <- numeric(tt*(tt+1)/2); k <- 0L
  for (j in 1:tt) for (i in j:tt) {
    k <- k+1L; x[k] <- if(i==j) log(L[i,j]) else L[i,j]
  }
  x
}
decode_R <- function(x) {
  L <- matrix(0,tt,tt); k <- 0L
  for (j in 1:tt) for (i in j:tt) {
    k <- k+1L; L[i,j] <- if(i==j) exp(x[k]) else x[k]
  }
  tcrossprod(L)
}
unpack <- function(par) {
  lam <- par[1:tt]; psi <- 1e-4+exp(par[tt+1:tt]);
  list(G=tcrossprod(lam)+diag(psi), R=decode_R(par[(2*tt+1):length(par)]),
       lambda=lam,psi=psi)
}
objective <- function(par) {
  m <- unpack(par)
  V <- kronecker(B,m$G)+kronecker(ii,m$R)
  C <- tryCatch(chol(V),error=function(e) NULL)
  if (is.null(C)) return(1e100)
  Viy <- backsolve(C,forwardsolve(t(C),y))
  ViD <- backsolve(C,forwardsolve(t(C),D))
  W <- crossprod(D,ViD)
  CW <- tryCatch(chol(W),error=function(e) NULL)
  if (is.null(CW)) return(1e100)
  beta <- solve(W,crossprod(D,Viy))
  r <- y-D%*%beta
  quad <- drop(crossprod(r,backsolve(C,forwardsolve(t(C),r))))
  .5*((length(y)-ncol(D))*log(2*pi)+2*sum(log(diag(C)))+
       2*sum(log(diag(CW)))+quad)
}
par0 <- c(lambda_true, log(psi_true-1e-4), encode_R(R_true))
cat('start_nll',objective(par0),'\n')
t0 <- proc.time()[3]
fit <- optim(par0,objective,method='BFGS',control=list(maxit=800,reltol=1e-11))
elapsed <- proc.time()[3]-t0
m <- unpack(fit$par)
write.csv(m$G,'/private/tmp/fa-same-model-exact-20260930/fa_ref_R_Ghat.csv',row.names=FALSE)
write.csv(m$R,'/private/tmp/fa-same-model-exact-20260930/fa_ref_R_Rhat.csv',row.names=FALSE)
write.csv(matrix(fit$par,nrow=1),'/private/tmp/fa-same-model-exact-20260930/fa_ref_R_par.csv',row.names=FALSE)
cat('R_version',R.version.string,'\n')
cat('elapsed_s',elapsed,'\n')
cat('convergence',fit$convergence,'function_evals',fit$counts[1],'gradient_evals',fit$counts[2],'\n')
cat('nll',fit$value,'loglik',-fit$value,'\n')
cat('lambda',paste(signif(m$lambda,10),collapse=','),'\n')
cat('psi',paste(signif(m$psi,10),collapse=','),'\n')
cat('Gdiag',paste(signif(diag(m$G),10),collapse=','),'\n')
cat('Rdiag',paste(signif(diag(m$R),10),collapse=','),'\n')
cat('h2',paste(signif(diag(m$G)/(diag(m$G)+diag(m$R)),10),collapse=','),'\n')
