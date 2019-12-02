
&AtClient
Procedure CommandProcessing ( Job, CommandExecuteParameters )
	
	p = new Structure ( "Job", Job );
	OpenForm ( "InformationRegister.Log.ListForm", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
