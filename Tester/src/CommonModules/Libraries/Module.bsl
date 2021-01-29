
Function Init ( Name ) export
	
	id = "AddIn.Extender." + Name;
	try
		lib = new ( id );
	except
		load ();
		lib = new ( id );
	endtry;
	return lib;
	
EndFunction

Procedure load ()
	
	AttachAddIn ( "CommonTemplate.ExternalLibrary", "Extender", AddInType.Native );	
	
EndProcedure 
