
#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure Run ( ID ) export
	
	DataProcessors.Update.Create ().Update ( ID );
	
EndProcedure 

#endif