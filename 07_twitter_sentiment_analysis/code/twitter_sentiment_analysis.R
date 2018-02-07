# https://analyzecore.com/2017/02/08/twitter-sentiment-analysis-doc2vec/
# loading packages
library(twitteR)
library(ROAuth)
library(tidyverse)
library(purrrlyr)
library(text2vec)
library(caret)
library(glmnet)
library(ggrepel)

#*********************************************************************************************************************
# clean data 

### loading and preprocessing a training set of tweets
# function for converting some symbols
conv_fun <- function(x) iconv(x, "latin1", "ASCII", "")
 
##### loading classified tweets ######
inpath <- "C:/Users/Aaron_clover/Desktop/HEG_folder/_interview_prep/twitter_sentiment_analysis/data/"
 
tweets_classified <- read_csv(paste0(inpath,'train_twitter.csv'), col_names = c('sentiment', 'id', 'date', 'query', 'user', 'text')) 
 # converting some symbols
tweets_classified <- tweets_classified %>% dmap_at('text', conv_fun)
tweets_classified <- mutate(tweets_classified, sentiment = ifelse(sentiment == 0, 0, 1))
data <- tweets_classified
# for demenstration, we only use 10000 records
set.seed(123)
pos <- filter(data, sentiment == 1)
pos <- pos[sample(1:dim(pos)[1],5000),]
neg <- filter(data, sentiment == 0)
neg <- neg[sample(1:dim(neg)[1],5000),]
tweets_classified <- rbind(pos, neg)

# data splitting on train and test
set.seed(2340)
trainIndex <- createDataPartition(tweets_classified$sentiment, p = 0.8, 
 list = FALSE, 
 times = 1)
tweets_train <- tweets_classified[trainIndex, ]
tweets_test <- tweets_classified[-trainIndex, ]


#*********************************************************************************************************************
# Method 1: Logistic regression 
# Main R packages:  text2vec, glmnet(cv.glmnet)
 
##### Vectorization #####
# define preprocessing function and tokenization function
prep_fun <- tolower
tok_fun <- word_tokenizer
 
it_train <- itoken(tweets_train$text, 
 preprocessor = prep_fun, 
 tokenizer = tok_fun,
 ids = tweets_train$id,
 progressbar = TRUE)
it_test <- itoken(tweets_test$text, 
 preprocessor = prep_fun, 
 tokenizer = tok_fun,
 ids = tweets_test$id,
 progressbar = TRUE)
 
# creating vocabulary and document-term matrix
vocab <- create_vocabulary(it_train)
vectorizer <- vocab_vectorizer(vocab)
dtm_train <- create_dtm(it_train, vectorizer)
# define tf-idf model
tfidf <- TfIdf$new()
# fit the model to the train data and transform it with the fitted model
dtm_train_tfidf <- fit_transform(dtm_train, tfidf)
# apply pre-trained tf-idf transformation to test data
dtm_test_tfidf  <- create_dtm(it_test, vectorizer) %>% 
        transform(tfidf)
 
# train the model
t1 <- Sys.time()
glmnet_classifier <- cv.glmnet(x = dtm_train_tfidf,
 y = tweets_train[['sentiment']], 
 family = 'binomial', 
 # L1 penalty
 alpha = 1,
 # interested in the area under ROC curve
 type.measure = "auc",
 # 5-fold cross-validation
 nfolds = 5,
 # high value is less accurate, but has faster training
 thresh = 1e-3,
 # again lower number of iterations for faster training
 maxit = 1e3)
print(difftime(Sys.time(), t1, units = 'mins'))
 
plot(glmnet_classifier)
print(paste("max AUC =", round(max(glmnet_classifier$cvm), 4)))
# prediction step is faster than naiveBayes 
preds_logistic <- predict(glmnet_classifier, dtm_test_tfidf, type = 'response')[ ,1]
preds_logistic <- ifelse(preds_logistic > 0.5,1,0)

table("Predictions"= preds_logistic,  "Actual" = tweets_test$sentiment )
#           Actual
#Predictions   0   1
#          0 739 253
#          1 261 747
# (739+747)/2000 = 74.3% accuracy (testing data)
 
#************************************************************************************************************************
# Method 2: Naive Bayes 
# Main R packages: tm, e1071(naiveBayes)

