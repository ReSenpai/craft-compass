local _, ns = ...
if GetLocale() ~= "ruRU" then
    return
end
local L = ns.L

-- Подсказки и закреплённые окна
L.Quests = "Задания"
L.Completed = "выполнено"
L.NotUsed = "Не используется ни в рецептах, ни в заданиях."
L.QuestLevel = "Уровень %d"
L.QuestLinkHint = "Shift+клик — ссылка в чат."
L.Recipe = "Рецепт"
L.Trainer = "у учителя профессии"
L.SoldBy = "Продаёт"
L.DropsFrom = "Падает с"
L.FoundIn = "Лежит в"
L.QuestReward = "Награда за задание"
L.AndMore = "и ещё %d"

-- Настройки
L.OptionsTitle = "Craft Compass"
L.OptionsHelp = "Зажмите Shift над предметом, чтобы увидеть, для чего он нужен, или Alt, чтобы закрепить это в окне."
L.OnlyMyProfessions = "Только мои профессии"
L.OnlyMyProfessionsDesc = "Показывать рецепты только тех профессий, которые есть у персонажа."
L.ShowCompletedQuests = "Показывать выполненные задания"
L.ShowCompletedQuestsDesc = "Показывать задания, которые персонаж уже выполнил (с пометкой)."
L.ShowNotUsed = "Строка «не используется»"
L.ShowNotUsedDesc = "Писать об этом, если предмет не нужен ни в одном рецепте или задании."
