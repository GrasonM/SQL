DECLARE
		@rptStartDate date,
		@rptEndDate date

Set @rptStartDate = ?
Set @rptEndDate = ?


SELECT a.Vehicle, a.NAME as 'Name', SUM(CAST(a.[Odometer] as int)) as 'Miles Driven'

From

(SELECT
			   e.accountingcode AS [Vehicle],
			    fta.Date as 'Date',
			   Concat(e.year + ' ', e.make + ' ', e.model + ' ', Cast( e.[Description] AS VARCHAR(80))) AS NAME,
			   fta.Odometer as 'Readings' , CASE WHEN COALESCE(Lag(e.accountingcode) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.Odometer), '0') <> e.accountingcode 
			THEN '0' ELSE Lag(fta.Odometer) OVER ( partition BY e.accountingcode ORDER BY e.accountingcode, fta.Odometer) END as 'Previous Reading', fta.Odometer - Iif((CASE WHEN COALESCE(Lag(e.accountingcode) OVER ( partition BY e.accountingcode ORDER BY
			 e.accountingcode, fta.Odometer), '0') <> e.accountingcode THEN '0' ELSE Lag(fta.Odometer) OVER ( partition BY e.accountingcode 
			ORDER BY e.accountingcode, fta.Odometer) END) = '0', fta.Odometer, CASE WHEN COALESCE(Lag(e.accountingcode) OVER ( partition BY e.accountingcode 
			ORDER BY e.accountingcode, fta.Odometer), '0') <> e.accountingcode THEN '0' ELSE Lag(fta.Odometer) OVER ( partition BY e.accountingcode ORDER BY
			   e.accountingcode, fta.Odometer) END ) AS 'Odometer' 
			
from Equipment as e inner join

	 -- Fuel total gallons and cost per container per fluid
	(SELECT    fc.EquipmentID, CAST(ft.TransferDate as Date) as 'Date',IIF(ft.OdometerReading = 0 , null, ft.OdometerReading) as 'Odometer'
	 FROM        FluidTransfer AS ft inner join
			fluidtransferdetail as ftd on ft.ID = ftd.FluidTransferID  and (ft.DestinationContainerID = ftd.DestinationContainerID or ft.DestinationContainerID = ftd.SourceContainerID) inner join
			FluidTransferInventory as fti on ftd.id = fti.FluidTransferDetailID left outer Join
			FluidContainer as fc on ft.DestinationContainerID = fc.ID inner join
			fluid as f on ft.fluidid = f.ID inner join
			FluidCost as fifo on fti.FifoCostID = fifo.ID
	 where  ft.Type in (0,1) and (isburntank = 1) and (f.code in ('ON-ROAD', 'UNLEADED')) and ft.OdometerReading <> 0 
	 Group BY fc.EquipmentID, ft.TransferDate ,ft.OdometerReading) as fta on e.id = fta.EquipmentID

	) as a left outer join
			Equipment as e on a.Vehicle = e.AccountingCode 

			

WHERE (((e.AccountingCode) >= ? and (e.AccountingCode) <= ?) AND ((e.IsDeleted)=0)) AND a.Date between @rptStartDate and @rptEndDate
group by a.Vehicle, a.NAME
order by Vehicle