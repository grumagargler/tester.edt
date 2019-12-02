Function CreateFilter ( LeftValue, RightValue = undefined, ComparisonType = undefined, Use = true, ViewMode = undefined, Access = true ) export
	
	filter = new Structure ( "LeftValue, ComparisonType, RightValue, ViewMode, Use, Access" );
	filter.LeftValue = new DataCompositionField ( LeftValue );
	filter.ViewMode = ? ( ViewMode = undefined, DataCompositionSettingsItemViewMode.QuickAccess, ViewMode );
	filter.Use = Use;
	filter.Access = Access;
	if ( RightValue = undefined ) then
		value = undefined;
	else
		if ( TypeOf ( RightValue ) = Type ( "Array" ) ) then
			if ( RightValue.Count () = 1 ) then
				value = RightValue [ 0 ];
			else
				value = new ValueList ();
				value.LoadValues ( RightValue );
			endif;
		else
			value = RightValue;
		endif;
	endif;
	filter.RightValue = value;
	if ( ComparisonType = undefined ) then
		filter.ComparisonType = ? ( TypeOf ( value ) = Type ( "ValueList" ), DataCompositionComparisonType.InList, DataCompositionComparisonType.Equal );
	else
		filter.ComparisonType = ComparisonType;
	endif;
	return filter;
	
EndFunction

Procedure DeleteFilter ( Source, Name ) export
	
	while ( true ) do
		filter = FindFilter ( Source, Name );
		if ( filter = undefined ) then
			break;
		endif; 
		if ( filter.Parent = undefined ) then
			Source.Filter.Items.Delete ( filter );
		else
			filter.Parent.Items.Delete ( filter );
		endif; 
	enddo; 
	
EndProcedure

Function FindFilter ( Source, Name, Deeply = true ) export
	
	composer = ( TypeOf ( Source ) = Type ( "DataCompositionSettingsComposer" ) );
	settings = ? ( composer, Source.Settings, Source );
	filter = filterItem ( Name, settings.Filter.Items, Deeply );
	if ( composer ) then
		if ( filter <> undefined
			and filter.UserSettingID <> "" ) then
			filter = Source.UserSettings.Items.Find ( filter.UserSettingID );
		endif; 
	endif; 
	return filter;
	
EndFunction

Function filterItem ( Name, Items, Deeply )
	
	field = new DataCompositionField ( Name );
	group = Type ( "DataCompositionFilterItemGroup" );
	for each filter in Items do
		if ( TypeOf ( filter ) = group ) then
			if ( Deeply ) then
				result = filterItem ( Name, filter.Items, Deeply );
				if ( result <> undefined ) then
					return result;
				endif; 
			endif; 
		else
			if ( filter.LeftValue = field ) then
				return filter;
			endif; 
		endif; 
	enddo;
	return undefined;
	
EndFunction

Procedure ChangeFilter ( Source, Name, Value, Setup, ComparisonType = undefined ) export
	
	DeleteFilter ( Source, Name );
	if ( Setup ) then
		SetFilter ( Source, Name, Value, ComparisonType );
	endif;
	
EndProcedure

Procedure SetFilter ( Source, Name, Value, ComparisonType = undefined, Access = false ) export
	
	item = FindFilter ( Source, Name );
	if ( item = undefined ) then
		composer = ( TypeOf ( Source ) = Type ( "DataCompositionSettingsComposer" ) );
		if ( composer ) then
			id = Source.Settings.Filter.UserSettingID;
			if ( id = "" ) then
				items = Source.Settings.Filter.Items;
			else
				items = Source.UserSettings.Items.Find ( id ).Items;
			endif; 
		else
			items = Source.Filter.Items;
		endif; 
		item = items.Add ( Type ( "DataCompositionFilterItem" ) );
	endif; 
	item.LeftValue = new DataCompositionField ( Name );
	item.ComparisonType = ? ( ComparisonType = undefined, DataCompositionComparisonType.Equal, ComparisonType );
	item.RightValue = Value;
	item.Use = true;
	item.ViewMode = ? ( Access, DataCompositionSettingsItemViewMode.Auto, DataCompositionSettingsItemViewMode.Inaccessible );
	
EndProcedure

Procedure SetParameter ( Source, Name, Value, Setup = true ) export
	
	parameter = GetParameter ( Source, Name );
	if ( Setup ) then
		parameter.Value = Value;
		parameter.Use = true;
	else
		parameter.Use = false;
	endif;
	
EndProcedure

