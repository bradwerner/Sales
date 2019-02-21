/**********************
Program Name: Split_Shipment.sql
Program Description: Get the count of Invoiced order, back order,voided orders and Returned order for each master number.
Requestor: Gwen
Developer: Kyle MacKenzie

Updates: V1 - 01/10/2019
***********************
Requestor: Kyle MacKenzie
Developer: Ankita Gupta

Updates: V2 - 02/21/2019

1. Modified the date range to include all orders from 1/1/2016 till today.
2. For calculating Returns count removing Customer PO number equlas Trade, Donation and Marketing and Exclusing item Type  
   = Misc Charges and Services
   
**********************/

Select 
       st.[Master Number], li.LOCATION_TYPE as [Location Type], li.REPORTING_CUSTOMER_CLASS as [Customer Class], 
       Count(distinct st.[SOP Number]) as Invoice_Number, case when bo.Back_Orders is null then 0 else bo.Back_Orders end as Back_Orders,
       case when void.Voided_Orders is null then 0 else void.Voided_Orders end as Voided_Orders,
       case when ret.Return_Orders is null then 0 else ret.Return_Orders end as Return_Orders,
       min(cast(st.[DOcument Date] as date)) as [First Invoice], Max(cast(st.[DOcument Date] as date)) as [Last Invoice],
       min(cast(st.[Requested Ship Date] as date)) as [First Requested Ship Date], min(cast(st.[Order Date] as date)) as [Initial Order], --ord.First_Order,
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
       it.dbo.LOCATION_INFO li WITH (nolock)
              on st.[Customer Class] = li.SYSTEM_CUSTOMER_CLASS
       Inner Join -- need to look at the first order date to make sure it falls in our 2 month window
       (Select 
              bst.[Master Number], Min(Cast(bst.[DOcument Date] as date)) as First_Order
       from blu.dbo.SalesTransactions bst
              inner join
              it.dbo.LOCATION_INFO bli WITH (nolock)
              on bst.[Customer Class] = bli.SYSTEM_CUSTOMER_CLASS
       Where
              bst.[SOP Type] = 'Order'
              and bli.division = 'Blu Dot'
              and bst.[Document Date] between '2016-01-01' and CAST(GETDATE() AS date)
              and bst.[Void Status] = 'Normal'
              and bst.[SOP Number] not like '%SVC%'
              and bst.[Originating Subtotal] > 0
       Group by
              bst.[Master Number]
       ) ord
              on st.[Master Number] = ord.[Master Number]
       Left Join -- looking at back orders to join to the data set
       (Select 
              bst.[Master Number], Count(Distinct bst.[Sop Number]) as Back_Orders
       from blu.dbo.SalesTransactions bst
              inner join
              it.dbo.LOCATION_INFO bli WITH (nolock)
              on bst.[Customer Class] = bli.SYSTEM_CUSTOMER_CLASS
       Where
              bst.[SOP Type] = 'Back Order'
              and bli.division = 'Blu Dot'
              and bst.[Document Date] between '2016-01-01' and CAST(GETDATE() AS date)
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
              it.dbo.LOCATION_INFO bli WITH (nolock)
              on bst.[Customer Class] = bli.SYSTEM_CUSTOMER_CLASS
       Where
              bst.[SOP Type] = 'Order'
              and bli.division = 'Blu Dot'
              and bst.[Document Date] between '2016-01-01' and CAST(GETDATE() AS date)
              and bst.[Void Status] = 'Voided'
              and bst.[SOP Number] not like '%SVC%'
              and bst.[Originating Subtotal] > 0
       Group by
              bst.[Master Number]
       ) void
       on st.[Master Number] = void.[Master Number]
       Left Join
       (      Select     ---------9531   ---9497 without user defined 2
              bst.[Customer PO Number], bst.[Customer Number],/*bst.[User Defined 2],*/count(Distinct bst.[SOP Number]) as Return_Orders,
              - sum(bst.[Originating Subtotal] - bst.[Originating Trade Discount Amount]) as NPR
       from blu.dbo.SalesLineItems bst
              inner join
              it.dbo.LOCATION_INFO bli WITH (nolock)
              on bst.[Customer Class] = bli.SYSTEM_CUSTOMER_CLASS
       Where
              bst.[SOP Type] = 'Return'
              and bli.division = 'Blu Dot'
              and bst.[Document Date] between '2016-01-01' and CAST(GETDATE() AS date)
              and bst.[Void Status] = 'Normal'
              --and bst.[Originating Subtotal] > 0
			  and bst.[Item Type] NOT IN ('Misc Charges','Services')
			  and bst.[Customer PO Number] NOT IN ('TRADE','DONATION','MARKETING')
       Group by
              bst.[Customer PO Number], bst.[Customer Number]   ------,bst.[User Defined 2]
       ) ret
       on st.[Customer PO Number] = ret.[Customer PO Number]
       and st.[Customer Number] = ret.[Customer Number]
	   --and st.[User Defined 2] = ret.[User Defined 2]
Where
       st.[SOP Type] in ('Invoice')
--     and li.LOCATION_TYPE = 'Trade'
       and li.division = 'Blu Dot'
       and ord.First_Order between '2016-01-01' and CAST(GETDATE() AS date)
       and st.[Document Date] between '2016-01-01' and CAST(GETDATE() AS date)
      and st.[Void Status] = 'Normal'
       and st.[SOP Number] not like '%SVC%'
       and st.[Originating Subtotal] > 0 -- noticed we had Steelcase Invoice that are service but do not contain SVC, Meghan has this as a new item to be released
group by
       st.[Master Number], li.LOCATION_TYPE, li.REPORTING_CUSTOMER_CLASS, case when bo.Back_Orders is null then 0 else bo.Back_Orders end,
       case when void.Voided_Orders is null then 0 else void.Voided_Orders end,
       case when ret.Return_Orders is null then 0 else ret.Return_Orders end,
       case when ret.NPR is null then 0 else ret.NPR end
       
       
