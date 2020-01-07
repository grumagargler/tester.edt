
Procedure Go ( Scenario, Debugging ) export
	
	if ( SessionScenario.IsEmpty () ) then
		if ( Scenario = undefined ) then
			Output.UndefinedMainScenario ();
		else
			Output.SetupMainScenario ( ThisObject, new Structure ( "Scenario, Debugging", Scenario ) );
		endif;
	else
		runScenario ( Debugging );
	endif; 
	
EndProcedure

Procedure SetupMainScenario ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	Environment.ChangeScenario ( Params.Scenario );
	runScenario ( Params.Debugging );
	
EndProcedure 

Procedure runScenario ( Debugging )
	
	saveAll ();
	ClearMessages ();
	Test.Exec ( SessionScenario, , , Debugging );
	Output.TestComlete ();
	if ( TesterServerMode ) then
		Watcher.AddMessage ( Output.TestComleteMessage () );
	endif;
	
EndProcedure 

Procedure saveAll ()
	
	Notify ( Enum.MessageSaveAll () );
	
EndProcedure 
