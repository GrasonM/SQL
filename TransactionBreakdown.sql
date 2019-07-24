DECLARE
		@rptStartDate date,
		@rptEndDate date

Set @rptStartDate = ?
Set @rptEndDate = ?


SELECT
   e.accountingcode AS [Vehicle],
    fta.Date as 'Date',
   Concat(e.year + ' ', e.make + ' ', e.model + ' ', Cast( e.[Description] AS VARCHAR(80))) AS NAME,
   Iif(cff.stringtype = '', cff1.stringtype, cff.stringtype) AS 'Operator', tmc.OperatorTest ,fta.fluid,
   CONCAT(fta.odometer, fta.hour) as 'Readings', CONCAT(CASE WHEN COALESCE(Lag(e.accountingcode) OVER ( partition BY e.accountingcode ORDER BY
  e.accountingcode, fta.odometer), '0') <> e.accountingcode THEN null ELSE Lag(fta.odometer) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.odometer) 
   END, CASE WHEN COALESCE(Lag(e.accountingcode) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.hour), '0') <> e.accountingcode 
THEN '0' ELSE Lag(fta.hour) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.hour) END) as 'Previous Reading', CONCAT(fta.odometer - Iif(( 
   CASE WHEN COALESCE(Lag(e.accountingcode) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.odometer), '0') <> e.accountingcode 
THEN '0' ELSE Lag(fta.odometer) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.odometer) END) = '0', fta.odometer, CASE WHEN
   COALESCE( Lag(e.accountingcode) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.odometer), '0') <> e.accountingcode THEN
   '0' ELSE Lag(fta.odometer) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.odometer) 
   END ), fta.hour - Iif((CASE WHEN COALESCE(Lag(e.accountingcode) OVER ( partition BY e.accountingcode ORDER BY
 e.accountingcode, fta.hour), '0') <> e.accountingcode THEN '0' ELSE Lag(fta.hour) OVER ( partition BY e.accountingcode 
ORDER BY e.accountingcode, fta.hour) END) = '0', fta.hour, CASE WHEN COALESCE(Lag(e.accountingcode) OVER ( partition BY e.accountingcode 
ORDER BY e.accountingcode, fta.hour), '0') <> e.accountingcode THEN '0' ELSE Lag(fta.hour) OVER ( partition BY e.accountingcode ORDER BY
   e.accountingcode, fta.hour) END )) AS 'Elapsed Odometer' , ftc.TransactionCount ,fta.Quantity as Gallons, fta.totalcost/fta.Quantity as [Unit Price], fta.totalcost as [Total Cost]

from Equipment as e left outer join

	(SELECT     cf.CustomFieldID, cf.EntityID, cf.StringType, cfc.FieldName, cfc.CategoryType, cfc.EntityName
	 FROM       CustomField AS cf INNER JOIN
                CustomField_Category AS cfc ON cf.CustomField_CategoryID = cfc.CustomField_CategoryID
	 WHERE cfc.FieldName = 'Operator' and cf.IsDeleted = 0) as cff on e.EquipmentID = cff.EntityID left outer join

	(SELECT     cf.CustomFieldID, cf.EntityID, cf.StringType, cfc.FieldName, cfc.CategoryType, cfc.EntityName
	 FROM       CustomField AS cf INNER JOIN
                CustomField_Category AS cfc ON cf.CustomField_CategoryID = cfc.CustomField_CategoryID
	 WHERE cfc.FieldName = 'Unassigned Description' and cf.IsDeleted = 0) as cff1 on e.EquipmentID = cff1.EntityID left outer join

	 -- Fuel total gallons and cost per container per fluid
	(SELECT    fc.EquipmentID, fc.FluidID as 'FluidID', MAX(f.code) as 'Fluid', IIF(ft.MeterReading = 0 , null, ft.MeterReading) as 'Hour', IIF(ft.OdometerReading = 0, null, ft.OdometerReading ) as 'Odometer' , 
			ft.TransferDate as 'Date', ft.Quantity, SUM(fifo.Cost * CASE WHEN ft.DestinationContainerID = ftd.DestinationContainerID THEN fti.Quantity  ELSE -1* fti.Quantity END) as 'totalcost', ft.EmployeeID
	 FROM        FluidTransfer AS ft left outer join
			fluidtransferdetail as ftd on ft.ID = ftd.FluidTransferID  and (ft.DestinationContainerID = ftd.DestinationContainerID or ft.DestinationContainerID = ftd.SourceContainerID) left outer join
			FluidTransferInventory as fti on ftd.id = fti.FluidTransferDetailID left outer Join
			FluidContainer as fc on ft.DestinationContainerID = fc.ID inner join
			fluid as f on ft.fluidid = f.ID inner join
			FluidCost as fifo on fti.FifoCostID = fifo.ID
	 where  ft.Type in (0,1) and (isburntank = 1) and (f.code in ('ON-ROAD', 'UNLEADED')) 
	 Group BY fc.EquipmentID, fc.FluidID, ft.MeterReading, ft.OdometerReading, ft.TransferDate, ft.Quantity, ft.EmployeeID) as fta on e.id = fta.EquipmentID inner join

	 --Count of transactions by equipment and fluid
	(SELECT fcd.EquipmentID, ft.FluidID, COUNT(*) as 'TransactionCount'
	 FROM   FluidTransfer AS ft left outer join
			FluidContainer as FcD on ft.destinationcontainerid = fcD.id
	 where (isburntank = 1)
	 Group By fcd.EquipmentID, ft.FluidID) as ftc on fta.EquipmentID = ftc.EquipmentID and fta.FluidID = ftc.FluidID left outer join

	 (SELECT e.ID, CONCAT(p.FirstName, ' ' ,p.LastName) as 'OperatorTest' 
			FROM	
					Employee as e Inner join
					Person as p on e.ID = p.ID 
			Group by e.ID, CONCAT(p.FirstName, ' ' ,p.LastName)) as tmc on fta.EmployeeID = tmc.ID


WHERE ((e.AccountingCode) = ?  AND ((e.IsDeleted)=0)) 

order by AccountingCode