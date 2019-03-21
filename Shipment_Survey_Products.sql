/**********************
Program Name: Shipment_Survey_Products.sql
Program Description: Source table contains duplicate survey responses for some orders. Goal of this table is to return only the latest shipment survey response for each order, then apply that to each product within the order.

Requestor: Kevin M
Developer: Brad W

Tables Used:
1. it.dbo.Demand_Sales_Line_Items_2015
2. it.dbo.GetFeedBackSurveyResponse
3. blu.dbo.SOP10107 (to allow join to delivery result data)

Created on : 3/21/2019
**********************/

SELECT 
	surv.score
	,surv.MaxDate
	,surv.OrderID
	,sop.SOPNUMBE
	,sop.Tracking_Number
	,dem.[Master Number]
	,dem.[Demand Date]
	,dem.[SOP Number]
	,dem.[SOP Type]
	,dem.[System Customer Class]
	,dem.[Customer Class]
	,dem.[Budget Customer Class]
	,dem.[Location Type]
	,dem.[Division]
	,dem.[Customer Name]
	,dem.[Customer Name from Customer Master]
	,dem.[Customer Number]
	,dem.[Customer PO Number]
	,dem.[Item Number]
	,dem.[Item Description]
	,dem.[Item_Level]
	,dem.[Component Sequence]
	,dem.[QTY]
	,dem.[Item Type]
	,dem.[Salesperson ID from Sales Transaction]
	,dem.[BDB_Product]
	,dem.[Active_Item]
	,dem.[Color]
	,dem.[Style]
	,dem.[Category]
	,dem.[Item Class Code]
	,dem.[City From Customer Master]
	,dem.[City from Sales Transaction]
	,dem.[Contact Person from Customer Master]
	,dem.[Originating Subtotal]
	,dem.[Originating Trade Discount Amount]
	,dem.[Demand Amount]
	,dem.[Retail_Price]
	,dem.[Unit Cost]
	,dem.[Batch Number]
	,dem.[Shipping Method from Sales Transaction]
	,dem.[QTY To Invoice]
	,dem.[Invoice Level 1]
	,dem.[Line Item Sequence]
	,dem.[Pick Up Date]
	,dem.[Document Status]
	,dem.[Original Type]
	,dem.[Requested Ship Date - Order Lvl]
	,dem.[PO Promise Date]
	,dem.[PO Promise Date Calculation]
	,dem.[Hold]
	,dem.[Payment Terms ID]
	,dem.[Payment Received]

FROM [IT].[dbo].[Demand_Sales_Line_Items_2015] dem
	
	LEFT JOIN 
	(SELECT [SurveyID]
		  ,MAX([ResponseDate]) as MaxDate
		  ,[email]
		  ,[OrderID]
		  ,[utm_source]
		  ,[utm_content]
		  ,[Score]
		  ,[Comment]
		FROM [IT].[dbo].[GetFeedBackSurveyResponse]
		GROUP BY [SurveyID]
		  ,[email]
		  ,[OrderID]
		  ,[utm_source]
		  ,[utm_content]
		  ,[Score]
		  ,[Comment]
	) surv
		ON dem.[SOP Number] = surv.OrderID

	LEFT JOIN 
	[BLU].[dbo].[SOP10107] sop
		ON dem.[SOP Number] = sop.SOPNUMBE

WHERE surv.[score] IS NOT NULL
