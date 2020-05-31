Function Focus(Name, Source = undefined, Type = undefined) export
	
	place = Source;
	parts = StrSplit(encode(Name), "/");
	tableType = Type("TestedFormTable");
	rowWasLocated = (tableType = TypeOf(Source));
	for each part in parts do
		part = decode(part);
		data = findField(TrimAll(part), place, Type);
		field = data.Field;
		area = data.Area;
		placeIsTable = TypeOf(place) = tableType;
		rowWasLocated = rowWasLocated or placeIsTable;
		if (placeIsTable
				and place.GetSelectedRows().Count() = 0) then
			place.GotoFirstRow(false);
		endif;
		field.Activate();
		if (area <> undefined) then
			fieldType = field.Type;
			if (fieldType = FormFieldType.SpreadsheetDocumentField) then
				field.SetCurrentArea(area);
			elsif (not rowWasLocated
					and fieldType <> FormFieldType.LabelField) then
				locateRow(place, area);
			endif;
		endif;
		place = field;
	enddo;
	return data;
	
EndFunction

Function encode(Name)
	
	return StrReplace(Name, "\/", "27E9292F");
	
EndFunction

Function decode(Name)
	
	return StrReplace(Name, "27E9292F", "/");
	
EndFunction

Function findField(Name, Source = undefined, Type = undefined)
	
	result = new Structure("Field, Area, Parent");
	window = ?(Source = undefined, CurrentSource, Source);
	table = TypeOf(window) = Type("TestedFormTable");
	fieldType = getFieldType(Type);
	cell = cellInfo(Name);
	if (StrStartsWith(Name, "#")
			or StrStartsWith(Name, "!")) then
		if (cell = undefined) then
			result.Field = window.GetObject(fieldType, , Mid(Name, 2));
		else
			if (table) then
				locateRow(window, cell.Area);
			endif;
			result.Field = window.GetObject(fieldType, , Mid(cell.Field, 2));
			result.Area = cell.Area;
		endif;
	else
		if (cell = undefined) then
			objects = window.FindObjects(fieldType, Name);
		else
			if (table) then
				locateRow(window, cell.Area);
			endif;
			objects = window.FindObjects(fieldType, cell.Field);
			result.Area = cell.Area;
		endif;
		count = objects.Count();
		if (count = 0) then
			s = Name + ?(Type = undefined, "", " (" + Type + ")");
			raise Output.FieldNotFound(new Structure("Field", s));
		else
			if (count > 1) then
				showObjects(Name, objects);
			endif;
			result.Field = objects[0];
		endif;
	endif;
	result.Parent = window;
	return result;
	
EndFunction

Function cellInfo(Name)
	
	result = undefined;
	i = StrFind(Name, "[");
	if (i > 0) then
		j = StrFind(Name, "]", , i);
		if (j > 0) then
			result = new Structure();
			result.Insert("Field", TrimR(Left(Name, i - 1)));
			result.Insert("Area", TrimAll(Mid(Name, i + 1, j - i - 1)));
		endif;
	endif;
	return result;
	
EndFunction

Procedure locateRow(Table, Row)
	
	#if ( ThinClient or ThickClientManagedApplication ) then
	Table.Activate();
	try
		// This navigation is "just in case".
		// We do not care if first row is aready activated
		Table.GotoFirstRow(false);
	except
	endtry;
	column = SpecialFields.LineNo;
	field = Table.FindObject( , column);
	if (field = undefined
			or not field.CurrentVisible()) then
		for i = 1 to Number(Row) - 1 do
			Table.GotoNextRow(false);
		enddo;
	else
		search = new Map();
		search.Insert(column, Row);
		Table.GotoRow(search, RowGotoDirection.Down);
	endif;
	#endif
	
EndProcedure

Function Retrieve(Name, Source = undefined, Type = undefined) export
	
	place = Source;
	parts = StrSplit(encode(Name), "/");
	for each part in parts do
		part = decode(part);
		data = findField(TrimAll(part), place, Type);
		place = data.Field;
	enddo;
	return data;
	
