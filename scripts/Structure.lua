
local Config = require("scripts/Config")
local Utils = require("scripts/Utils")

local Structure = {}

local nextId = 1000

function Structure.Create(typeName, gridX, gridY, worldX, worldY)
    local definition = Config.StructureTypes[typeName]
    if not definition then
        return nil
    end

    nextId = nextId + 1
    return {
        id = nextId,
        type = typeName,
        name = definition.name,
        gridX = gridX,
        gridY = gridY,
        x = worldX,
        y = worldY,
        health = definition.health,
        maxHealth = definition.maxHealth,
        size = definition.size,
        color = definition.color,
        outline = definition.outline,
        blocksPath = definition.blocksPath,
        owner = "player",
        hitFlash = 0,
    }
end

function Structure.Damage(structure, amount)
    structure.health = structure.health - amount
    structure.hitFlash = 0.15
    return structure.health <= 0
end

function Structure.Update(structure, dt)
    if structure.hitFlash > 0 then
        structure.hitFlash = math.max(0, structure.hitFlash - dt)
    end
end

function Structure.Draw(nvg, structure, transform)
    local x, y = Utils.ToScreen(transform, structure.x, structure.y)
    local size = Utils.ToScreenSize(transform, structure.size)
    local flash = structure.hitFlash > 0 and 40 or 0

    nvgBeginPath(nvg)
    nvgRect(nvg, x - size * 0.5, y - size * 0.5, size, size)
    nvgFillColor(nvg, nvgRGBA(
        math.min(255, structure.color[1] + flash),
        math.min(255, structure.color[2] + flash),
        math.min(255, structure.color[3] + flash),
        structure.color[4]
    ))
    nvgFill(nvg)
    nvgStrokeColor(nvg, nvgRGBA(structure.outline[1], structure.outline[2], structure.outline[3], structure.outline[4]))
    nvgStrokeWidth(nvg, math.max(2, size * 0.12))
    nvgStroke(nvg)

    local barWidth = size * 1.2
    local barHeight = math.max(4, size * 0.12)
    local ratio = structure.health / structure.maxHealth

    nvgBeginPath(nvg)
    nvgRect(nvg, x - barWidth * 0.5, y - size * 0.8, barWidth, barHeight)
    nvgFillColor(nvg, nvgRGBA(20, 20, 20, 160))
    nvgFill(nvg)

    nvgBeginPath(nvg)
    nvgRect(nvg, x - barWidth * 0.5, y - size * 0.8, barWidth * ratio, barHeight)
    nvgFillColor(nvg, nvgRGBA(220, 150, 80, 200))
    nvgFill(nvg)
end

return Structure
