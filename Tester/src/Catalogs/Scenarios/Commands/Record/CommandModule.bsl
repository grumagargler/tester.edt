
&AtClient
Procedure CommandProcessing ( Scenarios, CommandExecuteParameters )
	
	saveAll ();
	ClearMessages ();
	for each scenario in Scenarios do
		Test.Exec ( Scenario, DF.Pick ( Scenario, "Application" ), , , , true );
	enddo; 
	Output.TestComlete ();
	
EndProcedure

&AtClient
Procedure saveAll ()
	
	Notify ( Enum.MessageSaveAll () );
	
EndProcedure 
