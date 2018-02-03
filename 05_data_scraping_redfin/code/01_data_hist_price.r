	# Author: Aaron Zhu 
	# step0: we have past sale record for every address and we have url for every address
	#        each url, there is one table called "Property History", we can get all the sale records for a given address
	# step1: Use url to get all the sale records for a given address for future analysis

	#************************************************************
	inpath <- ".../"
	outpath <- ".../"
	#*************************************************************
	# ********************************************************
	# ********************************************************
	data<- fread(paste0(outpath, "el_monte_step1.csv"))
	data <- data %>%
				mutate(sold_date_new = ifelse(sold_date_new == "", NA, sold_date_new), 
						   price_new = ifelse(sold_date_new == "", NA, price_new)
				)
	# need to first check if url is unique

	total <- length(unique(data$url))
	unfinish <- length(unique(data[is.na(data$sold_date_new),]$url))
	finish <- total-unfinish
	finish_rate <- 1- unfinish/total

	p <- proc.time()
	for(i in 1:20000) {
	if(sum(is.na(data$sold_date_new))==0){
	break
	}
	url <- filter(data, is.na(sold_date_new))$url[1]
	hist <- read_html(url)
	hist <- html_node(hist, "#property-history-transition-node > div > table")
	hist <- html_table(hist)
	names(hist) <- c("sold_date_new_temp", "event", "price_new_temp", "note")
	hist$note <- NULL
	hist <- filter(hist, grepl("Sold (Public Records)", event, fixed="TRUE") | grepl("Sold (MLS) (Closed Sale)", event, fixed="TRUE") )
	hist$event <- NULL
	hist <- hist[!duplicated(hist),]
	if(dim(hist)[1]>0){ 
	hist$url <- url
	}
	if(dim(hist)[1]==0){ 
	hist <- data.frame(sold_date_new_temp = "pending", price_new_temp = "pending", url = url, stringsAsFactors=FALSE)
	}
	data <- left_join(data, hist, by= "url")
	data$sold_date_new  <- ifelse(is.na(data$sold_date_new_temp), data$sold_date_new, data$sold_date_new_temp )
	data$price_new  <- ifelse(is.na(data$price_new_temp), data$price_new, data$price_new_temp )
	data$sold_date_new_temp <- NULL
	data$price_new_temp <- NULL
	}
	p - proc.time()

	# output 
	fwrite(data, paste0(outpath, "el_monte_step2.csv"))





















