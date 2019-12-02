var IsNew;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkAgent () ) then
		Cancel = true;
		return;
	endif;
	
EndProcedure

Function checkAgent ()
	
	if ( Agent.IsEmpty () ) then
		return true;
	endif;
	s = "
	|select top 1 1
	|from Catalog.Users.Managers as Managers
	|where Managers.Ref = &Agent
	|and Managers.Ref.Agent
	|and Managers.User = &Creator
	|and not Managers.Ref.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Agent", Agent );
	q.SetParameter ( "Creator", Creator );
	error = q.Execute ().IsEmpty ();
	if ( error ) then
		Output.AgentAccessDenied ( new Structure ( "Creator", Creator ), "Agent" );
	endif;
	return not error;
	
EndFunction

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	IsNew = IsNew ();
	SetPrivilegedMode ( true );
	if ( DeletionMark ) then
		remove ();
		return;
	endif;
	if ( IsNew ) then
		defaultScenario ();
	endif;
	adjustSchedule ();
	
EndProcedure

Procedure remove ()
	
	r = InformationRegisters.Jobs.CreateRecordManager ();
	r.Job = Ref;
	r.Delete ();
	r = InformationRegisters.AgentJobs.CreateRecordManager ();
	r.Job = Ref;
	r.Read ();
	r.Job = Ref;
	r.Status = Enums.JobStatuses.Removed;
	r.Write ();
	if ( Mode = Enums.Running.Schedule ) then
		Jobs.Remove ( Ref );
	endif;

EndProcedure

Procedure defaultScenario ()
	
	table = Scenarios;
	if ( table.Count () = 0 ) then
		Scenario = undefined;
	else
		Scenario = table [ 0 ].Scenario;
	endif;

EndProcedure

Procedure adjustSchedule ()
	
	if ( Mode = Enums.Running.Now ) then
		Schedule = undefined;
	endif;
	
EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( DeletionMark ) then
		return;
	endif;
	if ( Mode = Enums.Running.Now ) then
		if ( IsNew ) then
			TesterAgent.Create ( Ref, Agent, Date, Computer );
		endif;
	else
		initJob ();
	endif;
	
EndProcedure

Procedure initJob ()
	
	var task;
	
	if ( not IsNew ) then
		task = Jobs.GetScheduled ( Ref );
	endif;
	if ( task = undefined ) then
		task = ScheduledJobs.CreateScheduledJob ( Metadata.ScheduledJobs.Testing );
	endif;
	task.Use = true;
	task.UserName = UserName ();
	task.Key = Ref;
	p = new Array ();
	p.Add ( Ref );
	task.Parameters = p;
	task.Schedule = Conversion.JSONToObject ( Schedule, Type ( "JobSchedule" ) );
	task.Write ();
	
EndProcedure 
