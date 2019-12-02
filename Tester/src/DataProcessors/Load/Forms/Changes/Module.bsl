&AtServer
var Tree;
&AtServer
var CurrentApplication;
&AtServer
var CurrentData;
&AtClient
var ScenarioIndex;
&AtClient
var LastScenario;
&AtServer
var CommonApplication;
&AtClient
var ScenariosSet;
&AtClient
var CurrentData;
&AtClient
var FilesContent;
&AtClient
var FilesList;
&AtClient
var CurrentFile;
&AtClient
var FileIndex;
&AtClient
var LastFile;
&AtClient
var RenewList;
&AtServer
var CommonRows;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadScenarios ();
	
EndProcedure

&AtServer
Procedure loadScenarios ()
	
	createTree ();
	q = getQuery ();
	for each CurrentApplication in getApplications () do
		q.SetParameter ( "Application", CurrentApplication );
		selection = q.Execute ().Select ( QueryResultIteration.ByGroupsWithHierarchy, "Scenario" );
		loadSelection ( selection, newApplication () );
	enddo; 
	loadChanges ();
	formatTree ( Tree.Rows );
	ValueToFormAttribute ( Tree, "ChangesTree" );
	
EndProcedure 

&AtServer
Procedure createTree ()
	
	Tree = new ValueTree ();
	columns = Tree.Columns;
	boolean = new TypeDescription ( "Boolean" );
	string = new TypeDescription ( "String" );
	number = new TypeDescription ( "Number" );
	datetime = new TypeDescription ( "Date" );
	columns.Add ( "Presentation", string );
	columns.Add ( "Application", new TypeDescription ( "CatalogRef.Applications" ) );
	columns.Add ( "Use", boolean );
	columns.Add ( "Scenario", new TypeDescription ( "CatalogRef.Scenarios" ) );
	columns.Add ( "Path", string );
	columns.Add ( "New", boolean );
	columns.Add ( "File", string );
	columns.Add ( "Locked", number );
	columns.Add ( "Type", new TypeDescription ( "EnumRef.Scenarios" ) );
	columns.Add ( "Picture", number );
	columns.Add ( "Sorting", number );
	columns.Add ( "Found", boolean );
	columns.Add ( "Changed", datetime );
	columns.Add ( "Usage", boolean );
	columns.Add ( "UTC", datetime );
	columns.Add ( "Extensions", string );
	
EndProcedure 

&AtServer
Function getApplications ()
	
	list = new Array ();
	for each row in Parameters.Changes do
		list.Add ( row.Application );
	enddo; 
	return list;
	
EndFunction 

&AtServer
Function getQuery ()
	
	s = "
	|select allowed Scenarios.Ref as Scenario, Scenarios.Application as Application, Scenarios.Path as Path,
	|	Scenarios.Type as Type, Scenarios.Changed as Changed, Scenarios.Sorting as Sorting,
	|	case when Editing.Scenario is null then 0
	|		when Editing.User = &User then 1
	|		else 2
	|	end as Locked,
	|	case when Scenarios.Spreadsheet then 4 else 0 end
	|	+
	|	case when Scenarios.Type = value ( Enum.Scenarios.Library ) then 0
	|		when Scenarios.Type = value ( Enum.Scenarios.Folder ) then 1
	|		when Scenarios.Type = value ( Enum.Scenarios.Method ) then 2
	|		else 3
	|	end as Picture
	|from Catalog.Scenarios as Scenarios
	|	//
	|	// Editing
	|	//
	|	left join InformationRegister.Editing as Editing
	|	on Editing.Scenario = Scenarios.Ref
	|where Scenarios.Application in ( &Application, value ( Catalog.Applications.EmptyRef ) )
	|and not Scenarios.DeletionMark
	|order by Application, Tree desc, Sorting, Path
	|totals by Scenario hierarchy
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	return q;
	
EndFunction

&AtServer
Function newApplication ()
	
	row = Tree.Rows.Add ();
	row.Application = CurrentApplication;
	row.Presentation = "" + ? ( CurrentApplication.IsEmpty (), Output.CommonApplicationName (), CurrentApplication );
	return row.Rows;

EndFunction 

