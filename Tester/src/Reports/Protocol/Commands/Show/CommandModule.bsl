&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = ReportsSystem.GetParams ( "Protocol" );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );
	
EndProcedure
