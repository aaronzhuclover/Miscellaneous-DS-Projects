	# Author: Aaron Zhu 
	# step 1: get all the zipcode in CA from http://www.zipcodestogo.com/California/ 
	# step 2: get the correponding regionid (redfin internal use) from redfin for a given zipcode from https://www.redfin.com/zipcode/[zipcode]
	# step 3: download all the sale record in redfin for a given zipcode from "https://www.redfin.com/stingray/api/gis-csv?al=3&market=socal&num_homes=3500000&ord=redfin-recommended-asc&page_number=1&region_id=", [regionid] ,"&region_type=2&sf=1,2,3,4,5,6,7&sold_within_days=36500&sp=true&status=9&uipt=1,2,3,4,5,6&v=8"

	#****************************************************************************
	# clear workspace
	rm(list = ls())

	library(data.table)
	library(RCurl)
	library(rvest)
	library(dplyr)
	#************************************************************
	outpath <- ".../redfin/out/"
	#*************************************************************
	# get all the zipcode in california
	list <- read_html("http://www.zipcodestogo.com/California/") %>%
		html_node("table") %>%
		html_table( fill = T)
	all_zip <- list$X1[4: length(list$X1)]

	for(zip in all_zip){
	p <- proc.time()
	# get the correponding regionid from redfin for a given zipcode 
	data <- read_html(paste0("https://www.redfin.com/zipcode/" , zip )) 
	data1 <- as.character(data)
	library(stringr)
	num_loc <- str_locate(data1, "regionId=.*regionType")
	a <- str_sub(data1, num_loc[, "start"], num_loc[, "end"])
	start <- str_locate(a, "=")[1]+1
	end <- str_locate(a, "&")[1]-1
	a <- str_sub(a, start, end)
	rm(num_loc, data, data1, end, start)
	#*********************************************************
	# get information of saling house for a given zipcode
	url <- paste0("https://www.redfin.com/stingray/api/gis-csv?al=3&market=socal&num_homes=3500000&ord=redfin-recommended-asc&page_number=1&region_id=", a ,"&region_type=2&sf=1,2,3,4,5,6,7&sold_within_days=36500&sp=true&status=9&uipt=1,2,3,4,5,6&v=8")
	myfile <- getURL(url, ssl.verifyhost=FALSE, ssl.verifypeer=FALSE)
	data <- read.csv(textConnection(myfile), header=T)
	rm(a, myfile)

	if(dim(data)[2]==1 ){
	data <- fread(url)
	}
	if(dim(data)[2]>1 ){
	fwrite(data, paste0(outpath, zip,".csv"))
	}
	proc.time() - p
	}
	#*********************************************************








