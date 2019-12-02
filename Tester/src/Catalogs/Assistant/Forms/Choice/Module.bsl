&AtClient
var Reference;
&AtClient
var ReferenceCode;
&AtClient
var Buitin;
&AtClient
var AssistantRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	setQuery ();
	filterList ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	ControlName = Parameters.ControlName;
	TypeFilter = Parameters.ControlType;
	Picking = Parameters.Picking;
	
EndProcedure 

&AtServer
Procedure setQuery ()
	
	if ( CurrentLanguage () = Metadata.Languages.Russian ) then
		callMethod = "Вызвать";
	else
		callMethod = "Call";
	endif; 
	callMethod = """" + callMethod + " ( " + """""""" + " + Catalog.Path + """""" );""";
	s = "
	|select Catalog.Ref as Ref, Catalog.Description as Description, Catalog.Body as Body,
	|	Catalog.Explanation as Explanation, Catalog.Help as Help, Catalog.Code as Code, Usage.Date as Date,
	|	Catalog.Button as Button, Catalog.CommandBar as CommandBar, Catalog.CommandInterface as CommandInterface,
	|	Catalog.ContextMenu as ContextMenu, Catalog.Decoration as Decoration, Catalog.Field as Field,
	|	Catalog.Form as Form, Catalog.GroupType as GroupType, Catalog.InterfaceButton as InterfaceButton,
	|	Catalog.InterfaceGroup as InterfaceGroup, Catalog.Table as Table, Catalog.Window as Window,
	|	case when Catalog.Ref = value ( Catalog.Assistant.EmptyRef ) then 0 else 1 end as Image
	|from (
	|	select Catalog.Ref as Ref, Catalog.Description as Description, Catalog.Body as Body,
	|		Catalog.Explanation as Explanation, """" as Help, Catalog.Code as Code,
	|		0 as Button, 0 as CommandBar, 0 as CommandInterface, 0 as ContextMenu, 0 as Decoration,
	|		0 as Field, 0 as Form, 0 as GroupType, 0 as InterfaceButton, 0 as InterfaceGroup, 0 as Table, 0 as Window
	|	from Catalog.Assistant as Catalog
	|	where not Catalog.DeletionMark
	|	union all
	|	" + getBuiltin () + "
	|	) as Catalog
	|	//
	|	// Usage
	|	//
	|	left join InformationRegister.Usage as Usage
	|	on Usage.User = &User
	|	and Usage.Reference = 0
	|	and Usage.Code = Catalog.Code
	|union all
	|select Catalog.Ref, " + callMethod + ", " + callMethod + ", """", """", Catalog.Code, Usage.Date,
	|	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	|from Catalog.Scenarios as Catalog
	|	//
	|	// Usage
	|	//
	|	left join InformationRegister.Usage as Usage
	|	on Usage.User = &User
	|	and Usage.Reference = 1
	|	and Usage.Code = Catalog.Code
	|where not Catalog.DeletionMark
	|and Catalog.Application in ( value ( Catalog.Applications.EmptyRef ), &Application )
	|and Catalog.Type = value ( Enum.Scenarios.Method )
	|";
	List.QueryText = s;
	DC.SetParameter ( List, "User", SessionParameters.User );
	DC.SetParameter ( List, "Application", EnvironmentSrv.GetApplication () );
	
EndProcedure 

&AtServer
Function getBuiltin ()
	
	parts = new Array ();
	t = Catalogs.Assistant.GetTemplate ( "Builtin" );
	for i = 2 to t.TableHeight do
		selection = new Array ();
		for j = 1 to t.TableWidth do
			cell = t.Area ( i, j, i, j );
			selection.Add ( ? ( j > 5, ? ( cell.Parameter = undefined, 0, 1 ), """" + cell.Text + """" ) );
		enddo; 
		parts.Add ( "select value ( Catalog.Assistant.EmptyRef ), " + StrConcat ( selection, "," ) );
	enddo; 
	return StrConcat ( parts, " union all " );
	
EndFunction 

&AtServer
Procedure filterList ()
	
	filterByType ();
	if ( not Picking ) then
		return;
	endif; 
	DC.ChangeFilter ( List, "Ref", Catalogs.Assistant.EmptyRef (), true );
	
EndProcedure 

&AtServer
Procedure filterByType ()
	
	if ( not LastFilter.IsEmpty () ) then
		DC.DeleteFilter ( List, getColumn ( LastFilter ) );
	endif; 
	if ( not TypeFilter.IsEmpty () ) then
		DC.ChangeFilter ( List, getColumn ( TypeFilter ), 1, true );
	endif; 
	LastFilter = TypeFilter;
	
EndProcedure 

&AtServer
Function getColumn ( Control )
	
	column = Conversion.EnumToName ( Control );
	if ( column = "Group" ) then
		column = column + "Type";
	endif; 
	return column;
	
EndFunction 

&AtClient
Procedure TypeFilterOnChange ( Item )
	
	filterByType ();
	activateList ();
	
EndProcedure

&AtClient
Procedure activateList ()
	
	CurrentItem = Items.List;
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	startListener ();
	
EndProcedure

&AtClient
Procedure startListener ()
	
	AttachIdleHandler ( "listener", 0.1, true );
	
EndProcedure 

&AtClient
Procedure listener ()
	
	if ( AssistantRow <> Items.List.CurrentData ) then
		readRow ();
		if ( AssistantRow = undefined ) then
			showExplanation ();
		else
			if ( Buitin ) then
				helpOnline ();
			else
				showExplanation ();
			endif; 
		endif; 
	endif; 
	startListener ();

EndProcedure 

&AtClient
Procedure readRow ()
	
	AssistantRow = Items.List.CurrentData;
	if ( AssistantRow = undefined ) then
		return;
	endif; 
	ReferenceCode = AssistantRow.Code;
	ref = AssistantRow.Ref;
	type = TypeOf ( ref );
	if ( type = Type ( "CatalogRef.Assistant" ) ) then
		Reference = 0;
		Buitin = ref.IsEmpty ();
	else
		Reference = 1;
		Buitin = false;
	endif;
	
EndProcedure

&AtClient
Procedure showExplanation ()
	
	Items.HelpPages.CurrentPage = Items.UserHelpPage;
	HTML = "";
	
EndProcedure 

&AtClient
Procedure helpOnline ()
	
	Items.HelpPages.CurrentPage = Items.BuiltinHelpPage;
	HTML = OnlineHelp.Href ( getLink (), false );
				
EndProcedure 

&AtClient
Function getLink ()
	
	return "Functions." + AssistantRow.Help;
	
EndFunction 

// *****************************************
// *********** List

&AtClient
Procedure Create ( Command )
	
	openElement ( true );
	
EndProcedure

&AtClient
Procedure openElement ( CreateNew )
	
	tableRow = Items.List.CurrentData;
	ref = ? ( tableRow = undefined or CreateNew, PredefinedValue ( "Catalog.Assistant.EmptyRef" ), tableRow.Ref );
	edit = not CreateNew;
	if ( edit
		and ref.IsEmpty () ) then
		Output.AssistantBuiltin ();
	else
		p = new Structure ( "Key", ref );
		OpenForm ( form ( ref ), p, ThisObject, , , , new NotifyDescription ( "HintCreated", ThisObject ) );
	endif; 
	
EndProcedure 

&AtClient
Function form ( Ref )
	
	if ( TypeOf ( Ref ) = Type ( "CatalogRef.Scenarios" ) ) then
		return "Catalog.Scenarios.ObjectForm";
	else
		return "Catalog.Assistant.ObjectForm";
	endif; 
	
EndFunction 

&AtClient
Procedure HintCreated ( Result, Params ) export
	
	Items.List.Refresh ();
	
EndProcedure 

&AtClient
Procedure Edit ( Command )
	
	openElement ( false );
	
EndProcedure

&AtClient
Procedure ListValueChoice ( Item, Value, StandardProcessing )
	
	StandardProcessing = false;
	readRow ();
	if ( Buitin ) then
		openParams ();
	else
		notifySelection ();
	endif; 

EndProcedure

&AtClient
Procedure openParams ()
	
	data = Items.List.CurrentData;
	p = new Structure ( "Method, ControlName, Picking, Help", data.Description, ControlName, Picking, getLink () );
	OpenForm ( "Catalog.Assistant.Form.Params", p, ThisObject, , , , new NotifyDescription ( "AssistantParams", ThisObject ) );

EndProcedure 

&AtClient
Procedure AssistantParams ( Details, Params ) export
	
	if ( Details = undefined ) then
		return;
	endif; 
	notifyOwner ( Details );	
	
EndProcedure 

&AtClient
Procedure notifyOwner ( Params )
	
	updateUsage ( Reference, ReferenceCode );
	NotifyChoice ( Params );

EndProcedure 

&AtServerNoContext
Procedure updateUsage ( val Reference, val Code )
	
	r = InformationRegisters.Usage.CreateRecordManager ();
	r.User = SessionParameters.User;
	r.Reference = Reference;
	r.Code = Code;
	r.Date = CurrentSessionDate ();
	r.Write ();
	
EndProcedure 

&AtClient
Procedure notifySelection ()
	
	data = Items.List.CurrentData;
	value = data.Body;
	if ( IsBlankString ( value ) ) then
		value = data.Description;
	endif;
	notifyOwner ( value );
		
EndProcedure 
