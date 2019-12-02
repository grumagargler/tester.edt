&AtClient
var TableRow export;
&AtClient
var ApplicationIndex;
&AtClient
var ApplicationLastIndex;
&AtClient
var FilesIndex;
&AtClient
var FilesLastIndex;
&AtClient
var FilesArray;
&AtClient
var CurrentFile;
&AtClient
var CurrentExtension;
&AtClient
var CurrentObjectName;
&AtClient
var ChangedRepositories;
&AtClient
var ChangedScenarios;
&AtClient
var PathBegins;
&AtClient
var FolderSuffix;
&AtClient
var Slash;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadRepositories ();
	
EndProcedure

&AtServer
Procedure loadRepositories ()
	
	s = "
	|select allowed Applications.Ref as Application, Repositories.Folder as Folder,
	|	case when Settings.Application is null then false else true end as Use
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
	|order by Application
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Computer", SessionData.Computer () );
	Object.Repositories.Load ( q.Execute ().Unload () );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	setConstants ();
	RepositoryForm.SetFocus ( ThisObject );
	LocalFiles.Prepare ();

EndProcedure

&AtClient
Procedure setConstants ()
	
	Slash = GetPathSeparator ();
	FolderSuffix = RepositoryFiles.FolderSuffix ();
	
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
Procedure Load ( Command )
	
	if ( CheckFilling () ) then
		savePaths ();
		init ();
		loadApplications ();
	endif; 
		
EndProcedure

&AtServer
Procedure savePaths ()
	
	RepositoryForm.SavePaths ( Object );
	
EndProcedure

&AtClient
Procedure init ()
	
	ApplicationIndex = -1;
	ApplicationLastIndex = Object.Repositories.Count () - 1;
	ChangedRepositories = new Array ();
	
EndProcedure 

&AtClient
Procedure loadApplications ()
	
	ApplicationIndex = ApplicationIndex + 1;
	if ( ApplicationIndex > ApplicationLastIndex ) then
		openChanges ();
		return;
	endif; 
	repo = Object.Repositories [ ApplicationIndex ];
	folder = repo.Folder;
	if ( repo.Use ) then
		ChangedScenarios = new Array ();
		PathBegins = StrLen ( folder ) + 2;
		ChangedRepositories.Add ( new Structure ( "Application, Changes", repo.Application, ChangedScenarios ) );
	else
		loadApplications ();
		return;
	endif; 
	BeginFindingFiles ( new NotifyDescription ( "FindingFiles", ThisObject ), folder, "*.*", true );
	
EndProcedure 

&AtClient
Procedure openChanges ()
	
	OpenForm ( "DataProcessor.Load.Form.Changes", new Structure ( "Changes", ChangedRepositories ), ThisObject, , , , new NotifyDescription ( "AfterApplyingChanges", ThisObject ) );
	
EndProcedure 

&AtClient
Procedure AfterApplyingChanges ( Result, Params ) export
	
	if ( Result <> undefined
		and Result ) then
		Close ();
	endif; 
	
EndProcedure 

&AtClient
Procedure FindingFiles ( Files, Params ) export
	
	FilesIndex = -1;
	FilesLastIndex = Files.Count () - 1;
	FilesArray = Files;
	loadFiles ();
	
EndProcedure 

&AtClient
Procedure loadFiles ()
	
	FilesIndex = FilesIndex + 1;
	if ( FilesIndex > FilesLastIndex ) then
		loadApplications ();
		return;
	endif; 
	CurrentFile = FilesArray [ FilesIndex ];
	CurrentExtension = objectExtension ();
	CurrentObjectName = FileSystem.GetBaseName ( CurrentFile.BaseName );
	if ( validFile () ) then
		CurrentFile.BeginGettingModificationUniversalTime ( new NotifyDescription ( "GettingModificationUniversalTime", ThisObject ) );
	else
		loadFiles ();
	endif; 
	
EndProcedure 

&AtClient
Function objectExtension ()
	
	ext = CurrentFile.Extension;
	if ( ext = RepositoryFiles.BSLFile () ) then
		return FileSystem.Extension ( CurrentFile.BaseName );
	else
		return ext;
	endif; 
	
EndFunction 

&AtClient
Function validFile ()
	
	return CurrentExtension = RepositoryFiles.ScriptFile ()
	or CurrentExtension = RepositoryFiles.LibFile ()
	or CurrentExtension = RepositoryFiles.MethodFile ()
	or CurrentExtension = RepositoryFiles.MXLFile ();
	
EndFunction 

&AtClient
Procedure GettingModificationUniversalTime ( Time, Params ) export
	
	enrollChanges ( Time );
	loadFiles ();
	
EndProcedure 

&AtClient
Procedure enrollChanges ( UTC )
	
	p = new Structure ();
	p.Insert ( "Path", buildPath () );
	p.Insert ( "File", CurrentFile.Path + CurrentObjectName );
	p.Insert ( "Extension", CurrentExtension );
	p.Insert ( "UTC", UTC );
	ChangedScenarios.Add ( p );
	
EndProcedure 

&AtClient
Function buildPath ()
	
	parent = StrReplace ( Mid ( CurrentFile.Path, PathBegins ), Slash, "." );
	if ( StrEndsWith ( CurrentObjectName, FolderSuffix ) ) then
		return Mid ( parent, 1, StrLen ( parent ) - 1 );
	else
		return parent + CurrentObjectName;
	endif; 
	
EndFunction 

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
