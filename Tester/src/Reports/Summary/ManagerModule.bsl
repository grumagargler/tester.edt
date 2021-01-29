
Function Events () export
	
	params = Reporter.Events ();
	params.OnDetail = true;
	params.OnCompose = true;
	return params;
	
EndFunction 

Procedure OnDetail ( Menu, StandardMenu, UseMainAction, Filters ) export
	
	UseMainAction = true;

EndProcedure