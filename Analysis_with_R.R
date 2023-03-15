#setting up the environment 
install.packages("tidyverse")
library(tidyverse)
install.packages("readr")
library(readr)
install.packages("hms")
library(hms)
install.packages("lubridate")
library(lubridate)
install.packages("skimr")
library(skimr)
install.packages("ggplot2")
library(ggplot2)
install.packages("dplyr")
library(dplyr)
install.packages("rmarkdown")
library(rmarkdown)

#reading every csv file 
december_2022<-read_csv("202212-divvy-tripdata.csv")
november_2022<-read_csv("202211-divvy-tripdata.csv")
october_2022<-read_csv("202210-divvy-tripdata.csv")
spetember_2022<- read_csv("202209-divvy-publictripdata.csv")
august_2022<-read_csv("202208-divvy-tripdata.csv")
july_2022<-read_csv("202207-divvy-tripdata.csv")
june_2022<-read_csv("202206-divvy-tripdata.csv")
may_2022<- read_csv("202205-divvy-tripdata.csv")
april_2022<- read_csv("202204-divvy-tripdata.csv")
mars_2022<- read_csv("202203-divvy-tripdata.csv")
february_2022<- read_csv("202202-divvy-tripdata.csv")
january_2023<- read_csv("202301-divvy-tripdata.csv")

#the january csv file doesn't have the correct date format 
#changing the dates from dd/mm/yyyy to yyyy/mm/dd
january_2023<- january_2023 %>% 
  mutate(started_at=(as.POSIXct(started_at, format = '%d/%m/%Y %H:%M',tz = "UTC")))%>% 
  mutate(ended_at=as.POSIXct(ended_at, format = '%d/%m/%Y %H:%M',tz = "UTC"))

#biding 12 month of data into a single dataframe 
biker_data_0<-bind_rows(february_2022,mars_2022,april_2022,may_2022,june_2022,july_2022,august_2022,spetember_2022,october_2022,november_2022,december_2022,january_2023)
#getting a sense of the data 
colnames(biker_data_0)

#checking for null and NA values 
print(sum(is.na(biker_data_0)))
print(sum(is.null(biker_data_0)))

#checking for duplicates in the dataSet 
#no duplicates found 
print(sum(duplicated(biker_data_3$ride_id)))

#ride_id is the primary key 
#checking to see if all values are valid and of same length 
#some of the value are invalid and needs to be removed 
ride_id_len = biker_data_0 %>% 
  group_by(nchar(ride_id)) %>% 
  summarize(count=n() )

#data cleaning process

#transorming the time started_at and ended_at to the right format 
#calculating the duration of each ride 
biker_data_1<-biker_data_0 %>%
  mutate(started_at=ymd_hms(as_datetime(started_at)),
  ended_at=ymd_hms(as_datetime(ended_at)))


biker_data_2<- biker_data_1 %>% 
  mutate(day_of_week=wday(started_at, label = T, abbr = F),
         day_of_month=day(started_at),
         month_of_year=month(started_at, label = T, abbr =F),
         hour_of_day= hour(started_at),
         duration= difftime(ended_at,started_at,units="mins"))
         
                           
 




print(sum(is.na(biker_data_2)))
#removing N/A
biker_data_2<- biker_data_2 %>% 
  na.omit()



#filtering out trip duration that are less than 1 minute and greater than a day 
#i am also filtering out all data that has wrong or invalid ride_id value

biker_data_3<-biker_data_2 %>% 
  filter(duration>0) %>% 
  filter(duration>= 1 & duration<=1440) %>% 
  filter(nchar(ride_id)==16)
  



#making sure that there is no missing values 
colSums(is.na(biker_data_3))

skim_without_charts(biker_data_3)

#creating a smaller dataframe to make fetching data easier 
trips_time_df = biker_data_3 %>% 
  drop_na(
    end_lat, end_lng
  ) %>% 
  select(
    ride_id, member_casual, rideable_type, hour_of_day, day_of_week, month_of_year, day_of_month, duration
  )

#aggregate data 
ride_week=trips_time_df %>% 
  group_by(member_casual,day_of_week) %>% 
  summarise(number_of_rides=n(),
            avg_rides_week = mean(duration),
            total_duration_week = sum(duration))