library(tm)
library(RTextTools)
library(e1071)
library(dplyr)
library(caret)

tweets_all <- rbind(tweets_train,tweets_test)
# Convert the 'class' variable from character to factor.
tweets_all$sentiment <- as.factor(tweets_all$sentiment)
# Bag of Words Tokenisation
corpus <- Corpus(VectorSource(tweets_all$text))
# Data Cleanup
# Use dplyr's  %>% (pipe) utility to do this neatly.
corpus.clean <- corpus %>%
  tm_map(content_transformer(tolower)) %>% 
  tm_map(removePunctuation) %>%
  tm_map(removeNumbers) %>%
  tm_map(removeWords, stopwords(kind="en")) %>%
  tm_map(stripWhitespace)
# Matrix representation of Bag of Words : The Document Term Matrix
dtm <- DocumentTermMatrix(corpus.clean)
 
# Partitioning the Data 
df.train <- tweets_all[1:8000,]
df.test <- tweets_all[8001:10000,]

dtm.train <- dtm[1:8000,]
dtm.test <- dtm[8001:10000,]

corpus.clean.train <- corpus.clean[1:8000]
corpus.clean.test <- corpus.clean[8001:10000]
 
# Feature Selection
# keep word only if it appears more than 5 times 
fivefreq <- findFreqTerms(dtm.train, 5)
length((fivefreq))
dtm.train.nb <- DocumentTermMatrix(corpus.clean.train, control=list(dictionary = fivefreq))
dim(dtm.train.nb)
dtm.test.nb <- DocumentTermMatrix(corpus.clean.test, control=list(dictionary = fivefreq))
dim(dtm.test.nb)

# Boolean feature Multinomial Naive Bayes
# Function to convert the word frequencies to "Negative", "Positive"
convert_count <- function(x) {
  y <- ifelse(x > 0, 1,0)
  y <- factor(y, levels=c(0,1), labels=c("Negative", "Positive"))
  y
}
# Apply the convert_count function to get final training and testing DTMs
trainNB <- apply(dtm.train.nb, 2, convert_count)
testNB <- apply(dtm.test.nb, 2, convert_count)

# Training the Naive Bayes Model
# Train the classifier
system.time( classifier <- naiveBayes(trainNB, df.train$sentiment, laplace = 1) )
# Use the NB classifier we built to make predictions on the test set.
# prediction step is slower than logistic regression if we increase variable, therefore Feature Selection is useful 
system.time( pred <- predict(classifier, newdata=testNB) )
# Create a truth table by tabulating the predicted class labels with the actual class labels 
preds_naivebays <- as.numeric(pred)-1
table("Predictions"= preds_naivebays,  "Actual" = df.test$sentiment )
#           Actual
#Predictions   0   1
#          0 706 242
#          1 294 758
# (706+758)/2000 = 73.2% accuracy (testing data)

#************************************************************************************************************************
# Method 3: SVM 
# Main R package: RTextTools (create_matrix, create_container, train_models)
library(RTextTools)

tweets_all <- rbind(tweets_train,tweets_test)
 
matrix <- create_matrix(tweets_all$text, language = "english", removeStopwords = TRUE, 
    removeNumbers = TRUE, stemWords = FALSE, tm::weightTfIdf) 
 
#removeSparseTerms
container <- create_container(matrix, tweets_all$sentiment, trainSize = 1:8000, 
    testSize = 8001:10000, virgin = FALSE)  
 
system.time( models <- train_models(container, algorithms = c("SVM")))

results <- classify_models(container, models)
preds_svm <- as.numeric(results[, "SVM_LABEL"]) -1 

table("Predictions"= preds_svm,  "Actual" = tweets_all$sentiment[8001:10000] )
#           Actual
#Predictions   0   1
#          0 682 262
#          1 318 738
# (682+738)/2000 = 71% accuracy (testing data)
 

#*****************************************************************************************************************************				   
# apply ensemble 

ensemble <- preds_logistic + preds_naivebays + preds_svm
ensemble <- sapply(ensemble/3, round)

table("Predictions"= ensemble,  "Actual" = tweets_all$sentiment[8001:10000] )
#           Actual
#Predictions   0   1
#          0 718 224
#          1 282 776
# (718+776)/ 2000 = 74.7% accuracy (testing data)
 
 

  