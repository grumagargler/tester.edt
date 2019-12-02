&AtClient
var TableRow export;
&AtServer
var DeletionType;
&AtServer
var Node;
&AtServer
var CurrentData;
&AtServer
var CurrentApplication;
&AtServer
var DataType;
&AtServer
var PathFinder;
&AtServer
var RemovingSet;
&AtClient
var FolderSuffix;
&AtClient
var MXLExtension;
&AtClient
var ContinueUnloading;
&AtClient
var CurrentIndex;
&AtClient
var LastIndex;
&AtClient
var Roots;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	saveChangesOnly ();
	loadRepositories ();
	
EndProcedure

&AtServer
Procedure saveChangesOnly ()
	
	Object.Changes = true;

EndProcedure 

&AtServer
Procedure loadRepositories ()
	
	if ( silentMode ( Parameters ) ) then
		s = "
		|select &Application as Application, Repositories.Folder as Folder, true as Use, Nodes.Ref as Node
		|from ExchangePlan.Changes as Nodes
		|	//
		|	// Repositories
		|	//
		|	left join InformationRegister.Repositories as Repositories
		|	on Repositories.User = &User
		|	and Repositories.Computer = &Computer
		|	and Repositories.Application = &Application
		|where Nodes.User = &User
		|and Nodes.Application = &Application
		|and not Nodes.DeletionMark
		|";
	else
		s = "
		|select allowed Applications.Ref as Application, Repositories.Folder as Folder,
		|	case when Settings.Application is null then false else true end as Use,
		|	Nodes.Ref as Node
		|from (
		|	select value ( Catalog.Applications.EmptyRef ) as Ref
		|	union all
		|	select Applications.Ref
		|	from Catalog.Applications as Applications
		|	where not Applications.DeletionMark
		|	and not Applications.IsFolder
		|	) as Applications
		|	//
		|	// Repositories
		|	//
		|	left join InformationRegister.Repositories as Repositories
		|	on Repositories.User = &User
		|	and Repositories.Computer = &Computer
		|	and Repositories.Application = Applications.Ref
		|	//
		|	// Settings
		|	//
		|	left join InformationRegister.Applications as Settings
		|	on Settings.User = &User
		|	and Settings.Application = Applications.Ref
		|	//
		|	// Nodes
		|	//
		|	join ExchangePlan.Changes as Nodes
		|	on Nodes.User = &User
		|	and Nodes.Application = Applications.Ref
		|	and not Nodes.DeletionMark
		|order by Application
		|";
	endif;
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Computer", SessionData.Computer () );
	q.SetParameter ( "Application", Parameters.Application );
	Object.Repositories.Load ( q.Execute ().Unload () );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	setConstants ();
	RepositoryForm.SetFocus ( ThisObject );
	LocalFiles.Prepare ();
	if ( silentMode ( Parameters ) ) then
		if ( CheckFilling () ) then
			Cancel = true;
			startUnloading ();
		endif;
	endif;

EndProcedure

&AtClient
Procedure setConstants ()
	
	Slash = GetPathSeparator ();
	FolderSuffix = RepositoryFiles.FolderSuffix ();
	MXLExtension = RepositoryFiles.MXLFile ();
	
EndProcedure 

&AtClientAtServerNoContext
Function silentMode ( Parameters )
	
	return Parameters.Application <> undefined;
	
EndFunction

&AtClient
Procedure startUnloading ()
	
	prepareScenarios ();
	prepareCounters ();
	getRoots ();
	toggleWatching ( false );
	createSystemFolders ();
	unloadScenarios ();
	
EndProcedure

&AtServer
Procedure prepareScenarios ()
	
	init ();
	RepositoryForm.SavePaths ( Object );
	fillScenarios ();
	
EndProcedure 

&AtServer
Procedure init ()
	
	DeletionType = Type ( "ObjectDeletion" );
	PathFinder = getPathFinder ();
	
EndProcedure 

&AtServer
Function getPathFinder ()
	
	s = "
	|select top 1 1
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Path = &Path
	|and Scenarios.Application = &Application
	|and Scenarios.Tree = &Tree
	|and not Scenarios.DeletionMark
	|";
	return new Query ( s );
	
