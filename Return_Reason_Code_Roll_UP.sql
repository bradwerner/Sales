/**********************
Program Name: Return_Reason_Code_Roll_UP.sql
Program Description: It blends Return and service orders with Invoices at the monthly level.  
Requestor: John McGuire
Developer: Kyle MacKenzie
Updates: V1 - 1/15/2019
**********************/
Select
	it_dt.[Type], it_dt.[item number], it_dt.[item category], it_dt.[item collection], it_dt.[Month],
	ret.[55 Customer dissatisfied with quality], 
	ret.[75  Picking error],
	ret.[15  Part missing - Blu Dot error], 
	ret.[30  Part damaged in shipping], 
	ret.[No Reason Selected], 
	ret.[10  Part missing - supplier error], 
	ret.[60  Carton labeled incorrectly],
	ret.[40  Customer damaged/lost part],  
	ret.[20  Part is broken or has quality problem],  
	ret.[70  Shipping error],  
	ret.[50  Customer decided against],
	ret.[80  Other - please specify],
	ret.Return_Ttl,
	inv.Invoiced_Qty
from
(
Select 
	cbi.[Type], cbi.[item number], cbi.[item category], cbi.[item collection], [Month]
from 
	(select 
		cast(DATEADD(month, DATEDIFF(month, 0, [Date]), 0) as date) as [Month] 
	from 
		it.dbo.ACCT_DATE 
	Where
		[Date] between '2010-01-01' and Getdate()	
	group by 
		cast(DATEADD(month, DATEDIFF(month, 0, [Date]), 0) as date)
	) ad 
	cross join
	(select distinct [Type], [item number], [item category], [item collection] from it.dbo.Level1_Can_we_Build_it) cbi
) it_dt

left join
(
	Select
		[Item Number],
		[Month], 
		sum(Case when [Return Reascon Code Value] = '55  Customer dissatisfied with quality' then 1 else 0 end) as [55 Customer dissatisfied with quality], 
		sum(Case when [Return Reascon Code Value] = '75  Picking error' then 1 else 0 end) as [75  Picking error],
		sum(Case when [Return Reascon Code Value] = '15  Part missing - Blu Dot error' then 1 else 0 end) as [15  Part missing - Blu Dot error], 
		sum(Case when [Return Reascon Code Value] = '30  Part damaged in shipping' then 1 else 0 end) as [30  Part damaged in shipping], 
		sum(Case when [Return Reascon Code Value] is null then 1 else 0 end) as [No Reason Selected], 
		sum(Case when [Return Reascon Code Value] = '10  Part missing - supplier error' then 1 else 0 end) as [10  Part missing - supplier error], 
		sum(Case when [Return Reascon Code Value] = '60  Carton labeled incorrectly' then 1 else 0 end) as [60  Carton labeled incorrectly],
		sum(Case when [Return Reascon Code Value] = '40  Customer damaged/lost part' then 1 else 0 end) as [40  Customer damaged/lost part],  
		sum(Case when [Return Reascon Code Value] = '20  Part is broken or has quality problem' then 1 else 0 end) as [20  Part is broken or has quality problem],  
		sum(Case when [Return Reascon Code Value] = '70  Shipping error' then 1 else 0 end) as [70  Shipping error],  
		sum(Case when [Return Reascon Code Value] = '50  Customer decided against' then 1 else 0 end) as [50  Customer decided against],
		sum(Case when [Return Reascon Code Value] = '80  Other - please specify' then 1 else 0 end) as [80  Other - please specify],
		Count(isnull([Return Reascon Code Value], 'Changing to not null')) as Return_Ttl
	From
		(Select 
			[Customer PO Number], [Item Number],  [Return Reascon Code Value], Cast(DATEADD(month, DATEDIFF(month, 0, [Document Date]), 0) as date) as month,
			count([Item Number]) as ttl
		from
			it.dbo.Return_Defect_Orders
		group by
			[Customer PO Number], [Item Number],  [Return Reascon Code Value], Cast(DATEADD(month, DATEDIFF(month, 0, [Document Date]), 0) as date)
		) a
	Group by
		[Item Number],
		[Month]
) ret
	on it_dt.[item number] = ret.[Item Number]
	and it_dt.[Month] = ret.[Month]

Left join
(
	Select 
		[Item Number],
		Cast(DATEADD(month, DATEDIFF(month, 0, [Document Date]), 0) as date) as month,
		sum(qty) as Invoiced_Qty
	From
		it.dbo.Invoiced_Sales_Line_Items 
	Where
		DIVISION = 'Blu Dot' 
		and [SOP Type] = 'Invoice'
	group by
		[Item Number],
		Cast(DATEADD(month, DATEDIFF(month, 0, [Document Date]), 0) as date)
) inv
	on it_dt.[item number] = inv.[Item Number]
	and it_dt.[Month] = inv.[Month]
