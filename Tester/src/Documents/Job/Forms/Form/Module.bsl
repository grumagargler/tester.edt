&AtClient
var TableRow;
&AtClient
var ConfirmationTaken;
&AtClient
var LockedScenarios;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	setAgentStatus ( ThisObject );
	readSchedule ();
	readInfo ();
	readErrors ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClientAtServerNoContext
Procedure setAgentStatus ( Form )
	
	object = Form.Object;
	Form.AgentStatus = getStatus ( object.Agent, object.Computer );
	Appearance.Apply ( Form );
	
EndProcedure

&AtServerNoContext
Function getStatus ( val Agent, val Computer )
	
	s = "
	|select top 1 AgentStatuses.Status as Status
	|from InformationRegister.AgentStatuses as AgentStatuses
	|where AgentStatuses.Session in (
	|	select top 1 Sessions.Ref as Ref
	|	from Catalog.Sessions as Sessions
	|	where not Sessions.DeletionMark
	|	and Sessions.User = &Agent
	|	and Sessions.Computer = &Computer
	|)
	|";
	q = new Query ( s );
	q.SetParameter ( "Agent", Agent );
	q.SetParameter ( "Computer", Computer );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Status );
	
EndFunction 

&AtServer
Procedure readSchedule ()
	
	if ( Object.Mode = Enums.Running.Schedule ) then
		Schedule = Conversion.JSONToObject ( Object.Schedule, Type ( "JobSchedule" ) );
	endif;
	
EndProcedure

&AtServer
Procedure readInfo ()
	
	r = InformationRegisters.AgentJobs.CreateRecordManager ();
	r.Job = Object.Ref;
	r.Read ();
	ValueToFormAttribute ( r, "JobInfo" );
	DC.SetParameter ( JobsLog, "Ref", Object.Ref );
	
EndProcedure

&AtServer
Procedure readErrors ()
	
	s = "
	|select count ( Log.Status ) as Count
	|from InformationRegister.Log as Log
	|where Log.Job = &Ref
	|and Log.Level = 0
	|and Log.Status = value ( Enum.Statuses.Fault )
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	ErrorsCount = q.Execute ().Unload ().Total ( "Count" );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		loadParams ();
		initNew ();
	else
		WindowOpeningMode = FormWindowOpeningMode.Independent;
	endif;
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	if ( Parameters.Scenarios = undefined ) then
		return;
	endif;
	list = getScenarios ();
	Object.Scenarios.Load ( list );
	
EndProcedure

&AtServer
Function getScenarios ()
	
	s = "
	|select allowed Scenarios.Ref as Scenario,
	|	case when Scenarios.Application = value ( Catalog.Applications.EmptyRef ) then &Application else Scenarios.Application end as Application
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Ref in hierarchy ( &Scenarios )
	|and not Scenarios.DeletionMark
	|and Scenarios.Type = value ( Enum.Scenarios.Scenario )
	|order by Scenarios.Path
	|";
	q = new Query ( s );
	q.SetParameter ( "Scenarios", Parameters.Scenarios );
	q.SetParameter ( "Application", EnvironmentSrv.GetApplication () );
	return q.Execute ().Unload ();
	
EndFunction

&AtServer
Procedure initNew ()
	
	if ( Object.Schedule = "" ) then
		initSchedule ();
	else
		readSchedule ();
	endif;
	if ( not Object.Agent.IsEmpty () ) then
		setAgentStatus ( ThisObject );
	endif;
	
EndProcedure

&AtServer
Procedure initSchedule ()
	
	Schedule = new JobSchedule ();
	Schedule.BeginDate = BegOfDay ( CurrentSessionDate () + 86400 );
	Schedule.DaysRepeatPeriod = 1;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer ( Settings )
	
	if ( not Object.Agent.IsEmpty ()
		or not Object.Ref.IsEmpty () ) then
		Settings.Clear ();
	endif;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer ( Settings )
	
	if ( not Object.Agent.IsEmpty () ) then
		setAgentStatus ( ThisObject );
	endif;
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	if ( not CheckFilling () ) then
		Cancel = true;
		return;
	endif;
	if ( confirmationRequired () ) then
		Cancel = true;
		askUser ();
	endif;
	storeSchedule ();
	
EndProcedure

&AtClient
Function confirmationRequired ()
	
	if ( ConfirmationTaken
		or not Object.Ref.IsEmpty () ) then
		return false;
	endif;
	LockedScenarios = editingScenarios ();
	return LockedScenarios.Count () > 0;
	
EndFunction

&AtServer
Function editingScenarios ()
	
	s = "
	|select allowed distinct Editing.Scenario as Scenario
	|from InformationRegister.Editing as Editing
	|	//
	|	// Actual Versions
	|	//
	|	left join Catalog.Versions as Versions
	|	on Versions.Scenario = Editing.Scenario
	|	and Versions.Changed = Editing.Scenario.Changed
	|where Editing.Scenario in ( &Scenarios )
	|and Editing.User <> &Agent
	|and Editing.User = &Me
	|and Versions.Code is null
	|order by Editing.Scenario.Path
	|";
	q = new Query ( s );
	q.SetParameter ( "Scenarios", Object.Scenarios.Unload ( , "Scenario" ).UnloadColumn ( "Scenario" ) );
	q.SetParameter ( "Agent", Object.Agent );
	q.SetParameter ( "Me", SessionParameters.User );
	return q.Execute ().Unload ().UnloadColumn ( "Scenario" );
	
