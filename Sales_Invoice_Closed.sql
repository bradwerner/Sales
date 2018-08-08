/*******************************
Program Description: look to see if the past fiscal month has had its sales closed so processes can be run
Developer: Kyle
Date:
	v1 - 5/7/2018 - Initial creation
	v2 - 5/11/2018 - Built a table to store what the current status is.  This will be used to not re-send out the alert if it doesn't need too.  
Notes:  sy.FORIGIN = 1 -- the master record for the month, year
	sy.PSERIES_2 = 1 -- 1 means closed, 0 means open
*******************************/

/* Production code in schedule SQL Agent */

Select * from
(
Select 
	sy.PERNAME,
	sy.PSERIES_2,
	sy.Year1,
	(select SALES_CLOSED from it.dbo.OTB_MONTHLY_SALES_CLOSED) as Sales_Closed_Period  
From
	blu.dbo.SY40100 sy
where
	cast(sy.PERIODDT as date) = DATEADD(month, DATEDIFF(month, 0, GETDATE()) - 1, 0)
	and sy.FORIGIN = 1
	and sy.PSERIES_2 = 1
) a
where a.Sales_Closed_Period = 'No'

/* 
Column Pseries_2 = Sales, goofy cause sales = series 3
 https://www.gofastpath.com/blog/gp-fiscal-period-auditing-sy40100
*/

/*
code I used to develop it and test it
*/
SELECT
   YEAR1 [Year],
   FSTFSCDY First_Day,
   LSTFSCDY Last_Day,
   NUMOFPER Number_of_Periods,
   CASE HISTORYR
     WHEN 0 THEN 'Open Year'
     WHEN 1 THEN 'Historical Year'
     END Year_Status
FROM blu.dbo.SY40101
ORDER BY YEAR1

SELECT
   D.PERIODID Period_Number,
   D.PERNAME Period_Name,
   D.PERIODDT Starting_Date,
   D.PERDENDT Ending_Date,
   D.YEAR1 Fiscal_Year
FROM blu.dbo.SY40100 D
INNER JOIN
   blu.dbo.SY40101 H
   ON H.YEAR1 = D.YEAR1
WHERE
   D.FORIGIN = 1 AND D.PERIODID <> 0 -- means the start of the year
   and GETDATE() between H.FSTFSCDY and H.LSTFSCDY
ORDER BY D.PERIODID

select top 100 * from blu.dbo.SY40101
select top 100 * from blu.dbo.SY40100 where /*SERIES = 3 and*/  FORIGIN = 1
/*PERNAME = 'APRIL'*/ and year1 = 2018

select	datediff(month, getdate(), -1)
select DATEADD(month, DATEDIFF(month, 0, GETDATE()) - 1, 0)
