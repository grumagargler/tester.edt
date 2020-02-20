Procedure Init() export

	stopWatching();
	type = "AddIn.Extender.Watcher";
	try
		lib = new (type);
	except
		return;
	endtry;
	FoldersWatchdog = new Map();
	data = WatcherSrv.MappedApplications();
	apps = data.Applications;
	folders = data.Folders;
	slash = GetPathSeparator();
	testerFolder = slash + TesterSystemFolder + slash;
	for i = 0 to apps.UBound() do
		folder = folders[i];
		DeleteFiles(folder + testerFolder, "*");
		lib = new (type);
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

Procedure Proceed(Event, Path) export

	if (myResponse(Path)
		or systemChanges(Path)) then
		return;
	elsif (externalRequest(Path)) then
		if (Event = "Added" or Event = "Changed") then
			if (newRequest(Path)) then
				proceedRequest();
			endif;
		endif;
	else
		if (Event = "Changed") then
			proceedChanging(Path);
		elsif (Event = "FolderAdded") then
			proceedCreating(Path, true);
		elsif (Event = "Added") then
			proceedCreating(Path, false);
		elsif (Event = "RenamedOld" or Event = "FolderRenamedOld") then
			TesterExternalRequestsRenaming = Path;
		elsif (Event = "RenamedNew") then
			proceedRenaming(Path, false);
		elsif (Event = "FolderRenamedNew") then
			proceedRenaming(Path, true);
		elsif (Event = "Removed" or Event = "FolderRemoved") then
			proceedRemoving(Path);
		endif;
	endif;

EndProcedure

Function myResponse(Path)

	return StrEndsWith(Path, TesterExternalResponses);

EndFunction

Function systemChanges(Path)

	return StrFind(Path, GetPathSeparator() + ".git") > 0
	or StrEndsWith(Path, TesterSystemFolder) > 0
	or StrEndsWith(Path, TesterWatcherBSLServerSettings) > 0;

EndFunction

Function externalRequest(Path)

	return StrEndsWith(Path, TesterExternalRequests);

EndFunction

Function newRequest(Path)

	request = Conversion.FromJSON(readFile(Path, RepositoryFiles.BSLFile()));
	if (TesterExternalRequestObject <> undefined
			and TesterExternalRequestObject.ID = request.ID) then
		return false;
	endif;
	TesterExternalRequestObject = request;
	TesterExternalRequestsApplication = findApplication(Path);
	return true;

EndFunction

Function findApplication(File)

	for each item in FoldersWatchdog do
		value = item.Value;
		if (StrStartsWith(File, value.Folder)) then
			return item;
		endif;
	enddo;

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
	scenario = WatcherSrv.FindScenario(syncingContext(File));
	if (scenario = undefined) then
		syncingResponse(Output.UndefinedScenario(new Structure("File", file)));
	else
		Environment.ChangeScenario(scenario);
		Watcher.SendResponse();
	endif;

EndProcedure

Function syncingContext(File, Removing = false)

	p = new Structure("Application, File, Extension, Path, Changed");
	p.Application = TesterExternalRequestsApplication.Key;
	p.File = File;
	p.Extension = FileSystem.Extension(File);
	p.Path = RepositoryFiles.FileToPath(File, StrLen(TesterExternalRequestsApplication.Value.Folder)+2);
	if (not Removing) then
		handler = new File(File);
		p.Changed = handler.GetModificationUniversalTime();
	endif;
	return p;

EndFunction

Procedure syncingResponse(Error)

	Message(Error);
	Watcher.AddMessage(Error, Enum.MessageTypesPopupWarning());
	Watcher.SendResponse();

EndProcedure

Procedure runSelected()

	file = TesterExternalRequestObject.File;
	scenario = WatcherSrv.FindScenario(syncingContext(File));
	if (scenario = undefined) then
		syncingResponse(Output.UndefinedScenario(new Structure("File", file)));
	else
		TesterExternalRequestsScenario = scenario;
		// Client session will not survive if exception happens in ExternalEvent processing
		DetachIdleHandler("TesterRunsSelectedScript");
		AttachIdleHandler("TesterRunsSelectedScript", 0.1, true);
	endif;

EndProcedure

Procedure checkSyntax()

	file = TesterExternalRequestObject.File;
	error = Runtime.CheckSyntax(readFile(file, RepositoryFiles.BSLFile()));
	if (error = undefined) then
		Watcher.AddMessage(Output.ErrorsNotFound());
	else
		Watcher.ThrowError ( error );
	endif;
	Watcher.SendResponse();

