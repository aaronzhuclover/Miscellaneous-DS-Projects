# Author: Aaron Zhu
# task: convert unstructured raw data into structured data source
#         compare annual average production volume with capacity volume

# clear all variables 
rm(list=ls())
# Collect Information About the Current R Session
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
library(sandwich)     # robust error
library(lmtest)
library(stats)
library(AICcmodavg)
library(foreach)   
library(iterators)
library(parallel)
library(doParallel)
library(lazyeval)
library(grid)         # for graph
library(gridExtra)    # for graph
library(lubridate)    # date
library(data.table) 

#############################
### write my own function ###
#############################

# rtab()
# return frequency and percentage of all the unique values for a given variale
rtab <-function(x,sort=F){
  if(!sort){
    count <- as.vector(table(x,useNA = "a"))
  }else{
    count <- as.vector(sort(table(x,useNA = "a"),T))
  }
  per <- round(as.vector(count/length(x)),4)*100
  per1<- as.vector(count/length(x))*100
  cum <- round(cumsum(per1),2)
  matrix <- matrix(c(count,per,cum),ncol=3)
  if(!sort){
    rownames(matrix) <-names(table(x,useNA = "a"))
  }else{
    rownames(matrix) <-names(sort(table(x,useNA = "a"),T))
  }
  colnames(matrix) <- c("Freq.","Percent","Cum.")
  return <- matrix
  return(return)
}
# **************************************************************************************************************************
# rsum()
# return Summary statistics (percentile, min, max and avg) of a given variable 
rsum <- function(x){
  quantile <- quantile(x,c(0.01,0.05,0.1,0.25,0.5,0.75,0.9,0.95,0.99), na.rm = T)
  quantile <- round(quantile,4)
  stat_1   <- c(mean = round(mean(x, na.rm = T),4),
                sd   = round(sd(x, na.rm = T),4)
  )				
  stat_2   <- c(Obs  = length(x), 
                na   = sum(is.na(x)) 
  )
  smallest <- round(head(sort(x, decreasing = F), 5),4)
  names(smallest) <- c("smallest", "2nd", "3rd", "4th", "5th")
  largest <- round(head(sort(x, decreasing = T), 5),4)
  names(largest) <- c("largest", "2nd", "3rd", "4th", "5th")
  return <- list(quantile, stat_1, stat_2, smallest, largest)
  return(return)
}
# **************************************************************************************************************************
# ds var* *var1* 
# display variables using regular expression
rds <- function(x,y){
  return <- names(x)[grepl(y, names(x))]
  return(return)
}
# **************************************************************************************************************************
# order var* 
# reallocate variables to the beginning of dataset 
rorder <- function(x,y){
  other <- setdiff(names(x), y)
  return(x[,c(y,other)])
}

# **************************************************************************************************************************
inpath <- ".../01_graph_cntb/data/"
outpath <- ".../01_graph_cntb/out/"
# **************************************************************************************************************************
#*********
# create shaded areas for price increasing events
min <- c("2004-03-01", "2004-06-01", "2005-04-01", "2005-10-01", "2006-01-01", "2006-04-01", "2007-01-01", "2007-05-01", "2007-08-01")
min <- c(min, "2008-03-01", "2008-07-01", "2008-10-01", "2010-01-01", "2010-04-01", "2010-08-01")
min <- as.Date(min)
max <- min
month(max) <- month(max) + 1 
shade = data.frame(x1=min, x2=max, y1=rep(-Inf, 15), y2=rep(Inf, 15) , s = c(1,1,0,1,1,1,0,0,1,0,1,0,1,1,0))
# **************************************************************************************************************************
# import AB data 
data <- as.data.frame(read.xlsx(paste0(inpath, "ab.xlsx"), sheet = 1, colNames = FALSE))
names(data) <- gsub("X","x",names(data))
# extract production and capacity data 
pro <- data[grep("Production", data$x2),]
cap <- data[grep("Capacity", data$x2),]

