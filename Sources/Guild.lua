--[[
Guild members by profession, for "who in the guild has it". The guild's club (C_Club, the
communities system behind the guild window) gives each member's two professions on Classic Era and
World of Warcraft: Forever, with name, level, class, zone and presence, offline members too; not
the skill (its rank is always 1) nor the recipes. Clients whose club has no professions get nothing.

Members are read anew at most every few seconds, and whenever the guild changes. They are sorted
by how near they are: the character's zone first, then the rest of its continent by the distance
from the character to the middle of their zone (the club gives zones, not positions), then the
rest online, then offline, the ones seen last first.
]]
local _, ns = ...
local Util = ns.Util

local Guild = {}
ns.Guild = Guild

-- The skill line of each of AtlasLoot's profession ids (Crafts.GetProfession takes those).
local SKILL_LINES = {
    [1] = 129, -- First Aid
    [2] = 164, -- Blacksmithing
    [3] = 165, -- Leatherworking
    [4] = 171, -- Alchemy
    [5] = 182, -- Herbalism
    [6] = 185, -- Cooking
    [7] = 186, -- Mining
    [8] = 197, -- Tailoring
    [9] = 202, -- Engineering
    [10] = 333, -- Enchanting
    [11] = 356, -- Fishing
    [12] = 393, -- Skinning
    [14] = 755 -- Jewelcrafting
}
-- Enum.ClubMemberPresence: online, online in the app, away, busy.
local ONLINE_PRESENCE = {[1] = true, [2] = true, [4] = true, [5] = true}
local MAX_AGE = 5
-- Enum.UIMapType.Zone: zones and cities.
local ZONE_MAP_TYPE = 3

local members
local readAt = 0
local zoneCenters

local function Available()
    return type(C_Club) == "table" and type(C_Club.GetGuildClubId) == "function"
        and type(C_Club.GetClubMembers) == "function" and type(C_Club.GetMemberInfo) == "function"
        and IsInGuild ~= nil and IsInGuild()
end

local function ClassFile(classId)
    local info = classId and C_CreatureInfo and C_CreatureInfo.GetClassInfo and C_CreatureInfo.GetClassInfo(classId)
    return info and info.classFile
end

--- Hours since a member was last online, from the club's years, months, days and hours.
local function HoursAway(info)
    return (info.lastOnlineYear or 0) * 8760 + (info.lastOnlineMonth or 0) * 730
        + (info.lastOnlineDay or 0) * 24 + (info.lastOnlineHour or 0)
end

local function ReadMembers()
    members = {}
    readAt = GetTime()
    local clubId = C_Club.GetGuildClubId()
    if not clubId then
        return
    end
    for _, memberId in ipairs(C_Club.GetClubMembers(clubId) or {}) do
        local info = C_Club.GetMemberInfo(clubId, memberId)
        if type(info) == "table" and info.name and not info.isSelf
            and (info.profession1ID or info.profession2ID) then
            table.insert(members, {
                name = info.name,
                level = info.level,
                classFile = ClassFile(info.classID),
                zone = info.zone,
                online = ONLINE_PRESENCE[info.presence] == true,
                hoursAway = HoursAway(info),
                professions = {[info.profession1ID or 0] = true, [info.profession2ID or 0] = true}
            })
        end
    end
end

local function Members()
    if not members or GetTime() - readAt > MAX_AGE then
        ReadMembers()
    end
    return members
end

--- A position in the world, {continent, x, y} in yards, of a point on a map; nil where the client can't tell.
local function WorldPosition(mapId, mapPosition)
    local ok, continent, position = pcall(C_Map.GetWorldPosFromMapPos, mapId, mapPosition)
    if not (ok and continent and position) then
        return nil
    end
    local x, y = position:GetXY()
    return {continent, x, y}
end

local function HasWorldPositions()
    return C_Map ~= nil and C_Map.GetBestMapForUnit ~= nil and C_Map.GetMapInfo ~= nil
        and C_Map.GetMapChildrenInfo ~= nil and C_Map.GetWorldPosFromMapPos ~= nil
        and C_Map.GetPlayerMapPosition ~= nil and CreateVector2D ~= nil
end

