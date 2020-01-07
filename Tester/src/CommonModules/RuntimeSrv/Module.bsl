Function StartSession ( val Application, val Job ) export
	
	r = InformationRegisters.Sessions.CreateRecordManager ();
	r.Session = SessionParameters.Session;
	started = CurrentSessionDate ();
	r.Started = started;
	r.Application = Application;
	r.Job = Job;
	r.Write ();
	return started;
	
EndFunction 

Procedure StopSession ( val Started ) export
	
	r = InformationRegisters.Sessions.CreateRecordManager ();
	r.Session = SessionParameters.Session;;
	r.Started = Started;
	r.Read ();
	r.Finished = CurrentSessionDate ();
	r.Write ();
	
EndProcedure 

Function FindScenario ( val Scenario, val DefaultApplication, val Application, val Parent, val EvenLocked = false, val EvenRemoved = false ) export
	
	s = "
	|select allowed top 1 1 as Priority, Scenarios.Ref as Ref
	|into Main
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Path = &Scenario
	|and Scenarios.Application.Description = &Application
	|and not Scenarios.DeletionMark
	|union all
	|select top 1 0, Scenarios.Ref
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Path = &Scenario
	|and Scenarios.Application = &Application
	|";
	if ( not EvenRemoved ) then
		s = s + "and not Scenarios.DeletionMark"; 
	endif;
	if ( Application = undefined ) then
		s = s + "
		|union all
		|select top 1 2 as Priority, Scenarios.Ref as Ref
		|from Catalog.Scenarios as Scenarios
		|where Scenarios.Path = &Scenario
		|and Scenarios.Application = value ( Catalog.Applications.EmptyRef )
		|";
		if ( not EvenRemoved ) then
			s = s + "and not Scenarios.DeletionMark"; 
		endif;
	endif; 
	s = s + "
	|order by Priority
	|;";
	if ( EvenLocked ) then
		s = s + "
		|select Main.Ref as Ref
		|from Main as Main
		|";
	else
		s = s + "
		|select case when isnull ( Editing.User, &User ) = &User then Main.Ref
		|			else isnull ( Versions.Version, Main.Ref )
		|		end as Ref
		|from Main as Main
		|	//
		|	// Versions
		|	//
		|	left join InformationRegister.Versions.SliceLast ( , Scenario in ( select Ref from Main ) ) as Versions
		|	on Versions.Scenario = Main.Ref
		|	//
		|	// Editing
		|	//
		|	left join InformationRegister.Editing as Editing
		|	on Editing.Scenario = Main.Ref
		|";
	endif; 
	q = new Query ( s );
	if ( Parent = undefined ) then
		path = Scenario;
	else
		parentPath = DF.Pick ( Parent, "Path" );
		path = ? ( parentPath = "", Scenario, parentPath + "." + Scenario );
	endif; 
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Scenario", path );
	q.SetParameter ( "Application", ? ( Application = undefined, DefaultApplication, Application ) );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction 

Function ActualScenario ( val Scenario ) export
	
	s = "
	|select case when isnull ( Editing.User, &User ) = &User then Main.Ref else isnull ( Versions.Version, &Scenario ) end as Ref
	|from ( select &Scenario as Ref ) as Main
	|	//
	|	// Versions
	|	//
	|	left join InformationRegister.Versions.SliceLast ( , Scenario = &Scenario ) as Versions
	|	on Versions.Scenario = Main.Ref
	|	//
	|	// Editing
	|	//
	|	left join InformationRegister.Editing as Editing
	|	on Editing.Scenario = Main.Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Scenario", Scenario );
	return q.Execute ().Unload () [ 0 ].Ref;
	
EndFunction 

Function LogError ( val Debug, val Error, val Screenshot ) export
	
	SetPrivilegedMode ( true );
	stack = stack ( Debug );
	msg = completeError ( stack, Error );
	log = addError ( stack, msg, Debug.Level, Screenshot, Debug.Job );
	return new Structure ( "Log, Error, Scenario, Line", log, msg.Long, stack.Scenario, stack.Line );

