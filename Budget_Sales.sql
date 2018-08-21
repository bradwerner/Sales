/**********************
Program Name: Budget_Sales.sql
Program Description: Use the daily budget table and join to the max Invoice date to be used in tableau reporting.  It also includes
  the Location table which helps identify what the budget customer class belongs too. 
Developer: Kyle MacKenzie
Updates: V1 - 4/9/2018
**********************/
SELECT 
  bud.[Date]
  ,bud.[Budget_Year]
  ,bud.[Budget_Month]
  ,Upper(bud.[Customer Class - Original]) as [Budget Customer Class]
  ,loc.[Customer Class]
  ,loc.[Location Type]
  ,loc.DIVISION as Division
  ,bud.Budget
  ,(SELECT Max([Document Date]) as most_Recent_Invoice_Date
    FROM [BLU].[dbo].[SalesLineItems] sli
    where
      (([SOP Type] = 'Invoice' AND [Void Status] = 'Normal' AND [Document Status] = 'Posted' AND [SOP Number] NOT LIKE '%SVC%')
      OR ([SOP Type] = 'Return' AND [Void Status]='Normal' AND [Document Status] = 'Posted'))
      and sli.[Document Date] >= dateadd(dd, -14, getdate()) 
  ) as Max_Invoice_date
FROM 
  [IT].[dbo].[BUDGET] bud
  left join
  (select 
    distinct case when BUDGET_CUSTOMER_CLASS = 'WHOLESALE' then 'Multiple Customers' else REPORTING_CUSTOMER_CLASS end as [Customer Class]
    ,LOCATION_TYPE as [Location Type]
    ,DIVISION
    ,BUDGET_CUSTOMER_CLASS
  from IT.dbo.LOCATION_INFO
  ) loc
on bud.[Customer Class - Original] = loc.BUDGET_CUSTOMER_CLASS
