local _, ns = ...
if GetLocale() ~= "ruRU" then
    return
end
local L = ns.L

-- Подсказки и закреплённые окна
L.Quests = "Задания"
L.Completed = "выполнено"
L.QuestLevel = "Уровень %d"
L.QuestLinkHint = "Щелчок — окно задания, Shift+щелчок — ссылка в чат."
L.QuestTitleHint = "Shift+щелчок — ссылка в чат."
L.QuestLevels ="Уровень %d (доступно с %d)"
L.InQuestLog = "в журнале заданий"
L.QuestStartedBy = "Даёт"
L.QuestFinishedBy = "Сдать"
L.QuestItems = "Принести"
L.QuestBefore = "Сначала"
L.QuestNext = "Дальше"
L.OpenInQuestie = "Открыть в Questie"
L.OpenInQuestieHint = "Окно задания в самом Questie."
L.PinLinkHint = "Alt+клик по ссылке — закрепить, реагенты откроются оттуда."
L.Recipe = "Рецепт"
L.Trainer = "у учителя профессии"
L.SoldBy = "Продаёт"
L.QuestReward = "Награда за задание"
L.WhereToGet = "Где взять"
L.Zones = "Зоны"
L.ZonesOrder = "Сначала зоны, где их больше всего."
L.OpenListHint = "Щелчок — весь список."
L.WowheadPage = "Страница на Wowhead"
L.CopyUrlClickHint = "Щелчок — скопировать адрес."
L.CopyUrlHint = "Нажмите Ctrl+C — адрес скопируется, а окно закроется. Затем вставьте его в браузер."
L.AndMore = "и ещё %d"

-- Настройки
L.OptionsTitle = "Craft Compass"
L.OptionsHelp = "Зажмите Shift над предметом, чтобы увидеть, для чего он нужен, или Alt, чтобы закрепить это в окне."
L.OnlyMyProfessions = "Только мои профессии"
L.OnlyMyProfessionsDesc = "Показывать рецепты только тех профессий, которые есть у персонажа."
L.ShowCompletedQuests = "Показывать выполненные задания"
L.ShowCompletedQuestsDesc = "Показывать задания, которые персонаж уже выполнил (с пометкой)."
L.NoAtlasLoot = "для рецептов нужен AtlasLoot (AtlasLoot Classic или AtlasLoot Continued); без него показываются только задания."
L.TwoAtlasLoots = "включены сразу %s и %s, а вместе они ломают друг друга. Выключите один из них: Craft Compass работает с любым, а больше всего рецептов у AtlasLoot Continued."
