
local GridMap = require("scripts/GridMap")

local RoutePlanner = {}

local function heuristic(x1, y1, x2, y2)
    return math.abs(x1 - x2) + math.abs(y1 - y2)
end

local function getNeighbors(x, y, map)
    local neighbors = {}
    local directions = {
        {dx = 1, dy = 0},
        {dx = -1, dy = 0},
        {dx = 0, dy = 1},
        {dx = 0, dy = -1},
    }

    for _, dir in ipairs(directions) do
        local nx = x + dir.dx
        local ny = y + dir.dy
        if GridMap.IsWalkable(map, nx, ny) then
            table.insert(neighbors, {x = nx, y = ny})
        end
    end

    return neighbors
end

local function reconstructPath(cameFrom, current)
    local path = {current}
    while cameFrom[current.x] and cameFrom[current.x][current.y] do
        current = cameFrom[current.x][current.y]
        table.insert(path, 1, current)
    end
    return path
end

function RoutePlanner.FindPath(map, startX, startY, goalX, goalY)
    local openSet = {}
    local closedSet = {}
    local cameFrom = {}
    local gScore = {}
    local fScore = {}

    for y = 1, map.height do
        cameFrom[y] = {}
        gScore[y] = {}
        fScore[y] = {}
        for x = 1, map.width do
            gScore[y][x] = math.huge
            fScore[y][x] = math.huge
        end
    end

    gScore[startY][startX] = 0
    fScore[startY][startX] = heuristic(startX, startY, goalX, goalY)

    table.insert(openSet, {x = startX, y = startY})

    while #openSet &gt; 0 do
        local currentIndex = 1
        local current = openSet[1]
        for i, node in ipairs(openSet) do
            if fScore[node.y][node.x] &lt; fScore[current.y][current.x] then
                current = node
                currentIndex = i
            end
        end

        if current.x == goalX and current.y == goalY then
            local nodes = reconstructPath(cameFrom, current)
            return {
                nodes = nodes,
                totalCost = gScore[current.y][current.x],
                valid = true,
            }
        end

        table.remove(openSet, currentIndex)
        closedSet[current.y] = closedSet[current.y] or {}
        closedSet[current.y][current.x] = true

        local neighbors = getNeighbors(current.x, current.y, map)
        for _, neighbor in ipairs(neighbors) do
            if not (closedSet[neighbor.y] and closedSet[neighbor.y][neighbor.x]) then
                local tentativeGScore = gScore[current.y][current.x] + GridMap.GetMoveCost(map, neighbor.x, neighbor.y)

                if tentativeGScore &lt; gScore[neighbor.y][neighbor.x] then
                    cameFrom[neighbor.y] = cameFrom[neighbor.y] or {}
                    cameFrom[neighbor.y][neighbor.x] = current
                    gScore[neighbor.y][neighbor.x] = tentativeGScore
                    fScore[neighbor.y][neighbor.x] = tentativeGScore + heuristic(neighbor.x, neighbor.y, goalX, goalY)

                    local inOpenSet = false
                    for _, node in ipairs(openSet) do
                        if node.x == neighbor.x and node.y == neighbor.y then
                            inOpenSet = true
                            break
                        end
                    end

                    if not inOpenSet then
                        table.insert(openSet, neighbor)
                    end
                end
            end
        end
    end

    return {
        nodes = {},
        totalCost = 0,
        valid = false,
    }
end

function RoutePlanner.Draw(nvg, route, map, transform, colors)
    if not route or not route.valid or #route.nodes &lt; 2 then
        return
    end

    for i = 1, #route.nodes - 1 do
        local node1 = route.nodes[i]
        local node2 = route.nodes[i + 1]

        local x1, y1 = GridMap.GridToWorld(map, node1.x, node1.y)
        local x2, y2 = GridMap.GridToWorld(map, node2.x, node2.y)

        local sx1, sy1 = Utils.ToScreen(transform, x1, y1)
        local sx2, sy2 = Utils.ToScreen(transform, x2, y2)

        nvgBeginPath(nvg)
        nvgMoveTo(nvg, sx1, sy1)
        nvgLineTo(nvg, sx2, sy2)
        nvgStrokeColor(nvg, nvgRGBA(255, 255, 100, 150))
        nvgStrokeWidth(nvg, 4)
        nvgLineCap(nvg, NVG_ROUND)
        nvgStroke(nvg)
    end
end

return RoutePlanner
