// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	ScenarioForm.InitPort ( Items.Port );
	setTitle ();
	setDefaults ();
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure setTitle ()
	
	Title = Output.RecordSenario ();
	
EndProcedure 

&AtServer
Procedure setDefaults ()
	
	Mode = Enums.Recording.Tester;
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	init ();
	fixLang ();
	start ( true );
	
EndProcedure

&AtClient
Procedure init ()
	
	if ( Test.AttachApplication ( SessionScenario ) ) then
		Port = AppData.Port;
	endif;
	flagConnected ();
	
EndProcedure

&AtClient
Procedure flagConnected ()
	
	Connected = AppData.Connected;
	Appearance.Apply ( ThisObject, "Connected" );
	
EndProcedure

&AtClient
Procedure fixLang ()
	
	if ( Items.Lang.ChoiceList.FindByValue ( Lang ) = undefined ) then
		Lang = CurrentLanguage ();
	endif; 
	
EndProcedure 

&AtClient
Procedure start ( Silently )
	
	if ( attach ( Silently ) ) then
		App.StartUILogRecording ();
		setStatus ( "R" );
	endif;
	
EndProcedure 

&AtClient
Function attach ( Silently )
	
	if ( Silently ) then
		try
			Test.Attach ( Port );
			attached = true;
		except
			attached = false;
		endtry;
	else
		Test.Attach ( Port );
		attached = true;
	endif;
	flagConnected ();
	return attached;
	
EndFunction

&AtClient
Procedure setStatus ( Value )
	
	Status = Value;
	if ( Status = "R" ) then
		Title = Output.RecordingSenario ();
	elsif ( Status = "P" ) then
		Title = Output.PauseScenario ();
	else
		Title = Output.RecordSenario ();
	endif; 
	Appearance.Apply ( ThisObject, "Status" );
	
EndProcedure 

&AtClient
Procedure OnClose ( Exit )
	
	detach ();
	
EndProcedure

&AtClient
Procedure detach ()
	
	if ( Connected ) then
		if ( Status <> "" ) then
			App.CancelUILogRecording ();
		endif;
		Disconnect ();
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure StartRecording ( Command )
	
	start ( false );
	
EndProcedure

&AtClient
Procedure PauseRecording ( Command )
	
	App.PauseUILogRecording ();
	setStatus ( "P" );
	
EndProcedure

&AtClient
Procedure StopRecording ( Command )
	
	setStatus ( "" );
	Close ( getLog () );
	
EndProcedure

&AtClient
Function getLog ()
	
	log = App.FinishUILogRecording ();
	return new Structure ( "Log, Lang, Mode", log, Lang, Mode );
	
EndFunction 

&AtClient
Procedure ResumeRecording ( Command )
	
	App.ResumeUILogRecording ();
	setStatus ( "R" );
	
EndProcedure

&AtClient
Procedure ModeClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure

&AtClient
Procedure DisconnectClient ( Command )
	
	App.CancelUILogRecording ();
	Disconnect ();
	flagConnected ();
	setStatus ( "" );
	
EndProcedure
