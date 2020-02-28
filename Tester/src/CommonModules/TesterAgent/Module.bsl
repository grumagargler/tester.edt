
Function GetWork () export
	
	if ( Jobs.GetBackground ( "Exchange" ) <> undefined ) then
		return undefined;
	endif;
	job = findJob ();
	if ( job = undefined ) then
		return undefined;
	else
		return new Structure ( "Job, Parameters, Scenarios", job.Job, job.Parameters, getScenarios ( job ) );
	endif;
	
EndFunction

Function findJob ()
	
	s = "
	|select top 1 Jobs.Job as Job, Jobs.Job.Parameters as Parameters
	|from InformationRegister.Jobs as Jobs
	|where Jobs.Agent = &Agent
	|and Jobs.Computer in ( value ( Catalog.Computers.EmptyRef ), &Computer )
	|order by Jobs.Created
	|";
	q = new Query ( s );
	q.SetParameter ( "Agent", SessionParameters.User );
	q.SetParameter ( "Computer", SessionData.Computer () );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );
	
EndFunction

Function getScenarios ( Job )
	
	s = "
	|select Scenarios.Scenario as Scenario, Scenarios.Application as Application,
	|	Scenarios.LineNumber as LineNumber
	|from Document.Job.Scenarios as Scenarios
	|where Scenarios.Ref = &Job
	|order by Scenarios.LineNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Job", Job.Job );
	return Collections.Serialize ( q.Execute ().Unload () );
	
EndFunction

Procedure Start ( val Job ) export
	
	TesterAgent.AgentStatus ( Enums.AgentStatuses.Busy );
	SetPrivilegedMode ( true );
	r = InformationRegisters.Jobs.CreateRecordManager ();
	r.Job = Job;
	r.Delete ();
	r = InformationRegisters.AgentJobs.CreateRecordManager ();
	r.Job = Job;
	r.Started = CurrentSessionDate ();
	r.Start = CurrentUniversalDateInMilliseconds ();
	r.Session = SessionParameters.Session;
	r.Status = Enums.JobStatuses.Running;
	r.Write ();
	
EndProcedure

Procedure AgentStatus ( val Status ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.AgentStatuses.CreateRecordManager ();
	session = SessionParameters.Session;
	r.Session = session;
	r.Read ();
	if ( r.Status = Status ) then
		return;
	endif;
	r.Session = session;
	r.Status = Status;
	ExchangeKillers.Write ( r );
	
EndProcedure

Procedure Finish ( val Job ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.AgentJobs.CreateRecordManager ();
	r.Job = Job;
	r.Read ();
	r.Finished = CurrentSessionDate ();
	finish = CurrentUniversalDateInMilliseconds ();
	r.Finish = finish;
	r.Duration = finish - r.Start;
	r.Status = ? ( hasErrors ( Job ), Enums.JobStatuses.Fault, Enums.JobStatuses.Passed );
	r.Write ();
	TesterAgent.AgentStatus ( Enums.AgentStatuses.Available );
	
EndProcedure

Function hasErrors ( Job )
	
	s = "
	|select top 1 1
	|from Catalog.ErrorLog as Log
	|where Log.Job = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Job );
	return not q.Execute ().IsEmpty ();
	
EndFunction

Procedure StartScenario ( val Job, val Row ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.AgentScenarios.CreateRecordManager ();
	r.Job = Job;
	r.Row = Row;
	r.Started = CurrentSessionDate ();
	r.Write ();
	
EndProcedure

Procedure FinishScenario ( val Job, val Row ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.AgentScenarios.CreateRecordManager ();
	r.Job = Job;
	r.Row = Row;
	r.Read ();
	r.Finished = CurrentSessionDate ();
	r.Write ();
	
EndProcedure

Procedure Create ( Job, Agent, Date, Computer ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.AgentJobs.CreateRecordManager ();
	r.Job = Job;
	r.Status = Enums.JobStatuses.Pending;
	r.Write ();
	r = InformationRegisters.Jobs.CreateRecordManager ();
	r.Job = Job;
	r.Agent = Agent;
	r.Created = Date;
	r.Computer = Computer;
	r.Write ();
	
EndProcedure

Procedure Testing ( Job ) export
	
	BeginTransaction ();
	lockJob ( Job );
	skip = not DF.Pick ( Job, "IgnoreCompletion" )
	and jobActive ( Job );
	if ( skip ) then
		RollbackTransaction ();
		return;
	endif;
	obj = Job.GetObject ().Copy ();
	obj.Date = CurrentSessionDate ();
	obj.Mode = Enums.Running.Now;
	obj.Job = Job;
	obj.Memo = "";
	obj.Write ();
	TesterAgent.Create ( obj.Ref, obj.Agent, obj.Date, obj.Computer );
	CommitTransaction ();
	
EndProcedure

Procedure lockJob ( Job )
	
	lock = new DataLock ();
	item = lock.Add ( "Document.Job" );
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "Ref", Job );
	lock.Lock ();
	
EndProcedure

Function jobActive ( Job )
	
	s = "
	|select top 1 1
	|from Document.Job as Jobs
	|	//
	|	// AgentJobs
	|	//
	|	join InformationRegister.AgentJobs as AgentJobs
	|	on AgentJobs.Job = Jobs.Ref
	|	and AgentJobs.Status in ( value ( Enum.JobStatuses.Pending ), value ( Enum.JobStatuses.Running ) )
	|where Jobs.Job = &Job
	|and not Jobs.DeletionMark
	|order by Jobs.Date desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Job", Job );
	return not q.Execute ().IsEmpty ();
	
EndFunction

Function Canceled ( val Job ) export
	
	s = "
	|select top 1 1
	|from InformationRegister.AgentJobs as AgentJobs
	|where AgentJobs.Job = &Job
	|and AgentJobs.Status = value ( Enum.JobStatuses.Removed )
	|";
	q = new Query ( s );
	q.SetParameter ( "Job", Job );
	return not q.Execute ().IsEmpty ();
	
EndFunction

Procedure CreateJob ( val Agent, val Scenario, val Application, val Parameters, val Computer, val Memo ) export
	
	obj = Documents.Job.CreateDocument ();
	obj.Date = CurrentSessionDate ();
	obj.Agent = findAgent ( Agent );
	if ( Computer <> undefined ) then
		obj.Computer = findComputer ( Computer );
	endif;
	obj.Creator = SessionParameters.User;
	obj.Parameters = Conversion.ToJSON ( Parameters, false );
	obj.Memo = Memo;
	obj.Mode = Enums.Running.Now;
	row = obj.Scenarios.Add ();
	row.Scenario = findScenario ( Scenario, Application );
	row.Application = EnvironmentSrv.FindApplication ( Application );
	obj.Write ();
	
EndProcedure

Function findAgent ( Agent )
	
	ref = Catalogs.Users.FindByDescription ( Agent );
	if ( ref.IsEmpty () ) then
		raise Output.AgentNotFound ( new Structure ( "Agent", Agent ) );
	endif;
	return ref;
	
EndFunction

Function findComputer ( Computer )
	
	ref = Catalogs.Computers.FindByDescription ( Computer );
	if ( ref.IsEmpty () ) then
		raise Output.ComputerNotFound ( new Structure ( "Computer", Computer ) );
	endif;
	return ref;
	
EndFunction

Function findScenario ( Scenario, Application )
	
	ref = RuntimeSrv.FindScenario ( Scenario, undefined, Application, undefined, true );
	if ( ref = undefined ) then
		raise Output.ScenarioNotFound ( new Structure ( "Name", Scenario ) );
	endif;
	return ref;
	
EndFunction