EndProcedure

Function readFile(File, Extension)

	#if ( WebClient or MobileClient ) then
		raise Output.ClientDoesNotSupport();
	#else
		timeout = CurrentDate() + 7;
		while (true) do
			try
				if (Extension = RepositoryFiles.MXLFile()) then
					return new BinaryData(File);
				else
					text = new TextReader(File, TextEncoding.UTF8, , , true);
					data = text.Read();
					return ?(data = undefined, "", data);
				endif;
			except
				if (CurrentDate() > timeout) then
					raise Output.FileReadingError(new Structure("File", File));
				endif;
			endtry;
		enddo;
	#endif

EndFunction

Procedure ThrowError(Error, Scenario=undefined, Offset=0) export
	
	range = errorRange(Error, Offset);
	Watcher.AddMessage(range.Message, Enum.MessageTypesError(), Scenario, range.Line, range.Column);
	
EndProcedure

Function errorRange(Text, Offset)
	
	i = StrFind(Text, "{(");
	j = StrFind(Text, ")}");
	core = Mid(Text, i + 2, j - i - 2);
	parts = StrSplit(core, ",");
	message = Mid(Text, j + 4);
	return new Structure("Message, Line, Column", message, Offset + parts[0], parts[1]);
	
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
		scenario = WatcherSrv.FindScenario(syncingContext(File));
		if (scenario = undefined) then
			syncingResponse(Output.UndefinedScenario(new Structure("File", file)));
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

Procedure proceedChanging(File)

	if (not validFile(File, false)) then
		return;
	endif;
	TesterExternalRequestsApplication = findApplication(File);
	error = undefined;
	context = syncingContext(File);
	scenario = WatcherSrv.Update(context, readFile(File, context.Extension), error);
	if (error <> undefined) then
		syncingResponse(error);
		return;
	endif;
	if (scenario <> undefined) then
		broadcast(scenario);
	endif;
	if (savingRequest(File)) then
		comleteSaving();
	endif;

EndProcedure

Function validFile(File, IsFolder)

	if (IsFolder) then
		return StrFind(File, ".") = 0;
	else
		ext = FileSystem.Extension(File);
		return ext = RepositoryFiles.BSLFile()
		or ext = RepositoryFiles.MXLFile()
		or ext = RepositoryFiles.JSONFile();
	endif;

EndFunction

Procedure broadcast(Them)

	DetachIdleHandler("TesterWatcherBroadcasting");
	TesterExternalBroadcasting = them;
	AttachIdleHandler("TesterWatcherBroadcasting", 0.5, true);

EndProcedure

Function savingRequest(File)

	return TesterExternalRequestObject <> undefined
		and (TesterExternalRequestObject.Request = Enum.ExternalRequestsSaveBeforeCheckSyntax()
		or TesterExternalRequestObject.Request = Enum.ExternalRequestsSaveBeforeRun()
		or TesterExternalRequestObject.Request = Enum.ExternalRequestsSaveBeforeRunSelected()
		or TesterExternalRequestObject.Request = Enum.ExternalRequestsSaveBeforeAssigning())
		and Lower(TesterExternalRequestObject.File) = Lower(File);

EndFunction

Procedure comleteSaving()

	response = prepareResponse();
	response.TransactionComplete = true;
	TesterExternalRequestObject = undefined;
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

Procedure proceedCreating(File, IsFolder)

	if (not validFile(File, IsFolder)) then
		return;
	endif;
	TesterExternalRequestsApplication = findApplication(File);
	if (not checkName(File)) then
		return;
	endif;
	error = undefined;
	context = syncingContext(File);
	changes = WatcherSrv.Create(context, IsFolder, error);
	if (error <> undefined) then
		syncingResponse(error);
		return;
	endif;
	if (IsFolder) then
		uploadFiles(File);
	endif;
	broadcast(changes);

EndProcedure

Function checkName(Name)

	if (not ScenarioForm.CheckName(RepositoryFiles.FileToName(Name))) then
		error = Output.WatcherFileNameError(new Structure("File", Name));
		syncingResponse(error);
		return false;
	endif;
	return true;

EndFunction

