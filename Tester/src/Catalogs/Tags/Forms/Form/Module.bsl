// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	OldName = Object.Description;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( OldName <> "" and OldName <> Object.Description ) then
		updateKeys ();
	endif; 
	
EndProcedure

&AtServer
Procedure updateKeys ()
	
	lock ();
	list = getKeys ();
	for each ref in list do
		obj = ref.GetObject ();
		obj.SetDescription ();
		obj.Write ();
	enddo; 
	
EndProcedure 

&AtServer
Procedure lock ()
	
	lock = new DataLock ();
	item = lock.Add ( "Catalog.TagKeys" );
	item.Mode = DataLockMode.Exclusive;
	lock.Lock ();
	
EndProcedure 

&AtServer
Function getKeys ()
	
	s = "
	|select Tags.Ref as Ref
	|from Catalog.TagKeys.Tags as Tags
	|where Tags.Tag = &Tag
	|";
	q = new Query ( s );
	q.SetParameter ( "Tag", Object.Ref );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction 
