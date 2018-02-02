	# Author: Aaron Zhu 
	# step 1: join all the records from different zipcode together, compute unit price (total price / total living space)
	# step 2: For a given city, year and type (single house/condo/townhouse), compute their median price
	# step 3: For a given city and type, compute annual median price change
	# step 3: make graphs 
	#************************************************************
	inpath <- ".../data/archive/"
	outpath <- ".../07_data_scraping/out/"
	#*************************************************************

	# import .csv data 
	files <- list.files(inpath)
	files <- files[grepl("csv", files)]

	data <- read.csv(paste0(inpath, files[1]), sep = ",", header= TRUE, stringsAsFactors = F)

	for(i in 2:length(files)){
	tmp <- read.csv(paste0(inpath, files[i]), sep = ",", header= TRUE, stringsAsFactors = F)
	data <- rbind(data, tmp)
	}
	rm(tmp)

	names(data) <- gsub("URL.*","URL",names(data))
	names(data) <- tolower(names(data) )
	names(data) <- gsub("\\.","_",names(data))
	data <- filter(data, sale_type == "PAST SALE" )
	data$sold_date <- as.Date(data$sold_date, "%B-%d-%Y")

	data$pro_type <- ""
	data<- data %>%
			   mutate(pro_type = ifelse(property_type== "Condo/Co-op", "condo", pro_type), 
						  pro_type = ifelse(grepl("Single Family", property_type), "single_family", pro_type), 
						  pro_type = ifelse(property_type== "Townhouse", "townhouse", pro_type)
			   )

	data <- filter(data, !pro_type == "" )
	data$sale_type <- NULL
	data <- mutate(data, city = toupper(city))
	data <- mutate(data, city = ifelse(city == "RANCHO CALIFORNIA", "RANCHO CUCAMONGA",city))
	#*********

	data <- filter(data, !is.na(sold_date))
	data <- mutate(data, lot_price = price/lot_size , 
								   living_price = price/square_feet
				)
	data <- mutate(data, yr = year(sold_date))
	#data <- filter(data, yr >= 2000)

	data <- data %>%
				group_by(city, yr, pro_type) %>%
				mutate(lot_price_10 = quantile(lot_price, 0.1, na.rm = T),
						   lot_price_30 = quantile(lot_price, 0.3, na.rm = T),
						   lot_price_50 = quantile(lot_price, 0.5, na.rm = T),
						   lot_price_70 = quantile(lot_price, 0.7, na.rm = T),
						   lot_price_90 = quantile(lot_price, 0.9, na.rm = T),
						   living_price_10 = quantile(living_price, 0.1, na.rm = T),
						   living_price_30 = quantile(living_price, 0.3, na.rm = T),
						   living_price_50 = quantile(living_price, 0.5, na.rm = T),
						   living_price_70 = quantile(living_price, 0.7, na.rm = T),
						   living_price_90 = quantile(living_price, 0.9, na.rm = T),
						   n = sum(!is.na(living_price))
				)
	keep <- names(data)[grep("lot_price_", names(data) )	]		
	keep <- c(keep , names(data)[grep("living_price_", names(data) )	])
	keep <- c("n","city", "yr", "pro_type", keep)
	data <- data[,keep]		
	data <- data[!duplicated(data),]		
	data <- arrange(data, city, pro_type, yr)

	keep <- names(data)[grep("living_price_", names(data) )	]	
	keep <- c("n","city", "yr", "pro_type", keep)
	data <- data[,keep]	
	data <- data%>%
				arrange(city, pro_type, yr) %>%
				group_by(city, pro_type) %>%
				mutate(living_p_r_10  = living_price_10/ lag(living_price_10) - 1 ,
						   living_p_r_30  = living_price_30/ lag(living_price_30) - 1 ,
						   living_p_r_50 = living_price_50/ lag(living_price_50) - 1 ,
						   living_p_r_70  = living_price_70/ lag(living_price_70) - 1 ,
						   living_p_r_90  = living_price_90/ lag(living_price_90) - 1 
				)

	data <- filter(data,city == "WEST COVINA" |city == "ARCADIA" |city == "EL MONTE" |city == "SAN GABRIEL"  |city == "PASADENA" |city == "ALHAMBRA" 
	 )
	 
	 
	#*************************************************************
	tiff(paste0(outpath, "sf_home_price.jpeg"), width=1500, height=1200)
	ggplot() +
	geom_line(data= data[data$pro_type == "single_family",], aes(x= yr, y = living_price_50, color = city), size =2 )  +
	scale_x_continuous(breaks=min(data$yr):max(data$yr)) +
	xlab("Year") + 
	ylab("Dollars per Square Foot") + 
	labs(title=paste0("Median Single-Family Home Price at San Gabriel Area"), caption = "Source: REDFIN.COM" )  +
	theme(legend.position = "bottom", plot.title = element_text(hjust = 0.5, size=46), plot.subtitle = element_text(hjust = 0.5, size=34), plot.caption = element_text(size=28), axis.text=element_text(size=24) , axis.title=element_text(size=30), legend.text = element_text(size=23), legend.title=element_blank()) +
	scale_y_continuous(labels =scales::dollar_format()) 
	dev.off()

	#*************************************************************

	tiff(paste0(outpath, "sf_home_price_change.jpeg"), width=1500, height=1200)
	ggplot() +
	geom_line(data= data[data$pro_type == "single_family",], aes(x= yr, y = living_p_r_50, color = city), size =2 )  +
	scale_x_continuous(breaks=min(data$yr):max(data$yr)) +
	xlab("Year") + 
	ylab("Percentage Change") + 
	labs(title=paste0("Annual Percentage Change for Median Single-Family Home Price \n at San Gabriel Area"), caption = "Source: REDFIN.COM" )  +
	theme(legend.position = "bottom", plot.title = element_text(hjust = 0.5, size=46), plot.subtitle = element_text(hjust = 0.5, size=34), plot.caption = element_text(size=28), axis.text=element_text(size=24) , axis.title=element_text(size=30), legend.text = element_text(size=23), legend.title=element_blank()) + 
	scale_y_continuous(labels = scales::percent, breaks= seq(-0.25,0.5,0.1)) 
	dev.off()

	#*************************************************************
	tiff(paste0(outpath, "condo_home_price.jpeg"), width=1500, height=1200)
	ggplot() +
	geom_line(data= data[data$pro_type == "condo",], aes(x= yr, y = living_price_50, color = city), size =2 )  +
	scale_x_continuous(breaks=min(data$yr):max(data$yr))  +
	xlab("Year") + 
	ylab("Dollars per Square Foot") + 
	labs(title=paste0("Median Condo Price at San Gabriel Area"), caption = "Source: REDFIN.COM" )  +
	theme(legend.position = "bottom", plot.title = element_text(hjust = 0.5, size=46), plot.subtitle = element_text(hjust = 0.5, size=34), plot.caption = element_text(size=28), axis.text=element_text(size=24) , axis.title=element_text(size=30), legend.text = element_text(size=23), legend.title=element_blank()) +
	scale_y_continuous(labels =scales::dollar_format()) 
	dev.off()

	#*************************************************************
	tiff(paste0(outpath, "condo_home_price_change.jpeg"), width=1500, height=1200)
	ggplot() +
	geom_line(data= data[data$pro_type == "condo",], aes(x= yr, y = living_p_r_50, color = city), size =2 )  +
	scale_x_continuous(breaks=min(data$yr):max(data$yr))  +
	xlab("Year") + 
	ylab("Percentage Change") + 
	labs(title=paste0("Annual Percentage Change for Median Condo Price \n at San Gabriel Area"), caption = "Source: REDFIN.COM" )  +
	theme(legend.position = "bottom", plot.title = element_text(hjust = 0.5, size=46), plot.subtitle = element_text(hjust = 0.5, size=34), plot.caption = element_text(size=28), axis.text=element_text(size=24) , axis.title=element_text(size=30), legend.text = element_text(size=23), legend.title=element_blank()) + 
	scale_y_continuous(labels = scales::percent, breaks= seq(-0.3,0.75,0.1)) 
	dev.off()







