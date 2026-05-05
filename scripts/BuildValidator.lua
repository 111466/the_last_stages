
local GridMap = require("scripts/GridMap")
local RoutePlanner = require("scripts/RoutePlanner")

local BuildValidator = {}

function BuildValidator.CanPlaceStructure(map, structures, gridX, gridY)
    local tile = GridMap.GetTile(map, gridX, gridY)
    if not tile then
        return false, "超出地图范围"
    end

    if not tile.fortifiable then
        return false, "此处不可施工"
    end

    if tile.occupantType ~= nil then
        return false, "与已有建筑冲突"
    end

    for _, structure in ipairs(structures) do
        if structure.gridX == gridX and structure.gridY == gridY then
            return false, "与已有工事冲突"
        end
    end

    return true, nil
end

function BuildValidator.WouldBlockPathCompletely(map, structures, gridX, gridY)
    local tile = GridMap.GetTile(map, gridX, gridY)
    if not tile then
        return true
    end

    local originalBlocked = tile.blocked
    tile.blocked = true

    local pathValid = false
    for _, spawn in ipairs(map.spawnPoints) do
        for _, goal in ipairs(map.goalPoints) do
            local route = RoutePlanner.FindPath(map, spawn.x, spawn.y, goal.x, goal.y)
            if route.valid then
                pathValid = true
                break
            end
        end
        if pathValid then
            break
        end
    end

    tile.blocked = originalBlocked

    return not pathValid
end

return BuildValidator
