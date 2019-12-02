// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	if (Record.SourceRecordKey.IsEmpty()) then
		fillNew();
	endif;
	
EndProcedure

&AtServer
Procedure fillNew()
	
	if (not Parameters.CopyingValue.IsEmpty()) then
		return;
	endif;
	Record.Computer = SessionData.Computer();
	if (Record.User.IsEmpty()) then
		Record.User = SessionParameters.User;
	endif;
	if (Record.Application.IsEmpty()) then
		Record.Application = EnvironmentSrv.GetApplication();
	endif;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	if (not checkFolder()) then
		Cancel = true;
		return;
	endif;
	
EndProcedure

&AtServer
Function checkFolder()
	
	folder = Record.Folder;
	if (IsBlankString(folder)) then
		return true;
	endif;
	folders = getFolders();
	folder1 = Lower(Record.Folder);
	for each folder in folders do
		folder2 = Lower(folder.Folder);
		overlapped = (folder1 = folder2);
		if (overlapped) then
			Output.WrongRepoFolder1(new Structure("Folder1, Folder2", folder1, folder2), "Folder", , "Record");
			return false;
		endif;
		inside = (StrStartsWith(folder1, folder2) or StrStartsWith(folder2, folder1))
			and StrSplit(folder1, "/\").Count() <> StrSplit(folder2, "/\").Count();
		if (inside) then
			Output.WrongRepoFolder2(new Structure("Folder1, Folder2", folder1, folder2), "Folder", , "Record");
			return false;
		endif;
	enddo;
	return true;
	
EndFunction

&AtServer
Function getFolders()
	
	s = "
		|select allowed Repositories.Folder as Folder, Repositories.Application as Application
		|from InformationRegister.Repositories as Repositories
		|where Repositories.Computer = &Computer
		|and not ( Repositories.User = &User
		|	and Repositories.Application = &Application )
		|";
	q = new Query(s);
	q.SetParameter("User", Record.User);
	q.SetParameter("Application", Record.Application);
	q.SetParameter("Computer", Record.Computer);
	return q.Execute().Unload();
	
EndFunction

&AtClient
Procedure AfterWrite(WriteParameters)
	
	restartWatcher();
	
EndProcedure

&AtClient
Procedure restartWatcher()
	
	#if ( not WebClient ) then
	if (myRepositry(ComputerName())) then
		Watcher.Init();
	endif;
	#endif
	
EndProcedure

&AtServer
Function myRepositry(val Computer)
	
	return Computer = String(Record.Computer)
		and SessionParameters.User = Record.User;
	
EndFunction

// *****************************************
// *********** Group Form

&AtClient
Procedure FolderStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = false;
	chooseFolder();
	
EndProcedure

&AtClient
Procedure chooseFolder()
	
	dialog = new FileDialog(FileDialogMode.ChooseDirectory);
	dialog.Show(new NotifyDescription("selectFolder", ThisObject));
	
EndProcedure

&AtClient
Procedure selectFolder(Folder, Params) export
	
	if (Folder = undefined) then
		return;
	endif;
	Record.Folder = Folder[0];
	
EndProcedure

&AtClient
Procedure FolderOnChange(Item)
	
	adjustPath();
	
EndProcedure

&AtClient
Procedure adjustPath()
	
	Record.Folder = FileSystem.RemoveSlash(Record.Folder);
	
EndProcedure

