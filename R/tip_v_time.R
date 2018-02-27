library("ggplot2")
data = read.csv("~/yellow_tripdata_2015-01.csv", header = T, sep = ',')
data_shaped <- data.frame(
  date = as.POSIXct(data$tpep_pickup_datetime, format='%m/%d/%Y %H:%M'),
  tip_amount = data$tip_amount
)
ggplot(data_shaped) + 
  geom_smooth(aes(x=date, y=tip_amount)) +
  ylim(0, 20)