Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkFolder ( CheckedAttributes );
	
EndProcedure

Procedure checkFolder ( CheckedAttributes )
	
	if ( Mapping ) then
		CheckedAttributes.Add ( "Folder" );
	endif;
	
EndProcedure