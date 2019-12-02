Procedure Init() export
	
	stopWatching();
	type = "AddIn.Extender.Watcher";
	try
		lib = new(type);
	except
		return;
	endtry;
	FoldersWatchdog = new Map();
	data = WatcherSrv.MappedApplications();
	apps = data.Applications;
	folders = data.Folders;
	slash = GetPathSeparator();
	testerFolder = slash + RepositoryFiles.SystemFolder() + slash;
	for i = 0 to apps.UBound() do
		folder = folders[i];
		DeleteFiles(folder + testerFolder, "*");
		lib = new(type);
		FoldersWatchdog[apps[i]] = new Structure("Lib, Folder", lib, folder);
		lib.Start(folder);
	enddo;
	
EndProcedure

Procedure stopWatching()
	
	if (FoldersWatchdog = undefined) then
		return;
	endif;
	for each item in FoldersWatchdog do
		// There is only one right way to clean the mess properly:
		// - stop thread
		// - execute destructor
		item.Value.Lib.Stop();
		item.Value.Lib = undefined;
	enddo;
	FoldersWatchdog = undefined;
	
EndProcedure

Function SystemFolder() export
	
	return ".tester" + GetPathSeparator();
	
EndFunction

Procedure Proceed(Event, Path) export
	
	if (myResponse(Path)) then
		return;
	elsif (externalRequest(Path)) then
		if (Event = "Added"
				or Event = "Changed") then
			if (newRequest(Path)) then
				proceedRequest();
			endif;
		endif;
	else
		if (Event = "Changed") then
			proceedFile(Path);
		endif;
	endif;
	
EndProcedure

Function myResponse(Path)
	
	return StrEndsWith(Path, TesterExternalResponses);
	
EndFunction

Function externalRequest(Path)
	
	return StrEndsWith(Path, TesterExternalRequests);
	
EndFunction

Function newRequest(Path)
	
	request = Conversion.FromJSON(readFile(Path));
	if (TesterExternalRequestObject <> undefined
			and TesterExternalRequestObject.ID = request.ID) then
		return false;
	endif;
	TesterExternalRequestObject = request;
	TesterExternalRequestsApplication = findApplication(Path);
	return true;
	
EndFunction

Procedure proceedRequest()
	
	request = TesterExternalRequestObject.Request;
	if (request = Enum.ExternalRequestsRun()) then
		runTesting();
	elsif (request = Enum.ExternalRequestsRunSelected()) then
		runSelected();
	else
		TesterServerMode = true;
		if (request = Enum.ExternalRequestsSaveBeforeCheckSyntax()
				or request = Enum.ExternalRequestsSaveBeforeRun()
				or request = Enum.ExternalRequestsSaveBeforeRunSelected()
				or request = Enum.ExternalRequestsSaveBeforeAssigning()) then
			Watcher.SendResponse();
		elsif (request = Enum.ExternalRequestsSetMain()) then
			setMain();
		elsif (request = Enum.ExternalRequestsCheckSyntax()) then
			checkSyntax();
		elsif (request = Enum.ExternalRequestsPickField()) then
			pickField();
		elsif (request = Enum.ExternalRequestsPickScenario()) then
			pickScenario();
		elsif (request = Enum.ExternalRequestsGenerateID()) then
			generateID();
		else
			undefinedRequest();
		endif;
		TesterServerMode = false;
	endif;
	
EndProcedure

Procedure runTesting()
	
	// Client session will not survive if exception happens in ExternalEvent processing
	DetachIdleHandler("TesterRunsMainScenario");
	AttachIdleHandler("TesterRunsMainScenario", 0.1, true);
	
EndProcedure

Procedure setMain()
	
	file = TesterExternalRequestObject.File;
	scenario = findScenario(file);
	if (scenario = undefined) then
		undefinedScenario(File, Enum.ExternalRequestsSaveFile());
		return;
	endif;
	Environment.ChangeScenario(scenario);
	Watcher.SendResponse();
	
EndProcedure

Procedure runSelected()
	
	file = TesterExternalRequestObject.File;
	scenario = findScenario(file);
	if (scenario = undefined) then
		undefinedScenario(File, Enum.ExternalRequestsSaveFile());
		return;
	endif;
	TesterExternalRequestsScenario = scenario;
	// Client session will not survive if exception happens in ExternalEvent processing
	DetachIdleHandler("TesterRunsSelectedScript");
	AttachIdleHandler("TesterRunsSelectedScript", 0.1, true);
	
