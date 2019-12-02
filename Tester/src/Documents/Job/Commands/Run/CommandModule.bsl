
&AtClient
Procedure CommandProcessing ( Scenarios, ExecuteParameters )
	
	saveAll ();
	p = new Structure ( "Scenarios", Scenarios );
	OpenForm ( "Document.Job.ObjectForm", p, ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL );
	
EndProcedure

&AtClient
Procedure saveAll ()
	
	Notify ( Enum.MessageSaveAll () );
	
EndProcedure 