EndFunction

Function stack ( Debug )
	
	stack = Debug.Stack;
	s = new Array ();
	calls = new Array ();
	for i = 0 to Min ( stack.Ubound (), Debug.Level ) do
		info = stack [ i ];
		module = getModule ( info );
		scenario = module.Ref;
		position = info.Row + ? ( i = 0, Debug.Offset, 0 );
		line = Format ( position, "NG=;NZ=" );
		s.Add ( module.Name + "[" + line + "]" );
		calls.Add ( new Structure ( "Scenario, Row", scenario, position ) );
	enddo; 
	data = new Structure ( "Line, Source, Scenario, Calls" );
	data.Line = Format ( line, "NG=;NZ=" );
	data.Source = StrConcat ( s, " -> " );
	data.Scenario = scenario;
	data.Calls = calls;
	return data;
	
EndFunction 

Function getModule ( Stack )
	
	source = ? ( Stack.IsVersion, "Catalog.Versions", "Catalog.Scenarios" );
	s = "
	|select top 1 Scenarios.Path as Name, Scenarios.Ref as Ref
	|from " + source + " as Scenarios
	|where Scenarios.Code = &Module
	|";
	q = new Query ( s );
	q.SetParameter ( "Module", Stack.Module );
	return q.Execute ().Unload () [ 0 ];

EndFunction 

Function completeError ( Stack, Error )
	
	p = new Structure ();
	p.Insert ( "Message", Error );
	p.Insert ( "Line", stack.Line );
	p.Insert ( "Stack", stack.Source );
	prefix = Output.RuntimeMessagePrefix ( p );
	body = Output.RuntimeMessage ( p );
	long = prefix + body;
	//@skip-warning
	max = Metadata.Catalogs.ErrorLog.StandardAttributes.Description.Type.StringQualifiers.Length;
	tooLong = StrLen ( long ) > max;
	if ( tooLong ) then
		cutPrefix = Output.RuntimeMessageCutPrefix ();
		rest = max - StrLen ( prefix ) - StrLen ( cutPrefix );
		short = prefix + cutPrefix + Right ( long, rest );
	else
		short = long;
	endif;
	return new Structure ( "Long, Short", long, short );
	
EndFunction 

Function addError ( Stack, Error, Level, Screenshot, Job )
	
	obj = Catalogs.ErrorLog.CreateItem ();
	obj.SetNewObjectRef ( Catalogs.ErrorLog.GetRef ( new UUID () ) );
	if ( Screenshot <> undefined ) then
		obj.Screenshot = new ValueStorage ( Screenshot );
		obj.ScreenshotExists = true;
	endif; 
	ref = obj.GetNewObjectRef ();
	scenario = stack.Scenario;
	source = getSource ( scenario );
	date = CurrentSessionDate ();
	writeError ( source, scenario, date, ref, Level, Job );
	obj.Description = Error.Short;
	obj.FullText = Error.Long;
	obj.Session = SessionParameters.Session;
	obj.Scenario = scenario;
	obj.Line = stack.Line;
	obj.User = SessionParameters.User;
	obj.Date = date;
	obj.Source = source.Scenario;
	obj.Application = source.Application;
	assignJob ( obj, Job );
	table = obj.Stack;
	maxSeverity = undefined;
	for each call in stack.Calls do
		row = table.Insert ( 0 );
		row.Row = call.Row;
		scenario = call.Scenario;
		row.Scenario = scenario;
		severity = DF.Pick ( scenario, "Severity" );
		if ( severityLevel ( severity ) > severityLevel ( maxSeverity ) ) then
			maxSeverity = severity;
		endif;
	enddo; 
	obj.Severity = maxSeverity;
	obj.Write ();
	return ref;
	
EndFunction 

