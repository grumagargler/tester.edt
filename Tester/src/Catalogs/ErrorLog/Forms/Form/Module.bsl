// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )

	readApplication ();
	setScreenshot ();
	ErrorLogForm.UpdateStack ( Object.Ref, Stack );
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readApplication ()
	
	ScenarioApplication = DF.Pick ( Object.Scenario, "Application" );
	
EndProcedure

&AtServer
Procedure setScreenshot ()
	
	if ( Object.ScreenshotExists ) then
		Screenshot = GetURL ( Object.Ref, "Screenshot" );
	else
		Screenshot = "";
	endif; 

EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure ShowInList ( Command )
	
	openList ();
	Close ();
	
EndProcedure

&AtClient
Procedure openList ()
	
	ref = Object.Ref;
	form = GetForm ( "Catalog.ErrorLog.ListForm", new Structure ( "CurrentRow", ref ) );
	table = form.Items.List;
	table.CurrentRow = ref;
	form.Open ();
	if ( table.CurrentRow = undefined ) then
		Output.ErrorNotLocated ();
	endif;
	
EndProcedure

// *****************************************
// *********** Table Stack

&AtClient
Procedure StackSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	ErrorLogForm.OpenScenario ( Item );
	Close ();
	
EndProcedure

// *****************************************
// *********** Screenshot Field

&AtClient
Procedure ScreenshotClick ( Item, StandardProcessing )
	
	StandardProcessing = false;
	showPicture ();
	
EndProcedure

&AtClient
Procedure showPicture ()
	
	if ( Screenshot = "" ) then
		return;
	endif; 
	p = new Structure ();
	p.Insert ( "Title", Object.Ref );
	p.Insert ( "URL", Screenshot );
	OpenForm ( "CommonForm.Screenshot", p );
	
EndProcedure 