EndFunction 

&AtServer
Procedure fillScenarios ()
	
	ScenariosCounter = 0;
	RemovingSet = new Array ();
	AllScenarios.Clear ();
	for each repository in Object.Repositories do
		if ( not repository.Use ) then
			continue;
		endif; 
		Node = repository.Node;
		CurrentApplication = repository.Application;
		changes = getChanges ();
		while ( changes.Next () ) do
			try // there is no way to avoid RLS restrictions
				CurrentData = changes.Get ();
			except
				continue;
			endtry; 
			DataType = TypeOf ( CurrentData );
			if ( DataType = DeletionType
				or CurrentData.DeletionMark ) then
				addDeletion ();
			else
				if ( CurrentData.Application = CurrentApplication ) then
					addRenaming ();
					addScenario ();
				endif; 
			endif; 
		enddo;
	enddo;
	AllScenarios.Sort ( "Application, Delete desc" );
	RemovingIDs = new FixedArray ( RemovingSet );

EndProcedure 

&AtServer
Function getChanges ()
	
	if ( not Object.Changes ) then
		ExchangePlans.Changes.Reset ( Node );
	endif; 
	return ExchangePlans.SelectChanges ( Node, Node.SentNo );
	
EndFunction 

&AtServer
Procedure addDeletion ()
	
	if ( DataType = DeletionType ) then
		id = CurrentData.Ref.UUID ();
		RemovingSet.Add ( id );
		r = InformationRegisters.Removing.Get ( new Structure ( "User, ID", SessionParameters.User, id ) );
		if ( r.Application <> CurrentApplication ) then
			return;
		endif; 
		path = r.Path;
		tree = r.Tree;
		type = r.Type;
	else
		path = CurrentData.Path;
		tree = CurrentData.Tree;
		type = CurrentData.Type;
	endif;
	if ( scenarioRecreated ( path, tree ) ) then
		return;
	endif; 
	row = AllScenarios.Add ();
	row.Application = CurrentApplication;
	row.Delete = deletedFile ( path, tree, type );
	ScenariosCounter = ScenariosCounter + 1;

EndProcedure

&AtServer
Function deletedFile ( Path, Tree, Type )
	
	return StrReplace ( Path, ".", Slash ) + RepositoryFiles.TypeToExtension ( Type );
	
EndFunction 

&AtServer
Function scenarioRecreated ( Path, Tree )
	
	PathFinder.SetParameter ( "Path", Path );
	PathFinder.SetParameter ( "Application", CurrentApplication );
	PathFinder.SetParameter ( "Tree", Tree );
	return not PathFinder.Execute ().IsEmpty ();
	
EndFunction 

&AtServer
Procedure addRenaming ()
	
	id = CurrentData.Ref.UUID ();
	RemovingSet.Add ( id );
	r = InformationRegisters.Removing.Get ( new Structure ( "User, ID", SessionParameters.User, id ) );
	path = r.Path;
	tree = r.Tree;
	if ( path = ""
		or scenarioRecreated ( path, tree ) ) then
		return;
	endif; 
	row = AllScenarios.Add ();
	row.Application = CurrentApplication;
	row.Delete = deletedFile ( path, tree, r.Type );
		
EndProcedure 

&AtServer
Procedure addScenario ()
	
	row = AllScenarios.Add ();
	row.Application = CurrentApplication;
	row.Scenario = CurrentData.Ref;
	ScenariosCounter = ScenariosCounter + 1;

EndProcedure 

&AtClient
Procedure prepareCounters ()
	
	CurrentIndex = -1;
	LastIndex = AllScenarios.Count () - 1;
	initProgress ();
	ContinueUnloading = new NotifyDescription ( "ContinueUnloading", ThisObject );
	
EndProcedure 

&AtClient
Procedure initProgress ()
	
	ProgressBar = 0;
	Items.ProgressBar.MaxValue = 1 + LastIndex;
	Items.ProgressBar.ShowPercent = true;
	
EndProcedure 

&AtClient
Procedure getRoots ()
	
	Roots = new Map ();
	for each row in Object.Repositories do
		if ( row.Use ) then
			roots [ row.Application ] = row.Folder;
		endif; 
	enddo; 
	
