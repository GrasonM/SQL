--Created in collaboration with DBA team to keep track of progress on a change that caused an error with the calculation of volume of a container and the max volume of the trailer load
--Worked within the specifications required to differentiate freight from small parcel and identified points where redimming may have been required as well
--Effectively facilitated the resolution of a global issue within a few hours on the first day that the SEV was dropped

SELECT item_number, length, width, height,
CONCAT(CAST(([length] + width * 2 + height * 2) AS NVARCHAR), + '"') AS [girth],
CASE WHEN ([length] + width * 2 + height * 2) <= 129
THEN 'Under 129", can ship SP'
ELSE 'Over 129", cannot ship SP'
END AS [girth_can_ship_SP],
unit_weight,
CASE WHEN unit_weight >= 150
THEN 'Over 150lbs cannot ship SP'
ELSE 'Under 150lbs can ship SP'
END AS [weight_can_ship_SP],
CASE WHEN freight_class_id = 1 THEN 'Product setup as SP'
ELSE 'Product not setup SP'
END AS is_freight_class_SP
FROM t_item_master WITH(NOLOCK)
WHERE item_number in (SELECT uom.item_number
FROM t_tran_log log
INNER JOIN t_hu_master hum
ON hum.hu_id = log.hu_id
AND hum.wh_id = log.wh_id
INNER JOIN t_item_uom uom
ON uom.item_number = log.item_number
AND uom.wh_id = log.wh_id
WHERE log.tran_type = '341'
AND log.control_number_2 = 'L000574567'
AND log.wh_id = '25')