&AtServer
Procedure loadSelection ( Selection, Destination, LastScenario = undefined )
	
	detail = QueryRecordType.DetailRecord;
	bygroup = QueryRecordType.GroupTotal;
	hierarchy = QueryRecordType.TotalByHierarchy;
	deep = QueryResultIteration.ByGroupsWithHierarchy;
	while ( Selection.Next () ) do
		scenario = Selection.Scenario;
		type = Selection.RecordType ();
		if ( type = detail ) then
			if ( scenario = LastScenario ) then
				FillPropertyValues ( Destination.Parent, Selection );
			endif;
		else
			if ( scenario = LastScenario ) then
				rows = Destination;
			else
				row = Destination.Add ();
				FillPropertyValues ( row, Selection );
				rows = row.Rows;
			endif;
			if ( type = hierarchy ) then
				next = Selection.Select ( deep, "Scenario" );
			elsif ( type = bygroup ) then
				next = Selection.Select ();
			endif; 
			loadSelection ( next, rows, Selection.Scenario );
		endif;
	enddo; 
	
EndProcedure

&AtServer
Procedure loadChanges ()
	
	defineCommon ();
	for each repository in Parameters.Changes do
		CurrentApplication = repository.Application;
		for each CurrentData in repository.Changes do
			addScenario ();
		enddo; 
	enddo; 
	
EndProcedure 

&AtServer
Procedure defineCommon ()
	
	CommonApplication = Catalogs.Applications.EmptyRef ();
	row = Tree.Rows.Find ( CommonApplication, "Application" );
	CommonRows = ? ( row = undefined, undefined, row.Rows );
	
EndProcedure 

&AtServer
Procedure addScenario ()
	
	path = CurrentData.Path;
	row = findScenario ( path );
	if ( row = undefined ) then
		row = newRow ( defineParent (), path );
	else
		row.Found = not row.New;
	endif; 
	row.UTC = Max ( CurrentData.UTC, row.UTC );
	row.File = CurrentData.File;
	ext = CurrentData.Extension;
	if ( ext <> "" ) then
		row.Extensions = row.Extensions + ext + ";";
	endif; 
	
EndProcedure 

&AtServer
Function findScenario ( Path )
	
	found = Tree.Rows.FindRows ( new Structure ( "Application, Path", CurrentApplication, Path ), true );
	if ( found.Count () = 0 ) then
		rows = findRoot ();
		found = rows.FindRows ( new Structure ( "Application, Path", CommonApplication, Path ), true );
	endif;
	return ? ( found.Count () = 0, undefined, found [ 0 ] );
	
EndFunction 

&AtServer
Function findRoot ()
	
	row = Tree.Rows.Find ( CurrentApplication, "Application" );
	return ? ( row = undefined, undefined, row.Rows );
	
EndFunction 

&AtServer
Function newRow ( Rows, Path )
	
	row = Rows.Add ();
	if ( CommonRows = undefined ) then
		commonRow = undefined;
	else
		commonRow = CommonRows.Find ( Path, "Path", true );
	endif; 
	if ( commonRow = undefined ) then
		row.Path = Path;
		row.New = true;
		row.Application = CurrentApplication;
	else
		FillPropertyValues ( row, commonRow );
	endif; 
	return row;
	
EndFunction 

&AtServer
Function defineParent ()
	
	parts = StrSplit ( CurrentData.Path, "." );
	parts.Delete ( parts.UBound () );
	path = "";
	parent = findRoot ();
	for each part in parts do
		path = path + part;
		row = findScenario ( path );
		if ( row = undefined ) then
			row = newRow ( parent, path );
		endif; 
		parent = row.Rows;
		path = path + ".";
	enddo; 
	return parent;
	
EndFunction 

&AtServer
Procedure formatTree ( Rows )
	
	for each row in Rows do
		setType ( row );
		setPicture ( row );
		setUsage ( row );
		setPresentation ( row );
		next = row.Rows;
		if ( next.Count () > 0 ) then
			formatTree ( next );
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Procedure setType ( Row )
	
	if ( not Row.New ) then
		return;
	endif; 
	extensions = Row.Extensions;
	folder = StrEndsWith ( Row.File, RepositoryFiles.FolderSuffix () );
	if ( StrFind ( Extensions, RepositoryFiles.ScriptFile () + ";" ) > 0 ) then
		type = ? ( folder, Enums.Scenarios.Folder, Enums.Scenarios.Scenario );
	elsif ( StrFind ( Extensions, RepositoryFiles.MethodFile () + ";" ) > 0 ) then
		type = Enums.Scenarios.Method;
	else
		type = Enums.Scenarios.Library;
	endif;
	Row.Type = type;
		
EndProcedure 

&AtServer
Procedure setPicture ( Row )
	
	if ( not Row.New ) then
		return;
	endif; 
	type = Row.Type;
	if ( type = Enums.Scenarios.Library ) then
		picture = 0;
	elsif ( type = Enums.Scenarios.Folder ) then
		picture = 1;
	elsif ( type = Enums.Scenarios.Method ) then
		picture = 2;
	else
		picture = 3;
	endif;
	if ( StrFind ( Row.Extensions, RepositoryFiles.MXLFile () + ";" ) > 0 ) then
		picture = 4 + picture;
	endif;
	Row.Picture = picture;
		
