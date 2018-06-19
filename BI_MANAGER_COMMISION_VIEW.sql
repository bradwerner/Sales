/**********************
Program Name: BI_MANAGER_COMMISION_VIEW.sql
Program Description: A commission view that will be fed into BI360 for reporting purposes.  Specifically for Store Managers only.  It
  will contain all their employees as well
Requestor: Christine Brausen
Developer: Kyle MacKenzie
	V1 - 6/19/2018 
*****************/

Select
	cm.[Sales Person Name] as [Manager Name],
	s.[Salesperson ID],
	s.[SOP Type],
	s.[SOP Number],
	cast(s.[Document Date]) as [Document Date],
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
	(cast(cm.[Commission Rate] as decimal(4,2)) * .01) as 'Rate',
	case
		when s.[SOP Type] = 'Invoice' 
			Then (s.[Originating Subtotal] - s.[Originating Trade Discount Amount]) * (cast(cm.[Commission Rate] as decimal(4,2)) * .01)
		else (- s.[Originating Subtotal] + s.[Originating Trade Discount Amount]) * (cast(cm.[Commission Rate] as decimal(4,2)) * .01)
	End as [Commission]


FROM
	blu.dbo.SalesTransactions s
	inner join
	it.dbo.LOCATION_INFO li
		on s.[Customer Class] = li.SYSTEM_CUSTOMER_CLASS
	inner join
	it.dbo.Store_Associates emp      
		on s.[Salesperson ID] = emp.[Sales Person Name]
	Inner join
	(select [Sales Person Name], [Commission Rate], [Home Store] from it.dbo.Store_Associates where  [Salesperson Type] like 'Manager%') cm
		on emp.[Home Store] = cm.[Home Store]
WHERE
	([SOP Type] = 'Invoice' OR [SOP Type] = 'Return') AND [Void Status] = 'Normal' AND [Document Status] = 'Posted'
	AND cast(s.[Document Date] as date) between '2018-04-01' and '2018-04-30'
--	and li.LOCATION_TYPE = 'Store'
--	and s.[Salesperson ID] <> ''
	and s.[Customer Class] <> 'Employee'
	--and emp.[Salesperson Type] = 'Sales Associate'
