	# Admin stuff here, nothing special 
	  options(digits=4)
	# load library
	  library(dplyr)  
	  library(foreach)
	  library(iterators)
	  library(parallel)
	  library(doParallel)
	  library(wordcloud)
	  library(ggplot2)
	  library(igraph)
	  library(ggraph)
	  
	# data <- read.csv(file="lastfm-data.csv")
	  inpath <- "C:/Users/Aaron_clover/Desktop/HEG_folder/_interview_prep/recomd_sys/data/"
	  outpath <- "C:/Users/Aaron_clover/Desktop/HEG_folder/_interview_prep/recomd_sys/out/"
	  data0 <- read.csv(file=paste0(inpath, "lastfm-matrix-germany.csv"))
	# Drop the user column and make a new data frame
	  data <- select(data0, -user)  
	  artist <- names(data)
	  
	################
	#  wordcloud   #
	################
	  wordcloud <- as.numeric(colSums(data))
	  wordcloud <- as.data.frame(cbind(artist = artist , count = wordcloud), stringsAsFactors = FALSE)
	  rownames(wordcloud) <- NULL
	  wordcloud$count <- as.numeric(wordcloud$count)
	  set.seed(12)
	  tiff(paste0(outpath, "wordcloud.jpeg"), width=1000, height=800)
	  with(wordcloud, wordcloud(artist, count))
	  dev.off()
	 
	########################
	# Networks of Artists  #
	########################
	  gc()
	  cl <- makeCluster(detectCores()-1)  
	  registerDoParallel(cl) 
	  p <- proc.time()
	  network <- foreach(i = 1: (dim(data)[2]-1), .combine = "rbind")%:%
					 foreach(j = (i+1) : dim(data)[2], .combine = "rbind")%dopar%{
							 temp<-  c( artist_1 = artist[i],
										artist_2 = artist[j],
										   count = sum(data[,i] ==1 & data[,j] ==1))
						 }
	  proc.time() - p
	  stopCluster(cl)
	  gc()
	  network <- as.data.frame(network, stringsAsFactors = FALSE)
	  rownames(network) <- NULL
	  network$count <- as.numeric(network$count) 

	# graph the network
	  
	  bigram_graph <- network %>%
					  filter(count >= 35) %>%
					  graph_from_data_frame()
	  
	  set.seed(1234)
	  tiff(paste0(outpath, "network.jpeg"), width=1000, height=800)
	  ggraph(bigram_graph, layout = "fr") +
	  geom_edge_link(aes(edge_alpha = count, edge_width = count), edge_colour = "cyan4") +
	  geom_node_point(size = 5) +
	  geom_node_text(aes(label = name), repel = TRUE, point.padding = unit(0.2, "lines")) +
	  theme_void()
	  dev.off()
	  
	############################
	#  Item Based Similarity   #
	############################   
	 
	# Create a helper function to calculate the cosine between two vectors
	  getCosine <- function(x,y){
		return(sum(x*y) / (sqrt(sum(x*x)) * sqrt(sum(y*y))))
	  }
	 
	# create matrix with cosine similarities
	  gc()
	  cl <- makeCluster(detectCores()-1)  
	  registerDoParallel(cl) 
	  p <- proc.time()
	  similarity <- foreach(i = 1:dim(data)[2] ,  .combine = "rbind") %:% 
					   foreach(j = 1:dim(data)[2] ,  .combine = "c") %dopar% {
						  getCosine(data[,i],data[,j])		   
					   }
	# Write output to file
	  write.csv(file=paste0(outpath, "similarity.csv"),similarity)
	  
	# Get the top 10 neighbours for each

	  top10_neighbours_index <- foreach(i = 1:dim(data)[2] ,  .combine = "rbind") %dopar% {
								 order(similarity[i,], decreasing=TRUE)[2:11]
								 }
	  top10_neighbours_sim_val <- foreach(i = 1:dim(data)[2] ,  .combine = "rbind") %dopar% {
								 similarity[i,][order(similarity[i,], decreasing=TRUE)[2:11]]
								 }
	 
	############################
	# User Scores Matrix       #
	############################    
	# Process:
	# Get the similarities of that product's top 10 neighbours
	# Get the purchase record of that user of these top 10 neighbours
	# Do the formula: sumproduct(purchaseHistory, similarities)/sum(similarities)
	 
	# create a helper function to calculate the scores
	  getScore <- function(history, similarities){
		return(sum(history*similarities)/sum(similarities))
	  }
	 
	# compute the recommendation score 
	  score <- foreach(i = 1:dim(data)[1] ,  .combine = "rbind") %:% 
						  foreach(j = 1:dim(data)[2] ,  .combine = "c") %dopar% {
							  hist <- data[i,top10_neighbours_index[j,]]
							   sim <- top10_neighbours_sim_val[j,]
							 point <- ifelse(data[i,j] == 1 , 0, getScore(hist, sim))
							  
					   }

	  recommendation <- foreach(i = 1:dim(data)[1] ,  .combine = "rbind") %dopar% {
								 artist[order(score[i,], decreasing=TRUE)[1:10]]
								 }
	  proc.time() - p
	  stopCluster(cl)
	  gc() 
	  recommendation <- as.data.frame(recommendation)
	  recommendation <- cbind(data0$user, recommendation)
	  rownames(recommendation) <- NULL
	  names(recommendation) <- c("user", paste("rec", 1:10))

	# Write output to file
	  write.csv(file=paste0(outpath, "recommendations.csv"),recommendation)