Procedure FormGetProcessing ( FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing )
	
	if ( newScenario ( FormType, Parameters ) ) then
		SelectedForm = "New";
		StandardProcessing = false;
	endif;
	
EndProcedure

Function newScenario ( Type, Parameters )
	
	return Type = "ObjectForm"
	and not Parameters.Property ( "Key" )
	and not Parameters.Property ( "CopyingValue" );
	
EndFunction

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	Fields.Add ( "Path" );
	StandardProcessing = false;
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Data.Path;
	
EndProcedure

Procedure Rollback ( Scenario, Version ) export
	
	obj = Scenario.GetObject ();
	source = Version.GetObject ();
	FillPropertyValues ( obj, source, , "Owner, Parent, Code" );
	obj.Areas.Load ( source.Areas.Unload () );
	obj.Template = new ValueStorage ( source.Template.Get () );
	obj.Parent = FindByCode ( source.Folder );
	obj.AdditionalProperties.Insert ( "Restored", true );
	obj.Write ();
	
EndProcedure 
