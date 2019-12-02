
Procedure Init ( Object ) export
	
	setCreator ( Object );
	
EndProcedure 

Procedure setCreator ( Object )
	
	Object.Creator = SessionParameters.User;
	
EndProcedure 
