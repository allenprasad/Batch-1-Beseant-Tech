rm(list=ls(all=TRUE))

setwd("C:/Users/jeevan/Desktop/Ensemble/")

# Load required libraries
library(vegan)
library(dummies)
library(ada) 
install.packages("ada")
attr = c('id', 'age', 'exp', 'inc', 'zip', 'family', 
         'ccavg', 'edu', 'mortgage', 'loan', 
         'securities', 'cd', 'online', 'cc')

# Read the data using csv file
data = read.csv(file = "UniversalBank.csv", 
                header = TRUE, col.names = attr)

# Removing the id, zip and experience. 
drop_Attr = c("id", "zip", "exp")
attr = setdiff(attr, drop_Attr)
data = data[, attr]
rm(drop_Attr)

# Convert attribute to appropriate type  
cat_Attr = c("family", "edu", "securities", 
             "cd", "online", "cc", "loan")
num_Attr = setdiff(attr, cat_Attr)
rm(attr)

cat_Data <- data.frame(sapply(data[,cat_Attr], as.factor))
num_Data <- data.frame(sapply(data[,num_Attr], as.numeric))

data = cbind(num_Data, cat_Data)
rm(cat_Data, num_Data)

# Do the summary statistics and check for missing values and outliers.
summary(data)

#------------------------------------------------------

# Build the classification model.
ind_Num_Attr = num_Attr
rm(num_Attr)
ind_Cat_Attr = setdiff(cat_Attr, "loan")
rm(cat_Attr)

# Standardizing the numeric data
cla_Data = decostand(data[,ind_Num_Attr], "range") 
rm(ind_Num_Attr)

# Convert all categorical attributes to numeric 
# 1. Using dummy function, convert education and family categorical attributes into numeric attributes 
edu = dummy(data$edu)
family = dummy(data$family)
cla_Data = cbind(cla_Data, edu, family)
ind_Cat_Attr = setdiff(ind_Cat_Attr, c("edu", "family"))
rm(edu, family)

# 2. Using as.numeric function, convert remaining categorical attributes into numeric attributes 
cla_Data = cbind(cla_Data, sapply(data[,ind_Cat_Attr], as.numeric))
rm(ind_Cat_Attr)
ind_Attr = names(cla_Data)

# Append the Target attribute 
cla_Data = cbind(cla_Data, loan=data[,"loan"]) 

str(cla_Data)
summary(cla_Data)

# Divide the data into test and train
set.seed(123)

train_RowIDs = sample(1:nrow(cla_Data), nrow(cla_Data)*0.6)
train_Data = cla_Data[train_RowIDs,]
test_Data = cla_Data[-train_RowIDs,]
rm(train_RowIDs)

# Check how records are split with respect to target attribute.
table(cla_Data$loan)
table(train_Data$loan)
table(test_Data$loan)
rm(cla_Data)

# Build best ada boost model 
model = ada(x = train_Data[,ind_Attr], 
            y = train_Data$loan, 
            iter=20, loss="logistic",verbose=TRUE) # 20 Iterations 

# Look at the model summary
model
summary(model)

# Predict on train data  
pred_Train  =  predict(model, train_Data[,ind_Attr])  

# Build confusion matrix and find accuracy   
cm_Train = table(train_Data$loan, pred_Train)
accu_Train= sum(diag(cm_Train))/sum(cm_Train)
rm(pred_Train, cm_Train)

# Predict on test data
pred_Test = predict(model, test_Data[,ind_Attr]) 

# Build confusion matrix and find accuracy   
cm_Test = table(test_Data$loan, pred_Test)
accu_Test= sum(diag(cm_Test))/sum(cm_Test)
rm(pred_Test, cm_Test)

accu_Train
accu_Test

rm(model, accu_Test, accu_Train, ind_Attr, train_Data, test_Data)
