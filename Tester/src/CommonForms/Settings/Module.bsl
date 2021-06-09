
// *****************************************
// *********** Form events

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageApplicationSettingsSaved () );
	
EndProcedure

// *****************************************
// *********** Form

&AtClient
Procedure IDOnChange ( Item )

	adjustID ();

EndProcedure

// Server is used to make WebClient possible to use
&AtServer
Procedure adjustID ()
	
	id = Upper ( TrimAll ( ConstantsSet.ID ) );
	matches = Regexp.Select ( id, "[\d,[A-Z]+" );
	if ( matches.Count () = 0 ) then
		ConstantsSet.ID = "A000";
	else
		ConstantsSet.ID = matches [ 0 ].Value;
	endif;
	
EndProcedure