# clear workspace
rm(list = ls())


# load packages 
library(openxlsx)
# library(plyr)   # used only if neccesay (like rbind.fill), it will mess up functions in dplyr
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
library(sandwich)  # robust error
library(lmtest)
library(stats)
library(AICcmodavg)
library(foreach)   
library(iterators)
library(parallel)
library(doParallel)
library(lazyeval)
library(grid)  # for graph
library(gridExtra) # for graph
library(lubridate)  # date
library(lattice)
library(caret)  # for cart analysis
library(e1071)
library(randomForest)
library(rpart)

#**********************************************************************************************************
# Preparing and exploring the data
inpath <- "C:/Users/Aaron_clover/Desktop/HEG_folder/_interview_prep/08_machine_learnig/caret/data/"

#Loading training data
train<-read.csv(paste0(inpath,"train_u6lujuX_CVtuZ9i.csv"),stringsAsFactors = T)

# Pre-processing using Caret
sum(is.na(train))
#Imputing missing values using KNN.Also centering and scaling numerical columns
# "center","scale" -> standardized data
# "knnImpute" -> used KNN to fill in missing value
preProcValues <- preProcess(train, method = c("knnImpute","center","scale"))

library('RANN')
train_processed <- predict(preProcValues, train)
sum(is.na(train_processed))

#Converting outcome variable to numeric
train_processed$Loan_Status<-ifelse(train_processed$Loan_Status=='N',0,1)

id<-train_processed$Loan_ID
train_processed$Loan_ID<-NULL

#Converting every categorical variable to numerical using dummy variables
dmy <- dummyVars(" ~ .", data = train_processed,fullRank = T)
train_transformed <- data.frame(predict(dmy, newdata = train_processed))

#Converting the dependent variable back to categorical
train_transformed$Loan_Status<-as.factor(train_transformed$Loan_Status)

# Splitting data using caret
# We’ll be creating a cross-validation set from the training set to evaluate our model against. It is important to rely more on the cross-validation set for the actual evaluation of your model otherwise you might end up overfitting the public leaderboard.

# Spliting training set into two parts based on outcome: 75% and 25%
index <- createDataPartition(train_transformed$Loan_Status, p=0.75, list=FALSE)
trainSet <- train_transformed[ index,]
testSet <- train_transformed[-index,]

#Feature selection using rfe in caret
control <- rfeControl(functions = rfFuncs,
                   method = "repeatedcv",
                   repeats = 3,
                   verbose = FALSE)
outcomeName<-'Loan_Status'
predictors<-names(trainSet)[!names(trainSet) %in% outcomeName]
Loan_Pred_Profile <- rfe(trainSet[,predictors], trainSet[,outcomeName],
                      rfeControl = control)
Loan_Pred_Profile
#Recursive feature selection
#Outer resampling method: Cross-Validated (10 fold, repeated 3 times)
#Resampling performance over subset size:
#  Variables Accuracy  Kappa AccuracySD KappaSD Selected
#4   0.7737 0.4127    0.03707 0.09962        
#8   0.7874 0.4317    0.03833 0.11168        
#16   0.7903 0.4527    0.04159 0.11526        
#18   0.7882 0.4431    0.03615 0.10812        
#The top 5 variables (out of 16):
#  Credit_History, LoanAmount, Loan_Amount_Term, ApplicantIncome, CoapplicantIncome
#Taking only the top 5 predictors
predictors<-c("Credit_History", "LoanAmount", "Loan_Amount_Term", "ApplicantIncome", "CoapplicantIncome")

# Training models using Caret
model_gbm<-train(trainSet[,predictors],trainSet[,outcomeName],method='gbm')
model_rf<-train(trainSet[,predictors],trainSet[,outcomeName],method='rf')
model_nnet<-train(trainSet[,predictors],trainSet[,outcomeName],method='nnet')
model_glm<-train(trainSet[,predictors],trainSet[,outcomeName],method='glm')

# continue...............
# https://www.analyticsvidhya.com/blog/2016/12/practical-guide-to-implement-machine-learning-with-caret-package-in-r-with-practice-problem/
# ..............

# Predictions using Caret
#Predictions
predictions<-predict.train(object=model_gbm,testSet[,predictors],type="raw")
table(predictions)






























