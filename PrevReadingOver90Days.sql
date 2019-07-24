Select A.Vehicle, A.[Description], CONCAT(A.[Odometer], A.[Meter]) as [Reading] ,A.[Last Reading Date]
From
(Select e.AccountingCode as [Vehicle], CONCAT(e.Description + ' ', e.make + ' ', e.model + ' ', e.year + ' ') as [Description], IIF(MAX(e.Current_OdometerTrueMiles) = 0 , null, MAX(e.Current_OdometerTrueMiles)) as [Odometer], IIF(MAX(e.Current_MeterTrueHours)=0, null, MAX(e.Current_MeterTrueHours)) as [Meter] , CONCAT(CAST(MAX(e.Current_OdometerReadingDate) as smalldatetime) , CAST(MAX(e.Current_MeterReadingDate) as smalldatetime)) as [Last Reading Date], e.IsDeleted
from equipment as e INNER JOIN
FluidContainer as fc ON e.ID = fc.EquipmentID
WHERE fc.IsBurnTank = 1 and e.Current_MeterTrueHours > 0 OR e.Current_OdometerTrueMiles > 0 and fc.IsDeleted = 0
Group By e.AccountingCode, CONCAT(e.Description + ' ', e.make + ' ', e.model + ' ', e.year + ' '), e.IsDeleted) as A

Where A.[Last Reading Date] <= DATEADD(mm,-3,getdate()) and a.IsDeleted = 0
Order By A.[Vehicle]