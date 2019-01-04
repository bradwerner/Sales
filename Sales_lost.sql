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
V2 - 01/03/2019

1. Storing data in IT_DEV.dbo.data_rpt_orders table for all updates type. This will give us total sales and stock status for 
   every update and I ma storing just the instock and out status in the final output table. 
   
 v3 - 01/04/2019
 1. Adding filters to Temp table to get the items which have been invoiced before to filter out new items.
 2. Including only sellable items in the analysis.
 3. Considering DNR as Instock.
		
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
and [Document Date] < '2018-02-01'
    and [Location Code] = 'BDMN'
    and [SOP Type] = 'Invoice'    
    and [Void Status] = 'Normal'    
    and [SOP Number]  NOT LIKE '%SVC%'
    and [Extended Price] > 0
group by [Item Number]
) a

--------selecting data from temp table

select * from #temp  --------1977

----Creating a new table in IT_Dev and storing data from salesLineitem Table

select a.* into IT_DEV.dbo.data_saleslineitem from 
(select [Item Number], [Document Date], sum(QTY) as 'total qty' from blu.dbo.SalesLineItems sli
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

select * from IT_DEV.dbo.data_saleslineitem ------56802

----Creating a new table in IT_Dev and storing data from OTB_RPT_INVENTORY_CHECK_DAILY_LOG Table. This table contains all updates

select a.* into IT_DEV.dbo.data_rpt_orders from 
(select item_number,
coalesce(LAG(Change_Date,1,Null) OVER (PARTITION BY item_number ORDER BY Change_date),'2018-02-01') AS PrevDate, Change_Date,
Original_Note, New_Note,Updates from it.dbo.OTB_RPT_INVENTORY_CHECK_DAILY_LOG 
where item_number IN (select [item number] from #temp) 
---and Updates in ('Instock to Out', 'Out to Instock')
) a

select * from IT_DEV.dbo.data_rpt_orders ---1776


---Creating table to hold the query results together

Create table IT_DEV.dbo.Sales_lost (item_number varchar(100), [Stock Status] varchar(100), [Total Qty] numeric(19,5), 
Days int, sales_per_day numeric(19,5))
select * from IT_DEV.dbo.Sales_lost

----selecting items to loop over using cursor

DECLARE @item as varchar(100);

DECLARE item_cursor CURSOR FOR                                  -----------423 items stored in item_cursor which are sales inventory items
select t.[Item Number] from #temp t 
inner join
(select distinct item_number from IT_DEV.dbo.data_rpt_orders ) v 
on t.[Item Number] = v.item_number
inner join it.dbo.Level1_Can_we_Build_it lvl with (nolock)
on t.[Item Number] = lvl.[item number]
where lvl.Type = 'Sales Inventory';

OPEN item_cursor

FETCH NEXT FROM item_cursor INTO @item  ---brings first value into @item

WHILE @@FETCH_STATUS = 0                  ---------FETCH_STATUS = 1 means no more items left and the loop exits
BEGIN

INSERT INTO IT_DEV.dbo.Sales_lost (item_number, [Stock Status], [Total Qty], Days, sales_per_day)
select y.[item_number], y.[Stock Status], sum(y.[Total Qty]) as 'Total Qty', sum(y.days) AS 'Days', sum(y.[Total Qty])/ sum(y.days) as 'sales_per_day'
from  (
select x.[item_number], 
CASE
when x.[Stock Status] = 'Out' THEN 'Out'
when x.[Stock Status] = 'Instock' THEN 'Instock'
when x.[Stock Status] = 'DNR' THEN 'Instock' 
end AS 'Stock Status',
sum(x.[total qty]) AS 'Total Qty', x.days from
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
group by x.[item_number],
CASE
when x.[Stock Status] = 'Out' THEN 'Out'
when x.[Stock Status] = 'Instock' THEN 'Instock'
when x.[Stock Status] = 'DNR' THEN 'Instock' End, 
x.[days]
having CASE
when x.[Stock Status] = 'Out' THEN 'Out'
when x.[Stock Status] = 'Instock' THEN 'Instock'
when x.[Stock Status] = 'DNR' THEN 'Instock' End 
 IN ('Instock','Out')                           /*---('Instock','Out','None','Did not exist', 'New - QC', 'New - Ocean', 'OUT-DNR', 'DNR', 'New')*/
) y
group by y.[item_number],y.[Stock Status];

FETCH NEXT FROM item_cursor INTO @item

END
CLOSE item_cursor;
DEALLOCATE item_cursor;

---Final Result

select * from IT_DEV.dbo.Sales_lost