EndProcedure

Procedure checkSyntax()
	
	file = TesterExternalRequestObject.File;
	error = Test.FindError(readFile(file));
	if (error = undefined) then
		Watcher.AddMessage(Output.ErrorsNotFound());
	endif;
	Watcher.SendResponse();
	
EndProcedure

Function readFile(File)
	
	#if ( WebClient ) then
	raise Output.WebClientDoesNotSupport();
	#else
	timeout = CurrentDate() + 7;
	while (true) do
		try
			text = new TextReader(File, TextEncoding.UTF8, , , true);
			return text.Read();
		except
			if (CurrentDate() > timeout) then
				raise Output.FileReadingError(new Structure("File", File));
			endif;
		endtry;
	enddo;
	#endif
	
EndFunction

Procedure pickField()
	
	response = prepareResponse();
	try
		Test.Attach();
		ok = true;
	except
		error = BriefErrorDescription(ErrorInfo());
		ok = false;
	endtry;
	if (ok) then
		insertFields(response);
	else
		Watcher.AddMessage(error, Enum.MessageTypesPopupWarning());
	endif;
	Watcher.SendResponse(response);
	
EndProcedure

Procedure insertFields(Response)
	
	result = new Structure("Set, Language, Current");
	controls = getControls();
	if (controls <> undefined) then
		FillPropertyValues(result, controls);
	endif;
	result.Language = CurrentLanguage();
	Response.Insert("Fields", result);
	
EndProcedure

Function getControls()
	
	set = new Array();
	try
		objects = App.GetActiveWindow().FindObjects();
	except
		Watcher.AddMessage(ErrorDescription(), Enum.MessageTypesPopupWarning());
		return undefined;
	endtry;
	currentItem = undefined;
	currentControl = undefined;
	for each control in objects do
		field = new Structure("Name, Type, TitleText, TypeDescription");
		FillPropertyValues(field, control);
		field.Type = ScenarioForm.FieldType(control, true);
		type = ScenarioForm.FieldType(control);
		if (type = PredefinedValue("Enum.Controls.Form")) then
			field.Name = "<" + control.FormName + ">";
			try
				currentItem = control.GetCurrentItem();
			except
				currentItem = undefined;
			endtry;
		endif;
		field.TypeDescription = String(type);
		text = control.TitleText;
		field.TitleText = text;
		if (field.Name = undefined) then
			field.Name = text;
		endif;
		if (currentItem = control) then
			currentControl = field.Name;
		endif;
		set.Add(field);
	enddo;
	return new Structure("Set, Current", set, currentControl);
	
EndFunction

Procedure pickScenario()
	
	if (TesterExternalRequestObject.Method = "Run") then
		file = TesterExternalRequestObject.File;
		scenario = findScenario(file);
		if (scenario = undefined) then
			undefinedScenario(file, Enum.ExternalRequestsPickScenario());
			return;
		endif;
	else
		scenario = undefined;
	endif;
	response = prepareResponse();
	response.Insert("Scenarios", WatcherSrv.GetMethods(scenario));
	Watcher.SendResponse(response);
	
EndProcedure

Procedure generateID()
	
	response = prepareResponse();
	response.Insert("GeneratedID", Environment.GenerateID());
	Watcher.SendResponse(response);
	
EndProcedure

Procedure undefinedRequest()
	
	Watcher.AddMessage(Output.UndefinedExternalRequest(), Enum.MessageTypesPopupWarning());
	Watcher.SendResponse();
	
EndProcedure

Procedure proceedFile(File)
	
	ext = FileSystem.Extension(File);
	if (ext = RepositoryFiles.BSLFile()) then
		TesterExternalRequestsApplication = findApplication(File);
		scenario = findScenario(File);
		if (scenario = undefined) then
			undefinedScenario(File, Enum.ExternalRequestsSaveFile());
			return;
		endif;
		if (WatcherSrv.Update(scenario, readFile(File))) then
			broadcast(scenario);
		endif;
		if (savingRequest(File)) then
			comleteSaving();
		endif;
	endif;
	
