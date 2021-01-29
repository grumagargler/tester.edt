Function Allowed () export
	
	if ( Logins.AccessDenies () ) then
		Output.AccessDenied ( ThisObject, , , "Quit" );
		return false;
	endif; 
	return true;
	
EndFunction

Procedure Quit ( Params ) export
	
	Terminate ();
	
EndProcedure 
