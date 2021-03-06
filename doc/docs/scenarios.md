Интерфейс Тестера организован с позиций удобного написания и запуска тестов. При первом запуске, на домашнюю страницу выводится справка по системе (выкачивается из интернета) и открывается основной сценарий, если он задан. В левой части системы находится текстовый редактор для ввода кода сценария, справа – дерево сценариев.

К сожалению, встроенный в Тестер редактор сценариев не поддерживает синтаксическое цветовое оформление модуля. При написании большого количества сложных тестов, можно использовать [возможность интеграции](vscode.md) Тестера с продвинутым редактором модулей Visual Studio Code.

Дерево сценариев
----------------

Тестер поставляется с демонстрационной базой. В демо-базе содержится небольшой набор универсальных тестов, а также специальные тесты для конфигурации ERP2. Я предлагаю использовать демо-базу в качестве начальной базы для создания вашей собственной инфраструктуры тестов.

Когда вы запускаете Тестер, в правой части экрана находится дерево сценариев. Это дерево позволяет организовать сценарии в виде иерархии. Каждый узел дерева имеет тип. Тип задает смысловое значение сценариев внутри узла, сортировку и пиктограмму. В терминологии 1С, это дерево – обычный иерархический справочник.

На картинке ниже показан пример дерева тестов из демонстрационной базы, и далее дано описание каждого маркера:

![](/img/2017_06_10_02_50_111.png)

### Типы сценариев, Маркер 1<a name=ScenarioTypes></a>

Левее маркера, в зеленом цвете и специальной пиктограмме, находятся такие узлы как Корзина, Общее, Таблица и другие.

Такое оформление означает, что это библиотеки тестов. Признак, что узел является библиотекой, задается при создании/редактировании теста:

![](/img/2017_06_10_02_58_562.png)

На картинке видно, что кроме библиотеки, тест может быть папкой, сценарием или методом.

Строгой технической привязки и контроля типа сценария в Тестере нет. Главное предназначение типов – это организация визуальной логики взаимосвязи сценариев.

