SELECT *
FROM

(SELECT e.AccountingCode as 'Vehicle', CAST(CONCAT(e.year + ' ', e.make + ' ', e.model + ' ', e.description + ' ') as varchar(120)) as 'Vehicle Description' ,CAST(MAX(ft.TransferDate) as Date) as 'Date', l.Name as 'Location/Job', j.Description
 FROM Equipment as e inner join
	  Equipment_MeterHistory as emh on e.EquipmentID = emh.Equipment_EquipmentID left outer join 
      FluidContainer as fc ON e.ID = fc.EquipmentID inner join
	  FluidTransfer as ft on fc.ID = ft.DestinationContainerID inner join
	  Location as l ON ft.LocationID = l.ID left outer join
	  Job as j ON l.Name = j.Code
	  WHERE CAST(ft.TransferDate as date) <= '12/31/2018' and e.AccountingCode between '1400' and '9552' and l.name in('1630','1725','1732','1733','1734','1735','1738','1739','1740','1745','1746','1748','1755','1758','1760','1761','1762','1765','1766','1775','1779','1783','1786','1790','1791','1792','1793','1794','1795','1796','1802','1803','1804','1805','1820','1823','1824','1825')
	  Group By e.AccountingCode, CONCAT(e.year + ' ', e.make + ' ', e.model + ' ', e.description + ' '), l.name, j.Description
	  ) as core
	  Order By Core.Vehicle, core.Date