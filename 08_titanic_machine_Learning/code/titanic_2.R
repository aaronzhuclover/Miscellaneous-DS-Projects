	# PassengerID— A column added by Kaggle to identify each row and make submissions easier
	# Survived— Whether the passenger survived or not and the value we are predicting (0=No, 1=Yes)
	# Pclass—	The class of the ticket the passenger purchased (1=1st, 2=2nd, 3=3rd)
	# Sex— The passenger's sex
	# Age— The passenger's age in years
	# SibSp— The number of siblings or spouses the passenger had aboard the Titanic
	# Parch— The number of parents or children the passenger had aboard the Titanic
	# Ticket— The passenger's ticket number
	# Fare— The fare the passenger paid
	# Cabin— The passenger's cabin number
	# Embarked— The port where the passenger embarked (C=Cherbourg, Q=Queenstown, S=Southampton)


	# clear workspace
	rm(list = ls())

	# load library
	library(rpart)
	library(rpart.plot)
	library(rattle)
	library(RColorBrewer)
	library(dplyr)
	library(randomForest)
	library(party)
	library(ada)


	# path to data
	inpath <- "C:/Users/Aaron_clover/Desktop/HEG_folder/_interview_prep/_github/08_titanic_machine_Learning/data/"
	outpath <- "C:/Users/Aaron_clover/Desktop/HEG_folder/_interview_prep/_github/08_titanic_machine_Learning/out/"


	# import titanic data 
	data <- read.csv(paste0(inpath,"titanic.csv"))
	data <- data[!is.na(data$survived),]

	for(i in 1:2){
	data[,i] <- as.factor(data[,i])
	}
	data[,"name"] <- as.character(data[,"name"])
	data <- data %>%
			rename(Survived = survived, 
					Pclass  = pclass,
						Sex = sex,
						Age = age,
					  SibSp = sibsp,
					  Parch = parch,
					   Fare = fare,
				   Embarked = embarked,	
					   Name = name
			) 

	set.seed(123)
	index <- sample(1:dim(data)[1], 400)
	train <- data[-index,]
	 test <- data[index,]
	 
	 
	# run first classification tree 
	set.seed(123)
	tree <- rpart(Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked, data = train, control = rpart.control(cp = 0.0001))
	fancyRpartPlot(tree)
	# Pick the tree size that minimizes misclassification rate (i.e. prediction error).
	# Prediction error rate in training data = Root node error * rel error * 100%    = right prediction / total in training set 
	# Prediction error rate in cross-validation = Root node error * xerror * 100%
	# Hence we want the cp value (with a simpler tree) that minimizes the xerror. 

	# Each row represents a different height of the tree. In general, more levels in the tree mean that it has lower classification error on the training. However, you run the risk of overfitting. Often, the cross-validation error will actually grow as the tree gets more levels (at least, after the 'optimal' level).
				   
	printcp(tree)

	bestcp <- tree$cptable[which.min(tree$cptable[,"xerror"]),"CP"]
	# Prune the tree using the best cp.
	tree.pruned <- prune(tree, cp = bestcp)
	printcp(tree.pruned)
	# confusion matrix (training data)
	conf.matrix <- table(train$Survived, predict(tree.pruned, train, type="class"))
	rownames(conf.matrix) <- paste("Actual", rownames(conf.matrix), sep = ":")
	colnames(conf.matrix) <- paste("Pred", colnames(conf.matrix), sep = ":")
	print(conf.matrix)	
    # (510+222)/909 = 80.5% accuracy (training data)	
    tiff(paste0(outpath, "decision_tree.png"), width=1500, height=1200)	
	fancyRpartPlot(tree.pruned)
	dev.off()

	# confusion matrix (testing data)
	conf.matrix <- table(test$Survived, predict(tree.pruned, test, type="class"))
	rownames(conf.matrix) <- paste("Actual", rownames(conf.matrix), sep = ":")
	colnames(conf.matrix) <- paste("Pred", colnames(conf.matrix), sep = ":")
	print(conf.matrix)	
	# (202+114)/400 = 79% accuracy (testing data)


	#*****************************************************************************************************************************
	# Feature Engineering
	data$Title <- sapply(data$Name, FUN=function(x) {strsplit(x, split='[,.]')[[1]][2]})
	data$Title <- sub(' ', '', data$Title)
	data$Title[data$Title %in% c('Mme', 'Mlle')] <- 'Mlle'
	data$Title[data$Title %in% c('Capt', 'Don', 'Major', 'Sir')] <- 'Sir'
	data$Title[data$Title %in% c('Dona', 'Lady', 'the Countess', 'Jonkheer')] <- 'Lady'
	data$Title <- factor(data$Title)


	data$FamilySize <- data$SibSp + data$Parch + 1
	data$Surname <- sapply(data$Name, FUN=function(x) {strsplit(x, split='[,.]')[[1]][1]})
	data$FamilyID <- paste(as.character(data$FamilySize), data$Surname, sep="")
	data$FamilyID[data$FamilySize <= 2] <- 'Small'
	table(data$FamilyID)
	famIDs <- data.frame(table(data$FamilyID))
	famIDs <- famIDs[famIDs$Freq <= 2,]
	data$FamilyID[data$FamilyID %in% famIDs$Var1] <- 'Small'
	data$FamilyID <- factor(data$FamilyID)

	#*****************************************************************************************************************************
	# fill in the missing values
	# replace missing age with predict value using regression tree	   
	set.seed(123) 
	Agefit <- rpart(Age ~ Pclass + Sex + SibSp + Parch + Fare + Embarked + Title + FamilySize,
					  data=data[!is.na(data$Age),], 
					  method="anova")
	data$Age[is.na(data$Age)] <- predict(Agefit, data[is.na(data$Age),])
	# replace mising embarked with most frequently observed "S"		   
	data$Embarked[which(data$Embarked == '')] = "S"			   
	# replace missing fare with median fare for a given Embarked group		
	data <- data %>%
			group_by(Embarked) %>%
			mutate(Fare = ifelse(is.na(Fare), median(Fare, na.rm = TRUE), Fare )) %>%
			ungroup()			
	# increase small family to 3 people since random forest can only handel up to 32 factors   			   
	data$FamilyID2 <- data$FamilyID
	data$FamilyID2 <- as.character(data$FamilyID2)
	data$FamilyID2[data$FamilySize <= 3] <- 'Small'
	data$FamilyID2 <- factor(data$FamilyID2)
				   
	train <- data[-index,]
	 test <- data[index,]  

	#*****************************************************************************************************************************	
	# run classification tree after Feature Engineering + replace missing values 		
	set.seed(123)   
	tree <- rpart(Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked + Title + FamilySize + FamilyID,
				   data=train, 
				   method="class",control = rpart.control(cp = 0.0001))			   
	printcp(tree)
	bestcp <- tree$cptable[which.min(tree$cptable[,"xerror"]),"CP"]
	# Prune the tree using the best cp.
	tree.pruned <- prune(tree, cp = bestcp)
	printcp(tree.pruned)
	# confusion matrix (training data)
	conf.matrix <- table(train$Survived, predict(tree.pruned, train, type="class"))
	rownames(conf.matrix) <- paste("Actual", rownames(conf.matrix), sep = ":")
	colnames(conf.matrix) <- paste("Pred", colnames(conf.matrix), sep = ":")
	fancyRpartPlot(tree.pruned)
	print(conf.matrix)		   			   
	# (517+243)/909 = 83.6% accuracy (training data)

	# confusion matrix (testing data)
	conf.matrix <- table(test$Survived, predict(tree.pruned, test, type="class"))
	rownames(conf.matrix) <- paste("Actual", rownames(conf.matrix), sep = ":")
	colnames(conf.matrix) <- paste("Pred", colnames(conf.matrix), sep = ":")
	print(conf.matrix)	
	# (201+128)/400 = 82.2% accuracy (testing data)			   			 
	  
	#*****************************************************************************************************************************	
	# apply random forest (part 1)
	set.seed(123)
	# "importance=TRUE" argument allows us to inspect variable importance
	# "ntree" argument specifies how many trees we want to grow.
	fit <- randomForest(as.factor(Survived) ~ Pclass + Sex + Age + SibSp + Parch + Fare +
												Embarked + Title + FamilySize + FamilyID2,
						  data=train, 
						  importance=TRUE, 
						  ntree=2000)
	varImpPlot(fit)			   
				   
	# confusion matrix (training data)
	conf.matrix <- table(train$Survived, predict(fit,train, type="class"))
	rownames(conf.matrix) <- paste("Actual", rownames(conf.matrix), sep = ":")
	colnames(conf.matrix) <- paste("Pred", colnames(conf.matrix), sep = ":")
	print(conf.matrix)		   			   
	# (552+272)/ 909 = 90.6% accuracy (training data)		
		   
	# confusion matrix (testing data)
	conf.matrix <- table(test$Survived, predict(fit, test, type="class"))
	rownames(conf.matrix) <- paste("Actual", rownames(conf.matrix), sep = ":")
	colnames(conf.matrix) <- paste("Pred", colnames(conf.matrix), sep = ":")
	print(conf.matrix)
	# (211+119)/400 = 82.5% accuracy (testing data)	

	#*****************************************************************************************************************************
	# apply random forest (part 2)			   
	# Conditional inference trees are able to handle factors with more levels than Random Forests can		
	set.seed(123)	   
	fit <- cforest(as.factor(Survived) ~ Pclass + Sex + Age + SibSp + Parch + Fare +
										   Embarked + Title + FamilySize + FamilyID,
					 data = train, 
					 controls=cforest_unbiased(ntree=2000, mtry=3))			   

	# confusion matrix (training data)				 
	conf.matrix <- table(train$Survived, predict(fit, type="response"))
	rownames(conf.matrix) <- paste("Actual", rownames(conf.matrix), sep = ":")
	colnames(conf.matrix) <- paste("Pred", colnames(conf.matrix), sep = ":")
	print(conf.matrix)			   
	# (529+237)/ 909 = 84.3% accuracy (training data)		   
				   
	# confusion matrix (testing data)
	conf.matrix <- table(test$Survived, predict(fit, test, OOB=TRUE, type="response"))
	rownames(conf.matrix) <- paste("Actual", rownames(conf.matrix), sep = ":")
	colnames(conf.matrix) <- paste("Pred", colnames(conf.matrix), sep = ":")
	print(conf.matrix)
	# (208+122)/400 = 82.5% accuracy (testing data)	

	test_rf <- as.numeric(predict(fit, test, OOB=TRUE, type="response"))-1
				   
	#*****************************************************************************************************************************			   
	# apply adaboost
	set.seed(123)
	fit <- ada(as.factor(Survived) ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked + Title + FamilySize + FamilyID, data = train)

	# confusion matrix (training data)
	conf.matrix <- table(train$Survived, predict(fit, train))
	rownames(conf.matrix) <- paste("Actual", rownames(conf.matrix), sep = ":")
	colnames(conf.matrix) <- paste("Pred", colnames(conf.matrix), sep = ":")
	print(conf.matrix)			   
	# (536+259)/ 909 = 87.5% accuracy  (training data)			   
				   
	# confusion matrix (testing data)
	conf.matrix <- table(test$Survived, predict(fit, test))
	rownames(conf.matrix) <- paste("Actual", rownames(conf.matrix), sep = ":")
	colnames(conf.matrix) <- paste("Pred", colnames(conf.matrix), sep = ":")
	print(conf.matrix)			   
	# (208+125)/ 400 = 83.3% accuracy  (testing data)				   
				   
	test_boost <- as.numeric(predict(fit, test))-1
				   
	#*****************************************************************************************************************************				   
	# apply logistic regression 
	library(glmnet)
	key_var <- c("Survived", "Pclass", "Sex" , "Age", "SibSp", "Parch", "Fare", "Embarked", "Title", "FamilySize", "FamilyID")

	x <- model.matrix(Survived ~., data = train[,key_var])
	y <- train[,key_var]$Survived
	testx <- model.matrix(~., data = select(test[,key_var], - Survived)  )

	set.seed(123)
	fit_ridge <- cv.glmnet(x, y, alpha = 0, family = 'binomial', type.measure = 'deviance')

	train_pred <- predict(fit_ridge, newx = x, s = 'lambda.min', type='class')	
	test_pred <- predict(fit_ridge, newx = testx, s = 'lambda.min', type='class')			   
				   
	# confusion matrix (training data)
	conf.matrix <- table(train$Survived, train_pred)
	rownames(conf.matrix) <- paste("Actual", rownames(conf.matrix), sep = ":")
	colnames(conf.matrix) <- paste("Pred", colnames(conf.matrix), sep = ":")
	print(conf.matrix)			   
	# (521+245)/ 909 = 84.3% accuracy  (training data)			   
				   
	# confusion matrix (testing data)
	conf.matrix <- table(test$Survived, test_pred)
	rownames(conf.matrix) <- paste("Actual", rownames(conf.matrix), sep = ":")
	colnames(conf.matrix) <- paste("Pred", colnames(conf.matrix), sep = ":")
	print(conf.matrix)			   
	# (200+126)/ 400 = 81.5% accuracy  (testing data)			   
				   
	test_logi <- as.numeric(test_pred)			   
				   
				   
	#*****************************************************************************************************************************				   
	# apply ensemble 

	ensemble <- test_boost + test_logi + test_rf
	ensemble <- sapply(ensemble/3, round)

	conf.matrix <- table(test$Survived, ensemble)
	rownames(conf.matrix) <- paste("Actual", rownames(conf.matrix), sep = ":")
	colnames(conf.matrix) <- paste("Pred", colnames(conf.matrix), sep = ":")
	print(conf.matrix)
	# (206+128)/ 400 = 84% accuracy (testing data)
















			   
				   
				   
				   
