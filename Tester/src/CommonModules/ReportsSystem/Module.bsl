Procedure Form ( Source, FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing ) export
	
	#if ( Server ) then
		if ( FormType <> "Form" ) then
			return;
		endif;
		reportName = Metadata.FindByType ( TypeOf ( Source ) ).Name;
		if ( nonStandardReport ( reportName ) ) then
			return;
		endif; 
		StandardProcessing = false;
		ReportsSystem.SetParams ( Parameters, ReportName );
		SelectedForm = Metadata.Reports.Common.Forms.Form;
	#endif
	
EndProcedure

#if ( Server ) then
	
Function nonStandardReport ( ReportName )

	reps = "Common";
	return Find ( reps, ReportName ) > 0;
	
EndFunction 

#endif

Function GetParams ( ReportName ) export
	
	p = new Structure ();
	SetParams ( p, ReportName );
	return p;
	
EndFunction

Procedure SetParams ( Params, ReportName ) export
	
	Params.Insert ( "ReportName", ReportName );
	Params.Insert ( "Command", "OpenReport" );
	Params.Insert ( "Filters" );
	Params.Insert ( "Parent" );
	Params.Insert ( "GenerateOnOpen", false );
	
EndProcedure
