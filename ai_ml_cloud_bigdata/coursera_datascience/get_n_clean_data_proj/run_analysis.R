library(plyr)

#
# Helper functions
#

getDownloadedZipFilePath <- function() {

  print("getDownloadedZipFilePath function - START")
  
  ## temporary zip file path
  tempZipPath <- tempfile(fileext = ".zip")
  
  ## download dataset zip into temporary zip file path
  download.file("https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip", tempZipPath)

  print("getDownloadedZipFilePath function - END")
  
  tempZipPath
}

getTrainingDataFrame <- function(zipFilePath) {
  
  print("getTrainingDataFrame function - START")
  
  ## read training data
  ## ./UCI HAR Dataset/train/X_train.txt, y_train.txt & subject_train.txt
  dataTrainX <- read.table(unz(zipFilePath, paste0(refDatasetRootFolder, trainingDataFolder, xTrainFilename)), header=F)
  dataTrainY <- read.table(unz(zipFilePath, paste0(refDatasetRootFolder, trainingDataFolder, yTrainFilename)), header=F)
  dataTrainSubject <- read.table(unz(zipFilePath, paste0(refDatasetRootFolder, trainingDataFolder, subjectTrainFilename)), header=F)

  print("getTrainingDataFrame function - END")
  
  dfTrain <- data.frame(dataTrainSubject, dataTrainY, dataTrainX)
}

getTestingDataFrame <- function(zipFilePath) {
  
  print("getTestingDataFrame function - START")
  
  ## read testing data
  ## ./UCI HAR Dataset/test/X_test.txt, y_test.txt & subject_test.txt
  dataTestX <- read.table(unz(zipFilePath, paste0(refDatasetRootFolder, testingDataFolder, xTestFilename)), header=F)
  dataTestY <- read.table(unz(zipFilePath, paste0(refDatasetRootFolder, testingDataFolder, yTestFilename)), header=F)
  dataTestSubject <- read.table(unz(zipFilePath, paste0(refDatasetRootFolder, testingDataFolder, subjectTestFilename)), header=F)

  print("getTestingDataFrame function - END")
  
  dfTesting <- data.frame(dataTestSubject, dataTestY, dataTestX)  
}

labelColsInMergedData <- function(zipFilePath, dfData) {

  print("labelColsInMergedData function - START")
  
  ## features - skip serial no column
  ## ./UCI HAR Dataset/features.txt
  features <- read.table(unz(zipFilePath, paste0(refDatasetRootFolder, featuresFilename)), colClasses = c("NULL", "character"), header=F)
  
  names(dfData) <- c(c("subject", "activity"), as.character(features[,1]))

  print("labelColsInMergedData function - END")
  
  dfData
}

labelActivitiesInData <- function(zipFilePath, dfData) {

  print("labelActivitiesInData function - START")
  
  ## activityLevels - skip serial no column
  ## ./UCI HAR Dataset/activity_labels.txt
  activityLevels <- read.table(unz(zipFilePath, paste0(refDatasetRootFolder, activityLabelsFilename)), colClasses = c("NULL", "character"), header=F)
  activityLevels <- data.frame(activity = apply(activityLevels, 1, tolower))  ##tolower or *apply* does not return data.frame

  ## convert 'activity' column from numeric to factor with levels with Activity
  dfData$activity <- as.factor(dfData$activity)  
  levels(dfData$activity) <- activityLevels[,1]

  print("labelActivitiesInData function - END")
  
  dfData
}

#
# Constants
#

refDatasetRootFolder <- "UCI HAR Dataset/"
trainingDataFolder <- "train/"
testingDataFolder <- "test/"

featuresFilename <- "features.txt"
activityLabelsFilename <- "activity_labels.txt"

xTrainFilename <- "X_train.txt"
yTrainFilename <- "y_train.txt"
subjectTrainFilename <- "subject_train.txt"

xTestFilename <- "X_test.txt"
yTestFilename <- "y_test.txt"
subjectTestFilename <- "subject_test.txt"

#
# Task 0 - Get training & test data
#
print("Task 0 - Get training & test data")

zipFilePath <- getDownloadedZipFilePath()

dfTraining <- getTrainingDataFrame(zipFilePath)
dfTesting <- getTestingDataFrame(zipFilePath)

#
# Task 1 - Merges the training and the test sets to create one data set.
#
print("Task 1 - Merges the training and the test sets to create one data set.")

dfMerged <- merge(dfTraining, dfTesting, all=TRUE, sort=FALSE)
dfMerged <- labelColsInMergedData(zipFilePath, dfMerged)

#
# Task 2 - Extracts only the measurements on the mean and standard deviation for each measurement.
#
print("Task 2 - Extracts only the measurements on the mean and standard deviation for each measurement.")

meanStdColsIndices <- grep("activity|subject|mean\\(\\)|std\\(\\)", colnames(dfMerged))
dfMeanStdData <- dfMerged[,meanStdColsIndices]

#
# Task 3 - Uses descriptive activity names to name the activities in the data set
#
print("Task 3 - Uses descriptive activity names to name the activities in the data set")

dfMeanStdData <- labelActivitiesInData(zipFilePath, dfMeanStdData)

#
# Task 4 - Appropriately labels the data set with descriptive variable names.
#
print("Task 4 - Appropriately labels the data set with descriptive variable names.")

names(dfMeanStdData) <- gsub("^t", "time", names(dfMeanStdData))
names(dfMeanStdData) <- gsub("^f", "frequency", names(dfMeanStdData))
names(dfMeanStdData) <- gsub("Acc", "Accelerometer", names(dfMeanStdData))
names(dfMeanStdData) <- gsub("Gyro", "Gyroscope", names(dfMeanStdData))
names(dfMeanStdData) <- gsub("Mag", "Magnitude", names(dfMeanStdData))
names(dfMeanStdData) <- gsub("BodyBody", "Body", names(dfMeanStdData))
names(dfMeanStdData) <- gsub("\\(\\).*", "", names(dfMeanStdData))

#
# Task 5 - From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.
#
print("Task 5 - From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.")

dfTidyData <- aggregate(. ~ subject + activity, dfMeanStdData, mean)
dfTidyData <- dfTidyData[order(dfTidyData$subject, dfTidyData$activity),]