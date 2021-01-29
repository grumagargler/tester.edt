#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Events () export
	
	p = Reporter.Events ();
	p.OnDetail = true;
	p.OnCompose = true;
	p.AfterOutput = true;
	return p;
	
EndFunction 

Procedure OnDetail ( Menu, StandardMenu, UseMainAction, Filters ) export
	
	UseMainAction = true;
	filters = GetFromTempStorage ( Filters );
	info = moduleInfo ( filters );
	if ( info <> undefined ) then
		Reporter.DisableMenu ( StandardMenu );
		Reporter.AddCommand ( Menu, Enum.ReportCommandsOpenModule (), info );
	endif;

EndProcedure

Function moduleInfo ( Filters ) export
	
	line = getValue ( "ModuleLine", Filters );
	if ( line <> undefined ) then
		scenario = getValue ( "ErrorScenario", Filters );
		error = getValue ( "ErrorsRef", Filters );
		return new Structure ( "Scenario, Line, Error", scenario, line, error );
	endif;

EndFunction

Function getValue ( Name, Filters )
	
	for each item in Filters do
		if ( item.Name = Name ) then
			return item.Item.Value;
		endif;
	enddo;
	
EndFunction

#endif