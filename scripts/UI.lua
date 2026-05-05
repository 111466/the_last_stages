
local UI = {}

local function PointInRect(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

function UI.Render(nvg, view)
    nvgSave(nvg)

    if view.phase == "title" then
        UI.DrawTitleScreen(nvg, view.screenWidth, view.screenHeight)
    elseif view.phase == "level_select" then
        UI.DrawLevelSelect(nvg, view.levels, view.screenWidth, view.screenHeight)
    else
        UI.DrawBattleHUD(
            nvg,
            view.gold,
            view.lives,
            view.wave,
            view.heroState,
            view.screenWidth,
            view.screenHeight,
            view.currentLevel,
            view.totalWaves
        )
    end

    nvgRestore(nvg)
end

function UI.DrawTitleScreen(nvg, screenWidth, screenHeight)
    nvgFillColor(nvg, nvgRGBA(28, 38, 62, 255))
    nvgBeginPath(nvg)
    nvgRect(nvg, 0, 0, screenWidth, screenHeight)
    nvgFill(nvg)

    nvgFillColor(nvg, nvgRGBA(52, 74, 118, 255))
    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, 120, 90, screenWidth - 240, screenHeight - 180, 28)
    nvgFill(nvg)

    nvgStrokeColor(nvg, nvgRGBA(128, 178, 255, 180))
    nvgStrokeWidth(nvg, 2)
    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, 120, 90, screenWidth - 240, screenHeight - 180, 28)
    nvgStroke(nvg)

    nvgTextAlign(nvg, 1)
    nvgFillColor(nvg, nvgRGBA(255, 244, 212, 255))
    nvgFontSize(nvg, 52)
    nvgText(nvg, screenWidth / 2, 210, "Tiny Swords")

    nvgFillColor(nvg, nvgRGBA(226, 238, 255, 255))
    nvgFontSize(nvg, 28)
    nvgText(nvg, screenWidth / 2, 260, "动作 RPG + 塔防 守卫战")

    nvgFontSize(nvg, 18)
    nvgFillColor(nvg, nvgRGBA(214, 224, 240, 220))
    nvgText(nvg, screenWidth / 2, 315, "操控英雄近战迎敌，搭配技能与防御塔守住最后据点。")

    local buttonX = screenWidth / 2 - 130
    local buttonY = screenHeight / 2 + 20
    local buttonW = 260
    local buttonH = 64
    UI.DrawButton(nvg, buttonX, buttonY, buttonW, buttonH, "开始游戏", true)

    nvgFontSize(nvg, 18)
    nvgFillColor(nvg, nvgRGBA(235, 240, 248, 255))
    nvgText(nvg, screenWidth / 2, buttonY + 110, "回车 / 空格 或 点击按钮继续")

    nvgFontSize(nvg, 16)
    nvgFillColor(nvg, nvgRGBA(210, 220, 238, 220))
    nvgText(nvg, screenWidth / 2, screenHeight - 150, "移动: WASD   普攻: 空格/左键   建塔: 5/6/7/8 + 右键")
    nvgText(nvg, screenWidth / 2, screenHeight - 118, "技能: 1/2/3/4   升级: F1-F4/U   购买装备: Z/X/C")
end

