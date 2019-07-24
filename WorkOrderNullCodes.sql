SELECT wr.WorkRequestID, IIF(wr.WorkRequest_StatusID = 8, 'PM', IIF(wr.WorkRequest_StatusID = 1, 'Open', IIF(wr.WorkRequest_StatusID = 2, 'Closed', null))) as 'Status'  , wrd.WorkRequest_ItemCodeID, wric.Code as ItemCode, wrwc.Code as WorkCode, wrd.IsDeleted
FROM WorkRequest as wr left outer join 
	 WorkRequest_Detail as wrd on wr.WorkRequestID = wrd.WorkRequestID left outer join
     WorkRequest_ItemCode as wric on wrd.WorkRequest_ItemCodeID = wric.WorkRequest_ItemCodeID left outer join
	 WorkRequest_WorkCode as wrwc on wrd.WorkRequest_WorkCodeID = wrwc.WorkRequest_WorkCodeID
WHERE wrd.WorkRequest_ItemCodeID is null 
ORDER BY WorkRequestID