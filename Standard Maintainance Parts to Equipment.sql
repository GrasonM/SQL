select  case when row_number() over(partition by y.[Part Number] order by y.[Part Number])=1 then y.[Part Number] end as [Part Number]
          ,y.Description,y.Quantity, y.Unit, y.Name
  from (
select  case when row_number() over(partition by x.[Part Number] order by x.[Part Number])=1 then x.Description end as Description
          ,x.[Part Number],x.Quantity, x.Unit, x.Name
  from (
             SELECT DISTINCT  P.PartNum AS [Part Number], P.Description, EPMSP.Quantity, E.AccountingCode AS Unit, CONCAT(e.year + ' ', e.make + ' ', e.model + ' ', CAST(e.[Description] as VARCHAR(80))) As Name
FROM UnitOfMeasure AS UOM INNER JOIN (Part AS P INNER JOIN ((Equipment_PMSetup AS EPMS INNER JOIN Equipment AS E ON EPMS.EquipmentID = E.EquipmentID) INNER JOIN 
Equipment_PMSetupPart AS EPMSP ON EPMS.Equipment_PMSetupID = EPMSP.Equipment_PMSetupID) ON P.PartID = EPMSP.Part_PartID) ON UOM.LegacyKey = P.Part_UnitOfMeasureID
WHERE E.IsDeleted = 0
          )x 
		  )y
		  order by y.[Part Number]