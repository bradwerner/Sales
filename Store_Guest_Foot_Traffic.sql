/**********************
Program Name: Store_Guest_Foot_Traffic.sql
Program Description: Take Foot Traffic data and merge it with our location reference table.  The code pushes data to Tableau for 
  reporting purposes.
Requestor: Kyle MacKenzie
Developer: Kyle MacKenzie
Tables:
  HEAD_COUNT_TRAFFIC - Table built daily from Head Count that counts daily foot traffic at each of Blu Dot Stores
  LOCATION_INFO - Location reference table for all things BLu Dot
Updates: V1 - 4/27/2018
**********************/
select 
    h.HeadCount_Store_ID as [Head Count Store ID]
    ,h.[Traffic_Date] as [Traffic Date]
    ,h.[Traffic_Hour] as [Traffic Hour]
    ,h.[Traffic_Count] as [Traffic Count]
    ,h.[Traffic_Date_Format] as [Traffic Date Format]
    ,l.REPORTING_CUSTOMER_CLASS as [Customer Class]
From 
    it.dbo.HEAD_COUNT_TRAFFIC h
    inner join
    it.dbo.LOCATION_INFO l
	on h.HeadCount_Store_ID = l.Head_Count_Store
