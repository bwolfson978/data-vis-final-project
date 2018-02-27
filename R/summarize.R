library("dplyr")
file <- '~/yellow_tripdata_2015-04.csv'
index <- 0
chunkSize <- 100000
con <- file(description = file, open = "r")
dataChunk <- read.table(con, nrows = chunkSize, header = T, fill = TRUE, sep = ",")
results <- data.frame(Date=as.Date(character()),
                      AverageTip = double())

resultsPayment <- data.frame(date=as.Date(character()),
                      payment_type = integer(),
                      n = integer(),
                      freq = double())

colnames <- c('VendorID', 'tpep_pickup_datetime', 'tpep_dropoff_datetime', 'passenger_count',
              'trip_distance', 'pickup_longitude', 'pickup_latitude', 'RateCodeID', 'store_and_fwd_flag',
              'dropoff_longitude', 'dropoff_latitude', 'payment_type', 'fare_amount', 'extra', 'mta_tax',
              'tip_amount', 'tolls_amount', 'improvement_surcharge', 'total_amount')
repeat {
  index <- index + 1
  print(paste('Processing rows:', index * chunkSize))

  #tip_data
  dataFrame <- data.frame(
    date = as.POSIXct(dataChunk$tpep_pickup_datetime, format='%Y-%m-%d %H'),
    tip_amount = dataChunk$tip_amount
  )
  dataFrame <- filter(dataFrame, dataFrame$tip_amount > 0)
  groupedByData <- group_by(dataFrame, date)
  summarized <- summarize(groupedByData, tip = mean(tip_amount))
  results <- rbind(results, summarized)

  #payment_type data
  dataFramePayment <- data.frame(
    date = as.POSIXct(dataChunk$tpep_pickup_datetime, format='%Y-%m-%d %H'),
    payment_type = dataChunk$payment_type
  )
  dataFramePayment <- filter(dataFramePayment, dataFramePayment$payment_type == 1 | dataFramePayment$payment_type == 2)
  
  groupedByDataPayment <- group_by(dataFramePayment, date, payment_type)
  summarizedPayment <- summarize(groupedByDataPayment, n=n())
  percentData <- mutate(summarizedPayment, freq = n / sum(n))
  percentDataFiltered <- filter(percentData, payment_type == 1)
  resultsPayment <- bind_rows(percentDataFiltered, resultsPayment)
  
  if(nrow(dataChunk) != chunkSize){
    dateGroupedResults <- group_by(results, date)
    results <- summarize(dateGroupedResults, tip = mean(tip))
    dateGroupedResultsPayment <- group_by(resultsPayment, date)
    resultsPayment <- summarize(dateGroupedResultsPayment, freq = mean(freq))
    write.csv(results, file = "apr_tip_hour_buckets.csv")
    write.csv(resultsPayment, file = "apr_payment_hour_buckets.csv")
    break
  }
  
  dataChunk <- read.table(con, nrows = chunkSize, skip = 0, header = FALSE, fill = TRUE, sep = ",", col.names = colnames)
}
close(con)