Function getSource ( Scenario )
	
	result = new Structure ( "Application, Scenario" );
	if ( TypeOf ( Scenario ) = Type ( "CatalogRef.Versions" ) ) then
		data = DF.Values ( Scenario, "Application, Scenario" );
		result.Application = data.Application;
		result.Scenario = data.Scenario;
	else
		result.Application = DF.Pick ( Scenario, "Application" );
		result.Scenario = Scenario;
	endif;
	return result;
	
EndFunction

Procedure writeError ( Source, Scenario, Date, Error, Level, Job )
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.Log.CreateRecordManager ();
	r.Period = CurrentSessionDate ();
	r.Session = SessionParameters.Session;
	r.Scenario = Scenario;
	r.Level = Level;
	r.Status = Enums.Statuses.Fault;
	r.Error = Error;
	r.Source = Source.Scenario;
	r.Application = Source.Application;
	assignJob ( r, Job );
	completeRunning ( r );
	r.Write ();
	
EndProcedure

Procedure completeRunning ( Record )
	
	completed = CurrentUniversalDateInMilliseconds ();
	session = SessionParameters.Session;
	data = InformationRegisters.Log.SliceLast ( , new Structure ( "Scenario, Session", Record.Scenario, session ) );
	if ( data.Count () = 1 ) then
		log = data [ 0 ];
		if ( log.Status = Enums.Statuses.Running ) then
			r = InformationRegisters.Log.CreateRecordManager ();
			FillPropertyValues ( r, log, "Period, Scenario, Session" );
			r.Delete ();
			started = log.Started;
			Record.Started = started;
			Record.Duration = completed - started;
		endif; 
	endif;
	
EndProcedure 

Procedure assignJob ( Record, Job )
	
	if ( Job <> undefined ) then
		Record.Job = Job.Job;
		Record.Row = Job.Row;
	endif;
	
EndProcedure

Function severityLevel ( Severity )
	
	if ( severity = Enums.Severity.Critical ) then
		return 3;
	elsif ( severity = Enums.Severity.Normal ) then
		return 2;
	elsif ( severity = Enums.Severity.Low ) then
		return 1;
	else
		return 0;
	endif;
	
EndFunction

