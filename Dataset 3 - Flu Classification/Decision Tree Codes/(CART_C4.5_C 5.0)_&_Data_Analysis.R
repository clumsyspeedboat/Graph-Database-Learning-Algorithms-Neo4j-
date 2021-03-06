###################
###### COVID ###### ---> DATA ANALYSIS + DECISION TREE ALGORITHMS
###################

# Cleaning the work space #
cat("\f")       # Clear old outputs
rm(list=ls())   # Clear all variables

if(!require("ggplot2")) install.packages("ggplot2")       # Visualization
if(!require("factoextra")) install.packages("factoextra") # PCA
if(!require("FSelector")) install.packages("FSelector")   # Information Gain & Gain Ratio
if(!require("DescTools")) install.packages("DescTools")   # Gini Index
if(!require("rpart")) install.packages("rpart")           # Decision Tree : CART (gini)
if(!require("rpart.plot")) install.packages("rpart.plot") # Decision Tree plot : CART
if(!require("C50")) install.packages("C50")               # Decision Tree : C 5.0 (gain ratio)
if(!require("RWeka")) install.packages("RWeka")           # Decision Tree : C 4.5 (gain ratio)

library("ggplot2")
library("factoextra")
library("FSelector")
library("DescTools")
library("rpart")
library("rpart.plot")
library("C50")
library("RWeka")


# Creating a data matrix #
data <- file.choose()
data_matrix <- read.csv(data, header = TRUE, sep = ",", na.strings=c("","NA"))
# data_matrix[data_matrix == ""] <- NA

# Selecting necessary columns for Decision Tree Implementation #
data_matrix <- data_matrix[,c(1,3,4,26,32,33,34,35,36,37,42,47,50)]
data_matrix <- data_matrix[,c(2,11,3,4,5,6,7,8,9,10,12,13,1)]

# Information about the variables #
info1_data <- str(data_matrix)
info_data <- as.data.frame.matrix(summary(data_matrix))

# Handling null values in the data set #
data1 <- data_matrix[,1:2]
data2 <- data_matrix[,3:13]

data1[is.na(data1)] <- 0          # for numeric variables
data2[is.na(data2)] <- "unknown"  # for categorical variables
data_matrix <- cbind(data1,data2)

# Transforming Variables #
for (i in 1:2) {
    data_matrix[,i] <- as.numeric(data_matrix[,i])
}
  
for (i in 3:13) {
  data_matrix[,i] <- as.factor(data_matrix[,i])
}

###################
## Data Analysis ##
###################

ggplot(data = data_matrix) +
  geom_histogram(aes(x = age), bins = 10, colour = "black", fill = "red")

ggplot(data = data_matrix) +
  geom_histogram(aes(x = creatinine_phosphokinase), bins = 10, colour = "black", fill = "red")

ggplot(data = data_matrix) +
  geom_histogram(aes(x = ejection_fraction), bins = 10, colour = "black", fill = "red")

ggplot(data = data_matrix) +
  geom_histogram(aes(x = platelets), bins = 10, colour = "black", fill = "red")

ggplot(data = data_matrix) +
  geom_histogram(aes(x = serum_creatinine), bins = 10, colour = "black", fill = "red")

ggplot(data = data_matrix) +
  geom_histogram(aes(x = serum_sodium), bins = 10, colour = "black", fill = "red")

ggplot(data = data_matrix) +
  geom_histogram(aes(x = time), bins = 10, colour = "black", fill = "red")

###########################
## Unsupervised Learning ##
###########################

## Principal Component Analysis (Numeric Variables) ##
pca1 <- prcomp(data_matrix[,c(2,11)], scale = TRUE, center = TRUE)
fviz_pca_biplot(pca1, repel = F,
                col.var = "black", # Variables color
                addEllipses = T  # add ellipse around individuals
)

## Hierarchical Clustering ##
h_clust <- eclust(data_matrix[,c(3,4,6,7,8,9,10,11,12,13)], "hclust", 3 , hc_metric = "manhattan", hc_method = "ward.D", graph = TRUE)
fviz_dend(h_clust, show_labels = TRUE, palette = "jco", as.ggplot= TRUE)


## DBSCAN ##
dbscan <- fpc::dbscan(data_matrix[,c(3,4,6,7,8,9,10,11,12,13)], eps = 20, MinPts =3)  
fviz_cluster(dbscan, data_matrix[,c(3,4,6,7,8,9,10,11,12,13)], stand = FALSE, ellipse = TRUE, geom = "point")


