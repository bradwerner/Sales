/**********************
Program Name: Demand_Sales_Line_Items.sql
Program Description: Build a Demand Sales Query that encompasses the 4 Different queries that currently
exist to reproduce it.  Also go to Line Item Level so we can really have fun with the data
Requestor: Kyle MacKenzie
Developer: Kyle MacKenzie
Tables used
	1. SalesLineItems - This is a View for all Sales Line Items.  It comes from multiple tables
It also contains 2 seperate queries to build a low level look at BOMs and Kits items it detail
Updates: V1 - 11/1/2017
		V2 in Dec 2017 - Found a bug in Blu Dot's general look at Demand Sales.  If an order in GP starts as a quote it would be excluded.  Added code
			and [Original Type] in ('', 'Quote')
		v3 1/8/2017 - Added a field that figures out if it was a Direct Web Outlet sale or not. And added GP retail price to calculate Discounts applied
		v4 - 1/10/2018 - Removed most of the Web Outlet stuff.  Look in version 3 if you need it.
			- Fixed a bug that didn't remove Void Status = Voided.  added the logic sli.[Void Status] = 'Normal'
		v5 - 1/17/2018 - Added another field.  [Requested Ship Date] for CDP analysis.  [Item Class Code] for Gail
		v6 - 3/7/2018 - Added a location table to give us specifics about locations and Customer Classes.  And ITem_Level.
		v7 - 3/14/2018 - Added a [Customer Name from Customer Master], We realized that Wholesale partners and others get a Name with (Customer Name and Number) in it.  So if a customer
			has had orders placed directly in GP and Magento the name will be different
		v8 - 3/15/2018 - Added a join to a Steelcase view with Shipping information.
		v9 - 3/16/2018 - Added even more steelcase join information so we can figure out if we can build Kit Items
		v10 - 3/20/2018 - Added sli.[Document Status] which will tell you if an order is Open (Posted vs UnPosted).  Added field [Original Type] to results and removed it from the where condition.
			This will help us determine if an item was a backorder item or not.  if we pre-filter for it then we can't get backorder.  
		v11 - 3/30/2018 - Customer service requested that we add the '[Requested Ship Date]' at the Order level and not the line item level.  Added the new field [Requested Ship Date from Sales Transaction]
		v12 - 4/18/2018 - Added our new PO Promise date and if it was calculated or from a PO
		v13 - 4/20/2018 - Added Budget Customer Class
		v14 - 8/6/2018 - Changed the Date to 2016 to speed up the query.  Plus we don't need all this data

Kyle Notes
	1. Web Outlet Sale = 'No' and 20/20 Sale = 'No'.  Originating Subtotal ends in 00 or is Mattress.  It is a sale in October that isn't 20% off RETAIL - Normal Web Sale
	2. Web Outlet Sale = 'No' and 20/20 Sale = 'Not Oct'.  Originating Subtotal ends in 00 or is Mattress.  Assume It is a non Outlet sales - Normal Web Sale
	3. Web Outlet Sale = 'No' and 20/20 Sale = 'Yes'. Originating Subtotal ends in 00 or is Mattress.  Sale in October that is 20% off.  So the No is good - Normal Web Sale
	4. Web Outlet Sale = 'Yes' and 20/20 Sale = 'No'.  Originating Subtotal DOES NOT end in 00.  Not a 20% discount and the sale was in October - Legit Web OUtlet Sale
	5. Web Outlet Sale = 'Yes' and 20/20 Sale = 'Not Oct'.  Originating Subtotal DOES NOT end in 00.  Outside of October so we will assue Outlet - Legit Web Outlet Sales
	6. Web Outlet Sale = 'Yes' and 20/20 Sale = 'Yes'. 	Originating Subtotal DOES NOT end in 00.  It calculates out to a 20 % discount - Normal Web Sale
**********************/
ALTER view [dbo].[Demand_Sales_Line_Items] as
Select
	sli.[Master Number],
	Cast(sli.[Document Date] as Date) as [Demand Date],
	cast(sli.[Requested Ship Date] as Date) as [Requested Ship Date],
	sli.[SOP Number],
	sli.[SOP Type],
	sli.[Customer Class] as [System Customer Class],
	loc.REPORTING_CUSTOMER_CLASS as [Customer Class],
	loc.BUDGET_CUSTOMER_CLASS as [Budget Customer Class],
	loc.LOCATION_TYPE as [Location Type],
	loc.[Division],
	sli.[Customer Name],
	sli.[Customer Name from Customer Master],
	sli.[Customer Number],
	sli.[Customer PO Number],
	sli.[Item Number],
	sli.[Item Description],
	substring(sli.[Item Number], 3,1) as Item_Level,
	sli.[Component Sequence],
	sli.QTY,
	sli.[Item Type],
	sli.[Salesperson ID from Sales Transaction],
	sli.[User Category Value 1] as BDB_Product,
	sli.[User Category Value 2] as Active_Item,
	sli.[User Category Value 3] as Color,
	sli.[User Category Value 4] as Style,
	sli.[User Category Value 5] as Category,
	sli.[Item Class Code],
	sli.[City From Customer Master],
	sli.[City from Sales Transaction],
	sli.[Contact Person from Customer Master],
	sli.[Extended Price] as [Originating Subtotal],
	sli.[Originating Trade Discount Amount],
	(sli.[Extended Price] - sli.[Originating Trade Discount Amount]) AS [Demand Amount],
	ret.UOMPRICE as Retail_Price,
	sli.[Batch Number],
	sli.[Shipping Method from Sales Transaction],
	sli.[QTY To Invoice],
	kit.qtytoinv as [Invoice Level 1],
	sli.[Line Item Sequence],
	cast(stc.[Pick-up date] as date) as [Pick Up Date],
	sli.[Document Status],
	sli.[Original Type],
	cast(sli.[Requested Ship Date from Sales Transaction] as date) as [Requested Ship Date - Order Lvl],
	pod.Promise_Date as [PO Promise Date],
	pod.Promise_Date_Calculation as [PO Promise Date Calculation]

