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
		V2 in Dec 2017 - Found a bug in Blu Dot's general look at Demand Sales.  If an order in GP starts as a quote it would 
			be excluded.  Added code and [Original Type] in ('', 'Quote')
		v3 1/8/2017 - Added a field that figures out if it was a Direct Web Outlet sale or not. And added GP retail price 
			to calculate Discounts applied
		v4 - 1/10/2018 - Removed most of the Web Outlet stuff.  Look in version 3 if you need it.
			- Fixed a bug that didn't remove Void Status = Voided.  added the logic sli.[Void Status] = 'Normal'
		v5 - 1/17/2018 - Added another field.  [Requested Ship Date] for CDP analysis.  [Item Class Code] for Gail
		v6 - 3/7/2018 - Added a location table to give us specifics about locations and Customer Classes.  And ITem_Level.
		v7 - 3/14/2018 - Added a [Customer Name from Customer Master], We realized that Wholesale partners and others get a 
			Name with (Customer Name and Number) in it.  So if a customer
			has had orders placed directly in GP and Magento the name will be different
		v8 - 3/15/2018 - Added a join to a Steelcase view with Shipping information.
		v9 - 3/16/2018 - Added even more steelcase join information so we can figure out if we can build Kit Items
		v10 - 3/20/2018 - Added sli.[Document Status] which will tell you if an order is Open (Posted vs UnPosted).  
			Added field [Original Type] to results and removed it from the where condition.
			This will help us determine if an item was a backorder item or not.  if we pre-filter for it then we 
			can't get backorder.  
		v11 - 3/30/2018 - Customer service requested that we add the '[Requested Ship Date]' at the Order level 
			and not the line item level.  Added the new field [Requested Ship Date from Sales Transaction]
		v12 - 4/18/2018 - Added our new PO Promise date and if it was calculated or from a PO
		v13 - 4/20/2018 - Added Budget Customer Class
		v14 - 8/6/2018 - Changed the Date to 2016 to speed up the query.  Plus we don't need all this data
		v15 - 8/14/2018 - MAJOR CHANGES made.  Removed the GP View SalesLineItems from the equation (Performance Issues).  It was the main 
			source of data for the results.  Replaced it with the tables that build the view.  Now there is a Unposted flow
			that Unions the Posted transactions
			In order to improve efficiencies I went straight at the tables and added (Nolock)
			I also removed one field that was not being used.  [Requested Ship Date] - this was at the Line item and won't be updated if Customer Service does someting
				[Invoice Level 1] - I removed this field but it is needed for the Steel Case Shipping Report
		
		V16 - 12/19/2018
		1. Added Unit Cost and Included Service orders

Kyle Notes
	1. Web Outlet Sale = 'No' and 20/20 Sale = 'No'.  Originating Subtotal ends in 00 or is Mattress.  It is a sale in October that isn't 20% off RETAIL - Normal Web Sale
	2. Web Outlet Sale = 'No' and 20/20 Sale = 'Not Oct'.  Originating Subtotal ends in 00 or is Mattress.  Assume It is a non Outlet sales - Normal Web Sale
	3. Web Outlet Sale = 'No' and 20/20 Sale = 'Yes'. Originating Subtotal ends in 00 or is Mattress.  Sale in October that is 20% off.  So the No is good - Normal Web Sale
	4. Web Outlet Sale = 'Yes' and 20/20 Sale = 'No'.  Originating Subtotal DOES NOT end in 00.  Not a 20% discount and the sale was in October - Legit Web OUtlet Sale
	5. Web Outlet Sale = 'Yes' and 20/20 Sale = 'Not Oct'.  Originating Subtotal DOES NOT end in 00.  Outside of October so we will assue Outlet - Legit Web Outlet Sales
	6. Web Outlet Sale = 'Yes' and 20/20 Sale = 'Yes'. 	Originating Subtotal DOES NOT end in 00.  It calculates out to a 20 % discount - Normal Web Sale
