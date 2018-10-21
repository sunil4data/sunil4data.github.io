## NOTE that directly reading data with 'header=TRUE' fills colName with unexpected values, hence this intial read to get colNames
tmp <- read.csv("household_power_consumption.txt", nrows=1, header=TRUE, sep=";")
featureNames <- names(tmp)

## Reading data for 1st & 2nd Feb 2007; 1st row header, 66636 rows of data for year 2006 & 24*60*2=2880 rows for 2 days in Feb
x <- read.csv("household_power_consumption.txt", skip=66636, nrows=2880, header=TRUE, sep=";")
names(x) <- featureNames

datetime <- strptime(paste(x$Date, x$Time, sep=" "), "%d/%m/%Y %H:%M:%S")
plot(datetime, x$Global_active_power, type="l", xlab="", ylab="Global Active Power (kilowatts)")
dev.copy(png, file="plot2.png", width=480, height=480)
dev.off()