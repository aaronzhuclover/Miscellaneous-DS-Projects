	# Author: Aaron Zhu

	# 2.0: high-K and one variance
	#      - this is Gibbs sampler in Homoskedatic model
	# 2.5: used conventional method - NOT orthogonalize Xs
	#  use Kolmogorov-Smirnov tests to test convergence
	#********************************************
	# data file path 
	db  <- ".../out/"
	nas <- ".../out/"

	#******************************************
	load(file = paste0(db, "df_regresults.Rda"))    #### df_output
	df_selec <- df_output %>% filter(ri == 1000)
	(selec_nms <- df_selec$coef_nm)

	########### load demeaned FE data ##########
	system.time(load(file = paste0(nas, "REG_randomize_data_dm_1.RData")))            # FE_data_demean_1, vlist_lags_all
	system.time(load(file = paste0(nas, "REG_randomize_data_dm_2.RData")))            # FE_data_demean_2, region_xinter_vlist
	system.time(load(file = paste0(nas, "REG_randomize_data_dm_3.RData")))            # FE_data_demean_3, def_xinter_vlist
	system.time(load(file = paste0(nas, "REG_randomize_data_dm_4.RData")))            # FE_data_demean_4, prodattr_xinter_vlist
	system.time(load(file = paste0(nas, "REG_randomize_data_dm_5.RData")))            # FE_data_demean_5, ctype_xinter_vlist
	system.time(load(file = paste0(nas, "REG_randomize_data_dm_6.RData")))            # FE_data_demean_6, csize_xinter_vlist
	 
	FE_data_demean <- cbind(FE_data_demean_1, FE_data_demean_2, FE_data_demean_3, FE_data_demean_4, FE_data_demean_5, FE_data_demean_6)
	data <- FE_data_demean
	rm(FE_data_demean_1, FE_data_demean_2, FE_data_demean_3, FE_data_demean_4, FE_data_demean_5, FE_data_demean_6, FE_data_demean)
	gc()
	data <- data[,c("ln_p", selec_nms)]

	#*************
	formu <- paste0(selec_nms, collapse= " + ")
	formu <- paste0("ln_p ~ ", formu)

	lm <- lm(formula =  formu, data=data)
	summary(lm)
	gc()

	#****************************************************
	# construct intercept 
	data <- mutate(data, interp = 1)
	w_list <- c("interp", names(lm$coefficients)[2:length(lm$coefficients)])
	# construct W matrix						
	W <- as.matrix(select(data, w_list))

	s2 <- var(lm$residuals)
	print(s2)
	# 0.0032693233033777966

	#****************************************************
	varcov <- s2 * solve(t(W) %*% W)
	varcov_diag <- diag(varcov)

	# update betas using FGLS
	y <- as.matrix(select(data, ln_p))
	beta <- as.matrix(lm$coefficients)

	# pick 10 starting points for gibbs sampling 
	set.seed(123)
	for(i in 1:10){
	sign <- rep(4, dim(beta)[1])
	sign[sort(sample(1:dim(beta)[1], floor(dim(beta)[1]/2)))] <- -4
	temp  <- varcov_diag^0.5 * sign + beta
	if(i == 1){ sp <- temp}
	if(i >1 ) {sp <- cbind(sp, temp)}
	}

	names <- row.names(sp)
	colnames(sp) <- NULL
	sp <- as.data.frame(t(sp))
	names(sp) <- names


	#*******************************************************************
	#step 2: start gibbs sampling  
	#*******************************************************************
	# need to use %dorng% to make result reproducible
	# contruct repeated matrix, so that we dont need to recompute them - save running time 
	ww <- t(W)%*% W
	wy <- t(W)%*% y
	yy <- t(y)%*%y
	gs_varcov <-  solve(ww)          # only calculate once
	ch_gs_varcov <- t(chol(gs_varcov))  # only calculate once, transpose: L'L=W'W^(-1)
	ny <- length(y)                     # only calculate once 
	gc()
	cl <- makeCluster(6)  
	registerDoParallel(cl)

	p <- proc.time()
	set.seed(123)
	converge <- foreach(k = 1:10, .packages = c("dplyr", "stats"), .combine = rbind ) %dorng% {
			for(i in 1:1000){
					 
				   if(i==1){
				   gs_beta <- as.matrix(t(sp[k,]))
				   gs_s2 <- as.numeric((yy - 2 * t(gs_beta) %*% wy + t(gs_beta) %*% ww %*% gs_beta) / ny)
				   }
					 
				   if(i> 1){
				   gs_beta <- gs_beta_sim
				   gs_s2 <- as.numeric((yy - 2 * t(gs_beta) %*% wy + t(gs_beta) %*% ww %*% gs_beta) / ny)
				   }
				   # based on s2, simulate sigma2
				   gs_sigma2 <- gs_s2*ny/ rchisq(1, ny)
				   
				   # based on sigma2, update mean and var of betas (means of betas don't change in hmtsk model)
				   gs_beta <- beta
				   
				   # simulate betas using MVN draw 
				   chol <- ch_gs_varcov * gs_sigma2^0.5
					 
				   gs_beta_sim <- gs_beta + chol %*% as.matrix(rnorm(length(gs_beta), mean = 0, sd = 1))
					 
				   # record value in each iteration
					 
				   end <- as.data.frame(t(gs_beta_sim))
					 
				   end <- mutate(end, s2 = gs_s2, sigma2 = gs_sigma2 , sp = k, iter = i)
					if(i ==1){
						result <- end
					}
					if(i >1){
						result <- rbind(result, end)
					}
					}
			result
	}
	proc.time() - p  
	# 28.71 s 
	stopCluster(cl)
	gc()

	fwrite(converge , paste0(nas, "az_07_gpsm_fe_gibbs_test2_5_result.csv"))


	#***************************************************************************************************************************
	# Kolmogorov-Smirnov tests for sigma2
	converge <- fread(paste0(nas, "az_07_gpsm_fe_gibbs_test2_5_result.csv"))
	set.seed(123)
	edf <- filter(converge, iter>500)$sigma2
	df  <- s2*(length(y)-length(beta))/ rchisq(5000, (length(y)-length(beta)))
	ks.test(edf, df)

	edf <- as.data.frame(filter(converge, iter>500)$sigma2)
	names(edf) <- "x"
	edf <- arrange(edf, x)
	edf$cdf <- seq(0,1,length.out = 5000)
	edf$n <- 1:5000

	set.seed(123)
	df  <- as.data.frame(s2*(length(y)-length(beta))/ rchisq(5000, (length(y)-length(beta))))
	names(df) <- "x"
	df <- arrange(df, x)
	df$cdf <- seq(0,1,length.out = 5000)
	df$n <- 1:5000

	ggplot() + 
	geom_step(data = edf, aes(x = x, y = cdf, color = "ECDF")) + 
	geom_step(data = df,  aes(x = x, y = cdf, color = "CDF")) +
	labs(title = "sigma2")















