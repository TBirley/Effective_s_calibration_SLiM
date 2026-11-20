source('common.R')
B<-as.integer(Sys.getenv('N_BOOT','2000')); stopifnot(B>0); set.seed(12345)
d<-read('threshold_by_seed')[threshold==.05]
pool<-function(z) if(sum(z$n_tracked)>0) sum(z$n_crossed)/sum(z$n_tracked) else NA_real_
bootpool<-function(z) pool(z[sample.int(nrow(z),replace=TRUE)])
invert<-function(x,p,y){ if(any(!is.finite(c(p,y)))||length(x)<2) return(NA_real_); fit<- -isoreg(x,-p)$yf; if(y<min(fit)||y>max(fit)) return(NA_real_); if(length(unique(fit))<2) return(NA_real_); approx(fit,x,xout=y,ties=mean)$y }
res<-list(); j<-0L
for(g in seq_len(nrow(unique(d[,..refkeys])))) { a<-unique(d[,..refkeys])[g]; z<-d[a,on=refkeys,nomatch=0]; hard<-z[model=='Hard']; comp<-z[model=='Competition']; if(!nrow(hard)||!nrow(comp)) next
 hs<-sort(unique(abs(hard$s))); hh<-lapply(hs,function(x) hard[abs(s)==x]); hp<-vapply(hh,pool,0.0)
 hb<-replicate(B,vapply(hh,bootpool,0.0)); if(is.null(dim(hb))) hb<-matrix(hb,nrow=length(hs))
 for(k in seq_len(nrow(unique(comp[,.(R,D,s)])))) { b<-unique(comp[,.(R,D,s)])[k]; if(b$s==0) next; c1<-comp[b,on=c('R','D','s')]; c0<-comp[R==b$R & D==b$D & s==0]; p<-pool(c1); p0<-pool(c0); h0<-if(0%in%hs) hp[match(0,hs)] else NA_real_; cb<-replicate(B,bootpool(c1)); c0b<-if(nrow(c0)) replicate(B,bootpool(c0)) else rep(NA_real_,B); h0b<-if(0%in%hs) hb[match(0,hs),] else rep(NA_real_,B)
 for(method in c('raw','adjusted')) { y<-if(method=='raw') p else if(is.finite(p0)&&p0>0) p/p0*h0 else NA_real_; yb<-if(method=='raw') cb else ifelse(c0b>0,cb/c0b*h0b,NA_real_); est<-invert(hs,hp,y); bs<-vapply(seq_len(B),function(i) invert(hs,hb[,i],yb[i]),0.0); valid<-sum(is.finite(bs)); lim<-if(valid/B>=.95) quantile(bs,c(.025,.975),na.rm=TRUE,names=FALSE) else c(NA_real_,NA_real_); j<-j+1L; res[[j]]<-cbind(a,b,data.table(method=method,p_comp=p,p_hard_neutral=h0,p_comp_neutral=p0,p_target=y,abs_se=est,lower=lim[1],upper=lim[2],amplification=est/abs(b$s),amp_lower=lim[1]/abs(b$s),amp_upper=lim[2]/abs(b$s),n_valid=valid,n_boot=B,n_comp=nrow(c1))) }
 }
}
if(!length(res)) stop('No matched hard/competition reference groups')
write(rbindlist(res),'calibration'); write(d[,.(p=sum(n_crossed)/sum(n_tracked),n_replicates=.N,n_tracked=sum(n_tracked),n_crossed=sum(n_crossed)),by=keys],'threshold_summary')
