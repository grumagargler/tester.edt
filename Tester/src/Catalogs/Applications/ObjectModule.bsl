var IsNew;

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	IsNew = IsNew ();
	
EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	SetPrivilegedMode ( true );
	if ( IsNew ) then
		ExchangePlans.Changes.EnrollApplication ( ThisObject );
	endif;
	SetPrivilegedMode ( false );
	
EndProcedure