function UI.DrawLevelSelect(nvg, levels, screenWidth, screenHeight)
    nvgFillColor(nvg, nvgRGBA(22, 30, 48, 255))
    nvgBeginPath(nvg)
    nvgRect(nvg, 0, 0, screenWidth, screenHeight)
    nvgFill(nvg)

    nvgTextAlign(nvg, 1)
    nvgFillColor(nvg, nvgRGBA(255, 244, 212, 255))
    nvgFontSize(nvg, 42)
    nvgText(nvg, screenWidth / 2, 100, "选择关卡")

    nvgFontSize(nvg, 18)
    nvgFillColor(nvg, nvgRGBA(210, 220, 238, 220))
    nvgText(nvg, screenWidth / 2, 138, "点击任意关卡立即开始战斗")

    UI.DrawButton(nvg, 40, 40, 120, 42, "返回", false)

    local cardWidth = 320
    local cardHeight = 250
    local gap = 24
    local totalWidth = (#levels * cardWidth) + ((#levels - 1) * gap)
    local startX = (screenWidth - totalWidth) / 2
    local startY = 200

    for i, level in ipairs(levels) do
        local x = startX + (i - 1) * (cardWidth + gap)
        local y = startY

        nvgFillColor(nvg, nvgRGBA(58, 78, 118, 235))
        nvgBeginPath(nvg)
        nvgRoundedRect(nvg, x, y, cardWidth, cardHeight, 18)
        nvgFill(nvg)

        nvgStrokeColor(nvg, nvgRGBA(138, 184, 255, 220))
        nvgStrokeWidth(nvg, 2)
        nvgBeginPath(nvg)
        nvgRoundedRect(nvg, x, y, cardWidth, cardHeight, 18)
        nvgStroke(nvg)

        nvgTextAlign(nvg, 0)
        nvgFillColor(nvg, nvgRGBA(255, 230, 160, 255))
        nvgFontSize(nvg, 18)
        nvgText(nvg, x + 22, y + 36, level.tag)

        nvgFillColor(nvg, nvgRGBA(245, 248, 255, 255))
        nvgFontSize(nvg, 28)
        nvgText(nvg, x + 22, y + 78, level.name)

        nvgFillColor(nvg, nvgRGBA(220, 228, 244, 230))
        nvgFontSize(nvg, 16)
        nvgTextBox(nvg, x + 22, y + 112, cardWidth - 44, level.description)

        nvgFillColor(nvg, nvgRGBA(180, 224, 255, 255))
        nvgText(nvg, x + 22, y + 178, "初始金币: " .. level.initialGold)
        nvgText(nvg, x + 22, y + 206, "据点耐久: " .. level.initialLives)
        nvgText(nvg, x + 22, y + 234, "波次规模: " .. #level.waves .. " 波")
    end
end

function UI.DrawBattleHUD(nvg, gold, lives, wave, heroState, screenWidth, screenHeight, currentLevel, totalWaves)
    nvgTextAlign(nvg, 3)

    nvgFillColor(nvg, nvgRGBA(235, 244, 255, 235))
    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, 10, 10, screenWidth - 20, 52, 14)
    nvgFill(nvg)

    nvgStrokeColor(nvg, nvgRGBA(150, 188, 235, 255))
    nvgStrokeWidth(nvg, 2)
    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, 10, 10, screenWidth - 20, 52, 14)
    nvgStroke(nvg)

    nvgFontSize(nvg, 18)
    nvgFillColor(nvg, nvgRGBA(255, 215, 0, 255))
    nvgText(nvg, 26, 32, "金币: " .. gold)
    nvgFillColor(nvg, nvgRGBA(255, 80, 80, 255))
    nvgText(nvg, 180, 32, "据点: " .. lives)
    nvgFillColor(nvg, nvgRGBA(70, 85, 120, 255))
    nvgText(nvg, 330, 32, "波次: " .. wave .. "/" .. totalWaves)
    nvgFillColor(nvg, nvgRGBA(80, 180, 120, 255))
    nvgText(nvg, 500, 32, "击杀: " .. heroState.killCount)
    nvgFillColor(nvg, nvgRGBA(90, 110, 155, 255))
    nvgText(nvg, 660, 32, "建塔 5/6/7/8")
    nvgText(nvg, 820, 32, "升级 F1-F4/U")
    nvgText(nvg, 980, 32, "装备 Z/X/C")

    if currentLevel then
        nvgTextAlign(nvg, 1)
        nvgFillColor(nvg, nvgRGBA(225, 238, 255, 255))
        nvgFontSize(nvg, 16)
        nvgText(nvg, screenWidth / 2, 84, "当前关卡: " .. currentLevel.name .. "    Esc 返回主菜单")
    end

    UI.DrawHeroBars(nvg, heroState)
    UI.DrawSkillBar(nvg, screenWidth, screenHeight)
    UI.DrawTowerBar(nvg, gold, screenWidth, screenHeight)
    UI.DrawEquipmentBar(nvg, gold, screenWidth, screenHeight)
    UI.DrawSelectionHint(nvg, screenWidth, screenHeight)

    if not WaveManager.waveActive and not WaveManager.allComplete then
        local remaining = math.ceil(math.max(WaveManager.prepTimer, 0))
        nvgFillColor(nvg, nvgRGBA(255, 200, 50, 255))
        nvgFontSize(nvg, 28)
        nvgTextAlign(nvg, 1)
        nvgText(nvg, screenWidth / 2, 116, "下一波: " .. remaining .. "秒")
    end

    if WaveManager.allComplete then
        UI.DrawBattleEndOverlay(nvg, screenWidth, screenHeight, true)
    elseif not heroState.alive or lives <= 0 then
        UI.DrawBattleEndOverlay(nvg, screenWidth, screenHeight, false)
    end
