/**********************
Program Name: Sales_lost.sql
Program Description: This report will show for all the item sold after feb 2018 which are not new ,that is it had been sold before,
the total quantity sold and numbers of days when it was in stock vs out of stock.
  
Requestor: Susanna
Developer: Ankita Gupta

Tables used
	1. SalesLineItems
  2. Location_info
  3. OTB_RPT_INVENTORY_CHECK_DAILY_LOG
  
Updates: V1 - 12/31/2018
		
***************************/


----Dropping the table which will populate with new data each time the code runs:

DROP table IT_DEV.dbo.data_saleslineitem
DROP table IT_DEV.dbo.data_rpt_orders
DROP table IT_DEV.dbo.Sales_lost
DROP table #temp

----creating temp table to store unique item number after feb 2018 but its been first bought before feb 2018 its not new

select a.* into #temp from
(
select [Item Number], min([Document Date]) as 'first bought'
from blu.dbo.saleslineitems 
where [Item Number] IN
( 
select distinct [Item Number]
from blu.dbo.SalesLineItems sli
join it.dbo.LOCATION_INFO loc WITH (nolock)
on sli.[Customer Class] = loc.[SYSTEM_CUSTOMER_CLASS]
where sli.[Document Date] >= '2018-02-01'
and sli.[Original Type] IN ('','Quote')
and sli.[Location Code] = 'BDMN'
and sli.[SOP Type] = 'Order'	
and sli.[Void Status] = 'Normal'	
and sli.[SOP Number]  NOT LIKE '%SVC%'
and sli.[Extended Price] > 0
and loc.division = 'Blu Dot')
group by [Item Number]
HAVING min([Document Date]) < '2018-02-01'
) a

--------selecting data from temp table
select * from #temp -----2135

----Creating a new table in IT_Dev and storing data from salesLineitem Table


select a.* into IT_DEV.dbo.data_saleslineitem from 
(select [Item Number], [Document Date], sum(QTY) as 'total qty' from blu.dbo.SalesLineItems sli------------------------------------75085
join it.dbo.LOCATION_INFO loc WITH (nolock)
on sli.[Customer Class] = loc.[SYSTEM_CUSTOMER_CLASS]
where [Item Number] IN (select [item number] from #temp)
AND sli.[Document Date] >= '2018-02-01'
and sli.[Original Type] IN ('','Quote')
and sli.[Location Code] = 'BDMN'
and sli.[SOP Type] = 'Order'	
and sli.[Void Status] = 'Normal'	
and sli.[SOP Number]  NOT LIKE '%SVC%'
and sli.[Extended Price] > 0
and loc.division = 'Blu Dot'
group by [Item Number], [Document Date]) a

select * from IT_DEV.dbo.data_saleslineitem ---58225

----Creating a new table in IT_Dev and storing data from rpt_orders Table

select a.* into IT_DEV.dbo.data_rpt_orders from 
(select item_number,
coalesce(LAG(Change_Date,1,Null) OVER (PARTITION BY item_number ORDER BY Change_date),'2018-02-01') AS PrevDate, Change_Date,
Original_Note, New_Note,Updates from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG 
where item_number IN (select [item number] from #temp) 
and Updates in ('Instock to Out', 'Out to Instock')) a

select * from IT_DEV.dbo.data_rpt_orders ---1586

---Creating table to hold the query results together
Create table IT_DEV.dbo.Sales_lost (item_number varchar(100), [Stock Status] varchar(100), [Total Qty] numeric(19,5), 
Days int, sales_per_day numeric(19,5))
select * from IT_DEV.dbo.Sales_lost


----selecting items to loop over using cursor

DECLARE @item as varchar(100);

DECLARE item_cursor CURSOR FOR
select t.[Item Number] from #temp t 
inner join
(select distinct item_number from IT_DEV.dbo.data_rpt_orders ) v 
on t.[Item Number] = v.item_number;

OPEN item_cursor

FETCH NEXT FROM item_cursor INTO @item  ---brings first value into @item

WHILE @@FETCH_STATUS = 0
BEGIN

INSERT INTO IT_DEV.dbo.Sales_lost (item_number, [Stock Status], [Total Qty], Days, sales_per_day)
select y.[item_number], y.[Stock Status], sum(y.[Total Qty]) as 'Total Qty', sum(y.days) AS 'Days', sum(y.[Total Qty])/ sum(y.days) as 'sales_per_day'
from  (
select x.[item_number], x.[Stock Status], sum(x.[total qty]) AS 'Total Qty', x.days from
(
select a.[Item Number], a.[Document Date], a.[total qty], b.item_number,b. PrevDate, b. Change_Date,  b.New_Note, b.original_Note,b.Updates,
case
when cast(a.[Document Date] AS DATE)   >= CAST(b.PrevDate AS DATE) and cast(a.[Document Date] AS DATE) < CAST(b.Change_Date AS DATE) then b.Original_Note
when cast(b.[Change_Date] AS DATE) = (select max(Change_Date) from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where item_number = @item)
AND (cast(a.[Document Date] AS DATE)  between (select max(Change_Date) from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where item_number = @item) AND CAST(GETDATE() AS date))  then b.New_Note
end as 'Stock Status',
case
when cast(a.[Document Date] AS DATE)  >= CAST(b.PrevDate AS DATE) and cast(a.[Document Date] AS DATE) < CAST(b.Change_Date AS DATE) then DATEDIFF(day, b.PrevDate, b.Change_Date)
when cast(b.[Change_Date] AS DATE) = (select max(Change_Date) from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where item_number = @item)
AND (cast(a.[Document Date] AS DATE)  between (select max(Change_Date) from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG where item_number = @item) AND CAST(GETDATE() AS date))  
then DATEDIFF(day, b.Change_Date,GETDATE())
end as 'days'
 from IT_DEV.dbo.data_saleslineitem a 
cross join
IT_DEV.dbo.data_rpt_orders b with (nolock)
where a. [Item Number] = b.[item_number]
AND a. [Item Number] = @item
) x
group by x.[item_number],x.[Stock Status], x.[days]
having x.[Stock Status] IN ('Instock','Out')
) y
group by y.[item_number],y.[Stock Status];

FETCH NEXT FROM item_cursor INTO @item

END
CLOSE item_cursor;
DEALLOCATE item_cursor;


---Final Result

select * from IT_DEV.dbo.Sales_lost
