  
#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then 

var UpdaterFolder;

Procedure Update ( ID ) export
	
	cancel = checkingExistence ();
	if ( cancel ) then
		Output.NotFoundExecuteFile1C ();
		return;
	endif;
	Output.StartUpdateScriptProcedure ();
	Connections.Lock ();
	Connections.LeaveMeAlone ();
	saveUpdater ( ID );
	runUpdater ( ID );  
		
EndProcedure

Function checkingExistence ()
	
	exeFile = BinDir () + "1cv8.exe";  
	file = new File ( exeFile );
	return not file.Exist (); 
	
EndFunction 

Procedure saveUpdater ( ID )
	
	name = updaterName ();
	tempDir = Exchange.GetTempDir ( ID ); 
	UpdaterFolder = tempDir + "\" + Metadata.Name + "_" + name + ID;
	db = UpdaterFolder + GetPathSeparator () + "db.zip";
	data = getUpdater ( name );	
	data.Write ( db );
	zip = new ZipFileReader ( db );
	zip.ExtractAll ( UpdaterFolder );
	zip.Close (); 
	
EndProcedure

Function updaterName ()
	
	return Metadata.DataProcessors.Update.Templates [ 0 ].Name;
	
EndFunction

Function getUpdater ( Name )
	
	archive = DataProcessors.Update.GetTemplate ( Name );
	return archive;
	
EndFunction

Procedure runUpdater ( ID )
	
	p = getParameters ( ID );
	params = Conversion.ToJSON ( p );
	app = """" + BinDir () + "1cv8c.exe"" ENTERPRISE /F """ + UpdaterFolder + "" + """ /N ""admin""" + " /C """ + StrReplace ( params, """", """""" ) + """";
	RunApp ( app );
	
EndProcedure

Function getParameters ( ID )
	
	credentials = Connections.GetCredentials ();
	p = new Structure ();
	p.Insert ( "User", credentials.CloudUser );
	p.Insert ( "Password", credentials.CloudPassword );
	p.Insert ( "Key", ? ( credentials.ServerCode = "", "EXCHANGE", credentials.ServerCode ) );
	p.Insert ( "ID", ID );
	p.Insert ( "Connection", getConnection () );
	return p; 
	
EndFunction 

Function getConnection ()
	
	connectDB = InfoBaseConnectionString ();
	if ( Find ( connectDB, "File=" ) = 1 ) then
		s = " /F " + """" + NStr ( connectDB, "File" ) + """";
	else
		s = " /S " + """" + NStr ( connectDB, "Srvr" ) + "\" + NStr ( connectDB, "Ref" ) + """";
	endif;
	return s;	        

EndFunction

#endif