EndProcedure

&AtClient
Procedure toggleWatching ( On )
	
	if ( FoldersWatchdog = undefined ) then
		return;
	endif;
	for each root in Roots do
		entry = FoldersWatchdog [ root.Key ];
		if ( entry <> undefined ) then
			if ( On ) then
				entry.Lib.Start ( entry.Folder );
			else
				entry.Lib.Stop ();
			endif;
		endif;
	enddo;
	
EndProcedure

&AtClient
Procedure createSystemFolders ()
	
	folder = RepositoryFiles.SystemFolder ();
	stub = new NotifyDescription ( "Stub", ThisObject );
	for each root in Roots do
		BeginCreatingDirectory ( stub, root.Value + slash + folder );
	enddo;
	
EndProcedure

&AtClient
Procedure Stub ( Result, Params ) export
	
	//@skip-warning
	noerrors = true;
	
EndProcedure

&AtClient
Procedure ContinueUnloading ( Result ) export
	
	unloadScenarios ();
	
EndProcedure 

&AtClient
Procedure unloadScenarios ()
	
	CurrentIndex = CurrentIndex + 1;
	ProgressBar = ProgressBar + 1;
	RefreshDataRepresentation ( Items.ProgressBar );
	if ( CurrentIndex > LastIndex ) then
		deleteRecords ();
		toggleWatching ( true );
		showInfo ();
		return;
	endif; 
	row = AllScenarios [ CurrentIndex ];
	root = Roots [ row.Application ];
	if ( row.Delete = "" ) then
		data = scenarioData ( row.Scenario );
		p = new Structure ( "Root, Data", root, data );
		createFolder ( p );
	else
		BeginDeletingFiles ( ContinueUnloading, root + Slash + row.Delete );
	endif; 
	
EndProcedure 

&AtServer
Procedure deleteRecords ()
	
	for each repository in Object.Repositories do
		if ( repository.Use ) then
			Node = repository.Node;
			ExchangePlans.DeleteChangeRecords ( Node, Node.ReceivedNo );
		endif; 
	enddo; 
	commitRemoving ();
	
EndProcedure 

&AtServer
Procedure commitRemoving ()
	
	user = SessionParameters.User;
	for each id in RemovingIDs do
		r = InformationRegisters.Removing.CreateRecordManager ();
		r.User = user;
		r.ID = id;
		r.Delete ();
	enddo; 
	
EndProcedure 

&AtClient
Procedure showInfo ()
	
	p = new Structure ( "Counter", Format ( ScenariosCounter, "NZ=; NG=" ) );
	if ( silentMode ( Parameters ) ) then
		Output.ScenariosProcessedNotification ( p );
	else
		Output.ScenariosProcessed ( ThisObject, , p );
	endif;
	
EndProcedure 

&AtClient
Procedure ScenariosProcessed ( Params ) export
	
	Close ();
	
EndProcedure 

&AtServerNoContext
Function scenarioData ( val Scenario )
	
	data = new Structure ();
	data.Insert ( "Path", Scenario.Path );
	data.Insert ( "Script", Scenario.Script );
	data.Insert ( "Spreadsheet", Scenario.Spreadsheet );
	data.Insert ( "Template", getTemplate ( Scenario ) );
	data.Insert ( "Type", Scenario.Type );
	data.Insert ( "Tree", Scenario.Tree );
	changed = Scenario.Changed;
	data.Insert ( "Changed", ? ( changed = Date ( 1, 1, 1 ), Date ( 2000, 1, 1 ), changed ) );
	return data;
	
EndFunction 

&AtServerNoContext
Function getTemplate ( Scenario )
	
	tabDoc = Scenario.Template.Get ();
	if ( Scenario.Spreadsheet ) then
		anchor = tabDoc.TableHeight + 1;
		tabDoc.Area ( anchor, 1, anchor, 1 ).Text = RepositoryFiles.Signature ();
		anchor = anchor + 1;
		tabDoc.Area ( anchor, 1, anchor, 1 ).Text = serializeAreas ( Scenario );
	endif; 
	return tabDoc;

EndFunction 

