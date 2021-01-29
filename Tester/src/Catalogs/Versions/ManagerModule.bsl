Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	Fields.Add ( "Path" );
	StandardProcessing = false;
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Enum.OthersVersionPrefix () + Data.Path;
	
EndProcedure

Procedure Create ( Scenario, Memo = undefined ) export
	
	version = createVersion ( Scenario );
	stampVersion ( Scenario, version, Memo );
	
EndProcedure 

Function createVersion ( Scenario )
	
	obj = CreateItem ();
	source = Scenario.GetObject ();
	FillPropertyValues ( obj, source, , "Owner, Parent, Code" );
	obj.Areas.Load ( source.Areas.Unload () );
	obj.Users.Load ( source.Users.Unload () );
	obj.Creator = SessionParameters.User;
	obj.Scenario = Scenario;
	obj.Folder = DF.Pick ( source.Parent, "Code" );
	obj.Template = new ValueStorage ( source.Template.Get () );
	obj.Write ();
	return obj.Ref;
	
EndFunction 

Procedure stampVersion ( Scenario, Version, Memo )
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.Versions.CreateRecordManager ();
	r.Period = CurrentSessionDate ();
	r.Scenario = Scenario;
	r.Version = Version;
	r.Memo = Memo;
	r.Write ();
	SetPrivilegedMode ( false );
	
EndProcedure 
