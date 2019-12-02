Function RunScript(val Code, val Params = undefined, DebugInfo = undefined, val _Scenario = undefined) export
	
	result = undefined;
	if (Params <> undefined) then
		//@skip-warning
		_ = Params;
	endif;
	//@skip-warning
	_procedures = new Map();
	Chronograph = new Structure("Scenario, Module, Сценарий, Модуль");
	//@skip-warning
	Хронограф = Chronograph;
	this = new Structure();
	//@skip-warning
	тут = this;
	#if ( Server ) then
	Debug = DebugInfo;
	#else
	//@skip-warning
	_oldSource = CurrentSource;
	#endif
	#region ScenarioContext
	//@skip-warning
	StandardProcessing = true;
	//@skip-warning
	СтандартнаяОбработка = true;
	#endregion
	_monitoring = _Scenario <> undefined;
	if (_monitoring) then
		_level = scenarioLevel(Debug);
		RuntimeSrv.LogRunning(_Scenario, _level, Debug.Job);
		#if ( Client ) then
		agentStatus(PredefinedValue("Enum.AgentStatuses.Busy"));
		#endif
	endif;
	#region ExecutionContext
	_errorInfo = undefined;
	try
		Execute(Code);
	except
		_errorInfo = ErrorInfo();
		#if ( Client ) then
		if (_monitoring
				and not Debug.DebuggingStopped) then
			RuntimeSrv.FetchServerDebug(Debug);
		endif;
		#endif
	endtry;
	#if ( Client ) then
	if (_monitoring) then
		// If scenario code /Execute ( Code )/ calls server then
		// Debug sctructure will be re-instanced. In order to pass
		// actual Debug information to the caller we need to reassign
		// acquired (from the server) Debug data
		DebugInfo = Debug;
		agentStatus(PredefinedValue("Enum.AgentStatuses.Available"));
	endif;
	#endif
	if (_errorInfo = undefined) then
		if (_monitoring) then
			RuntimeSrv.LogSuccess(_Scenario, _level, Debug.Job);
		endif;
		return result;
	else
		#if ( Client ) then
		if (_monitoring) then
			if (PlatformFeatures.HasTimeout
					and not Debug.Error
					and not Debug.DebuggingStopped
					and not Debug.JobCanceled) then
				Debugger.ErrorCheck(Debug);
			endif;
		endif;
		if ( Debug.Level = 0 ) then
			try
				Disconnect ();				
			except
			endtry;
		endif;
		#endif
		Runtime.ThrowError(BriefErrorDescription(_errorInfo), Debug);
	endif;
	#endregion
	
EndFunction

Function scenarioLevel(DebugInfo)
	
	level = 0;
	stack = DebugInfo.Stack;
	lastModule = undefined;
	lastType = undefined;
	for i = 0 to DebugInfo.Level - 1 do
		info = stack[i];
		module = info.Module;
		type = info.IsVersion;
		if (lastModule <> module
				or lastType <> type) then
			level = level + 1;
		endif;
		lastModule = module;
		lastType = type;
	enddo;
	return level;
	
EndFunction

&AtClient
Procedure agentStatus(Status)
	
	if (IAmAgent
			and not RunningDelegatedJob) then
		TesterAgent.AgentStatus(Status);
	endif;
	
EndProcedure

//@skip-warning
&AtClient
Procedure Debug(Value) export
	
	//.. stop here for analysing Value
	
EndProcedure

&AtClient
Procedure Exec(SessionApplication = undefined, ProgramCode = undefined, ResetDebugger, Debugging = false, Offset = 0, Filming = false, NewSession = false) export
	
	Runtime.UpdateConstants();
	Runtime.InitEnv();
	initMeta();
	if (ResetDebugger) then
		Runtime.InitDebug(SessionApplication, Offset);
	endif;
	if (Debugging) then
		DebugStart();
	endif;
	if (Filming) then
		RecorderStart();
	endif;
	scenario = AppData.Scenario;
	result = Compiler.Build(scenario, ProgramCode);
	try
		Runtime.RunScript(result.ClientSyntax);
	except
		Runtime.ThrowError(BriefErrorDescription(ErrorInfo()), Debug);
	endtry;
	if (result.ServerSyntax <> undefined) then
		try
			RuntimeSrv.CheckSyntax(result.ServerSyntax);
		except
			Runtime.ThrowError(BriefErrorDescription(ErrorInfo()), Debug);
		endtry;
	endif;
	Runtime.RunScript(result.Compiled, , , scenario);
	#if ( Client ) then
	Runtime.StopSession();
	#endif
	