end

function UI.DrawHeroBars(nvg, heroState)
    local bx = 15
    local by = 72

    nvgFillColor(nvg, nvgRGBA(238, 243, 250, 220))
    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, bx, by, 180, 16, 4)
    nvgFill(nvg)

    local hpRatio = heroState.hp / heroState.maxHP
    local hpColor = hpRatio > 0.5 and {80, 200, 80}
        or (hpRatio > 0.25 and {220, 180, 40} or {220, 50, 50})
    nvgFillColor(nvg, nvgRGBA(hpColor[1], hpColor[2], hpColor[3], 255))
    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, bx, by, 180 * hpRatio, 16, 4)
    nvgFill(nvg)

    nvgFillColor(nvg, nvgRGBA(35, 40, 55, 255))
    nvgFontSize(nvg, 12)
    nvgTextAlign(nvg, 1)
    nvgText(nvg, bx + 90, by + 12, math.floor(heroState.hp) .. "/" .. heroState.maxHP)

    nvgFillColor(nvg, nvgRGBA(225, 233, 250, 220))
    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, bx, by + 20, 180, 10, 3)
    nvgFill(nvg)
    nvgFillColor(nvg, nvgRGBA(80, 120, 255, 255))
    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, bx, by + 20, 180 * (heroState.mana / Hero.config.maxMana), 10, 3)
    nvgFill(nvg)
end

function UI.DrawSkillBar(nvg, screenWidth, screenHeight)
    local startX = screenWidth / 2 - 120
    local sy = screenHeight - 70

    for i = 1, 4 do
        local slot = Skills.slots[i]
        local sx = startX + (i - 1) * 65

        local unlocked = slot.level > 0
        local ready = unlocked and slot.cooldownTimer <= 0
            and Hero.state.mana >= Skills.definitions[slot.id].manaCost

        if ready then
            nvgFillColor(nvg, nvgRGBA(214, 235, 255, 240))
        elseif unlocked then
            nvgFillColor(nvg, nvgRGBA(228, 232, 242, 220))
        else
            nvgFillColor(nvg, nvgRGBA(210, 214, 224, 170))
        end
        nvgBeginPath(nvg)
        nvgRoundedRect(nvg, sx, sy, 55, 55, 8)
        nvgFill(nvg)

        nvgStrokeColor(nvg, nvgRGBA(115, 145, 195, 255))
        nvgStrokeWidth(nvg, 2)
        nvgBeginPath(nvg)
        nvgRoundedRect(nvg, sx, sy, 55, 55, 8)
        nvgStroke(nvg)

        if unlocked and slot.cooldownTimer > 0 then
            local cdRatio = slot.cooldownTimer / Skills.definitions[slot.id].cooldown
            nvgFillColor(nvg, nvgRGBA(0, 0, 0, 150))
            nvgBeginPath(nvg)
            nvgRoundedRect(nvg, sx, sy, 55, 55 * cdRatio, 8)
            nvgFill(nvg)
        end

        if unlocked then
            UI.DrawSkillIcon(nvg, slot.id, sx, sy)
            nvgFillColor(nvg, nvgRGBA(70, 88, 120, 255))
            nvgFontSize(nvg, 10)
            nvgTextAlign(nvg, 1)
            nvgText(nvg, sx + 27, sy + 45, "Lv." .. slot.level)
        else
            nvgFillColor(nvg, nvgRGBA(110, 118, 132, 220))
            nvgFontSize(nvg, 11)
            nvgTextAlign(nvg, 1)
            nvgText(nvg, sx + 27, sy + 30, "未解锁")
        end

        nvgFillColor(nvg, nvgRGBA(180, 180, 180, 200))
        nvgFontSize(nvg, 10)
        nvgText(nvg, sx + 20, sy - 5, tostring(i))
    end
