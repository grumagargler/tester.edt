
Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkVersion () ) then
		Cancel = true;
	endif;
	if ( not checkLocalhost () ) then
		Cancel = true;
	endif;
	
EndProcedure

Function checkVersion ()
	
	if ( not Proxy
		or Version = "" ) then
		return true;
	endif;
	si = new SystemInfo ();
	platform = si.AppVersion;
	if ( StrLen ( Version ) = StrLen ( platform ) ) then
		return true;
	endif;
	Output.IncorrectVersion ( new Structure ( "Framework", framework ), "Version" );
	return false;
	
EndFunction

Function checkLocalhost ()
	
	if ( not Proxy ) then
		return true;
	endif;
	exp = Regexp.Create ();
	exp.Pattern = "\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b";
	if ( exp.Test ( Localhost ) ) then
		return true;
	endif;
	Output.IncorrectIP ( , "IP", , "" );
	return false;

EndFunction