# clear all variables 
rm(list=ls())
library(tidyverse)

inpath <- ".../data/"
outpath <- ".../out/"
# Read data
train <- read.csv(paste0(inpath, "training_set.csv") , header = T)
test_d <- read.csv(paste0(inpath, "testing_data.csv") , header = T)
test_d <- rename(test_d , Fraud = Fraudulent )

#######################
# logistic regression #
#######################
# Apply logistic regression - this method is not suitable for this task. 
# Since fraud data are usually mislabeled (pre-defined labels will be wrong for some of the transactions because they are using rule-based techniques) and highly unbalanced (fraud transactions are much less – 1%). Most of supervised learning techniques, such as logistic regression, random forest, SVM, are sensitive to unbalance in predictor class. They trend to predict 0% fraud rate, which is not useful to decision makers
library(glmnet) # load package for implementation of logistic regression
key_var <- c("Fraud", "Purchased", "State", "Risk.Score1", "Risk.Score2", "Risk.Score3")
# define input data
x <- model.matrix(Fraud ~., data = train[,key_var])
# define response variable
y <- train[,key_var]$Fraud
# define input data in testing data
testx <- model.matrix(~., data = select(test_d[,key_var], - Fraud)  )
set.seed(123)
# implemented logistic regression 
fit_ridge <- cv.glmnet(x, y, alpha = 0, family = 'binomial', type.measure = 'deviance')
# predict response variable in training data 
train_pred <- predict(fit_ridge, newx = x, s = 'lambda.min', type='class')	
# predict response variable in testing data 
test_pred <- predict(fit_ridge, newx = testx, s = 'lambda.min', type='class')	
# confusion matrix (training data) - 0% fraud rate - not useful 
conf.matrix <- table(train$Fraud, train_pred)
rownames(conf.matrix) <- paste("Actual", rownames(conf.matrix), sep = ":")
colnames(conf.matrix) <- paste("Pred", colnames(conf.matrix), sep = ":")
print(conf.matrix)			   

#######################
# Deep Neural Network #
#######################
# Apply Deep Neural Network - this method is not suitable for this task. 
library(keras)  # load package for implementation of Deep Neural Network 
key_var <- c("Fraud", "Purchased", "State", "Risk.Score1", "Risk.Score2", "Risk.Score3")
# define input data
x <- model.matrix(~., data = train[,key_var])
x <- x[,-1]
# Change to matrix
data <- as.matrix(x)
dimnames(data) <- NULL
# Normalize input data
data[, 2:dim(x)[2]] <- normalize(data[, 2:dim(x)[2]])
summary(data)
# Data partition
set.seed(1234)
ind <- sample(2, nrow(data), replace = T, prob = c(0.7, 0.3))
# define input data in training data
training <- data[ind==1, 2:dim(x)[2]]
# define input data in testing data
test <- data[ind==2, 2:dim(x)[2]]
# define response variable in training data
trainingtarget <- data[ind==1, 1]
# define response variable in testing data
testtarget <- data[ind==2, 1]

# One Hot Encoding
trainLabels <- to_categorical(trainingtarget)
testLabels <- to_categorical(testtarget)
print(testLabels)

# Construct a DNN model 
# Create sequential model
model <- keras_model_sequential()
model %>%
         layer_dense(units=100, activation = 'relu', input_shape = c(53)) %>%
		 layer_dense(units=27, activation = 'relu') %>%
         layer_dense(units = 2, activation = 'softmax')
summary(model)
# Compile
model %>%
         compile(loss = 'binary_crossentropy',  # for two class, use 'binary_crossentropy'
                 optimizer = 'adam',
                 metrics = 'accuracy')
# Fit model
history <- model %>%
         fit(training,
             trainLabels,
             epoch = 200,
             batch_size = 32,
             validation_split = 0.2)
plot(history)

# Evaluate model with test data
model1 <- model %>%
         evaluate(test, testLabels)
# Prediction & confusion matrix in testing data (where response variables are pre-defined)
# still 0 % fraud rate - Not useful
prob <- model %>%
         predict_proba(test)
pred <- model %>%
         predict_classes(test)
table1 <- table(Predicted = pred, Actual = testtarget)
		 
		 
##################################################
# Neural Network with Deep Learning Autoencoders #		 
##################################################	 
library(h2o) # load library
# h2o.shutdown()
h2o.init(nthreads=-1,enable_assertions = FALSE) # initiate h2o 

key_var <- c("Fraud", "Purchased", "State", "Risk.Score1", "Risk.Score2", "Risk.Score3")
x <- model.matrix(~., data = train[,key_var])
x <- x[,-1]
data <- as.data.frame(x)
# convert fraud into categorical variable
data$Fraud <- as.factor(data$Fraud)
x<- data
# convert data to H2OFrame
creditcard_hf <- as.h2o(x)	

# Data partition	
splits <- h2o.splitFrame(creditcard_hf, 
                         ratios = c(0.4, 0.4), 
                         seed = 42)
# [19947 X 54]
train_unsupervised  <- splits[[1]]
# [20092 X 54]
train_supervised  <- splits[[2]]
# [9961 X 54]
test <- splits[[3]]