EndProcedure

&AtClient
Procedure UpdateConstants() export
	
	properties = DF.Values(AppData.Application, "Description, DialogsTitle, ScreenshotsLocator, OriginalQuality");
	AppName = properties.Description;
	ИмяПриложения = AppName;
	DialogsTitle = properties.DialogsTitle;
	ЗаголовокДиалогов = DialogsTitle;
	ScreenshotsLocator = properties.ScreenshotsLocator;
	ScreenshotsCompressed = not properties.OriginalQuality;
	
EndProcedure

&AtClient
Procedure InitEnv() export
	
	Runtime.UpdateConstants();
	__ = undefined;
	IgnoreErrors = false;
	ИгнорироватьОшибки = false;
	CurrentSource = undefined;
	ТекущийОбъект = undefined;
	
EndProcedure

&AtClient
Procedure initMeta(Reset = false) export
	
	application = AppData.Application;
	if (Meta <> undefined
			and AppMeta = application) then
		return;
	endif;
	AppMeta = application;
	s = DF.Pick(application, "Metadata");
	if (IsBlankString(s)) then
		return;
	endif;
	try
		Runtime.UpdateMeta(s);
	except
		Runtime.ThrowError(ErrorDescription(), Debug);
	endtry;
	
EndProcedure

&AtClient
Procedure UpdateMeta(JSON) export
	
	if (IsBlankString(JSON)) then
		Meta = undefined;
	else
		Meta = Conversion.FromJSON(JSON);
	endif;
	Мета = Meta;
	
EndProcedure

&AtClient
Procedure InitDebug(SessionApplication = undefined, Offset = 0) export
	
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
	job = ?(RunningDelegatedJob, CurrentDelegatedJob, undefined);
	Debug.Insert("Job", job);
	Debug.Insert("CancelationCheck", CurrentDate());
	Debug.Insert("JobCanceled", false);
	Debug.Insert("Offset", Max(0, Offset - 1));
	started = ?(SessionApplication = undefined, undefined, RuntimeSrv.StartSession(SessionApplication, ?(job = undefined, undefined, job.Job)));
	Debug.Insert("Started", started);
	
EndProcedure

&AtClient
Procedure StopSession() export
	
	started = Debug.Started;
	if (started = undefined
			or Debug.Level > 0) then
		return;
	endif;
	RuntimeSrv.StopSession(started);
	
EndProcedure

Procedure ThrowError(Text, DebugInfo) export
	
	if (syntaxError(DebugInfo)) then
		throwSyntaxError(Text);
	elsif (DebugInfo.Error) then
		RuntimeSrv.LogFailing(DebugInfo);
	else
		saveError(Text, DebugInfo);
	endif;
	rethrow(DebugInfo);
	
EndProcedure

Function syntaxError(DebugInfo)
	
	return (DebugInfo = undefined
			or DebugInfo.Stack[0] = undefined)
		and not DebugInfo.DebuggingStopped;
	
EndFunction

Procedure saveError(Text, DebugInfo)
	
	#if ( Server ) then
	image = undefined;
	#else
	image = Screenshot();
	#endif
	entry = RuntimeSrv.LogError(DebugInfo, Text, image);
	if (DebugInfo.DebuggingStopped) then
		return;
	endif;
	log = entry.Log;
	scenario = entry.Scenario;
	line = entry.Line;
	DebugInfo.Error = true;
	DebugInfo.ErrorLog = log;
	DebugInfo.ErrorLine = line;
	DebugInfo.FallenScenario = scenario;
	Output.PutMessage(entry.Error, undefined, , log, "");
	#if ( Client ) then
	if (ScenarioForm.IsOpen(scenario)) then
		Notify(Enum.MessageActivateError(), line, scenario);
	endif;
	refreshLog();
	Runtime.PassError(DebugInfo);
	#endif
	
EndProcedure

