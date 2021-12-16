--This query was used to identify all LP's attached to faulty/virtual loads that were stuck inside of a warehouse door as well as active virtual loads in any Wayfair FC globally. 
--This was benefitial to ops and WITS as we now had a tool that could see the current state of the issue in realtime. 
--Providing visibility as to the employee involved and the LP's and doors effected, this mitigated time waste by solving the issue much more quickly and providing training to avoid
--this functionality error within nexus

SELECT a.load_master_id, a2.tran_log_id, a2.employee_id, a.load_id as [load_id], a.hu_id, a.alt_hu_id, MAX(a2.date) as [Date], a.door_loc, a.shipment_status, a.shipment_status_date, a.wh_id, a.execution_status
FROM
(
(
SELECT tlm.load_id, tlm.door_loc, thm.hu_id, thm.alt_hu_id, tlm.shipment_status, tlm.shipment_status_date, tlm.wh_id, tlm.execution_status, tlm.load_master_id
FROM t_load_master as tlm WITH(NOLOCK) 
left outer join t_hu_master as thm on tlm.load_id = thm.load_id
WHERE tlm.load_id like '%DOOR%' /*and door_loc is not null and door_loc not in  ('CLOSED')*/ /*and ttl.description = 'Loading (put)'*/ and tlm.wh_id = '25' and tlm.load_id like('%DOOR380')
) as a left outer join

(
SELECT tran_log_id, hu_id, tl.location_id_2, employee_id, MAX(end_tran_date) as [date] FROM t_tran_log as tl 
left join (SELECT location_id FROM t_location as tl WHERE description = 'DOOR' and type = 'D') as l ON l.location_id = tl.location_id_2
WHERE /*tl.end_tran_date > '2017-01-01 00:00:00.000' and*/ tl.tran_type = '322'
Group By end_tran_date, tran_log_id, hu_id, tl.location_id_2, employee_id, end_tran_date
) as a2 on a.hu_id = a2.hu_id)
WHERE wh_id = '25'
Group by a.load_master_id, a2.employee_id, a.load_id, a.hu_id, a.alt_hu_id, a.door_loc, a.shipment_status, a.shipment_status_date, a.wh_id, a.execution_status, a2.tran_log_id
order by a2.tran_log_id, a2.employee_id desc,  a.hu_id desc