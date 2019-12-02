
&AtClient
Procedure CommandProcessing ( Scenarios, CommandExecuteParameters )
	
	callback = new NotifyDescription ( "Locked", ThisObject );
	p = new Structure ( "Scenarios", Scenarios );
	OpenForm ( "Catalog.Scenarios.Form.Lock", p, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL, callback );
	
EndProcedure

&AtClient
Procedure Locked ( Errors, Params ) export
	
	if ( Errors = undefined ) then
		return;
	endif; 
	for each error in Errors do
		Output.LockError ( error );
	enddo; 
	
EndProcedure 