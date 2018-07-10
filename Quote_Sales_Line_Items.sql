/**********************
Program Name: Quote_Sales_Line_Items.sql
Program Description: Build a quote view/query that shows all the quotes entered into GP.  THis doesn't include quotes
  that originate from Magento
Developer: Kyle MacKenzie
Tables used
	1. SalesLineItems - This is a View for all Sales Line Items.  It comes from multiple tables
It also contains 2 seperate queries to build a low level look at BOMs and Kits items it detail
Updates: V1 - 7/9/2018
**********************/
alter view Quote_Sales_Line_Items as
select 
	sli.[Sop Type], sli.[Sop Number], sli.[Item Number], sli.[Item Description], sli.QTY, sli.[Extended Cost], sli.[Extended Price], sli.[Customer Name], sli.[Customer PO Number],
	loc.REPORTING_CUSTOMER_CLASS as [Customer Class], loc.BUDGET_CUSTOMER_CLASS as [Budget Customer Class], loc.LOCATION_TYPE as [Location Type], loc.DIVISION,
	sli.[Customer Discount], sli.[Document Status], sli.[Item Class Code], sli.[Item Type], sli.[Master Number], sli.[Originating Trade Discount Amount], sli.[Salesperson ID from Sales Transaction],
	sli.[User Category Value 1] as BDB_Product,
	sli.[User Category Value 2] as Active_Item,
	sli.[User Category Value 3] as Color,
	sli.[User Category Value 4] as Style,
	sli.[User Category Value 5] as Category,
	sli.[Void Status],
	(sli.[Extended Price] - sli.[Originating Trade Discount Amount]) AS [Quote Amount],
	cast(sli.[Document Date] as date) as [Quote Date]
from 
	blu.dbo.saleslineitems sli
	inner join
	it.dbo.LOCATION_INFO loc
		on sli.[Customer Class] = loc.SYSTEM_CUSTOMER_CLASS
		
where 
	sli.[Sop Type] = 'Quote' and sli.[Document Date] > '2014-01-01'
