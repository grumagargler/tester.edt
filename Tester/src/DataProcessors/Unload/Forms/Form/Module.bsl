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
var ChildHunter;
&AtServer
var RemovingSet;
&AtClient
var FolderSuffix;
&AtClient
var MXLExtension;
&AtClient
var JSONExtension;
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
		s = "select Repositories.Application as Application, Repositories.Folder as Folder, true as Use, Repositories.Ref as Node
		|from ExchangePlan.Repositories as Repositories
		|where Repositories.Session = &Session
		|and not Repositories.DeletionMark
		|and Repositories.Mapping";
	else
		s = "select allowed Repositories.Application as Application, Repositories.Folder as Folder,
		|	case when Settings.Application is null then false else true end as Use, Repositories.Ref as Node
		|from ExchangePlan.Repositories as Repositories
		|	//
		|	// Settings
		|	//
		|	left join InformationRegister.Applications as Settings
		|	on Settings.User = &User
		|	and Settings.Application = Repositories.Application
		|where Repositories.Session = &Session
		|and not Repositories.DeletionMark
		|order by Application";
	endif;
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Session", SessionParameters.Session );
	Object.Repositories.Load ( q.Execute ().Unload () );
	
EndProcedure 

&AtClientAtServerNoContext
Function silentMode ( Parameters )
	
	return Parameters.Silent;
	
EndFunction

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
	JSONExtension = RepositoryFiles.JSONFile ();
	
EndProcedure 

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
	fillScenarios ();
	
EndProcedure 

&AtServer
Procedure init ()
	
	DeletionType = Type ( "ObjectDeletion" );
	PathFinder = getPathFinder ();
	ChildHunter = getChildHunter ();
	
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
Function getChildHunter ()

	s = "
	|select top 1 1
	|from Catalog.Scenarios as Scenarios
	|where not Scenarios.DeletionMark
	|and Scenarios.Parent = &Ref
	|and Scenarios.Application = &Application";
	return new Query ( s );

EndFunction

&AtServer
Procedure fillScenarios ()
	
	ScenariosCounter = 0;
	RemovingSet = new Array ();
	ChangedScenarios.Clear ();
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
				addRenaming ();
				if ( CurrentData.Application = CurrentApplication ) then
					addScenario ();
				endif; 
			endif; 
		enddo;
	enddo;
	ChangedScenarios.Sort ( "Application, Delete desc" );
	RemovingIDs = new FixedArray ( RemovingSet );

EndProcedure 

&AtServer
Function getChanges ()
	
	if ( not Object.Changes ) then
		ExchangePlans.Repositories.Reset ( Node );
	endif; 
	return ExchangePlans.SelectChanges ( Node, Node.SentNo );
	
EndFunction 

&AtServer
Procedure addDeletion ()
	
	if ( DataType = DeletionType ) then
		id = CurrentData.Ref.UUID ();
		r = InformationRegisters.Removing.Get ( new Structure ( "Repository, ID", Node, id ) );
		if ( r.path = "" ) then
			return;
		endif; 
		RemovingSet.Add ( new Structure ( "ID, Repository", id, Node ) );
		path = r.Path;
		tree = r.Tree;
	else
		path = CurrentData.Path;
		tree = CurrentData.Tree;
	endif;
	if ( scenarioRecreated ( path, tree ) ) then
		return;
	endif; 
	row = ChangedScenarios.Add ();
	row.Application = CurrentApplication;
	row.Delete = deletedFile ( path );
	ScenariosCounter = ScenariosCounter + 1;

EndProcedure

&AtServer
Function deletedFile ( Path )
	
	return StrReplace ( Path, ".", Slash ) + ".*";
	
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
	r = InformationRegisters.Removing.Get ( new Structure ( "Repository, ID", Node, id ) );
	path = r.Path;
	tree = r.Tree;
	if ( path = ""
		or scenarioRecreated ( path, tree ) ) then
		return;
	endif;
	row = ChangedScenarios.Add ();
	row.Application = CurrentApplication;
	scenarioBecameCommon = ( path = CurrentData.Path )
	and CurrentData.Application.IsEmpty ()
	and not CurrentApplication.IsEmpty ();
	if ( scenarioBecameCommon
		and hasChildren () ) then
		row.Delete = unbindFolder ( path );
	else
		row.Delete = deletedFile ( path );
	endif;
	RemovingSet.Add ( new Structure ( "ID, Repository", id, Node ) );
		
EndProcedure

&AtServer
Function hasChildren ()
	
	ChildHunter.SetParameter ( "Ref", CurrentData.Ref );
	ChildHunter.SetParameter ( "Application", CurrentApplication );
	return not ChildHunter.Execute ().IsEmpty ();
	
EndFunction 

&AtServer
Function unbindFolder ( Path )
	
	return StrReplace ( Path, ".", Slash ) + Slash + "*.dir.*";
	
EndFunction 

&AtServer
Procedure addScenario ()
	
	row = ChangedScenarios.Add ();
	row.Application = CurrentApplication;
	row.Scenario = CurrentData.Ref;
	ScenariosCounter = ScenariosCounter + 1;

EndProcedure 

