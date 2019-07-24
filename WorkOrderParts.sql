select  case when row_number() over(partition by x.[Entity Name] order by x.[Entity Name])=1 then x.[Entity Name] end as [Entity Name]
          ,x.[Work Order ID],x.[Date Utilized],x.[Work Done], x.[Part], x.[Part #], x.[Part Description], x.Quantity, x.[Unit Price] ,x.[Parts Cost]
  from (
             SELECT el.Name AS 'Entity Name', wr.WorkRequestID AS 'Work Order ID', partscost.[Date Utilized], 
CAST(wr.RequestDescription as VARCHAR(80)) as 'Work Done', PartsCost.Part as 'Part', PartsCost.[Part #] as 'Part #', CAST(PartsCost.[Part Description]as VARCHAR(80)) as 'Part Description', 
		SUM(PartsCost.Quantity) as 'Quantity', PartsCost.[Part Cost] as 'Unit Price', PartsCost.[Part Cost] * SUM(PartsCost.Quantity) as 'Parts Cost'
FROM    WorkRequest AS wr left outer join

(SELECT        EquipmentID AS 'EntityID', Name, 0 AS 'WOType'
           FROM            Equipment AS EQP
           UNION ALL
           SELECT        LegacyKey, Code, 1 AS Expr1
           FROM            Job AS Job_1
           UNION ALL
           SELECT        LegacyKey, Name, 2 AS Expr1
           FROM            Shop) AS el ON el.EntityID = wr.EntityID AND el.WOType = wr.WorkRequest_TypeID LEFT OUTER JOIN

		   (SELECT     cf.CustomFieldID, cf.EntityID, cf.StringType, cfc.FieldName, cfc.CategoryType, cfc.EntityName, cf.BoolType
	       FROM       CustomField AS cf Inner Join
                      CustomField_Category AS cfc ON cf.CustomField_CategoryID = cfc.CustomField_CategoryID
	       WHERE cfc.FieldName = 'SUBCONTRACTOR'  and cf.IsDeleted = 0) as cff on wr.EntityID = cff.EntityID inner join

		(Select	  iu.part_partID, iu.QuantityUtilized as 'Quantity',iu.Inventory_UtilizationID, iu.WorkRequest_WorkRequestID, iu.UtilizedDateTime as 'Date Utilized', p.PartName as 'Part', p.PartNum as 'Part #', p.Description as 'Part Description',
				(it.UnitPrice + CASE WHEN rd.OrderReceived > 0 THEN rd.Tax / rd.OrderReceived ELSE 0 END) as 'Part Cost'
		 From	
				Inventory_Utilization AS iu left outer join
				Inventory_Transaction AS it ON  iu.Inventory_UtilizationID = it.Inventory_UtilizationID left outer join
				Part As p ON iu.Part_PartID = p.PartID left outer join
				Receival_Detail AS rd ON it.Receival_DetailID = rd.Receival_DetailID left outer join
				Receival AS r on rd.Receival_ReceivalID = r.ReceivalID LEFT OUTER JOIN
				WorkRequest_Detail as wrd on iu.WorkRequest_ItemCodeID = wrd.WorkRequest_ItemCodeID 
		 Where r.IsDeleted = 0 AND  iu.WorkRequest_WorkRequestID > 0 AND wrd.IsDeleted = 0 and iu.UtilizedDateTime between ? and ?
		 GROUP BY iu.part_partID, iu.QuantityUtilized , iu.Inventory_UtilizationID, iu.WorkRequest_WorkRequestID, iu.UtilizedDateTime, p.PartName, p.PartNum, p.Description,
				(it.UnitPrice + CASE WHEN rd.OrderReceived > 0 THEN rd.Tax / rd.OrderReceived ELSE 0 END)) as PartsCost ON wr.WorkRequestID = PartsCost.WorkRequest_WorkRequestID

WHERE wr.WorkRequest_TypeID = 0 and cff.Booltype = 1 

Group By el.Name ,wr.WorkRequestID, PartsCost.[Date Utilized], CAST(wr.RequestDescription as VARCHAR(80)), PartsCost.Part, PartsCost.[Part #], CAST(PartsCost.[Part Description]as VARCHAR(80)),
		 PartsCost.Quantity, PartsCost.[Part Cost]
          )x
Group By x.[Entity Name], x.[Work Order ID],x.[Date Utilized],x.[Work Done], x.[Part], x.[Part #], x.[Part Description], x.Quantity , x.[Unit Price] ,x.[Parts Cost]
order by x.[Entity Name]