--[[
The middle of each zone in the world, by zone name (the roster names zones), from the zones under
the map the character's map belongs to. Built once there is a map.
]]
local function ZoneCenters()
    if zoneCenters or not HasWorldPositions() then
        return zoneCenters or {}
    end
    local mapId = C_Map.GetBestMapForUnit("player")
    local root = mapId and C_Map.GetMapInfo(mapId)
    while root and root.parentMapID and root.parentMapID ~= 0 and C_Map.GetMapInfo(root.parentMapID) do
        root = C_Map.GetMapInfo(root.parentMapID)
    end
    if not root then
        return {}
    end
    zoneCenters = {}
    local middle = CreateVector2D(0.5, 0.5)
    for _, zone in ipairs(C_Map.GetMapChildrenInfo(root.mapID, ZONE_MAP_TYPE, true) or {}) do
        if not zoneCenters[zone.name] then
            zoneCenters[zone.name] = WorldPosition(zone.mapID, middle)
        end
    end
    return zoneCenters
end

--- Where the character is in the world, or nil (in an instance, or without the map API).
local function PlayerPosition()
    if not HasWorldPositions() then
        return nil
    end
    local mapId = C_Map.GetBestMapForUnit("player")
    local mapPosition = mapId and C_Map.GetPlayerMapPosition(mapId, "player")
    return mapPosition and WorldPosition(mapId, mapPosition)
end

--[[
How near a member is: near is 1 in the character's zone, 2 on its continent (with the distance to
the middle of the member's zone), 3 elsewhere online, 4 offline.
]]
local function Place(member, zone, player, centers)
    if not member.online then
        return 4
    elseif member.zone and member.zone == zone then
        return 1, 0
    end
    local center = member.zone and centers[member.zone]
    if player and center and center[1] == player[1] then
        return 2, math.sqrt((center[2] - player[2]) ^ 2 + (center[3] - player[3]) ^ 2)
    end
    return 3
end

--[[
The guild members with the profession of an AtlasLoot profession id, nearest first, and how many
of them are online. A member is {name, level, classFile, zone, online, near, distance}, near
being 1 for the character's zone. Nil without guild data on this client.
]]
function Guild.ForProfession(professionId)
    local skillLine = SKILL_LINES[professionId]
    if not skillLine or not Available() then
        return nil
    end
    local zone = GetRealZoneText and GetRealZoneText()
    local player, centers = PlayerPosition(), ZoneCenters()
    local found, online = {}, 0
    for _, member in ipairs(Members()) do
        if member.professions[skillLine] then
            member.near, member.distance = Place(member, zone, player, centers)
            table.insert(found, member)
            if member.online then
                online = online + 1
            end
        end
    end
    table.sort(found, function (a, b)
        if a.near ~= b.near then
            return a.near < b.near
        elseif a.near == 2 and a.distance ~= b.distance then
            return a.distance < b.distance
        elseif a.near == 4 and a.hoursAway ~= b.hoursAway then
            return a.hoursAway < b.hoursAway
        elseif a.near > 1 and a.near < 4 and a.zone ~= b.zone then
            return (a.zone or "") < (b.zone or "")
        end
        return a.name < b.name
    end)
    return found, online
end

--- Asks the server for the guild's roster anew, so that presence and zones are fresh.
function Guild.RequestUpdate()
    local guildRoster = C_GuildInfo and C_GuildInfo.GuildRoster or _G.GuildRoster
    if guildRoster and Available() then
        Util.SafeCall(guildRoster)
    end
end

--- Opens the chat input to whisper a member.
function Guild.Whisper(name)
    local sendTell = ChatFrameUtil and ChatFrameUtil.SendTell or _G.ChatFrame_SendTell
    if sendTell then
        sendTell(name, DEFAULT_CHAT_FRAME)
    end
end

local frame = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_GUILD_UPDATE", "GUILD_ROSTER_UPDATE", "CLUB_MEMBER_ADDED", "CLUB_MEMBER_REMOVED",
    "CLUB_MEMBER_UPDATED", "CLUB_MEMBER_PRESENCE_UPDATED"}) do
    -- The club events exist only on clients with C_Club.
    pcall(frame.RegisterEvent, frame, event)
end
frame:SetScript("OnEvent", function ()
    members = nil
end)