**********************/
-- ALTER view [dbo].[Demand_Sales_Line_Items] as -- in IT database
/*
Unposted transactions, the tables are called Work tables
*/
Select
	oln.MSTRNUMB as [Master Number],
	cast(oln.DOCDATE as date) as [Demand Date],
	rtrim(oln.SOPNUMBE) as [SOP Number], -- the view I was using uses it from the Line Item level
	'SOP Type' = blu.dbo.Dyn_func_sop_type(oln.[soptype]),
	rtrim(cus.CUSTCLAS) as [System Customer Class],
	loc.REPORTING_CUSTOMER_CLASS as [Customer Class],
	loc.BUDGET_CUSTOMER_CLASS as [Budget Customer Class],
	loc.LOCATION_TYPE as [Location Type],
	loc.[Division],
	rtrim(oln.CUSTNAME) as [Customer Name],
	rtrim(cus.CUSTNAME) as [Customer Name from Customer Master],
	rtrim(oln.CUSTNMBR) as [Customer Number],
	rtrim(oln.CSTPONBR) as  [Customer PO Number],
	rtrim(lvn.ITEMNMBR) as [Item Number],
	rtrim(lvn.ITEMDESC) as [Item Description],
	substring(lvn.ITEMNMBR, 3,1) as Item_Level,
	lvn.CMPNTSEQ as [Component Sequence],
	lvn.QUANTITY as QTY,
	'Item Type' = blu.dbo.Dyn_func_item_type(inv.[itemtype]),
	 rtrim(oln.slprsnid)  as [Salesperson ID from Sales Transaction],
	rtrim(inv.uscatvls_1) as BDB_Product,
	rtrim(inv.uscatvls_2) as Active_Item,
	rtrim(inv.uscatvls_3) as Color,
	rtrim(inv.uscatvls_4) as Style,
	rtrim(inv.uscatvls_5) as Category,
	rtrim(inv.itmclscd) as [Item Class Code],
	rtrim(cus.city) as [City From Customer Master],
	rtrim(oln.city) as [City from Sales Transaction],
	rtrim(cus.cntcprsn) as [Contact Person from Customer Master],
	lvn.XTNDPRCE as [Originating Subtotal],
	lvn.ortdisam as [Originating Trade Discount Amount],
	(lvn.XTNDPRCE - lvn.ortdisam) AS [Demand Amount],
	ret.UOMPRICE as Retail_Price,
	lvn.UNITCOST as 'Unit Cost',
	rtrim(oln.bachnumb) as [Batch Number],
	rtrim(oln.SHIPMTHD) as [Shipping Method from Sales Transaction],
	lvn.qtytoinv as [QTY To Invoice],
	kit.qtytoinv as [Invoice Level 1],
	lvn.lnitmseq as [Line Item Sequence],
	cast(stc.[Pick-up date] as date) as [Pick Up Date],
	'Document Status' = blu.dbo.Dyn_func_document_status_sop_line_items(1),
	'Original Type' = blu.dbo.Dyn_func_original_type(oln.[origtype]),
	cast(oln.reqshipdate as date) as [Requested Ship Date - Order Lvl],
	pod.Promise_Date as [PO Promise Date],
	pod.Promise_Date_Calculation as [PO Promise Date Calculation]
