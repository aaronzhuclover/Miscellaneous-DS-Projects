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
library(randomForestSRC)
library(rpart)
library(rattle)

#**********************************************************************************************************
# Preparing and exploring the data
data(iris)
# look at the dataset
summary(iris)
# visually look at the dataset
qplot(Petal.Length,Petal.Width,colour=Species,data=iris)


# we will divide the population in two sets: Training and validation. 
train.flag <- createDataPartition(y=iris$Species,p=0.5,list=FALSE)
training <- iris[train.flag,]
Validation <- iris[-train.flag,]

# Building a CART model 
modfit <- train(Species~.,method="rpart",data=training) 
fancyRpartPlot(modfit$finalModel)

#  Validating the model 
train.cart<-predict(modfit,newdata=training)
table(train.cart,training$Species)


pred.cart<-predict(modfit,newdata=Validation)
table(pred.cart,Validation$Species)

correct <- pred.cart == Validation$Species
qplot(Petal.Length,Petal.Width,colour=correct,data=Validation)


#**********************************************************************************************************
# randomForest

# randomForest on training set 
modfit <- train(Species~ .,method="rf",data=training)
# predict on training set 
pred <- predict(modfit,training)
table(pred,training$Species)

# predict on Validation set
train.cart<-predict(modfit,newdata=Validation)
table(train.cart,Validation$Species)




































