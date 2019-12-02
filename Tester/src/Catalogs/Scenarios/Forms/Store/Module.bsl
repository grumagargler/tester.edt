&AtServer
var Stored;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	LockingForm.LoadScenarios ( ThisObject );
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	JobPreparing = Parameters.JobPreparing;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	AllScenarios = fetchScenarios ();
	Notify ( Enum.MessageSave (), AllScenarios );
	stored = store ();
	broadcast ( stored );
	Close ();
	
EndProcedure

&AtServer
Function fetchScenarios ()
	
	return new FixedArray ( LockingForm.FetchScenarios ( ThisObject ).UnloadColumn ( "Ref" ) );
	
EndFunction 

&AtServer
Function store ()
	
	BeginTransaction ();
	LockingForm.LockEditing ( scenariosTable () );
	userScenarios ();
	if ( not KeepLocked ) then
		unlockScenarios ();
	endif; 
	createVersions ();
	CommitTransaction ();
	return Stored;
	
EndFunction

&AtServer
Function scenariosTable ()
	
	table = new ValueTable ();
	table.Columns.Add ( "Ref", new TypeDescription ( "CatalogRef.Scenarios" ) );
	for each scenario in AllScenarios do
		row = table.Add ();
		row.Ref = scenario;
	enddo; 
	return table;
	
EndFunction 

&AtServer
Procedure userScenarios ()
	
	s = "
	|select Editing.Scenario as Scenario
	|from InformationRegister.Editing as Editing
	|where Editing.Scenario in ( &Scenarios )
	|and Editing.User = &User
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Scenarios", AllScenarios );
	Stored = q.Execute ().Unload ().UnloadColumn ( "Scenario" );

EndProcedure

&AtServer
Procedure unlockScenarios ()
	
	for each scenario in Stored do
		r = InformationRegisters.Editing.CreateRecordManager ();
		r.Scenario = scenario;
		r.Delete ();
	enddo; 
	
EndProcedure

&AtServer
Procedure createVersions ()
	
	for each scenario in Stored do
		Catalogs.Versions.Create ( scenario, Memo );
	enddo; 

EndProcedure 

&AtClient
Procedure broadcast ( Scenarios )
	
	Notify ( Enum.MessageStored (), Scenarios );
	NotifyChanged ( Type ( "CatalogRef.Scenarios" ) );
	
EndProcedure 

// *****************************************
// *********** Table List

&AtClient
Procedure ListBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure
