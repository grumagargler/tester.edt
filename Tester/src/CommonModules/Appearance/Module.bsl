
Procedure Apply ( Form, Value = undefined, CanBeDisallowed = false ) export
	
	if ( appearanceIsReady ( Form ) ) then
		applyAppearance ( Form, Value, false, CanBeDisallowed );
	endif; 
	
EndProcedure 

Function appearanceIsReady ( Form )
	
	return Form.FormAppearance <> undefined;
	
EndFunction 

Procedure applyAppearance ( Form, Value, IsItemUpdate, CanBeDisallowed )
	
	items = Form.Items;
	appearanceItems = Form.FormAppearance;
	dependencyFound = false;
	for each appearanceItem in appearanceItems do
		if ( not appearanceDependsOn ( appearanceItem, Value, IsItemUpdate ) ) then
			continue;
		endif; 
		dependencyFound = true;
		result = conditionMatched ( Form, appearanceItem.Filters, DataCompositionFilterItemsGroupType.AndGroup );
		formatFields ( items, appearanceItem, result );
	enddo; 
	if ( Value = undefined or CanBeDisallowed or dependencyFound ) then
	else
		raise "Conditional appearance cannot find dependency by name: " + Value;
	endif; 
	
EndProcedure 

Function appearanceDependsOn ( AppearanceItem, Value, IsItemUpdate )
	
	if ( Value = undefined ) then
		return true;
	endif;
	if ( IsItemUpdate ) then
		return AppearanceItem.Fields.Find ( Value ) <> undefined;
	else
		return AppearanceItem.FilterFields.Find ( Value ) <> undefined;
	endif; 
	
EndFunction 

Procedure Update ( Form, Item, CanBeDisallowed = false ) export
	
	if ( appearanceIsReady ( Form ) ) then
		applyAppearance ( Form, Item, true, CanBeDisallowed );
	endif;
	
EndProcedure 

Function conditionMatched ( Form, Filters, FiltersGroupType )
	
	for each item in Filters do
		if ( item.IsGroup ) then
			result = conditionMatched ( Form, item.Filters, item.GroupType );
		else
			result = compareValues ( Form, item );
		endif; 
		if ( result ) then
			if ( FiltersGroupType = DataCompositionFilterItemsGroupType.OrGroup
				or FiltersGroupType = DataCompositionFilterItemsGroupType.NotGroup ) then
				break;
			endif;
		else
			if ( FiltersGroupType = DataCompositionFilterItemsGroupType.AndGroup ) then
				break;
			endif;
		endif; 
	enddo; 
	return result;
	
EndFunction 

Function compareValues ( Form, FilterItem )
	
	leftValue = getActualtValue ( Form, FilterItem.LeftValue );
	rightValue = getActualtValue ( Form, FilterItem.RightValue );
	return comparisonResult ( leftValue, rightValue, FilterItem.ComparisonType );
	
EndFunction 

Function getActualtValue ( Form, Value )
	
	if ( TypeOf ( Value ) = Type ( "Array" ) ) then
		currentObject = Form;
		result = undefined;
		for each valuePart in Value do
			result = currentObject [ valuePart ];
			currentObject = result;
		enddo; 
		return result;
	else
		return Value;
	endif; 
	
EndFunction 

Function comparisonResult ( LeftValue, RightValue, ComparisonType )
	
	if ( ComparisonType = DataCompositionComparisonType.Equal ) then
		return LeftValue = RightValue;
	elsif ( ComparisonType = DataCompositionComparisonType.NotEqual ) then
		return LeftValue <> RightValue;
	elsif ( ComparisonType = DataCompositionComparisonType.Greater ) then
		return LeftValue > RightValue;
	elsif ( ComparisonType = DataCompositionComparisonType.GreaterOrEqual ) then
		return LeftValue >= RightValue;
	elsif ( ComparisonType = DataCompositionComparisonType.Less ) then
		return LeftValue < RightValue;
	elsif ( ComparisonType = DataCompositionComparisonType.LessOrEqual ) then
		return LeftValue <= RightValue;
	elsif ( ComparisonType = DataCompositionComparisonType.Filled ) then
		return ValueIsFilled ( LeftValue );
	elsif ( ComparisonType = DataCompositionComparisonType.NotFilled ) then
		return not ValueIsFilled ( LeftValue );
	elsif ( ComparisonType = DataCompositionComparisonType.InList ) then
		return RightValue.FindByValue ( LeftValue ) <> undefined;
	elsif ( ComparisonType = DataCompositionComparisonType.NotInList ) then
		return RightValue.FindByValue ( LeftValue ) = undefined;
	elsif ( ComparisonType = DataCompositionComparisonType.Contains ) then
		return Find ( String ( LeftValue ), String ( RightValue ) ) > 0;
	else
		return false;
	endif; 
	
EndFunction 

Procedure formatFields ( Items, AppearanceItem, Result )
	
	formats = AppearanceItem.Formats;
	for each field in AppearanceItem.Fields do
		if ( formats.ReadOnly <> undefined ) then
			Items [ field ].ReadOnly = ? ( Result, formats.ReadOnly, not formats.ReadOnly );
		endif; 
		if ( formats.Visible <> undefined ) then
			Items [ field ].Visible = ? ( Result, formats.Visible, not formats.Visible );
		endif; 
		if ( formats.Enabled <> undefined ) then
			Items [ field ].Enabled = ? ( Result, formats.Enabled, not formats.Enabled );
		endif; 
		if ( Result and formats.TextColor <> undefined ) then
			Items [ field ].TextColor = formats.TextColor;
		endif; 
		if ( formats.MarkIncomplete <> undefined ) then
			formField = Items [ field ];
			if ( TypeOf ( formField ) = Type ( "FormButton" ) ) then
				formField.Check = ? ( Result, formats.MarkIncomplete, not formats.MarkIncomplete );
			else
				formField.MarkIncomplete = ? ( Result, formats.MarkIncomplete, not formats.MarkIncomplete );
			endif; 
		endif; 
		if ( Result and formats.Text <> undefined ) then
			formField = Items [ field ];
			if ( TypeOf ( formField ) = Type ( "FormDecoration" ) ) then
				formField.Title = formats.Text;
			else
				formField.InputHint = formats.Text;
			endif; 
		endif; 
	enddo; 
	
EndProcedure 