EndProcedure 

&AtServer
Procedure setUsage ( Row )
	
	usage = Row.Path <> ""
	and ( Row.Extensions <> "" and ( Row.New or Row.Locked = 1 )
		or ( not Row.Found and Row.Application = CurrentApplication )
	);
	Row.Usage = usage;
	if ( Row.Found ) then
		Row.Use = usage and ( Row.Changed < Row.UTC );
	else
		Row.Use = usage;
	endif; 
		
EndProcedure 

&AtServer
Procedure setPresentation ( Row )
	
	if ( Row.Presentation = "" ) then
		Row.Presentation = Row.Path;
	endif; 
		
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Load ( Command )
	
	prepareScenarios ();
	prepareCounters ();
	initProgress ();
	startLoading ();
	
EndProcedure

&AtClient
Procedure prepareScenarios ()
	
	ScenariosSet = new Array ();
	fillScenarios ( ChangesTree.GetItems () );
	
EndProcedure 

&AtClient
Procedure fillScenarios ( Rows )
	
	for each row in Rows do
		if ( row.Use ) then
			ScenariosSet.Add ( row );
		endif;
		next = row.GetItems ();
		if ( next.Count () > 0 ) then
			fillScenarios ( next );
		endif; 
	enddo; 
	
EndProcedure 

&AtClient
Procedure prepareCounters ()
	
	ScenarioIndex = -1;
	LastScenario = ScenariosSet.UBound ();
	RenewList = new Array ();
	
EndProcedure 

&AtClient
Procedure initProgress ()
	
	ProgressBar = 0;
	Items.ProgressBar.MaxValue = 1 + LastScenario;
	Items.ProgressBar.ShowPercent = true;
	
EndProcedure 

&AtClient
Procedure startLoading ()
	
	ScenarioIndex = ScenarioIndex + 1;
	ProgressBar = ProgressBar + 1;
	RefreshDataRepresentation ( Items.ProgressBar );
	if ( ScenarioIndex > LastScenario ) then
		showInfo ();
		return;
	endif; 
	CurrentData = ScenariosSet [ ScenarioIndex ];
	FilesContent = new Map ();
	FilesList = filesList ();
	FileIndex = -1;
	LastFile = FilesList.UBound ();
	loadFiles ();
	
EndProcedure 

&AtClient
Function filesList ()
	
	list = new Array ();
	for each ext in StrSplit ( CurrentData.Extensions, ";", false ) do
		list.Add ( new Structure ( "Name, Extension", CurrentData.File, ext ) );
	enddo; 
	return list;
	
EndFunction 

&AtClient
Procedure loadFiles ()
	
	FileIndex = FileIndex + 1;
	if ( FileIndex > LastFile ) then
		remove = not CurrentData.Found and not CurrentData.New;
		CurrentData.Scenario = updateScenario ( CurrentData.Application, CurrentData.GetParent ().Scenario, CurrentData.Path, FilesContent, CurrentData.Type, remove );
		RenewList.Add ( CurrentData.Scenario );
		startLoading ();
		return;
	endif; 
	CurrentFile = FilesList [ FileIndex ];
	file = fileName ();
	if ( CurrentFile.Extension = RepositoryFiles.MXLFile () ) then
		BeginPutFile ( new NotifyDescription ( "PutMXL", ThisObject ), , file, false, UUID );
	else
		doc = new TextDocument ();
		doc.BeginReading ( new NotifyDescription ( "ReadingComplete", ThisObject, doc ), file );
	endif; 
	
EndProcedure 

&AtClient
Function fileName ()
	
	if ( CurrentFile.Extension = RepositoryFiles.MXLFile () ) then
		return CurrentFile.Name + CurrentFile.Extension;
	else
		return CurrentFile.Name + CurrentFile.Extension + RepositoryFiles.BSLFile ();
	endif; 
	
EndFunction 

&AtClient
Procedure PutMXL ( Result, Address, File, Params ) export
	
	if ( Result ) then
		FilesContent [ CurrentFile.Extension ] = Address;
	endif; 
	loadFiles ();
	
EndProcedure 

&AtClient
Procedure showInfo ()
	
	Output.ScenariosProcessed ( ThisObject, , new Structure ( "Counter", Format ( LastScenario + 1, "NZ=; NG=" ) ) );
	
EndProcedure 

&AtClient
Procedure ScenariosProcessed ( Params ) export
	
	Notify ( Enum.MessageReload (), RenewList );
	NotifyChanged ( Type ( "CatalogRef.Scenarios" ) );
	Close ( true );
	