#****************************************************************************************
# capacity
# reshape the data from wide form to long form 
cap$x1 <- 1:dim(cap)[1]
add<- as.data.frame(matrix(NA, nrow = dim(cap), ncol = 3))
add <- cbind(cap[,1:2], add)
names(add) <- names(cap)
cap <- rbind(cap , add, add)

cap <- arrange(cap, x1, x3)
cap $n <- 1
cap <- cap %>%
           group_by(x1) %>%
		   mutate(n = cumsum(n))
cap <- cap %>%
           group_by(x1) %>%
		   mutate(x4 = head(x4,1), x5 = head(x5,1))
cap <- mutate(cap, x3 = ifelse(n ==2 , x4 , x3) ,  x3 = ifelse(n ==3 , x5 , x3) )
cap <- select(cap, -x4, -x5)

cap$ym = NA
cap <- mutate(cap, 
                       ym = ifelse(x1 == 1 & n ==1  , as.Date("2003-12-01") , ym),
					   ym = ifelse(x1 == 1 & n ==2  , as.Date("2004-01-01") , ym),
					   ym = ifelse(x1 == 1 & n ==3  , as.Date("2004-02-01") , ym),
					   ym = ifelse(x1 == 3 & n ==1  , as.Date("2004-03-01") , ym),
					   ym = ifelse(x1 == 3 & n ==2  , as.Date("2004-04-01") , ym),
					   ym = ifelse(x1 == 3 & n ==3  , as.Date("2004-05-01") , ym),
					   ym = ifelse(x1 == 5 & n ==1  , as.Date("2005-01-01") , ym),
					   ym = ifelse(x1 == 5 & n ==2  , as.Date("2005-02-01") , ym),
					   ym = ifelse(x1 == 5 & n ==3  , as.Date("2005-03-01") , ym),
					   ym = ifelse(x1 == 7 & n ==1  , as.Date("2005-08-01") , ym),
					   ym = ifelse(x1 == 7 & n ==2  , as.Date("2005-09-01") , ym),
					   ym = ifelse(x1 == 7 & n ==3  , as.Date("2005-10-01") , ym),
					   ym = ifelse(x1 == 9 & n ==1  , as.Date("2005-11-01") , ym),
					   ym = ifelse(x1 == 9 & n ==2  , as.Date("2005-12-01") , ym),
					   ym = ifelse(x1 == 9 & n ==3  , as.Date("2006-01-01") , ym),
					   ym = ifelse(x1 == 11 & n ==1  , as.Date("2006-01-01") , ym),
					   ym = ifelse(x1 == 11 & n ==2  , as.Date("2006-02-01") , ym),
					   ym = ifelse(x1 == 11 & n ==3  , as.Date("2006-03-01") , ym),
					   ym = ifelse(x1 == 13 & n ==1  , as.Date("2006-10-01") , ym),
					   ym = ifelse(x1 == 13 & n ==2  , as.Date("2006-11-01") , ym),
					   ym = ifelse(x1 == 13 & n ==3  , as.Date("2006-12-01") , ym),
					   ym = ifelse(x1 == 15 & n ==1  , as.Date("2007-03-01") , ym),
					   ym = ifelse(x1 == 15 & n ==2  , as.Date("2007-04-01") , ym),
					   ym = ifelse(x1 == 15 & n ==3  , as.Date("2007-05-01") , ym),
					   ym = ifelse(x1 == 17 & n ==1  , as.Date("2007-06-01") , ym),
					   ym = ifelse(x1 == 17 & n ==2  , as.Date("2007-07-01") , ym),
					   ym = ifelse(x1 == 17 & n ==3  , as.Date("2007-08-01") , ym),
					   ym = ifelse(x1 == 19 & n ==1  , as.Date("2008-01-01") , ym),
					   ym = ifelse(x1 == 19 & n ==2  , as.Date("2008-02-01") , ym),
					   ym = ifelse(x1 == 19 & n ==3  , as.Date("2008-03-01") , ym),
					   ym = ifelse(x1 == 21 & n ==1  , as.Date("2008-04-01") , ym),
					   ym = ifelse(x1 == 21 & n ==2  , as.Date("2008-05-01") , ym),
					   ym = ifelse(x1 == 21 & n ==3  , as.Date("2008-06-01") , ym),
					   ym = ifelse(x1 == 23 & n ==1  , as.Date("2008-08-01") , ym),
					   ym = ifelse(x1 == 23 & n ==2  , as.Date("2008-09-01") , ym),
					   ym = ifelse(x1 == 23 & n ==3  , as.Date("2008-10-01") , ym),
					   ym = ifelse(x1 == 25 & n ==1  , as.Date("2009-10-01") , ym),
					   ym = ifelse(x1 == 25 & n ==2  , as.Date("2009-11-01") , ym),
					   ym = ifelse(x1 == 25 & n ==3  , as.Date("2009-12-01") , ym),
					   ym = ifelse(x1 == 27 & n ==1  , as.Date("2010-01-01") , ym),
					   ym = ifelse(x1 == 27 & n ==2  , as.Date("2010-02-01") , ym),
					   ym = ifelse(x1 == 27 & n ==3  , as.Date("2010-03-01") , ym),
					   ym = ifelse(x1 == 29 & n ==1  , as.Date("2010-05-01") , ym),
					   ym = ifelse(x1 == 29 & n ==2  , as.Date("2010-06-01") , ym),
					   ym = ifelse(x1 == 29 & n ==3  , as.Date("2010-07-01") , ym)					   
					   )