В случае, если это библиотека, подразумевается, что внутри данной папки будут храниться только библиотечные сценарии-методы. Метод – это сценарий, который не должен привязываться к конкретной тестируемой логике приложения. Методы обычно могут принимать параметры, они работают как процедуры/функции. Методы не должны запускаться как отдельные, самостоятельные сценарии (запуск сценариев см. [здесь](#Running)).

Пример метода: `ПроверитьОшибкуЗаписи`.

Пример использования в коде сценария:

    Вызвать ( "Общее.ПроверитьОшибкуЗаписи", "Не заполнен контрагент" );

### Группы сценариев, Маркер 2

На этом маркере изображена папка Документы. Папка – это логическая группировка сценариев. Группировка может быть произвольной. Вы можете создавать папки с тестами по принципу тестируемых подсистем, ролей пользователей или технических заданий. Если вы не чувствуете, какая структура тестов вам нужна, тогда универсальным подходом является проецирование структуры тестов на объекты метаданных вашей конфигурации. Смело можно создавать группы Справочники, Документы и так далее. Внутри этих групп, создавать группы с названиями объектов метаданных, а следующим уровнем, располагать конкретные сценарии. В будущем, если потребуется, вы сможете сделать перегруппировку.

### Обычный сценарий, Маркер 3

Маркером отмечен стандартный сценарий. В данном случае, это сценарий под названием Начало. Обратите внимание, что пиктограмма левее, имеет небольшой желтый шарик справа, а у сценария на маркере 5 такого шарика нет. Наличие желтого шара означает, что внутри данного сценария, кроме скрипта сценария, находится еще и шаблон. Шаблоны используются для проверки бизнес-логики тестируемого приложения. Подробнее о проверке бизнес-логики см. [здесь](businesslogic.md).

### Сценарий-метод, Маркер 4<a name="ScenarioMethod"></a>

Этим маркером отмечен сценарий-метод. В данном случае, метод находится внутри обычной группы сценариев, а не в библиотеке. В этом случае, предполагается, что метод используется основными сценариями для разгрузки логики. Например, сценарий Начало будет вызывать сценарий-метод ЗадолженностьПоставщикам, который в свою очередь будет формировать отчет и проверять правильность показателей. Тестер, в дереве, располагает сценарии выше методов, чтобы они не смешивались.

### Основной сценарий, Маркер 5

Этим маркером отмечен обычный сценарий. Подчеркивание снизу указывает на то, что данный сценарий в настоящий момент текущий (основной). Основной сценарий, это тот сценарий, над которым сейчас работает программист. Любой сценарий может быть установлен основным (правый клик в дереве / Основной). У каждого пользователя системы Тестер может быть свой основной сценарий. Основной сценарий отличается от остальных тем, что его легко найти в дереве (правый клик в дереве / Найти основной сценарий) и легко запустить на выполнение (см. [Запуск тестов](#Running)). Также, основной сценарий автоматически открывается при запуске новой сессии Тестера.

### Приложения, Маркер 6

Под маркером 6 находится колонка с названием приложения, к которому принадлежит соответствующий сценарий.

Приложение устанавливается в форме редактирования сценария, для любого типа сценария:

![](/img/2017_06_10_16_50_311.png)

Поле `Приложение` можно не устанавливать, оставить пустым. В этом случае, предполагается что сценарий универсальный и может работать для всех приложений в системе.

Обратите внимание, что для библиотечных тестов и групп первого уровня (см. картинку с деревом тестов) приложение не задано, а для группы ЗаказПоставщику, ТестСоздания и т.д. приложение задано. Логика следующая: библиотечные тесты могут работать для любой конфигурации, поэтому при их создании, приложение не задали. Группа тестов Документы тоже будет в любой конфигурации, приложение также не задано. Для группы ЗаказПоставщику, ТестСоздания и т.д. приложение задано, потому что они имеет четкую привязку к тестируемому приложению.

Задавать приложение для сценариев нужно:

1.  Для логической группировки сценариев и возможности отбора сценариев в дереве тестов, см. картинку:  
    ![](/img/2017_06_10_17_22_082.png)
2.  Для контроля уникальности имен сценариев. Например, может существовать несколько тестов с названием ЗаказПоставщику, если для каждого из них задано отдельное приложение. Создать еще одну группу тестов с названием Документы нельзя, потому что она задана как общая, без указания конкретного приложения.

### Хранилище, Маркер 7

Правее маркера, находится колонка, определяющая в виде пиктограммы статус сценариев в хранилище тестов.

Стратегия редактирования сценариев в Тестере организована по принципу работы со стандартным хранилищем 1С. Для того, чтобы начать редактирование сценария, его нужно захватить (правый клик в дереве / Захватить). Для того, чтобы сценарий сохранить в хранилище тестов, его нужно туда поместить (правый клик в дереве / Поместить). В момент помещения теста в хранилище (или создания нового теста), создается его версия. В тот период времени, пока сценарий захвачен на редактирование, остальные участники тестирования могут использовать захваченный сценарий, но они не могут его изменять. При использовании захваченного сценария, программисты буду получать от Тестера последнюю версию сценария, а не текущую, которая редактируется в настоящий момент.

Например, если вы захватили и редактируете сценарий-метод ЗадолженностьПоставщикам, а другой программист запустил на выполнение сценарий Начало, который в свою очередь из кода вызовет заблокированный вами метод ЗадолженностьПоставщикам, Тестер отдаст этому программисту последнюю версию теста ЗадолженностьПоставщикам, которая была в хранилище до того, как вы начали его редактирование. Таким образом, ваши текущие изменения сценария не повлияют на работу других разработчиков.

При помещении изменений в хранилище, ваши изменения становятся доступны всем пользователям. Если вы разрабатываете определенный функционал, и ваши изменения теста могут затронуть работоспособность других связанных тестов, рекомендуется использовать метод [МояВерсия ()](api.md#MyVersionMethod).

### Запуск тестов<a name="Running"></a>

Любой тест из дерева тестов может быть запущен на выполнение, вне зависимости от его типа. Однако, как было сказано выше, предполагается, что запускаться должны только тесты с типом `Сценарий`, а сценарии-методы, должны вызываться из кода сценариев.

Основной способ запуска тестов это кнопка `F5` или команда `Запустить`:

![](/img/2017_06_10_18_40_543.png)

При запуске теста по кнопке `F5` (или командe `Запустить`) Тестер всегда запускает сценарий, установленный как [основной](http://test1c.com/#CurrentScenario). Таким образом, вне зависимости от кого, какой сценарий вы в данный момент редактируете, запускаться будет только основной.

Такой подход позволяет редактировать группу взаимосвязанных тестов, и быстро запускать весь сценарий на выполнение, без ненужных переключений вкладок. Кроме запуска основного сценария, имеется возможность запуска текущего сценария. Полный набор функций см. в контекстных меню Тестера.

Вкладка Поля<a name=FieldsPage></a>
------------

В процессе написания сценария, может возникать необходимость в анализе внутренней структуры окон тестируемого приложения.

Такой анализ нужен для выделения идентификаторов полей и точного к ним обращения из кода теста. Также, такой анализ может единственным способом разобраться в составе полей тестируемой формы в случаях, когда поля формируются динамически.

Для такой задачи на форме сценария присутствует вкладка `Поля` (для новых сценариев, вкладка скрыта, сценарий должен существовать):

![](/img/2016_11_10_12_32_081.png)

По порядку следования маркеров:

1.  Позволяет получить структуру всех окон тестируемого приложения, которые сейчас открыты на экране.
2.  Позволяет получить только текущее окно тестируемого приложения.
3.  Позволяет быстро найти в дереве элементов текущий активный элемент тестируемого приложения. Очень удобная функция при написании тестов. Например, можно открыть нужную форму и встать на нужный элемент, затем, в Тестере, получить эту форму (п.2) и нажать `Синхронизировать`. После этого, Тестер попытается найти и активировать строку в дереве с данным элементом. В случае неудачи, генерируется ошибка.
4.  При навигации по дереву, Тестер пытается активировать выделенные элементы в тестируемом приложении. Будьте внимательны, фокус может “прыгать” с дерева на тестируемое приложение.
5.  Для выделенного поля можно выполнить метод или получить свойство. Набор методов и свойств зависит от типа выделенного элемента и применяется согласно объектной модели тестируемого приложения платформы 1С. Например, на картинке поле `ОтборСостояние` имеет тип `ТестируемоеПолеФормы`. В синтаксис помощнике 1С, можно посмотреть, какие методы и свойства доступны объектам этого типа. Одно из них, свойство ТекстЗаголовка, результат получения которого выведен на картинке выше.