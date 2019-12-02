Function Get () export
	
	exp = new COMObject ( "VBScript.RegExp" );
	exp.MultiLine = true;
	exp.Global = true;
	exp.IgnoreCase = true;
	return exp;
	
EndFunction 
