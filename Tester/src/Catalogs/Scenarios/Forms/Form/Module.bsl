&AtClient
var TableRow;
&AtClient
var RowStart;
&AtClient
var RowEnd;
&AtClient
var ColumnStart;
&AtClient
var ColumnEnd;
&AtClient
var SelectionStart;
&AtClient
var SelectionEnd;
&AtClient
var FieldsRow;
&AtClient
var FieldsMap;
&AtClient
var TestedForm;
&AtClient
var OldParent;

// *****************************************
// *********** Form events
&AtServer
Procedure OnReadAtServer(CurrentObject)

	readMyself(CurrentObject);

EndProcedure

&AtServer
Procedure readMyself(CurrentObject)

	iHook();
	initTags();
	readStatus();
	restoreTemplate(CurrentObject);
	Appearance.Apply(ThisObject);

EndProcedure

&AtServer
Procedure iHook()
	
	WebHook = Constants.Webhook.Get() = Object.Ref;
	
EndProcedure

&AtServer
Procedure initTags()

	initTagsList();
	initTagsFilter();

EndProcedure

&AtServer
Procedure initTagsList()

	set = Items.TagsList.ChoiceList;
	tags = readTags();
	if (tags = undefined) then
		set.Clear();
	else
		insertTag(tags, set)
	endif;

EndProcedure

&AtServer
Function readTags()

	tag = Object.Tag;
	if (tag.IsEmpty()) then
		return undefined;
	endif;
	s = "
	|select Tags.Tag.Description as Tag
	|from Catalog.TagKeys.Tags as Tags
	|where Tags.Ref = &Key
	|and not Tags.Tag.DeletionMark
	|";
	q = new Query(s);
	q.SetParameter("Key", tag);
	return q.Execute().Unload().UnloadColumn("Tag");

EndFunction

&AtClientAtServerNoContext
Procedure insertTag(Tag, List)

	if (TypeOf(Tag) = Type("Array")) then
		List.LoadValues(Tag);
	else
		List.Add(Tag);
	endif;
	List.SortByValue();

EndProcedure

&AtServer
Procedure initTagsFilter()

	tags = getTagClassifier();
	for each row in tags do
		tag = row.Ref;
		item = TagsFilter.FindByValue(tag);
		if (item = undefined) then
			TagsFilter.Add(tag, row.Description);
		endif;
	enddo;
	TagsFilter.SortByPresentation();

EndProcedure

&AtServer
Function getTagClassifier()

	s = "
		|select Tags.Ref as Ref, Tags.Description as Description
		|from Catalog.Tags as Tags
		|where not Tags.DeletionMark
		|";
	q = new Query(s);
	return q.Execute().Unload();

EndFunction

&AtServer
Procedure readStatus()

	Locked = false;
	LockedBy = undefined;
	if (Object.Ref.IsEmpty()) then
		Locked = true;
		return;
	endif;
	info = InformationRegisters.Editing.Get(new Structure("Scenario", Object.Ref));
	if (info.User.IsEmpty()) then
		return;
	endif;
	user = info.User;
	if (user = SessionParameters.User) then
		Locked = true;
	else
		LockedBy = "" + user + ", " + info.Date;
	endif;

EndProcedure

&AtServer
Procedure restoreTemplate(Scenario)

	TabDoc = Scenario.Template.Get();
	TemplateChanged = Object.Ref.IsEmpty();
	entitleTemplate(ThisObject);
	AreasStorage = "";
	markAreas();

EndProcedure

&AtClientAtServerNoContext
Procedure entitleTemplate(Form)

	items = Form.Items;
	tabDoc = Form.TabDoc;
	caption = Output.TemplateCaption();
	if (0 < (tabDoc.TableWidth + tabDoc.TableHeight)) then
		caption = caption + " *";
	endif;
	items.PageTemplate.Title = caption;

EndProcedure

&AtServer
Procedure markAreas(val List = undefined)

	noline = new Line(SpreadsheetDocumentCellLineType.None);
	redLine = new Line(SpreadsheetDocumentCellLineType.LargeDashed, 3);
	redColor = new Color(255, 0, 0);
	savedAreas = getSavedAreas();
	if (List = undefined) then
		set = Object.Areas.Unload(, "Name").UnloadColumn("Name");
	else
		set = List;
	endif;
	for each name in set do
		savedAreas[name] = TabDoc.GetArea(Name);
		area = TabDoc.Area(name);
		area.TopBorder = noline;
		area.LeftBorder = noline;
		area.RightBorder = noline;
		area.BottomBorder = noline;
		area.Outline(redLine, redLine, redLine, redLine);
		area.BorderColor = redColor;
	enddo;
	saveAreas(savedAreas);

EndProcedure

&AtServer
Function getSavedAreas()

	if (AreasStorage = "") then
		return new Map();
	else
		return GetFromTempStorage(AreasStorage);
	endif;

EndFunction

&AtServer
Procedure saveAreas(Areas)

	AreasStorage = PutToTempStorage(Areas, UUID);

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	if (Object.Ref.IsEmpty()) then
		if (not Parameters.CopyingValue.IsEmpty()) then
			restoreTemplate(Parameters.CopyingValue);
		endif;
		ScenarioForm.Init(ThisObject);
		readStatus();
		initTags();
	endif;
	bindWorkplace();
	setView();
	setFilters();
	showFilters(ThisObject);
	AppearanceSrv.Read(ThisObject);

EndProcedure

&AtServer
Procedure bindWorkplace()

	params = new Array();
	params.Add(new ChoiceParameter("Filter.Owner", SessionParameters.User));
	Items.WorkplaceFilter.ChoiceParameters = new FixedArray(params);

EndProcedure

&AtServer
Procedure setView()

	control = Items.List;
	if (StatusFilter = 0 and IsBlankString(SearchString)
			and not tagsFiltered()) then
		control.Representation = TableRepresentation.Tree;
	else
		control.Representation = TableRepresentation.List;
	endif;
	showPath = StatusFilter <> 0;
	Items.ListDescription.Visible = not showPath;
	Items.ListFullDescription.Visible = showPath;

EndProcedure

&AtServer
Function tagsFiltered()

	for each item in TagsFilter do
		if (item.Check) then
			return true;
		endif;
	enddo;
	return false;

EndFunction

&AtServer
Procedure setFilters()

	DC.SetParameter(List, "User", SessionParameters.User);
	ApplicationFilter = EnvironmentSrv.GetApplication();
	WorkplaceFilter = CommonSettingsStorage.Load(Enum.SettingsWorkplaceFilter());
	applicationFixed(ThisObject);
	filterByApplication();
	filterByWorkplace();
	filterByDeletion();

