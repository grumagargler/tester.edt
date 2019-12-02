Function Href ( Path, Embedded ) export
	
	#if ( Server ) then
		lang = CurrentLanguage ().LanguageCode;
	#else
		lang = CurrentLanguage ();
	#endif
	name = "tester";
	user = name + ".help." + lang;
	link = lang + "." + Path;
	params = new Array ();
	if ( Embedded ) then
		params.Add ();
		params.Add ( "Embedded=1" );
	endif; 
	return "https://apps.rdbcode.com/" + user + "/hs/Document?Link=" + link + StrConcat ( params, "&" );
	
EndFunction 