cap$ym <- as.Date(cap$ym)
cap$yr <- year(cap$ym)
cap$mth <- month(cap$ym)
cap <- filter(cap, !is.na(x3) )

cap1 <- as.data.frame(matrix(c(rep(2003,12), 1:12), ncol = 2))
for(i in 2004:2010) {
cap1 <- rbind(cap1, as.data.frame(matrix(c(rep(i,12), 1:12), ncol = 2)))
}
names(cap1) <- c("yr", "mth")

cap1 <- merge(cap1 , cap , by = c("yr", "mth"), all.x = TRUE )
cap1 <- select(cap1, yr, mth, x3, ym)
# fill in the missing data with average value 
cap1[18:24,"x3"] = cap[8, "x3"]
cap1[28:31,"x3"] = cap[12, "x3"]
cap1[41:46,"x3"] = cap[14, "x3"]
cap1[50:51,"x3"] = cap[24, "x3"]
cap1[58:61,"x3"] = cap[28, "x3"]
cap1[68,"x3"] = cap[36, "x3"]
cap1[72:82,"x3"] = cap[44, "x3"]
cap1[89,"x3"] = cap[48, "x3"]
cap1[18:24,"x3"] = cap[52, "x3"]
cap1[18:24,"x3"] = cap[56, "x3"]

cap1$ym <- as.Date(paste0(cap1$yr, "-", cap1$mth,"-1" ))
cap <- cap1
names(cap)[names(cap)=="x3"] = "cap"
cap <- filter(cap, !is.na(cap))
# convert cap from string to integer
cap$cap <- strtoi(cap$cap)

#****************************************************************************************
# production
pro$x1 <- 1:dim(pro)[1]
add<- as.data.frame(matrix(NA, nrow = dim(pro), ncol = 3))
add <- cbind(pro[,1:2], add)
names(add) <- names(pro)
pro <- rbind(pro , add, add)

pro <- arrange(pro, x1, x3)
pro $n <- 1
pro <- pro %>%
           group_by(x1) %>%
		   mutate(n = cumsum(n))
pro <- pro %>%
           group_by(x1) %>%
		   mutate(x4 = head(x4,1), x5 = head(x5,1))
pro <- mutate(pro, x3 = ifelse(n ==2 , x4 , x3) ,  x3 = ifelse(n ==3 , x5 , x3) )
pro <- select(pro, -x4, -x5)