EndProcedure

&AtClientAtServerNoContext
Function applicationFixed(Form)

	object = Form.Object;
	application = object.Application;
	if (Form.ApplicationFilter <> application and not application.IsEmpty()) then
		Form.ApplicationFilter = application;
		return true;
	else
		return false;
	endif;

EndFunction

&AtServer
Procedure filterByApplication()

	if (ApplicationFilter.IsEmpty()) then
		DC.ChangeFilter(List, "Application", undefined, false);
	else
		filter = new Array();
		filter.Add(Catalogs.Applications.EmptyRef());
		filter.Add(ApplicationFilter);
		DC.ChangeFilter(List, "Application", filter, true, DataCompositionComparisonType.InList);
	endif;

EndProcedure

&AtServer
Procedure filterByWorkplace()

	show = DC.FindParameter(List, "Show");
	hide = DC.FindParameter(List, "Hide");
	show.Use = false;
	hide.Use = false;
	if (WorkplaceFilter.IsEmpty()) then
		return;
	endif;
	set = WorkplaceFilter.Scenarios.UnloadColumn("Scenario");
	if (WorkplaceFilter.Exclude) then
		hide.Use = true;
		hide.Value = set;
	else
		show.Use = true;
		show.Value = set;
	endif;

EndProcedure

&AtServer
Procedure filterByDeletion()

	if (DeletionFilter) then
		DC.DeleteFilter(List, "DeletionMark");
	else
		DC.ChangeFilter(List, "DeletionMark", false, true);
	endif;

EndProcedure

&AtClientAtServerNoContext
Procedure showFilters(Form)

	label = Form.Items.ShowOptionsLabel;
	if (Form.ShowOptions) then
		label.Title = Output.OptionsLabelHide();
	else
		parts = new Array();
		value = Form.ApplicationFilter;
		if (not value.IsEmpty()) then
			parts.Add(value);
		endif;
		value = Form.WorkplaceFilter;
		if (not value.IsEmpty()) then
			parts.Add(value);
		endif;
		value = Form.StatusFilter;
		if (value = 1) then
			parts.Add(Output.LockedLabel());
		elsif (value = 2) then
			parts.Add(Output.UnlockedLabel());
		endif;
		value = selectedTags(Form);
		if (value <> "") then
			parts.Add(Output.TagsFilter() + ": " + value);
		endif;
		if (parts.Count() = 0) then
			label.Title = Output.OptionsLabelShow();
		else
			label.Title = Output.FilterLabelShow() + StrConcat(parts, " | ");
		endif;
	endif;

EndProcedure

&AtClientAtServerNoContext
Function selectedTags(Form)

	set = new Array();
	for each item in Form.TagsFilter do
		if (item.Check) then
			set.Add(item.Presentation);
		endif;
	enddo;
	return StrConcat(set, ", ");

EndFunction

&AtClient
Procedure OnOpen(Cancel)

	saveOldParent();
	ScenariosPanel.Push(ThisObject);
	initProperties();
	Appearance.Apply(ThisObject);
	if (not Object.Ref.IsEmpty()) then
		syncScenario();
		AttachIdleHandler("activateEditor", 0.1, true);
	endif;
	setTitle();

EndProcedure

&AtClient
Procedure saveOldParent()

	OldParent = Object.Parent;

EndProcedure

&AtClient
Procedure initProperties()

	if (TestManager = true) then
		TestedMode = true;
	else
		TestedMode = false;
	endif;

EndProcedure

&AtServer
Procedure loadScenario(val Scenario)

	exists = (Scenario <> undefined);
	if (exists) then
		obj = Scenario.GetObject();
	else
		obj = Catalogs.Scenarios.CreateItem();
		FillPropertyValues(obj, Object, "Parent, Application, Type, Creator");
	endif;
	ValueToFormAttribute(obj, "Object");
	if (exists) then
		restoreTemplate(obj);
	endif;
	readStatus();
	Appearance.Apply(ThisObject);

EndProcedure

&AtClient
Procedure syncScenario()

	Items.List.CurrentRow = Object.Ref;

EndProcedure

&AtClient
Procedure activateEditor()

	CurrentItem = Items.Script;

EndProcedure

&AtClient
Procedure setTitle()

	ref = Object.Ref;
	if (ref.IsEmpty()) then
		Title = Output.NewScenario();
	else
		Title = ?(ref = SessionScenario, "►", "") + Object.Path;
	endif;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	if (EventName = Enum.MessageSaveAll()) then
		if (Locked) then
			if (isModified()) then
				Write();
			endif;
		endif;
	elsif (EventName = Enum.MessageLocked()
			or EventName = Enum.MessageApplicationChanged()
			or EventName = Enum.MessageReload()) then
		if (Parameter.Find(Object.Ref) <> undefined) then
			reload();
			setTitle();
		endif;
	elsif (EventName = Enum.MessageStored()) then
		if (Parameter.Find(Object.Ref) <> undefined) then
			unlock();
		endif;
	elsif (EventName = Enum.MessageSave()) then
		if (Locked and Parameter.Find(Object.Ref) <> undefined) then
			if (isModified()) then
				Write();
			endif;
		endif;
	elsif (EventName = Enum.MessageActivateError()
			or EventName = Enum.MessageDebugger()) then
		if (Source = Object.Ref) then
			activateEditor();
			activateRow(Parameter);
		endif;
	elsif (EventName = Enum.MessageMainScenarioChanged()) then
		setTitle();
	endif;

EndProcedure

&AtClient
Function isModified()

// Modified flag will not appear unless editor box looses focus
	editor = Items.Script;
	if (CurrentItem = editor) then
		CurrentItem = Items.Description;
		CurrentItem = editor;
	endif;
	return Modified;

EndFunction

&AtServer
Procedure reload()

	if (Object.Ref.IsEmpty()) then
		return;
	endif;
	obj = Object.Ref.GetObject();
	obj.Unlock();
	ValueToFormAttribute(obj, "Object");
	Modified = false;
	readStatus();
	restoreTemplate(obj);
	applicationFixed(ThisObject);
	filterByApplication();
	showFilters(ThisObject);
	Appearance.Apply(ThisObject);

EndProcedure

&AtServer
Procedure unlock()

	readStatus();
	if (not Locked) then
		UnlockFormDataForEdit();
	endif;
	Appearance.Apply(ThisObject, "Locked");

EndProcedure

