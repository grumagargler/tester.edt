
&AtClient
Procedure CommandProcessing ( Node, CommandExecuteParameters )
	
	if ( main ( Node ) ) then
		Output.EnrollmentError ();
	else
		Output.EnrollNode ( ThisObject, Node );
	endif; 
	
EndProcedure

&AtServer
Function main ( val Node )
	
	name = Node.Metadata ().Name;
	return ExchangePlans [ name ].ThisNode () = Node;
	
EndFunction 

&AtClient
Procedure EnrollNode ( Answer, Node ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	enroll ( Node );
	Output.EnrollmentCompleted ();

EndProcedure 

&AtServer
Procedure enroll ( val Node )
	
	ExchangePlans.Repositories.Reset ( Node );
	
EndProcedure 