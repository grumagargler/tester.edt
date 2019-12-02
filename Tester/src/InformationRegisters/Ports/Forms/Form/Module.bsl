// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Record.SourceRecordKey.IsEmpty () ) then
		initNew ();
	endif;
	
EndProcedure

&AtServer
Procedure initNew ()
	
	Record.Session = SessionParameters.Session;
	
EndProcedure