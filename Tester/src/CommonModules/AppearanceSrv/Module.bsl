
Procedure Read ( Form ) export
	
	appearanceItems = new Array ();
	serializedItems = new Array ();
	index = 0;
	for each item in Form.ConditionalAppearance.Items do
		if ( not item.Use ) then
			continue;
		endif; 
		serializedFormats = getSerializedFormats ( item.Appearance );
		if ( serializedFormats = undefined ) then
			continue;
		endif; 
		appearanceItem = new Structure ( "Formats, Filters, Fields, FilterFields", serializedFormats, new Array (), new Array (), new Array () );
		appearanceItems.Add ( appearanceItem );
		filterSupported = serializeFilters ( Form, item.Filter.Items, appearanceItem.Filters, appearanceItem.FilterFields );
		if ( filterSupported ) then
			serializeFields ( Form.Items, item.Fields.Items, appearanceItem.Fields );
			serializedItems.Add ( item );
			index = index + 1;
		else
			appearanceItems.Delete ( index );
		endif; 
	enddo; 
	removeSerializedItems ( Form, serializedItems );
	Form.FormAppearance = new FixedArray ( appearanceItems );
	
EndProcedure 

Function getSerializedFormats ( CompositionAppearance )
	
	readonlyItem = CompositionAppearance.Items.Find ( new DataCompositionParameter ( "ReadOnly" ) );
	visibleItem = CompositionAppearance.Items.Find ( new DataCompositionParameter ( "Visible" ) );
	enabledItem = CompositionAppearance.Items.Find ( new DataCompositionParameter ( "Enabled" ) );
	markIncompleteItem = CompositionAppearance.Items.Find ( new DataCompositionParameter ( "MarkIncomplete" ) );
	textItem = CompositionAppearance.Items.Find ( new DataCompositionParameter ( "Text" ) );
	colorItem = CompositionAppearance.Items.Find ( new DataCompositionParameter ( "TextColor" ) );
	existAppearance = readonlyItem.Use or visibleItem.Use or enabledItem.Use or markIncompleteItem.Use or textItem.Use;
	if ( not existAppearance ) then
		return undefined;
	endif; 
	result = new Structure ();
	result.Insert ( "ReadOnly", ? ( readonlyItem.Use, readonlyItem.Value, undefined ) );
	result.Insert ( "Visible", ? ( visibleItem.Use, visibleItem.Value, undefined ) );
	result.Insert ( "Enabled", ? ( enabledItem.Use, enabledItem.Value, undefined ) );
	result.Insert ( "MarkIncomplete", ? ( markIncompleteItem.Use, markIncompleteItem.Value, undefined ) );
	result.Insert ( "Text", ? ( textItem.Use, StrReplace ( textItem.Value, Char ( 182 ), Chars.LF ), undefined ) );
	result.Insert ( "TextColor", ? ( colorItem.Use, colorItem.Value, undefined ) );
	return result;
	
EndFunction 

Function serializeFilters ( Form, CompositionFilters, SerializedFilters, FilterFields )
	
	for each filterItem in CompositionFilters do
		if ( not filterItem.Use ) then
			continue;
		endif; 
		if ( TypeOf ( filterItem ) = Type ( "DataCompositionFilterItem" ) ) then
			serializedFilterItem = getFilterItem ( Form, filterItem, FilterFields );
		else
			serializedFilterItem = getFilterGroup ( Form, filterItem, FilterFields );
		endif; 
		if ( serializedFilterItem = undefined ) then
			return false;
		else
			SerializedFilters.Add ( serializedFilterItem );
		endif; 
	enddo; 
	return true;
	
EndFunction

Function getFilterItem ( Form, Filter, FilterFields )
	
	filterItem = new Structure ();
	filterItem.Insert ( "IsGroup", false );
	filterItem.Insert ( "ComparisonType", Filter.ComparisonType );
	error = not addFilterItemValue ( Form, Filter, FilterFields, filterItem, "LeftValue" );
	error = error or not addFilterItemValue ( Form, Filter, FilterFields, filterItem, "RightValue" );
	if ( error ) then
		return undefined;
	endif; 
	return filterItem;
	
EndFunction 

Function addFilterItemValue ( Form, Filter, FilterFields, FilterItem, FilterSide )
	
	value = Filter [ FilterSide ];
	if ( TypeOf ( value ) = Type ( "DataCompositionField" ) ) then
		valuePath = String ( value );
		valueParts = Conversion.StringToArray ( valuePath, "." );
		if ( not supportValueType ( Form, valueParts ) ) then
			return false;
		endif; 
		FilterItem.Insert ( FilterSide, valueParts );
		FilterFields.Add ( valuePath );
	else
		FilterItem.Insert ( FilterSide, value );
	endif; 
	return true;
	
EndFunction

Function supportValueType ( Form, ValueParts )
	
	if ( ValueParts.Count () <> 3 ) then
		return true;
	endif;
	object = Form;
	for each part in ValueParts do
		object = object [ part ];
		typeOfObject = TypeOf ( object );
		if ( typeOfObject = Type ( "FormDataCollection" )
			or typeOfObject = Type ( "FormDataTree" )
			or typeOfObject = Type ( "DynamicList" )
			or typeOfObject = Type ( "ValueList" ) ) then
			return false;
		endif; 
	enddo; 
	return true;
		
EndFunction 

Function getFilterGroup ( Form, Filter, FilterFields )
	
	filterItem = new Structure ();
	filterItem.Insert ( "IsGroup", true );
	filterItem.Insert ( "GroupType", Filter.GroupType );
	filterItem.Insert ( "Filters", new Array () );
	filterSupported = serializeFilters ( Form, Filter.Items, filterItem.Filters, FilterFields );
	if ( filterSupported ) then
		return filterItem;
	endif; 
	return undefined;
	
EndFunction 

Procedure serializeFields ( FormItems, CompositionFields, SerializedFields )
	
	for each fieldItem in CompositionFields do
		if ( not fieldItem.Use or FormItems.Find ( fieldItem.Field ) = undefined ) then
			continue;
		endif; 
		SerializedFields.Add ( String ( fieldItem.Field ) );
	enddo; 
	
EndProcedure 

Procedure removeSerializedItems ( Form, Items )
	
	collection = Form.ConditionalAppearance.Items;
	for each item in Items do
		collection.Delete ( item );
	enddo; 
	
EndProcedure 