EndFunction

&AtClient
Procedure askUser ()
	
	p = new Structure ( "Scenarios, JobPreparing", LockedScenarios, true );
	callback = new NotifyDescription ( "StoreFormClosed", ThisObject );
	OpenForm ( "Catalog.Scenarios.Form.Store", p, ThisObject, true, , , callback );
	
EndProcedure

&AtClient
Procedure StoreFormClosed ( Result, Params ) export
	
	ConfirmationTaken = true;
	Write ();
	Close ();
	
EndProcedure

&AtClient
Procedure storeSchedule ()
	
	if ( Object.Mode = PredefinedValue ( "Enum.Running.Schedule" ) ) then
		Object.Schedule = Conversion.ObjectToJSON ( Schedule );
	endif;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure ModeOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.Mode" );

EndProcedure

&AtClient
Procedure ScheduleClick ( Item, StandardProcessing )
	
	StandardProcessing = false;
	showSchedule ();
	
EndProcedure

&AtClient
Procedure showSchedule ()
	
	#if ( not MobileClient ) then
		dialog = new ScheduledJobDialog ( Schedule );
		dialog.Show ( new NotifyDescription ( "ScheduleDefined", ThisObject ) );
	#endif
	
EndProcedure

&AtClient
Procedure ScheduleDefined ( Data, Params ) export
	
	if ( Data = undefined ) then
		return;
	endif;
	Schedule = Data;
	
EndProcedure

&AtClient
Procedure Delete ( Command )

	Output.DeleteJob ( ThisObject );
	
EndProcedure

&AtClient
Procedure DeleteJob ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	Object.DeletionMark = true;
	Write ();
	Close ();
	
EndProcedure

&AtClient
Procedure AgentChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	if ( TypeOf ( SelectedValue ) = Type ( "Structure" ) ) then
		StandardProcessing = false;
		applyAgent ( SelectedValue );
	endif;
	
EndProcedure

&AtClient
Procedure applyAgent ( Data )
	
	Object.Agent = Data.Agent;
	Object.Computer = Data.Computer;
	setAgentStatus ( ThisObject );
	
EndProcedure

&AtClient
Procedure AgentOnChange ( Item )
	
	setAgentStatus ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Scenarios

&AtClient
Procedure ScenariosOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ScenariosScenarioOnChange ( Item )
	
	setApplication ();
	
EndProcedure

&AtClient
Procedure setApplication ()
	
	value = DF.Pick ( TableRow.Scenario, "Application" );
	if ( value.IsEmpty () ) then
		value = EnvironmentSrv.GetApplication ();
	endif;
	TableRow.Application = value;
	
EndProcedure

// *****************************************
// *********** Jobs

&AtClient
Procedure JobsLogOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure JobsLogSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( Field.Name = "JobsLogScenario" ) then
		showMenu ();
	endif;
	
EndProcedure

&AtClient
Procedure showMenu ()
	
	menu = new ValueList ();
	status = TableRow.Status;
	if ( status = PredefinedValue ( "Enum.Statuses.Fault" ) ) then
		menu.Add ( 1, Output.OpenErrorsLog (), , PictureLib.Warning );
		menu.Add ( 2, Output.OpenError () + TableRow.Error );
	endif;
	menu.Add ( 3, Output.OpenLog (), , PictureLib.EventLog );
	menu.Add ( 4, Output.OpenScenario (), , PictureLib.Change );
	ShowChooseFromMenu ( new NotifyDescription ( "ActionSelected", ThisObject ), menu );

EndProcedure

&AtClient
Procedure ActionSelected ( Menu, Params ) export
	
	if ( Menu = undefined ) then
		return;
	endif;
	value = Menu.Value;
	if ( value = 1 ) then
		openLog ( true );
	elsif ( value = 2 ) then
		ShowValue ( , TableRow.Error );
	elsif ( value = 3 ) then
		openLog ();
	elsif ( value = 4 ) then
		ShowValue ( , findScenario ( Object.Ref, jobScenario (), TableRow.LineNumber ) );
	endif;
	
EndProcedure

&AtClient
Function jobScenario ()
	
	return Object.Scenarios [ TableRow.LineNumber - 1 ].Scenario;
	
EndFunction

&AtClient
Procedure openLog ( OnlyErrors = false )
	
	job = Object.Ref;
	scenario = findScenario ( job, jobScenario (), TableRow.LineNumber );
	if ( scenario = undefined ) then
		return;
	endif;
	params = new Structure ( "Scenario, Job", scenario, job );
	if ( OnlyErrors ) then
		OpenForm ( "Catalog.ErrorLog.ListForm", params );
	else
		OpenForm ( "InformationRegister.Log.ListForm", params );
	endif;
	
EndProcedure

&AtServerNoContext
Function findScenario ( val Job, val Scenario, val Row )
	
	s = "
	|select top 1 Log.Scenario as Scenario
	|from InformationRegister.Log as Log
	|where Log.Job = &Job
	|and Log.Row = &Row
	|and Log.Level = 0
	|and &Scenario in ( Log.Scenario.Scenario, Log.Scenario )
	|";
	q = new Query ( s );
	q.SetParameter ( "Job", Job );
	q.SetParameter ( "Row", Row );
	q.SetParameter ( "Scenario", Scenario );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Scenario );
	
EndFunction

// *****************************************
// *********** Variables Initialization

ConfirmationTaken = false;