EndProcedure

Function findApplication(File)
	
	for each item in FoldersWatchdog do
		value = item.Value;
		if (StrStartsWith(File, value.Folder)) then
			return item;
		endif;
	enddo;
	
EndFunction

Function findScenario(File)
	
	slash = GetPathSeparator();
	source = Lower(File);
	path = Lower(Mid(source, 1, StrFind(source, ".", SearchDirection.FromEnd, , 2) - 1));
	if (StrEndsWith(path, RepositoryFiles.FolderSuffix())) then
		path = Mid(source, 1, StrFind(source, slash, SearchDirection.FromEnd) - 1);
	endif;
	path = StrReplace(StrReplace(path, Lower(TesterExternalRequestsApplication.Value.Folder) + slash, ""), slash, ".");
	scenario = RuntimeSrv.FindScenario(path, undefined, TesterExternalRequestsApplication.Key, undefined, true);
	return scenario;
	
EndFunction

Procedure undefinedScenario(File, Request)
	
	response = prepareResponse();
	response.Insert("Request", new Structure("Request", Request));
	Watcher.AddMessage(Output.UndefinedScenario(new Structure("File", File)), Enum.MessageTypesError(), File);
	Watcher.SendResponse(response);
	
EndProcedure

Function prepareResponse()
	
	response = new Structure();
	if (TesterExternalRequestObject <> undefined) then
		response.Insert("Request", Collections.CopyStructure(TesterExternalRequestObject));
	endif;
	response.Insert("Status", Enum.ExternalStatusesCompleted());
	response.Insert("TransactionComplete", false);
	response.Insert("Messages");
	return response;
	
EndFunction

Procedure broadcast(Scenario)
	
	list = new Array();
	list.Add(Scenario);
	Notify(Enum.MessageReload(), list);
	NotifyChanged(Type("CatalogRef.Scenarios"));
	
EndProcedure

Function savingRequest(File)
	
	return TesterExternalRequestObject <> undefined
	and (TesterExternalRequestObject.Request = Enum.ExternalRequestsSaveBeforeCheckSyntax()
			or TesterExternalRequestObject.Request = Enum.ExternalRequestsSaveBeforeRun()
			or TesterExternalRequestObject.Request = Enum.ExternalRequestsSaveBeforeRunSelected()
			or TesterExternalRequestObject.Request = Enum.ExternalRequestsSaveBeforeAssigning())
		and TesterExternalRequestObject.File = File;
	
EndFunction

Procedure comleteSaving()
	
	response = prepareResponse();
	response.TransactionComplete = true;
	TesterExternalRequestObject = undefined;
	Watcher.SendResponse(response);
	
EndProcedure

Procedure SendResponse(Response = undefined) export
	
	#if ( WebClient ) then
	raise Output.WebClientDoesNotSupport();
	#else
	if (Response = undefined) then
		answer = prepareResponse();
	else
		answer = Response;
	endif;
	path = TesterExternalRequestsApplication.Value.Folder + GetPathSeparator() + TesterExternalResponses;
	writer = new TextWriter(path);
	answer.Messages = TesterServerMessages;
	writer.Write(Conversion.ToJSON(answer, false));
	TesterServerMessages = undefined;
	#endif
	
EndProcedure

Procedure AddMessage(Text, Type = undefined, Scenario = undefined, Line = 1, Column = 1) export
	
	if (Scenario = undefined) then
		file = undefined;
	else
		file = scenarioFile(Scenario);
		if (file = undefined) then
			return;
		endif;
	endif;
	if (TesterServerMessages = undefined) then
		TesterServerMessages = new Array();
	endif;
	messageType = ?(Type = undefined, Enum.MessageTypesPopup(), Type);
	p = new Structure("Text, Type, File, Line, Column", Text, messageType, file, Line, Column);
	TesterServerMessages.Add(p);
	
EndProcedure

Function scenarioFile(Scenario)
	
	if (TypeOf(Scenario) = Type("String")) then
		return Scenario;
	endif;
	error = "";
	file = RepositoryFiles.ScenarioToFile(Scenario, error);
	if (file = undefined) then
		Watcher.AddMessage(error, Enum.MessageTypesPopupWarning());
	else
		return file;
	endif;
	
EndFunction

