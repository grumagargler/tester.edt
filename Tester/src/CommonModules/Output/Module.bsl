
Function Sformat ( Str, Params ) export
	
	if ( Params = undefined
		or StrFind ( Str, "%" ) = 0 ) then
		return Str;
	endif; 
	result = Str;
	p = new Array ();
	for each parameter in Params do
		p.Add ( parameter.Key );
	enddo;
	indexOfMax = 0;
	while ( true ) do
		i = 0;
		max = 0;
		for each param in p do
			a = StrLen ( param );
			if ( a > max ) then
				max = a;
				indexOfMax = i;
			endif; 
			i = i + 1;
		enddo;
		k = p [ indexOfMax ];
		p.Delete ( indexOfMax );
		result = StrReplace ( result, "%" + k, Params [ k ] );
		if ( p.UBound () = -1 ) then
			break;
		endif; 
	enddo; 
	return result;
	
EndFunction

Procedure PutMessage ( Text, Params, Field, DataKey, DataPath ) export
	
	msg = new UserMessage ();
	s = Output.Sformat ( Text, Params );
	interactive = ( Params = undefined  ) or not Params.Property ( "_Interactive" ) or Params._Interactive;
	if ( interactive ) then
		msg.DataPath = DataPath;
		msg.Field = Field;
		msg.DataKey = DataKey;
	else
		prefix = new Array ();
		if ( ValueIsFilled ( DataKey ) ) then
			prefix.Add ( String ( DataKey ) );
			table = getTable ( Field );
			if ( table <> undefined ) then
				name = DataKey.Metadata ().TabularSections [ table.Name ].Presentation ();
				prefix.Add ( Output.TableAndRow ( new Structure ( "Table, Row", name, table.Row ) ) );
			endif; 
		endif; 
		if ( prefix.Count () > 0 ) then
			s = StrConcat ( prefix, ", " ) + ": " + s;
		endif; 
	endif; 
	msg.Text = s;
	msg.Message ();
	
EndProcedure

&AtClient
Procedure openMessageBox ( Text, Params, ProcName, Module, CallbackParams, Timeout, Title )
	
	if ( Module = undefined ) then
		handler = undefined;
	else
		handler = new NotifyDescription ( ProcName, Module, CallbackParams );
	endif; 
	if ( handler = undefined ) then // Bug workaround 8.3.3.658 for WebClient: it doesn't understand "Undefined" in first paramer
		ShowMessageBox ( , Output.Sformat ( Text, Params ), Timeout, ? ( Title = "", MetadataPresentation (), Title ) );
	else
		ShowMessageBox ( handler, Output.Sformat ( Text, Params ), Timeout, ? ( Title = "", MetadataPresentation (), Title ) );
	endif; 
	
EndProcedure

&AtClient
Procedure openQueryBox ( Text, Params, ProcName, Module, CallbackParams, Buttons, Timeout, DefaultButton, Title )
	
	ShowQueryBox ( new NotifyDescription ( ProcName, Module, CallbackParams ), Output.Sformat ( Text, Params ), Buttons, Timeout, DefaultButton, ? ( Title = "", MetadataPresentation (), Title ) );
	
EndProcedure

&AtClient
Procedure putUserNotification ( Text, Params, NavigationLink, Explanation, Picture )
	
	ShowUserNotification ( Output.SFormat ( Text, Params ), NavigationLink, Output.SFormat ( Explanation, Params ), Picture );
	
EndProcedure

Function Row ( Table, LineNumber, Field ) export
	
	return Table + "[" + Format ( LineNumber - 1, "NG=;NZ=" ) + "]." + Field;
	
EndFunction 