&AtServerNoContext
Function serializeAreas ( Scenario )
	
	parts = new Array ();
	for each area in Scenario.Areas do
		fields = new Structure ( "Name, Top, Left, Bottom, Right" );
		FillPropertyValues ( fields, area );
		parts.Add ( fields );
	enddo; 
	return Conversion.ToJSON ( parts, false );
	
EndFunction 

&AtClient
Procedure createFolder ( Params )
	
	data = Params.Data;
	path = data.Path;
	if ( data.Tree ) then
		folder = Params.Root + Slash + StrReplace ( path, ".", Slash );
	else
		folder = Left ( path, StrFind ( path, ".", SearchDirection.FromEnd ) - 1 );
		folder = Params.Root + Slash + StrReplace ( folder, ".", Slash );
	endif; 
	BeginCreatingDirectory ( new NotifyDescription ( "CreatingDirectory", ThisObject, Params ), folder );

EndProcedure 

&AtClient
Procedure CreatingDirectory ( Folder, Params ) export
	
	createScript ( Params );
	
EndProcedure 

&AtClient
Procedure createScript ( Params )
	
	baseName = getBaseName ( Params );
	data = Params.Data;
	file = baseName + RepositoryFiles.TypeToExtension ( data.Type );
	p = new Structure ( "File, Params", file, Params );
	doc = new TextDocument ();
	doc.SetText ( data.Script );
	doc.BeginWriting ( new NotifyDescription ( "ScriptCreated", ThisObject, p ), file );
		
EndProcedure 

&AtClient
Function getBaseName ( Params )
	
	data = Params.Data;
	path = data.Path;
	file = Params.Root + Slash + StrReplace ( path, ".", Slash );
	if ( data.Tree ) then
		dirname = Mid ( path, 1 + StrFind ( path, ".", SearchDirection.FromEnd ) ) + FolderSuffix;
		file = file + Slash + dirname;
	endif;
	return file;
	
EndFunction 

&AtClient
Procedure ScriptCreated ( Result, Params ) export
	
	p = Params.Params;
	callback = new NotifyDescription ( "SettingModificationUniversalTime", ThisObject, p );
	file = new File ( Params.File );
	file.BeginSettingModificationUniversalTime ( callback, p.Data.Changed );

EndProcedure 

&AtClient
Procedure SettingModificationUniversalTime ( Params ) export
	
	createSpreadsheet ( Params );
	
EndProcedure 

&AtClient
Procedure createSpreadsheet ( Params )
	
	baseName = getBaseName ( Params );
	file = baseName + MXLExtension;
	data = Params.Data;
	if ( data.Spreadsheet ) then
		data.Template.Write ( file );
		modifyFile ( file, data.Changed );
		unloadScenarios ();
	else
		BeginDeletingFiles ( ContinueUnloading, file );
	endif; 
		
EndProcedure 

&AtClient
Procedure modifyFile ( File, Date )
	
	file = new File ( File );
	file.SetModificationUniversalTime ( Date );
	
EndProcedure 

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not RepositoryForm.CheckSelection ( Object ) ) then
		Cancel = true;
	endif; 
	if ( not RepositoryForm.CheckFolders ( Object ) ) then
		Cancel = true;
	endif; 
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Unload ( Command )
	
	if ( CheckFilling () ) then
		startUnloading ();
	endif;

EndProcedure

// *****************************************
// *********** Table Repositories

&AtClient
Procedure MarkAll ( Command )
	
	checkbox ( true );
	
EndProcedure

&AtClient
Procedure checkbox ( Value )
	
	for each row in Object.Repositories do
		row.Use = Value;
	enddo; 
	
EndProcedure 

&AtClient
Procedure UnmarkAll ( Command )
	
	checkbox ( false );
	
EndProcedure

&AtClient
Procedure RepositoriesOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ReporitoriesFolderStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	RepositoryForm.ChooseFolder ( ThisObject );
	
EndProcedure

&AtClient
Procedure ReporitoriesFolderOnChange ( Item )
	
	RepositoryForm.ApplyFolder ( ThisObject );
	
EndProcedure

&AtClient
Procedure RepositoriesBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure RepositoriesBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure
