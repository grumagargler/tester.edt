&AtClient
Procedure Connect ( ClearErrors = true, Port = undefined, Computer = undefined ) export
	
	Test.ConnectClient ( ClearErrors, Port, Computer );
	
EndProcedure 

&AtClient
Procedure Подключить ( ClearErrors = true, Port = undefined, Computer = undefined ) export
	
	Connect ( ClearErrors, Port, Computer );
	
EndProcedure 

&AtClient
Procedure Disconnect ( Close = false, ShutdownProxy = false ) export
	
	Test.DisconnectClient ( Close, ShutdownProxy );
	
EndProcedure 

&AtClient
Procedure Отключить ( Close = false, ShutdownProxy = false ) export
	
	Disconnect ( Close, ShutdownProxy );
	
EndProcedure 

&AtClient
Procedure CloseAll () export
	
	Test.CheckConnection ();
	Forms.CloseWindows ();
	
EndProcedure 

&AtClient
Procedure ЗакрытьВсе () export
	
	CloseAll ();
	
EndProcedure 

&AtClient
Procedure ЗакрытьВсё () export
	
	CloseAll ();
	
EndProcedure 

&AtClient
Function Get ( Name, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	return Fields.GetControl ( Name, Forms.FindSource ( Source ), Type ).Field;
	
EndFunction

&AtClient
Function FindForm ( Name ) export
	
	Test.CheckConnection ();
	return Forms.SearchForm ( Name );
	
EndFunction 

&AtClient
Function НайтиФорму ( Name ) export
	
	return FindForm ( Name );
	
EndFunction 

&AtClient
Function Получить ( Name, Source = undefined, Type = undefined ) export
	
	return Get ( Name, Source, Type );
	
EndFunction

&AtClient
Function Clear ( Name, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	target = Forms.FindSource ( Source );
	for each item in Conversion.StringToArray ( Name ) do
		data = Fields.ClearControl ( item, target, Type );
	enddo; 
	return data.Field;
	
EndFunction 

&AtClient
Function Очистить ( Name, Source = undefined, Type = undefined ) export
	
	return Clear ( Name, Source, Type );
	
EndFunction 

&AtClient
Function Fetch ( Name, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	return Fields.FetchValue ( Name, Forms.FindSource ( Source ), Type );
	
EndFunction

&AtClient
Function Взять ( Name, Source = undefined, Type = undefined ) export
	
	return Fetch ( Name, Source, Type );
	
EndFunction

&AtClient
Function Set ( Name, Value, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	return Fields.SetValue ( Name, Value, Forms.FindSource ( Source ), Type );
	
EndFunction 

&AtClient
Function Установить ( Name, Value, Source = undefined, Type = undefined ) export
	
	return Set ( Name, Value, Source, Type );
	
EndFunction 

&AtClient
Function Put ( Name, Value, Source = undefined, Type = undefined, TestValue = false ) export
	
	Test.CheckConnection ();
	return Fields.SetValue ( Name, Value, Forms.FindSource ( Source ), Type, true, TestValue );
	
EndFunction 

&AtClient
Function Ввести ( Name, Value, Source = undefined, Type = undefined, TestValue = false ) export
	
	return Put ( Name, Value, Source, Type, TestValue );
	
EndFunction 

&AtClient
Procedure Pick ( Name, Value, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	Fields.Select ( Name, Value, Forms.FindSource ( Source ), Type );

EndProcedure 

&AtClient
Procedure Подобрать ( Name, Value, Source = undefined, Type = undefined ) export
	
	Pick ( Name, Value, Source, Type );

EndProcedure 

&AtClient
Function Activate ( Name, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	return Fields.Focus ( Name, Forms.FindSource ( Source ), Type ).Field;
	
EndFunction

&AtClient
Function Фокус ( Name, Source = undefined, Type = undefined ) export
	
	return Activate ( Name, Source, Type );
	
EndFunction

&AtClient
Function Click ( Name, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	return Fields.ClickField ( Name, Source, Type );
	
EndFunction

&AtClient
Function Нажать ( Name, Source = undefined, Type = undefined ) export
	
	return Click ( Name, Source, Type );
	
EndFunction

&AtClient
Function Call ( Scenario, Params = undefined, Application = undefined ) export
	
	return Runtime.Perform ( Scenario, Params, Application, false );
	
EndFunction

&AtClient
Function Вызвать ( Scenario, Params = undefined, Application = undefined ) export
	
	return Call ( Scenario, Params, Application );
	
EndFunction

&AtClient
Function Run ( Scenario, Params = undefined, Application = undefined ) export
	
	return Runtime.Perform ( Scenario, Params, Application, true );
	
EndFunction

&AtClient
Function Позвать ( Scenario, Params = undefined, Application = undefined ) export
	
	return Run ( Scenario, Params, Application );
	
EndFunction

&AtClient
Procedure OpenMenu ( Path ) export
	
	Test.CheckConnection ();
	Forms.ClickMenu ( Path );
	
EndProcedure 

&AtClient
Procedure Меню ( Path ) export
	
	OpenMenu ( Path );
	
EndProcedure 

&AtClient
Function With ( Name = undefined, Activate = false ) export
	
	Test.CheckConnection ();
	return Forms.SetCurrent ( Name, Activate );

EndFunction

&AtClient
Function Здесь ( Name = undefined, Activate = false ) export
	
	return With ( Name, Activate );

EndFunction

&AtClient
Function Choose ( Name, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	return Fields.StartChoosing ( Name, Source, Type );
	
EndFunction

&AtClient
Function Выбрать ( Name, Source = undefined, Type = undefined ) export
	
	return Choose ( Name, Source, Type );
	
EndFunction 

&AtClient
Procedure Check ( Name, Value, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	Fields.CheckValue ( Name, Value, Forms.FindSource ( Source ), Type );
	
EndProcedure 

&AtClient
Procedure Проверить ( Name, Value, Source = undefined, Type = undefined ) export
	
	Check ( Name, Value, Source, Type );
	
EndProcedure 

&AtClient
Procedure CheckTable ( Table, Params = undefined, Options = undefined, Source = undefined ) export
	
	Test.CheckConnection ();
	Fields.CheckTableContent ( Table, Params, Options, Forms.FindSource ( Source ) );
	
EndProcedure 

&AtClient
Procedure ПроверитьТаблицу ( Table, Params = undefined, Options = undefined, Source = undefined ) export
	
	CheckTable ( Table, Params, Options, Source );
	
EndProcedure 

&AtClient
Procedure CheckState ( Name, Value, Flag = true, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	parts = StrSplit ( Name, "," );
	for each part in parts do
		Fields.CheckAppearance ( TrimAll ( part ), Value, Flag, Forms.FindSource ( Source ), Type );
	enddo; 
		
EndProcedure 

&AtClient
Procedure ПроверитьСтатус ( Name, Value, Flag = true, Source = undefined, Type = undefined ) export
	
	CheckState ( Name, Value, Flag, Source, Type );
		
EndProcedure 

&AtClient
Procedure CheckTemplate ( Name, Source = undefined, Type = undefined, Template = undefined ) export
	
	Test.CheckConnection ();
	Fields.CheckSpreadsheet ( Name, Forms.FindSource ( Source ), Type, Template );
		
EndProcedure 

&AtClient
Procedure ПроверитьШаблон ( Name, Source = undefined, Type = undefined, Template = undefined ) export
	
	CheckTemplate ( Name, Source, Type, Template );
		
EndProcedure 

&AtClient
Procedure CheckErrors () export
	
	Test.CheckConnection ();
	errors = Runtime.GetErrors ();
	if ( errors.Count () > 0 ) then
		raise errors [ 0 ];
	endif; 
	
EndProcedure 

&AtClient
Procedure ПроверитьОшибки () export
	
	CheckErrors (); 
	
EndProcedure 

&AtClient
Function GetMessages () export
	
	Test.CheckConnection ();
	return Runtime.GetErrors ();
	
EndFunction

&AtClient
Function ПолучитьСообщения () export
	
	return GetMessages ();
	
EndFunction

&AtClient
Function FindMessages ( Template ) export
	
	Test.CheckConnection ();
	return Runtime.FindErrors ( Template );
	
EndFunction

&AtClient
Function НайтиСообщения ( Template ) export
	
	return FindMessages ( Template );
	
EndFunction

&AtClient
Procedure Stop ( Reason = undefined ) export
	
	if ( Reason = undefined ) then
		raise Output.StopMessage ();
	else
		raise String ( Reason );
	endif; 
	
EndProcedure 

&AtClient
Procedure Стоп ( Reason = undefined ) export
	
	Stop ( Reason );
	
EndProcedure 

&AtClient
Procedure Close ( Form = undefined ) export
	
	Test.CheckConnection ();
	target = Forms.GetFrame ( Form );
	target.Close ();
	
EndProcedure 

&AtClient
Procedure Закрыть ( Form = undefined ) export
	
	Close ( Form );
	
EndProcedure 

&AtClient
Function Waiting ( Name, Timeout = 3, Type = undefined ) export
	
	Test.CheckConnection ();
	return Forms.Wait ( Name, Timeout, Type );
	
EndFunction 

&AtClient
Function Дождаться ( Name, Timeout = 3, Type = undefined ) export
	
	return Waiting ( Name, Timeout, Type );
	
EndFunction 

&AtClient
Function GetWindow ( Form = undefined ) export
	
	Test.CheckConnection ();
	return Forms.GetFrame ( Form );
	
EndFunction 

&AtClient
Function ПолучитьОкно ( Form = undefined ) export
	
	return GetWindow ( Form );
	
EndFunction 

&AtClient
Function GetLinks ( Form = undefined ) export
	
	Test.CheckConnection ();
	return Forms.GetFrame ( Form ).GetCommandInterface ();
	
EndFunction 

&AtClient
Function ПолучитьСсылки ( Form = undefined ) export
	
	return GetLinks ( Form );
	
EndFunction 

&AtClient
Procedure Pause ( Seconds ) export
	
	Test.PauseExecution ( Seconds );

EndProcedure

&AtClient
Procedure Пауза ( Seconds ) export
	
	Pause ( Seconds ); 

EndProcedure

&AtClient
Function CurrentTab ( Name, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	tab = Fields.GetControl ( Name, Forms.FindSource ( Source ), Type ).Field;
	return tab.GetCurrentPage ();
	
EndFunction

&AtClient
Function ТекущаяВкладка ( Name, Source = undefined, Type = undefined ) export
	
	return CurrentTab ( Name, Source, Type );
	
EndFunction

&AtClient
Procedure Next () export
	
	Test.CheckConnection ();
	Fields.NextField ();
	
EndProcedure 

&AtClient
Procedure Далее () export
	
	Next ();
	
EndProcedure 
         
&AtClient
Function GotoRow ( Table, Column, Value, FromStart = true, Source = undefined ) export
	
	Test.CheckConnection ();
	if ( TypeOf ( Table ) = Type ( "TestedFormTable" ) ) then
		target = Table;
	else
		target = Fields.GetControl ( Table, Forms.FindSource ( Source ), "Table" ).Field;
	endif; 
	if ( FromStart ) then
		try
			// This navigation is "just in case".
			// We do not care if first row is aready activated
			target.GotoFirstRow ( false );
		except
		endtry;
	endif; 
	search = new Map ();
	search [ Column ] = Value;
	try
		return target.GotoRow ( search );
	except
		error = ErrorDescription ();
	endtry; 
	tableIsEmpty = target.FindObject ( , Column ) <> undefined;
	if ( tableIsEmpty ) then
		return false;
	else
		raise error;
	endif; 
	
EndFunction
         
&AtClient
Function КСтроке ( Table, Column, Value, FromStart = true, Source = undefined ) export
	
	return GotoRow ( Table, Column, Value, FromStart, Source );
	
EndFunction

&AtClient
Function Commando ( Action, Activate = true ) export
	
	Test.CheckConnection ();
	Forms.DoCommand ( Action );
	if ( Activate ) then
		return Forms.SetCurrent ( undefined, Activate );
	endif;

EndFunction

&AtClient
Function Коммандос ( Action, Activate = true ) export
	
	return Commando ( Action, Activate );
	
EndFunction 

&AtClient
Procedure LogError ( Text ) export
	
	Runtime.WriteError ( Text );
	
EndProcedure 

&AtClient
Procedure ЗаписатьОшибку ( Text ) export
	
	LogError ( Text );
	
EndProcedure 

&AtClient
Function MyVersion ( Expression ) export
	
	return TestSrv.Version ( Expression );
	
EndFunction 

&AtClient
Function МояВерсия ( Expression ) export
	
	return MyVersion ( Expression );
	
EndFunction 

&AtClient
Procedure DebugStart () export
	
	Debugger.Toggle ( true );
	
EndProcedure 

&AtClient
Procedure ОтладкаСтарт () export
	
	DebugStart ();
	
EndProcedure 

&AtClient
Function EnvironmentExists ( ID ) export
	
	return Environment.FindByID ( ID );
	
EndFunction 

&AtClient
Function СозданоОкружение ( ID ) export
	
	return EnvironmentExists ( ID );
	
EndFunction 

&AtClient
Procedure RegisterEnvironment ( ID ) export
	
	Environment.Register ( ID );
	
EndProcedure 

&AtClient
Procedure СохранитьОкружение ( ID ) export
	
	RegisterEnvironment ( ID );
	
EndProcedure 

&AtClient
Function Screenshot ( Pattern = "", Compressed = undefined ) export
	
	return Forms.Shoot ( Pattern, Compressed );
	
EndFunction 

&AtClient
Function Снимок ( Pattern = "", Compressed = undefined ) export
	
	return Screenshot ( Pattern, Compressed );
	
EndFunction 

&AtClient
Procedure VStudio ( Text ) export
	
	Forms.BroadcastMessage ( Text );
	
EndProcedure

&AtClient
Procedure ВСтудию ( Text ) export
	
	VStudio ( Text );
	
EndProcedure

&AtClient
Procedure PinApplication ( Name ) export
	
	Environment.ChangeApplication ( Name );
	
EndProcedure

&AtClient
Procedure УстановитьПриложение ( Name ) export
	
	PinApplication ( Name );
	
EndProcedure

&AtClient
Procedure SetVersion ( Version, Application = undefined ) export
	
	Environment.SetApplicationVersion ( Version, Application );
	
EndProcedure 

&AtClient
Procedure УстановитьВерсию ( Version, Application = undefined ) export
	
	SetVersion ( Version, Application );
	
EndProcedure 

Procedure NewJob ( Agent, Scenario, Application = undefined, Parameters = undefined, Computer = undefined, Memo = undefined ) export
	
	TesterAgent.CreateJob ( Agent, Scenario, Application, Parameters, Computer, Memo );
	
EndProcedure

Procedure СоздатьЗадание ( Agent, Scenario, Application = undefined, Parameters = undefined, Computer = undefined, Memo = undefined ) export
	
	NewJob ( Agent, Scenario, Application, Parameters, Computer, Memo );
	
EndProcedure

&AtClient
Procedure GotoConsole () export
	
	Test.GotoSystemConsole ();

EndProcedure

&AtClient
Procedure ПерейтиВКонсоль () export
	
	GotoConsole (); 

EndProcedure

Function Assert ( Value, Details = "" ) export 
	
	#if ( Server ) then
		obj = DataProcessors.Assertions.Create ();
	#else
		obj = GetForm ( "DataProcessor.Assertions.Form" );
	#endif
	obj.That ( Value, Details );	
	return obj;
	
EndFunction

Function Заявить ( Value, Details = "" ) export
	
	return Assert ( Value, Details );
	
EndFunction

&AtClient
Procedure RecorderStart () export
	
	Debugger.Recording ( true );
	
EndProcedure

&AtClient
Procedure ХронографСтарт () export
	
	RecorderStart ();
	
EndProcedure

&AtClient
Procedure RecorderStop () export
	
	Debugger.Recording ( false );
	
EndProcedure

&AtClient
Procedure ХронографСтоп () export
	
	RecorderStop ();
	
EndProcedure

Procedure RecorderClean ( Scenario = undefined, DateTo = undefined, Session = undefined ) export
	
	Maintenance.CleanTimelapse ( Session, Scenario, DateTo );
	
EndProcedure

Procedure ХронографОчистить ( Scenario = undefined, DateTo = undefined, Session = undefined ) export
	
	RecorderClean ( Session, Scenario, DateTo );
	
EndProcedure

&AtClient
Procedure ProgressShow () export
	
	Debugger.EnableProgress ();
	
EndProcedure

&AtClient
Procedure ПрогрессПоказать () export
	
	ProgressShow ();
	
EndProcedure

&AtClient
Procedure ProgressHide () export
	
	Debugger.DisableProgress ();
	
EndProcedure

&AtClient
Procedure ПрогрессСкрыть () export
	
	ProgressHide ();
	
EndProcedure

&AtClient
Function SystemVariable ( Name ) export
	
	return Environment.GetVariable ( Name );
	
EndFunction

&AtClient
Function ПеременнаяСреды ( Name ) export

	return SystemVariable ( Name );
	
EndFunction

&AtClient
Procedure MaximizeWindow ( Pattern = "" ) export
	
	Forms.ToggleWindow ( Pattern, true );
	
EndProcedure

&AtClient
Procedure МаксимизироватьОкно ( Pattern = "" ) export
	
	MaximizeWindow ( Pattern );
	
EndProcedure

&AtClient
Procedure MinimizeWindow ( Pattern = "" ) export
	
	Forms.ToggleWindow ( Pattern, false );
	
EndProcedure

&AtClient
Procedure МинимизироватьОкно ( Pattern = "" ) export
	
	MinimizeWindow ( Pattern );
	
EndProcedure

&AtClient
Procedure StoreScenarios ( Memo = "" ) export

	p = new Structure ( "Silent, Memo", true, Memo );
	OpenForm ( "Catalog.Scenarios.Form.Store", p, , true );

EndProcedure

&AtClient
Procedure ПоместитьСценарии ( Memo = "" ) export

	StoreScenarios ( Memo );

EndProcedure

&AtClient
Procedure RunTest ( Scenario, Application = undefined, IgnoreLocking = false ) export
	
	Test.Start( Scenario, Application, IgnoreLocking );
	
EndProcedure

&AtClient
Procedure ЗапуститьТест ( Scenario, Application = undefined, IgnoreLocking = false ) export
	
	RunTest ( Scenario, Application, IgnoreLocking );
	
EndProcedure
