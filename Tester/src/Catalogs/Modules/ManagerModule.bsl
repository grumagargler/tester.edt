Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	Fields.Add ( "Path" );
	Fields.Add ( "IsVersion" );
	StandardProcessing = false;
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = ? ( Data.IsVersion, Enum.OthersVersionPrefix (), "" ) + Data.Path;
	
EndProcedure
