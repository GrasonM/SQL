SELECT e.AccountingCode As Equip# , e.Year, e.Description, e.Make, e.Model, COALESCE(NULLIF(e.SerialNo,''), e.VIN) As [Serial Number],
e.EngineMake As Engine, cft.StringType AS Transmission, IIF(cfo.StringType = '', cfo1.StringType, cfo.StringType)  AS Operator,
IIf(e.Current_MeterHours=0, e.Current_OdometerTrueMiles,
e.Current_MeterHours) AS [Current Meter],IIf(e.Current_MeterTrueHours=0,e.Current_OdometerTrueMiles,
e.Current_MeterTrueHours) AS [Life Meter]
FROM Equipment360.dbo.Equipment AS e LEFT JOIN 

(SELECT cf.CustomFieldID, cf.EntityID, cf.StringType, cfc.FieldName, cfc.CategoryType, cfc.EntityName
FROM Equipment360.dbo.CustomField AS cf INNER JOIN Equipment360.dbo.CustomField_Category AS cfc ON cf.CustomField_CategoryID = cfc.CustomField_CategoryID
WHERE cfc.FieldName = 'Operator' and cf.IsDeleted = 0)  AS cfo 
ON e.EquipmentID = cfo.EntityID LEFT JOIN 

(SELECT cf.CustomFieldID, cf.EntityID, cf.StringType, cfc.FieldName, cfc.CategoryType, cfc.EntityName
FROM Equipment360.dbo.CustomField AS cf INNER JOIN Equipment360.dbo.CustomField_Category AS cfc ON cf.CustomField_CategoryID = cfc.CustomField_CategoryID
WHERE cfc.FieldName = 'Unassigned Description' and cf.IsDeleted = 0)  AS cfo1
ON e.EquipmentID = cfo1.EntityID LEFT JOIN 

(SELECT cf.CustomFieldID, cf.EntityID, cf.StringType, cfc.FieldName, cfc.CategoryType, cfc.EntityName
FROM Equipment360.dbo.CustomField AS cf INNER JOIN Equipment360.dbo.CustomField_Category AS cfc ON cf.CustomField_CategoryID = cfc.CustomField_CategoryID
WHERE cfc.FieldName = 'Transmission' and cf.IsDeleted = 0)  AS cft 
ON e.EquipmentID = cft.EntityID 
WHERE (((e.AccountingCode)  >= '0900' and (e.AccountingCode) <= '9999' ) AND ((e.IsDeleted)=0))
ORDER BY e.Name