&AtClient
Procedure activateRow(Line)

	Items.Script.SetTextSelectionBounds(Line, 1, Line, StrLen(StrGetLine(Object.Script, Line)) + 1);

EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)

	if (TypeOf(SelectedValue) = Type("String")) then
		applyAssistant(SelectedValue, false, false);
	endif;

EndProcedure

&AtClient
Procedure applyAssistant(Replacement, Picking, Comment)

	multiline = StrLineCount(Replacement) > 1;
	if (multiline) then
		getSelection();
		if (ColumnStart = 1) then
			text = Replacement;
		else
			text = Chars.LF + Replacement;
		endif;
	else
		text = Replacement;
	endif;
	if (Picking) then
		text = text + Chars.LF;
	endif;
	if (Comment) then
		text = "//" + text;
	endif;
	Items.Script.SelectedText = text;

EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)

	type = TypeOf(NewObject);
	if (type = Type("CatalogRef.Tags")) then
		insertTag(String(NewObject), Items.TagsList.ChoiceList);
		initTagsFilter();
	endif;

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)

	if (not ScenarioForm.CheckName(Object.Description)) then
		Output.ScenarioIDError ( , "Description" );
		Cancel = true;
	endif;

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	if (not ScenarioForm.SaveParents(Object, OldParent)) then
		Cancel = true;
	endif;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	saveTags(CurrentObject);
	if (TemplateChanged) then
		prepareTempale();
		saveTemplate(CurrentObject);
	endif;

EndProcedure

&AtServer
Procedure saveTags(CurrentObject)

	CurrentObject.Tag = Catalogs.TagKeys.Pick(Items.TagsList.ChoiceList.UnloadValues());

EndProcedure

&AtServer
Procedure prepareTempale()

	begin = undefined;
	end = undefined;
	marker = getMarker();
	while (true) do
		begin = TabDoc.FindText("{", end);
		if (begin = undefined) then
			break;
		endif;
		end = begin;
		if (isTemplate(begin.Text)) then
			begin.TextColor = marker;
		endif;
	enddo;

EndProcedure

&AtClientAtServerNoContext
Function getMarker()

	return new Color(255, 0, 255);

EndFunction

&AtClientAtServerNoContext
Function isTemplate(Text)

	s = TrimAll(Text);
	return StrStartsWith(s, "{") and StrEndsWith(s, "}");

EndFunction

&AtServer
Procedure saveTemplate(CurrentObject)

	restoreAreas();
	CurrentObject.Template = new ValueStorage(TabDoc);
	CurrentObject.Spreadsheet = (TabDoc.TableHeight + TabDoc.TableWidth) > 0;
	TemplateChanged = false;

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	markAreas();
	if (tagsFiltered()) then
		filterByTag();
	endif;
	Appearance.Apply(ThisObject, "Object.Ref");

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ScenarioForm.RereadParents(Object, OldParent);
	saveOldParent();
	setTitle();
	ScenariosPanel.Push(ThisObject);
	RepositoryFiles.Sync();
	resetCursor();

EndProcedure

&AtClient
Procedure resetCursor()

	// Bug workaround: the following actions try to avoid
	// undefined behaviour of cursor position in Text Editor
	OldCurrentItem = CurrentItem;
	CurrentItem = Items.Description;
	CurrentItem = OldCurrentItem;

EndProcedure

&AtClient
Procedure OnClose(Exit)

	ScenariosPanel.Pop(Object.Ref);

EndProcedure

&AtClient
Procedure Reread() export

	rereadMyself();
	saveOldParent();
	setTitle();

EndProcedure

&AtServer
Procedure rereadMyself()

	obj = Object.Ref.GetObject();
	ValueToFormAttribute(obj, "Object");
	readMyself(obj);

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Restart(Command)

	OpenForm("Catalog.Scenarios.Form.Restart");

EndProcedure

&AtClient
Procedure RunSelected(Command)

	runCode();
	activateEditor();

EndProcedure

&AtClient
Procedure runCode()

	getSelection();
	ModuleCode = getBlock();
	Test.Exec(Object.Ref, , ModuleCode, , SelectionStart);

EndProcedure

&AtClient
Procedure getSelection()

	Items.Script.GetTextSelectionBounds(RowStart, ColumnStart, RowEnd, ColumnEnd);
	SelectionStart = RowStart;
	SelectionEnd = RowEnd;
	if (ColumnStart = ColumnEnd and ColumnStart = 1) then
		SelectionEnd = Max(SelectionStart, SelectionEnd - 1);
	endif;

EndProcedure

&AtClient
Function getBlock()

	text = Object.Script;
	rows = new Array();
	for i = SelectionStart to SelectionEnd do
		rows.Add(StrGetLine(text, i));
	enddo;
	return StrConcat(rows, Chars.LF);

EndFunction

&AtClient
Procedure Comment(Command)

	commentScript();
	activateEditor();

EndProcedure

&AtClient
Procedure commentScript()

	getSelection();
	insertComments();
	restoreSelection();

EndProcedure

&AtClient
Procedure insertComments()

	text = Object.Script;
	rows = new Array();
	for i = SelectionStart to SelectionEnd do
		row = StrGetLine(text, i);
		rows.Add("//" + row);
	enddo;
	replaceSelection(rows);

EndProcedure

&AtClient
Procedure replaceSelection(Rows)

	control = Items.Script;
	control.SetTextSelectionBounds(SelectionStart, 1, SelectionEnd, 2
		+ StrLen(StrGetLine(Object.Script, SelectionEnd)));
	control.SelectedText = StrConcat(rows, Chars.LF);

EndProcedure

&AtClient
Procedure restoreSelection()

	control = Items.Script;
	control.SetTextSelectionBounds(RowStart, ColumnStart, RowEnd, ColumnEnd);

EndProcedure

&AtClient
Procedure Uncomment(Command)

	uncommentScript();
	activateEditor();

EndProcedure

&AtClient
Procedure uncommentScript()

	getSelection();
	removeComments();
	restoreSelection();

EndProcedure

&AtClient
Procedure removeComments()

	text = Object.Script;
	rows = new Array();
	for i = SelectionStart to SelectionEnd do
		row = StrGetLine(text, i);
		if (Lexer.IsComment(row)) then
			rows.Add(Mid(row, 3));
		else
			rows.Add(row);
		endif;
	enddo;
	replaceSelection(rows);

EndProcedure

&AtClient
Procedure GotoDefinition(Command)

	openSubScenario();
	activateEditor();

EndProcedure

&AtClient
Procedure openSubScenario()

	scenario = getScenario();
	if (scenario = undefined) then
		return;
	endif;
	OpenForm("Catalog.Scenarios.ObjectForm", new Structure("Key", scenario), Items.List);

