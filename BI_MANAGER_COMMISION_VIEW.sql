/**********************
Program Name: BI_MANAGER_COMMISION_VIEW.sql
Program Description: A commission view that will be fed into BI360 for reporting purposes.  Specifically for Store Managers only.  It
  will contain all their employees as well
Requestor: Christine Brausen
Developer: Kyle MacKenzie
	V1 - 6/19/2018 
	v2 - 6/26/2018 - I was missing the Store Manager Sales for NY market.  I added a new field to the Location Table to help
		identify if the store is a market or not.  Then that was used as part of the Join condition.
*****************/


Select
	cm.[Sales Person Name] as [Manager Name],
	s.[Salesperson ID],
	s.[SOP Type],
	s.[SOP Number],
	cast(s.[Document Date] as date) as [Document Date],
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
	(	select Distinct -- FOr managers of multiple stores
			sa.[Sales Person Name], sa.[Commission Rate], li.REPORTING_CUSTOMER_CLASS--, case when sq.Market_store = 1 then  sa.[Home Store] 
		from	
			it.dbo.Store_Associates sa
			inner join
			it.dbo.LOCATION_INFO li		
				on sa.[Home Store] = li.MANAGER_COMMISSION_STORE
		where  
			[Salesperson Type] like 'Manager%'
		) cm
		on case when li.market_store = 1 and emp.[Salesperson Type] like 'Manager%' then li.REPORTING_CUSTOMER_CLASS else emp.[Home Store] end = cm.REPORTING_CUSTOMER_CLASS
WHERE
	([SOP Type] = 'Invoice' OR [SOP Type] = 'Return') AND [Void Status] = 'Normal' AND [Document Status] = 'Posted'
	and	 cast(s.[Document Date] as date) between '2018-04-01' and '2018-04-30'
--	and li.LOCATION_TYPE = 'Store'
--	and s.[Salesperson ID] <> ''
	and s.[Customer Class] <> 'Employee'
--	and s.[SOP Number] in ('INV00215114', 'INV00216482', 'INV00217004', 'INV00217427')
	--and emp.[Salesperson Type] = 'Sales Associate'
