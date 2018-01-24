# Author: Aaron Zhu

#***********************************************************************************************
inpath <- ".../"
outpath <- ".../market_shr/"
#***********************************************************************************************
i <- 1
for(f in c("cream", "gel", "oint") ){
wb <- loadWorkbook(paste0(inpath, "drug_005_",f ,".xls"))
sheets <- names(getSheets(wb))
for(sh in sheets){
tmp <- read.xlsx(paste0(inpath, "drug_005_",f ,".xls"), sheetName= sh)
names(tmp) <- gsub("\\.", "_",  tolower(names(tmp)))
# reshape data from wide form to long form
tmp <- reshape(tmp, 
          varying = 2:dim(tmp)[2],
		  v.names = paste0(f,"_",sh),
		  timevar = "mfr",
		  time = names(tmp)[2:dim(tmp)[2]],
		  direction = "long", 
)
row.names(tmp) <- 1:dim(tmp)[1]
tmp$id <- NULL
if(i ==1){
data <- tmp 
}
if(i >1){
data <- left_join(data, tmp, by = c("date","mfr"))
}
i <- i +1
}
}
data[is.na(data)] <- 0
master <- data
#**********************************
data <- filter(data, mfr %in% c("company3", "company2", "company1") )
data <- mutate(data, int_mbs_dollars = cream_int_mbs_dollars + gel_int_mbs_dollars + oint_int_mbs_dollars)
data <- mutate(data, date1 = as.Date(paste0(year(date), "-", month(date), "-01"))  )
#**********************************

jpeg(paste0(outpath, paste0( "drug_int_mbs_byMfr.jpeg")), width=2000, height=1500)
ggplot(data = data, aes(x= date)) +
geom_bar(aes(weight = int_mbs_dollars, fill=factor(mfr, levels=c("company3", "company2", "company1" )))) +
scale_fill_manual(labels = c("Mayne     ", "Taro     ", "Teva     "), name = " ", values = c("chartreuse4", "chocolate3", "deepskyblue4"))  +
xlab("Month") + 
ylab("") + 
scale_x_date(date_breaks = "3 month", date_labels = "%y-%m" ,  limits = c(as.Date("2012-01-31"),as.Date("2017-06-30")))  +
labs(subtitle=paste0("Integrated Manufacturer's Benchmark Sales by Manufacturer and Year") , title = "Generic drug, 0.05%" , caption = "Sources: BI/Symphony \n Includes cream, ointment and gel" ) +
theme(legend.position = "bottom", plot.title = element_text(hjust = 0.5, size=46), plot.subtitle = element_text(hjust = 0.5, size=34), plot.caption = element_text(size=28), axis.text=element_text(size=24) , axis.title=element_text(size=30), legend.text = element_text(size=30), legend.title=element_text(size=24)) + 
scale_y_continuous(breaks =seq(0,35*10^6,5*10^6), labels =scales::dollar_format(), limits = c(0, 35*10^6)) 
dev.off()









#***********************************************************************************************

















