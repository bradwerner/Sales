/**********************
Program Name: Shipment_Survey_Products.sql
Program Description: Source table contains duplicate survey responses for some orders. Goal of this table is to return only the latest shipment survey response for each order, then apply that to each product within the order.

Requestor: Kevin M
Developer: Brad W

Tables Used:
1. it.dbo.Demand_Sales_Line_Items_2015
2. it.dbo.GetFeedBackSurveyResponse
3. blu.dbo.SOP10107 (to allow join to delivery result data)

Created on : 3/27/2019
**********************/

SELECT
	surv.Score
	,surv.surveyID
	,cast(surv.MaxDate as date) as Survey_Date
	,surv.[email]
	,sop.tracking_number
	,dem.[Master Number]
	,dem.[Demand Date]
	,dem.[SOP Number]
	,dem.[SOP Type]
	,dem.[Customer Class]
	,dem.[Location Type]
	,dem.[Division]
	,dem.[Customer Number]
	,dem.[Customer PO Number]
	,dem.[Item Number]
	,dem.[Item Description]
	,dem.[Item_Level]
	,dem.[Component Sequence]
	,dem.[QTY]
	,dem.[Item Type]
	,dem.[Active_Item]
	,dem.[Color]
	,dem.[Style]
	,dem.[Category]
	,dem.[Item Class Code]
	,dem.[Originating Subtotal]
	,dem.[Originating Trade Discount Amount]
	,dem.[Demand Amount]
	,dem.[Batch Number]
	,dem.[Shipping Method from Sales Transaction]
	,dem.[QTY To Invoice]
	,dem.[Line Item Sequence]
	,dem.[Pick Up Date]
	,dem.[Document Status]
	,dem.[Original Type]
	,dem.[Requested Ship Date - Order Lvl]
FROM
	(SELECT 
		[SurveyID]
		,MAX([ResponseDate]) as MaxDate
		,[email]
		,case when CHARINDEX('.',[OrderID]) > 1 then Left([OrderID], CHARINDEX('.',[OrderID])-1)
			else [OrderID]
		End as [OrderID]
		,avg(cast([Score] as int)) as Score
	FROM 
		[IT].[dbo].[GetFeedBackSurveyResponse]
	WHERE 
		orderid <> ''
	GROUP BY 
		[SurveyID]
		,[email]
		,case when CHARINDEX('.',[OrderID]) > 1 then Left([OrderID], CHARINDEX('.',[OrderID])-1)
			else [OrderID]
		End
	) surv
	Inner join
	[BLU].[dbo].[SOP10107] sop
		ON surv.[OrderID] = sop.SOPNUMBE
	Inner join
	IT.dbo.Demand_Sales_Line_Items_2015 dem
		on surv.OrderID = dem.[Sop Number]