EndProcedure

&AtClient
Function getScenario()

	getSelection();
	s = StrGetLine(Object.Script, RowStart);
	return findScenario(s, Object.Application, ?(Object.Tree, Object.Ref, Object.Parent));

EndFunction

&AtServerNoContext
Function findScenario(val Row, val Application, val Parent)

	variants = new Array();
	variants.Add(getSignature("call|вызвать", 1, 3));
	variants.Add(getSignature("run|позвать", 1, 3, Parent));
	variants.Add(getSignature("test.start", 1, 2));
	variants.Add(getSignature("callserver|вызватьсервер ", 2, 4));
	variants.Add(getSignature("runserver|позватьсервер ", 2, 4, Parent));
	for each variant in variants do
		p = extractParams(variant, Row);
		if (p <> undefined) then
			return RuntimeSrv.FindScenario(p.Scenario, Application, p.Application, variant.Parent, true);
		endif;
	enddo;

EndFunction

&AtServerNoContext
Function getSignature(Names, Scenario, Application, Parent = undefined)

	return new Structure("Names, Scenario, Application, Parent", Names, Scenario, Application, Parent);

EndFunction

&AtServerNoContext
Function extractParams(Variant, Row)

	params = getParams(Variant.Names, Row);
	if (params = undefined) then
		return undefined;
	endif;
	count = params.Count();
	i = Variant.Scenario;
	if (count < i) then
		return undefined;
	endif;
	scenario = params[i - 1];
	i = Variant.Application;
	app = ?(count < i, undefined, params[i - 1]);
	return new Structure("Scenario, Application", scenario, app);

EndFunction