Function TableAndRow ( Params ) export

	text = NStr ( "en='table %Table [%Row]';ru='таблица %Table [%Row]'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtClient
Function MetadataPresentation () export

	text = NStr ( "en='Tester';ru='Тестер'" );
	return text;

EndFunction

Function getTable ( Field )
	
	i = StrFind ( Field, "[" );
	j = StrFind ( Field, "]", , i );
	if ( i = 0 or j = 0 ) then
		return undefined;
	endif; 
	name = TrimAll ( Left ( Field, i - 1 ) );
	row = 1 + Number ( Mid ( Field, i + 1, j - i - 1 ) );
	return new Structure ( "Name, Row", name, row );
	
EndFunction 

&AtServer
Function RuntimeMessage ( Params = undefined ) export

	text = NStr ( "en='%Message {%Stack}';ru='%Message {%Stack}'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtServer
Function RuntimeMessagePrefix ( Params = undefined ) export

	text = "%Line: ";
	return Output.Sformat ( text, Params );

EndFunction

&AtServer
Function RuntimeMessageCutPrefix () export

	text = "...";
	return text;

EndFunction

&AtClient
Function CheckError ( Params ) export

	text = NStr ( "en='%Form: %Title. Field ""%Field"" <> ""%Value"". The actual value is ""%Result""';ru='%Form: %Title. Поле ""%Field"" <> ""%Value"". Текущее значение ""%Result""'" );
	return Output.Sformat ( text, Params );

EndFunction

Function ScenarioError () export

	text = NStr ( "en='Scenario error';ru='Ошибка сценария'" );
	return text;

EndFunction

Function CallError ( Params ) export

	text = NStr ( "en='Scenario ""%Scenario"" not found';ru='Сценарий ""%Scenario"" не найден'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtClient
Procedure TestComlete ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = Output.TestComleteMessage ();
	PutMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Function TestComleteMessage () export
	
	text = NStr ( "en='Test complete!';ru='Тест завершен!'" );
	return text;
	
EndFunction

Function CompilationError () export

	text = NStr ( "en='Compilation error';ru='Ошибка компиляции'" );
	return text;

EndFunction

&AtClient
Function CheckAppearanceIncorrect ( Params ) export

	text = NStr ( "en='CheckAppearance error: Status ""%Value"" is unknown';ru='CheckAppearance ошибка: Статус ""%Value"" не определен'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtClient
Function CheckAppearanceError ( Params ) export

	text = NStr ( "en='Field ""%Field"" state ""%Value"" should be ""%Flag"". Actual state is ""%State""';ru='У поля ""%Field"" состояние ""%Value"" должно быть ""%Flag"", а реальное состояние ""%State""'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtClient
Function FieldNotFound ( Params ) export

	text = NStr ( "en='Field ""%Field"" is not found';ru='Поле ""%Field"" не найдено'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtClient
Function ManyPlaces ( Params ) export

	text = NStr ( "en='Field ""%Field"" found many times: %Places';ru='Поле ""%Field"" найдено в нескольких местах: %Places'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtClient
Procedure ApplicationUndefined ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ApplicationUndefined" ) export
	
	text = ApplicationUndefinedMessage ();
	title = NStr ( "en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtClient
Function ApplicationUndefinedMessage () export
	
	text = NStr ( "en = 'Application is not defined.
                  |Set Application in Menu / Current Application'; ru = 'Приложение не определено.
                  |Установите приложение в Меню / Текущее приложение'" );
	return text;
	
EndFunction

&AtClient
Function StopMessage () export

	text = NStr ( "en='Scenario stopped';ru='Сценарий остановлен'" );
	return text;

EndFunction

&AtClient
Function NewScenario () export

	text = NStr ( "en='New Scenario';ru='Новый сценарий'" );
	return text;

EndFunction

&AtClient
Function TemplateEmpty () export

	text = NStr ( "en='Template is empty';ru='Шаблон пустой'" );
	return text;

EndFunction

&AtClient
Function AreaComparisonError ( Params ) export

	text = NStr ( "en='Cell [%Area] correct value [%Original] is not equal actual value [%Actual]';ru='Ячейка [%Area] правильное значение [%Original] не соответствует текущему значению [%Actual]'" );
	return Output.Sformat ( text, Params );

EndFunction

Function TemplateCaption () export

	text = NStr ( "en='Template';ru='Шаблон'" );
	return text;

EndFunction

&AtClient
Procedure MainScenarioUndefined ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "MainScenarioUndefined" ) export
	
	text = NStr ( "en='Main Scenario is not yet defined';ru='Основной сценарий еще не определен'" );
	title = NStr ( "en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtServer
Procedure UserNameAlreadyExists ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Duplicate user name detected';ru='Такое имя пользователя уже существует'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure SelectAccessRights ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Check the boxes to set access rights';ru='Отметьте флажками права доступа'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure ConfirmAccessRights ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Confirm or revert changes in access rights';ru='Принять или отменить изменения в правах доступа'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure SelectUsersGroup ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Assign user to the group or assign individual rights';ru='Назначить пользователю группу или индивидуальные права'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Procedure RightsConfirmation ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "BPNotFound" ) export
	
	text = NStr ( "en='Selected right has dependencies on other system rights."
"They should be added or removed as well."
"Please review changes, then Accept or Cancel them';ru='Выбранное право имеет зависимости от других прав системы."
"Они должны быть добавлены или удалены соответственно."
"Пожалуйста, просмотрите изменения и примите или отмените их'" );
	title = NStr ( "en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtClient
Procedure ClearLogConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ClearLogConfirmation" ) export
	
	text = NStr ( "en='Do you want to remove all records?';ru='Удалить все записи?'" );
	title = NStr ( "en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
EndProcedure

&AtServer
Procedure AdministratorNotFound ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='No users with administrative rights left in the system. You need to have at least one user with administrative rights in the database for service efficiency';ru='В системе не осталось пользователей с административными правами. Для работы сервиса требуется как минимум один администратор приложения'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Procedure AccessDenied ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "AccessDenied" ) export
	
	text = NStr ( "en='Access denied';ru='Доступ запрещен'" );
	title = NStr ( "en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtServer
Function ApplicationNotFound ( Params ) export

	text = NStr ( "en='""%Name"" application is not found';ru='""%Name"" приложение не найдено'" );
	return Sformat ( text, Params );

EndFunction

Function ScenarioNotFound ( Params ) export

	text = NStr ( "en='""%Name"" scenario is not found';ru='""%Name"" сценарий не найден'" );
	return Sformat ( text, Params );

EndFunction

&AtClient
Procedure DownloadCompleted ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "DownloadCompleted" ) export
	
	text = NStr ( "en='Download completed!';ru='Загрузка завершена!'" );
	title = NStr ( "en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtServer
Function ParametersCountError ( Params ) export

	text = NStr ( "en='%Name (): Count of parameters cannot be more than %Limit';ru='%Name (): Количество параметров не может быть больше %Limit'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Procedure ScenarioAlreadyExists ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = '""%Name"" scenario is already exists'; ru = '""%Name"" сценарий уже существует'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

Procedure LockError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Scenario ""%Scenario"" has already been locked by %User';ru='Сценарий ""%Scenario"" уже захватил %User'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure ScenarioNotLocked ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Scenario ""%Scenario"" has not been locked'; ru = 'Сценарий ""%Scenario"" не захвачен для редактирования'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Procedure UnlockConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "UnlockConfirmation" ) export
	
	text = NStr ( "en = 'Selected scenarios will be replaced on the previous versions!
                  |Do you want to continue?'; ru = 'Выбранные сценарии будут заменены на предыдущие версии!
                  |Продолжить операцию?'" );
	title = NStr ( "en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
EndProcedure

&AtClient
Procedure EnrollmentError ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "EnrollmentError" ) export
	
	text = NStr ( "ru='Центральный узел не может быть использован';en='The main node cannot be used'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtClient
Procedure EnrollMobile ( Module, CallbackParams = undefined, Params = undefined, ProcName = "EnrollMobile" ) export
	
	text = NStr ( "en = 'For this User, all scenarios will be marked as changed!
                   |Would you like to continue?'; ru = 'Для данного пользователя все сценарии будут помечены как измененные!
                   |Продолжить?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
EndProcedure

&AtClient
Procedure EnrollmentCompleted ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "EnrollmentCompleted" ) export
	
	text = NStr ( "ru='Регистрация завершена!';en='Enrollment is completed!'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtServer
Procedure ColumnIsEmpty ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "ru='Не заполнена колонка ""%Column"" в строке %LineNumber списка ""%Table""';en='Row ""%Column"" in line %LineNumber of list ""%Table"" is empty'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure FieldIsEmpty ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "ru='Поле ""%Field"" не заполнено';en='Field ""%Field"" is empty'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Procedure ScenariosProcessed ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ScenariosProcessed" ) export
	
	text = NStr ( "en = 'Operation completed!
                   |Scenarios Processed: %Counter'; ru = 'Операция завершена!
                   |Обработано сценариев: %Counter'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtClient
Procedure ScenariosProcessedNotification ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export
	
	text = NStr ( "en='Unloading scenarios';ru='Выгрузка сценариев'" );
	explanation = NStr ( "en = 'Operation completed!
                   |Scenarios Processed: %Counter'; ru = 'Операция завершена!
                   |Обработано сценариев: %Counter'" );
	putUserNotification ( text, Params, NavigationLink, explanation, Picture );
	
EndProcedure

&AtServer
Function CommonApplicationName () export

	text = NStr ( "en='<Common>';ru='<Общее>'" );
	return text;

EndFunction

&AtServer
Function CommonApplicationCode () export

	text = NStr ( "en='COMM';ru='ОБЩЕ'" );
	return text;

EndFunction

&AtServer
Procedure RepositoryNotSelected ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Select at least one repository for processing'; ru = 'Выберите хотя бы один репозиторий для обработки'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure ScenarioIDError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Scenario ID should not contain special characters'; ru = 'ID сценария не должен содержать специальные символы'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Function UserAdmin () export

	text = NStr ( "en='Administrator';ru='Администратор'" );
	return text;

EndFunction

&AtClient
Procedure SetupMainScenario ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SetupMainScenario" ) export
	
	text = NStr ( "en = 'Main Scenario is not yet defined.
                  |Would you like to install current scenario as main?'; ru = 'Основной сценарий еще не определен.
                  |Установить запускаемый сценарий как основной?'" );
	title = NStr ( "en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
EndProcedure

&AtClient
Procedure UndefinedMainScenario ( Module, CallbackParams = undefined, Params = undefined, ProcName = "UndefinedMainScenario" ) export
	
	title = NStr ( "en=''" );
	text = NStr ( "en = 'Main scenario is undefined'; ru = 'Основной сценарий не определен'" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtServer
Function LoadingProcessVersionMemo () export

	text = NStr ( "en = 'Automatically created scenario version during files loading process'; ru = 'Автоматически созданная версия перед загрузкой сценария из файла'" );
	return text;

EndFunction

&AtClient
Procedure AssistantBuiltin ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "AssistantBuiltin" ) export
	
	text = NStr ( "en = 'Built-in functions cannot be changed'; ru = 'Встроенные функции не могут быть изменены'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtClient
Function RecordingSenario () export

	text = NStr ( "en = 'Recording...'; ru = 'Идет запись...'" );
	return text;

EndFunction

&AtClient
Function PauseScenario () export

	text = NStr ( "en = 'Pause'; ru = 'Пауза'" );
	return text;

EndFunction

Function RecordSenario () export

	text = NStr ( "en = 'Record: no connection'; ru = 'Запись: нет подключения'" );
	return text;

EndFunction

&AtClient
Function WrongFieldValue () export

	text = NStr ( "en = 'Wrong field value'; ru = 'Неверное значение поля'" );
	return text;

EndFunction

&AtServer
Procedure CommonReportOpenError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='This report is an official report and it cannot be opened interactively ';ru='Данный отчет является служебным и не предназначен для интерактивного открытия'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Function ClickGenerateReport () export
	
	text = NStr ( "en='Press the button ""Generate"" to create a report';ru='Нажмите кнопку Сформировать для формирования отчета'" );
	return text;
	
EndFunction

&AtClient
Procedure ReportVariantModified2 ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReportVariantModified2" ) export
	
	text = NStr ( "en='Current report version was modified."
"Would you like to save changes?';ru='Текущий вариант отчета модифицирован."
"Сохранить изменения?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNoCancel, 0, DialogReturnCode.Yes, title );
	
EndProcedure

&AtServer
Procedure ReportSchedulingIncorrectPeriod ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Selection by period is set to specific date. You cannot use the schedule because you set strict selection mode and the report will be delivered with the same data all the time. Try to set predefined value as a selection, not a specific date.';ru='Отбор по периоду установлен на конкретную дату. Использовать расписание нельзя, так как вы установили строгий отбор и будете каждый раз получать этот отчет с одними и теме же данными. Попробуйте указать в качестве отбора, не конкретную дату(ы), а предопределенное значение'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Procedure ReportVariantModified1 ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReportVariantModified1" ) export
	
	text = NStr ( "en='Current report version has been modified."
"Would you like to save current changes before loading the new version?';ru='Текущий вариант отчета модифицирован."
"Перед загрузкой нового варианта отчета, произвести сохранение текущих изменений?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNoCancel, 0, DialogReturnCode.Yes, title );
	
EndProcedure

&AtServer
Function LoadReportSettings () export
	
	text = NStr ( "en='Report settings';ru='Настройки отчета'" );
	return text;
	
EndFunction

&AtServer
Function LoadReportVariant () export
	
	text = NStr ( "en='Report variants';ru='Варианты отчета'" );
	return text;
	
EndFunction

&AtClient
Procedure ReplaceReportVariant ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReplaceReportVariant" ) export
	
	text = NStr ( "en='Overwrite the existing report settings?';ru='Перезаписать существующие настройки отчета?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
EndProcedure

&AtServer
Procedure SendingReportsByScheduleAddingError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Scheduled reports can be created and sent from specific form. Interactive access denied';ru='Создание графиков отправки осуществляется из форм конкретных отчетов. Интерактивное добавление недоступно'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure ScheduleDateError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Start the schedule from the date greater than current date';ru='Начните расписание с даты большей, чем текущая дата'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure WeekDaySelectionError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Please select at least one week day';ru='Выберите хотя бы один день недели'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Procedure ReportScheduleRemovingConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReportScheduleRemovingConfirmation" ) export
	
	text = NStr ( "en='Are you sure you want to delete the schedule?';ru='Удалить расписание?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
EndProcedure

&AtServer
Function ReportByEmailBody ( Params ) export
	
	text = NStr ( "en='Hello,"
"You received scheduled report %ReportPresentation. Report is attached to this e-mail."
""
"To change the schedule you can go to:"
"%ScheduleSettingsURL"
""
"Sincerely,"
"%Website';ru='Доброго времени суток!"
"Вы получили по расписанию отчет %ReportPresentation. Отчет во вложении к письму."
""
"Для изменения расписания, вы можете перейти по ссылке:"
"%ScheduleSettingsURL"
""
"С уважением, команда специалистов %Website'" );
	return Output.Sformat ( text, Params );
	
EndFunction

&AtServer
Function PageFooter () export
	
	text = NStr ( "en='[&PageNumber] from [&PagesTotal]';ru='[&PageNumber] from [&PagesTotal]'" );
	return text;
	
EndFunction

&AtClient
Procedure SetCurrentVersion ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SetCurrentVersion" ) export
	
	text = NStr ( "en = 'Selected version %Version will be used as current application version for your profile.
                  |Would you like to continue?'; ru = 'Для вашего профиля, версия %Version будет установлена как текущая.
                  |Продолжить?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
EndProcedure

&AtServer
Function ExpressionError () export
	
	text = NStr ( "en = 'Expression error'; ru = 'Ошибка в выражении'" );
	return text;
	
EndFunction

&AtServer
Function CurrentVersionUndefined () export
	
	text = NStr ( "en = 'Current version is not defined'; ru = 'Текущая версия не определена'" );
	return text;
	
EndFunction

&AtServer
Function VersionNotFound ( Params ) export
	
	text = NStr ( "en = 'Version <%Version> is not found'; ru = 'Версия <%Version> не найдена'" );
	return Output.Sformat ( text, Params );
	
EndFunction

&AtClient
Function StopDebugging () export

	text = NStr ( "en = 'Debugging stopped'; ru = 'Отладка остановлена'" );
	return text;

EndFunction

&AtClient
Procedure ApplicationChangingError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Application changing error. Scenario: %Scenario, Error: %Error'; ru = 'Не удалось изменить приложение для сценария %Scenario. Ошибка: %Error'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

Function OptionsLabelShow () export

	text = NStr ( "en = 'Options'; ru = 'Опции'" );
	return text;

EndFunction

Function OptionsLabelHide () export

	text = NStr ( "en = 'Hide'; ru = 'Скрыть'" );
	return text;

EndFunction

Function FilterLabelShow () export

	text = NStr ( "en = 'Filter: '; ru = 'Отбор: '" );
	return text;

EndFunction

Function LockedLabel () export

	text = NStr ( "en = 'Filtered by Locked'; ru = 'Отобраны захваченные'" );
	return text;

EndFunction

Function UnlockedLabel () export

	text = NStr ( "en = 'Filtered by Unlocked'; ru = 'Отобраны незахваченные'" );
	return text;

EndFunction

Function TagsFilter () export

	text = NStr ( "en = 'Tags'; ru = 'Теги'" );
	return text;

EndFunction

&AtClient
Function SourceNotFound () export

	text = NStr ( "en = 'Source not found '; ru = 'Источник не найден'" );
	return text;

EndFunction

&AtServer
Function NewTag () export

	text = NStr ( "en = 'New Tag'; ru = 'Новый тег'" );
	return text;

EndFunction

&AtServer
Procedure ObjectNotOriginal ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = '%Value already exists!'; ru = '%Value уже существует!'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Procedure TagRemovingConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "TagRemovingConfirmation" ) export
	
	text = NStr ( "en='Do you want to remove the tag?';ru='Удалить тег?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
EndProcedure

&AtClient
Procedure TagsListEmpty ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "TagsListEmpty" ) export
	
	text = NStr ( "en = 'Tags list is empty. For creating new tags please contact your administrator'; ru = 'Список тегов не задан. Для создания новых тегов, обратитесь к администратору за получением соответствующих прав доступа'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtClient
Function UndefinedExternalRequest () export

	text = NStr ( "en = 'Undefined request'; ru = 'Неопознанный запрос'" );
	return text;

EndFunction

&AtClient
Function FileReadingError ( Params ) export

	text = NStr ( "en = 'File reading timeout error: %File'; ru = 'Превышен таймаут ожидания для чтения файла: %File'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtClient
Function ErrorsNotFound () export

	text = NStr ( "en = 'No syntax errors found!'; ru = 'Синтаксических ошибок не обнаружено!'" );
	return text;

EndFunction

&AtClient
Function UndefinedScenario ( Params ) export

	text = NStr ( "en = 'Cannot find scenario by file: %File'; ru = 'Не удалось найти сценарий согласно файла: %File'" );
	return Sformat ( text, Params );

EndFunction

&AtClient
Function ScenarioApplicationUnmapped ( Params ) export

	text = NStr ( "en = 'Scenario <%Path> is not mapped to the folder of the file system'; ru = 'Сценарий <%Path> не синхронизирован с папкой файловой системы'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Procedure WrongRepoFolder1 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'One folder cannot be specified twice'; ru = 'Одна папка не может использоваться дважды'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure WrongRepoFolder2 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Repository folders cannot be inside of each other: %Folder1 <-> %Folder2. Use another folder path'; ru = 'Папки репозиториев не могут включать друг друга: %Folder1 <-> %Folder2. Укажите другой путь к папке'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure AgentAccessDenied ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = '%Creator cannot delegate tasks for the Agent: Access Denied'; ru = '%Creator не может делегировать задачи для этого агента: Отказано в доступе'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Function OpenErrorsLog () export

	text = NStr ( "en = 'Open Errors Log'; ru = 'Открыть журнал ошибок'" );
	return text;

EndFunction

&AtClient
Function OpenError () export

	text = NStr ( "en = 'Error: '; ru = 'Ошибка: '" );
	return text;

EndFunction

&AtClient
Function OpenLog () export

	text = NStr ( "en = 'Open Execution Log'; ru = 'Открыть журнал запуска'" );
	return text;

EndFunction

&AtClient
Function OpenScenario () export

	text = NStr ( "en = 'Open Scenario'; ru = 'Открыть сценарий'" );
	return text;

EndFunction

&AtClient
Procedure DeleteJob ( Module, CallbackParams = undefined, Params = undefined, ProcName = "DeleteJob" ) export
	
	text = NStr ( "en = 'Would you like to remove this job?'; ru = 'Удалить задание?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
EndProcedure

Function JobCanceled () export

	text = NStr ( "en = 'Job canceled'; ru = 'Задание отменено'" );
	return text;

EndFunction

&AtClient
Function TestedApplicationOffline () export

	text = NStr ( "en = 'Tested application is offline'; ru = 'Нет подключения к тестируемому приложению'" );
	return text;

EndFunction

&AtServer
Function AgentNotFound ( Params ) export

	text = NStr ( "en = 'Agent ""%Agent"" not found'; ru = 'Агент ""%Agent"" не найден'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Function ComputerNotFound ( Params ) export

	text = NStr ( "en = 'Computer ""%Computer"" not found'; ru = 'Компьютер ""%Computer"" не найден'" );
	return Sformat ( text, Params );

EndFunction

&AtClient
Function OSNotSupported () export
	
	text = NStr ( "en = 'The extended functions library supports Windows OS only. Other operating systems are not currently supported'; ru = 'Библиотека расширенных функций поддерживает работу в операционной системе Windows. Другие операционные системы в настоящий момент не поддерживаются'" );
	return text;
	
EndFunction

&AtServer
Procedure SourcesFolderError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'At least one folder should be defined'; ru = 'Как минимум одна папка должна быть определена'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure IncorrectVersion ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Length of version should be equal to length of test-manager version %Framework'; ru = 'Длина строки с версией должна совпадать с длиной версии менеджера тестирования %Framework'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure IncorrectIP ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'IP-address is incorrect'; ru = 'Некорректный IP-адрес'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Function ProxyAlreadyStarted ( Params ) export

	text = NStr ( "en = 'Proxy for the %Host:%Port has already been started'; ru = 'Прокси для %Host:%Port уже был запущен ранее'" );
	return Sformat ( text, Params );

EndFunction

&AtClient
Function UnableToClick ( Params ) export

	text = NStr ( "en = 'Unable to click %Field'; ru = 'Не удалось нажать на %Field'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Function CheckAppearanceError ( Params ) export

	text = NStr ( "en='Field ""%Field"" state ""%Value"" should be ""%Flag"". Actual state is ""%State""';ru='У поля ""%Field"" состояние ""%Value"" должно быть ""%Flag"", а реальное состояние ""%State""'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtServer
Function ShouldBe () export
	
	text = NStr ( "en = 'should be'; ru = 'должно быть'");
	return text;
	
EndFunction

&AtServer
Function ShouldNotBe () export
	
	text = NStr ( "en = 'should not be'; ru = 'не должно быть'");
	return text;
	
EndFunction

&AtServer
Function Filled () export
	
	text = NStr ( "en = 'filled'; ru = 'заполненным'");
	return text;
	
EndFunction

&AtServer
Function Empty () export
	
	text = NStr ( "en = 'empty'; ru = 'пустым'");
	return text;
	
EndFunction

&AtServer
Function Existed () export
	
	text = NStr ( "en = 'existed'; ru = 'существующим'");
	return text;
	
EndFunction

&AtServer
Function Between ( Params ) export
	
	text = NStr ( "en = 'between %Start and %Finish'; ru = 'между %Start и %Finish'");
	return Output.Sformat ( text, Params );
	
EndFunction

&AtServer
Function ShouldContain () export
	
	text = NStr ( "en = 'should contain'; ru = 'должно содержать'");
	return text;
	
EndFunction

&AtServer
Function ShouldNotContain () export
	
	text = NStr ( "en = 'should not contain'; ru = 'не должно содержать'");
	return text;
	
EndFunction

&AtServer
Function ShouldHave () export
	
	text = NStr ( "en = 'should have size'; ru = 'должно иметь размер'");
	return text;
	
EndFunction

&AtServer
Function ShouldNotHave () export
	
	text = NStr ( "en = 'should not have size'; ru = 'не должно иметь размер'");
	return text;
	
EndFunction

&AtServer
Function Value () export
	
	text = NStr ( "en = 'Value'; ru = 'Значение'");
	return text;
	
EndFunction

&AtServer
Function YesNo () export
	
	text = NStr ( "en = 'BF=False; BT=True'; ru = 'BF=Ложь; BT=Истина'");
	return text;
	
EndFunction

&AtClient
Procedure NoStepsInChronograph ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export
	
	text = NStr ( "en='Chronograph';ru='Хронограф'" );
	explanation = NStr ( "en = 'There are no steps for the selected direction'; ru = 'Нет шагов для перехода в указанном направлении'" );
	putUserNotification ( text, Params, NavigationLink, explanation, Picture );
	
EndProcedure

&AtServer
Function SessionAccessError () export
	
	text = NStr ( "en = 'You don’t have access to the tested session'; ru = 'Нет доступа к тестируемой сессии'");
	return text;
	
EndFunction

&AtServer
Function ScenarioNotFilmed () export
	
	text = NStr ( "en = 'Scenario wasn’t filmed'; ru = 'Сценарий не записывался в хронограф'");
	return text;
	
EndFunction

&AtClient
Procedure WrongFolder ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'The folder is referencing to itself'; ru = 'Папка ссылается на саму себя'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Function CopyingError () export
	
	text = NStr ( "en = 'Selected item causes levels looping!'; ru = 'Выбранный элемент приводит к зацикливанию уровней!'" );
	return text;
	
EndFunction

&AtClient
Procedure CopyMoveConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "CopyMoveConfirmation" ) export
	
	text = NStr ( "en = 'During the process system will change applications of transferred scenarios to %Application'; ru = 'При помещении сценариев в выбранную папку будет произведена замена приложения помещаемых сценариев на %Application'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
EndProcedure

&AtClient
Procedure ErrorNotLocated ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ErrorNotLocated" ) export
	
	text = NStr ( "en = 'Selected error has not been found in the list. Check filters in the list which can prevent locating the error'; ru = 'Не удалось перейти к строке с ошибкой. Проверьте установленные отборы, возможно они не позволяют найти выбранную в списке ошибку'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtClient
Function WebClientDoesNotSupport () export
	
	text = NStr ( "en = 'Web client does not support this functionality'; ru = 'Веб-клиент не поддерживает данную функциональность'" );
	return text;
	
EndFunction
