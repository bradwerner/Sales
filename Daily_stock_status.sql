/**********************
Program Name: daily_stock_status.sql
Program Description: This report contains distinct item-Number from OTB_RPT_INVENTORY_CHECK_DAILY_LOG table 
and its stock status everyday from 02/01/2018 till date.
  
Requestor: Kyle M
Developer: Ankita Gupta

Tables used
  1. OTB_RPT_INVENTORY_CHECK_DAILY_LOG
  
Updates: 
***************************/


----Creating a temp table to hold all distinct item from OTB_RPT_INVENTORY_CHECK_DAILY_LOG table and dates from feb1, 2018 
----till today from ACCT_DATE table.

select a.* into #item_date from
(select t.[Item_Number], cal.[Date] 
from 
(select distinct item_number from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG) t     
cross join
it.dbo.ACCT_DATE cal   
where cal.[date] >= '2018-02-01' and cal.[date] <= getdate()
) a

select * from #item_date

----creating table from OTB_RPT_INVENTORY_CHECK_DAILY_LOG table with new fields called PrevDate and NextDate

select b.* into #daily_check_log from
(select item_number,
coalesce(LAG(Change_Date,1,Null) OVER (PARTITION BY item_number ORDER BY Change_date),'2018-02-01') AS PrevDate, Change_Date,
coalesce(LEAD(Change_date,1,NULL) OVER (PARTITION BY item_number ORDER BY Change_date), CAST(getdate() AS DATE)) AS 'NextDate',
Original_Note, New_Note,Updates from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG 
) b

select * from #daily_check_log 

----Creating table with item_number and [Date] as PK to hold the query results together

CREATE TABLE IT_DEV.dbo.daily_stock_status (
	item_number varchar(100), 
	[Date] date, 
	[Stock Status] varchar(100),
	[Available] varchar(50),
	CONSTRAINT item_date PRIMARY KEY(item_number,[Date])	
)

select * from IT_DEV.dbo.daily_stock_status

----Code to populate the table craeted
----selecting items to loop over using cursor

DECLARE @item as varchar(100);

DECLARE item_cursor CURSOR FOR                                 
select distinct item_number from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG;

OPEN item_cursor
FETCH NEXT FROM item_cursor INTO @item  ---brings first value into @item

WHILE @@FETCH_STATUS = 0                  ---------FETCH_STATUS = 1 means no more items left and the loop exits
BEGIN

INSERT INTO IT_DEV.dbo.daily_stock_status (item_number, [Date], [Stock Status], Available)
select a.[item_Number], a.[Date],
case
---condition 1
when cast(a.[Date] AS DATE) >= b.PrevDate and cast(a.[Date] AS DATE) < CAST(b.Change_Date AS DATE) then b.Original_Note
---condition 2
WHEN cast(b.[Change_Date] AS DATE) = (select max(Change_Date) from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where item_number = @item)
AND b.Change_Date = b.NextDate  AND cast(a.[Date] AS DATE) >= (select max(Change_Date) from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where item_number = @item) THEN NULL
---condition 3
WHEN cast(b.[Change_Date] AS DATE) = (select max(Change_Date) from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where item_number = @item) 
AND (cast(a.[Date] AS DATE)  = b.PrevDate AND cast(a.[Date] AS DATE)  = b.Change_Date) Then b.New_Note
---codition 4
WHEN cast(a.[Date] AS DATE)  = b.PrevDate AND cast(a.[Date] AS DATE)  = b.Change_Date Then NULL
---condition 5
when cast(b.[Change_Date] AS DATE) = (select max(Change_Date) from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where item_number = @item)
--AND (cast(a.[Date] AS DATE)  <> b.PrevDate AND cast(a.[Date] AS DATE)  <> b.Change_Date)
AND (cast(a.[Date] AS DATE)  between (select max(Change_Date) from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where item_number = @item) AND CAST(GETDATE() AS date))  then b.New_Note
end as 'Stock Status',
CASE
when [Stock Status] = 'DNR' OR [Stock Status] = 'Instock' THEN 'Yes'
ELSE 'No'
END AS 'Available'
from
#item_date a
join
#daily_check_log b
on a.item_number = b.[item_number] 
AND b.item_number = @item
and
case
---condition 1
when cast(a.[Date] AS DATE) >= b.PrevDate and cast(a.[Date] AS DATE) < CAST(b.Change_Date AS DATE) then b.Original_Note
---condition 2
WHEN cast(b.[Change_Date] AS DATE) = (select max(Change_Date) from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where item_number = @item)
AND b.Change_Date = b.NextDate  AND cast(a.[Date] AS DATE) >= (select max(Change_Date) from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where item_number = @item) THEN NULL
---condition 3
WHEN cast(b.[Change_Date] AS DATE) = (select max(Change_Date) from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where item_number = @item) 
AND (cast(a.[Date] AS DATE)  = b.PrevDate AND cast(a.[Date] AS DATE)  = b.Change_Date) Then b.New_Note
---codition 4
WHEN cast(a.[Date] AS DATE)  = b.PrevDate AND cast(a.[Date] AS DATE)  = b.Change_Date Then NULL
---condition 5
when cast(b.[Change_Date] AS DATE) = (select max(Change_Date) from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where item_number = @item)
--AND (cast(a.[Date] AS DATE)  <> b.PrevDate AND cast(a.[Date] AS DATE)  <> b.Change_Date)
AND (cast(a.[Date] AS DATE)  between (select max(Change_Date) from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where item_number = @item) AND CAST(GETDATE() AS date))  then b.New_Note
end IS NOT NULL;

FETCH NEXT FROM item_cursor INTO @item

END
CLOSE item_cursor;
DEALLOCATE item_cursor;

---Final Result----has everything except todays stock status for item whose status changed today

select * from IT_DEV.dbo.daily_stock_status

----Manually inserted data in table whose status changed today(the day above code ran).

----SQL Agent job needs to be scheduled everyday after 4:00 PM to insert the stock status of each item daily.

---CASE 1:
----Update table with changes that happened today

Insert into IT_dev.dbo.daily_stock_status (item_number, [Date], [Stock Status], Available)
select x.item_number, y.Change_Date, y.New_Note,-------, x.row_num, y.row_num 
CASE
when y.New_Note = 'DNR' OR y.New_Note = 'Instock' THEN 'Yes'
ELSE 'No'
END AS 'Available'
from 
(select item_number, max(row_num) as 'row_num' from (
select item_number, Change_date, New_Note, ROW_NUMBER() OVER (PARTITION BY item_number ORDER BY Change_Date ASC) row_num
from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where change_date = cast(getdate() as date)) a
group by  item_number) x
inner join
(select item_number, Change_date, New_Note, ROW_NUMBER() OVER (PARTITION BY item_number ORDER BY Change_Date ASC) row_num
from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where change_date = cast(getdate() as date)) y
on x.item_number = y.item_number
and x.row_num = y.row_num

----CASE 2:
----Inserting data in daily_stock_status_updated whose status on a day is same as yesterday.

Insert into IT_dev.dbo.daily_stock_status (item_number, [Date], [Stock Status], Available)
select item_number, cast(getdate() as date) as 'Date', [Stock Status],
CASE
when [Stock Status] = 'DNR' OR [Stock Status] = 'Instock' THEN 'Yes'
ELSE 'No'
END AS 'Available'
from IT_dev.dbo.daily_stock_status_updated 
where 
item_number NOT IN
(select distinct item_number from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where change_date = cast(getdate() as date))
AND 
[Date] = cast(getdate() - 1  as date)







