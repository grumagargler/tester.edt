	
Procedure Unload ( Params ) export
	
	dp = getProcessor ();
	dp.Unload ( Params );
	
EndProcedure

Procedure Load ( Params ) export
	
	dp = getProcessor ();
	dp.Load ( Params );
	
EndProcedure

Function getProcessor ()
	
	return DataProcessors.ExchangeData.Create ();
	
EndFunction