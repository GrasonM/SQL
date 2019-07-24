SET ANSI_WARNINGS OFF
DECLARE
		@rptStartDate date,
		@rptEndDate date

Set @rptStartDate = ?
Set @rptEndDate = ?


SELECT a.Vehicle, a.NAME as 'Name', a.Operator, a.Fluid, SUM(a.TransactionCount) as 'Transactions', 
IIF(IIF(CONCAT(CASE WHEN SUM(CAST(a.[odometer] as int)) = 0 then null else SUM(CAST(a.[odometer] as int)) END , ' Miles @ ' , CASE WHEN SUM(CAST(a.[odometer] as int))= 0 then null else SUM(CAST(a.[odometer] as int))/SUM(a.Gallons) END, ' MPG' ) = ' Miles @  MPG', CONCAT(CASE WHEN SUM(CAST(a.[hour] as int)) = 0 then null else SUM(CAST(a.[hour] as int)) END , ' Hours @ ' , CASE WHEN SUM(CAST(a.[hour] as int)) = 0 then null else SUM(a.Gallons)/SUM(CAST(a.[hour] as int)) END , ' GPH'), CONCAT(SUM(CAST(a.[odometer] as int)) , ' Miles @ ' , SUM(CAST(a.[odometer] as int))/SUM(a.Gallons) , ' MPG' )) = ' Hours @  GPH', '', IIF(CONCAT(SUM(CAST(a.[odometer] as int)) , ' Miles @ ' , SUM(CAST(a.[odometer] as int))/SUM(a.Gallons) , ' MPG' ) = ' Miles @  MPG', CONCAT(SUM(CAST(a.[hour] as int)) , ' Hours @ ' , SUM(a.Gallons)/SUM(CAST(a.[hour] as int)) , ' GPH'), CONCAT(SUM(CAST(a.[odometer] as int)) , ' Miles @ ' , SUM(CAST(a.[odometer] as int))/SUM(a.Gallons) , ' MPG' ))) as ' ', 
 AVG(a.[Unit Price]) as 'Avg Price', SUM(a.Gallons) as 'Total Gallons' ,SUM(a.[Total Cost]) as 'Total Cost'

From

(SELECT
			   e.accountingcode AS [Vehicle],
			    fta.Date as 'Date',
			   Concat(e.year + ' ', e.make + ' ', e.model + ' ', Cast( e.[Description] AS VARCHAR(80))) AS NAME,
			   Iif(cff.stringtype = '', cff1.stringtype, cff.stringtype) AS 'Operator', tmc.OperatorTest ,fta.fluid,
			   CONCAT(fta.odometer, fta.hour) as 'Readings', CONCAT(CASE WHEN COALESCE(Lag(e.accountingcode) OVER ( partition BY e.accountingcode ORDER BY
			  e.accountingcode, fta.odometer), '0') <> e.accountingcode THEN null ELSE Lag(fta.odometer) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.odometer) 
			   END, CASE WHEN COALESCE(Lag(e.accountingcode) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.hour), '0') <> e.accountingcode 
			THEN '0' ELSE Lag(fta.hour) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.hour) END) as 'Previous Reading', fta.odometer - Iif(( 
			   CASE WHEN COALESCE(Lag(e.accountingcode) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.odometer), '0') <> e.accountingcode 
			THEN '0' ELSE Lag(fta.odometer) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.odometer) END) = '0', fta.odometer, CASE WHEN
			   COALESCE( Lag(e.accountingcode) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.odometer), '0') <> e.accountingcode THEN
			   '0' ELSE Lag(fta.odometer) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.odometer) 
			   END ) as 'Odometer', fta.hour - Iif((CASE WHEN COALESCE(Lag(e.accountingcode) OVER ( partition BY e.accountingcode ORDER BY
			 e.accountingcode, fta.hour), '0') <> e.accountingcode THEN '0' ELSE Lag(fta.hour) OVER ( partition BY e.accountingcode 
			ORDER BY e.accountingcode, fta.hour) END) = '0', fta.hour, CASE WHEN COALESCE(Lag(e.accountingcode) OVER ( partition BY e.accountingcode 
			ORDER BY e.accountingcode, fta.hour), '0') <> e.accountingcode THEN '0' ELSE Lag(fta.hour) OVER ( partition BY e.accountingcode ORDER BY
			   e.accountingcode, fta.hour) END ) AS 'hour' , fta.TransactionCount ,fta.Quantity as Gallons, fta.totalcost/fta.Quantity as [Unit Price], fta.totalcost as [Total Cost]
			
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
	(SELECT    fc.EquipmentID, fc.FluidID as 'FluidID', ft.id, CAST(MAX(ft.TransferDate) as Date) as 'Date', Count(Distinct ft.id) as 'TransactionCount',MAX(f.code) as 'Fluid', IIF(ft.MeterReading = 0 , null, ft.MeterReading) as 'Hour', IIF(ft.OdometerReading = 0, null, ft.OdometerReading ) as 'Odometer' , 
			 ft.Quantity ,SUM(fifo.Cost * CASE WHEN ft.DestinationContainerID = ftd.DestinationContainerID THEN fti.Quantity  ELSE -1* fti.Quantity END) as 'totalcost', ft.EmployeeID
	 FROM        FluidTransfer AS ft left outer join
			fluidtransferdetail as ftd on ft.ID = ftd.FluidTransferID  and (ft.DestinationContainerID = ftd.DestinationContainerID or ft.DestinationContainerID = ftd.SourceContainerID) left outer join
			FluidTransferInventory as fti on ftd.id = fti.FluidTransferDetailID left outer Join
			FluidContainer as fc on ft.DestinationContainerID = fc.ID inner join
			fluid as f on ft.fluidid = f.ID inner join
			FluidCost as fifo on fti.FifoCostID = fifo.ID
	 where  ft.Type in (0,1) and (isburntank = 1) and (f.code in ('ON-ROAD', 'UNLEADED')) 
	 Group BY fc.EquipmentID, fc.FluidID, ft.id ,ft.MeterReading, ft.OdometerReading,  ft.Quantity, ft.EmployeeID) as fta on e.id = fta.EquipmentID inner join

	 (SELECT e.ID, CONCAT(p.FirstName, ' ' ,p.LastName) as 'OperatorTest' 
			FROM	
					Employee as e Inner join
					Person as p on e.ID = p.ID 
			Group by e.ID, CONCAT(p.FirstName, ' ' ,p.LastName)) as tmc on fta.EmployeeID = tmc.ID
			
			

			) as a left outer join
			Equipment as e on a.Vehicle = e.AccountingCode 

			

WHERE (((e.AccountingCode) >= ? and (e.AccountingCode) <= ?) AND ((e.IsDeleted)=0)) AND a.Date between @rptStartDate and @rptEndDate and ((e.IsDeleted)=0) 
group by a.Vehicle, a.NAME, a.Operator, a.Fluid
order by Vehicle