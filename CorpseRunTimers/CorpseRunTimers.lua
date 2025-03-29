local timerBarsFrame = CreateFrame("Frame", "CorpseRunTimersBarsAnchor", UIParent)
local addonFrame = CreateFrame("Frame")
local updateFrame = CreateFrame("Frame")

local knownPlayers = {}
local activeTimers = {}
local timerBarHeight = 15
local timerBarWidth = 190
local barSpacing = 2


local function ConvertMapCoordsToYards(mapID, x, y)
    local zoneInfo = CRT_ZoneData[mapID]
    if not zoneInfo then return nil end
    local yardsX = (x / 100) * zoneInfo.width
    local yardsY = (y / 100) * zoneInfo.height
    return yardsX, yardsY
end

local function CalculateYardDistanceBetweenCoordinates(mapID, x1, y1, x2, y2)
    local yards1X, yards1Y = ConvertMapCoordsToYards(mapID, x1, y1)
    local yards2X, yards2Y = ConvertMapCoordsToYards(mapID, x2, y2)
    if not yards1X or not yards2X then return nil end
    return math.sqrt((yards2X - yards1X) ^ 2 + (yards2Y - yards1Y) ^ 2)
end

local function IsPointInPolygon(point, polygon)
    local inside = false
    local j = #polygon

    for i = 1, #polygon do
        if ((polygon[i].y > point.y) ~= (polygon[j].y > point.y)) and
            (point.x < (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) /
                (polygon[j].y - polygon[i].y) + polygon[i].x) then
            inside = not inside
        end
        j = i
    end

    return inside
end

local function GetPathForLocation(mapID, x, y)
    local zone = CRT_WaypointPathDataPerZone[mapID]
    if not zone then return nil end

    local point = { x = x, y = y }
    for _, area in ipairs(zone.areasThatRequireWaypointPath) do
        if IsPointInPolygon(point, area.polygon) then
            return area.path
        end
    end
    return nil
end

local function CalculatePathDistance(mapID, startX, startY, endX, endY)
    local path = GetPathForLocation(mapID, startX, startY)
    if not path then
        return CalculateYardDistanceBetweenCoordinates(mapID, startX, startY, endX, endY)
    end

    local totalDistance = 0
    local lastX, lastY = endX, endY -- Start at graveyard coordinates

    -- First waypoint is path to restricted area
    for _, wp in ipairs(path) do
        totalDistance = totalDistance + CalculateYardDistanceBetweenCoordinates(mapID, lastX, lastY, wp.x, wp.y)
        lastX, lastY = wp.x, wp.y
    end

    -- Add final distance from last waypoint to death location
    totalDistance = totalDistance + CalculateYardDistanceBetweenCoordinates(mapID, lastX, lastY, startX, startY)
    return totalDistance
end

local function GetDistanceToNearestGraveyard(mapId, deathX, deathY)
    local zone = CRT_ZoneData[mapId]
    if not zone then return nil end

    local nearestDist = math.huge

    for _, gy in ipairs(zone.graveyards) do
        local dist = CalculatePathDistance(mapId, deathX, deathY, gy.x, gy.y)
        if dist and dist < nearestDist then
            nearestDist = dist
        end
    end

    return nearestDist
end

local function CalculateReturnTime(distance, isNightElf)
    local effectiveDistance = math.max(0, distance - CRT_CORPSE_RESURRECTION_RANGE)
    local speedModifier = isNightElf and CRT_WISP_SPIRIT_MODIFIER or CRT_GHOST_SPEED_MODIFIER
    local returnTime = math.ceil(effectiveDistance / (CRT_BASE_RUNNING_SPEED * speedModifier))
    local delayForReleasingSpirit = 1.5 -- seconds
    return returnTime + delayForReleasingSpirit
end

local function InitTimerBarsFrame()
    timerBarsFrame:SetSize(timerBarWidth, timerBarHeight)
    timerBarsFrame:SetPoint("CENTER")
    timerBarsFrame:EnableMouse(true)
    timerBarsFrame:SetMovable(true)
    timerBarsFrame:RegisterForDrag("LeftButton")
    timerBarsFrame:SetScript("OnDragStart", timerBarsFrame.StartMoving)
    timerBarsFrame:SetScript("OnDragStop", timerBarsFrame.StopMovingOrSizing)
    timerBarsFrame:Show()
end

