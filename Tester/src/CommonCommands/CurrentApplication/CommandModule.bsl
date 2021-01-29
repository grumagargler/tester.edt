
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	OpenForm ( "Catalog.Applications.ChoiceForm", , , , , , new NotifyDescription ( "ApplicationSelection", ThisObject ) );

EndProcedure

&AtClient
Procedure ApplicationSelection ( Application, Params ) export
	
	if ( Application = undefined ) then
		return;
	endif; 
	Environment.ChangeApplication ( Application );
	
EndProcedure 