pro$ym = NA
pro <- mutate(pro, 
                       ym = ifelse(x1 == 1 & n ==1  , as.Date("2003-12-01") , ym),
					   ym = ifelse(x1 == 1 & n ==2  , as.Date("2004-01-01") , ym),
					   ym = ifelse(x1 == 1 & n ==3  , as.Date("2004-02-01") , ym),
					   ym = ifelse(x1 == 3 & n ==1  , as.Date("2004-03-01") , ym),
					   ym = ifelse(x1 == 3 & n ==2  , as.Date("2004-04-01") , ym),
					   ym = ifelse(x1 == 3 & n ==3  , as.Date("2004-05-01") , ym),
					   ym = ifelse(x1 == 5 & n ==1  , as.Date("2005-01-01") , ym),
					   ym = ifelse(x1 == 5 & n ==2  , as.Date("2005-02-01") , ym),
					   ym = ifelse(x1 == 5 & n ==3  , as.Date("2005-03-01") , ym),
					   ym = ifelse(x1 == 7 & n ==1  , as.Date("2005-08-01") , ym),
					   ym = ifelse(x1 == 7 & n ==2  , as.Date("2005-09-01") , ym),
					   ym = ifelse(x1 == 7 & n ==3  , as.Date("2005-10-01") , ym),
					   ym = ifelse(x1 == 9 & n ==1  , as.Date("2005-11-01") , ym),
					   ym = ifelse(x1 == 9 & n ==2  , as.Date("2005-12-01") , ym),
					   ym = ifelse(x1 == 9 & n ==3  , as.Date("2006-01-01") , ym),
					   ym = ifelse(x1 == 11 & n ==1  , as.Date("2006-01-01") , ym),
					   ym = ifelse(x1 == 11 & n ==2  , as.Date("2006-02-01") , ym),
					   ym = ifelse(x1 == 11 & n ==3  , as.Date("2006-03-01") , ym),
					   ym = ifelse(x1 == 13 & n ==1  , as.Date("2006-10-01") , ym),
					   ym = ifelse(x1 == 13 & n ==2  , as.Date("2006-11-01") , ym),
					   ym = ifelse(x1 == 13 & n ==3  , as.Date("2006-12-01") , ym),
					   ym = ifelse(x1 == 15 & n ==1  , as.Date("2007-03-01") , ym),
					   ym = ifelse(x1 == 15 & n ==2  , as.Date("2007-04-01") , ym),
					   ym = ifelse(x1 == 15 & n ==3  , as.Date("2007-05-01") , ym),
					   ym = ifelse(x1 == 17 & n ==1  , as.Date("2007-06-01") , ym),
					   ym = ifelse(x1 == 17 & n ==2  , as.Date("2007-07-01") , ym),
					   ym = ifelse(x1 == 17 & n ==3  , as.Date("2007-08-01") , ym),
					   ym = ifelse(x1 == 19 & n ==1  , as.Date("2008-01-01") , ym),
					   ym = ifelse(x1 == 19 & n ==2  , as.Date("2008-02-01") , ym),
					   ym = ifelse(x1 == 19 & n ==3  , as.Date("2008-03-01") , ym),
					   ym = ifelse(x1 == 21 & n ==1  , as.Date("2008-04-01") , ym),
					   ym = ifelse(x1 == 21 & n ==2  , as.Date("2008-05-01") , ym),
					   ym = ifelse(x1 == 21 & n ==3  , as.Date("2008-06-01") , ym),
					   ym = ifelse(x1 == 23 & n ==1  , as.Date("2008-08-01") , ym),
					   ym = ifelse(x1 == 23 & n ==2  , as.Date("2008-09-01") , ym),
					   ym = ifelse(x1 == 23 & n ==3  , as.Date("2008-10-01") , ym),
					   ym = ifelse(x1 == 25 & n ==1  , as.Date("2009-10-01") , ym),
					   ym = ifelse(x1 == 25 & n ==2  , as.Date("2009-11-01") , ym),
					   ym = ifelse(x1 == 25 & n ==3  , as.Date("2009-12-01") , ym),
					   ym = ifelse(x1 == 27 & n ==1  , as.Date("2010-01-01") , ym),
					   ym = ifelse(x1 == 27 & n ==2  , as.Date("2010-02-01") , ym),
					   ym = ifelse(x1 == 27 & n ==3  , as.Date("2010-03-01") , ym),
					   ym = ifelse(x1 == 29 & n ==1  , as.Date("2010-05-01") , ym),
					   ym = ifelse(x1 == 29 & n ==2  , as.Date("2010-06-01") , ym),
					   ym = ifelse(x1 == 29 & n ==3  , as.Date("2010-07-01") , ym)					   
					   )