local function UpdateTimerBarPositions()
    local index = 0
    for _, timer in pairs(activeTimers) do
        timer.frame:ClearAllPoints()
        timer.frame:SetPoint("TOP", timerBarsFrame, "TOP", 0, -(index * (timerBarHeight + barSpacing)))
        index = index + 1
    end
end

local function CreateTimerBar(playerName, duration, level, class, shouldPause)
    -- If timer already exists, update its duration and pause state
    if activeTimers[playerName] then
        local timer = activeTimers[playerName]
        timer.duration = duration
        timer.startTime = GetTime()
        timer.paused = shouldPause
        timer.bar:SetMinMaxValues(0, duration)
        timer.bar:SetValue(duration)
        return timer
    end

    local frame = CreateFrame("Frame", nil, timerBarsFrame)
    frame:SetSize(timerBarWidth, timerBarHeight)

    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

    local color = CLASS_COLORS[class] or { r = 1, g = 0, b = 0 }
    bar:SetStatusBarColor(color.r, color.g, color.b)
    bar:SetAllPoints(true)
    bar:SetMinMaxValues(0, duration)
    bar:SetValue(duration)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bg:SetVertexColor(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.8)

    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")

    local timer = {
        frame = frame,
        bar = bar,
        text = text,
        duration = duration,
        remaining = duration,
        playerName = playerName,
        level = level,
        class = class,
        startTime = GetTime(),
        paused = shouldPause
    }
    activeTimers[playerName] = timer

    UpdateTimerBarPositions()
    return timer
end

local function UpdateTimerBars()
    local currentTime = GetTime()
    local needsRepositioning = false

    for playerName, timer in pairs(activeTimers) do
        local remaining = nil
        if timer.paused then
            timer.bar:SetValue(timer.duration)
            remaining = timer.duration
        else
            local elapsed = currentTime - timer.startTime
            remaining = timer.duration - elapsed

            if remaining <= 0 then
                timer.frame:Hide()
                activeTimers[playerName] = nil
                needsRepositioning = true
            else
                timer.bar:SetValue(remaining)
            end
        end
        local className = CRT_CLASS_NAMES[timer.class] or timer.class
        local levelText = (timer.level == -1) and "??" or tostring(timer.level)
        timer.text:SetText(string.format("%s (%s %s): %d",
            timer.playerName,
            levelText,
            className,
            math.ceil(remaining)))
    end

    if needsRepositioning then
        UpdateTimerBarPositions()
    end
end

local function SimulatePlayerDeath(args)
    local testLevel = math.random(10, 60)
    -- testLevel = -1
    local testX, testY

    -- Parse arguments: level x y or just x y
    local arg1, arg2, arg3 = strsplit(" ", args or "")
    if arg3 then
        testLevel = tonumber(arg1) or 60
        testX = tonumber(arg2)
        testY = tonumber(arg3)
    elseif arg2 then
        testX = tonumber(arg1)
        testY = tonumber(arg2)
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    local zoneText = C_Map.GetMapInfo(mapID).name
    if not CRT_ZoneData[mapID] then
        print("[CorpseRunTimers]: Error - Current zone '" .. zoneText .. "' ".. "(" .. mapID .. ")" .. " is not supported")
        return
    end

    local x, y
    if testX and testY then
        x, y = testX, testY
    else
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        x = pos.x * 100
        y = pos.y * 100
    end

    print("Test data:")
    print("- Zone: " .. zoneText .. "(" .. mapID .. ")")
    print("- Position: " .. string.format("%.1f, %.1f", x, y))

    local path = GetPathForLocation(zoneText, x, y)
    print("- Path calculation: " .. (path and "Using waypoint path" or "Using direct path"))

    local zoneInfo = CRT_ZoneData[mapID]
    print("\nAvailable graveyards:")
    for i, gy in ipairs(zoneInfo.graveyards) do
        local dist = CalculateYardDistanceBetweenCoordinates(mapID, x, y, gy.x, gy.y)
        if dist then
            print(string.format("  %d. Coordinates: %.1f, %.1f - Direct distance: %.1f yards",
                i, gy.x, gy.y, dist))
        end
    end

    local distance = GetDistanceToNearestGraveyard(mapID, x, y)
    if distance then
        print(string.format("\nSimulation results:"))
        testPlayerNumber = math.random(1, 10)
        testClassNumber = math.random(1, 9)
        if testClassNumber == 1 then
            testClass = "WARRIOR"
        elseif testClassNumber == 2 then
            testClass = "ROGUE"
        elseif testClassNumber == 3 then
            testClass = "PRIEST"
        elseif testClassNumber == 4 then
            testClass = "DRUID"
        elseif testClassNumber == 5 then
            testClass = "MAGE"
        elseif testClassNumber == 6 then
            testClass = "WARLOCK"
        elseif testClassNumber == 7 then
            testClass = "HUNTER"
        elseif testClassNumber == 8 then
            testClass = "PALADIN"
        elseif testClassNumber == 9 then
            testClass = "SHAMAN"
        end
        local isNightElf = false
        local runTime = CalculateReturnTime(distance, isNightElf)
        print(string.format("- Is Night Elf: %s", isNightElf and "Yes" or "No"))
        print(string.format("- Speed modifier: %.2fx", isNightElf and CRT_WISP_SPIRIT_MODIFIER or CRT_GHOST_SPEED_MODIFIER))
        print(string.format("- Actual path distance: %.1f yards", distance))
        print(string.format("- Minimum return time: %d seconds", runTime))
        CreateTimerBar("Player" .. testPlayerNumber, runTime, testLevel, testClass)
    end