Procedure rethrow(DebugInfo)
	
	Runtime.PreviousLevel(DebugInfo);
	#if ( Server ) then
	storeDebugInfo(DebugInfo);
	#else
	Runtime.StopSession();
	#endif
	if (DebugInfo.DebuggingStopped) then
		raise Output.StopDebugging();
	else
		raise Output.ScenarioError();
	endif;
	
EndProcedure

&AtServer
Procedure storeDebugInfo(DebugInfo)
	
	r = InformationRegisters.ServerDebug.CreateRecordManager();
	r.Session = SessionParameters.Session;
	r.Debug = new ValueStorage(DebugInfo);
	r.Write();
	
EndProcedure

&AtClient
Procedure PassError(DebugInfo) export
	
	if (not TesterServerMode) then
		return;
	endif;
	text = String(DebugInfo.ErrorLog);
	splitter = StrFind(text, ":");
	Watcher.AddMessage(Mid(text, splitter + 2), Enum.MessageTypesError(), DebugInfo.FallenScenario, DebugInfo.ErrorLine);
	
EndProcedure

Procedure throwSyntaxError(Error, Scenario = undefined)
	
	s = Output.CompilationError() + ":" + Error;
	Output.PutMessage(s, undefined, "", Scenario, "");
	#if ( Client ) then
	if (TesterServerMode) then
		range = errorRange(Error);
		Watcher.AddMessage(range.Message, Enum.MessageTypesError(), Scenario, range.Line, range.Column);
	endif;
	Runtime.StopSession();
	#endif
	raise Output.ScenarioError();
	
EndProcedure

&AtClient
Function errorRange(Text)
	
	i = StrFind(Text, "{(");
	j = StrFind(Text, ")}");
	core = Mid(Text, i + 2, j - i - 2);
	parts = StrSplit(core, ",");
	message = Mid(Text, j + 4);
	return new Structure("Message, Line, Column", message, parts[0], parts[1]);
	
EndFunction

&AtClient
Procedure refreshLog()
	
	NotifyChanged(Type("CatalogRef.ErrorLog"));
	NotifyChanged(Type("InformationRegisterRecordKey.Log"));
	
EndProcedure

&AtClient
Procedure WriteError(Text) export
	
	if (Debug = undefined
			or Debug.Stack[0] = undefined) then
		throwSyntaxError(Text);
	else
		RuntimeSrv.LogError(Debug, Text, Screenshot());
	endif;
	
EndProcedure

&AtClient
Procedure ShowWarning(Text) export
	
	entry = RuntimeSrv.LogError(Debug, Text, Screenshot());
	scenario = entry.Scenario;
	if (ScenarioForm.IsOpen(scenario)) then
		Notify(Enum.MessageActivateError(), entry.Line, scenario);
	endif;
	Output.PutMessage(entry.Error, undefined, , entry.Log, "");
	refreshLog();
	
EndProcedure

Function Perform(Scenario, Params = undefined, Application = undefined, InsideFolder, ServerDebug = undefined) export
	
	#if ( Server ) then
	dbg = ServerDebug;
	#else
	dbg = Debug;
	#endif
	level = dbg.Level;
	stack = dbg.Stack[level];
	program = Compiler.Call(Scenario, stack.Module, stack.IsVersion, Application, InsideFolder);
	return callProgram ( Program, Scenario, Params, dbg );
	
EndFunction

Function callProgram ( Program, Scenario, Params, DebugInfo )

	if (Program = undefined) then
		error = Output.CallError(new Structure("Scenario", Scenario));
		Runtime.ThrowError(error, DebugInfo);
	else
		compilation = Program.Compilation;
		reference = Program.Scenario;
		try
			Runtime.RunScript(compilation.ClientSyntax, , DebugInfo);
			if (compilation.ServerSyntax <> undefined) then
				RuntimeSrv.CheckSyntax(compilation.ServerSyntax);
			endif;
		except
			throwSyntaxError(BriefErrorDescription(ErrorInfo()), reference);
			return undefined;
		endtry;
		Runtime.NextLevel(DebugInfo);
		result = Runtime.RunScript(compilation.Compiled, toStructure(Params), DebugInfo, reference);
		Runtime.PreviousLevel(DebugInfo);
		return result;
	endif;

EndFunction

