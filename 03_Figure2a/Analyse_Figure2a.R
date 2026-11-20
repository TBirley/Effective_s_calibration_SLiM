# Rscript Analyse_Figure2a.R figure2a_results analysis_results/threshold_by_seed.csv figure2a_analysis
# Hard reference CSV is produced by 01_Process_simulations.R in the main repository.
suppressPackageStartupMessages({library(data.table); library(ggplot2)})
a <- commandArgs(TRUE)
root <- if(length(a)>0) a[1] else 'figure2a_results'
hardfile <- if(length(a)>1) a[2] else 'analysis_results/threshold_by_seed.csv'
out <- if(length(a)>2) a[3] else 'figure2a_analysis'
dir.create(out,recursive=TRUE,showWarnings=FALSE)
B <- as.integer(Sys.getenv('N_BOOT','2000')); stopifnot(B>0)
set.seed(12345)
keys <- c('K','Nc','Mu','rho','chromLength','h','generations','trackStart','trackEnd')
tr <- c(keys,'s','R','D','EnvSD','mode')
files <- list.files(root,pattern='^parameters\\.tsv$',recursive=TRUE,full.names=TRUE)
if(!length(files)) stop('No Figure2a parameter files found')
m <- rbindlist(lapply(files,function(f){z<-fread(f); stopifnot(nrow(z)==1); z[,run_dir:=dirname(f)]; z[,completed:=file.exists(file.path(run_dir,'completed.txt'))]; z}))
if(anyDuplicated(m[,c(tr,'seed'),with=FALSE])) stop('Duplicate treatment/seed')
fwrite(m,file.path(out,'manifest.csv'))
if(any(!m$completed)) warning('Incomplete runs excluded; see manifest.csv')
m <- m[completed==TRUE]
if(!nrow(m)) stop('No completed runs')
d <- rbindlist(lapply(seq_len(nrow(m)),function(i){
 z<-m[i]; stopifnot(as.numeric(readLines(file.path(z$run_dir,'completed.txt'))[1])==z$generations)
 t<-fread(file.path(z$run_dir,'Figure2a_trackedmutations_10-15k.txt'))
 ids<-t[Event=='tracked',Mutation_ID]
 if(anyDuplicated(ids)||any(!t$Mutation_ID %in% ids)||any(!is.finite(t$q)|t$q<0|t$q>1)) stop('Invalid mutation events: ',z$run_dir)
 terminal<-t[Event %in% c('lost','fixed','censored'),Mutation_ID]
 if(anyDuplicated(terminal)||!setequal(ids,terminal)) stop('Missing or duplicate terminal events: ',z$run_dir)
 z[,`:=`(n_tracked=length(ids),n_crossed=uniqueN(t[q>=.05,Mutation_ID]))]; z
}))
fwrite(d,file.path(out,'threshold_by_seed.csv'))
hard<-fread(hardfile)[model=='Hard' & abs(threshold-.05)<1e-10]
stopifnot(all(c(keys,'s','seed','n_tracked','n_crossed') %in% names(hard)))
if(anyDuplicated(hard[,c(keys,'s','seed'),with=FALSE])) stop('Duplicate hard reference treatment/seed')
pool<-function(z) if(sum(z$n_tracked)>0) sum(z$n_crossed)/sum(z$n_tracked) else NA_real_
boot<-function(z) pool(z[sample.int(nrow(z),replace=TRUE)])
invert<-function(x,p,y){
 if(length(x)<2 || any(!is.finite(c(p,y)))) return(NA_real_)
 fit <- -isoreg(x,-p)$yf
 if(y<min(fit)||y>max(fit)||length(unique(fit))<2) return(NA_real_)
 approx(fit,x,xout=y,ties=mean)$y
}
res<-list(); refs<-list(); j<-0L
for(g in seq_len(nrow(unique(d[,..keys])))){
 k<-unique(d[,..keys])[g]; h<-hard[k,on=keys,nomatch=0]; cdat<-d[k,on=keys,nomatch=0]
 if(!nrow(h)) stop('No matched hard reference: ',paste(unlist(k),collapse=' / '))
 hs<-sort(unique(abs(h$s))); hh<-lapply(hs,function(x) h[abs(s)==x]); hp<-vapply(hh,pool,0.0)
 if(length(hs)<2 || any(!is.finite(hp))) stop('Insufficient hard reference')
 hb<-matrix(replicate(B,vapply(hh,boot,0.0)),nrow=length(hs))
 refs[[g]]<-cbind(k[rep(1,length(hs))],data.table(abs_s=hs,p=hp,p_monotone=-isoreg(hs,-hp)$yf,n_replicates=vapply(hh,nrow,integer(1))))
 treatments<-unique(cdat[,.(s,R,D,EnvSD,mode)])
 for(i in seq_len(nrow(treatments))){
  b<-treatments[i]; if(b$s==0) next
  z<-cdat[b,on=names(b),nomatch=0]; p<-pool(z); cb<-replicate(B,boot(z)); est<-invert(hs,hp,p)
  draws<-vapply(seq_len(B),function(v) invert(hs,hb[,v],cb[v]),0.0)
  valid<-sum(is.finite(draws)); ci<-if(valid/B>=.95) quantile(draws,c(.025,.975),na.rm=TRUE,names=FALSE) else c(NA_real_,NA_real_)
  j<-j+1L; res[[j]]<-cbind(k,b,data.table(p=p,abs_se=est,abs_se_lower=ci[1],abs_se_upper=ci[2],amplification=est/abs(b$s),amp_lower=ci[1]/abs(b$s),amp_upper=ci[2]/abs(b$s),n_valid=valid,n_boot=B,n_replicates=nrow(z),n_tracked=sum(z$n_tracked),n_crossed=sum(z$n_crossed)))
 }
}
if(!length(res)) stop('No non-neutral competitive treatments')
r<-rbindlist(res); fwrite(r,file.path(out,'calibration.csv')); fwrite(rbindlist(refs),file.path(out,'hard_reference.csv'))
# Plot defaults follow manuscript caption, not the example Bash file.
num<-function(name,default) as.numeric(Sys.getenv(name,as.character(default)))
ps<-num('PLOT_S',-.001); ph<-num('PLOT_H',.5); pe<-num('PLOT_ENV_SD',.25); pr<-num('PLOT_R',1)
plotdata<-r[s==ps & h==ph & K==num('PLOT_K',1000) & Nc==num('PLOT_NC',5000) & Mu==num('PLOT_MU',1e-5) & rho==num('PLOT_RHO',.5) & chromLength==num('PLOT_L',1000) & generations==num('PLOT_GENERATIONS',30000) & trackStart==num('PLOT_TRACK_START',10001) & trackEnd==num('PLOT_TRACK_END',15000) & ((mode=='Bernoulli' & R==pr & EnvSD==pe) | mode=='Ranked')]
if(!nrow(plotdata)) stop('No matching plot treatments; calibration.csv saved. Set PLOT_* variables.')
plotdata[,label:=ifelse(mode=='Ranked','Ranked',as.character(D))]
if(anyDuplicated(plotdata$label)) stop('Multiple treatments per plotted category')
lev<-c(as.character(sort(plotdata[mode=='Bernoulli',D])),'Ranked'); plotdata[,label:=factor(label,levels=lev)]
if(!all(c('1','2','5','10','20','50','100','Ranked') %in% as.character(plotdata$label))) warning('Some manuscript categories missing')
if(any(plotdata$n_replicates!=100)) warning('Some plotted treatments do not have 100 replicates')
if(any(!is.finite(plotdata$amplification))) warning('Some estimates outside calibration range; no bar drawn')
if(any(!is.finite(plotdata$amp_lower))) warning('Some bootstrap intervals unavailable')
fwrite(plotdata,file.path(out,'Figure2a_plot_data.csv'))
p<-ggplot(plotdata,aes(label,amplification,fill=mode))+geom_col(width=.72,na.rm=TRUE)+geom_errorbar(aes(ymin=amp_lower,ymax=amp_upper),width=.18,na.rm=TRUE)+geom_hline(yintercept=1,linetype='dashed')+scale_fill_manual(values=c(Bernoulli='#0072B2',Ranked='#D55E00'))+scale_y_continuous(expand=expansion(mult=c(0,.08)))+labs(x='Number of distinct rivals (D)',y=expression(abs(s[e])/abs(s)),fill=NULL)+theme_classic(base_size=12)+theme(legend.position='none')
ggsave(file.path(out,'Figure2a.pdf'),p,width=7,height=4.5); ggsave(file.path(out,'Figure2a.png'),p,width=7,height=4.5,dpi=400)