pro$ym <- as.Date(pro$ym)
pro$yr <- year(pro$ym)
pro$mth <- month(pro$ym)
pro <- filter(pro, !is.na(x3) )

pro1 <- as.data.frame(matrix(c(rep(2003,12), 1:12), ncol = 2))
for(i in 2004:2010) {
pro1 <- rbind(pro1, as.data.frame(matrix(c(rep(i,12), 1:12), ncol = 2)))
}
names(pro1) <- c("yr", "mth")

pro1 <- merge(pro1 , pro , by = c("yr", "mth"), all.x = TRUE )
pro1 <- select(pro1, yr, mth, x3, ym)
pro1[18:24,"x3"] = pro[8, "x3"]
pro1[28:31,"x3"] = pro[12, "x3"]
pro1[41:46,"x3"] = pro[14, "x3"]
pro1[50:51,"x3"] = pro[24, "x3"]
pro1[58:61,"x3"] = pro[28, "x3"]
pro1[68,"x3"] = pro[36, "x3"]
pro1[72:82,"x3"] = pro[44, "x3"]
pro1[89,"x3"] = pro[48, "x3"]
pro1[18:24,"x3"] = pro[52, "x3"]
pro1[18:24,"x3"] = pro[56, "x3"]

pro1$ym <- as.Date(paste0(pro1$yr, "-", pro1$mth,"-1" ))
pro <- pro1
names(pro)[names(pro)=="x3"] = "pro"
pro <- filter(pro, !is.na(pro))
pro$pro <- strtoi(pro$pro)
pro <- select(pro, -yr, -mth )
# join production with capacity data 
data <- merge(pro, cap , by = "ym", all.x= T )
# compute annual production and capacity 
data <- data %>%
           arrange(ym) %>%
		   group_by(yr) %>%
		   mutate(pro_avg = mean(pro, na.rm = TRUE), cap_avg = mean(cap, na.rm = TRUE))
data_ab <- data

#*********
# export the graph 
tiff(paste0(outpath, "Company_pro_cap.tiff"), width=1500, height=1200)
ggplot() + 
geom_rect(data=shade[shade$s==1,], mapping=aes(xmin=x1, xmax=x2, ymin=y1, ymax=y2, fill = "success"), alpha=0.3) + 
geom_rect(data=shade[shade$s==0,], mapping=aes(xmin=x1, xmax=x2, ymin=y1, ymax=y2, fill = "unsuccess"), alpha=0.6) + 
geom_line(data = data, aes(x= ym, y=pro_avg/1000, color = "c1"), size = 2) + 
geom_line(data = data, aes(x= ym, y=cap_avg/1000, color = "c2"), size = 2) + 
scale_x_date(date_breaks= "2 year", date_labels = "%Y-%m", limits = c(as.Date("2003-01-01"),as.Date("2010-12-01")) ) + 
scale_fill_manual(labels=c("Successful Price Increase Events", "Unsuccessful Price Increase Events"), name = " ", values=c("blue", "grey")) + 
xlab("Month") + 
ylab("Thousands of Tons per Month") + 
labs(title="Annual Average Production & Capacity")  +
theme(legend.position = "bottom", plot.title = element_text(size=46, hjust = 0.5), axis.text=element_text(size=24) , axis.title=element_text(size=30), , plot.subtitle = element_text( size=28), legend.text = element_text(size=30))  +
scale_color_manual(labels = c("Production", "Capacity"), name = " ", values = c("blue", "red"))  +
guides(fill=guide_legend(nrow=2), color =guide_legend(nrow=2) ) +
scale_y_continuous(limits = c(0,500), breaks= seq(0,500,100) , expand = c(0,0) )
dev.off()

fwrite(data_ab, paste0(inpath, "structured_data.csv"))










