// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	Title = Parameters.Title;
	Screenshot = Parameters.URL;
	
EndProcedure 