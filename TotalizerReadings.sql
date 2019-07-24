Select TD.date, fc.code, Dispensed.TotalDispensed, Purchased.TotalPurchased, Measured.TotalMeasured
from FluidContainer as fc inner join Fluid as f ON fc.FluidID = f.ID inner join 

		-- All dates
		(SELECT fc.ID, CAST(ftdate.transferdate as  date) as 'Date'
		 FROM FluidTransfer as ftdate,
		 FluidContainer as fc
		 GROUP BY fc.ID, CAST(ftdate.transferdate as date)) as TD on fc.id = TD.ID left outer join
		 
		 -- This queries the total fuel dispensed by a container each day		
         (Select SourceContainerID, CAST(ft.transferdate as date) as 'DispenseDate', SUM(ft.Quantity) as 'TotalDispensed'
		 from	FluidTransfer as ft inner join
		 FluidContainer as fcS on ft.SourceContainerID = fcs.ID 
		 group by SourceContainerID, CAST(ft.transferdate as date)) as Dispensed on fc.ID = Dispensed.SourceContainerID and TD.Date = Dispensed.DispenseDate left outer join

		 -- This queries the total fuel purchased by a container each day.
		(Select DestinationContainerID, CAST(ftd.TransferDate as date) as 'PurchaseDate' , SUM(ftd.Quantity) as 'TotalPurchased'
		 from	FluidTransfer as ftd inner join
		 FluidContainer as fcS on ftd.DestinationContainerID = fcs.ID 
		 group by DestinationContainerID, CAST(ftd.TransferDate as date)) as Purchased on fc.ID = Purchased.DestinationContainerID and TD.Date = Purchased.PurchaseDate left outer join
		 
		 -- This queries the inches read
	    (SELECT FcS.ID, CAST(FTP.TaskDate as date) as 'MeasureDate', FTP.Notes as 'TotalMeasured' ,ftask.NAME
		FROM FuelerTask as ftask inner join
		 FuelerTaskPerformed as FTP ON ftask.ID = FTP.FuelerTaskID,
		 FluidContainer as fcS 
		WHERE fcS.EquipmentID = FTP.EquipmentID AND ((ftask.NAME) <> 'DEF')
		group by FcS.ID, FTP.Notes, CAST(FTP.TaskDate as date), ftask.NAME) as Measured on fc.ID = Measured.ID and TD.Date = Measured.MeasureDate

WHERE (((fc.IsBurnTank)=0)  AND  /*((Measured.NAME) <> 'DEF') AND*/ ((fc.IsDeleted)=0) AND  ((f.Code)='ON-ROAD') AND ((fc.AttachedType) = 1))	 
order by fc.Code, TD.date