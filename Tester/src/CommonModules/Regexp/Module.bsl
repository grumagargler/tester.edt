
Function Select ( From, How ) export
	
	exp = Libraries.Init ( "Regex" );
	result = exp.Select ( From, How );
	return Conversion.FromJSON ( result );

EndFunction

Function Test ( What, How ) export
	
	exp = Libraries.Init ( "Regex" );
	return exp.Test ( What, How );

EndFunction

Function Replace ( What, How, Replacement ) export
	
	exp = Libraries.Init ( "Regex" );
	return exp.Replace ( What, How, Replacement );

EndFunction