DECLARE
	@rptStartDate date,
	@rptEndDate date

Set @rptStartDate = ?
Set @rptEndDate = ?

             SELECT  a.Equipment  as 'EquipID', a.WOID as 'WoNum', a.Date ,Part.PartNum as 'PartNum', CAST(Part.PartName as VARCHAR(80)) as 'PartName', pl.code as 'Location' ,a.QuantityUtilized as ' Qty ',
			  a.[UnitPrice] as 'UnitPrice' , (a.tax * a.QuantityUtilized) as 'Tax', a.SubTotal, a.Total

FROM	(Select t.Equipment, t.WOID , t.Date ,t.PartID, t.Location ,t.QuantityUtilized as 'QuantityUtilized', t.UP as 'UnitPrice', t.tax, (QuantityUtilized * UP) as 'SubTotal', ((QuantityUtilized * UP) + (tax * QuantityUtilized)) as 'Total'
		 
		 FROM		
		 	
					(SELECT e.accountingcode as 'Equipment', e.EquipmentID as 'EquipID', wr.EntityID as 'EntityID', iu.UtilizedDateTime as 'Date' ,iu.Part_PartID as 'PartID' ,it.Part_LocationsID as 'Location', 
					wr.WorkRequestID as 'WOID', CAST(SUM(iu.QuantityUtilized) as int) as 'QuantityUtilized', MAX(it.UnitPrice) as 'UP', 
					CASE WHEN MAX(rd.OrderReceived) > 0 THEN MAX(rd.Tax / rd.OrderReceived) ELSE 0 END as 'tax'
					 FROM		Equipment as e INNER JOIN
								WorkRequest as wr ON e.EquipmentID = wr.EntityID INNER JOIN
								Inventory_Utilization as iu on wr.WorkRequestID = iu.WorkRequest_WorkRequestID 	INNER JOIN
								Inventory_Transaction as it  ON iu.Inventory_TransactionID = it.Inventory_TransactionID left outer join
								Receival_Detail AS rd ON it.Receival_DetailID = rd.Receival_DetailID inner join
								Receival AS r on rd.Receival_ReceivalID = r.ReceivalID 
								WHERE CAST(iu.UtilizedDateTime as Date) between @rptStartDate and @rptEndDate and e.isdeleted = 0 and r.IsDeleted = 0 
					 GROUP BY	e.accountingcode , e.EquipmentID , wr.EntityID, iu.UtilizedDateTime ,wr.WorkRequestID, iu.Part_PartID, it.Part_LocationsID) as t) as a left outer join

					 

		Part_Locations as pl ON a.Location = pl.ID INNER JOIN 
		Part left outer join 
		Part_Category ON Part_Category.Part_CategoryID = part.Part_CategoryID left outer join 
		UnitOfMeasure ON UnitOfMeasure.LegacyKey = Part.Part_UnitOfMeasureID ON a.PartID = Part.PartID left outer join
		Part_LocationsReorderLevel as plrl on part.ID = plrl.PartID and a.Location = plrl.Part_LocationsID 
		WHERE pl.Code = ? and /*and Part_Category.Code = 'FILTERS' or Part_Category.Code = 'OIL' */ Part.IsDeleted = 0 and a.Equipment between '0900' and '9999'
		ORDER BY a.Equipment, a.WOID, Part.PartNum