
&AtClient
Procedure CommandProcessing ( Version, CommandExecuteParameters )
	
	Output.SetCurrentVersion ( ThisObject, Version, new Structure ( "Version", Version ) );
	
EndProcedure

&AtClient
Procedure SetCurrentVersion ( Answer, Version ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	Environment.ApplyVersion ( Version );
	
EndProcedure 
