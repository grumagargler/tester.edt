
&AtClient
Procedure CommandProcessing ( Scenario, ExecuteParameters )
	
	runExplorer ( Scenario );
	
EndProcedure

&AtClient
Procedure runExplorer ( Scenario )
	
	error = "";
	file = RepositoryFiles.ScenarioToFile ( Scenario, error );
	if ( file = undefined ) then
		Message ( error );
	else
		#if ( WebClient or MobileClient ) then
			Output.ClientDoesNotSupport ();
		#else
			RunApp ( FileSystem.GetParent ( file ) );
		#endif
	endif;
	
EndProcedure
