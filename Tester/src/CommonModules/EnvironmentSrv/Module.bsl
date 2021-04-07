Function InitSession ( val Computer, val WebClient, val MobileClient, val ThinClient, val ThickClient ) export
	
	SetPrivilegedMode ( true );
	EnvironmentSrv.SetSession ( Computer );
	EnvironmentSrv.SetConnection ( WebClient, MobileClient, ThinClient, ThickClient );
	data = new Structure ( "User, Scenario, Application, Connection" );
	user = SessionParameters.User;
	data.User = "" + user;
	data.Scenario = InformationRegisters.Scenarios.Get ( new Structure ( "User", user ) ).Scenario;
	data.Application = EnvironmentSrv.GetApplication ();
	data.Connection = SessionParameters.Connection;
	return data;
	
EndFunction 

Function GetApplication () export
	
	r = InformationRegisters.Applications.Get ( new Structure ( "User", SessionParameters.User ) );
	return r.Application;
	
EndFunction 

Function SetApplication ( val Application ) export
	
	actual = FindApplication ( Application );
	SetPrivilegedMode ( true );
	r = InformationRegisters.Applications.CreateRecordManager ();
	r.User = SessionParameters.User;
	r.Application = actual;
	r.Write ();
	SetPrivilegedMode ( false );
	return actual;
	
EndFunction

Function FindApplication ( Application ) export
	
	if ( TypeOf ( Application ) = Type ( "String" ) ) then
		value = Catalogs.Applications.FindByDescription ( Application, true );
		if ( value.IsEmpty () ) then
			raise Output.ApplicationNotFound ( new Structure ( "Name", Application ) );
		else
			return value;
		endif; 
	else
		return Application;
	endif; 
	
EndFunction 

Procedure ChangeScenario ( val Scenario, NewApplication ) export
	
	SetPrivilegedMode ( true );
	user = SessionParameters.User;
	r = InformationRegisters.Scenarios.CreateRecordManager ();
	r.User = user;
	r.Scenario = Scenario;
	r.Write ();
	newApp = DF.Pick ( Scenario, "Application" );
	currentApp = EnvironmentSrv.GetApplication ();
	if ( not newApp.IsEmpty ()
		and currentApp <> newApp ) then
		r = InformationRegisters.Applications.CreateRecordManager ();
		r.User = user;
		r.Application = newApp;
		r.Write ();
		NewApplication = newApp;
	endif; 
	SetPrivilegedMode ( false );
	
EndProcedure 

Procedure SetSession ( Computer ) export
	
	SetPrivilegedMode ( true );
	host = getComputer ( Computer );
	session = findSession ( host );
	if ( session = undefined ) then
		session = createSession ( host );
	endif; 
	SessionParameters.Session = session;
	SetPrivilegedMode ( false );
	
EndProcedure 

Function getComputer ( Name )
	
	host = Catalogs.Computers.FindByDescription ( Name, true );
	if ( host.IsEmpty () ) then
		obj = Catalogs.Computers.CreateItem ();
		obj.Description = Name;
		obj.Write ();
		host = obj.Ref;
	endif; 
	return host;
	
EndFunction 

Function findSession ( Host )
	
	s = "
	|select top 1 Sessions.Ref as Ref
	|from Catalog.Sessions as Sessions
	|where not Sessions.DeletionMark
	|and Sessions.Computer = &Computer
	|and Sessions.User = &User
	|";
	q = new Query ( s );
	q.SetParameter ( "Computer", Host );
	q.SetParameter ( "User", SessionParameters.User );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction 

Function createSession ( Host )
	
	obj = Catalogs.Sessions.CreateItem ();
	obj.Computer = Host;
	obj.User = SessionParameters.User;
	obj.Description = Host;
	obj.Write ();
	return obj.Ref;
	
EndFunction 

Procedure SetConnection ( WebClient, MobileClient, ThinClient, ThickClient ) export
	
	SetPrivilegedMode ( true );
	connection = findConnection ( WebClient, MobileClient, ThinClient, ThickClient );
	if ( connection = undefined ) then
		connection = createConnection ( WebClient, MobileClient, ThinClient, ThickClient );
	endif; 
	SessionParameters.Connection = connection;
	SetPrivilegedMode ( false );
	
EndProcedure 

Function findConnection ( WebClient, MobileClient, ThinClient, ThickClient )
	
	s = "
	|select top 1 Connections.Ref as Ref
	|from Catalog.Connections as Connections
	|where not Connections.DeletionMark
	|and Connections.WebClient = &WebClient
	|and Connections.MobileClient = &MobileClient
	|and Connections.ThinClient = &ThinClient
	|and Connections.ThickClient = &ThickClient
	|";
	q = new Query ( s );
	q.SetParameter ( "WebClient", WebClient );
	q.SetParameter ( "MobileClient", MobileClient );
	q.SetParameter ( "ThinClient", ThinClient );
	q.SetParameter ( "ThickClient", ThickClient );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction 

Function createConnection ( WebClient, MobileClient, ThinClient, ThickClient )
	
	obj = Catalogs.Connections.CreateItem ();
	obj.WebClient = WebClient;
	obj.MobileClient = MobileClient;
	obj.ThinClient = ThinClient;
	obj.ThickClient = ThickClient;
	obj.Write ();
	return obj.Ref;
	
EndFunction 

Procedure SetVersion ( val Version, val Running ) export
	
	r = InformationRegisters.ApplicationVersions.CreateRecordManager ();
	r.Period = ? ( Running, testingSession (), CurrentSessionDate () );
	r.Application = DF.Pick ( Version, "Owner" );
	r.User = SessionParameters.User;
	r.Version = Version;
	r.Write ();
	
EndProcedure 

Function testingSession ()
	
	s = "
	|select top 1 Sessions.Started as Started
	|from InformationRegister.Sessions as Sessions
	|where Sessions.Session = &Session
	|order by Sessions.Started desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Session", SessionParameters.Session );
	return q.Execute ().Unload () [ 0 ].Started;
	
EndFunction

Function FindByID ( val ID, val Application ) export
	
	r = InformationRegisters.Environment.CreateRecordManager ();
	r.Session = SessionParameters.Session;
	r.Application = Application;
	r.ID = ID;
	r.Read ();
	return r.Selected ();
	
EndFunction 

Procedure Register ( val ID, val Application ) export
	
	r = InformationRegisters.Environment.CreateRecordManager ();
	r.Session = SessionParameters.Session;
	r.Application = Application;
	r.ID = ID;
	r.Created = CurrentSessionDate ();
	r.Write ();
	
EndProcedure

Function LastID ( val Application ) export
	
	s = "
	|select top 1 Environments.ID as ID
	|from InformationRegister.Environment as Environments
	|where Environments.Session = &Session
	|and Environments.Application = &Application
	|order by Environments.Created desc";
	q = new Query ( s );
	q.SetParameter ( "Application", Application );
	q.SetParameter ( "Session", SessionParameters.Session );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].ID );
	
EndFunction 

Function User () export
	
	return SessionParameters.User;
	
EndFunction 

Function StartAgent () export
	
	agent = DF.Pick ( SessionParameters.User, "Agent" );
	if ( agent ) then
		TesterAgent.AgentStatus ( Enums.AgentStatuses.Available );
	endif;
	return agent;
	
EndFunction

Function MobileClient () export
	
	return isClient ( "MobileClient" );
	
EndFunction

Function isClient ( Type )
	
	return GetFunctionalOption ( Type, new Structure ( "Connection", SessionParameters.Connection ) );
	
EndFunction

Function WebClient () export
	
	return isClient ( "WebClient" );
	
EndFunction