Function toStructure(Params)
	
	if (TypeOf(Params) = Type("String")
			and StrStartsWith(Params, "{")
			and StrEndsWith(Params, "}")) then
		return Conversion.FromJSON(Params);
	else
		return Params;
	endif;
	
EndFunction

&AtClient
Function GetErrors() export
	
	try
		errors = App.GetActiveWindow().GetUserMessageTexts();
	except
		errors = new Array();
	endtry;
	if (errors.Count() = 0) then
		form = Forms.Get1C();
		if (form <> undefined) then
			if (Framework.VersionLess("8.3.15")) then
				type = Type("TestedFormField");
				label = form.FindObject(type, , "Field1");
				if (label = undefined) then
					label = form.FindObject(type, , "Поле1");
				endif;
				if (label <> undefined) then
					errors.Add(label.TitleText);
				endif;
			else
				type = Type("TestedFormDecoration");
				label = form.FindObject(type, , "Message");
				if (label <> undefined) then
					errors.Add(label.TitleText);
				endif;
			endif;
		endif;
	endif;
	return errors;
	
EndFunction

&AtClient
Function FindErrors(Template) export
	
	result = new Array();
	messages = Runtime.GetErrors();
	if (messages.Count() > 0) then
		result = RuntimeSrv.FindErrors(Template, messages);
	endif;
	return result;
	
EndFunction

&AtClient
Function DeepFunction(This, Chronograph, _Procedures, _Name, _P1 = undefined, _P2 = undefined, _P3 = undefined, _P4 = undefined, _P5 = undefined, _P6 = undefined, _P7 = undefined, _P8 = undefined, _P9 = undefined, _P10 = undefined, _P11 = undefined, _P12 = undefined, _P13 = undefined, _P14 = undefined, _P15 = undefined, _P16 = undefined, _P17 = undefined, _P18 = undefined, _P19 = undefined, _P20 = undefined) export
	
	_script = _Procedures[_Name];
	#region ScenarioContext
	this = This;
	//@skip-warning
	тут = This;
	//@skip-warning
	Хронограф = Chronograph;
	result = undefined;
	#endregion
	#region ExecutionContext
	Runtime.NextLevel(Debug);
	try
		Execute(_script);
	except
		errorInfo = ErrorInfo();
		RuntimeSrv.FetchServerDebug(Debug);
		Runtime.ThrowError(BriefErrorDescription(errorInfo), Debug);
	endtry;
	Runtime.PreviousLevel(Debug);
	return result;
	#endregion
	
EndFunction

Procedure NextLevel(DebugInfo) export
	
	DebugInfo.Level = DebugInfo.Level + 1;
	
EndProcedure

Procedure PreviousLevel(DebugInfo) export
	
	level = DebugInfo.Level;
	if (level = 0) then
		return;
	endif;
	DebugInfo.Level = level - 1;
	
EndProcedure

&AtClient
Procedure DeepProcedure(This, Chronograph, _Procedures, _Name, _P1 = undefined, _P2 = undefined, _P3 = undefined, _P4 = undefined, _P5 = undefined, _P6 = undefined, _P7 = undefined, _P8 = undefined, _P9 = undefined, _P10 = undefined, _P11 = undefined, _P12 = undefined, _P13 = undefined, _P14 = undefined, _P15 = undefined, _P16 = undefined, _P17 = undefined, _P18 = undefined, _P19 = undefined, _P20 = undefined) export
	
	_script = _Procedures[_Name];
	#region ScenarioContext
	this = This;
	//@skip-warning
	тут = This;
	//@skip-warning
	Хронограф = Chronograph;
	#endregion
	#region ExecutionContext
	Runtime.NextLevel(Debug);
	errorInfo = undefined;
	try
		Execute(_script);
	except
		errorInfo = ErrorInfo();
		RuntimeSrv.FetchServerDebug(Debug);
		Runtime.ThrowError(BriefErrorDescription(errorInfo), Debug);
	endtry;
	Runtime.PreviousLevel(Debug);
	#endregion
	
EndProcedure

Function IsClient() export
	
	#if ( Client ) then
	return true;
	#else
	return false;
	#endif
	
EndFunction

Function IsServer() export
	
	#if ( Server ) then
	return true;
	#else
	return false;
	#endif
	
EndFunction