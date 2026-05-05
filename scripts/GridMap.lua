
local Config = require("scripts/Config")

local GridMap = {}

GridMap.TileTypes = {
    ROAD = "road",
    GROUND = "ground",
    BLOCK = "block",
    BUILDABLE = "buildable",
    FORTIFIABLE = "fortifiable",
    DESTRUCTIBLE = "destructible",
    GOAL = "goal",
    SPAWN = "spawn",
}

GridMap.TileCosts = {
    road = 1,
    ground = 2,
    slow_zone = 3,
    hazard_zone = 4,
}

local function createTile(x, y, terrain)
    return {
        x = x,
        y = y,
        terrain = terrain or GridMap.TileTypes.GROUND,
        buildable = false,
        fortifiable = false,
        blocked = false,
        occupantType = nil,
        structureId = nil,
    }
end

function GridMap.Create(config)
    local map = {
        tileSize = config.TileSize or 64,
        width = config.GridWidth or 20,
        height = config.GridHeight or 12,
        tiles = {},
        spawnPoints = {},
        goalPoints = {},
    }

    for y = 1, map.height do
        map.tiles[y] = {}
        for x = 1, map.width do
            map.tiles[y][x] = createTile(x, y, GridMap.TileTypes.GROUND)
        end
    end

    GridMap._initDefaultMap(map)

    return map
end

function GridMap._initDefaultMap(map)
    local pathCoords = {
        {1, 3}, {2, 3}, {3, 3}, {4, 3}, {5, 3},
        {5, 4}, {5, 5}, {5, 6}, {5, 7}, {5, 8},
        {6, 8}, {7, 8}, {8, 8}, {9, 8}, {10, 8},
        {10, 7}, {10, 6}, {10, 5}, {10, 4}, {10, 3},
        {11, 3}, {12, 3}, {13, 3}, {14, 3}, {15, 3},
        {15, 4}, {15, 5}, {15, 6}, {15, 7}, {15, 8}, {15, 9}, {15, 10},
        {16, 10}, {17, 10}, {18, 10}, {19, 10}, {20, 10},
    }

    for _, coord in ipairs(pathCoords) do
        local tile = GridMap.GetTile(map, coord[1], coord[2])
        if tile then
            tile.terrain = GridMap.TileTypes.ROAD
        end
    end

    local spawnTile = GridMap.GetTile(map, 1, 3)
    if spawnTile then
        spawnTile.terrain = GridMap.TileTypes.SPAWN
        table.insert(map.spawnPoints, {x = 1, y = 3})
    end

    local goalTile = GridMap.GetTile(map, 20, 10)
    if goalTile then
        goalTile.terrain = GridMap.TileTypes.GOAL
        table.insert(map.goalPoints, {x = 20, y = 10})
    end

    local buildSlots = {
        {4, 2}, {4, 4}, {6, 6}, {6, 9}, {9, 2}, {9, 6}, {11, 2}, {11, 9},
        {14, 4}, {14, 9}, {17, 9}, {17, 11},
    }

    for _, slot in ipairs(buildSlots) do
        local tile = GridMap.GetTile(map, slot[1], slot[2])
        if tile then
            tile.buildable = true
            tile.fortifiable = true
        end
    end

    local blockTiles = {
        {1, 1}, {1, 2}, {1, 4}, {1, 5}, {1, 6}, {1, 7}, {1, 8}, {1, 9}, {1, 10}, {1, 11}, {1, 12},
        {2, 1}, {2, 2}, {2, 11}, {2, 12},
        {3, 1}, {3, 2}, {3, 11}, {3, 12},
        {4, 1}, {4, 11}, {4, 12},
        {5, 1}, {5, 2}, {5, 11}, {5, 12},
        {6, 1}, {6, 2}, {6, 3}, {6, 4}, {6, 5}, {6, 10}, {6, 11}, {6, 12},
        {7, 1}, {7, 2}, {7, 3}, {7, 4}, {7, 5}, {7, 6}, {7, 7}, {7, 9}, {7, 10}, {7, 11}, {7, 12},
        {8, 1}, {8, 2}, {8, 3}, {8, 4}, {8, 5}, {8, 6}, {8, 7}, {8, 9}, {8, 10}, {8, 11}, {8, 12},
        {9, 1}, {9, 3}, {9, 4}, {9, 5}, {9, 7}, {9, 8}, {9, 9}, {9, 10}, {9, 11}, {9, 12},
        {10, 1}, {10, 2}, {10, 10}, {10, 11}, {10, 12},
        {11, 1}, {11, 4}, {11, 5}, {11, 6}, {11, 7}, {11, 8}, {11, 10}, {11, 11}, {11, 12},
        {12, 1}, {12, 2}, {12, 4}, {12, 5}, {12, 6}, {12, 7}, {12, 8}, {12, 9}, {12, 10}, {12, 11}, {12, 12},
        {13, 1}, {13, 2}, {13, 4}, {13, 5}, {13, 6}, {13, 7}, {13, 8}, {13, 9}, {13, 10}, {13, 11}, {13, 12},
        {14, 1}, {14, 2}, {14, 3}, {14, 5}, {14, 6}, {14, 7}, {14, 8}, {14, 10}, {14, 11}, {14, 12},
        {15, 1}, {15, 2}, {15, 3}, {15, 11}, {15, 12},
        {16, 1}, {16, 2}, {16, 3}, {16, 4}, {16, 5}, {16, 6}, {16, 7}, {16, 8}, {16, 9}, {16, 11}, {16, 12},
        {17, 1}, {17, 2}, {17, 3}, {17, 4}, {17, 5}, {17, 6}, {17, 7}, {17, 8}, {17, 10}, {17, 12},
        {18, 1}, {18, 2}, {18, 3}, {18, 4}, {18, 5}, {18, 6}, {18, 7}, {18, 8}, {18, 9}, {18, 11}, {18, 12},
        {19, 1}, {19, 2}, {19, 3}, {19, 4}, {19, 5}, {19, 6}, {19, 7}, {19, 8}, {19, 9}, {19, 11}, {19, 12},
        {20, 1}, {20, 2}, {20, 3}, {20, 4}, {20, 5}, {20, 6}, {20, 7}, {20, 8}, {20, 9}, {20, 11}, {20, 12},
    }

    for _, block in ipairs(blockTiles) do
        local tile = GridMap.GetTile(map, block[1], block[2])
        if tile then
            tile.terrain = GridMap.TileTypes.BLOCK
            tile.blocked = true
        end
    end
