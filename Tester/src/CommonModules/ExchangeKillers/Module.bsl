Procedure Write ( Object ) export
	
	if ( TransactionActive () ) then
		Object.Write ();
	else
		BeginTransaction ();
		ExchangeKillers.Wait ();
		Object.Write ();
		CommitTransaction ();
	endif;

EndProcedure

Procedure Delete ( Object ) export
	
	if ( TransactionActive () ) then
		Object.Delete ();
	else
		BeginTransaction ();
		ExchangeKillers.Wait ();
		Object.Delete ();
		CommitTransaction ();
	endif;

EndProcedure

Procedure Wait () export
	
	lock = new DataLock ();
	scope = lock.Add ( "Constant.Exchange" );
	scope.Mode = DataLockMode.Exclusive;
	lock.Lock ();
	
EndProcedure