from
	blu.dbo.sop10100 as oln with (nolock)
	inner join
	blu.dbo.sop10200 as lvn with (nolock)
		on oln.SOPNUMBE = lvn.SOPNUMBE
		and oln.SOPTYPE = lvn.SOPTYPE 
	left join
	blu.dbo.rm00101 as cus with (nolock)
		on oln.CUSTNMBR = cus.CUSTNMBR
	inner join
	it.dbo.LOCATION_INFO as loc with (nolock)
		on cus.CUSTCLAS = loc.SYSTEM_CUSTOMER_CLASS
	left join -- seems to definitely needs a left join
	blu.dbo.iv00101 as inv with (nolock)
		on lvn.ITEMNMBR = inv.ITEMNMBR
	Left Join
	BLU.dbo.IV00108 as ret with (nolock) 
		on lvn.ITEMNMBR = ret.ITEMNMBR
		and ret.PRCLEVEL = 'RETAIL'
	left join
	blu.dbo.EXTSCAF stc with (nolock)
		on lvn.SOPNUMBE = stc.[SOP Number]
		and lvn.lnitmseq = stc.[Line Item Sequence]
	Left Join
		(select
			a.soptype, a.sopnumbe, a.lnitmseq, a.qtytoinv, 'Order' as [SOP Type]
		From
			blu.dbo.sop10200 a with (nolock)
			inner join
			blu.dbo.iv00101 b with (nolock)
				on a.ITEMNMBR = b.ITEMNMBR
		where
			b.ITEMTYPE = 3
			and a.SOPTYPE = 2
		) Kit
		on oln.soptype = kit.soptype
		and oln.sopnumbe = kit.sopnumbe
		and lvn.lnitmseq  = kit.LNITMSEQ
	Left Join
		(select 
			case when a.total = 1 then 'From PO' else 'Calculated' end as Promise_Date_Calculation,
			case when a.total = 1 then cast(d.date1 as date) else dateadd(day, 14, cast(d.date1 as date)) end as Promise_Date,
			rtrim(c.extender_Key_Values_1) as Item_Number,
			a.Extender_Record_ID
		from 
		BLU.dbo.EXT01103 a with (nolock)
		inner join
		BLU.dbo.EXT20010 b with (nolock)
			on a.field_ID = b.Field_ID
		Inner join
		BLU.dbo.EXT01100 c with (nolock)
			on a.Extender_Record_ID = c.Extender_Record_ID
		Inner join
		blu.dbo.EXT01102 d with (nolock)
			on c.Extender_Record_ID = d.Extender_Record_ID
		Inner join
		blu.dbo.EXT20010 e with (nolock)
			on d.Field_ID = e.Field_ID
		where b.FIELDNAM = 'Promise Date from PO'
			and c.Extender_Window_ID = 'Inventory Card'
		--	and c.Extender_Key_Values_1 = 'CN1-THROW1-GR'
			and e.FIELDNAM = 'Promise Date'
		) pod
		on lvn.ITEMNMBR = pod.Item_Number
Where
	oln.DOCDATE >= '2016-01-01'
	and (oln.SOPTYPE = 2 or (oln.SOPTYPE = 3 and oln.BACHNUMB like 'STORE FLOOR%'))  -- Includes All Demand ORders and Sales immediately invoiced from our Stores Sales Floor Inventory
	and oln.VOIDSTTS = 0 -- Normal or Not Voided
	--and oln.SOPNUMBE NOT LIKE '%SVC%'  -- Exclude Service Orders

union all
/* 
Looking at history SOP tables, when transactions post they go to the history tables
*/
Select
	oln.MSTRNUMB as [Master Number],
	cast(oln.DOCDATE as date) as [Demand Date],
	rtrim(oln.SOPNUMBE) as [SOP Number], -- the view I was using uses it from the Line Item level
	'SOP Type' = blu.dbo.Dyn_func_sop_type(oln.[soptype]),
	rtrim(cus.CUSTCLAS) as [System Customer Class],
	loc.REPORTING_CUSTOMER_CLASS as [Customer Class],
	loc.BUDGET_CUSTOMER_CLASS as [Budget Customer Class],
	loc.LOCATION_TYPE as [Location Type],
	loc.[Division],
	rtrim(oln.CUSTNAME) as [Customer Name],
	rtrim(cus.CUSTNAME) as [Customer Name from Customer Master],
	rtrim(oln.CUSTNMBR) as [Customer Number],
	rtrim(oln.CSTPONBR) as  [Customer PO Number],
	rtrim(lvn.ITEMNMBR) as [Item Number],
	rtrim(lvn.ITEMDESC) as [Item Description],
	substring(lvn.ITEMNMBR, 3,1) as Item_Level,
	lvn.CMPNTSEQ as [Component Sequence],
	lvn.QUANTITY as QTY,
	'Item Type' = blu.dbo.Dyn_func_item_type(inv.[itemtype]),
	 rtrim(oln.slprsnid)  as [Salesperson ID from Sales Transaction],
	rtrim(inv.uscatvls_1) as BDB_Product,
	rtrim(inv.uscatvls_2) as Active_Item,
	rtrim(inv.uscatvls_3) as Color,
	rtrim(inv.uscatvls_4) as Style,
	rtrim(inv.uscatvls_5) as Category,
	rtrim(inv.itmclscd) as [Item Class Code],
	rtrim(cus.city) as [City From Customer Master],
	rtrim(oln.city) as [City from Sales Transaction],
	rtrim(cus.cntcprsn) as [Contact Person from Customer Master],
	lvn.XTNDPRCE as [Originating Subtotal],
	lvn.ortdisam as [Originating Trade Discount Amount],
	(lvn.XTNDPRCE - lvn.ortdisam) AS [Demand Amount],
	ret.UOMPRICE as Retail_Price,
	lvn.UNITCOST as 'Unit Cost',
	rtrim(oln.bachnumb) as [Batch Number],
	rtrim(oln.SHIPMTHD) as [Shipping Method from Sales Transaction],
	lvn.qtytoinv as [QTY To Invoice],
	kit.qtytoinv as [Invoice Level 1],
	lvn.lnitmseq as [Line Item Sequence],
	cast(stc.[Pick-up date] as date) as [Pick Up Date],
	'Document Status' = blu.dbo.Dyn_func_document_status_sop_line_items(2),
	'Original Type' = blu.dbo.Dyn_func_original_type(oln.[origtype]),
	cast(oln.reqshipdate as date) as [Requested Ship Date - Order Lvl],
	pod.Promise_Date as [PO Promise Date],
	pod.Promise_Date_Calculation as [PO Promise Date Calculation]