Procedure uploadFiles(Folder)

	files = FindFiles(Folder, "*.*");
	for each file in files do
		isFolder = file.IsDirectory();
		path = file.FullName;
		proceedCreating(path, isFolder);
		if (not isFolder) then
			proceedChanging(path);
		endif;
	enddo;

EndProcedure

Procedure proceedRenaming(NewFile, IsFolder)

	if (not validFile(NewFile, IsFolder)) then
		return;
	endif;
	oldFile = TesterExternalRequestsRenaming;
	if ( not validFile(oldFile, IsFolder) ) then
		proceedCreating(NewFile, IsFolder);
		proceedChanging(NewFile);
		return;
	endif;
	TesterExternalRequestsApplication = findApplication(oldFile);
	if (not checkName(NewFile)) then
		return;
	endif;
	if (renamingDirFile()) then
		error = Output.WatcherRenamingFolderError(new Structure("File", oldFile));
		syncingResponse(error);
		return;
	elsif ( renamingDependencies ( IsFolder, NewFile ) ) then
		return;
	endif;
	error = undefined;
	context = syncingContext(oldFile, true);
	scenario = WatcherSrv.Rename(context, NewFile, RepositoryFiles.FileToPath(NewFile, StrLen(TesterExternalRequestsApplication.Value.Folder)+2), IsFolder, error);
	if (error <> undefined) then
		syncingResponse(error);
		return;
	endif;
	broadcast(scenario);
	syncRenaming(NewFile, IsFolder);

EndProcedure

Function renamingDirFile()

	oldFile = TesterExternalRequestsRenaming;
	renameFolder = StrFind(oldFile, RepositoryFiles.FolderSuffix());
	if (renameFolder) then
		folder = FileSystem.GetParent(FileSystem.GetParent(oldFile)) + GetPathSeparator() + RepositoryFiles.FileToName(oldFile);
		folders = FindFiles(folder);
		if (folders.Count() = 1) then
			return true;
		endif;
	endif;
	return false;

EndFunction

Function renamingDependencies ( IsFolder, NewFile )
	
	return not IsFolder and StrFind ( NewFile, RepositoryFiles.FolderSuffix () )
	
EndFunction

Procedure syncRenaming(NewFile, IsFolder)

	oldFile = TesterExternalRequestsRenaming;
	folderSuffix = RepositoryFiles.FolderSuffix();
	oldName = FileSystem.GetBaseName(FileSystem.GetFileName(OldFile));
	newName = FileSystem.GetBaseName(FileSystem.GetFileName(NewFile));
	if (IsFolder) then
		suffix = folderSuffix;
		files = FindFiles(NewFile, oldName + ".*");
	else
		suffix = "";
		files = FindFiles(FileSystem.GetParent(NewFile), oldName + ".*");
	endif;
	for each file in files do
		if (not IsFolder and StrFind(file.Name, folderSuffix) > 0) then
			continue;
		endif;
		MoveFile(file.FullName, file.Path + newName + suffix + file.Extension);
	enddo;

EndProcedure

Procedure proceedRemoving(File)

	if (not validRemoving(File)) then
		return;
	endif;
	TesterExternalRequestsApplication = findApplication(File);
	error = undefined;
	context = syncingContext(File, true);
	scenario = WatcherSrv.Remove(context, error);
	if (error <> undefined) then
		syncingResponse(error);
		return;
	endif;
	broadcast(scenario);

EndProcedure

Function validRemoving(File)

	ext = FileSystem.Extension(File);
	return ext = RepositoryFiles.BSLFile() or ext = RepositoryFiles.MXLFile()
		or ext = RepositoryFiles.JSONFile() or ext = "";

EndFunction

Procedure SendResponse(Response = undefined) export

	#if ( WebClient ) then
	raise Output.WebClientDoesNotSupport();
	#else
	path = TesterExternalRequestsApplication.Value.Folder + GetPathSeparator() + TesterExternalResponses;
	file = new File(FileSystem.GetParent(path));
	if ( not file.Exist() ) then
		return;
	endif;
	if (Response = undefined) then
		answer = prepareResponse();
	else
		answer = Response;
	endif;
	writer = new TextWriter(path);
	answer.Messages = TesterServerMessages;
	writer.Write(Conversion.ToJSON(answer, false));
	TesterServerMessages = undefined;
	#endif

EndProcedure

Procedure AddMessage(Text, Type = undefined, Scenario = undefined, Line = 1,
		Column = 1) export

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
