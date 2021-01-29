&AtServer
var ActualScenarios;
&AtServer
var LastVersions;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	LockingForm.LoadScenarios ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	if ( nothing () ) then
		Close ();
	else
		Output.UnlockConfirmation ( ThisObject );
	endif; 
	
EndProcedure

&AtClient
Function nothing ()
	
	for each row in List do
		if ( row.Use ) then
			return false;
		endif; 
	enddo; 
	return false;
	
EndFunction 

&AtClient
Procedure UnlockConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	restored = unlock ();
	broadcast ( restored );
	Close ();
	
EndProcedure 

&AtServer
Function unlock ()
	
	table = LockingForm.FetchScenarios ( ThisObject );
	BeginTransaction ();
	LockingForm.LockEditing ( table );
	userScenarios ( table );
	restored = rollbackScenarios ();
	unlockScenarios ();
	CommitTransaction ();
	return restored;
	
EndFunction

&AtServer
Procedure userScenarios ( Table )
	
	s = "
	|select Editing.Scenario as Scenario
	|into UserScenarios
	|from InformationRegister.Editing as Editing
	|where Editing.Scenario in ( &Scenarios )
	|and Editing.User = &User
	|index by Scenario
	|;
	|// Actual scenarios
	|select UserScenarios.Scenario as Scenario
	|from UserScenarios as UserScenarios
	|;
	|// Last versions
	|select Versions.Scenario as Scenario, Versions.Version as Version
	|from InformationRegister.Versions.SliceLast ( , Scenario in ( select Scenario from UserScenarios ) ) as Versions
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Scenarios", Table.UnloadColumn ( "Ref" ) );
	data = q.ExecuteBatch ();
	ActualScenarios  = data [ 1 ].Unload ().UnloadColumn ( "Scenario" );
	LastVersions  = data [ 2 ].Unload ();

EndProcedure 

&AtServer
Function rollbackScenarios ()
	
	restored = new Array ();
	for each row in LastVersions do
		scenario = row.Scenario;
		Catalogs.Scenarios.Rollback ( scenario, row.Version );
		restored.Add ( scenario );
	enddo; 
	return restored;

EndFunction

&AtServer
Procedure unlockScenarios ()
	
	for each scenario in ActualScenarios do
		r = InformationRegisters.Editing.CreateRecordManager ();
		r.Scenario = scenario;
		r.Delete ();
	enddo; 
	
EndProcedure

&AtClient
Procedure broadcast ( Scenarios )
	
	Notify ( Enum.MessageReload (), Scenarios );
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