&AtServerNoContext
Function getParams(Functions, Row)

	exp = Regexp.Create();
	exp.Pattern = "(" + Functions + ")(\(| +\()(.+)\)";
	matches = exp.Execute(Row);
	if (matches.Count = 0) then
		return undefined;
	endif;
	params = StrSplit(matches.Item(0).Submatches.Item(2), ",");
	for i = 0 to params.UBound() do
		params[i] = TrimAll(StrReplace(params[i], """", ""));
	enddo;
	return ?(params.Count() = 0, undefined, params);

EndFunction

&AtClient
Procedure FindDefinition(Command)

	scenario = getScenario();
	if (scenario = undefined) then
		return;
	endif;
	Items.List.CurrentRow = scenario;
	activateList();

EndProcedure

&AtClient
Procedure ActivateTree(Command)

	activateList();

EndProcedure

&AtClient
Procedure activateList()

	CurrentItem = Items.List;

EndProcedure

&AtClient
Procedure NewScenario(Command)

// Bug workaround 8.3.8.2088:
	// I have to create special command because standard form command disables F5 shortcut
	OpenForm("Catalog.Scenarios.ObjectForm");

EndProcedure

&AtClient
Procedure SyncTree(Command)

	if (Object.Ref.IsEmpty()) then
		Write();
	endif;
	applicationChanged = applicationFixed(ThisObject);
	searchUsed = SearchString <> "";
	if (applicationChanged or searchUsed) then
		resetFilters(applicationChanged, searchUsed);
	endif;
	syncScenario();
	activateList();

EndProcedure

&AtServer
Procedure resetFilters(val Application, val Search)

	if (Application) then
		filterByApplication();
		showFilters(ThisObject);
	endif;
	if (Search) then
		SearchString = "";
		applySearch();
	endif;

EndProcedure

&AtClient
Procedure CheckSyntax(Command)

	checkCode();
	activateEditor();

EndProcedure

&AtClient
Procedure checkCode()

	Test.CheckSyntax(Object.Script);

EndProcedure

&AtClient
Procedure Assist(Command)

	openAssistant ();

EndProcedure

&AtClient
Procedure openAssistant ()
	
	Test.AttachApplication ( Object.Ref );
	OpenForm ( "Catalog.Assistant.ChoiceForm", , ThisObject );
	
EndProcedure 

&AtClient
Procedure DescriptionOnChange(Item)

	Object.Description = TrimAll(Object.Description);

EndProcedure

&AtClient
Procedure InsertID(Command)

	insertIdentifier();

EndProcedure

&AtClient
Procedure insertIdentifier()

	Items.Script.SelectedText = Environment.GenerateID();

EndProcedure

&AtClient
Procedure StartRecording(Command)

	if (SessionScenario.IsEmpty()) then
		Output.SetupMainScenario(ThisObject, Object.Ref);
	else
		openRecording();
	endif;

EndProcedure

&AtClient
Procedure Convert(Command)

	openConversion();

EndProcedure

&AtClient
Procedure openConversion()

	OpenForm("Catalog.Scenarios.Form.Convert", , , , , , new NotifyDescription("Converting", ThisObject));

EndProcedure

&AtClient
Procedure SetupMainScenario(Answer, Scenario) export

	if (Answer = DialogReturnCode.No) then
		return;
	endif;
	Environment.ChangeScenario(Scenario);
	openRecording();

EndProcedure

&AtClient
Procedure openRecording()

	OpenForm("Catalog.Scenarios.Form.Record", , ThisObject, , , , new NotifyDescription("Converting", ThisObject));

EndProcedure

&AtClient
Procedure Converting(Data, Params) export

	if (Data = undefined) then
		return;
	endif;
	Log = Data.Log;
	Items.Script.SelectedText = transpile(Data, Object.Script);

EndProcedure

&AtServerNoContext
Function transpile(val Data, val Script)

	mode = Data.Mode;
	if (mode = Enums.Recording.Tester) then
		return DataProcessors.TranspilerTester.Perform(Data.Log, Data.Lang, findConnect(Script));
	else
		return DataProcessors.TranspilerRaw.Perform(Data.Log, Data.Lang, mode = Enums.Recording.Smart, findConnect(Script));
	endif;

EndFunction

&AtServerNoContext
Function findConnect(Script)

	exp = Regexp.Create();
	exp.Pattern = "(^|\s+)(connect\W|подключить\W)";
	return exp.Test(Script);

EndFunction

&AtClient
Procedure PickAction(Command)

	ScenarioForm.Picking(ThisObject, false);

EndProcedure

&AtClient
Procedure FormatTable ( Command )
	
	getSelection ();
	evalRange = SelectionStart = SelectionEnd;
	table = extractSelection ( evalRange );
	text = TableProcessor.Formatting ( table.Text, table.Indent );
	control = Items.Script;
	if ( evalRange ) then
		control.SetTextSelectionBounds ( table.Start, 1, table.Finish + 1, 1 );
		control.SelectedText = text + Chars.LF;
		restoreSelection ();
	else
		control.SelectedText = text + ? ( ColumnEnd = 1, Chars.LF, "" );
	endif;

EndProcedure

&AtClient
Function extractSelection ( EvalRange )
	
	rows = new Array ();
	indent = undefined;
	if ( EvalRange ) then
		start = evalTableStart ();
		finish = evalTableEnd ();
	else
		start = SelectionStart;
		finish = SelectionEnd;
	endif;
	script = Object.Script;
	for i = start to finish do
		s = StrGetLine ( script, i );
		data = extractTablePart ( s, 2 );
		if ( data = undefined ) then
			continue;
		endif;
		indent = data.Indent;
		rows.Add ( data.Text );
	enddo;
	return new Structure ( "Text, Indent, Start, Finish", StrConcat ( rows, Chars.LF ), indent, start, finish );
	
EndFunction

&AtClient
Function evalTableStart ()
	
	script = Object.Script;
	i = SelectionStart;
	while ( i > 0 ) do
		s = StrGetLine ( script, i );
		if ( extractTablePart ( s, 1 ) ) then
			return i + 1;
		elsif ( extractTablePart ( s, 2 ) = undefined
			and not extractTablePart ( s, 3 ) ) then
			break;
		endif;
		i = i - 1;
	enddo;
	raise Output.TableDefinitionNotFound ();

EndFunction

&AtClient
Function extractTablePart ( Row, Part )
	
	rex = Regexp.Create ();
	result = new Structure ( "Indent, Text" );
	if ( Part = 1 ) then
		// Definition begins
		// = "text
		// ( "text
		rex.Pattern = "((=(\s+)?"")|(\((\s+)?""))(.+)?";
		return rex.Test ( Row );
	elsif ( Part = 2 ) then
		// Header or Row
		// | text
		rex.Pattern = "^(\s+)?\|(.+)?";
		matches = rex.Execute ( Row );
		if ( matches.Count = 0 ) then
			return undefined;
		else
			set = matches.Item ( 0 );
			result.Indent = set.Submatches ( 0 );
			result.Text = set.Submatches ( 1 );
		endif; 
	else
		// Definition ends
		// | text";
		// | text" )
		rex.Pattern = "(^(\s+)?\|)(.+)?""(\s+)?(\)|;)";
		return rex.Test ( Row );
	endif;
	return result;
	
EndFunction

&AtClient
Function evalTableEnd ()
	
	script = Object.Script;
	eof = StrLineCount ( script );
	for i = SelectionStart to eof do
		s = StrGetLine ( script, i );
		if ( extractTablePart ( s, 3 ) ) then
			return i - 1;
		elsif ( not extractTablePart ( s, 1 )
			and extractTablePart ( s, 2 ) = undefined ) then
			break;
		endif;
	enddo;
	raise Output.TableDefinitionNotFound ();
	
EndFunction

&AtClient
Procedure AddBreakpoint(Command)

	insertDebugger();

EndProcedure

&AtClient
Procedure insertDebugger()

	lang = CurrentLanguage();
	s = ?(lang = "ru", "ОтладкаСтарт ();", "DebugStart ();") + Chars.LF;
	Items.Script.SelectedText = s;

EndProcedure

&AtClient
Procedure ShowScenarios(Command)

	togglePanel();

EndProcedure

&AtClient
Procedure togglePanel()

	HidePanel = not HidePanel;
	Appearance.Apply(ThisObject, "HidePanel");

EndProcedure

// *****************************************
// *********** Group Filters
&AtClient
Procedure QuickFilterStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = false;

EndProcedure

&AtClient
Procedure QuickFilterClearing(Item, StandardProcessing)

	resetSearch();
	activateList();

EndProcedure

&AtClient
Procedure resetSearch()

	SearchString = "";
	filterScenario();

EndProcedure

&AtClient
Procedure filterScenario() export

	applySearch();
	OldScenario = undefined;

EndProcedure

&AtServer
Procedure applySearch()

	setView();
	refs = FullSearch.Refs(SearchString, Enums.Search.Scenarios);
	DC.ChangeFilter(List, "Ref", refs, not IsBlankString(SearchString), DataCompositionComparisonType.InList);

EndProcedure

&AtClient
Procedure QuickFilterEditTextChange(Item, Text, StandardProcessing)

	DetachIdleHandler("filterScenario");
	SearchString = Text;
	AttachIdleHandler("filterScenario", 0.4, true);

EndProcedure

&AtClient
Procedure ShowOptionsLabelClick(Item)

	ShowOptions = not ShowOptions;
	Appearance.Apply(ThisObject, "ShowOptions");
	showFilters(ThisObject);

EndProcedure

&AtClient
Procedure ApplicationFilterOnChange(Item)

	filterByApplication();
	activateList();

EndProcedure

&AtClient
Procedure WorkplaceFilterOnChange(Item)

	applyWorkplace();

EndProcedure

&AtServer
Procedure applyWorkplace()

	LoginsSrv.SaveSettings(Enum.SettingsWorkplaceFilter(), , WorkplaceFilter);
	filterByWorkplace();

EndProcedure

&AtClient
Procedure StatusFilterOnChange(Item)

	applyStatusFilter();
	activateList();

EndProcedure

&AtServer
Procedure applyStatusFilter()

	setView();
	filterByStatus();

EndProcedure

&AtServer
Procedure filterByStatus()

	if (StatusFilter = 2) then
		DC.ChangeFilter(List, "Locked", 1, true, DataCompositionComparisonType.NotEqual);
	else
		DC.ChangeFilter(List, "Locked", StatusFilter, StatusFilter <> 0);
	endif;

EndProcedure

&AtClient
Procedure DeletionFilterOnChange(Item)

	filterByDeletion();

EndProcedure

&AtClient
Procedure TagsFilterOnChange(Item)

	applyTagsFilter();

EndProcedure

&AtServer
Procedure applyTagsFilter()

	setView();
	filterByTag();

EndProcedure

&AtServer
Procedure filterByTag()

	tags = gatherTags();
	DC.ChangeFilter(List, "Tag", gatherKeys(Tags), tags.Count() > 0, DataCompositionComparisonType.InList);

EndProcedure

&AtServer
Function gatherTags()

	set = new Array();
	for each item in TagsFilter do
		if (item.Check) then
			set.Add(item.Value);
		endif;
	enddo;
	return set;

EndFunction

&AtServer
Function gatherKeys(Tags)

	if (Tags.Count() = 0) then
		result = new Array();
	else
		s = "
			|select Keys.Ref as Ref
			|from Catalog.Tags as Tags
			|	//
			|	// Tags
			|	//
			|	left join (
			|		select Keys.Ref as Ref, Tags.Ref as Tag, case when Keys.Tag = Tags.Ref then 1 else 0 end as Selected
			|		from Catalog.TagKeys.Tags as Keys, Catalog.Tags as Tags
			|		where not Keys.Ref.DeletionMark
			|	) as Keys
			|	on Keys.Tag = Tags.Ref
			|where Tags.Ref in ( &Tags )
			|group by Keys.Ref
			|having sum ( Keys.Selected ) = &TagsCount
			|";
		q = new Query(s);
		q.SetParameter("Tags", Tags);
		q.SetParameter("TagsCount", Tags.Count());
		result = q.Execute().Unload().UnloadColumn("Ref");
	endif;
	return result;

EndFunction

&AtClient
Procedure TagsFilterBeforeRowChange(Item, Cancel)

	if (Item.CurrentItem.Name = "TagsFilterValue") then
		Cancel = true;
		toggleTagsFilter();
	endif;

EndProcedure

&AtClient
Procedure toggleTagsFilter()

	row = Items.TagsFilter.CurrentData;
	// The code does not work in 8.3.11.2924:
	// row.Check = not row.Check;
	//
	// Workaround is used:
	TagsFilter.FindByValue(row.Value).Check = not row.Check;
	applyTagsFilter();

EndProcedure

// *****************************************
// *********** Group List
&AtClient
Procedure SetCurrent(Command)

	Environment.ChangeApplication(ApplicationFilter);

EndProcedure

&AtClient
Procedure OpenHere(Command)

	applyScenario(TableRow.Ref);

EndProcedure

&AtClient
Procedure applyScenario(Scenario)

	if (Scenario = Object.Ref) then
		return;
	endif;
	if (Modified) then
		Write();
	endif;
	ScenariosPanel.Pop(Object.Ref);
	loadScenario(Scenario);
	ScenariosPanel.Push(ThisObject);
	setTitle();
	activateEditor();

EndProcedure

&AtClient
Procedure FindMain(Command)

	findHead();

EndProcedure

&AtClient
Procedure findHead()

	if (SessionScenario.IsEmpty()) then
		Output.MainScenarioUndefined();
	else
		Items.List.CurrentRow = SessionScenario;
		activateList();
	endif;

EndProcedure

&AtClient
Procedure RefreshList(Command)

	Items.List.Refresh();

EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)

	TableRow = Item.CurrentData;
	AttachIdleHandler("showCode", 0.1, true);

EndProcedure

&AtClient
Procedure showCode() export

	if (TableRow = undefined) then
		CodePreview = "";
		return;
	endif;
	if (TableRow.Ref = OldScenario) then
		return;
	endif;
	OldScenario = TableRow.Ref;
	CodePreview = preview(OldScenario, adjustText(Items.QuickFilter.EditText));

EndProcedure

&AtClientAtServerNoContext
Function adjustText(Text)

	if (IsBlankString(Text)) then
		return "";
	endif;
	parts = Conversion.StringToArray(Lower(Text), " ");
	s = "";
	for each part in parts do
		if (part = "") then
			continue;
		endif;
		s = s + " " + part;
	enddo;
	return Mid(s, 2);

EndFunction

&AtServerNoContext
Function preview(val Scenario, val Highlighting) export

	return "
		|<html>
		|<head>
		|<style>" + styles() + "</style>
		|<script type=""text/javascript"">" + scripts() + "</script>
		|</head>
		|<body onload=""highlightWord('" + Highlighting + "')"">
		|<pre>" + body(Scenario) + "</pre>
		|</body>
		|</html>";

EndFunction

&AtServerNoContext
Function styles()

	s = "
		|.yellow{
		|	background-color:yellow;
		|	color:black;
		|}
		|";
	return s;

EndFunction

&AtServerNoContext
Function scripts()

	s = "
		|function highlightWord(searchString) {
		|	if ( searchString == '' ) return;
		|	var nodes = textNodesUnder(document.body);
		|	var words = searchString.split(' ');
		|	for (var i in nodes) {
		|		highlightWords(nodes[i], words);
		|	}
		|}
		|function textNodesUnder(node) {
		|	var all = [];
		|	for (node = node.firstChild; node; node = node.nextSibling) {
		|		if (node.nodeType == 3) all.push(node);
		|		else all = all.concat(textNodesUnder(node));
		|	}
		|	return all;
		|}
		|function highlightWords(n, words) {
		|	for (var i in words) {
		|		var word = words[i].toLowerCase ();
		|		for (var j; (j = n.nodeValue.toLowerCase().indexOf(word, j)) > -1; n = after) {
		|			var after = n.splitText(j + word.length);
		|			var highlighted = n.splitText(j);
		|			var span = document.createElement('span');
		|			span.className = 'yellow';
		|			span.appendChild(highlighted);
		|			after.parentNode.insertBefore(span, after);
		|		}
		|	}
		|}
		|";
	return s;

EndFunction

&AtServerNoContext
Function body(val Scenario)

	body = DF.Pick(Scenario, "Script");
	return Conversion.XMLToStandard(body);

EndFunction

&AtClient
Procedure ListSelection(Item, SelectedRow, Field, StandardProcessing)

	if (hierarchy()) then
		StandardProcessing = false;
		processHierarchy();
	endif;

EndProcedure

&AtClient
Function hierarchy()

	type = TableRow.Type;
	return TableRow.Tree and (type = PredefinedValue("Enum.Scenarios.Folder")
		or type = PredefinedValue("Enum.Scenarios.Library"));

EndFunction

&AtClient
Procedure processHierarchy()

	tree = Items.List;
	row = tree.CurrentRow;
	if (tree.Expanded(row)) then
		tree.Collapse(row);
	else
		tree.Expand(row);
	endif;

EndProcedure

&AtClient
Procedure ListDrag(Item, DragParameters, StandardProcessing, Row, Field)

	ScenarioForm.ListDrag(ThisObject, DragParameters, StandardProcessing, Row);

EndProcedure

// *****************************************
// *********** Table FieldsTable

&AtClient
Procedure FetchFields(Command)

	fill(false);
	expandTree();

EndProcedure

&AtClient
Procedure fill(ActiveOnly)

	scenario = Object.Ref;
	Test.AttachApplication(scenario);
	Test.ConnectClient(false);
	initTree();
	source = ?(ActiveOnly, App.GetActiveWindow(), App);
	fillTree(FieldsTable.GetItems(), source.GetChildObjects());

EndProcedure

&AtClient
Procedure initTree()

	rows = FieldsTable.GetItems();
	rows.Clear();
	FieldsMap = new Map();
	TestedForm = undefined;

EndProcedure

&AtClient
Procedure fillTree(Rows, Objects)

	form = PredefinedValue("Enum.Controls.Form");
	for each obj in Objects do
		try
			next = obj.GetChildObjects(); // For some particular forms, testmanager gets error
		except
			continue;
		endtry;
		row = Rows.Add();
		FillPropertyValues(row, obj);
		type = ScenarioForm.FieldType(obj);
		row.Type = type;
		row.Picture = ScenarioForm.GetPicture(type);
		if (row.Name = "") then
			row.Name = "<" + ?(row.FormName = "", type, row.FormName) + ">";
		endif;
		id = row.GetID();
		FieldsMap[id] = obj; // TestedField cannot be used as a key
		if (next.Count() > 0) then
			fillTree(row.GetItems(), next);
		endif;
		if (type = form) then
			TestedForm = obj;
		endif;
	enddo;

EndProcedure

&AtClient
Procedure FetchActive(Command)

	fill(true);
	expandTree();

EndProcedure

&AtClient
Procedure Sync(Command)

	syncItem();

EndProcedure

&AtClient
Procedure syncItem()

	if (TestedForm = undefined) then
		return;
	endif;
	try
		item = TestedForm.GetCurrentItem();
	except
		return;
	endtry;
	for each field in FieldsMap do
		if (field.Value = item) then
			Items.FieldsTable.CurrentRow = field.Key;
			break;
		endif;
	enddo;

EndProcedure

&AtClient
Procedure Expand(Command)

	expandTree();

EndProcedure

&AtClient
Procedure expandTree()

	tree = Items.FieldsTable;
	rows = FieldsTable.GetItems();
	for each row in rows do
		tree.Expand(row.GetID(), true);
	enddo;

EndProcedure

&AtClient
Procedure Collapse(Command)

	collapseTree(FieldsTable.GetItems());

EndProcedure

&AtClient
Procedure collapseTree(Rows)

	tree = Items.FieldsTable;
	for each row in rows do
		next = row.GetItems();
		if (next.Count() > 0) then
			collapseTree(next);
		endif;
		tree.Collapse(row.GetID());
	enddo;

EndProcedure

&AtClient
Procedure ExpressionOnChange(Item)

	calcResult();

EndProcedure

&AtClient
Procedure calcResult()

	if (FieldsRow = undefined or IsBlankString(Expression)) then
		ExpressionResult = "";
	else
		try
			ExpressionResult = Eval("FieldsMap [ FieldsRow.GetID () ]." + Expression);
		except
			ExpressionResult = BriefErrorDescription(ErrorInfo());
		endtry;
	endif;

EndProcedure

&AtClient
Procedure ExpressionStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = false;
	calcResult();

EndProcedure

&AtClient
Procedure FieldsTableOnActivateRow(Item)

	FieldsRow = Item.CurrentData;
	AttachIdleHandler("activateItem", 0.1, true);

EndProcedure

&AtClient
Procedure activateItem() export

	if (App = undefined or FieldsRow = undefined) then
		return;
	endif;
	field = FieldsMap[FieldsRow.GetID()];
	if (field <> undefined) then
		try
			field.Activate();
		except
		endtry;
	endif;

EndProcedure

&AtClient
Procedure FieldsTableSelection(Item, SelectedRow, Field, StandardProcessing)

	StandardProcessing = false;
	ScenarioForm.OpenAssistant(Items.FieldsTable, Items.FieldsTableName, true,
		tableForm(), Object.Application);

EndProcedure

&AtClient
Function tableForm()
	
	row = FieldsRow;
	form = PredefinedValue ( "Enum.Controls.Form" );
	while (true) do
		row = row.GetParent();
		if (row = undefined) then
			return "";
		elsif (row.Type = form) then
			return row.TitleText;
		endif;
	enddo;
	
EndFunction

&AtClient
Procedure FieldsTableChoiceProcessing(Item, SelectedValue, StandardProcessing)

	StandardProcessing = false;
	applyAction(SelectedValue);

EndProcedure

&AtClient
Procedure applyAction(Action)

	withActiveForm();
	if (TypeOf(Action) = Type("String")) then
		applyAssistant(Action, true, false);
	else
		error = not ScenarioForm.ApplyAction(Action);
		applyAssistant(Action.Expression, true, error);
	endif;

EndProcedure

&AtClient
Procedure withActiveForm()

	#if ( ThinClient or ThickClientManagedApplication ) then
		form = PredefinedValue("Enum.Controls.Form");
		row = FieldsRow;
		while (row <> undefined) do
			if (row.Type = form) then
				With(row.TitleText);
				return;
			endif;
			row = row.GetParent();
		enddo;
	#endif

EndProcedure

// *****************************************
// *********** Group Template
&AtClient
Procedure TabDocOnChange(Item)

	TemplateChanged = true;
	entitleTemplate(ThisObject);
	restoreAreas();
	markAreas();

EndProcedure

&AtClient
Procedure UseTemplate(Command)

	openReplacement();

EndProcedure

&AtClient
Procedure openReplacement()

	if (isPicture(TabDoc.CurrentArea)) then
		return;
	endif;
	text = TabDoc.CurrentArea.Text;
	if (IsBlankString(text)) then
		return;
	endif;
	p = new Structure("Text", text);
	OpenForm("Catalog.Scenarios.Form.Template", p, Items.TabDoc, , , , new NotifyDescription("ApplyTemplate", ThisObject, text));

EndProcedure

&AtClient
Function isPicture(Area)

	try
	//@skip-warning
		text = Area.Text;
	except
		return true;
	endtry;
	return false;

EndFunction

&AtClient
Procedure ApplyTemplate(Result, Text) export

	if (Result = undefined) then
		return;
	endif;
	template = Result.Template;
	if (Lower(template) = Lower(Text)) then
		return;
	endif;
	Modified = true;
	TemplateChanged = true;
	marker = ?(isTemplate(template), getMarker(), undefined);
	if (Result.Everywhere) then
		while (true) do
			area = TabDoc.FindText(Text, , , , true, , true);
			if (area = undefined) then
				break;
			endif;
			replaceValue(area, template, marker);
		enddo;
	else
		replaceValue(TabDoc.CurrentArea, template, marker);
	endif;

EndProcedure

&AtClient
Procedure replaceValue(Area, Text, Marker)

	Area.Text = Text;
	if (Marker <> undefined) then
		Area.TextColor = Marker;
	endif;

EndProcedure

&AtClient
Procedure CheckArea(Command)

	attachAreas();

EndProcedure

&AtClient
Procedure attachAreas()

	names = new Array();
	for each area in TabDoc.SelectedAreas do
		if (isPicture(area)) then
			continue;
		endif;
		name = area.Name;
		areas = Object.Areas.FindRows(new Structure("Name", name));
		if (areas.Count() = 0) then
			names.Add(name);
			row = Object.Areas.Add();
			row.Name = name;
			row.Top = area.Top;
			row.Left = Max(area.Left, 1);
			row.Bottom = area.Bottom;
			row.Right = ?(area.Right = 0, TabDoc.TableWidth, area.Right);
		endif;
	enddo;
	if (names.Count() > 0) then
		markAreas(names);
	endif;

EndProcedure

&AtClient
Procedure ClearAreas(Command)

	restoreAreas();
	Object.Areas.Clear();

EndProcedure

&AtServer
Procedure restoreAreas(Name = undefined)

	savedAreas = getSavedAreas();
	if (savedAreas.Count() = 0) then
		return;
	endif;
	if (Name = undefined) then
		for each area in savedAreas do
			unmarkArea(area.Value, area.Key);
		enddo;
		savedAreas.Clear();
		saveAreas(savedAreas);
	else
		unmarkArea(savedAreas[Name], Name);
		savedAreas.Delete(Name);
		saveAreas(savedAreas);
	endif;

EndProcedure

&AtServer
Procedure unmarkArea(Source, Name)

	receiver = TabDoc.Area(Name);
	for i = 1 to source.TableHeight do
		for j = 1 to source.TableWidth do
			x = receiver.Top + i - 1;
			y = receiver.Left + j - 1;
			sourceCell = source.Area(i, j, i, j);
			receiverCell = TabDoc.Area(x, y, x, y);
			receiverCell.TopBorder = sourceCell.TopBorder;
			receiverCell.LeftBorder = sourceCell.LeftBorder;
			receiverCell.RightBorder = sourceCell.RightBorder;
			receiverCell.BottomBorder = sourceCell.BottomBorder;
			receiverCell.BorderColor = sourceCell.BorderColor;
		enddo;
	enddo;

EndProcedure

&AtClient
Procedure RemoveArea(Command)

	detachAreas();

EndProcedure

&AtClient
Procedure detachAreas()

	areas = Object.Areas;
	for each area in TabDoc.SelectedAreas do
		if (isPicture(area)) then
			continue;
		endif;
		for i = area.Top to area.Bottom do
			for j = area.Left to area.Right do
				k = areas.Count();
				while (k > 0) do
					k = k - 1;
					row = areas[k];
					if (row.Top <= i and i <= row.Bottom and row.Left <= j
							and j <= row.Right) then
						restoreAreas(row.Name);
						areas.Delete(k);
					endif;
				enddo;
			enddo;
		enddo;
	enddo;

EndProcedure

&AtClient
Procedure ClearTabDoc(Command)

	deleteTabDoc();
	TemplateChanged = true;
	entitleTemplate(ThisObject);

EndProcedure

&AtServer
Procedure deleteTabDoc()

	Object.Areas.Clear();
	TabDoc.Clear();

EndProcedure

// *****************************************
// *********** Tags
&AtClient
Procedure AddTag(Command)

	selectTag();

EndProcedure

&AtClient
Procedure selectTag()

	callback = new NotifyDescription("TagSelected", ThisObject);
	tags = getTags(Items.TagsList.ChoiceList.UnloadValues());
	menu = tags.Count();
	if (menu = 0) then
		Output.TagsListEmpty();
		return;
	elsif (menu = 1) then
		newTag();
	elsif (menu > 15) then
		ShowChooseFromList(callback, tags);
	else
		ShowChooseFromMenu(callback, tags);
	endif;

EndProcedure

&AtServerNoContext
Function getTags(val SelectedTags)

	s = "
		|select Tags.Description as Description
		|from Catalog.Tags as Tags
		|where not Tags.DeletionMark
		|and Tags.Description not in ( &Tags )
		|order by Description
		|";
	q = new Query(s);
	q.SetParameter("Tags", SelectedTags);
	tags = q.Execute().Unload().UnloadColumn("Description");
	list = new ValueList();
	list.LoadValues(tags);
	if (AccessRight("Edit", Metadata.Catalogs.Tags)) then
		list.Add(, Output.NewTag(), , PictureLib.CreateListItem);
	endif;
	return list;

EndFunction

&AtClient
Procedure newTag()

	callback = new NotifyDescription("TagCreated", ThisObject);
	OpenForm("Catalog.Tags.ObjectForm", , ThisObject, , , , callback);

EndProcedure

&AtClient
Procedure TagCreated(Tag, Params) export

	// For backward compatibility with versions < 8.3.11
	//@skip-warning
	noerrorshere = true;

EndProcedure

&AtClient
Procedure TagSelected(Tag, Params) export

	if (Tag = undefined) then
		return;
	endif;
	value = Tag.Value;
	if (value = undefined) then
		newTag();
	else
		insertTag(value, Items.TagsList.ChoiceList);
	endif;

EndProcedure

&AtClient
Procedure TagsListOnChange(Item)

	Output.TagRemovingConfirmation(ThisObject);

EndProcedure

&AtClient
Procedure TagRemovingConfirmation(Answer, Params) export

	if (Answer = DialogReturnCode.Yes) then
		removeTag();
	endif;
	TagsList = "";

EndProcedure

&AtClient
Procedure removeTag()

	set = Items.TagsList.ChoiceList;
	set.Delete(set.FindByValue(TagsList));

EndProcedure

// *****************************************
// *********** Access
&AtClient
Procedure AccessOnChange(Item)

	applyAccess();

EndProcedure

&AtClient
Procedure applyAccess()

	if (Object.Access) then
		defaultAccess();
	else
		Object.Users.Clear();
	endif;
	Appearance.Apply(ThisObject, "Object.Access");

EndProcedure

&AtClient
Procedure defaultAccess()

	table = Object.Users;
	if (table.Count() <> 0) then
		return;
	endif;
	creator = Object.Creator;
	row = table.Add();
	row.User = creator;
	user = EnvironmentSrv.User();
	if (user <> creator) then
		row = table.Add();
		row.User = user;
	endif;

EndProcedure