EndProcedure 

&AtClient
Procedure ReadingComplete ( Document ) export
	
	FilesContent [ CurrentFile.Extension ] = Document.GetText ();
	loadFiles ();
	
EndProcedure 

&AtServerNoContext
Function updateScenario ( val Application, val Parent, val Path, val Content, val Type, val Remove )
	
	scenario = getScenario ( Path, Application );
	if ( Remove ) then
		if ( scenario <> undefined ) then
			scenario.GetObject ().SetDeletionMark ( true );
		endif; 
		return undefined;
	endif;
	if ( scenario = undefined ) then
		obj = Catalogs.Scenarios.CreateItem ();
		loadFields ( obj, Path, Parent );
	else
		Catalogs.Versions.Create ( scenario, Output.LoadingProcessVersionMemo () );
		obj = scenario.GetObject ();
	endif; 
	obj.AdditionalProperties.Insert ( "Loading", true );
	obj.Application = Application;
	obj.Type = Type;
	loadScript ( obj, Content );
	loadTemplate ( obj, Content );
	obj.Write ();
	return obj.Ref;
	
EndFunction

&AtServerNoContext
Function getScenario ( Path, Application )
	
	s = "
	|select top 1 Scenarios.Ref as Ref
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Path = &Path
	|and Scenarios.Application = &Application
	|and not Scenarios.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Path", Path );
	q.SetParameter ( "Application", Application );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction 

&AtServerNoContext
Procedure loadFields ( Obj, Path, Parent )
	
	Obj.Creator = SessionParameters.User;
	Obj.Path = Path;
	parts = StrSplit ( Path, "." );
	level = parts.UBound ();
	Obj.Description = parts [ level ];
	Obj.Parent = Parent;
	
EndProcedure 

&AtServerNoContext
Procedure loadScript ( Scenario, Content )
	
	s = Content [ RepositoryFiles.ScriptFile () ];
	if ( s = undefined ) then
		s = Content [ RepositoryFiles.MethodFile () ];
		if ( s = undefined ) then
			s = Content [ RepositoryFiles.LibFile () ];
		endif; 
	endif; 
	Scenario.Script = s;

EndProcedure 

&AtServerNoContext
Procedure loadTemplate ( Scenario, Content )
	
	address = Content [ RepositoryFiles.MXLFile () ];
	if ( address = undefined ) then
		Scenario.Template = new ValueStorage ( new SpreadsheetDocument () );
		Scenario.Areas.Clear ();
		Scenario.Spreadsheet = false;
	else
		assembleTemplate ( address, Scenario );
	endif; 

EndProcedure 

&AtServerNoContext
Procedure assembleTemplate ( Address, Scenario )
	
	tabDoc = getSpreadsheet ( Address );
	anchor = Max ( 1, tabDoc.TableHeight - 1 );
	areas = Scenario.Areas;
	signature = tabDoc.Area ( anchor, 1, anchor, 1 ).Text;
	if ( signature = RepositoryFiles.Signature () ) then
		table = areas.UnloadColumns ();
		anchor = anchor + 1;
		set = Conversion.FromJSON ( tabDoc.Area ( anchor, 1, anchor, 1 ).Text );
		for each fields in set do
			row = table.Add ();
			FillPropertyValues ( row, fields );
		enddo; 
		areas.Load ( table );
		tabDoc = tabDoc.GetArea ( "R1:R" + Format ( anchor - 2, "NG=" ) );
	else
		areas.Clear ();
	endif;
	Scenario.Template = new ValueStorage ( tabDoc );
	Scenario.Spreadsheet = true;
	
EndProcedure

&AtServerNoContext
Function getSpreadsheet ( Address )
	
	storage = GetFromTempStorage ( address );
	file = GetTempFileName ();
	storage.Write ( file );
	tabDoc = new SpreadsheetDocument ();
	tabDoc.Read ( file );
	return tabDoc;
	
EndFunction 

// *****************************************
// *********** Group Tree

&AtClient
Procedure MarkAll ( Command )
	
	checkbox ( ChangesTree.GetItems (), true );
	
EndProcedure

&AtClient
Procedure checkbox ( Rows, Value )
	
	for each row in Rows do
		if ( row.Usage ) then
			row.Use = Value;
		endif; 
		next = row.GetItems ();
		if ( next.Count () > 0 ) then
			checkbox ( next, Value );
		endif; 
	enddo; 
	
EndProcedure 

&AtClient
Procedure UnmarkAll ( Command )
	
	checkbox ( ChangesTree.GetItems (), false );
	
EndProcedure

&AtClient
Procedure ChangesTreeBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ChangesTreeBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure
