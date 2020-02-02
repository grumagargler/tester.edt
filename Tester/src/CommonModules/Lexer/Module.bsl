&AtServer
Procedure ProcedureDescriptors ( Start, End ) export
	
	Start = new Map ();
	Start [ "процедура" ] = new Structure ( "Len, Function", 10, false );
	Start [ "procedure" ] = new Structure ( "Len, Function", 10, false );
	Start [ "функция" ] = new Structure ( "Len, Function", 8, true );
	Start [ "function" ] = new Structure ( "Len, Function", 9, true );
	End = new Array ();
	End.Add ( "конецпроцедуры" );
	End.Add ( "endprocedure" );
	End.Add ( "конецфункции" );
	End.Add ( "endfunction" );
	
EndProcedure

&AtServer
Procedure RegionDescriptors ( Start, End ) export
	
	Start = new Map ();
	Start [ "#область" ] = new Structure ( "Len", 9 );
	Start [ "#region" ] = new Structure ( "Len", 8 );
	End = new Array ();
	End.Add ( "#конецобласти" );
	End.Add ( "#endregion" );
	
EndProcedure

&AtServer
Function Declaration ( Descriptors, NormalRow ) export
	
	for each item in Descriptors do
		if ( StrStartsWith ( NormalRow, item.Key ) ) then
			descriptor = item.Value;
			next = Mid ( NormalRow, descriptor.Len, 1 );
			if ( not ValueIsFilled ( next ) ) then
				return descriptor;
			endif;
		endif;
	enddo;
	
EndFunction

&AtServer
Function DeclarationEnds ( Exp, Descriptors, NormalRow ) export
	
	for each item in Descriptors do
		Exp.Pattern = item + "($|\t| |\n)";
		if ( Exp.Test ( NormalRow ) ) then
			return true;
		endif;
	enddo;
	return false;
	
EndFunction

Function IsComment ( NormalRow ) export
	
	return StrStartsWith ( NormalRow, "//" );
	
EndFunction

&AtServer
Function AreaComment ( Exp, Row ) export
	
	Exp.Pattern = "^\s*//\s*(!|#)\s*(.+)"; // #MyArea
	matches = Exp.Execute ( Row );
	if ( matches.Count = 0 ) then
		return undefined;
	else
		return matches.Item ( 0 ).Submatches.Item ( 1 );
	endif; 
	
EndFunction

&AtServer
Function DeclarationName ( Exp, Row ) export
	
	Exp.Pattern = "^\s*(процедура|функция|#область|procedure|function|#region)\s+([a-z,_,A-Z,а-я,А-Я,0-9]+)";
	matches = Exp.Execute ( Row );
	if ( matches.Count = 0 ) then
		return undefined;
	else
		return matches.Item ( 0 ).Submatches.Item ( 1 );
	endif; 
	
EndFunction