ggplot(ride_week,mapping= aes(fill=member_casual,y=number_of_rides, x=day_of_week)) +
  geom_bar(position='dodge', stat='identity')+labs(
    title = "Number of Trips per day of week",
    subtitle = "Number of trips per weekDay MembervsCasual",
    caption = "Figure 1",
    x = "day of week",
    y = "number of rides",
  )


#average duration of a trip by each weekDay

ggplot(ride_week, mapping=aes(fill=member_casual,y=avg_rides_week, x=day_of_week)) +
  geom_bar(position='dodge', stat='identity')+
 
  labs(
    title = "Average Trip Duration",
    subtitle = "Average Trip_duration for every WeekDay MembervsCasual",
    caption = "Figure 2",
    x = "day of week",
    y = "average number of ride duration",
  )

#total trip Duration 
ggplot(ride_week, mapping=aes(fill=member_casual,y=total_duration_week, x=day_of_week)) +
  geom_bar(position='dodge', stat='identity')+labs(
    title = "total duration each day of the week ",
    subtitle = "Total duration for every day of week Member vs Casual",
    caption = "Figure 3",
    x = "day of week",
    y = "total number of rides",
  )


ride_month=trips_time_df %>% 
  group_by(member_casual,month_of_year) %>% 
  summarise(number_of_rides=n(),
            avg_rides_day = mean(duration),
            total_duration_day = sum(duration))

ggplot(ride_month,mapping= aes(fill=member_casual,y=number_of_rides, x=month_of_year)) +
  geom_bar(position='dodge', stat='identity')+labs(
    title = "Number of Trips per day of week",
    subtitle = "Number of trips for every month and by users",
    caption = "Figure 4",
    x = "month",
    y = "number of rides",
  )


ride_week=trips_time_df %>% 
  group_by(member_casual,hour_of_day) %>% 
  summarise(number_of_rides=n())
            

ggplot(ride_week,mapping= aes(fill=member_casual,y=number_of_rides, x=hour_of_day)) +
  geom_bar(position='dodge', stat='identity')+labs(
    title = "Number of Trips per hour of day",
    subtitle = "Number of trips for every hour of the day member vs casual",
    caption = "Figure 5",
    x = "hour of day",
    y = "number of rides",
  )

  

#summarizing data 
ride_per_bike=trips_time_df %>% 
  group_by(member_casual,rideable_type) %>% 
  summarise(number_of_rides=n(),
            avg_rides_per_bike = mean(duration),
            total_duration_bike = sum(duration))

#Most popular bike Type Member VS Casual 
ggplot(ride_per_bike,mapping= aes(fill=member_casual,y=number_of_rides, x=rideable_type)) +
  geom_bar(position='dodge', stat='identity')+labs(
    title = "Number of Trips per Bike Type",
    subtitle = "Number of trips for every bike type member vs casual",
    caption = "Figure 6",
    x = "bike type",
    y = "number of rides",
  )

ggplot(ride_per_bike,mapping= aes(fill=member_casual,y=avg_rides_per_bike, x=rideable_type)) +
  geom_bar(position='dodge', stat='identity')+labs(
    title = "average time per Bike",
    subtitle = "average trip Duration for every bike type member vs casual",
    caption = "Figure 7",
    x = "bike type",
    y = "average duration of rides",
  )

ggplot(ride_per_bike,mapping= aes(fill=member_casual,y=total_duration_bike, x=rideable_type)) +
  geom_bar(position='dodge', stat='identity')+labs(
    title = "total time per Bike",
    subtitle = "total duration of trip for every bike type member vs casual",
    caption = "Figure 8",
    x = "bike type",
    y = "total duration of rides",
  )

# Most Popular Start_Stations

stations = biker_data_3 %>% 
  select(
    ride_id, start_station_name, end_station_name, start_lat, start_lng,
    end_lat, end_lng, member_casual, duration
  ) %>% 
  drop_na(
    start_station_name, end_station_name
  )

location=stations %>% 
  group_by(member_casual,start_station_name) %>% 
  summarise(number_of_rides=n()) %>% 
  arrange(-number_of_rides)

ggplot(location[1:10,],mapping= aes(fill=member_casual,y=number_of_rides, x=start_station_name)) +
  geom_bar(position='dodge', stat='identity')+labs(
    title = "Popular start Stations",
    subtitle = "Top 10 most popular Start Stations MembervsCasual",
    caption = "Figure 9",
    x = "station_name",
    y = "total number of rides",
  )+theme(axis.text.x = element_text(angle = 65, vjust = 1, hjust = 1))




