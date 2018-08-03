
ALTER view [dbo].[Return_Defect_Orders] as 

Select 
	cast(st.[Document Date] as date) as [Document Date], st.[Sop Number], 
	sli.[Item Number], sli.[Item Description],  substring(sli.[Item Number], 3,1) as Item_Level,
	c.STRNG132 as [Return Reascon Code Value],
	concat(d.comment_1 , d.comment_2, d.comment_3, d.comment_4) as [Comment Text],
	case when (c.STRNG132 is Null or c.STRNG132 = '') 
			and (concat(d.comment_1 , d.comment_2, d.comment_3, d.comment_4) is null or concat(d.comment_1 , d.comment_2, d.comment_3, d.comment_4) = '') then 'Yes'
		when (c.STRNG132 is not Null and c.STRNG132 <> '') 
			and (concat(d.comment_1 , d.comment_2, d.comment_3, d.comment_4) is not null and concat(d.comment_1 , d.comment_2, d.comment_3, d.comment_4) <> '') then 'No'
		Else 'Partial'
	End as [Missing Reasons],
/*	case when c.STRNG132 is Null then 'Yes'
		when c.STRNG132 = '' then 'Yes'
			when c.STRNG132 is not Null then 'No'
			Else 'UNK'
	End as [Missing Reason],
	case when concat(d.comment_1 , d.comment_2, d.comment_3, d.comment_4) is null then 'Yes'
		when concat(d.comment_1 , d.comment_2, d.comment_3, d.comment_4) = '' then 'Yes'
		when concat(d.comment_1 , d.comment_2, d.comment_3, d.comment_4) is not null then 'No'	
		Else 'Unk'
	End as [Missing Comment],
*/
	sli.QTY, sli.[Line Item Sequence] as [Sales Line Item Sequence] ,
	st.[SOP Type],  st.[Document Status], st.[Customer Name],
	li.REPORTING_CUSTOMER_CLASS as [Customer Class], li.LOCATION_TYPE as [Location Type],
	/* st.[Document ID], st.[Customer Class] as [Order Customer Class], */
	st.[Batch Number] , st.[Master Number] , st.[Void Status], st.[Customer PO Number], st.[Salesperson ID],
	sli.[Item Type], sli.[User Category Value 1] as [BDB Product],
	Sli.[User Category Value 2] as [Active Item], Sli.[User Category Value 3] as [Color], Sli.[User Category Value 4] as [Style],
	Sli.[User Category Value 5] as [Category], sli.[Item Class Code],
	/* a.Extender_Key_Values_1 as [Extender Line Item Seq],  a.Extender_Record_ID, */
	/*b.Total as Return_Reason_Code, */
	d.comment_1, d.comment_2, d.comment_3, d.comment_4
		
	/*
	case WHEN SUBSTRING (st.[Sop Number]  ,1,3) = 'SVC' THEN 1
	WHEN SUBSTRING (st.[Sop Number]   ,1,5) = 'STSVC' THEN 1
	WHEN SUBSTRING (st.[Sop Number]  ,1,3) = 'RET' THEN 1
	WHEN SUBSTRING (st.[Sop Number]   ,1,5) = 'STRET' THEN 1
	Else 0 
	end as [In old report]
	*/
From
	blu.dbo.SalesTransactions st
	inner join
	blu.dbo.SalesLineItems sli
		on st.[SOP Number] = sli.[SOP Number]
		and st.[SOP Type] = sli.[SOP Type]
/*	Inner Join
	blu.dbo.iv00101 iv
		on sli.[Item Number] = iv.ITEMNMBR
*/
	inner join
	it.dbo.LOCATION_INFO li
		on st.[Customer Class] = li.System_CUSTOMER_CLASS	
	Left Join -- current join causes duplicates (I think this is really order level but it builds records for line items, going to try to roll it up first)
	blu.dbo.EXT01100 a  -- the main extender table that joins to the extender details
		on st.[SOP Number] = a.Extender_Key_Values_2
		and sli.[Line Item Sequence] = a.Extender_Key_Values_1
		and a.Extender_Window_ID = 'BLU DOT'
	left join
	blu.dbo.EXT01103 b
		on a.Extender_Record_ID = b.Extender_Record_ID
	Left Join
	blu.dbo.EXT20021 c 
		on b.Total = c.Extender_List_Item_ID
		and c.Extender_List_ID = 1
	Left Join
	blu.dbo.SOP10202 d
		on sli.[Line Item Sequence] = d.lnitmseq
		and sli.[SOP Number] = d.sopnumbe
where 
	(((st.[SOP Type] = 'Return' or st.[SOP Number] like '%SVC%') and st.[SOP Type] not in ('Invoice', 'Back Order')) 
	or (st.[SOP Type] =  'Invoice' and st.[Batch Number] = 'STORE FLOOR' and st.[SOP Number] like '%SVC%') ) 
	-- and datepart(year, st.[Document Date]) >= 2018
	-- and st.[SOP Number] in ('SVC00052204', 'Return00009370')
	and st.[Document Date] >= '2010-01-01'
