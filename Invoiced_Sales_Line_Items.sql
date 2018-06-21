/**********************
Program Name: Invoiced_Sales_Line_Items.sql
Program Description: Invoice Sales down to the line item level.  In order to apply a correct Freight Amount I needed to count the records in each order.
	THat number is used to divide the Freight Amount.  IF there are other fields that need it there is a column called order_row_Count.
Requestor: Kyle MacKenzie
Developer: Kyle MacKenzie
Tables used
	1. SalesLineItems - This is a View for all Sales Line Items.  It comes from multiple tables
Updates: V1 - 2/22/2018
		v2 - 3/8/2018 - added the location information and attributes.  Added Item_Level field as well
		v3 - 3/14/2018 - Added a [Customer Name from Customer Master], We realized that Wholesale partners and others get a Name with (Customer Name and Number) in it.  So if a customer
			has had orders placed directly in GP and Magento the name will be different

**********************/

Select
	b.[SOP Type]
	,b.[SOP Number]
	,b.[Item Number]
	,b.[Item Description]
	,substring(b.[Item Number], 3,1) as Item_Level
	,b.Qty
	,b.[Extended Cost]
	,b.[Extended Price]
	,b.[Unit Cost]
	,b.[Unit Price]
	,b.[Customer Number]
	,b.[Actual Ship Date]
	,b.[Back Order Date]
	,b.[Line Item Sequence]
	,b.[System Customer Class]
	,b.[Customer Class]
	,b.[Budget Customer Class]
	,b.[Location Type]
	,b.DIVISION
	,b.[Customer Discount]
	,b.[Customer Name]
	,b.[Customer Name from Customer Master]
	,b.[Customer PO Number]
	,b.[Document Date]
	,Round(b.[Freight Amount] / a.order_row_Count, 4) as [Freight Amount] -- Looks like at the Order Level
	,round(b.[Freight Tax Amount] / a.order_row_Count, 4) as [Freight Tax Amount]-- Looks like it is Order Level
	,b.[Item Class Code]
	,b.[Item Type]
	,b.[Location Code]
	,b.[Master Number]
	,b.[Order Date]
	,b.[Original Number]
	,b.[Original Type]
	,b.[Originating Trade Discount Amount]
	,b.[Posting Status]
	,b.[Requested Ship Date]
	,b.[Salesperson ID from Sales Transaction]
	,b.[Tax Amount]
	,b.[Trade Discount Amount]
	,b.[Trade Discount Percent]
	,b.BDB_Product
	,b.Active_Item
	,b.Color
	,b.Style
	,b.Category
	,b.[Void Status]
	,b.[Address 1 from Sales Line Item]
	,b.[City from Sales Line Item]
	,b.[State from Sales Line Item]
	,b.[Zip Code from Sales Line Item]
	,a.order_row_Count
from
	(
	Select
		i.[SOP NUmber], i.[SOP Type], max(i.rownumber) as order_row_Count
	from
		(
		SELECT row_number() over (Partition by [SOP NUmber] order by [SOP NUmber], [Item Number] ) as rownumber,
		[SOP Type]
			  ,[SOP Number]
		  FROM
			[BLU].[dbo].[SalesLineItems] sli
		  where
			(([SOP Type] = 'Invoice' AND [Void Status] = 'Normal' AND [Document Status] = 'Posted' AND [SOP Number] NOT LIKE '%SVC%')
			OR ([SOP Type] = 'Return' AND [Void Status]='Normal' AND [Document Status] = 'Posted'))
			AND [Document Date] >= '2010-01-01'
		) i
	group by i.[SOP NUmber], i.[SOP Type]
	) a

inner join

(
	SELECT
		sli.[SOP Type]
		,sli.[SOP Number]
		,sli.[Item Number]
		,sli.[Item Description]
		,case when sli.[SOP Type] = 'Invoice' then sli.[QTY] else - sli.[QTY] end as Qty
		,case when sli.[SOP Type] = 'Invoice' then sli.[Extended Cost] else - sli.[Extended Cost] end as [Extended Cost]
		,case when sli.[SOP Type] = 'Invoice' then sli.[Extended Price] else - sli.[Extended Price] end as [Extended Price]
		,case when sli.[SOP Type] = 'Invoice' then sli.[Unit Cost] else - sli.[Unit Cost] end as [Unit Cost]
		,case when sli.[SOP Type] = 'Invoice' then sli.[Unit Price] else - sli.[Unit Price] end as [Unit Price]
		,sli.[Customer Number]
		,cast(sli.[Actual Ship Date] as date) as [Actual Ship Date]
		,cast(sli.[Back Order Date] as date) as [Back Order Date]
		,sli.[Line Item Sequence]
		,sli.[Customer Class] as [System Customer Class]
		,loc.REPORTING_CUSTOMER_CLASS as [Customer Class]
		,loc.BUDGET_CUSTOMER_CLASS as [Budget Customer Class]
		,loc.LOCATION_TYPE as [Location Type]
		,loc.DIVISION
		,sli.[Customer Discount]
		,sli.[Customer Name]
		,sli.[Customer Name from Customer Master]
		,sli.[Customer PO Number]
		,cast(sli.[Document Date] as date) as [Document Date]
		,sli.[Freight Amount] -- Looks like at the Order Level
		,sli.[Freight Tax Amount] -- Looks like it is Order Level
		,sli.[Item Class Code]
		,sli.[Item Type]
		,sli.[Location Code]
		,sli.[Master Number]
		,sli.[Order Date]
		,sli.[Original Number]
		,sli.[Original Type]
		,case when sli.[SOP Type] = 'Invoice' then sli.[Originating Trade Discount Amount] else -sli.[Originating Trade Discount Amount] end as [Originating Trade Discount Amount]
		,sli.[Posting Status]
		,cast(sli.[Requested Ship Date] as date) as [Requested Ship Date]
		,sli.[Salesperson ID from Sales Transaction]
		,sli.[Tax Amount]
		,sli.[Trade Discount Amount]
		,sli.[Trade Discount Percent]
		,sli.[User Category Value 1] as BDB_Product
		,sli.[User Category Value 2] as Active_Item
		,sli.[User Category Value 3] as Color
		,sli.[User Category Value 4] as Style
		,sli.[User Category Value 5] as Category
		,sli.[Void Status]
		,sli.[Address 1 from Sales Line Item]
		,sli.[City from Sales Line Item]
		,sli.[State from Sales Line Item]
		,sli.[Zip Code from Sales Line Item]

	FROM
		[BLU].[dbo].[SalesLineItems] sli
		Inner join
		IT.dbo.LOCATION_INFO loc
			on sli.[Customer Class] = loc.SYSTEM_CUSTOMER_CLASS
	where
		(([SOP Type] = 'Invoice' AND [Void Status] = 'Normal' AND [Document Status] = 'Posted' AND [SOP Number] NOT LIKE '%SVC%')
		OR ([SOP Type] = 'Return' AND [Void Status]='Normal' AND [Document Status] = 'Posted'))
		AND [Document Date] >= '2010-01-01'
	) b
on a.[SOP Number] = b.[SOP Number] and a.[SOP Type] = b.[SOP Type]
