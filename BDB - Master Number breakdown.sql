/**********************

Program Name          : BDB - Master Number breakdown.sql
Program Description   : The table looks at each Master number and breaks down how many invoices, Returns, Voids and backorders it created. 
                        It can be used for Split Shipment analysis
Requestor             : Gwen
Developer             : Kyle MacKenzie

**********************/

Select 
	st.[Master Number], li.LOCATION_TYPE as [Location Type], li.REPORTING_CUSTOMER_CLASS as [Customer Class], 
	Count(distinct st.[SOP Number]) as Invoice_Number, case when bo.Back_Orders is null then 0 else bo.Back_Orders end as Back_Orders,
	case when void.Voided_Orders is null then 0 else void.Voided_Orders end as Voided_Orders,
	case when ret.Return_Orders is null then 0 else ret.Return_Orders end as Return_Orders,
	min(cast(st.[DOcument Date] as date)) as [First Invoice], Max(cast(st.[DOcument Date] as date)) as [Last Invoice],
	min(cast(st.[Requested Ship Date] as date)) as [First Requested Ship Date], min(cast(st.[Order Date] as date)) as [Initial Order],
	sum(st.[Freight Amount]) as [Freight paid by Customer], 
	sum(St.[Originating Subtotal]) as [Originating Subtotal], 
	sum(st.[Originating Trade Discount Amount]) as [Originating Trade Discount Amount], 
	sum(St.[Originating Subtotal] - st.[Originating Trade Discount Amount]) as NPR,
	case when ret.NPR is null then 0 else ret.NPR end as Return_NPR,
	count(Case	
		when st.[shipping method] like '%ABF%' then 'ABF'
		when st.[shipping method] like '%RESID%' then 'ABF'
		when st.[shipping method] like '%Timekeeper%' then 'ABF'
		end) as ABF,
    count(Case 
		when st.[shipping method] like '%smpkg%' then 'UPS'
		when st.[shipping method] like '%UPS%' then 'UPS'
		End) as UPS,
	Count(Case when st.[shipping method] like '%Steelcase%' then 'Steelcase' End)  as Steelcase,
	Count(Case when st.[shipping method] like '%COURIER%' then 'Courier' end) as Courier,
	Count(Case when st.[shipping method] like '%Pick%' then 'Pick Up' end) as [Pick Up],
	Count(Case when st.[shipping method] like '%YOUR CARRIER%' then 'YOUR CARRIER' end) as [Your Carrier]
from	
	blu.dbo.SalesTransactions st
	inner join
	it.dbo.LOCATION_INFO li
		on st.[Customer Class] = li.SYSTEM_CUSTOMER_CLASS
	Inner Join 
	(Select 
		bst.[Master Number], Min(Cast(bst.[DOcument Date] as date)) as First_Order
	from blu.dbo.SalesTransactions bst
		inner join
		it.dbo.LOCATION_INFO bli
		on bst.[Customer Class] = bli.SYSTEM_CUSTOMER_CLASS
	Where
		bst.[SOP Type] = 'Order'
		and bli.division = 'Blu Dot'
		and bst.[Void Status] = 'Normal'
		and bst.[SOP Number] not like '%SVC%'
		and bst.[Originating Subtotal] > 0
	Group by
		bst.[Master Number]
	) ord
		on st.[Master Number] = ord.[Master Number]
	Left Join
	(Select 
		bst.[Master Number], Count(Distinct bst.[Sop Number]) as Back_Orders
	from blu.dbo.SalesTransactions bst
		inner join
		it.dbo.LOCATION_INFO bli
		on bst.[Customer Class] = bli.SYSTEM_CUSTOMER_CLASS
	Where
		bst.[SOP Type] = 'Back Order'
		and bli.division = 'Blu Dot'
		and bst.[Void Status] = 'Normal'
		and bst.[SOP Number] not like '%SVC%'
		and bst.[Originating Subtotal] > 0
	Group by
		bst.[Master Number]
	) bo
		on st.[Master Number] = bo.[Master Number]
	left join
	(Select 
		bst.[Master Number], count(Distinct bst.[SOP Number]) as Voided_Orders
	from blu.dbo.SalesTransactions bst
		inner join
		it.dbo.LOCATION_INFO bli
		on bst.[Customer Class] = bli.SYSTEM_CUSTOMER_CLASS
	Where
		bst.[SOP Type] = 'Order'
		and bli.division = 'Blu Dot'
		and bst.[Void Status] = 'Voided'
		and bst.[SOP Number] not like '%SVC%'
		and bst.[Originating Subtotal] > 0
	Group by
		bst.[Master Number]
	) void
	on st.[Master Number] = void.[Master Number]
	Left Join
	(	Select 
		bst.[Customer PO Number], bst.[Customer Number], count(Distinct bst.[SOP Number]) as Return_Orders,
		- sum(bst.[Originating Subtotal] - bst.[Originating Trade Discount Amount]) as NPR
	from blu.dbo.SalesTransactions bst
		inner join
		it.dbo.LOCATION_INFO bli
		on bst.[Customer Class] = bli.SYSTEM_CUSTOMER_CLASS
	Where
		bst.[SOP Type] = 'Return'
		and bli.division = 'Blu Dot'
		and bst.[Void Status] = 'Normal'
	Group by
		bst.[Customer PO Number], bst.[Customer Number]
	) ret
	on st.[Customer PO Number] = ret.[Customer PO Number]
	and st.[Customer Number] = ret.[Customer Number]
Where
	st.[SOP Type] in ('Invoice')
	and li.division = 'Blu Dot'
	and ord.First_Order between '2016-01-01' and '2018-12-31'
 	and st.[Void Status] = 'Normal'
	and st.[SOP Number] not like '%SVC%'
	and st.[Originating Subtotal] > 0 

group by
	st.[Master Number], li.LOCATION_TYPE, li.REPORTING_CUSTOMER_CLASS, case when bo.Back_Orders is null then 0 else bo.Back_Orders end,
	case when void.Voided_Orders is null then 0 else void.Voided_Orders end,
	case when ret.Return_Orders is null then 0 else ret.Return_Orders end,
	case when ret.NPR is null then 0 else ret.NPR end
