local _, ns = ...
if GetLocale() ~= "ruRU" then
    return
end
local L = ns.L

-- Подсказки и закреплённые окна
L.Quests = "Задания"
L.Completed = "выполнено"
L.QuestLevel = "Уровень %d"
L.QuestLinkHint = "Shift+клик — ссылка в чат."
L.PinLinkHint = "Alt+клик по ссылке — закрепить, реагенты откроются оттуда."
L.Recipe = "Рецепт"
L.Trainer = "у учителя профессии"
L.SoldBy = "Продаёт"
L.QuestReward = "Награда за задание"
L.WhereToGet = "Где взять"
L.Zones = "Зоны"
L.NodesPerZone = "Сколько точек появления в каждой зоне."
L.OpenListHint = "Щелчок — весь список."
L.WowheadPage = "Страница на Wowhead"
L.CopyUrlClickHint = "Щелчок — скопировать адрес."
L.CopyUrlHint = "Нажмите Ctrl+C, чтобы скопировать адрес, и вставьте его в браузер."
L.AndMore = "и ещё %d"

-- Настройки
L.OptionsTitle = "Craft Compass"
L.OptionsHelp = "Зажмите Shift над предметом, чтобы увидеть, для чего он нужен, или Alt, чтобы закрепить это в окне."
L.OnlyMyProfessions = "Только мои профессии"
L.OnlyMyProfessionsDesc = "Показывать рецепты только тех профессий, которые есть у персонажа."
L.ShowCompletedQuests = "Показывать выполненные задания"
L.ShowCompletedQuestsDesc = "Показывать задания, которые персонаж уже выполнил (с пометкой)."
