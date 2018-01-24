options(digits=6)

# clear workspace
rm(list = ls())


# path for graph

outpath <- "C:/Users/Aaron_clover/Desktop/HEG_folder/_interview_prep/08_machine_learnig/CART/out/"

library(rpart)
library(rpart.plot)
data(ptitanic)

str(ptitanic)

# classification tree
# Step1: Begin with a small cp. 
set.seed(123)
tree <- rpart(survived ~ ., data = ptitanic, control = rpart.control(cp = 0.0001))

# Step2: Pick the tree size that minimizes misclassification rate (i.e. prediction error).
# Prediction error rate in training data = Root node error * rel error * 100%    = right prediction / total in training set 
# Prediction error rate in cross-validation = Root node error * xerror * 100%
# Hence we want the cp value (with a simpler tree) that minimizes the xerror. 

# Each row represents a different height of the tree. In general, more levels in the tree mean that it has lower classification error on the training. However, you run the risk of overfitting. Often, the cross-validation error will actually grow as the tree gets more levels (at least, after the 'optimal' level).

printcp(tree)

bestcp <- tree$cptable[which.min(tree$cptable[,"xerror"]),"CP"]

# Step3: Prune the tree using the best cp.
tree.pruned <- prune(tree, cp = bestcp)

# confusion matrix (training data)
conf.matrix <- table(ptitanic$survived, predict(tree.pruned,type="class"))
rownames(conf.matrix) <- paste("Actual", rownames(conf.matrix), sep = ":")
colnames(conf.matrix) <- paste("Pred", colnames(conf.matrix), sep = ":")
print(conf.matrix)


#*****************************************************************
tiff(paste0(outpath, "classification_tree.tiff"), width=1500, height=1200)
prp(tree.pruned, faclen = 0, cex = 2.5, extra = 1)
dev.off()
# faclen = 0 means to use full names of the factor labels
# extra = 1 adds number of observations at each node; equivalent to using use.n = TRUE in plot.rpart
# Take the far left node as an example, 660/136 under “died” means 660 people that actually died and 136 that actually survived are predicted as died.
#*****************************************************************
tot_count <- function(x, labs, digits, varlen)
{
  paste(labs, "\n\nn =", x$frame$n)
}
prp(tree.pruned, faclen = 0, cex = 0.8, node.fun=tot_count)





# regression tree
#************************************************
set.seed(123)
tree <- rpart(age ~ ., data = ptitanic, control = rpart.control(cp = 0.0001))
printcp(tree)
bestcp <- tree$cptable[which.min(tree$cptable[,"xerror"]),"CP"]
tree.pruned <- prune(tree, cp = bestcp)

tiff(paste0(outpath, "regression_tree.tiff"), width=1500, height=1200)
prp(tree.pruned, faclen = 0, cex = 2.5, extra = 1)
dev.off()












