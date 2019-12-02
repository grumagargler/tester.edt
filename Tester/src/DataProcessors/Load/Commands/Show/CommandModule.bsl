
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	Notify ( Enum.MessageSaveAll () );
	OpenForm ( "DataProcessor.Load.Form", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
