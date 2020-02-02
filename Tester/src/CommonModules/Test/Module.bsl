
Procedure Exec ( Scenario, Application = undefined, ProgramCode = undefined, Debugging = false, Offset = 0,
	Filming = false, Params = undefined ) export
	
	data = Test.FindScenario ( Scenario, Application );
	Test.AttachApplication ( data.Scenario );
	program = ? ( data.Application.IsEmpty (), SessionApplication, data.Application );
	Runtime.Exec ( program, ProgramCode, true, Debugging, Offset, Filming, , Params );
	
EndProcedure

Function FindScenario ( Scenario, Application = undefined ) export
	
	if ( TypeOf ( Scenario ) = Type ( "String" ) ) then
		if ( Application = undefined ) then
			default = EnvironmentSrv.GetApplication ();
		endif; 
		value = RuntimeSrv.FindScenario ( Scenario, default, Application, undefined );
		if ( value = undefined ) then
			raise Output.ScenarioNotFound ( new Structure ( "Name", Scenario ) );
		else
			ref = value;
		endif; 
	else
		ref = RuntimeSrv.ActualScenario ( Scenario );
	endif; 
	result = new Structure ();
	result.Insert ( "Scenario", ref );
	result.Insert ( "Application", DF.Pick ( ref, "Application" ) );
	return result;
	
EndFunction 

Procedure AttachApplication ( Scenario ) export
	
	AppData = TestSrv.Data ( Scenario );
	СвойстваПриложения = AppData;
	
EndProcedure
	
Procedure DisconnectClient ( Close = false, ShutdownProxy = false ) export
	
	if ( Close and ( MainWindow <> undefined ) ) then
		MainWindow.Close ();
	endif; 
	if ( App <> undefined ) then
		App.Disconnect ();
		App = undefined;
		Приложение = undefined;
		if ( ShutdownProxy ) then
			connection = proxyKey ( AppData.ConnectedHost, AppData.ConnectedPort );
			if ( ProxyConnections [ connection ] <> undefined ) then
				ProxyConnections [ connection ].Proxy.Stop ();
				ProxyConnections [ connection ].Proxy = undefined;
				ProxyConnections.Delete ( connection );
			endif;
		endif;
	endif;
	if ( AppData <> undefined ) then
		AppData.Connected = false;
	endif; 
	CurrentSource = undefined;
	ТекущийОбъект = undefined;
	MainWindow = undefined;
	ГлавноеОкно = undefined;
	
EndProcedure 

Function proxyKey ( Host, Port )
	
	return Host + "#" + Port;
	
EndFunction

Procedure ConnectClient ( ClearErrors = true, Port = undefined, Computer = undefined ) export
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		try
			tryConnect ( ClearErrors, Port, Computer );
		except
			try
				Disconnect ();
			except
			endtry;
			tryConnect ( ClearErrors, Port, Computer );
		endtry;
	#endif

EndProcedure 

Procedure tryConnect ( ClearErrors, Port, Computer )
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		host = ? ( Computer = undefined, AppData.Computer, Computer );
		hostPort = ? ( Port = undefined, AppData.Port, Port );
		AppData.ConnectedHost = host;
		AppData.ConnectedPort = hostPort;
		if ( AppData.Proxy <> undefined ) then
			proxy = proxyConnection ();
			host = proxy.Localhost;
			hostPort = proxy.Port;
		endif;
		// Evaluation is required because TestedApplication is not defined as a Type
		// outside of TestManager running mode
		App = Eval ( "new TestedApplication ( host, hostPort, AppData.ClientID )" );
		App.Connect ();
		Приложение = App;
		AppData.Connected = true;
		initMainWindow ();
		if ( ClearErrors ) then
			error = App.GetCurrentErrorInfo ();
			if ( error = undefined ) then
				try
					CheckErrors ();
					return;
				except
				endtry;
			endif; 
			Forms.CloseWindows ();
		endif; 
	#endif
	
EndProcedure