response <- "Fraud"
features <- setdiff(colnames(train_unsupervised), response)

# trained a unsupervised neural network using deep learning autoencoders
# features variables are both input and output data in neural network 
model_nn <- h2o.deeplearning(x = features,
                             training_frame = train_unsupervised,
                             model_id = "model_nn",
                             autoencoder = TRUE,
                             reproducible = TRUE, #slow - turn off for real problems
                             ignore_const_cols = FALSE,
                             seed = 42,
                             hidden = c(10, 2, 10), 
                             epochs = 100,
                             activation = "Tanh")

h2o.saveModel(model_nn, path=paste0(outpath,"model_nn"), force = TRUE)
model_nn <- h2o.loadModel(paste0(outpath,"model_nn/model_nn"))
model_nn

# Dimensionality reduction with hidden layers
# extracted the reduced representation of x (in this case, second layer, two dimensions)
# [19947 X 2]
train_features <- h2o.deepfeatures(model_nn, train_unsupervised, layer = 2) %>%
  as.data.frame() %>%
# [19947 X 3]  
  mutate(Fraud = as.vector(train_unsupervised[, 1]))
ggplot(train_features, aes(x = DF.L2.C1, y = DF.L2.C2, color = Class)) +
  geom_point(alpha = 0.1)

# let's take the third hidden layer
# extracted the reduced representation of x (in this case, third layer, 10 dimensions)
# [19947 X 10]
train_features <- h2o.deepfeatures(model_nn, train_unsupervised, layer = 3) %>%
  as.data.frame() %>%
# [19947 X 11]
  mutate(Fraud = as.factor(as.vector(train_unsupervised[, 1]))) %>%
  as.h2o()
features_dim <- setdiff(colnames(train_features), response)

# supervised learning stage
# reduced representation of x are input, response is output
model_nn_dim <- h2o.deeplearning(y = response,
                               x = features_dim,
                               training_frame = train_features,
                               reproducible = TRUE, #slow - turn off for real problems
                               balance_classes = TRUE,
                               ignore_const_cols = FALSE,
                               seed = 42,
                               hidden = c(10, 2, 10), 
                               epochs = 100,
                               activation = "Tanh")
h2o.saveModel(model_nn_dim, path=paste0(outpath,"model_nn_dim"), force = TRUE)
model_nn_dim <- h2o.loadModel(paste0(outpath,"model_nn_dim/DeepLearning_model_R_1519966491219_1"))
model_nn_dim

############
# Method 1 #
############

# For measuring model performance on test data, we need to convert the test data to the same reduced dimensions as the trainings data:
# For testing data, extracted the reduced representation of x (in this case, third layer, 10 dimensions)
# [9961 X 10]
test_dim <- h2o.deepfeatures(model_nn, test, layer = 3)
# predicted class output with reduced representation of x
# [9961 X 1]
h2o.predict(model_nn_dim, test_dim) %>%
  as.data.frame() %>%
  mutate(actual = as.vector(test[, 1])) %>%
  group_by(actual, predict) %>%
  summarise(n = n()) %>%
  mutate(freq = n / sum(n))
# A tibble: 4 x 4
# Groups:   actual [2]
#  actual predict     n  freq
#  <chr>  <fct>   <int> <dbl>
#1 0      0        6958 0.719
#2 0      1        2725 0.281
#3 1      0          74 0.266
#4 1      1         204 0.734

############
# Method 2 #
############
		 
# Anomaly detection
# computed the mean squared error (MSE) between actual x and reconstructed x 
# [9961 X 1]
anomaly <- h2o.anomaly(model_nn, test) %>%
  as.data.frame() %>%
  tibble::rownames_to_column() %>%
# [9961 X 2]  
  mutate(Fraud = as.vector(test[, 1]))

mean_mse <- anomaly %>%
  group_by(Fraud) %>%
  summarise(mean = mean(Reconstruction.MSE))
		 
ggplot(anomaly, aes(x = as.numeric(rowname), y = Reconstruction.MSE, color = as.factor(Fraud))) +
  geom_point(alpha = 0.3) +
  geom_hline(data = mean_mse, aes(yintercept = mean, color = Fraud)) +
  scale_color_brewer(palette = "Set1") +
  labs(x = "instance number",
       color = "Class")		 
		 
anomaly <- anomaly %>%
  mutate(outlier = ifelse(Reconstruction.MSE > 0.02, "outlier", "no_outlier"))

anomaly %>%
  group_by(Fraud, outlier) %>%
  summarise(n = n()) %>%
  mutate(freq = n / sum(n)) 		 

# A tibble: 4 x 4
# Groups:   Class [2]
#  Class outlier        n  freq
#  <chr> <chr>      <int> <dbl>
#1 0     no_outlier  8461 0.874
#2 0     outlier     1222 0.126
#3 1     no_outlier   241 0.867
#4 1     outlier       37 0.133

#################################################################################################
#  Apply Anomaly Detection with Autoencoders in whole training data, where response are present #
#################################################################################################
# Apply to entire training data
anomaly_w <- h2o.anomaly(model_nn, creditcard_hf) %>%
  as.data.frame() %>%
  tibble::rownames_to_column() %>%
  mutate(Class = as.vector(creditcard_hf[, 1]))
