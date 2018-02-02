	# Author: Aaron Zhu
	# starting point is final selected FE model (defXtype on d07 and d08)
	# apply posterior simulation on homoscedastic model - we dont need gibbs sampler for this task 
	# exam systematic conspiracy effect and cus impact with competitive residual 
	# for cus impact with competitive residual, 
	### 5.1 common:  Qt-weight x, y, and augmented terms at [cus X prod X loc X s] level, 
	### so that our data will be reduced to [cus X prod X loc X s] level
	### then, prepare reduced x, y , z matrix       
	#********************************************
	# data file path 
	db  <- ".../out/"
	nas <- ".../out/"

	#******************************************
	# load final selected double model 
	load(file = paste0(db, "10_df_regresults_ri_double.Rda"))  #### df_output
	df_selec <- df_output_i2 %>% filter(ri == 1000)
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
	data <- data[,c("ln_p", selec_nms[!(grepl("2008", selec_nms) |grepl("2007", selec_nms))])]
	gc()

	########### load double interaction for d_07 and d_08 ###########
	system.time(load(file = paste0(nas, "REG_randomize_data_fe_double_dm.Rda"))) 
	data <- cbind(data, REG_data_demean_double)
	rm(REG_data_demean_double)
	data <- data[,c("ln_p", selec_nms)]
	gc()

	formu <- paste0(selec_nms, collapse= " + ")
	formu <- paste0("ln_p ~ ", formu)

	lm <- lm(formula =  formu, data=data)
	summary(lm)
	gc()

	#### compute residual variance (s2)
	s2 <- var(lm$residuals)
	print(s2)

	#### construct x matrix and y matrix 
	data <- mutate(data, interp = 1)
	x <- as.matrix(select(data, c("interp", selec_nms)))
	y <- as.matrix(select(data, ln_p))


	# implement Bayesian simulation
	#### draw betas from MVN
	system.time(mean <- solve(t(x) %*% x) %*% t(x) %*% y )
	mean <- rep(mean, 1000)
	mean <- matrix(mean, nrow = 1000, byrow = TRUE)
	n <- length(lm$coefficients)
	set.seed(123)

	p <- proc.time()
	# standard normal draws are idd 
	m1 <- matrix(rnorm(n*1000, mean = 0, sd = 1),nrow = 1000, byrow = TRUE )
	# one sigma for one draw of betas  
	m2 <- matrix(rep(s2*(length(y)-n)/ rchisq(1000, (length(y)-n)), n) , nrow = 1000, byrow = FALSE )
	b_sim <- mean + m1 %*% chol(solve(t(x) %*% x)) * m2^0.5 
	proc.time() - p 
	# Running time: 12.24 s

	### compute distribution of systematic conspiracy effect 
	sys_effect <- selec_nms[grepl("2008", selec_nms) |grepl("2007", selec_nms)]

	for(var in sys_effect){
	print(var)
	print(summary(b_sim[,var]))
	}


	##############################################################################################################
	###################### compute distribution of impact share in term of acr ######################

	# 1. Qt-weight x(exclude systematic conspiracy effect) and y at CUS level, 
	system.time(load(file = paste0(nas, "REG_randomize_data_fe_others.Rda"))) 
	FE_data <- select(FE_data, std_soldto_num, yr, ym_R, tot_qty)
	data <- cbind(data, FE_data)
	rm(FE_data)
	gc()
	# we only need transactions in affected yr to compute acr
	data_a <- filter(data, yr >= 2007) 

	vw_list <- c("ln_p", "interp", selec_nms[!(grepl("2008", selec_nms) |grepl("2007", selec_nms))])
	for(var in vw_list){
		  c <- interp(~ weighted.mean(v, w = tot_qty) , v = as.name(var)) 
		  data_a <- data_a %>%
					   arrange(std_soldto_num, ym_R) %>%
					   group_by(std_soldto_num) %>%
					   mutate_(.dots = setNames(list(c), paste0(var, "_wt"))) %>%
					   ungroup()
	}

	data_a <- data_a[,c("std_soldto_num", names(data_a)[grepl("_wt", names(data_a))])]
	data_a <- data_a %>%
			  group_by(std_soldto_num) %>%
			  mutate(n = row_number()) %>%
			  filter(n==1) %>%
			  ungroup()
	data_a <- select(data_a, -n)

	# 2. used matrix to compute acr for a given simulated beta and cus
	# acr = Y - XB
	# [884*1000] = [884*1000] - [844*k][k*1000] 
	p <- proc.time()
	Y <- matrix(rep(data_a$ln_p_wt,1000), , nrow = dim(data_a)[1], byrow = FALSE )
	X <- as.matrix(data_a[,-c(1,2)])
	B <- b_sim[,colnames(b_sim)[!(grepl("2008", colnames(b_sim)) |grepl("2007", colnames(b_sim)))]] 
	acr <-  data.frame(Y - X %*% t(B))
	impact <- data.frame(ifelse(acr >= 0.05 , 1, 0))
	proc.time() - p 
	# Running time: 0.13 s
	# compute distribution of impact share
	summary(colMeans(impact))