end

function UI.DrawTowerBar(nvg, gold, screenWidth, screenHeight)
    local startX = screenWidth - 350
    local ty = screenHeight - 70

    nvgFillColor(nvg, nvgRGBA(255, 255, 255, 230))
    nvgFontSize(nvg, 14)
    nvgTextAlign(nvg, 0)
    nvgText(nvg, startX, ty - 8, "防御塔 5/6/7/8 选择, 右键放置")

    local towerTypes = { "archer_tower", "cannon_tower", "frost_tower", "lightning_tower" }
    for i, typeName in ipairs(towerTypes) do
        local config = Tower.types[typeName]
        local tx = startX + (i - 1) * 85

        local canAfford = gold >= config.cost
        nvgFillColor(nvg, nvgRGBA(
            canAfford and 230 or 205,
            canAfford and 238 or 215,
            canAfford and 250 or 225, 235))
        nvgBeginPath(nvg)
        nvgRoundedRect(nvg, tx, ty, 75, 55, 6)
        nvgFill(nvg)

        nvgStrokeColor(nvg, nvgRGBA(120, 150, 205, 255))
        nvgStrokeWidth(nvg, InputController.state.placingTower == typeName and 3 or 2)
        nvgBeginPath(nvg)
        nvgRoundedRect(nvg, tx, ty, 75, 55, 6)
        nvgStroke(nvg)

        nvgFillColor(nvg, nvgRGBA(config.color[1], config.color[2], config.color[3], 255))
        nvgBeginPath(nvg)
        nvgCircle(nvg, tx + 37, ty + 18, 12)
        nvgFill(nvg)

        nvgFillColor(nvg, nvgRGBA(255, 255, 255, 255))
        nvgFontSize(nvg, 12)
        nvgTextAlign(nvg, 1)
        nvgText(nvg, tx + 37, ty + 40, config.name)
        nvgFillColor(nvg, nvgRGBA(255, 215, 0, 255))
        nvgFontSize(nvg, 10)
        nvgText(nvg, tx + 37, ty + 52, config.cost .. "G")
    end
end

function UI.DrawEquipmentBar(nvg, gold, screenWidth, screenHeight)
    local startX = 220
    local sy = screenHeight - 70
    local slots = { "weapon", "armor", "accessory" }
    local labels = { weapon = "武器 Z", armor = "护甲 X", accessory = "饰品 C" }

    nvgFillColor(nvg, nvgRGBA(255, 255, 255, 220))
    nvgFontSize(nvg, 14)
    nvgTextAlign(nvg, 0)
    nvgText(nvg, startX, sy - 8, "装备购买")

    for i, slot in ipairs(slots) do
        local itemId = Equipment.GetNextItem(slot)
        local tx = startX + (i - 1) * 95
        local item = itemId and Equipment.items[itemId] or nil

        nvgFillColor(nvg, nvgRGBA(240, 236, 228, 230))
        nvgBeginPath(nvg)
        nvgRoundedRect(nvg, tx, sy, 85, 55, 8)
        nvgFill(nvg)
        nvgStrokeColor(nvg, nvgRGBA(176, 150, 104, 255))
        nvgStrokeWidth(nvg, 2)
        nvgBeginPath(nvg)
        nvgRoundedRect(nvg, tx, sy, 85, 55, 8)
        nvgStroke(nvg)

        nvgFillColor(nvg, nvgRGBA(82, 64, 42, 255))
        nvgFontSize(nvg, 11)
        nvgTextAlign(nvg, 1)
        nvgText(nvg, tx + 42, sy + 18, labels[slot])

        if item then
            nvgFillColor(nvg, nvgRGBA(gold >= item.price and 70 or 140, 90, 120, 255))
            nvgText(nvg, tx + 42, sy + 34, item.name)
            nvgFillColor(nvg, nvgRGBA(190, 130, 40, 255))
            nvgText(nvg, tx + 42, sy + 49, item.price .. "G")
        else
            nvgFillColor(nvg, nvgRGBA(110, 110, 110, 255))
            nvgText(nvg, tx + 42, sy + 36, "已满级")
        end
    end
