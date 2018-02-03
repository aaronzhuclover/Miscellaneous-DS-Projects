# clear all variables 
rm(list=ls())
#Collect Information About the Current R Session
sessionInfo()
search()
# load packages 
library(openxlsx)
library(dplyr)
library(stringr)
library(ggplot2)
library(readstata13)
library(tidyr)
library(xlsx)
library(foreign)
library(Formula)
library(plm)
library(zoo)
library(foreign)
library(sandwich)
library(lmtest)
library(rJava)
library(glmulti)
library(LEAP)
#########################################################################
# **************************************************************************************************************************
# **************************************************************************************************************************
inpath <- "M:/Containerboard/To Counsel/15-12-11_Dwyer_Merits_Reply_Backup_(dbx)/Other_Files/Data/_out/"
data <- as.data.frame(read.dta13(paste0(inpath, "a03_04a_regdata_real.dta")))
# **************************************************************************************************************************

# **************************************************************************************************************************
# write my own forward selection function (foreach)
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

# **************************************************************************************************************************

# run simple regression 

regset <- "pd_0403_1010 pd_1012_1104 pd_0402 pd_1011 ener_nom energy_cng pulp_nom chemical_index hourly_wages lag1_y_exog_brd lag1_lin_brd_exp lag1_box_ship initial_ui emp hours_mfg ip housing pmi_index cconf sp500 m2 bondrate lag1_ener_nom lag1_energy_cng lag1_pulp_nom lag1_chemical_index lag1_hourly_wages lag1_initial_ui lag1_emp lag1_hours_mfg lag1_ip lag1_housing lag1_pmi_index lag1_cconf lag1_sp500 lag1_m2 lag1_bondrate"
regset <- gsub(" ", "+", regset)
formu <- paste0("ln_p_agg_b ~" , regset)
lm<- lm(formu, data= data)

data$ln_p_agg_b_fit <- lm$fitted.values - data$pd_0403_1010 * lm$coefficients[2] - data$pd_1012_1104 * lm$coefficients[3]  -
                                      data$pd_0402 * lm$coefficients[4] - data$pd_1011 * lm$coefficients[5] 
res_mean <- mean(lm$residuals)
res_sd <- sd(lm$residuals)

# generate data parallelly 
library(doRNG)

cl <- makeCluster(3)  
registerDoParallel(cl) 
set.seed(123)
fit<- foreach(i = 1:1000, .combine = cbind) %dorng% {
step <-  rnorm(144, mean = res_mean, sd = res_sd) + data$ln_p_agg_b_fit
}  
fit <- as.data.frame(fit)
names(fit) <- sub("result.","fit_", names(fit) )
data <- cbind(data, fit)
rm(fit)

# **************************************************************************************************************************
# rum simulation with model selection on pcs
pool <- c(rds(data, "pca"), rds(data, "mo")[-1], "pd_1012_1104")
# fixed <- "1"
fixed <- "pd_0403_1010 + pd_0402 + pd_1011"
resp <- "ln_p_agg_b"
cri <- "aicc"

vs<- fws(resp = resp, fixed = fixed, cri = cri, pool = pool, data = data)
coef <- vs$coefficients[2]

ptm <- proc.time()
simu<- foreach(i = 1:1000, .packages = c("stats", "AICcmodavg", "foreach", "iterators", "parallel", "doParallel", "lmtest", "sandwich"), .combine = rbind ) %dopar% {
resp <- paste0("fit_", i)
vs<- fws(resp = resp, fixed = fixed, pool = pool, cri = cri, data = data)
coeftest(vs, vcov = vcovHC(vs, "HC1"))[2,]
}
print(proc.time() - ptm)

stopCluster(cl)

simu <- as.data.frame(simu)

outpath <- "C:/Users/azhu.HARRISECONOMICS/Dropbox/mtcs/04_pca_aicc/out/"
write.xlsx(simu, paste0(outpath, "simu_fcp_but4_2.xlsx"), append = T)	