Function proxyConnection ()
	
	if ( ProxyConnections = undefined ) then
		ProxyConnections = new Map ();
	endif;
	connection = proxyKey ( AppData.ConnectedHost, AppData.ConnectedPort );
	if ( ProxyConnections [ connection ] = undefined ) then
		proxyPort = AppData.Proxy;
		for each entry in ProxyConnections do
			lastPort = entry.Value.Port;
			if ( lastPort >= proxyPort ) then
				proxyPort = lastPort + 1;
			endif;
		enddo;
		proxy = new ( "AddIn.Extender.Proxy" );
		localhost = AppData.Localhost;
		proxy.Start ( FrameworkVersion, localhost, proxyPort, AppData.ConnectedHost, AppData.ConnectedPort, AppData.Version );
		ProxyConnections [ connection ] = new Structure ( "Localhost, Port, Proxy", localhost, proxyPort, proxy );
	endif;
	return ProxyConnections [ connection ];
	
EndFunction

Function StartProxy ( Localhost, LocalPort, Host, Port, ServerVersion = undefined, ClientVersion = undefined ) export
	
	if ( ProxyConnections = undefined ) then
		ProxyConnections = new Map ();
	endif;
	connection = proxyKey ( Host, Port );
	if ( ProxyConnections [ connection ] = undefined ) then
		proxy = new ( "AddIn.Extender.Proxy" );
		proxy.Start ( ? ( ServerVersion = undefined, FrameworkVersion, ServerVersion ), Localhost, LocalPort, Host, Port, ClientVersion );
		ProxyConnections [ connection ] = new Structure ( "Localhost, Port, Proxy", Localhost, LocalPort, proxy );
	else
		raise Output.ProxyAlreadyStarted ( new Structure ( "Host, Port", Host, Format ( Port, "NG=0;NZ=0" ) ) );
	endif;
	return ProxyConnections [ connection ];
	
EndFunction

Procedure StopProxy ( Host, Port ) export
	
	if ( ProxyConnections = undefined ) then
		return;
	endif;
	connection = proxyKey ( Host, Port );
	proxy = ProxyConnections [ connection ];
	if ( proxy = undefined ) then
		return;
	endif;
	proxy.Proxy.Stop ();
	proxy.Proxy = undefined;
	ProxyConnections.Delete ( connection );
	
EndProcedure

Procedure initMainWindow ()
	
	frames = App.FindObjects ( Type ( "TestedClientApplicationWindow" ) );
	for each item in frames do
		if ( item.IsMain ) then
			break;
		endif; 
	enddo; 
	MainWindow = item;
	ГлавноеОкно = MainWindow;
	if ( frames.Count () = 1 ) then
		MainWindow.Activate ();
	endif; 

EndProcedure 

Procedure CheckSyntax ( ProgramCode ) export
	
	error = Runtime.CheckSyntax ( ProgramCode );
	if ( error = undefined ) then
		OpenForm ( "CommonForm.SyntaxPassed" );
	else
		Output.SyntaxError ( undefined, new Structure ( "Error", error ) );
	endif;
	
EndProcedure 

Procedure Start ( Scenario, Application = undefined ) export
	
	data = Test.FindScenario ( Scenario, Application );
	Test.AttachApplication ( data.Scenario );
	Runtime.NextLevel ( Debug );
	Runtime.Exec ( , , false );
	Runtime.PreviousLevel ( Debug );
	
EndProcedure

Procedure Attach ( Port = undefined ) export
	
	Test.AttachApplication ( SessionScenario );
	Test.ConnectClient ( false, Port );

EndProcedure

Procedure CheckConnection () export
	
	if ( App = undefined
		or MainWindow = undefined ) then
		raise Output.TestedApplicationOffline ();
	endif;
	
EndProcedure

Procedure ShutdownProxy () export
	
	if ( ProxyConnections = undefined ) then
		return;
	endif;
	for each connection in ProxyConnections do
		connection.Value.Proxy.Stop ();
		connection.Value.Proxy = undefined;
	enddo;
	ProxyConnections = undefined;
	
EndProcedure

Procedure PauseExecution ( Seconds ) export
	
	if ( ExternalLibrary = undefined ) then
		return;
	endif;
	ExternalLibrary.Pause ( 1000 * Seconds );
	
EndProcedure

Procedure GotoSystemConsole () export
	
	if ( ExternalLibrary = undefined ) then
		return;
	endif;
	ExternalLibrary.GotoConsole ();
	
EndProcedure