from
	blu.dbo.sop30200 as oln with (nolock)
	inner join
	blu.dbo.sop30300 as lvn with (nolock)
		on oln.SOPNUMBE = lvn.SOPNUMBE
		and oln.SOPTYPE = lvn.SOPTYPE 
	left join
	blu.dbo.rm00101 as cus with (nolock)
		on oln.CUSTNMBR = cus.CUSTNMBR
	inner join
	it.dbo.LOCATION_INFO as loc with (nolock)
		on cus.CUSTCLAS = loc.SYSTEM_CUSTOMER_CLASS
	left join -- seems to definitely needs a left join
	blu.dbo.iv00101 as inv with (nolock)
		on lvn.ITEMNMBR = inv.ITEMNMBR
	Left Join
	BLU.dbo.IV00108 as ret with (nolock) 
		on lvn.ITEMNMBR = ret.ITEMNMBR
		and ret.PRCLEVEL = 'RETAIL'
	left join
	blu.dbo.EXTSCAF as stc with (nolock)
		on lvn.SOPNUMBE = stc.[SOP Number]
		and lvn.lnitmseq = stc.[Line Item Sequence]
	Left Join
		(select
			a.soptype, a.sopnumbe, a.lnitmseq, a.qtytoinv, 'Order' as [SOP Type]
		From
			blu.dbo.sop10200 a with (nolock)
			inner join
			blu.dbo.iv00101 b with (nolock)
				on a.ITEMNMBR = b.ITEMNMBR
		where
			b.ITEMTYPE = 3
			and a.SOPTYPE = 2
		) Kit
		on oln.soptype = kit.soptype
		and oln.sopnumbe = kit.sopnumbe
		and lvn.lnitmseq  = kit.LNITMSEQ
	Left Join
		(select 
			case when a.total = 1 then 'From PO' else 'Calculated' end as Promise_Date_Calculation,
			case when a.total = 1 then cast(d.date1 as date) else dateadd(day, 14, cast(d.date1 as date)) end as Promise_Date,
			rtrim(c.extender_Key_Values_1) as Item_Number,
			a.Extender_Record_ID
		from 
		BLU.dbo.EXT01103 a with (nolock)
		inner join
		BLU.dbo.EXT20010 b with (nolock)
			on a.field_ID = b.Field_ID
		Inner join
		BLU.dbo.EXT01100 c with (nolock)
			on a.Extender_Record_ID = c.Extender_Record_ID
		Inner join
		blu.dbo.EXT01102 d with (nolock)
			on c.Extender_Record_ID = d.Extender_Record_ID
		Inner join
		blu.dbo.EXT20010 e with (nolock)
			on d.Field_ID = e.Field_ID
		where b.FIELDNAM = 'Promise Date from PO'
			and c.Extender_Window_ID = 'Inventory Card'
		--	and c.Extender_Key_Values_1 = 'CN1-THROW1-GR'
			and e.FIELDNAM = 'Promise Date'
		) pod
		on lvn.ITEMNMBR = pod.Item_Number
Where
	oln.DOCDATE >= '2016-01-01'
	and (oln.SOPTYPE = 2 or (oln.SOPTYPE = 3 and oln.BACHNUMB like 'STORE FLOOR%'))  -- Includes All Demand ORders and Sales immediately invoiced from our Stores Sales Floor Inventory
	and oln.VOIDSTTS = 0 -- Normal or Not Voided
	--and oln.SOPNUMBE NOT LIKE '%SVC%'  -- Exclude Service Orders
