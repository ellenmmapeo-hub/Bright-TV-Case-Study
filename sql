select * from `workspace`.`default`.`1774896982744_bright_tv_dataset` limit 100;
select * from `workspace`.`default`.`bright_tv_consumer_profiles` limit 100;


--DATA Exploration Analysis(DEA) ON Bright TV viewership details
--USERID,CHANNEL2,RECORSDATE2,DURATION2

SELECT COUNT (`UserID`) AS Number_of_Users,
       COUNT(DISTINCT `Channel2`) AS No_of_Channels,
       MIN (TO_DATE(`RecordDate2`,'yyyy/MM/dd')) AS LASTVIEW_DATE,
       MAX (TO_DATE(`RecordDate2`,'yyyy/MM/dd')) AS FIRSTVIEW_DATE,
       MIN (`DURATION 2`) AS SHORTEST_DURATION,
       MAX(`DURATION 2`) AS LONGEST_DURATION
FROM `workspace`.`default`.`1774896982744_bright_tv_dataset`;

--Checking the number of users per channel
SELECT DISTINCT `Channel2` AS Name_of_Channels,
       COUNT (`UserID`) AS Number_of_Users
FROM `workspace`.`default`.`1774896982744_bright_tv_dataset`
GROUP BY `Channel2`
ORDER  BY `Number_of_Users` DESC;

--DATA EXPLORATION  Analysis for UserProfiles
select * from `workspace`.`default`.`bright_tv_consumer_profiles` limit 100;

Select COUNT(`UserID`),
        MIN (`Age`) AS youngest_age,
       MAX (`Age`) AS oldest_age,
       AVG (`Age`) AS AvgAge,
       PERCENTILE (`Age`) AS MEDAge
FROM `workspace`.`default`.`bright_tv_consumer_profiles`;

--Number of users in the user profile records,count by race 
SELECT DISTINCT `Race` AS RaceName,
COUNT (`UserID`) AS Number_of_Users 
FROM `workspace`.`default`.`bright_tv_consumer_profiles`
GROUP BY `Race`;

--Number of users in the user profile records,count by gender
SELECT DISTINCT `Gender`AS Gender_Name,
COUNT (UserID) AS Number_of_Users
FROM `workspace`.`default`.`bright_tv_consumer_profiles`
GROUP BY `Gender`;

--Number of users per age
SELECT DISTINCT `Age`,
COUNT(`UserID`) AS Number_of_Users
FROM `workspace`.`default`.`bright_tv_consumer_profiles`
GROUP BY `Age`;

--Number of viewers per province
SELECT DISTINCT `Province`,
COUNT(`UserID`) AS Number_of_Users
FROM `workspace`.`default`.`bright_tv_consumer_profiles`
GROUP BY `Province`;

--__MAIN CODE_________________________________________________

--JOINING THE TABLES
WITH base AS (
SELECT 
A.UserID,
CASE WHEN A.Gender IN ('None', ' ', '') OR A.Gender IS NULL THEN 'UnSpecified' ELSE A.Gender END AS Gender,
CASE WHEN A.Race IN ('None', ' ', '') OR A.Race IS NULL THEN 'Unspecified' ELSE A.Race END AS Race,
A.Age,
CASE WHEN A.Province IN ('None', ' ', '') OR A.Province IS NULL THEN 'Unspecified' ELSE A.Province END AS Province,
CASE WHEN B.Channel2 = 'Null' OR B.Channel2 IS NULL THEN 'Unspecified' ELSE B.Channel2 END AS Channel2,

--Converting UTC to SAST timezone(do this once)
FROM_UTC_TIMESTAMP(TO_TIMESTAMP(B.`RecordDate2`,'yyyy/MM/dd HH:mm'), 'Africa/Johannesburg') AS RecordDate_SAST,
B.`Duration 2` AS `DURATION 2`

FROM `workspace`.`default`.`bright_tv_consumer_profiles` AS A 
LEFT JOIN `workspace`.`default`.`1774896982744_bright_tv_dataset` AS B ON A.UserID = B.UserID)

SELECT 
    UserID,
    Gender,
    Race,
    Age,
    Province,
    Channel2,

    --Formating Date and Time for viewing 
    COALESCE(DATE(RecordDate_SAST), DATE('1900-01-01')) AS ViewDate,
    COALESCE(DATE_FORMAT(RecordDate_SAST,'HH:mm:ss'), 'Unspecified') AS ViewTime,
    
    --Listing the viewing months
    COALESCE(DATE_FORMAT(RecordDate_SAST, 'MMMM'), 'Unspecified') AS MonthoftheYear,
    
    --Listing viewing according to the days of the week
    COALESCE(DATE_FORMAT(RecordDate_SAST, 'EEEE'), 'Unspecified') AS DayoftheWeek,

--Listing the viewing trends in the month 
CASE 
  WHEN DAY(RecordDate_SAST)BETWEEN 1 AND 10 THEN 'EarlyInMonth'
  WHEN DAY(RecordDate_SAST) BETWEEN 11 AND 20 THEN 'MidInMonth'
  WHEN DAY(RecordDate_SAST) BETWEEN 21 AND 31 THEN 'LateInMonth'
  ELSE 'NotSpecified'
END AS ViewsintheMonth,

--Viewing Time Pockets
CASE 
  WHEN HOUR(RecordDate_SAST) BETWEEN 0 AND 10 THEN 'Morning'
  WHEN HOUR(RecordDate_SAST) BETWEEN 11 AND 17 THEN 'Afternoon'
  WHEN HOUR(RecordDate_SAST) BETWEEN 18 AND 23 THEN 'Evening'
  ELSE 'NotSpecified'
END AS ViewingTimes,

--DurationView Time Pockets
CASE
        WHEN DATE_FORMAT(`Duration 2`,'HH:mm:ss') BETWEEN '00:00:00' AND '00:05:00'  THEN '01.5minInsig_View'
        WHEN DATE_FORMAT(`Duration 2`,'HH:mm:ss') BETWEEN '00:05:01' AND '00:15:00' THEN '02.15minAlmost_View'
        WHEN DATE_FORMAT(`Duration 2`,'HH:mm:ss') BETWEEN '00:15:01' AND '00:30:00' THEN '03.30minMin_View'
        WHEN DATE_FORMAT(`Duration 2`,'HH:mm:ss') BETWEEN '00:30:01' AND '00:59:00' THEN '04.59minMax_View' 
        ELSE '05.NotSpecified'
        END AS ViewDuration,

--Age pockets
CASE 
  WHEN Age = 0 THEN 'Unspecified'
  WHEN Age BETWEEN 0.1 AND 18 THEN 'Under 18'
  WHEN Age BETWEEN 18 AND 24 THEN '18-24'
  WHEN Age BETWEEN 25 AND 34 THEN '25-34'
  WHEN Age BETWEEN 35 AND 44 THEN '35-44'
  WHEN Age BETWEEN 45 AND 54 THEN '45-54'
  WHEN Age BETWEEN 55 AND 64 THEN '55-64'
  WHEN Age >= 65 THEN '65+'
  WHEN Age IN ('Other','0','Unknown') THEN 'Unspecified'
  ELSE 'Unspecified'
  END AS Viewing_Age
FROM base;