&AtClient
Procedure prepareCounters ()
	
	CurrentIndex = -1;
	LastIndex = ChangedScenarios.Count () - 1;
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
				entry.Lib.Resume ();
			else
				entry.Lib.Pause ();
			endif;
		endif;
	enddo;
	
EndProcedure

&AtClient
Procedure createSystemFolders ()
	
	stub = new NotifyDescription ( "Stub", ThisObject );
	for each root in Roots do
		BeginCreatingDirectory ( stub, root.Value + slash + TesterSystemFolder );
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
		toggleWatching ( true );
		deleteRecords ();
		showInfo ();
		return;
	endif; 
	row = ChangedScenarios [ CurrentIndex ];
	root = Roots [ row.Application ];
	if ( row.Delete = "" ) then
		data = scenarioData ( row.Scenario );
		p = new Structure ( "Root, Data, BaseName", root, data );
		p.BaseName = getBaseName ( p );
		createFolder ( p );
	else
		victim = row.Delete;
		BeginDeletingFiles ( ContinueUnloading,
			root + Slash + FileSystem.GetParent ( victim ),
			FileSystem.GetFileName ( victim ) );
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
	
	for each record in RemovingIDs do
		r = InformationRegisters.Removing.CreateRecordManager ();
		r.Repository = record.Repository;
		r.ID = record.ID;
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
	data.Insert ( "Version", "1.3.4.6" );
	data.Insert ( "Path", Scenario.Path );
	data.Insert ( "Script", Scenario.Script );
	data.Insert ( "Spreadsheet", Scenario.Spreadsheet );
	data.Insert ( "Template", getTemplate ( Scenario ) );
	data.Insert ( "Type", Scenario.Type );
	data.Insert ( "TypeID", Conversion.EnumToName ( Scenario.Type ) );
	data.Insert ( "Tree", Scenario.Tree );
	data.Insert ( "Creator", String ( Scenario.Creator ) );
	data.Insert ( "LastCreator", String ( Scenario.LastCreator ) );
	data.Insert ( "Severity", Conversion.EnumToName ( Scenario.Severity ) );
	data.Insert ( "Tags", getTags ( Scenario ) );
	data.Insert ( "Memo", Scenario.Memo );
	changed = ? ( Scenario.Changed = Date ( 1, 1, 1 ), Date ( 2000, 1, 1 ), Scenario.Changed );
	data.Insert ( "Changed", changed );
	return data;
	
EndFunction

&AtServerNoContext
Function getTags ( Scenario )

	s = "select Tags.Tag.Description as Tag
	|from Catalog.TagKeys.Tags as Tags
	|where Tags.Ref = &Key";
	q = new Query ( s );
	q.SetParameter ( "Key", Scenario.Tag );
	return q.Execute ().Unload ().UnloadColumn ( "Tag" );
	
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
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		data = Params.Data;
		file = Params.BaseName + RepositoryFiles.BSLFile ();
		p = new Structure ( "File, Params", file, Params );
		doc = new TextDocument ();
		doc.SetText ( data.Script );
		doc.BeginWriting ( new NotifyDescription ( "ScriptCreated", ThisObject, p ), file, , Chars.LF );
	#endif
		
EndProcedure 

&AtClient
Procedure ScriptCreated ( Result, Params ) export
	
	p = Params.Params;
	callback = new NotifyDescription ( "ScriptTimeChanged", ThisObject, p );
	file = new File ( Params.File );
	file.BeginSettingModificationUniversalTime ( callback, p.Data.Changed );

EndProcedure 

&AtClient
Procedure ScriptTimeChanged ( Params ) export
	
	createPropeties ( Params );
	
EndProcedure

&AtClient
Procedure createPropeties ( Params )
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		data = Params.Data;
		file = Params.BaseName + JSONExtension;
		p = new Structure ( "File, Params", file, Params );
		doc = new TextDocument ();
		properties = new Structure ( "Version, Type, Tree, Severity, Creator, LastCreator, Memo, Tags" );
		properties.Version = data.Version;
		properties.Type = data.TypeID;
		properties.Tree = data.Tree;
		properties.Severity = ? ( data.Severity = undefined, "", data.Severity );
		properties.Creator = data.Creator;
		properties.LastCreator = data.LastCreator;
		properties.Memo = data.Memo;
		properties.Tags = data.Tags;
		doc.SetText ( Conversion.ToJSON ( properties ) );
		doc.BeginWriting ( new NotifyDescription ( "PropertiesCreated", ThisObject, p ), file, , Chars.LF );
	#endif
		
EndProcedure 

&AtClient
Procedure PropertiesCreated ( Result, Params ) export
	
	p = Params.Params;
	callback = new NotifyDescription ( "PropertiesTimeChanged", ThisObject, p );
	file = new File ( Params.File );
	file.BeginSettingModificationUniversalTime ( callback, p.Data.Changed );

EndProcedure

&AtClient
Procedure PropertiesTimeChanged ( Params ) export
	
	createSpreadsheet ( Params );
	
EndProcedure 

&AtClient
Procedure createSpreadsheet ( Params )
	
	file = Params.BaseName + MXLExtension;
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
