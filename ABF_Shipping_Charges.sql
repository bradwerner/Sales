/**********************
Program Name: ABF_Shipping_Charges.sql
Program Description: Matching orders to their Shipping charges for ABF shipped orders  
Developer: Kyle MacKenzie
Updates: V1 - 3/14/2018
**********************/
Select
	st.[Master Number],
	st.[Document Date],
	datepart(Year, St.[Document Date]) as Invoice_Year,
	datepart(Month, St.[Document Date]) as Invoice_Month,
	st.[SOP Number],
	st.[SOP Type],
	st.[Customer Class] as [System Customer Class],
	loc.REPORTING_CUSTOMER_CLASS as [Customer Class],
	loc.LOCATION_TYPE as [Location Type],
	loc.Division,
	st.[Shipping Method],
	tr.Tracking_Number,
	st.[Customer Name],
	st.[Customer Name from Customer Master],
	st.[Customer Number],
	st.[Salesperson ID],
	st.[Originating Subtotal],
	st.[Originating Trade Discount Amount],
	st.[Originating Subtotal] - st.[Originating Trade Discount Amount] as NPR,
	Substring(tr.Tracking_Number,1,3) as first_three,
	st.[Freight Amount],
	st.[Freight Tax Amount],
	st.[Tax Amount],
	st.[Originating Subtotal] - st.[Originating Trade Discount Amount] + st.[Freight Amount] /* + st.[Freight Tax Amount] */ + st.[Tax Amount] as Total_Customer_Paid,
	ttcp.Total_Tracking_Customer_Paid,
	case when (st.[Originating Subtotal] - st.[Originating Trade Discount Amount] + st.[Freight Amount] /* + st.[Freight Tax Amount] */ + st.[Tax Amount]) > 0 and ttcp.Total_Tracking_Customer_Paid > 0 then
	(st.[Originating Subtotal] - st.[Originating Trade Discount Amount] + st.[Freight Amount] /* + st.[Freight Tax Amount] */ + st.[Tax Amount]) / ttcp.Total_Tracking_Customer_Paid
	Else .00
	end as Percent_of_Total,
	pt.Invoice_Amount,
	case when (st.[Originating Subtotal] - st.[Originating Trade Discount Amount] + st.[Freight Amount] /* + st.[Freight Tax Amount]*/ + st.[Tax Amount]) > 0 and ttcp.Total_Tracking_Customer_Paid > 0 and pt.Invoice_Amount > 0 then
	((st.[Originating Subtotal] - st.[Originating Trade Discount Amount] + st.[Freight Amount] /*+ st.[Freight Tax Amount]*/ + st.[Tax Amount]) / ttcp.Total_Tracking_Customer_Paid) * pt.Invoice_Amount
	Else .00
	end as ABF_Order_Invoice
FROM
	blu.dbo.SalesTransactions st
	Inner Join
	blu.dbo.SOP10107 tr
		on st.[SOP Number] = tr.sopnumbe
	Inner join
	IT.dbo.LOCATION_INFO loc
		on st.[Customer Class] = loc.SYSTEM_CUSTOMER_CLASS
	Left join
	(Select
		tr2.Tracking_Number,
		sum(st2.[Originating Subtotal] - st2.[Originating Trade Discount Amount] + st2.[Freight Amount] /* + st2.[Freight Tax Amount] */+ st2.[Tax Amount]) as Total_Tracking_Customer_Paid
	from
		blu.dbo.SalesTransactions st2
		left join
		blu.dbo.SOP10107 tr2
			on st2.[SOP Number] = tr2.sopnumbe
	where
		st2.[SOP Type] = 'Invoice' AND st2.[Void Status] = 'Normal' AND st2.[Document Status] = 'Posted' AND st2.[SOP Number] NOT LIKE '%SVC%'
		AND st2.[Document Date]>'01/01/2017'
--		and (st2.[Customer Class] in ('Direct Web', 'Online Retail') or st2.[Customer Class] like 'Retail%')
	Group by
		tr2.Tracking_Number
	) Ttcp
		on tr.Tracking_Number = ttcp.tracking_number
	Left Join
	(select
		substring([Document Number], 1, 9) as ABF_Invoice
		,sum([Purchases Amount]) as Invoice_Amount
	from
		blu.dbo.PayablesTransactions
	where
		substring([Document Number], 10, 3) like '[_]%'
		and [Vendor Id] = 'ABF'
	group by
		substring([Document Number], 1, 9)
	) pt
		on tr.Tracking_Number = pt.ABF_Invoice
WHERE
	st.[SOP Type] = 'Invoice' AND st.[Void Status] = 'Normal' AND st.[Document Status] = 'Posted' /* AND st.[SOP Number]  NOT LIKE '%SVC%'*/
	AND st.[Document Date]>='01/01/2017'