FROM
	blu.dbo.SalesLineItems sli
	Left Join
	BLU.dbo.IV00108 ret
		on sli.[Item Number] = ret.ITEMNMBR
		and ret.PRCLEVEL = 'RETAIL'
	Inner join
	IT.dbo.LOCATION_INFO loc
		on sli.[Customer Class] = loc.SYSTEM_CUSTOMER_CLASS
	left join
	blu.dbo.EXTSCAF stc
		on sli.[SOP Number] = stc.[SOP Number]
		and sli.[Line Item Sequence] = stc.[Line Item Sequence]
	Left Join
		(select
			a.soptype, a.sopnumbe, a.lnitmseq, a.qtytoinv, 'Order' as [SOP Type]
		From
			blu.dbo.sop10200 a
			inner join
			blu.dbo.iv00101 b
				on a.ITEMNMBR = b.ITEMNMBR
		where
			b.ITEMTYPE = 3
			and a.SOPTYPE = 2
		) Kit
		on sli.[SOP Type] = kit.[SOP Type]
		and sli.[SOP Number] = kit.sopnumbe
		and sli.[Line Item Sequence] = kit.LNITMSEQ
	Left Join
		(select 
			case when a.total = 1 then 'From PO' else 'Calculated' end as Promise_Date_Calculation,
			case when a.total = 1 then cast(d.date1 as date) else dateadd(day, 14, cast(d.date1 as date)) end as Promise_Date,
			rtrim(c.extender_Key_Values_1) as Item_Number,
			a.Extender_Record_ID
		from 
		BLU.dbo.EXT01103 a
		inner join
		BLU.dbo.EXT20010 b
			on a.field_ID = b.Field_ID
		Inner join
		BLU.dbo.EXT01100 c 
			on a.Extender_Record_ID = c.Extender_Record_ID
		Inner join
		blu.dbo.EXT01102 d 
			on c.Extender_Record_ID = d.Extender_Record_ID
		Inner join
		blu.dbo.EXT20010 e
			on d.Field_ID = e.Field_ID
		where b.FIELDNAM = 'Promise Date from PO'
			and c.Extender_Window_ID = 'Inventory Card'
		--	and c.Extender_Key_Values_1 = 'CN1-THROW1-GR'
			and e.FIELDNAM = 'Promise Date'
		) pod
		on sli.[Item Number] = pod.Item_Number

WHERE
	(sli.[SOP Type]='Order' or (sli.[SOP Type]='Invoice' and sli.[Batch Number] like 'STORE FLOOR%'))  -- Includes All Demand ORders and Sales immediately invoiced from our Stores Sales Floor Inventory
	AND cast(sli.[Document Date] as date) >= '01/01/2016'
--	AND cast([Document Date] as date) <= '10/31/2017'
	AND sli.[SOP Number] NOT LIKE '%SVC%'  -- Exclude Service Orders
--	and [User Category Value 5] = 'Hardware'
	and sli.[Void Status] = 'Normal'
	--and sli.[Original Type] in ('', 'Quote') -- I think blanks refer to new orders and if it is a backorder it will have a value in it
	-- AND [Customer Class] IN ('Online Retail', 'Indy Retail', 'ABC', 'INTL DIST', 'OFFICEFURN', 'ID/ARCH', 'WEWORK', 'TradeProject', 'DIRECT OTHER', 'EMPLOYEE', 'DIRECT WEB', 'STEELCASE')
--	 and sli.[Item Number] = 'CN1-THROW1-GR'
--	and [master number] = 241558
