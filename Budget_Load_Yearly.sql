/**********************
Program Name: Budget_Load_Yearly.sql
Program Description: Get the monthly data from BI 360 environment, break it down to a daily view.  In order to match to customer class, 
  we edit the customer class.  It connects to the current BI 360 environment which lives on our Dev box and Accounting table that is
   on our Production SQL environment.  This will more than likely change soon
Requestor: Business
Developer: Kyle M
Tables used
  1. BI360DW.dbo.f_Trans_GL - The budget table by year, month and customer class.  There is more details in here than used
  2. BI360DW.dbo.d_account - account mapping table.  
  3. BI360DW.dbo.d_dim2 - descriptions of the Accounts (Customer Class)
  4. [bludot-sql1].it.dbo.acct_date - Daily accounting table mostly used for dates
  
Updates: v1 - 1/29/2018
	v2 - 1/29/2019 - Added link to our accountint table.  Will look to auto load the data from the query
***************************/
Select
	ad.[date],
	ad.Year_Number as Budget_Year,
	--left(gl.TimePeriod, 4) as Year_Estimate,
	ad.Month_Number as Budget_Month,
	--substring(cast(gl.TimePeriod as varchar(8)), 5, 2)  as Month_Estimate,
	--Convert(Datetime, convert(varchar(10), gl.TimePeriod)) as date,
	--di.Description as Location_Description,
	case
		when di.Code = 160 then 'CONTAINERSTORE'
		when di.Code = 147 then 'FREDMEYER'
		when di.Code = 137 then 'CANADIANTIRE'
		when di.Code = 179 then 'BJ''SWHOLESALE'
		when di.Code = 165 then 'BEDBATHBEYOND'
		when di.Code = 260 then 'WHOLESALE'
		when di.Code = 224 then 'WEWORK'
		when di.Code = 225 then 'STEELCASE'
		when di.Code = 222 then 'TRADEPROJECT'
		when di.Code = 271 then 'RETAIL SOHO'
		when di.Code = 279 then 'RETAIL SEATTLE'
		when di.Code = 273 then 'RETAIL SF'
		when di.Code = 278 then 'RETAIL NOMAD'
		when di.Code = 277 then 'RETAIL LA'
		when di.Code = 276 then 'RETAIL CHICAGO'
		when di.Code = 274 then 'RETAIL AUSTIN'
		when di.Code = 270 then 'ABC'
		when di.Code = 272 then 'RETAIL LA'
		when di.Code = 221 then 'OFFICEFURN'
		when di.Code = 220 then 'ID/ARCH'
		when di.Code = 210 then 'Direct Web'
		when di.Code = 212 then 'Direct Other'
		when di.Code = 275 then 'RETAIL MPLS'
		when di.code = 280 then 'Retail Portland'
		when di.code = 281 then 'Retail New Store'
	Else di.Description
	End as [Customer Class - Original],
	--DAY(EOMONTH(Convert(Datetime, convert(varchar(10), gl.TimePeriod)))) as days_in_month,
	-sum(gl.Value1 / DAY(EOMONTH(Convert(Datetime, convert(varchar(10), gl.TimePeriod))))) as avg_day_budget_per_month
	-- -sum(gl.value1) as total_Budget

FROM
	BI360DW.dbo.f_Trans_GL gl
	inner join
	BI360DW.dbo.d_account acct
		on gl.account = acct.MemberId
	Inner join
	BI360DW.dbo.d_dim2 di
		on gl.Dim2 = di.MemberID
	Inner Join
	[bludot-sql1].it.dbo.acct_date ad 
		on left(gl.TimePeriod, 4) = ad.Year_Number
		and substring(cast(gl.TimePeriod as varchar(8)), 5, 2) = ad.Month_Number
where
	-- acct.code in ('40000', '45000', '46000', '47000') -- Represent the Accounting codes we load budget into
	acct.code between '40000' and '49999'
	and acct.code not like '47%'
	and gl.Scenario in (3) -- Represents the years of budget loading.  So when we add 2019 we would have to code something in
	and left(gl.TimePeriod, 4) = 2019
	and ad.Year_Number = 2019
Group by
	ad.[date],
	ad.Year_Number,
	--left(gl.TimePeriod, 4),
	ad.Month_Number,
	--substring(cast(gl.TimePeriod as varchar(8)), 5, 2),
	--Convert(Datetime, convert(varchar(10), gl.TimePeriod)),
	--di.Description,
	case
		when di.Code = 160 then 'CONTAINERSTORE'
		when di.Code = 147 then 'FREDMEYER'
		when di.Code = 137 then 'CANADIANTIRE'
		when di.Code = 179 then 'BJ''SWHOLESALE'
		when di.Code = 165 then 'BEDBATHBEYOND'
		when di.Code = 260 then 'WHOLESALE'
		when di.Code = 224 then 'WEWORK'
		when di.Code = 225 then 'STEELCASE'
		when di.Code = 222 then 'TRADEPROJECT'
		when di.Code = 271 then 'RETAIL SOHO'
		when di.Code = 279 then 'RETAIL SEATTLE'
		when di.Code = 273 then 'RETAIL SF'
		when di.Code = 278 then 'RETAIL NOMAD'
		when di.Code = 277 then 'RETAIL LA'
		when di.Code = 276 then 'RETAIL CHICAGO'
		when di.Code = 274 then 'RETAIL AUSTIN'
		when di.Code = 270 then 'ABC'
		when di.Code = 272 then 'RETAIL LA'
		when di.Code = 221 then 'OFFICEFURN'
		when di.Code = 220 then 'ID/ARCH'
		when di.Code = 210 then 'Direct Web'
		when di.Code = 212 then 'Direct Other'
		when di.Code = 275 then 'RETAIL MPLS'
		when di.code = 280 then 'Retail Portland'
		when di.code = 281 then 'Retail New Store'
	Else di.Description
	End
	--DAY(EOMONTH(Convert(Datetime, convert(varchar(10), gl.TimePeriod))))
