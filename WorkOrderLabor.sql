select  case when row_number() over(partition by x.[Entity Name] order by x.[Entity Name])=1 then x.[Entity Name] end as [Entity Name]
          ,x.[Work Order ID],x.[Mechanic],x.[Date Worked],x.[Work Done], x.[Total Labor Hours]
  from (
             SELECT el.Name AS 'Entity Name', wr.WorkRequestID AS 'Work Order ID', tmc.name as 'Mechanic', tmc.[Date Worked],
CAST(wr.RequestDescription as VARCHAR(80)) as 'Work Done', ISNULL(tmc.[Total Labor Hours],0) as 'Total Labor Hours'
FROM    WorkRequest AS wr left outer join

		(Select	wrd.WorkRequestID, iu.WorkRequest_WorkRequestID
				
		 From	
				Inventory_Utilization AS iu left outer join
				Inventory_Transaction AS it ON  iu.Inventory_UtilizationID = it.Inventory_UtilizationID left outer join
				Part As p ON iu.Part_PartID = p.PartID left outer join
				Receival_Detail AS rd ON it.Receival_DetailID = rd.Receival_DetailID inner join
				Receival AS r on rd.Receival_ReceivalID = r.ReceivalID LEFT OUTER JOIN
				WorkRequest_Detail as wrd on iu.WorkRequest_ItemCodeID = wrd.WorkRequest_ItemCodeID  left outer join
				WorkRequest_StatusHistory as wrsh on  wrd.WorkRequestID = wrsh.WorkRequestID left outer join
				WorkRequest_ItemCode as wric on wrd.WorkRequest_ItemCodeID = wric.WorkRequest_ItemCodeID left outer join
				WorkRequest_Scheduling as wrs on wrd.WorkRequestID = wrs.WorkRequestID
		 Where r.IsDeleted = 0 AND  iu.WorkRequest_WorkRequestID > 0 AND wrd.IsDeleted = 0 AND wric.IsDeleted = 0
		 GROUP BY wrd.WorkRequestID, iu.WorkRequest_WorkRequestID, p.PartName, p.PartNum, p.Description, iu.QuantityUtilized ,
				(it.UnitPrice + CASE WHEN rd.OrderReceived > 0 THEN rd.Tax / rd.OrderReceived ELSE 0 END)) as PartsCost ON wr.WorkRequestID = PartsCost.WorkRequest_WorkRequestID left outer join

         (SELECT     cf.CustomFieldID, cf.EntityID, cf.StringType, cfc.FieldName, cfc.CategoryType, cfc.EntityName, cf.BoolType
	       FROM       CustomField AS cf Inner Join
                      CustomField_Category AS cfc ON cf.CustomField_CategoryID = cfc.CustomField_CategoryID
	       WHERE cfc.FieldName = 'SUBCONTRACTOR'  and cf.IsDeleted = 0) as cff on wr.EntityID = cff.EntityID left outer join

		 (SELECT        EquipmentID AS 'EntityID', Name, 0 AS 'WOType'
           FROM            Equipment AS EQP
           UNION ALL
           SELECT        LegacyKey, Code, 1 AS Expr1
           FROM            Job AS Job_1
           UNION ALL
           SELECT        LegacyKey, Name, 2 AS Expr1
           FROM            Shop) AS el ON el.EntityID = wr.EntityID AND el.WOType = wr.WorkRequest_TypeID LEFT OUTER JOIN

			(SELECT		td.WorkRequestID, wric.Code as 'Item Code', 
			SUM(td.regularhours + td.OvertimeHours + td.DoubleTimeHours) as 'Total Labor Hours', CONCAT(p.FirstName,p.LastName) as 'Name', td.Date as 'Date Worked' 
			FROM		TimeCard as t Left Outer Join
						TimeCard_Detail as td on t.TimeCardID = td.TimeCardID Left Outer Join
						Employee as e on t.MechanicID = e.LegacyKey Left Outer Join
						Person as p on e.ID = p.ID left outer join
						payclass as pc on e.PayClassID = pc.ID left outer join
						WorkRequest_ItemCode as wric on td.ItemCodeID = wric.WorkRequest_ItemCodeID

			WHERE td.Voided=0 
			Group by td.WorkRequestID,  wric.Code, CONCAT(p.FirstName,p.LastName), td.Date ) as tmc on wr.WorkRequestID = tmc.WorkRequestID

WHERE wr.WorkRequest_TypeID = 0 and cff.Booltype = 1 and  tmc.[Date Worked] between ? and ? --This is here to be used as parameters in the excel report

Group By el.Name ,wr.WorkRequestID, tmc.name, tmc.[Date Worked], CAST(wr.RequestDescription as VARCHAR(80)), ISNULL(tmc.[Total Labor Hours],0)
          )x
Group By x.[Entity Name], x.[Mechanic] , x.[Date Worked],x.[Work Order ID],x.[Work Done], x.[Total Labor Hours]
order by x.[Entity Name]