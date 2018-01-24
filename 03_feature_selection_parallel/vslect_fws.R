# Author: Aaron Zhu
# write forward selection function (foreach)
library(stats)
library(AICcmodavg)
library(foreach)
library(iterators)
library(parallel)
library(doParallel)

fws <- function (resp = resp, fixed = fixed, pool = pool, data = data, cri = "a_r2"){
formu <- paste0(resp , "~", fixed)
lm <- lm(formu, data = data)
cri_temp <- summary(lm)$adj.r.squared * (cri == "a_r2") * -1 +
          AICc(lm, return.K = FALSE, second.ord = FALSE) * (cri == "aic") +
          AICc(lm, return.K = FALSE) * (cri == "aicc") +
          BIC(lm) * (cri == "bic")
added <- "go"
while(!is.null(added)){
added <- NULL
count <- length(pool)
index <- foreach(i = 1:count , .packages = c("stats", "AICcmodavg"), .combine = rbind) %dopar% {
formu <- paste0(resp , "~", fixed, " + ",pool[i])
lm <- lm(formu, data = data)
temp <- summary(lm)$adj.r.squared * (cri == "a_r2") * -1 +
              AICc(lm, return.K = FALSE, second.ord = FALSE) * (cri == "aic") +
              AICc(lm, return.K = FALSE) * (cri == "aicc") +
              BIC(lm) * (cri == "bic")
}
if(index[which.min(index)] < cri_temp){
cri_temp <- index[which.min(index)]
added <- pool[which.min(index)]
}

if(!is.null(added)){
fixed <- paste0(fixed, "+", added)
pool  <- setdiff(pool, added)
}
}
formu <- paste0(resp , "~", fixed)
return(lm(formu, data = data) )
}

#*********************************************************
## instruction
## pool means potential variables to include in the model
# pool <- c("var1", "var2", ....)
## fixed means fixed terms in the model, you need "+"
# fixed <- "pd_0403_1010 + pd_0402 + pd_1011"
## if you don't want to fix any term, fixed <- "1"
## resp means the response variable
# resp <- "ln_p_agg_b"
## cri means the criteria (aicc aic bic a_r2) you want to use, the default is a_r2.
# cri <- "aicc"

# vs<- fws(resp = resp, fixed = fixed, cri = cri, pool = pool, data = data)
