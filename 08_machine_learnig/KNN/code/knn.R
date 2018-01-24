# clear workspace
rm(list = ls())

#**********************************************************************************************************
# Preparing and exploring the data
inpath <- "C:/Users/Aaron_clover/Desktop/HEG_folder/_interview_prep/08_machine_learnig/KNN/data/"
prc <- read.csv(paste0(inpath, "Prostate_Cancer.csv"),stringsAsFactors = FALSE)   
str(prc)
#***********
> str(prc)
'data.frame':	100 obs. of  10 variables:
 $ diagnosis_result : chr  "M" "B" "M" "M" ...
 $ radius           : int  23 9 21 14 9 25 16 15 19 25 ...
 $ texture          : int  12 13 27 16 19 25 26 18 24 11 ...
 $ perimeter        : int  151 133 130 78 135 83 120 90 88 84 ...
 $ area             : int  954 1326 1203 386 1297 477 1040 578 520 476 ...
 $ smoothness       : num  0.143 0.143 0.125 0.07 0.141 0.128 0.095 0.119 0.127 0.119 ...
 $ compactness      : num  0.278 0.079 0.16 0.284 0.133 0.17 0.109 0.165 0.193 0.24 ...
 $ symmetry         : num  0.242 0.181 0.207 0.26 0.181 0.209 0.179 0.22 0.235 0.203 ...
 $ fractal_dimension: num  0.079 0.057 0.06 0.097 0.059 0.076 0.057 0.075 0.074 0.082 ...
 $ diagnosis        : Factor w/ 2 levels "Benign","Malignant": 2 1 2 2 2 1 2 2 2 2 ...
> 

#removes the first variable(id) from the data set.
prc <- prc[-1]  
# it helps us to get the numbers of patients
table(prc$diagnosis_result)  
prc$diagnosis <- factor(prc$diagnosis_result, levels = c("B", "M"), labels = c("Benign", "Malignant"))
# it gives the result in the percentage form rounded of to 1 decimal place( and so it’s digits = 1)
round(prop.table(table(prc$diagnosis)) * 100, digits = 1)  

#**********************************************************************************************************
# Normalizing numeric data
normalize <- function(x) {
return ((x - min(x)) / (max(x) - min(x))) }
prc_n <- as.data.frame(lapply(prc[2:9], normalize))
summary(prc_n$radius)

#**********************************************************************************************************
# Creating training and test data set
# We shall divide the prc_n data frame into prc_train and prc_test data frames
prc_train <- prc_n[1:65,]
prc_test <- prc_n[66:100,]

prc_train_labels <- prc[1:65, 1]
#This code takes the diagnosis factor in column 1 of the prc data frame and on turn creates prc_train_labels and prc_test_labels data frame.
prc_test_labels <- prc[66:100, 1]   

#**********************************************************************************************************
# Training a model on data
library(class)
# The value for k is generally chosen as the square root of the number of observations.
prc_test_pred <- knn(train = prc_train, test = prc_test,cl = prc_train_labels, k=10)

#**********************************************************************************************************
# Evaluate the model performance
library(gmodels)
CrossTable(x = prc_test_labels, y = prc_test_pred, prop.chisq=FALSE)


#**********************
# result 
Total Observations in Table:  35 

 
                | prc_test_pred 
prc_test_labels |         B |         M | Row Total | 
----------------|-----------|-----------|-----------|
              B |         6 |        13 |        19 | 
                |     2.310 |     0.478 |           | 
                |     0.316 |     0.684 |     0.543 | 
                |     1.000 |     0.448 |           | 
                |     0.171 |     0.371 |           | 
----------------|-----------|-----------|-----------|
              M |         0 |        16 |        16 | 
                |     2.743 |     0.567 |           | 
                |     0.000 |     1.000 |     0.457 | 
                |     0.000 |     0.552 |           | 
                |     0.000 |     0.457 |           | 
----------------|-----------|-----------|-----------|
   Column Total |         6 |        29 |        35 | 
                |     0.171 |     0.829 |           | 
----------------|-----------|-----------|-----------|














