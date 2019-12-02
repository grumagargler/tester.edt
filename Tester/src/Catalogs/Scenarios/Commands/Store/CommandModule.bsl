
&AtClient
Procedure CommandProcessing ( Scenarios, CommandExecuteParameters )
	
	p = new Structure ( "Scenarios", Scenarios );
	OpenForm ( "Catalog.Scenarios.Form.Store", p, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
