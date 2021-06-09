
Procedure SetApplication ( Application ) export
	
	SessionApplication = Application;
	Environment.DisplayCaption ();
	
EndProcedure 

Procedure DisplayCaption () export
	
	parts = new Array ();
	parts.Add ( Output.MetadataPresentation () );
	if ( not SessionApplication.IsEmpty () ) then
		parts.Add ( EnvironmentSrv.GetApplication () );
	endif; 
	parts.Add ( SessionUser );
	ClientApplication.SetCaption ( StrConcat ( parts, "." ) );
	
EndProcedure 

Procedure ChangeApplication ( Application ) export
	
	reference = EnvironmentSrv.SetApplication ( Application );
	SessionApplication = reference;
	Environment.DisplayCaption ();
	if ( AppData <> undefined
		and AppData.Application <> reference ) then
		if ( AppData.Connected ) then
			Test.DisconnectClient ( false );
		endif;
		updateAppData ( reference );
		Runtime.UpdateConstants ();
		Runtime.InitEnv ();
	endif;
	
EndProcedure 

Procedure updateAppData ( Application )
	
	FillPropertyValues ( AppData, DF.Values ( Application, "Computer, Port, ClientID" ) );
	AppData.Application = Application;
	AppData.Connected = false;

EndProcedure

Procedure ChangeScenario ( Scenario ) export
	
	var newApp;
	SessionScenario = Scenario;
	EnvironmentSrv.ChangeScenario ( Scenario, newApp );
	if ( newApp <> undefined
		and newApp <> SessionApplication ) then
		SessionApplication = newApp;
		Environment.DisplayCaption ();
	endif; 
	Notify ( Enum.MessageMainScenarioChanged () );
	NotifyChanged ( Scenario );
	
EndProcedure 

Function FindByID ( ID ) export
	
	return EnvironmentSrv.FindByID ( ID, AppData.Application );
	
EndFunction 

Procedure Register ( ID ) export
	
	EnvironmentSrv.Register ( ID, AppData.Application );
	
EndProcedure 

Procedure ApplyVersion ( Version ) export
	
	pinVersion ( Version, false );
	
EndProcedure

Procedure pinVersion ( Version, Running )
	
	EnvironmentSrv.SetVersion ( Version, Running );
	NotifyChanged ( Version );
	
EndProcedure

Procedure SetApplicationVersion ( Version, Application ) export
	
	ref = TestSrv.GetVersion ( Version, ? ( Application = undefined, AppName, Application ) );
	pinVersion ( ref, true );
	
EndProcedure

Function GetVariable ( Name ) export
	
	return ExternalLibrary.GetEnv ( Name );
	
EndFunction 