EndFunction

Procedure showObjects(Field, Objects)
	
	types = new Array();
	types.Add(Type("TestedFormDecoration"));
	types.Add(Type("TestedFormField"));
	types.Add(Type("TestedFormGroup"));
	types.Add(Type("TestedFormButton"));
	places = new Array();
	for each obj in Objects do
		objType = TypeOf(obj);
		info = "" + objType;
		if (types.Find(objType) <> undefined) then
			info = info + " / " + obj.Type;
		endif;
		places.Add(obj.Name + " (" + info + ")");
	enddo;
	p = new Structure();
	p.Insert("Field", Field);
	p.Insert("Places", StrConcat(places, ", "));
	warning = Output.ManyPlaces(p);
	Runtime.ShowWarning(warning);
	
EndProcedure

Function getFieldType(Type)
	
	if (Type = undefined) then
		return undefined;
	elsif (Type = "Field"
			or Type = "Поле") then
		return Type("TestedFormField");
	elsif (Type = "Group"
			or Type = "Группа") then
		return Type("TestedFormGroup");
	elsif (Type = "Button"
			or Type = "Кнопка") then
		return Type("TestedFormButton");
	elsif (Type = "Table"
			or Type = "Таблица") then
		return Type("TestedFormTable");
	elsif (Type = "Decoration"
			or Type = "Декорация") then
		return Type("TestedFormDecoration");
	endif;
	
EndFunction

Function FetchValue(Field, Source = undefined, Type = undefined) export
	
	if (TypeOf(Field) = Type("String")) then
		data = Fields.Retrieve(Field, Source, Type);
		element = data.Field;
		area = data.Area;
		parent = data.Parent;
	else
		element = Field;
		area = undefined;
		parent = undefined;
	endif;
	tableType = Type("TestedFormTable");
	if (TypeOf(Source) = tableType) then
		element.Activate();
		if (area <> undefined) then
			locateRow(Source, area);
		endif;
		return Source.GetCellText();
	else
		elementType = element.Type;
		if (elementType = FormFieldType.SpreadsheetDocumentField) then
			return element.GetAreaText(?(area = undefined, element.GetCurrentAreaAddress(), area));
		else
			if (TypeOf(parent) = tableType) then
				return parent.GetCellText(element.Name);
			else
				return element.GetDataPresentation();
			endif;
		endif;
	endif;
	
EndFunction

Procedure CheckValue(Field, Value, Source = undefined, Type = undefined) export
	
	if (TypeOf(Source) = Type("TestedFormTable")) then
		// Bug workaroud for 8.3.7.1901: The method EndEditRow should be executed,
		// otherwise, system will be adding rows into the Table infinitely
		try
			Source.EndEditRow();
		except
		endtry;
	endif;
	result = Fields.FetchValue(Field, Source, Type);
	if (TableProcessor.ValuesEqual(result, Value)) then
		return;
	endif;
	p = new Structure();
	if (TypeOf(CurrentSource) = Type("TestedForm")) then
		form = CurrentSource.FormName;
		title = CurrentSource.TitleText;
	else
		form = "<...>";
		title = "<...>";
	endif;
	p.Insert("Form", form);
	p.Insert("Title", title);
	name = ?(TypeOf(Field) = Type("String"), Field, Field.TitleText);
	p.Insert("Field", name);
	p.Insert("Value", Value);
	p.Insert("Result", result);
	Runtime.ThrowError(Output.CheckError(p), Debug);
	
EndProcedure

Procedure CheckTableContent ( Table, Params, Options, Source ) export
	
	TableProcessor.CompareFieldAndTable ( Table, Params, Options, Source );
	
EndProcedure