mean_mse_w <- anomaly %>%
  group_by(Class) %>%
  summarise(mean = mean(Reconstruction.MSE))		 
ggplot(anomaly_w, aes(x = as.numeric(rowname), y = Reconstruction.MSE, color = as.factor(Class))) +
  geom_point(alpha = 0.3) +
  geom_hline(data = mean_mse_w, aes(yintercept = mean)) +
  scale_color_brewer(palette = "Set1") +
  labs(x = "instance number",
       color = "Class")		 		 
anomaly_w <- anomaly_w %>%
  mutate(outlier = ifelse(Reconstruction.MSE > 0.02, "outlier", "no_outlier"))
anomaly_w %>%
  group_by(Class, outlier) %>%
  summarise(n = n()) %>%
  mutate(freq = n / sum(n)) 		
# A tibble: 4 x 4
# Groups:   Class [2]
#  Class outlier        n  freq
#  <chr> <chr>      <int> <dbl>
#1 0     no_outlier 42276 0.872
#2 0     outlier     6224 0.128
#3 1     no_outlier  1326 0.884
#4 1     outlier      174 0.116
  
# Compute loss and profit with trained classifier  
anomaly_w$purchased <- train$Purchased
anomaly_w <- anomaly_w %>%
             mutate(profit = (outlier==)  ) 
sum(filter(anomaly_w, outlier == "outlier" & Class == 1)$purchased)*10
# [1] 318350
# With this trained model, we will avoid loss $ 318,350   
sum(filter(anomaly_w, outlier == "no_outlier" & Class == 0)$purchased)*2  
# [1] 2907460  
# With this trained model, we will make profit $ 2,907,460     
   		 
####################################################################################################
#  Apply Anomaly Detection with Autoencoders in whole testing data, where response are NOT present #
####################################################################################################
key_var <- c("Fraud", "Purchased", "State", "Risk.Score1", "Risk.Score2", "Risk.Score3")
test_d$Fraud <- 0
x1 <- model.matrix(~., data = test_d[,key_var])
x1 <- x1[,-1]
data1 <- as.data.frame(x1)
data1$Fraud <- as.factor(data1$Fraud)
x1<- data1
x1 <- as.h2o(x1)			 
		 
# Anomaly detection
anomaly_test <- h2o.anomaly(model_nn, x1) %>%
  as.data.frame() %>%
  tibble::rownames_to_column() %>%
  mutate(Class = as.vector(x1[, 1]))

mean_mse_test <- anomaly_test %>%
  group_by(Class) %>%
  summarise(mean = mean(Reconstruction.MSE))
		 
ggplot(anomaly_test, aes(x = as.numeric(rowname), y = Reconstruction.MSE, color = as.factor(Class))) +
  geom_point(alpha = 0.3) +
  geom_hline(data = mean_mse, aes(yintercept = mean)) +
  scale_color_brewer(palette = "Set1") +
  labs(x = "instance number",
       color = "Class")		 
		 
anomaly_test <- anomaly_test %>%
  mutate(outlier = ifelse(Reconstruction.MSE > 0.02, "outlier", "no_outlier"))

anomaly_test %>%
  group_by(Class, outlier) %>%
  summarise(n = n()) %>%
  mutate(freq = n / sum(n)) 		 		 
		 
anomaly_test <- mutate(anomaly_test, Fraud = ifelse(outlier == "outlier", 1, 0) )		 
test_d$Fraud <- anomaly_test$Fraud	 
		 
library(data.table)
fwrite(test_d, file= paste0(outpath, "test_result.csv"))		 
		 
		 
###################
# Future Research #
###################
# Pre-trained supervised model, This model will now use the weights from the autoencoder for model fitting  
model_nn_2 <- h2o.deeplearning(y = "Fraud",
                               x = features,
                               training_frame = train_supervised,
                               pretrained_autoencoder  = "model_nn",    # use weights from autoencoder
                               reproducible = TRUE, #slow - turn off for real problems
                               balance_classes = TRUE,
                               ignore_const_cols = FALSE,
                               seed = 42,
                               hidden = c(10, 2, 10), 
                               epochs = 100,
                               activation = "Tanh")
h2o.saveModel(model_nn_2, path=paste0(outpath,"model_nn_2"), force = TRUE)
model_nn_2 <- h2o.loadModel("model_nn_2/DeepLearning_model_R_1519340599720_21")
model_nn_2		 		 
pred <- as.data.frame(h2o.predict(object = model_nn_2, newdata = test)) %>%
  mutate(actual = as.vector(test[, 1]))
pred %>%
  group_by(actual, predict) %>%
  summarise(n = n()) %>%
  mutate(freq = n / sum(n)) 		 		 
# We need to change hyper-parameter in the future  
# A tibble: 4 x 4
# Groups:   actual [2]
#  actual predict     n  freq
#  <chr>  <fct>   <int> <dbl>
#1 0      0        6777 0.700
#2 0      1        2906 0.300
#3 1      0         102 0.367
#4 1      1         176 0.633		 
 				 