Procedure LogRunning ( val Scenario, val Level, val Job ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.Log.CreateRecordManager ();
	r.Period = CurrentSessionDate ();
	r.Session = SessionParameters.Session;
	r.Scenario = Scenario;
	r.Level = Level;
	r.Status = Enums.Statuses.Running;
	r.Started = CurrentUniversalDateInMilliseconds ();
	source = getSource ( Scenario );
	r.Source = source.Scenario;
	r.Application = source.Application;
	assignJob ( r, Job );
	r.Write ();
	
EndProcedure 

Procedure LogSuccess ( val Scenario, val Level, val Job ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.Log.CreateRecordManager ();
	r.Period = CurrentSessionDate ();
	r.Session = SessionParameters.Session;
	r.Scenario = Scenario;
	r.Level = Level;
	r.Status = Enums.Statuses.Passed;
	source = getSource ( Scenario );
	r.Source = source.Scenario;
	r.Application = source.Application;
	assignJob ( r, Job );
	completeRunning ( r );
	r.Write ();
	
EndProcedure 

Procedure LogFailing ( val Debug ) export
	
	SetPrivilegedMode ( true );
	stack = stack ( Debug );
	scenario = stack.Scenario;
	if ( scenario = Debug.FallenScenario ) then
		return;
	endif; 
	source = getSource ( scenario );
	writeError ( source, scenario, CurrentSessionDate (), Debug.ErrorLog, Debug.Level, Debug.Job );
	
EndProcedure

Function GetSpreadsheet ( Module, IsVersion ) export
	
	data = spreadsheetData ( Module, IsVersion );
	t = data.Template;
	if ( t = undefined ) then
		return undefined;
	endif; 
	tabDoc = t.Get ();
	if ( tabDoc = undefined ) then
		return undefined;
	endif;
	areas = data.Areas;
	if ( areas.Count () = 0 ) then
		x = tabDoc.TableWidth;
		y = tabDoc.TableHeight;
		if ( x = 0 and y = 0 ) then
			return undefined;
		endif;
		row = areas.Add ();
		row.Left = 1;
		row.Right = x;
		row.Up = 1;
		row.Bottom = y;
	endif; 
	return new Structure ( "Template, Areas", tabDoc, Collections.Serialize ( areas ) );

EndFunction 

Function spreadsheetData ( Module, IsVersion )
	
	source = ? ( IsVersion, "Catalog.Versions", "Catalog.Scenarios" );
	s = "
	|select top 1 Scenarios.Template as Template
	|from " + source + " as Scenarios
	|where Scenarios.Code = &Module
	|;
	|select Areas.Left as Left, Areas.Right as Right, Areas.Top as Up, Areas.Bottom as Bottom
	|from " + source + ".Areas as Areas
	|where Areas.Ref.Code = &Module
	|";
	q = new Query ( s );
	q.SetParameter ( "Module", Module );
	data = q.ExecuteBatch ();
	template = data [ 0 ].Unload () [ 0 ].Template;
	areas = data [ 1 ].Unload ();
	return new Structure ( "Template, Areas", template, areas );
	
EndFunction 

Function FindErrors ( val Template, val Messages ) export
	
	exp = Regexp.Get ();
	exp.Pattern = prepareTemplate ( Template );
	result = new Array ();
	for each msg in Messages do
		if ( exp.Test ( msg ) ) then
			result.Add ( msg );
		endif;
	enddo; 
	return result;
	
EndFunction 

Function prepareTemplate ( Template )
	
	s = Template;
	s = StrReplace ( s, "*", "[\s\S]+" );
	s = StrReplace ( s, "?", "[\s\S]" );
	return s;
	
EndFunction 

Procedure CheckSyntax ( val Code ) export
	
	//@skip-warning
	var Debug, _procedures, this, тут, Chronograph, Хронограф;
	Execute ( Code );

EndProcedure 

Function DeepFunction ( This, Chronograph, Debug, val _Procedures, _Name, _P1 = undefined, _P2 = undefined, _P3 = undefined, _P4 = undefined, _P5 = undefined, _P6 = undefined, _P7 = undefined, _P8 = undefined, _P9 = undefined, _P10 = undefined, _P11 = undefined, _P12 = undefined, _P13 = undefined, _P14 = undefined, _P15 = undefined, _P16 = undefined, _P17 = undefined, _P18 = undefined, _P19 = undefined, _P20 = undefined ) export
	
	initDebugStorage ();
	_script = _Procedures [ _Name ];
	#region ScenarioContext
	this = This;
	//@skip-warning
	тут = This;
	//@skip-warning
	Хронограф = Chronograph;
	result = undefined;
	#endregion
	#region ExecutionContext
	Runtime.NextLevel ( Debug );
	_errorInfo = undefined;
	try
		Execute ( _script );
	except
		_errorInfo = ErrorInfo ();
	endtry;
	if ( _errorInfo = undefined ) then
		Runtime.PreviousLevel ( Debug );
		return result;
	else
		Runtime.ThrowError ( BriefErrorDescription ( _errorInfo ), Debug );
	endif; 
	#endregion
	
EndFunction 

Procedure initDebugStorage ()
	
	r = InformationRegisters.ServerDebug.CreateRecordManager ();
	r.Session = SessionParameters.Session;
	r.Delete ();
	
EndProcedure

Procedure DeepProcedure ( This, Chronograph, Debug, val _Procedures, _Name, _P1 = undefined, _P2 = undefined, _P3 = undefined, _P4 = undefined, _P5 = undefined, _P6 = undefined, _P7 = undefined, _P8 = undefined, _P9 = undefined, _P10 = undefined, _P11 = undefined, _P12 = undefined, _P13 = undefined, _P14 = undefined, _P15 = undefined, _P16 = undefined, _P17 = undefined, _P18 = undefined, _P19 = undefined, _P20 = undefined ) export
	
	initDebugStorage ();
	_script = _Procedures [ _Name ];
	#region ScenarioContext
	this = This;
	//@skip-warning
	тут = This;
	//@skip-warning
	Хронограф = Chronograph;
	#endregion
	#region ExecutionContext
	Runtime.NextLevel ( Debug );
	_errorInfo = undefined;
	try
		Execute ( _script );
	except
		_errorInfo = ErrorInfo ();
	endtry;
	if ( _errorInfo = undefined ) then
		Runtime.PreviousLevel ( Debug );
	else
		Runtime.ThrowError ( BriefErrorDescription ( _errorInfo ), Debug );
	endif; 
	#endregion

EndProcedure

Function RecordingContext ( val Code, val IsVersion ) export
	
	SetPrivilegedMode ( true );
	BeginTransaction ();
	result = scenarioAndModule ( Code, IsVersion );
	if ( result.Module = null ) then
		data = scenarioData ( result.Scenario, IsVersion );
		obj = Catalogs.Modules.CreateItem ();
		scenario = result.Scenario;
		obj.Scenario = scenario;
		obj.Description = data.Description;
		obj.Path = data.Path;
		obj.Changed = data.Changed;
		obj.Application = data.Application;
		obj.Script = data.Script;
		obj.IsVersion = IsVersion;
		obj.Source = ? ( IsVersion, data.Source, scenario );
		obj.Write ();
		result.Module = obj.Ref;
	endif;
	CommitTransaction ();
	return result;
	
EndFunction

Function scenarioAndModule ( Code, IsVersion )
	
	source = "Catalog." + ? ( IsVersion, "Versions", "Scenarios" );
	lock = new DataLock ();
	item = lock.Add ( source );
	item.SetValue ( "Code", Code );
	item.Mode = DataLockMode.Exclusive;
	lock.Lock ();
	s = "
	|select Scenarios.Ref as Scenario, Modules.Ref as Module
	|from " + source + " as Scenarios
	|	//
	|	// Modules
	|	//
	|	left join Catalog.Modules as Modules
	|	on Modules.Scenario = Scenarios.Ref
	|	and Modules.Changed = Scenarios.Changed
	|where Scenarios.Code = &Code
	|";
	q = new Query ( s );
	q.SetParameter ( "Code", Code );
	return Conversion.RowToStructure ( q.Execute ().Unload () );
	
EndFunction

Function scenarioData ( Scenario, IsVersion )
	
	s = "
	|select Scenarios.Description as Description, Scenarios.Path as Path,
	|	Scenarios.Changed as Changed, Scenarios.Application as Application,
	|	Scenarios.Script as Script";
	if ( IsVersion ) then
		s = s + ", Scenarios.Scenario as Source"
	endif;
	s = s + "
	|from Catalog." + ? ( IsVersion, "Versions", "Scenarios" ) + " as Scenarios
	|where Scenarios.Ref = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Scenario );
	return q.Execute ().Unload () [ 0 ];
	
EndFunction

Procedure Recording ( val Params ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.Timelapse.CreateRecordManager ();
	r.Session = SessionParameters.Session;
	r.Scenario = Params.Scenario;
	r.Row = Params.Row;
	r.Date = CurrentSessionDate ();
	r.Pointer = Params.Pointer;
	r.Module = Params.Module;
	r.Screenshot = new ValueStorage ( Params.Screenshot );
	r.Write ();	
	
EndProcedure

Procedure FetchServerDebug ( Debug ) export
	
	r = InformationRegisters.ServerDebug.CreateRecordManager ();
	r.Session = SessionParameters.Session;
	r.Read ();
	if ( r.Selected () ) then
		try
			Debug = r.Debug.Get ();
		except
		endtry;
	endif;
	r.Delete ();
	
EndProcedure
