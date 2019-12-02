Procedure Go ( Params ) export
	
	debug = getDebug ();
	perform ( Constants.Webhook.Get (), Params, debug );

EndProcedure

Function getDebug ()
	
	Debug = new Structure();
	Debug.Insert("Stack", new Array(1));
	Debug.Insert("ShowProgress", true);
	Debug.Insert("Level", 0);
	Debug.Insert("Delay", 0);
	Debug.Insert("Error", false);
	Debug.Insert("PreviousError", undefined);
	Debug.Insert("ErrorLog");
	Debug.Insert("ErrorLine");
	Debug.Insert("FallenScenario");
	Debug.Insert("Debugging", false);
	Debug.Insert("DebuggingStopped", false);
	Debug.Insert("SteppingOver", false);
	Debug.Insert("SteppingOverPoint", undefined);
	Debug.Insert("Running", false);
	Debug.Insert("Recording", false);
	Debug.Insert("Pointer", 0);
	Debug.Insert("Evaluate", "");
	Debug.Insert("EvaluationResult", "");
	Debug.Insert("EvaluationError", false);
	Debug.Insert("Job");
	Debug.Insert("CancelationCheck", CurrentDate());
	Debug.Insert("JobCanceled", false);
	Debug.Insert("Offset", 0);
	Debug.Insert("Started");
	return Debug;

EndFunction

Procedure perform ( Scenario, Params, Debug )
	
	result = Compiler.Build ( Scenario, , true );
	try
		Runtime.RunScript ( result.ClientSyntax );
	except
		Runtime.ThrowError ( BriefErrorDescription ( ErrorInfo () ), Debug );
	endtry;
	if ( result.ServerSyntax <> undefined ) then
		try
			RuntimeSrv.CheckSyntax ( result.ServerSyntax );
		except
			Runtime.ThrowError ( BriefErrorDescription ( ErrorInfo () ), Debug );
		endtry;
	endif;
	Runtime.RunScript ( result.Compiled, Params, Debug );
	
EndProcedure
