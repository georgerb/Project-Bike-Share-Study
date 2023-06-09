-- the data was binded during Analysis Using R 
-- this data contains bike trips of 12 consecutive month 
-- first lets get a sense of the data 
--ride_id should be of length 16 ,some fields are of differnet length and are invalid 
SELECT LEN(ride_id), count(*)
FROM Biker_Data
GROUP BY LEN(ride_id);

SELECT TOP 10 *
FROM Biker_Data
ORDER BY started_at DESC


-- find null values in the location fields 
SELECT *
FROM Biker_Data
WHERE start_lat ='NA' OR
 start_lng ='NA' OR
 end_lat ='NA' OR
 end_lng ='NA' OR
 start_station_id='NA'OR
 start_station_name='NA'OR
 end_station_id='NA' OR
 end_station_name='NA';
--making sure that there are only two types of bikers member and casual 
SELECT DISTINCT member_casual
FROM Biker_Data
--making sure that there are only three types of bikes 
SELECT DISTINCT rideable_type
FROM Biker_Data

--making sure that there are no duplicates
--no duplicates found 
WITH duplicates AS (
SELECT *,
ROW_NUMBER()OVER(
    PARTITION BY ride_id,
                 rideable_type ,
                 started_at,
                 ended_at
                 ORDER BY ride_id
) AS row_number 
FROM Biker_Data
)

SELECT * 
FROM duplicates 
WHERE row_number>1

-- now lets start cleaning the data 
CREATE TABLE #biker_info(
ride_id NVARCHAR(MAX),
rideable_type VARCHAR(MAX),
started_at DATETIME2(7),
ended_at DATETIME2(7),
start_station_name VARCHAR(MAX),
start_station_id NVARCHAR(MAX),
end_station_name VARCHAR(MAX),
end_station_id NVARCHAR(MAX),
start_lat NVARCHAR(MAX),
start_lng NVARCHAR(MAX),
end_lat NVARCHAR(MAX),
end_lng NVARCHAR(MAX),
member_casual VARCHAR(MAX)

)

INSERT INTO #biker_info(ride_id,rideable_type,started_at,ended_at,start_station_name,start_station_id,end_station_name,end_station_id,start_lat,start_lng,end_lat,end_lng,member_casual)
SELECT ride_id,rideable_type,started_at,ended_at,start_station_name,start_station_id,end_station_name,end_station_id,start_lat,start_lng,end_lat,end_lng,member_casual
FROM Biker_Data

-- remove null values from the temp table 

DELETE FROM #biker_info
WHERE start_lat ='NA' OR
 start_lng ='NA' OR
 end_lat ='NA' OR
 end_lng ='NA' OR
 start_station_id='NA'OR
 start_station_name='NA'OR
 end_station_id='NA' OR
 end_station_name='NA'

-- remove invalid fields 
 DELETE FROM #biker_info
 WHERE LEN(ride_id) <>16

 --add and find the duration of each trip 

 ALTER TABLE #biker_info
ADD Trip_duration FLOAT

UPDATE  #biker_info
SET  Trip_duration =CONVERT(DECIMAL(30,2),Cast(DATEDIFF(SECOND,started_at,ended_at) as FLOAT)/60)

--remove every row where the trip duration is less than 1 minutes or greater than 1 day 
DELETE FROM #biker_info
WHERE (Trip_duration <1) OR (Trip_duration >1440)
--extracting the month , weekday,day and hour and store them as seperate fields 
ALTER TABLE #biker_info 
ADD hour INTEGER,
    Day INTEGER,
    day_of_week VARCHAR(MAX),
    month VARCHAR(MAX);

    UPDATE #biker_info
    SET hour =DATENAME(HOUR, started_at ),
        Day= DATENAME(DAY,started_at),
        day_of_week=DATENAME(WEEKDAY, started_at ),
        month = DATENAME(MONTH,started_at)




--number of rides per bike type 
SELECT rideable_type, member_casual, count(*) AS Nb_of_rides
   FROM #biker_info
   GROUP BY rideable_type, member_casual
   ORDER BY member_casual, Nb_of_rides DESC

-- average trip duration per bike type 

SELECT rideable_type, member_casual, Round(AVG(Trip_duration),0) AS Avg_duration
   FROM #biker_info
   GROUP BY rideable_type, member_casual
   ORDER BY member_casual, Avg_duration DESC

   --number of rides and average trip duration per hour  
SELECT hour, member_casual, count(*) AS Nb_of_rides,Round(AVG(Trip_duration),0) AS Avg_duration
   FROM #biker_info
   GROUP BY hour, member_casual
   ORDER BY member_casual, Nb_of_rides DESC

   --number of rides and avearage trip duration of every week day 
   SELECT day_of_week, member_casual, count(*) AS Nb_of_rides, AVG(Trip_duration) as AVG_duration
   FROM #biker_info
   GROUP BY day_of_week, member_casual
   ORDER BY member_casual, Nb_of_rides DESC ,AVG_duration
    --number of rides and average trip duration  per month 
   SELECT month, member_casual,day_of_week, count(*) AS Nb_of_rides,AVG(Trip_duration) as AVG_duration
   FROM #biker_info
   GROUP BY month,day_of_week, member_casual
   ORDER BY member_casual, Nb_of_rides DESC

-- top 10 most popular location for casual riders 
    SELECT top 10 start_station_name, member_casual, count(*) AS Nb_of_rides
   FROM #biker_info
   where member_casual= 'casual' 
   GROUP BY start_station_name,member_casual
   ORDER BY member_casual, Nb_of_rides DESC

   -- top 10 most popular location for members
    SELECT top 10 start_station_name, member_casual, count(*) AS Nb_of_rides
   FROM #biker_info
   WHERE member_casual= 'member' 
   GROUP BY start_station_name,member_casual
   ORDER BY member_casual, Nb_of_rides DESC

-- create a summary of the Data at hand 
--Nb of biker , total number of members ,total number of casual,AVG trip duration for casual and member 
  SELECT Count(*) AS toal_users ,(
  SELECT count(*)
  FROM #biker_info
  WHERE member_casual = 'member') AS total_member,(
  SELECT count(*)
  FROM #biker_info
  WHERE member_casual = 'casual') AS total_casual,(
  SELECT AVG(Trip_duration)
  FROM #biker_info
  WHERE member_casual = 'member') AS AVG_trip_casual,(
  SELECT AVG(Trip_duration)
  FROM #biker_info
  WHERE member_casual = 'casual') AS AVG_trip_duration_member
   
FROM #biker_info
  
