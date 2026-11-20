suppressPackageStartupMessages(library(data.table))
args <- commandArgs(TRUE)
root <- if(length(args)>=1) args[1] else 'results'
out <- if(length(args)>=2) args[2] else 'analysis_results'
dir.create(out,recursive=TRUE,showWarnings=FALSE)
keys <- c('model','K','Nc','Mu','rho','chromLength','h','s','R','D','generations','trackStart','trackEnd')
refkeys <- setdiff(keys,c('model','s','R','D'))
write <- function(x,name) fwrite(x,file.path(out,paste0(name,'.csv')))
read <- function(name) fread(file.path(out,paste0(name,'.csv')))
ci <- function(x) { x <- x[is.finite(x)]; n <- length(x); m <- if(n) mean(x) else NA_real_; e <- if(n>1) qt(.975,n-1)*sd(x)/sqrt(n) else NA_real_; list(n=n,mean=m,lower=m-e,upper=m+e) }
file_one <- function(dir,pattern) { f <- list.files(dir,pattern=pattern,recursive=TRUE,full.names=TRUE); if(length(f)!=1) stop('Expected one file: ',dir,' / ',pattern); f }
manifest <- function() read('manifest')[status=='completed']
attach_meta <- function(d,m) { for(k in c(keys,'seed')) d[,(k):=m[[k]][1]]; d }