end

local function StorePlayerInfo(unit)
    if UnitIsPlayer(unit) then
        local name = UnitName(unit)
        local _, class = UnitClass(unit)
        local level = UnitLevel(unit)
        local _, race = UnitRace(unit)

        if not knownPlayers[name] then
            knownPlayers[name] = {}
        end

        knownPlayers[name].level = level -- Treat "??" as very high level
        knownPlayers[name].class = class
        knownPlayers[name].race = race
        -- DEFAULT_CHAT_FRAME:AddMessage("Stored player info: " .. name .. ", race: " .. knownPlayers[name].race .. " class: " .. knownPlayers[name].class .. ", level: " .. knownPlayers[name].level)
    end
end

local function HandleUnitDiedEvent(destGUID, unitName)
    local _, class, _, _, _, _ = GetPlayerInfoByGUID(destGUID)

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    local zoneText = C_Map.GetMapInfo(mapID).name
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return end

    local distance = GetDistanceToNearestGraveyard(mapID, pos.x * 100, pos.y * 100)
    if not distance then return end

    local isNightElf = knownPlayers[unitName] and knownPlayers[unitName].race == "NightElf"
    local runTime = CalculateReturnTime(distance, isNightElf)
    if class then
        local level = -1
        if knownPlayers[unitName] and knownPlayers[unitName].level then
            level = knownPlayers[unitName].level
        end
        CreateTimerBar(unitName, runTime, level, class, false)
    end
end

local function PauseTimerForTargetIfExists(targetName)
    if targetName and activeTimers[targetName] then
        local timer = activeTimers[targetName]
        timer.remaining = timer.duration
        timer.paused = true
    end
end

local function UnpauseTimerForPlayerNotInTargetAnymore(targetName)
    for playerName, timer in pairs(activeTimers) do
        if playerName ~= targetName and timer.paused then
            timer.paused = false
            timer.startTime = GetTime()
        end
    end
end

local function HandleTargetChangedEvent()
    local targetName = UnitName("target")
    PauseTimerForTargetIfExists(targetName)
    UnpauseTimerForPlayerNotInTargetAnymore(targetName)
end

local function HandleCombatLogEvent()
    local _, subEvent, _, _, _, _, _, destGUID, unitName, destFlags = CombatLogGetCurrentEventInfo()

    if subEvent == "UNIT_DIED" and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0 then
        if bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0 then
            HandleUnitDiedEvent(destGUID, unitName)
        end
    end
end

local function OnEvent(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        HandleCombatLogEvent()
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        StorePlayerInfo("mouseover")
    elseif event == "PLAYER_TARGET_CHANGED" then
        StorePlayerInfo("target")
        HandleTargetChangedEvent()
    end
end


function RegisterEvents()
    addonFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    addonFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    addonFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    addonFrame:SetScript("OnEvent", OnEvent)
    updateFrame:SetScript("OnUpdate", UpdateTimerBars)
end

function RegisterSlashCommands()
    SLASH_CORPSERUNTIMERS1 = "/crt"
    SlashCmdList["CORPSERUNTIMERS"] = function(msg)
        SimulatePlayerDeath(msg)
    end
end

function Main()
    RegisterEvents()
    RegisterSlashCommands()
    InitTimerBarsFrame()
end

Main()
