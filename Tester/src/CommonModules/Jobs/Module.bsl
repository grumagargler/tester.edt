Function GetScheduled ( Key ) export
	
	result = ScheduledJobs.GetScheduledJobs ( new Structure ( "Key", Key ) );
	return ? ( result.Count () = 0, undefined, result [ 0 ] );
	
EndFunction 

Procedure Remove ( Ref ) export
	
	job = Jobs.GetScheduled ( Ref );
	if ( job <> undefined ) then
		job.Delete ();
	endif; 
	
EndProcedure 

Function GetBackground ( Key ) export
	
	result = BackgroundJobs.GetBackgroundJobs ( new Structure ( "Key, State", Key, BackgroundJobState.Active ) );
	return ? ( result.Count () = 0, undefined, result [ 0 ] );
	
EndFunction 
