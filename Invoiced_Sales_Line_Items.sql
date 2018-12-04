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
***************************
Requestor: Kyle MacKenzie
Developer: Ankita Gupta

Tables used
  1. SOP30200
  2. SOP30300
  3. IV00101
  4. RM00101
  5. RM00102
  6. LOCATION_INFO
  7. EXT01100
  8. EXT01103
  9. EXT20010
  10.EXT20020
  11.EXT20021
  

Updates: V4 - 11/16/2018

1. Created a new view from the tables in GP and not using saleslineitems view to make query more efficient and fast. It reduced the 
   runtime to almost half.
2. Modified Kyle's code to add billing and shipping address and dealer classification for all SOPs.
3. Changed the table a to get data directly from SOP30300 and SOP30200 and not using SalesLineitems view to make query runtime short.


Updates: V5 - 11/16/2018

1. Added Original Number
2. Added join condition in table a sop1.SOPTYPE = sop2.SOPTYPE
3. Modified the join condition while joining header with win table.
4. Using inner join for joining iv to header table

Updates: V6 - 11/20/2018

1. changed the case of the fields to match the old code as many reports on tableau was showing error as tableu is case sensitive.

Updates: V7 - 12/03/2018

1. Getting shipping address from sop30200 instead of rm00102.
2. Joined invoice table with US_ZIP on zipcode to clean the city, state and country field. 
3. Getting data from Magento_Orders and joined fields like Code, Status, coupon_code, Customer_group_id,grand_total to Invoice table.

Updates: V7 - 12/04/2018

1. Removed Grand_Total field from the table.
2. Changed shipping and billing ZIP to show 5 digit zip when country is US else show the original zip of that country

**********************/

select                                   
		b.[SOP Type],
		b.[SOP Number], 
		b.[Item Number], 
		b.[Item Description], 
		substring(b.[Item Number],3,1) as Item_Level,
		b.[Qty], 
		b.[Extended Cost], 
		b.[Extended Price], 
        b.[Unit Cost], 
        b.[Unit Price], 
        b.[Customer Number],
		b.[Actual Ship Date], 
		b.[Back Order Date],
		b.[Line Item Sequence], 
		b.[System Customer Class],
        b.[Customer Class],
	    b.[Budget Customer Class],
	    b.[Location Type],
	    b.[DIVISION],
	    b.[Customer Discount], 
		b.[Customer Name], 
        b.[Customer Name from Customer Master], 
        b.[Customer PO Number], 
		b.[Document Date],
		Round(b.[Freight Amount] / a.order_row_count,4) as [Freight Amount],
		Round(b.[Freight Tax Amount] / a.order_row_count,4) as [Freight Tax Amount],
		b.[Item Class Code],
		b.[Item Type],
		b.[Location Code],
		b.[Master Number],
		b.[Order Date], 
		b.[Original Number],
		b.[Original Type],
		b.[Originating Trade Discount Amount],
		b.[Posting Status],
		b.[Requested Ship Date],
		b.[Salesperson ID from Sales Transaction],
		b.[Tax Amount], 
		b.[Trade Discount Amount],
		b.[Trade Discount Percent], 
		b.[BDB_Product], 
        b.[Active_Item], 
        b.[Color], 
        b.[Style], 
        b.[Category], 
		b.[Void Status],
		b.[Contact Person],
		b.[ShipToName],
		b.[ShipTo Address1],
		b.[ShipTo Address2],
		b.[ShipTo Address3],
		b.[ShipTo City],
		b.[ShipTo State],
		b.[ShipTo Zip],
		b.[ShipTo Country],
		b.[BillTo Address1],
		b.[BillTo Address2],
		b.[BillTo Address3],
		b.[BillTo City],
		b.[BillTo State],
		b.[BillTo Zip],
		b.[BillTo Country],
		b.[Phone Number],
		a.[order_row_Count],
		b.[Dealer Classification],
		b.[Code],
		b.[Status],
		b.[Coupon Code],
		b.[Customer Group ID]
from
(
select
    sop1.SOPNUMBE, count(sop2.ITEMNMBR) as order_row_count , 'SOP Type' =  blu.dbo.Dyn_func_sop_type(sop1.soptype)
from
    blu.dbo.SOP30200 sop1 with (nolock)
    inner join
    blu.dbo.sop30300 sop2 with (nolock)
        on sop1.SOPNUMBE = sop2.SOPNUMBE
		AND sop1.SOPTYPE = sop2.SOPTYPE
where
    ((sop1.SOPTYPE = 3 and sop1.VOIDSTTS = 0  and sop1.SOPNUMBE not like '%SVC%')
    OR (sop1.SOPTYPE = 4 and sop1.VOIDSTTS = 0 ))
    and sop1.DOCDATE >= '2010-01-01'
group by
    sop1.SOPNUMBE, sop1.SOPTYPE
 ) a
