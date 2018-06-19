/**********************
Program Name: BI_ASSOCIATE_COMMISION_VIEW.sql
Program Description: A commission view that will be fed into BI360 for reporting purposes.  Specifically for Associates only
Requestor: Christine Brausen
Developer: Kyle MacKenzie
	V1 - 6/19/2018 
*****************/
/*****************
Store associate piece Only
*****************/

Select
	s.[Salesperson ID],
	s.[SOP Type],
	s.[SOP Number],
	s.[Document Date] as 'Date',
	s.[Customer Number],
	s.[Customer Name],
	s.[Customer PO Number],
	li.REPORTING_CUSTOMER_CLASS as [Customer Class],
	case
		when s.[SOP Type] = 'Invoice' 
			Then s.[Document Amount]
		else - s.[Document Amount]
	End as [Document Amount],
	case
		when s.[SOP Type] = 'Invoice' 
			Then s.[Freight Amount]
		else - s.[Freight Amount]
	End as [Freight Amount],
	case
		when s.[SOP Type] = 'Invoice' 
			Then s.[Tax Amount]
		else - s.[Tax Amount]
	End as [Tax Amount],
	case
		when s.[SOP Type] = 'Invoice' 
			Then (s.[Originating Subtotal] - s.[Originating Trade Discount Amount])
		else (- s.[Originating Subtotal] + s.[Originating Trade Discount Amount])
	End as [Net Sales],
	(cast(emp.[Commission Rate] as decimal(4,2)) * .01) as 'Rate',
	case
		when s.[SOP Type] = 'Invoice' 
			Then (s.[Originating Subtotal] - s.[Originating Trade Discount Amount]) * (cast(emp.[Commission Rate] as decimal(4,2)) * .01)
		else (- s.[Originating Subtotal] + s.[Originating Trade Discount Amount]) * (cast(emp.[Commission Rate] as decimal(4,2)) * .01)
	End as [Commission]


FROM
	blu.dbo.SalesTransactions s
	inner join
	it.dbo.LOCATION_INFO li
		on s.[Customer Class] = li.SYSTEM_CUSTOMER_CLASS
	inner join
	it.dbo.Store_Associates emp      
		on s.[Salesperson ID] = emp.[Sales Person Name]
WHERE
	([SOP Type] = 'Invoice' OR [SOP Type] = 'Return') AND [Void Status] = 'Normal' AND [Document Status] = 'Posted'
	AND cast(s.[Document Date] as date) between '2018-04-01' and '2018-04-30'
	and emp.[Salesperson Type] = 'Sales Associate'
	and s.[Customer Class] <> 'Employee'