end

function GridMap.GetTile(map, gridX, gridY)
    if gridX &lt; 1 or gridX &gt; map.width or gridY &lt; 1 or gridY &gt; map.height then
        return nil
    end
    return map.tiles[gridY][gridX]
end

function GridMap.WorldToGrid(map, worldX, worldY)
    local gridX = math.floor(worldX / map.tileSize) + 1
    local gridY = math.floor(worldY / map.tileSize) + 1
    return gridX, gridY
end

function GridMap.GridToWorld(map, gridX, gridY)
    local worldX = (gridX - 0.5) * map.tileSize
    local worldY = (gridY - 0.5) * map.tileSize
    return worldX, worldY
end

function GridMap.IsWalkable(map, gridX, gridY)
    local tile = GridMap.GetTile(map, gridX, gridY)
    if not tile then
        return false
    end
    if tile.terrain == GridMap.TileTypes.BLOCK then
        return false
    end
    if tile.blocked then
        return false
    end
    return true
end

function GridMap.GetMoveCost(map, gridX, gridY)
    local tile = GridMap.GetTile(map, gridX, gridY)
    if not tile then
        return math.huge
    end
    return GridMap.TileCosts[tile.terrain] or 2
end

function GridMap.Draw(nvg, map, transform, colors)
    local tileSizeScreen = map.tileSize * transform.scale

    for y = 1, map.height do
        for x = 1, map.width do
            local tile = map.tiles[y][x]
            local worldX, worldY = GridMap.GridToWorld(map, x, y)
            local screenX, screenY = Utils.ToScreen(transform, worldX, worldY)

            local color
            if tile.terrain == GridMap.TileTypes.BLOCK then
                color = {40, 40, 50, 255}
            elseif tile.terrain == GridMap.TileTypes.ROAD then
                color = {72, 90, 60, 255}
            elseif tile.terrain == GridMap.TileTypes.SPAWN then
                color = {200, 80, 80, 255}
            elseif tile.terrain == GridMap.TileTypes.GOAL then
                color = {80, 200, 80, 255}
            elseif tile.buildable or tile.fortifiable then
                color = {60, 100, 140, 255}
            else
                color = {50, 70, 85, 255}
            end

            nvgBeginPath(nvg)
            nvgRect(nvg, screenX - tileSizeScreen * 0.5, screenY - tileSizeScreen * 0.5, tileSizeScreen, tileSizeScreen)
            nvgFillColor(nvg, nvgRGBA(color[1], color[2], color[3], color[4]))
            nvgFill(nvg)

            nvgBeginPath(nvg)
            nvgRect(nvg, screenX - tileSizeScreen * 0.5, screenY - tileSizeScreen * 0.5, tileSizeScreen, tileSizeScreen)
            nvgStrokeColor(nvg, nvgRGBA(80, 100, 115, 80))
            nvgStrokeWidth(nvg, 1)
            nvgStroke(nvg)
        end
    end
end

return GridMap