inner join
(
select  
		 'SOP Type' =  blu.dbo.Dyn_func_sop_type([line].[soptype]), 
	     Rtrim([line].[sopnumbe])                                  AS 'SOP Number', 
         Rtrim([line].[itemnmbr])                                  AS 'Item Number', 
         Rtrim([line].[itemdesc])                                  AS 'Item Description', 
		 case when [line].[soptype] = 3 
			then [line].[quantity] else - [line].[quantity] end    AS 'QTY', 
         case when[line].[soptype] = 3 
			then [line].[extdcost] else - [line].[extdcost] end    AS 'Extended Cost',
         case when [line].[soptype] = 3 
			then [line].[xtndprce] else - [line].[xtndprce] end    AS 'Extended Price', 
         case when [line].[soptype] = 3 
			then [line].[unitcost] else - [line].[unitcost] end    AS 'Unit Cost',
         case when [line].[soptype] = 3 
			then [line].[unitprce] else - [line].[unitprce] end    AS 'Unit Price',
		 Rtrim(header.[custnmbr])                                  AS 'Customer Number',
		 cast(header.[actlship] as date)                           AS 'Actual Ship Date', 
		 cast(header.[backdate] as date)                           AS 'Back Order Date',
		 [line].[lnitmseq]                                         AS 'Line Item Sequence', 
		 Rtrim(rm.[custclas])                                      AS 'System Customer Class',
		 Rtrim(rm.[CUSTCLAS])                                      AS 'Customer Class 1',
         loc.REPORTING_CUSTOMER_CLASS                              AS 'Customer Class',
	     loc.BUDGET_CUSTOMER_CLASS                                 AS 'Budget Customer Class',
	     loc.LOCATION_TYPE                                         AS 'Location Type',
	     loc.DIVISION                                              AS 'Division',
	     rm.[custdisc] / 100.00                                    AS 'Customer Discount', 
		 Rtrim(header.[custname])                                  AS 'Customer Name', 
         Rtrim(rm.[custname])                                      AS 'Customer Name from Customer Master', 
         Rtrim(header.[cstponbr])                                  AS 'Customer PO Number', 
		 cast(header.[docdate] as date)                            AS 'Document Date',
		 header.[frtamnt]                                          AS 'Freight Amount', 
		 header.[frttxamt]                                         AS 'Freight Tax Amount',
		 Rtrim(iv.[itmclscd])                                      AS 'Item Class Code',
		 'Item Type' = blu.dbo.Dyn_func_item_type(iv.[itemtype]),
		 Rtrim([line].[locncode])                                  AS'Location Code',
		 header.[mstrnumb]                                         AS 'Master Number',
		 header.[ordrdate]                                         AS 'Order Date', 
		 header.[orignumb]                                         AS 'Original Number',
		 'Original Type' = 
			blu.dbo.Dyn_func_original_type(header.[origtype]),
		 case when [line].[soptype] = 3 
			then [line].[ortdisam] else - [line].[ortdisam] end    AS 'Originating Trade Discount Amount',
		 'Posting Status' = 
			blu.dbo.Dyn_func_posting_status_sop_line_items(header.[pstgstus]),
		 cast([line].[reqshipdate] as date)                        AS 'Requested Ship Date',
		 Rtrim(header.[slprsnid])                                  AS 'Salesperson ID from Sales Transaction',
		 [line].[taxamnt]                                          AS 'Tax Amount', 
		 [line].[trdisamt]                                         AS 'Trade Discount Amount',
		 header.[trdispct]                                         AS 'Trade Discount Percent', 
		 Rtrim(iv.[uscatvls_1])                                    AS 'BDB_Product', 
         Rtrim(iv.[uscatvls_2])                                    AS 'Active_Item', 
         Rtrim(iv.[uscatvls_3])                                    AS 'Color', 
         Rtrim(iv.[uscatvls_4])                                    AS 'Style', 
         Rtrim(iv.[uscatvls_5])                                    AS 'Category', 
		 'Void Status' = blu.dbo.Dyn_func_void_status(header.[voidstts]),
		 header.[CNTCPRSN]                                         AS 'Contact Person',
		 header.[ShipToName]                                       AS 'ShipToName',
		 [header].[ADDRESS1]                                       AS 'ShipTo Address1',
		 [header].[ADDRESS2]                                       AS 'ShipTo Address2',
		 [header].[ADDRESS3]                                       AS 'ShipTo Address3',
		 coalesce(usship.[primary_city],[header].[CITY])           AS 'ShipTo City',
		 coalesce(usship.[state],[header].[STATE])                 AS 'ShipTo State',
		 coalesce(usship.[country],[header].[COUNTRY])             AS 'ShipTo Country',
		 IIF(coalesce(usship.[country],[header].[COUNTRY]) IN ('US','United States'), 
		 substring([header].[ZIPCODE],1,5),[header].[ZIPCODE])     AS 'ShipTo Zip',
		 [billto].[ADDRESS1]                                       AS 'BillTo Address1',
		 [billto].[ADDRESS2]                                       AS 'BillTo Address2',
		 [billto].[ADDRESS3]                                       AS 'BillTo Address3',
		 coalesce(usbill.[primary_city],[billto].[CITY])           AS 'BillTo City',
		 coalesce(usbill.[state],[billto].[STATE]  )               AS 'BillTo State',
		 coalesce(usbill.[country],[billto].[COUNTRY])             AS 'BillTo Country',
		 IIF(coalesce(usbill.[country],[billto].[COUNTRY]) IN ('US','United States'), 
		 substring([billto].[ZIP],1,5),[billto].[ZIP])             AS 'BillTo Zip', 
		 header.[PHNUMBR1]                                         AS 'Phone Number',
		 win.Extender_Key_Values_1                                 AS 'Customer Name1',
		 rtrim(vl.Strng132)                                        AS 'Dealer Classification',
		 ord.[code]						   AS 'Code',
		 ord.[status]                                              AS 'Status',
		 ord.[coupon_code]                                         AS 'Coupon Code',
		 ord.[customer_group_id]				   AS 'Customer Group ID'
FROM
		blu.dbo.SOP30300 AS line WITH (nolock)
		LEFT OUTER JOIN 
		     blu.dbo.iv00101 AS iv WITH (nolock) 
             ON [line].[itemnmbr] = iv.[itemnmbr] 
		INNER JOIN                                   
		     blu.dbo.sop30200 AS header WITH (nolock)  
             ON [line].[sopnumbe] = header.[sopnumbe] 
             AND [line].[soptype] = header.[soptype]
		LEFT OUTER JOIN 
		     blu.dbo.rm00101 AS rm WITH (nolock) 
             ON header.[custnmbr] =  rm.[custnmbr]
		INNER JOIN 
		     IT.dbo.LOCATION_INFO loc WITH (nolock)
			 ON rm.[CUSTCLAS] = loc.SYSTEM_CUSTOMER_CLASS
		LEFT OUTER JOIN  
			 blu.dbo.rm00102 AS [billto] WITH (nolock)
		     ON header.[CUSTNMBR] = [billto].CUSTNMBR
	         and header.PRBTADCD = [billto].ADRSCODE
		LEFT OUTER JOIN
			 blu.dbo.EXT01100 AS win WITH (nolock)
			 on header.[custnmbr] = win.Extender_Key_Values_1 
			 AND win.Extender_Window_ID like 'Dealer'
		LEFT OUTER JOIN
			 BLU.dbo.EXT01103 AS cd WITH (nolock)
			 on win.Extender_Record_ID = cd.Extender_Record_ID
		LEFT OUTER JOIN
			 BLU.dbo.EXT20010 AS fd WITH (nolock)
			 on cd.Field_ID = fd.Field_ID
			 and fd.FIELDNAM = 'Dealer Classification'
		LEFT OUTER JOIN
			 BLU.dbo.EXT20020 AS ld WITH (nolock)
			 on fd.FIELDNAM = ld.Extender_List_Desc
		LEFT OUTER JOIN
			 BLU.dbo.EXT20021 AS vl WITH (nolock)
			 on ld.Extender_List_ID = vl.Extender_List_ID
			 and cd.TOTAL = vl.Extender_List_Item_ID
		LEFT OUTER JOIN 
			it_dev.dbo.US_zip AS usship WITH (nolock)
			on substring([header].[ZIPCODE], 1, 5) = usship.[zip]
		LEFT OUTER JOIN 
			it_dev.dbo.US_zip AS usbill WITH (nolock)
			on substring([BillTo].[Zip], 1, 5) = usbill.[zip]
		LEFT OUTER JOIN
			blu.dbo.sop10106 AS tbl WITH (nolock)  ---Joined to this table to get userdef2 to be able to join Magento_orders
			on line.SOPNUMBE = tbl.SOPNUMBE
			AND line.SOPTYPE = tbl.SOPTYPE
		LEFT OUTER JOIN
			it.dbo.Magento_orders ord WITH (nolock)
			on tbl.[userdef2] = ord.increment_id
where
	((line.[soptype] = 3 AND header.[voidstts] = 0
        AND line.[sopnumbe] NOT LIKE '%SVC%')
    OR
     (line.[soptype] = 4 AND header.[voidstts] = 0))
    AND header.[docdate] >= '2010-01-01'
) b
on a.[SOPNUMBE] = b.[SOP Number]
and a.[SOP Type] = b.[SOP Type]