end

function UI.DrawSelectionHint(nvg, screenWidth, screenHeight)
    if not InputController.state.placingTower then return end
    nvgFillColor(nvg, nvgRGBA(255, 245, 200, 255))
    nvgFontSize(nvg, 16)
    nvgTextAlign(nvg, 1)
    nvgText(nvg, screenWidth / 2, screenHeight - 92,
        "已选择 " .. Tower.types[InputController.state.placingTower].name .. "，右键放置")
end

function UI.DrawBattleEndOverlay(nvg, screenWidth, screenHeight, victory)
    nvgFillColor(nvg, nvgRGBA(10, 14, 24, 165))
    nvgBeginPath(nvg)
    nvgRect(nvg, 0, 0, screenWidth, screenHeight)
    nvgFill(nvg)

    local panelX = screenWidth / 2 - 220
    local panelY = screenHeight / 2 - 120
    local panelW = 440
    local panelH = 240

    nvgFillColor(nvg, nvgRGBA(34, 46, 70, 245))
    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, panelX, panelY, panelW, panelH, 20)
    nvgFill(nvg)

    nvgStrokeColor(nvg, nvgRGBA(146, 190, 255, 220))
    nvgStrokeWidth(nvg, 2)
    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, panelX, panelY, panelW, panelH, 20)
    nvgStroke(nvg)

    nvgTextAlign(nvg, 1)
    nvgFontSize(nvg, 38)
    if victory then
        nvgFillColor(nvg, nvgRGBA(90, 210, 130, 255))
        nvgText(nvg, screenWidth / 2, panelY + 72, "胜利！")
        nvgFillColor(nvg, nvgRGBA(224, 236, 248, 230))
        nvgFontSize(nvg, 18)
        nvgText(nvg, screenWidth / 2, panelY + 108, "成功守住据点，准备迎接下一场战斗。")
    else
        nvgFillColor(nvg, nvgRGBA(255, 92, 92, 255))
        nvgText(nvg, screenWidth / 2, panelY + 72, "游戏结束")
        nvgFillColor(nvg, nvgRGBA(224, 236, 248, 230))
        nvgFontSize(nvg, 18)
        nvgText(nvg, screenWidth / 2, panelY + 108, "据点失守，可以重整阵型后再次挑战。")
    end

    UI.DrawButton(nvg, screenWidth / 2 - 170, panelY + 150, 150, 52, "重新挑战", true)
    UI.DrawButton(nvg, screenWidth / 2 + 20, panelY + 150, 150, 52, "主菜单", false)

    nvgFillColor(nvg, nvgRGBA(206, 216, 234, 220))
    nvgFontSize(nvg, 14)
    nvgText(nvg, screenWidth / 2, panelY + 222, "快捷键: R 重新开始, Esc 返回菜单")
end

function UI.DrawButton(nvg, x, y, w, h, label, primary)
    if primary then
        nvgFillColor(nvg, nvgRGBA(93, 144, 255, 235))
        nvgStrokeColor(nvg, nvgRGBA(190, 220, 255, 255))
    else
        nvgFillColor(nvg, nvgRGBA(70, 88, 120, 220))
        nvgStrokeColor(nvg, nvgRGBA(160, 188, 235, 240))
    end

    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, x, y, w, h, 12)
    nvgFill(nvg)

    nvgStrokeWidth(nvg, 2)
    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, x, y, w, h, 12)
    nvgStroke(nvg)

    nvgTextAlign(nvg, 1)
    nvgFillColor(nvg, nvgRGBA(255, 255, 255, 255))
    nvgFontSize(nvg, 22)
    nvgText(nvg, x + w / 2, y + h / 2 + 7, label)
end

