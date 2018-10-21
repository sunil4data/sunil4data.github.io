# Code Book

This document provides precise information about reference data set and then describes the code inside run_analysis.R.

## Precise information about reference data set
1. subject = Id of one of the 30 volunteers selected as subject at data collection points (7352 data points for training & 2947 for testing)
    1. subject_train.txt = random 70% volunteers picked for collecting TRAINING data (range 1-30)
    2. subject_test.txt = remaining 30% volunteers picked for collecting TESTING data (range 1-30)
2. internal signals (don't care for this project work) = body acceleration x/y/z, body gyro momemts x/y/z, etc are raw motion parameters
3. features = parameters depicting Human Activity; these parameters are calculated/derived from raw signals (internal signals)
4. x = 'features' values for specified 'y'
    1. x_train.txt = training x data
    2. x_test.txt = testing x data   
5. y = 'activity' value at data collection points (7352 data points for training & 2947 for testing)
    1. y_train.txt = training y data
    2. x_test.txt = testing y data
6. data.frame = [subject(subject-column) ||	y(activity-column)	||	x(features-columns)]
    (7352 + 2947) rows x (1+1+561) columns

## run_analysis.R script high level details along with key variables summary dump

The code has just 3 sections: - 
1. Helper functions
    1. getDownloadedZipFilePath => downloads the dataset into a .zip file into temporary folder and returns its file path
    2. getTrainingDataFrame(zipFilePath) => It reads training data into a dataframe[subject_train, y_train as activity, x_train as features] and returns the same
    3. getTestingDataFrame(zipFilePath) => It reads testing data into a dataframe[subject_test, y_test as activity, x_test as features] and returns the same
    4. labelColsInMergedData(zipFilePath, dataFrame) => It first merges 7352 & 2947 rows into combined dataset. It assigns 'subject', 'activity' and 'features' to subject, y & x columns; Features list is read from 'features.txt'
    5. labelActivitiesInData(zipFilePath, dataFrame) => It turns 'activity' from numeric into factor and assigns levels from 'activity_labels.txt'
2. Constants
3. High Level Code for performing the expected 5 tasks
    1. Task 0 - Get training & test data; At this point, both 'dfTraining' & 'dfTesting' dataFrames col names are default
    2. Task 1 - Merges the training and the test sets to create one data set.; We merge training & test data and assign names to all 563 columns
    3. Test 2 - Extracts only the measurements on the mean and standard deviation for each measurement.; We create a new dataFrame 'dfMeanStdData'
    4. Task 3 - Uses descriptive activity names to name the activities in the data set.; We assign descriptive name to 'dfMeanStdData$activity' column
    5. Task 4 - Appropriately labels the data set with descriptive variable names.; We rename features name to replace t->time, f->frequency, Acc->Accelerometer, etc and remove '()'
    6. Task 5 - From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.; The 'dfTidyData' dataFrame includes the average of each 'feature' for each 'activity' and each 'subject'. 10299 instances are split into 180 groups (30 subjects and 6 activities) and 66 mean and standard deviation features are averaged for each group. The resulting dataFrame has 180 rows and 68 columns - 33 Mean variables + 33 Standard deviation variables + 1 Subject( 1 of of the 30 test subjects) + ActivityName.
