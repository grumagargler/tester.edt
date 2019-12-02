
&AtClient
Procedure CommandProcessing ( Scenarios, CommandExecuteParameters )
	
	saveAll ();
	ClearMessages ();
	for each scenario in Scenarios do
		complete = Test.Exec ( Scenario, DF.Pick ( Scenario, "Application" ), , , , true );
	enddo; 
	if ( complete ) then
		Output.TestComlete ();
	endif;
	
EndProcedure

&AtClient
Procedure saveAll ()
	
	Notify ( Enum.MessageSaveAll () );
	
EndProcedure 
