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
data <- mutate(data,
        int_units = cream_int_units + gel_int_units + oint_int_units, 
		trx_mbs_dollars = cream_trx_mbs_dollars + gel_trx_mbs_dollars + oint_trx_mbs_dollars, 
		yr = year(date)
)

data <- data %>%
            arrange(yr, mfr) %>%
			group_by(yr, mfr) %>%
			mutate(tot_int_units = sum(int_units, na.rm = T), 
			             tot_trx_mbs_dollars = sum(trx_mbs_dollars, na.rm = T)
			)

data <- select(data, yr , mfr, tot_int_units, tot_trx_mbs_dollars)
data <- data[!duplicated(data),]

data <- arrange(data, yr, -tot_int_units)			
			
data <- filter(data, !mfr == "total")		


data <- mutate(data, mfr1 = ifelse(mfr %in% c("company1", "company2", "company3") ,mfr ,"other" ))
	
data <- data %>%
            group_by(yr, mfr1) %>%
            mutate( int_units = sum(tot_int_units),
			             trx_mbs_dollars = sum(tot_trx_mbs_dollars)
			)			
			
data <- select(data, yr , mfr1, int_units, trx_mbs_dollars)			
data <- data[!duplicated(data),]
			
data <- data %>%
            group_by(yr) %>%
            mutate( int_units_shr = int_units/ sum(int_units)	   
			)		
names(data) <- gsub("mfr1", "mfr", names(data))			
data <- mutate(data, yr1 = ifelse(yr==2017, "Mid-2017" , as.character(yr)) )
data <- mutate(data, yr2 = ifelse(yr==2017, "2017-Pace" , as.character(yr)) )
data <- mutate(data, int_units_pace = ifelse(yr==2017, int_units*2, int_units )  )
data <- mutate(data, trx_mbs_dollars_pace = ifelse(yr==2017, trx_mbs_dollars*2, trx_mbs_dollars )  )
data <- mutate(data, label = paste0(round(int_units_shr,2)*100, "%" ))

#***************************************************************************************

jpeg(paste0(outpath, paste0( "drug_size_byVol.jpeg")), width=2000, height=1500)			
ggplot(data = data, aes(x= yr2)) +
geom_bar(aes(weight = int_units_pace, fill=factor(mfr, levels=c("other","company3", "company2", "company1" )))) +
scale_fill_manual(labels = c("Others     ", "company3     ", "company2     ", "company1     "), name = " ", values = c("darkgrey", "chartreuse4","chocolate3", "deepskyblue4"))  +
xlab("Year") + 
ylab("") + 
labs(subtitle=paste0("Prescription (Integrated) Units by Manufacturer and Year")  , title = "Generic drug, 0.05%", caption = "Source: BI/Symphony \n Graph includes cream, ointment and gel" )  +
theme(legend.position = "bottom", plot.title = element_text(hjust = 0.5, size=46), plot.subtitle = element_text(hjust = 0.5, size=34), plot.caption = element_text(size=28), axis.text=element_text(size=24) , axis.title=element_text(size=30), legend.text = element_text(size=30), legend.title=element_text(size=24)) +
scale_y_continuous(breaks =seq(0,16*10^7,2*10^7), labels = scales::comma, limits = c(0, 16*10^7))
dev.off()	

#***************************************************************************************
jpeg(paste0(outpath, paste0( "drug_size_byDol.jpeg")), width=2000, height=1500)					
ggplot(data = data, aes(x= yr2)) +
geom_bar(aes(weight = trx_mbs_dollars_pace, fill=factor(mfr, levels=c("other","company3", "company2", "company1" )))) +
scale_fill_manual(labels = c("Others     ", "company3     ", "company2     ", "company1     "), name = " ", values = c("darkgrey", "chartreuse4", "chocolate3", "deepskyblue4"))  +
xlab("Year") + 
ylab("") + 
labs(subtitle=paste0("Prescription Dollars by Manufacturer and Year") , title = "Generic drug, 0.05%" , caption = "Source: BI/Symphony \n Graph includes cream, ointment and gely" ) +
theme(legend.position = "bottom", plot.title = element_text(hjust = 0.5, size=46), plot.subtitle = element_text(hjust = 0.5, size=34), plot.caption = element_text(size=28), axis.text=element_text(size=24) , axis.title=element_text(size=30), legend.text = element_text(size=30), legend.title=element_text(size=24)) + 
scale_y_continuous( breaks =seq(0,3*10^8,1*10^8), labels =scales::dollar_format()) 
dev.off()		

#***************************************************************************************
jpeg(paste0(outpath, paste0( "drug_shr_byVol.jpeg")), width=2000, height=1500)			
ggplot(data = data, aes(x= yr1, y = int_units_shr, fill=factor(mfr, levels=c("other","company3", "company2", "company1" )), label =  label  )) +				
geom_bar(stat = "identity") +
scale_fill_manual(labels = c("Others     ", "company3     ", "company2     ", "company1     "), name = " ", values = c("darkgrey", "chartreuse4","chocolate3", "deepskyblue4"))  +
geom_text(size = 10, position = position_stack(vjust = 0.5)) +
xlab("Year") + 
ylab("") + 
labs(subtitle=paste0("Prescription (Integrated) Unit Shares by Manufacturer and Year")  , title = "Generic drug, 0.05%", caption = "Source: BI/Symphony \n Graph includes cream, ointment and gel")  +
theme(legend.position = "bottom", plot.title = element_text(hjust = 0.5, size=46), plot.subtitle = element_text(hjust = 0.5, size=34), plot.caption = element_text(size=28), axis.text=element_text(size=24) , axis.title=element_text(size=30), legend.text = element_text(size=30), legend.title=element_text(size=24)) +
scale_y_continuous(breaks =seq(0,1,0.1) , labels = scales::percent) 
dev.off()			
					
					




































