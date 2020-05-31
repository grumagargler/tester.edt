Function Create () export
	
	#if ( Server ) then
		SetPrivilegedMode ( true );
	#endif
	#if ( WebClient or MobileClient ) then
		raise Output.WebClientDoesNotSupport ();
	#else
		exp = new COMObject ( "VBScript.RegExp" );
		exp.MultiLine = true;
		exp.Global = true;
		exp.IgnoreCase = true;
		return exp;
	#endif
	
EndFunction 
