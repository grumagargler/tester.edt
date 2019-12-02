
Procedure Go ( Scenario, Debugging ) export
	
	if ( SessionScenario.IsEmpty () ) then
		if ( Scenario = undefined ) then
			Output.UndefinedMainScenario ( ThisObject );
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
	complete = Test.Exec ( SessionScenario, , , Debugging );
	if ( complete ) then
		Output.TestComlete ();
		if ( TesterServerMode ) then
			Watcher.AddMessage ( Output.TestComleteMessage () );
		endif;
	endif;
	
EndProcedure 

Procedure saveAll ()
	
	Notify ( Enum.MessageSaveAll () );
	
EndProcedure 