Procedure CheckAppearance(Name, Value, Flag = true, Source = undefined, Type = undefined) export
	
	field = Fields.Retrieve(Name, Source, Type).Field;
	if (Value = "Visible"
			or Value = "Видимость") then
		state = field.CurrentVisible();
	elsif (Value = "Enable"
			or Value = "Доступность") then
		state = field.CurrentEnable();
	elsif (Value = "ReadOnly"
			or Value = "ТолькоЧтение") then
		state = field.CurrentReadOnly();
	else
		p = new Structure();
		p.Insert("Value", Value);
		Runtime.ThrowError(Output.CheckAppearanceIncorrect(p), Debug);
		return;
	endif;
	if (state = Flag) then
		return;
	endif;
	p = new Structure();
	p.Insert("Field", Name);
	p.Insert("Value", Value);
	p.Insert("Flag", Flag);
	p.Insert("State", state);
	Runtime.ThrowError(Output.CheckAppearanceError(p), Debug);
	
EndProcedure

Procedure CheckSpreadsheet(Name, Source = undefined, Type = undefined, Template = undefined) export
	
	if (Template = undefined) then
		stack = Debug.Stack[Debug.Level];
		spreadsheet = RuntimeSrv.GetSpreadsheet(stack.Module, stack.IsVersion);
		if (spreadsheet = undefined) then
			raise Output.TemplateEmpty();
		endif;
	else
		spreadsheet = Template;
	endif;
	result = Fields.Retrieve(Name, Source, Type).Field;
	areas = Collections.DeserializeTable(spreadsheet.Areas);
	tabDoc = spreadsheet.Template;
	for each range in areas do
		for j = range.Up to range.Bottom do
			for i = range.Left to range.Right do
				area = getArea(j, i);
				original = tabDoc.Area(area).Text;
				actual = result.GetAreaText(area);
				if (not equal(original, actual)) then
					p = new Structure("Area, Original, Actual", area, original, actual);
					raise Output.AreaComparisonError(p);
				endif;
			enddo;
		enddo;
	enddo;
	
EndProcedure

Function getArea(R, C)
	
	return "R" + Format(R, "NG=") + "C" + Format(C, "NG=");
	
EndFunction

Function equal(Original, Actual)
	
	if (Original = "{*}") then
		return not IsBlankString(Actual);
	elsif (StrStartsWith(Original, "{")
			and StrEndsWith(Original, "}")) then
		s = TrimAll(Original);
		s = Mid(s, 2, StrLen(s) - 2);
		s = Output.Sformat(s, __);
		asterisk = StrFind(s, "*");
		if (asterisk = 0) then
			return s = Actual;
		elsif (asterisk = 1) then
			return StrEndsWith(Actual, Mid(s, asterisk + 1));
		else
			return StrStartsWith(Actual, Left(s, asterisk - 1));
		endif;
	else
		return Lower(Original) = Lower(Actual);
	endif;
	
EndFunction

Function GetControl(Name, Source = undefined, Type = undefined) export
	
	data = Fields.Retrieve(Name, Source, Type);
	field = data.Field;
	area = data.Area;
	if (data.Area <> undefined) then
		if (field.Type = FormFieldType.SpreadsheetDocumentField) then
			field.SetCurrentArea(area);
			data.Field = field.GetCurrentAreaField();
		else
			table = data.Parent;
			if (table = undefined) then
				locateRow(Source, area);
			else
				locateRow(table, area);
			endif;
		endif;
	endif;
	return data;
	
EndFunction

Function SetValue(Name, Value, Source = undefined, Type = undefined, ChooseValue = false, TestSelection = false) export
	
	data = Fields.Focus(Name, Source, Type);
	field = data.Field;
	fieldType = field.Type;
	if (fieldType = FormFieldType.RadioButtonField) then
		field.SelectOption(Value);
	else
		stringValue = String(Value);
		if (fieldType = FormFieldType.SpreadsheetDocumentField) then
			field.BeginEditCurrentArea();
			putValue(field, stringValue, ChooseValue, TestSelection);
			field.EndEditCurrentArea();
		elsif (fieldType = FormFieldType.InputField) then
			table = editRow(data, Source);
			putValue(field, stringValue, ChooseValue, TestSelection);
			finishEditing(table);
		elsif (fieldType = FormFieldType.FormattedDocumentField) then
			if (Framework.VersionLess("8.3.13")) then
				field.InputHTML(Value);
			else
				field.InputDocumentHTML(Value);
			endif;
		else
			field.InputText(Value);
		endif;
	endif;
	return field;
	
