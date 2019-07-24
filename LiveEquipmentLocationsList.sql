SELECT e.AccountingCode as 'Equipment', (e.Year) as 'Year Model', (e.Make) as 'Manufacturer', (e.Model) as 'Model', CAST(e.Description as VARCHAR(80)) as 'Equipment Description', (j.Code) as 'Job', (j.Description) as 'Job Description', (l.Name) as 'Location Description'
FROM Equipment as e LEFT OUTER JOIN 
Equipment_License as el ON CAST(el.Equipment_EquipmentID as int) = CAST(e.EquipmentID as int) left outer join
Location as l ON l.LegacyKey = e.Equipment_LocationID LEFT OUTER JOIN
Job as j  ON J.LegacyKey = e.Equipment_JobID
WHERE (el.Equipment_EquipmentID is null) and e.IsDeleted = 0 AND e.RentalFlag = 0
Group BY e.AccountingCode, e.Year, e.Make, e.Model, CAST(e.Description as VARCHAR(80)) , j.Code, j.Description, l.Name
Order By e.AccountingCode