DECLARE
		@rptStartDate date,
		@rptEndDate date

Set @rptStartDate = ?
Set @rptEndDate = ?

SELECT core.name, core.operator, CAST(Core.Description as varchar(120)) as [Description], core.Reported, SUM(core.[Elapsed Utilization]) as 'Utilization', core.[Fuel Consumed] ,ISNULL((Case when SUM(core.[Elapsed Utilization]) = 0 then null
Else (ISNULL(Core.[Fuel Consumed], '0')/SUM(core.[Elapsed Utilization])) END), '0') as 'GPH'
FROM 



(SELECT e.name as 'Name', IIF(cfo.StringType = '', cfo1.StringType, cfo.StringType)  AS 'Operator' , CONCAT(e.year + ' ', e.make + ' ' , e.model + ' ' ,e.Description + ' ')as 'Description' , 
emh.ReadingDate as 'Date', 
ISNULL(a.Reported, '0') as 'Reported' , IIF(emh.TrueReading = 0, null, emh.truereading) as 'Utilized', 
				
				(CASE WHEN COALESCE(Lag(e.name) OVER ( partition BY e.name ORDER BY
			  e.name, emh.TrueReading), '0') <> e.name THEN '0' ELSE Lag(emh.TrueReading) OVER ( partition BY e.name ORDER BY e.name, emh.TrueReading) 
			   END) as 'Previous Utilized', 
			   
			   (emh.TrueReading - Iif(( CASE WHEN COALESCE(Lag(e.name) OVER ( partition BY e.name ORDER BY e.name, emh.TrueReading), '0') <> e.name 
THEN '0' ELSE Lag(emh.TrueReading) OVER ( partition BY e.name ORDER BY e.name, emh.TrueReading) END) = '0', emh.TrueReading, CASE WHEN
   COALESCE( Lag(e.name) OVER ( partition BY e.name ORDER BY e.name, emh.TrueReading), '0') <> e.name THEN
   '0' ELSE Lag(emh.TrueReading) OVER ( partition BY e.name ORDER BY e.name, emh.TrueReading) 
   END )) AS 'Elapsed Utilization',
   
   q.Quantity as 'Fuel Consumed'


FROM Equipment as e inner join
	Equipment_MeterHistory as emh on e.EquipmentID = emh.Equipment_EquipmentID /*inner join
	Equipment_OdometerHistory as eoh on e.EquipmentID = eoh.Equipment_EquipmentID */left outer join

	(SELECT e.EquipmentID, sum(ehu.HoursUtilized) as 'Reported'
	FROM Equipment as e Inner Join	
		 Equipment_HoursUtilized as ehu on e.equipmentID = ehu.EquipmentID 
		 WHERE CAST(ehu.Date as Date) between @rptStartDate and @rptEndDate
	GROUP BY e.equipmentID) as a on e.EquipmentID = a.equipmentID Left outer Join

	(SELECT e.EquipmentID as 'EquipmentID',  sum(ft.Quantity) as 'Quantity'
		FROM equipment as e inner join
			 Fluidcontainer as fc ON e.ID = fc.EquipmentID inner join
			 FluidTransfer as ft ON fc.ID = ft.DestinationContainerID
			 WHERE CAST(ft.TransferDate as Date) between @rptStartDate and @rptEndDate 
			 Group By e.EquipmentID) as q ON e.EquipmentID = q.EquipmentID left outer join

	(SELECT cf.CustomFieldID, cf.EntityID, cf.StringType, cfc.FieldName, cfc.CategoryType, cfc.EntityName
FROM Equipment360.dbo.CustomField AS cf INNER JOIN Equipment360.dbo.CustomField_Category AS cfc ON cf.CustomField_CategoryID = cfc.CustomField_CategoryID
WHERE cfc.FieldName = 'Operator' and cf.IsDeleted = 0)  AS cfo 
ON e.EquipmentID = cfo.EntityID LEFT JOIN

(SELECT cf.CustomFieldID, cf.EntityID, cf.StringType, cfc.FieldName, cfc.CategoryType, cfc.EntityName
FROM Equipment360.dbo.CustomField AS cf INNER JOIN Equipment360.dbo.CustomField_Category AS cfc ON cf.CustomField_CategoryID = cfc.CustomField_CategoryID
WHERE cfc.FieldName = 'Unassigned Description' and cf.IsDeleted = 0)  AS cfo1
ON e.EquipmentID = cfo1.EntityID

	WHERE e.IsDeleted = 0 
group by e.name, emh.ReadingDate ,IIF(cfo.StringType = '', cfo1.StringType, cfo.StringType) ,CONCAT(e.year + ' ', e.make + ' ' , e.model + ' ' ,e.Description + ' '), a.Reported ,emh.TrueReading, q.Quantity 
) as Core


WHERE CAST(core.Date as DATE) Between @rptStartDate and @rptEndDate
Group By core.name, core.operator, core.description, core.Reported, core.[Fuel Consumed], core.[Fuel Consumed]
order by core.name