EndFunction

Procedure putValue(Field, Value, ChooseValue, TestSelection)
	
	Field.InputText(Value);
	if (ChooseValue) then
		try
			opened = Field.WaitForDropListGeneration();
		except
			opened = false;
		endtry;
		if (opened) then
			if (Field.DropListIsOpen()) then
				Field.ExecuteChoiceFromChoiceList(0);
				if (TestSelection) then
					if (Lower(Field.GetEditText()) <> Lower(Value)) then
						Field.InputText(Value);
						raise Output.WrongFieldValue();
					endif;
				endif;
			endif;
		endif;
	endif;
	
EndProcedure

Function editRow(FieldData, Source)
	
	tableType = Type("TestedFormTable");
	if (TypeOf(FieldData.Parent) = tableType) then
		table = FieldData.Parent;
	elsif (TypeOf(Source) = tableType) then
		table = Source;
	else
		return undefined;
	endif;
	if (table.CurrentModeIsEdit()) then
		return undefined;
	endif;
	table.ChangeRow();
	return table;
	
EndFunction

Procedure finishEditing(Table)
	
	if (Table <> undefined) then
		Table.EndEditRow();
	endif;
	
EndProcedure

Function StartChoosing(Name, Source = undefined, Type = undefined) export
	
	data = Fields.Focus(Name, Source, Type);
	field = data.Field;
	fieldType = field.Type;
	if (fieldType = FormFieldType.SpreadsheetDocumentField) then
		field.BeginEditCurrentArea();
	else
		editRow(data, Source);
	endif;
	field.StartChoosing();
	return field;
	
EndFunction

Function ClearControl(Name, Source = undefined, Type = undefined) export
	
	data = Fields.GetControl(Name, Source, Type);
	field = data.Field;
	field.Activate();
	table = editRow(data, Source);
	field.Clear();
	finishEditing(table);
	return data;
	
EndFunction

Procedure NextField() export
	
	CurrentSource.GotoNextItem();
	
EndProcedure

Procedure Select(Name, Value, Source = undefined, Type = undefined) export
	
	data = Fields.Focus(Name, Source, Type);
	field = data.Field;
	table = editRow(data, Source);
	if (not field.DropListIsOpen()) then
		field.OpenDropList();
	endif;
	field.ExecuteChoiceFromChoiceList(Value);
	finishEditing(table);
	
EndProcedure

Function ClickField(Name, Source = undefined, Type = undefined) export
	
	if (TypeOf(Source) = Type("TestedWindowCommandInterface")) then
		data = Fields.Retrieve(Name, Source, Type);
		field = data.Field;
	else
		data = Fields.Focus(Name, Forms.FindSource(Source), Type);
		field = data.Field;
	endif;
	type = TypeOf(field);
	if (type = Type("TestedFormField")) then
		fieldType = field.Type;
		if (fieldType = FormFieldType.CheckBoxField) then
			field.SetCheck();
		elsif (fieldType = FormFieldType.LabelField) then
			try
				field.ClickFormattedStringHyperlink(getPosition(data.Area));
			except
				try
					field.Click();
				except
					raise Output.UnableToClick(new Structure("Field", Name));
				endtry;
			endtry;
		else
			field.Click();
		endif;
	elsif (type = Type("TestedFormDecoration")) then
		try
			field.ClickFormattedStringHyperlink(getPosition(data.Area));
		except
			field.Click();
		endtry;
	elsif (type = Type("TestedFormGroup")) then
		try
			field.Expand();
		except
			field.Collapse();
		endtry;
	else
		field.Click();
	endif;
	return field;
	
EndFunction

Function getPosition(Area)
	
	if (Area = undefined) then
		return 0;
	endif;
	try
		position = Number(Area);
		return position - 1;
	except
		return Area;
	endtry;
	
EndFunction