source('common.R')
cal<-read('calibration'); p<-read('threshold_summary'); ne<-read('ne_summary'); load<-read('load_summary'); sfs<-read('sfs_summary'); mx<-read('maxq_summary')
# Baseline settings; change for alternative experiments.
base<-function(z) z[Mu==1e-5 & rho==.5 & chromLength==1000 & generations==30000 & trackStart==10001 & trackEnd==15000]
main<-function(z) base(z)[K==1000 & Nc==5000]
six<-function(z) z[D%in%c(1,5,10)&R%in%c(1,9)]
three<-function(z) z[(R==1&D==1)|(R==3&D==5)|(R==9&D==10)]
write(six(main(cal))[h==.5 & method=='raw'],'Fig1a'); write(main(load)[h==.5 & s==-.001 & stage=='post' & metric=='mean_ind_relzLoad' & (model=='Hard'|(D%in%c(1,5,10)&R%in%c(1,9)))],'Fig1b')
write(main(sfs)[h==.5 & ((model=='Hard' & s%in%c(0,-.001)) | (model=='Competition' & s==-.001 & ((R==1&D==1)|(R==9&D==10)))) & (q_lower<.1|q_lower>=.9)],'Fig1c_f')
write(base(p)[s==0 & h==.5 & Nc==5000],'FigS1_probability'); write(base(ne)[s==0 & h==.5 & Nc==5000],'FigS1_Ne')
# S2 requires actual hard simulations at the calibrated s, not interpolation of distributions.
# Export available reference curves and a matching request with nearest available s and mismatch.
cc<-main(cal)[h==.5 & s==-.0025 & method=='raw']; hard<-main(mx)[model=='Hard' & h==.5]; hs<-unique(hard$s)
cc[,reference_s:=vapply(abs_se,function(x) if(is.finite(x)&&length(hs)) hs[which.min(abs(abs(hs)-x))] else NA_real_,0.0)]; cc[,reference_error:=abs(abs(reference_s)-abs_se)]; write(cc,'FigS2_reference_requests'); write(main(mx)[h==.5 & (model=='Hard'|s==-.0025)],'FigS2_distributions_available')
write(main(mx)[h%in%c(0,.1,.2,.5)&s==-.0025 & (model=='Hard'|(R==9&D==1))],'FigS3_density'); write(main(p)[h%in%c(0,.1,.2,.5)&s==-.0025 & (model=='Hard'|(R==9&D==1))],'FigS3_probability')
write(main(cal)[h==.5 & method=='raw' & R%in%c(1,3,9)&D%in%c(1,5,10)],'FigS4'); a<-three(main(cal))[h%in%c(0,.01,.05,.1,.2,.5)&s%in%c(-.0025,-.005)&method=='raw']; write(a,'FigS5a'); write(main(p)[h%in%c(0,.01,.05,.1,.2,.5)&s%in%c(-.0025,-.005)&(model=='Hard'|(R==1&D==1)|(R==3&D==5)|(R==9&D==10))],'FigS5b'); a<-a[h%in%c(.05,.1,.2,.5)]; a[,`:=`(abs_hs=abs(h*s),abs_hse=h*abs_se,hetero_lower=h*lower,hetero_upper=h*upper)]; write(a,'FigS6')
a<-base(cal)[h==.5 & R==1 & D==5 & Nc==5*K & s%in%c(-.001,-.0025,-.005)]; write(a[Nc==500],'FigS7a'); write(a[Nc==5000],'FigS7b'); write(a[(Nc%in%c(500,1000,2500,5000)&method=='adjusted')|(Nc==25000&method=='raw')],'FigS7c')
z<-base(p)[s==0 & h==.5 & Nc==5*K & (model=='Hard'|(R==1&D==5))]; t<-dcast(z,K+Nc~model,value.var='p'); if(all(c('Hard','Competition')%in%names(t))) t[,ratio:=Competition/Hard]; write(t,'TableS1')
z<-base(ne)[h==.5 & Nc==5*K & (model=='Hard'|(R==1&D==5))]; write(z[,.(Mean_Ne=base::mean(mean),Ne_over_Nc=mean(Ne_over_Nc),n_treatments=.N),by=.(model,K,Nc)],'TableS2'); write(z,'TableS2_treatment_detail')
z<-cal[K==1000&Nc==5000&chromLength==1000&generations==30000&trackStart==10001&trackEnd==15000&h==.5&s==-.0025&R==1&D==5&method=='raw']; write(z[rho==.5],'TableS3'); write(z[Mu==1e-5],'TableS4')
