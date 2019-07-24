select  case when row_number() over(partition by z.[Work Order ID] order by z.[Work Order ID])=1 then z.[Work Order ID] end as [Work Order ID]
          ,z.[Entity Name],z.[Invoice Number],z.[Part],z.[Part Cost]
  from (

             SELECT  wr.WorkRequestID AS 'Work Order ID', el.Name AS 'Entity Name', PartsCost.InvoiceNum as 'Invoice Number', PartsCost.Part as 'Part' , PartsCost.[Part Cost] as 'Part Cost'
FROM    WorkRequest AS wr Left Outer Join
		(Select	iu.WorkRequest_WorkRequestID, 
				 IIF(r.InvoiceNum = null, r.ReferenceNum, r.InvoiceNum) as 'InvoiceNum', p.PartNum as 'Part', (it.UnitPrice + CASE WHEN rd.OrderReceived > 0 THEN rd.Tax / rd.OrderReceived ELSE 0 END) as 'Part Cost'
		 From	Inventory_Utilization AS iu Left outer Join
				Inventory_Transaction AS it ON iu.Inventory_TransactionID = it.Inventory_TransactionID left outer join
				Part As p ON iu.Part_PartID = p.PartID left outer join
				Receival_Detail AS rd ON it.Receival_DetailID = rd.Receival_DetailID inner join
				Receival AS r on rd.Receival_ReceivalID = r.ReceivalID LEFT OUTER JOIN
				WorkRequest_ItemCode as wric on iu.WorkRequest_ItemCodeID = wric.WorkRequest_ItemCodeID
		 Where iu.WorkRequest_WorkRequestID > 0 
		 GROUP BY  iu.WorkRequest_WorkRequestID, IIF(r.InvoiceNum = null, r.ReferenceNum, r.InvoiceNum), p.PartNum, it.UnitPrice + CASE WHEN rd.OrderReceived > 0 THEN rd.Tax / rd.OrderReceived ELSE 0 END ) as PartsCost ON wr.WorkRequestID = partscost.WorkRequest_WorkRequestID left outer join
		 (SELECT        EquipmentID AS 'EntityID', Name, 0 AS 'WOType'
           FROM            Equipment AS EQP
           UNION ALL
           SELECT        LegacyKey, Code, 1 AS Expr1
           FROM            Job AS Job_1
           UNION ALL
           SELECT        LegacyKey, Name, 2 AS Expr1
           FROM            Shop) AS el ON el.EntityID = wr.EntityID AND el.WOType = wr.WorkRequest_TypeID LEFT OUTER JOIN

			(SELECT		td.WorkRequestID,
			SUM(pc.BaseRate * (td.RegularHours + pc.OvertimeFactor * td.OvertimeHours + pc.DoubleTimeFactor * td.DoubleTimeHours)) as 'Total Labor Costs'
			FROM		TimeCard as t INNER JOIN
						TimeCard_Detail as td on t.TimeCardID = td.TimeCardID INNER JOIN
						Employee as e on t.MechanicID = e.LegacyKey Inner join
						Person as p on e.ID = p.ID left outer join
						payclass as pc on e.PayClassID = pc.ID left outer join
						WorkRequest_ItemCode as wric on td.ItemCodeID = wric.WorkRequest_ItemCodeID
			WHERE td.Voided=0
			Group by td.WorkRequestID) as tmc on wr.WorkRequestID = tmc.WorkRequestID
WHERE wr.WorkRequest_TypeID = 0 and  (wr.StatusDate between ? and ?) and PartsCost.InvoiceNum <> ''
		  )z

order by z.[Work Order ID]