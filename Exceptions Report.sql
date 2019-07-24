SELECT  (p.FirstName + ' ' + p.LastName) as 'Fueler', CONVERT(VARCHAR(10),ft.TransferDate,101) as 'Date', fcS.code as 'From', fcD.Code as 'To', ft. Quantity, 
			ft.MeterReading, ft.MeterReadingDate, ft. OdometerReading, ft.OdometerReadingDate, 
			'Bad Meter Reading' as 'Problem Description'
FROM        
			FluidTransfer AS ft left outer join
			FluidContainer as fcS on ft.SourceContainerID = fcS.ID left outer Join
			FluidContainer as fcD on ft.DestinationContainerID = fcD.ID left outer join
			Equipment As e1 on fcS.EquipmentID = e1.ID left outer join
			Equipment As e2 on fcD.EquipmentID = e2.ID left outer join
			person as p on ft.EmployeeID = p.ID left outer join
			Vendor as V on ft.VendorID = v.ID 
where		CAST(ft.TransferDate as date) between DATEADD(day,-30,CAST(getdate() as date)) and CAST(getdate() as date) and 
			(ft.MeterReadingStatus >=2 or ft.OdometerReadingStatus >= 2) 
UNION ALL
SELECT      CONCAT(p.FirstName + ' ' + p.LastName, v.name) as 'Fueler', CONVERT(VARCHAR(10),ft.TransferDate,101) as 'Date', fcS.code as 'From', fcD.Code as 'To', ft. Quantity, 
			ft.MeterReading, ft.MeterReadingDate, ft. OdometerReading, ft.OdometerReadingDate, 'Overfuel' as 'Problem Description'
FROM        
			FluidTransfer AS ft left outer join
			FluidContainer as fcS on ft.SourceContainerID = fcS.ID left outer Join
			FluidContainer as fcD on ft.DestinationContainerID = fcD.ID left outer join
			Equipment As e1 on fcS.EquipmentID = e1.ID left outer join
			Equipment As e2 on fcD.EquipmentID = e2.ID left outer join
			person as p on ft.EmployeeID = p.ID left outer join
			Vendor as v on ft.VendorID = v.ID
where		CAST(ft.TransferDate as date) between DATEADD(day,-30,CAST(getdate() as date)) and CAST(getdate() as date) and 
			ft.Quantity > fcD.Capacity
ORDER BY	CONVERT(VARCHAR(10),ft.TransferDate,101), (p.FirstName + ' ' + p.LastName)