## Entropy, Information Gain & Gain Ratio of variables ##
ig_entropy <- information.gain(Diagnosis~., data_matrix, unit = "log2")
colnames(ig_entropy) <- "Information Gain"

gr_entropy <- gain.ratio(Diagnosis~. , data_matrix, unit = "log2")
colnames(gr_entropy) <- "Gain Ratio"


## Gini Index of variables ##
gini_ind <- as.data.frame(lapply(data_matrix, Gini))
gini_ind <- as.data.frame(t(gini_ind))
colnames(gini_ind) <- "Gini Index"


###################
## Decision Tree ##
###################

#------------------------------------------------
"Train-Test Data Split"
#------------------------------------------------
####################

# Split the original data_matrix #
training_size <- 0.75 #extracting Percentage
n = nrow(data_matrix)
smp_size <- floor(training_size * n)  
index<- sample(seq_len(n),size = smp_size, replace = FALSE)

# Breaking into Training and Testing Sets:
TrainingSet <- data_matrix[index,]
TestingSet <- data_matrix[-index,]

# Export CSV #
# write.csv(TrainingSet, file = "Training Set.csv", row.names = FALSE)
# write.csv(TestingSet, file = "Testing Set.csv", row.names = FALSE)

######   or   ######  

# Choosing pre-partitioned Training Set and Testing Set #
TrainingSet = read.csv(file.choose(), header = TRUE, sep = ",")
TestingSet = read.csv(file.choose(), header = TRUE, sep = ",")

# Transform Variables #

# Training data #

for (i in 1:2) {
  TrainingSet[,i] <- as.numeric(TrainingSet[,i])
}

for (i in 3:13) {
  TrainingSet[,i] <- as.factor(TrainingSet[,i])
}

# Testing data #

for (i in 1:2) {
  TestingSet[,i] <- as.numeric(TestingSet[,i])
}

for (i in 3:13) {
  TestingSet[,i] <- as.factor(TestingSet[,i])
}

##########################################
# CART #
########

options(digits.secs = 6)
start.time1 <- Sys.time()
tree1 <- rpart(Diagnosis ~.,data=TrainingSet[,-4], method = 'class', parms = list(split = "gini"))
end.time1 <- Sys.time()

rpart.plot(tree1)

start.time2 <- Sys.time()
Prediction1 <- predict(tree1, newdata=TestingSet[,-4],type = 'class')
end.time2 <- Sys.time()

# Confusion Matrix #

levels <- levels(Prediction1)
levels <- levels[order(levels)]    
cm1 <- table(ordered(Prediction1,levels), ordered(TestingSet$Diagnosis, levels))
cm1

time_taken1 <- end.time1 -start.time1
time_taken2 <- end.time2 -start.time2
time_taken1
time_taken2

###########################################

###########################################
# C4.5 #
########

options(digits.secs = 6)
start.time1 <- Sys.time()
tree2 <- J48(Diagnosis~., data = TrainingSet[,-4])
end.time1 <- Sys.time()

plot(tree2, type = "simple")

start.time2 <- Sys.time()
Prediction2 <- predict(tree2, newdata = TestingSet[,-4], type = "class")
end.time2 <- Sys.time()

# Confusion Matrix #

levels2 <- levels(Prediction2)
levels2 <- levels[order(levels2)]    
cm2 <- table(ordered(Prediction2,levels2), ordered(TestingSet$Diagnosis, levels2))
cm2

time_taken1 <- end.time1 -start.time1
time_taken2 <- end.time2 -start.time2
time_taken1
time_taken2

###########################################

###########################################
# C5.0 #
########

options(digits.secs = 6)
start.time1 <- Sys.time()
tree3 <- C5.0(Diagnosis~., data = TrainingSet[,-4], trials = 100)
end.time1 <- Sys.time()

plot(tree3, type = "simple")

start.time2 <- Sys.time()
Prediction3 <- predict(tree3, newdata = TestingSet[,-4], type = "class")
end.time2 <- Sys.time()

# Confusion Matrix #

levels3 <- levels(Prediction3)
levels3 <- levels[order(levels3)]    
cm3 <- table(ordered(Prediction3,levels3), ordered(TestingSet$Diagnosis, levels3))
cm3

time_taken1 <- end.time1 -start.time1
time_taken2 <- end.time2 -start.time2
time_taken1
time_taken2

###########################################