Function GetParameter ( Source, Name ) export
	
	parameter = FindParameter ( Source, Name );
	if ( parameter = undefined ) then
		type = TypeOf ( Source );
		if ( type = Type ( "DataCompositionSettingsComposer" ) ) then
			parameter = Source.Settings.DataParameters.Items.Add ();
		elsif ( type = Type ( "DataCompositionSettings" ) ) then
			parameter = Source.DataParameters.Items.Add ();
		endif;
		if ( parameter <> undefined ) then
			parameter.Parameter = new DataCompositionParameter ( Name );
		endif;
	endif; 
	return parameter;
	
EndFunction

Function FindParameter ( Source, Name ) export
	
	composer = ( TypeOf ( Source ) = Type ( "DataCompositionSettingsComposer" ) );
	settings = ? ( composer, Source.Settings, Source );
	target = new DataCompositionParameter ( Name );
	try
		parameter = settings.DataParameters.FindParameterValue ( target );
	except
	endtry;
	if ( parameter = undefined ) then
		try
			parameter = settings.Parameters.FindParameterValue ( target );
		except
		endtry;
	endif; 
	if ( composer
		and parameter <> undefined
		and parameter.UserSettingID <> "" ) then
		return Source.UserSettings.Items.Find ( parameter.UserSettingID );
	endif; 
	return parameter;
	
EndFunction

Procedure SetOrder ( List, Expression ) export
	
	p = getOrderParams ( Expression );
	deleteOrder ( List.Order.Items, p.Field );
	item = List.Order.Items.Add ( Type ( "DataCompositionOrderItem" ) );
	item.Use = true;
	item.Field = p.Field;
	item.OrderType = p.Direction;
	
EndProcedure

Function getOrderParams ( Expression )
	
	exp = Conversion.StringToArray ( Expression, " " );
	p = new Structure ();
	p.Insert ( "Field", new DataCompositionField ( exp [ 0 ] ) );
	p.Insert ( "Direction", ? ( exp.Count () = 1, DataCompositionSortDirection.Asc, DataCompositionSortDirection [ exp [ 1 ] ] ) );
	return p;
	
EndFunction 

Procedure deleteOrder ( Items, Field )
	
	i = Items.Count ();
	while ( i > 0 ) do
		i = i - 1;
		item = Items [ i ];
		if ( item.Field = Field ) then
			Items.Delete ( item );
		endif;
	enddo; 
	
EndProcedure

Procedure RemoveOrder ( List, Name ) export
	
	deleteOrder ( List.Order.Items, new DataCompositionField ( Name ) );
	
EndProcedure 
 
Function GetParameterStructure ( Parameter, Value = undefined, Use = true, ViewMode = undefined ) export
	
	return new Structure ( "Parameter, Value, ViewMode, Use", new DataCompositionParameter ( Parameter ), Value, ? ( ViewMode = undefined, DataCompositionSettingsItemViewMode.QuickAccess, ViewMode ), Use );
	
EndFunction

&AtServer
Function GetGroup ( Source, Name, SearchInFields = false ) export
	
	composer = ( TypeOf ( Source ) = Type ( "DataCompositionSettingsComposer" ) );
	settings = ? ( composer, Source.Settings, Source );
	group = groupByName ( settings.Structure, Name, SearchInFields );
	if ( composer ) and ( group <> undefined ) then
		group = Source.UserSettings.Items.Find ( group.UserSettingID );
	endif; 
	return group;
	
EndFunction
 
&AtServer
Function groupByName ( Container, Name, SearchInFields )
	
	tableType = Type ( "DataCompositionTable" );
	for each item in Container do
		if ( TypeOf ( item ) = tableType ) then
			items = new Array ();
			items.Add ( item.Rows );
			items.Add ( item.Columns );
			for each element in items do
				result = groupByName ( element, Name, SearchInFields );
				if ( result <> undefined ) then
					return result;
				endif; 
			enddo; 
		else
			if ( item.Name = Name ) then
				return item;
			endif;
			if ( SearchInFields ) then
				field = new DataCompositionField ( Name );
				for each group in item.GroupFields.Items do
					if ( group.Field = field ) then
						return item;
					endif; 
				enddo; 
			endif; 
			if ( item.Structure.Count () > 0 ) then
				result = groupByName ( item.Structure, Name, SearchInFields );
				if ( result <> undefined ) then
					return result;
				endif; 
			endif; 
		endif; 
	enddo; 
	return undefined;
	
EndFunction

&AtServer
Function FindField ( Group, Name ) export
	
	field = new DataCompositionField ( Name );
	for each item in Group.GroupFields.Items do
		if ( item.Field = field ) then
			return item;
		endif; 
	enddo; 
	return undefined;
	
EndFunction 
