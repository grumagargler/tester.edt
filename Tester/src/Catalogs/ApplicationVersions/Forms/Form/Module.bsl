// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif; 
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure fillNew ()
	
	SetCurrent = true;
	Object.Date = CurrentSessionDate ();
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	version = nextVersion ();
	if ( version <> undefined ) then
		FillPropertyValues ( Object, version );
	endif; 
	setDescription ( Object );

EndProcedure 

&AtServer
Function nextVersion ()
	
	s = "
	|select top 1 allowed Versions.Major, Versions.Minor as Minor,
	|	Versions.Version as Version, Versions.Build + 1 as Build
	|from Catalog.ApplicationVersions as Versions
	|where not Versions.DeletionMark
	|and Versions.Owner = &Owner
	|and Versions.Date <= &Date
	|order by Versions.Date desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Date", Object.Date );
	q.SetParameter ( "Owner", Object.Owner );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );
	
EndFunction 

&AtClientAtServerNoContext
Procedure setDescription ( Object )
	
	Object.Description = Format ( Object.Major, "NG=0;NZ=0" )
	+ "." + Format ( Object.Minor, "NG=0;NZ=0" )
	+ "." + Format ( Object.Version, "NG=0;NZ=0" )
	+ "." + Format ( Object.Build, "NG=0;NZ=0" );
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	if ( SetCurrent ) then
		setByDefault ();
		Appearance.Apply ( ThisObject, "Object.Ref" );
	endif; 
	
EndProcedure

&AtServer
Procedure setByDefault ()
	
	EnvironmentSrv.SetVersion ( Object.Ref, false );
	SetCurrent = false;
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure VersionOnChange ( Item )
	
	setDescription ( Object );
	
EndProcedure