function UI.DrawSkillIcon(nvg, skillId, sx, sy)
    local cx = sx + 27
    local cy = sy + 20
    nvgStrokeColor(nvg, nvgRGBA(70, 95, 145, 255))
    nvgStrokeWidth(nvg, 3)

    if skillId == "whirlwind" then
        nvgBeginPath(nvg)
        nvgArc(nvg, cx, cy, 12, -2.2, 0.8, 1)
        nvgStroke(nvg)
        nvgBeginPath(nvg)
        nvgArc(nvg, cx, cy, 7, 0.4, 2.9, 1)
        nvgStroke(nvg)
    elseif skillId == "charge" then
        nvgBeginPath(nvg)
        nvgMoveTo(nvg, cx - 14, cy + 6)
        nvgLineTo(nvg, cx + 12, cy - 2)
        nvgLineTo(nvg, cx + 2, cy - 8)
        nvgStroke(nvg)
    elseif skillId == "war_cry" then
        nvgBeginPath(nvg)
        nvgMoveTo(nvg, cx - 10, cy + 10)
        nvgLineTo(nvg, cx - 2, cy + 2)
        nvgLineTo(nvg, cx - 2, cy - 8)
        nvgLineTo(nvg, cx + 12, cy - 12)
        nvgLineTo(nvg, cx + 12, cy + 12)
        nvgLineTo(nvg, cx - 2, cy + 8)
        nvgLineTo(nvg, cx - 2, cy + 2)
        nvgStroke(nvg)
    elseif skillId == "meteor" then
        nvgBeginPath(nvg)
        nvgCircle(nvg, cx, cy - 2, 8)
        nvgStroke(nvg)
        nvgBeginPath(nvg)
        nvgMoveTo(nvg, cx - 10, cy - 12)
        nvgLineTo(nvg, cx + 10, cy + 8)
        nvgStroke(nvg)
    end
end

function UI.GetTowerCardAt(mx, my, screenWidth, screenHeight)
    local startX = screenWidth - 350
    local ty = screenHeight - 70
    local towerTypes = { "archer_tower", "cannon_tower", "frost_tower", "lightning_tower" }
    for i, typeName in ipairs(towerTypes) do
        local tx = startX + (i - 1) * 85
        if mx >= tx and mx <= tx + 75 and my >= ty and my <= ty + 55 then
            return typeName
        end
    end
    return nil
end

function UI.GetEquipmentCardAt(mx, my, screenWidth, screenHeight)
    local startX = 220
    local sy = screenHeight - 70
    local slots = { "weapon", "armor", "accessory" }
    for i, slot in ipairs(slots) do
        local tx = startX + (i - 1) * 95
        if mx >= tx and mx <= tx + 85 and my >= sy and my <= sy + 55 then
            return slot
        end
    end
    return nil
end

function UI.GetTitleButtonAt(mx, my, screenWidth, screenHeight)
    local x = screenWidth / 2 - 130
    local y = screenHeight / 2 + 20
    if PointInRect(mx, my, x, y, 260, 64) then
        return "start"
    end
    return nil
end

function UI.GetLevelCardAt(mx, my, screenWidth, screenHeight, levels)
    local cardWidth = 320
    local cardHeight = 250
    local gap = 24
    local totalWidth = (#levels * cardWidth) + ((#levels - 1) * gap)
    local startX = (screenWidth - totalWidth) / 2
    local startY = 200

    for i, level in ipairs(levels) do
        local x = startX + (i - 1) * (cardWidth + gap)
        if PointInRect(mx, my, x, startY, cardWidth, cardHeight) then
            return level.id
        end
    end
    return nil
end

function UI.GetLevelSelectButtonAt(mx, my, screenWidth, screenHeight)
    if PointInRect(mx, my, 40, 40, 120, 42) then
        return "back"
    end
    return nil
end

function UI.GetBattleEndButtonAt(mx, my, screenWidth, screenHeight)
    local panelY = screenHeight / 2 - 120
    if PointInRect(mx, my, screenWidth / 2 - 170, panelY + 150, 150, 52) then
        return "restart"
    end
    if PointInRect(mx, my, screenWidth / 2 + 20, panelY + 150, 150, 52) then
        return "menu"
    end
    return nil
end

return UI
