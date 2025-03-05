GHOST_SPEED_MODIFIER = 1.25
BASE_RUNNING_SPEED = 7         -- yards per second
CORPSE_RESURRECTION_RANGE = 40 -- yards
WISP_SPIRIT_MODIFIER = 1.50    -- 50% additional speed for Night Elf ghosts

CLASS_COLORS = {
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    ROGUE = { r = 1.00, g = 0.96, b = 0.41 },
    PRIEST = { r = 1.00, g = 1.00, b = 1.00 },
    DRUID = { r = 1.00, g = 0.49, b = 0.04 },
    MAGE = { r = 0.41, g = 0.80, b = 0.94 },
    WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
    HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    SHAMAN = { r = 0.00, g = 0.44, b = 0.87 }
}

CLASS_NAMES = {
    WARRIOR = "Warrior",
    ROGUE = "Rogue",
    PRIEST = "Priest",
    DRUID = "Druid",
    MAGE = "Mage",
    WARLOCK = "Warlock",
    HUNTER = "Hunter",
    PALADIN = "Paladin",
    SHAMAN = "Shaman"
}

ZoneData = {
    ["Redridge Mountains"] = {
        width = 2170.833229570681,
        height = 1447.922213393415,
        graveyards = {
            { x = 20.8, y = 56.6 }, -- Lakeshire
        }
    },
    ["Duskwood"] = {
        width = 2699.999669551933,
        height = 1800.007653419076,
        graveyards = {
            { x = 75.1, y = 59.0 }, -- Darkshire
            { x = 19.9, y = 49.2 }, -- Raven Hill
        }
    },
    ["Elwynn Forest"] = {
        width = 3470.831971412848,
        height = 2314.591970284716,
        graveyards = {
            { x = 39.5, y = 60.4 }, -- Goldshire
            { x = 83.5, y = 69.8 }  -- Eastvale Logging Camp
        }
    },
    ["Teldrassil"] = {
        width = 5091.720903621394,
        height = 3393.726923234355,
        graveyards = {
            { x = 59.0, y = 42.6 }, -- Shadowglen
            { x = 56.1, y = 63.1 }  -- Dolanaar
        }
    },
}

WaypointPathData = {
    ["Redridge Mountains"] = {
        areasThatRequireWaypointPath = {
            { -- Alther's Mill
                polygon = {
                    { x = 44.25, y = 43.75 },
                    { x = 50.17, y = 36.24 },
                    { x = 61.64, y = 39.70 },
                    { x = 62.32, y = 49.21 },
                    { x = 49.20, y = 51.80 }
                },
                path = {
                    { x = 28.75, y = 50.04 }, -- Lakeshire dock
                    { x = 40.48, y = 39.56 }, -- Ramp
                }
            },
            { -- Redner's Camp
                polygon = {
                    { x = 44.87, y = 24.59 },
                    { x = 33.33, y = 13.28 },
                    { x = 35.38, y = 5.29 },
                    { x = 40.19, y = 11.14 },
                    { x = 44.90, y = 14.40 },
                },
                path = {
                    { x = 28.75, y = 50.04 }, -- Lakeshire dock
                    { x = 45.78, y = 32.19 }, -- Ramp
                    { x = 47.67, y = 27.56 }, -- Choke
                    { x = 46.59, y = 23.62 }, -- Ramp
                }
            }
        }
    }
}
