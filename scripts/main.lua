
Config = require("scripts.Config")
Utils = require("scripts.Utils")
Path = require("scripts.Path")
Particle = require("scripts.Particle")
Hero = require("scripts.Hero")
Skills = require("scripts.Skills")
Equipment = require("scripts.Equipment")
Enemy = require("scripts.Enemy")
Tower = require("scripts.Tower")
Projectile = require("scripts.Projectile")
WaveManager = require("scripts.WaveManager")
InputController = require("scripts.InputController")
UI = require("scripts.UI")

local gold_ = Config.INITIAL_GOLD
local lives_ = Config.INITIAL_LIVES
local nvg_ = nil
local gameState = {
    phase = "title",
    currentLevel = nil,
    isBattleFinished = false,
}

local function AddBattleRewards(reward, kills)
    if reward and reward > 0 then
        gold_ = gold_ + reward
    end
    if kills and kills > 0 then
        Hero.state.killCount = Hero.state.killCount + kills
    end
end

local function ResetBattleObjects()
    Tower.list = {}
    Tower.selected = nil
    Projectile.list = {}
    Particle.list = {}
    Enemy.list = {}
    InputController.Reset()
end

local function EnterTitle()
    gameState.phase = "title"
    gameState.currentLevel = nil
    gameState.isBattleFinished = false
    gold_ = Config.INITIAL_GOLD
    lives_ = Config.INITIAL_LIVES
    ResetBattleObjects()
end

local function EnterLevelSelect()
    gameState.phase = "level_select"
    gameState.isBattleFinished = false
    InputController.Reset()
end

local function StartLevel(levelId)
    local level = Config.GetLevelById(levelId)
    gameState.phase = "battle"
    gameState.currentLevel = level
    gameState.isBattleFinished = false

    gold_ = level.initialGold or Config.INITIAL_GOLD
    lives_ = level.initialLives or Config.INITIAL_LIVES

    ResetBattleObjects()
    Skills.Reset()
    Hero.Init(level)
    WaveManager.Init(level)
end

function Start()
    nvg_ = nvgCreate(1)
    if not nvg_ then
        print("[ERROR] Failed to create NanoVG context")
        return
    end

    -- 创建字体（必须在使用 nvgText 之前调用，且只调用一次）
    nvgCreateFont(nvg_, "sans", "Fonts/MiSans-Regular.ttf")

    gold_ = Config.INITIAL_GOLD
    lives_ = Config.INITIAL_LIVES
    Skills.Reset()
    Hero.Init(Config.LEVELS[1])
    WaveManager.Init(Config.LEVELS[1])
    EnterTitle()

    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent(nvg_, "NanoVGRender", "HandleNanoVGRender")
    print("[Game] Started!")
end

function HandleUpdate(eventType, eventData)
    local dt = eventData["TimeStep"]:GetFloat()
    local actions = InputController.HandleInput(dt, gameState)

    if actions.openLevelSelect then
        EnterLevelSelect()
        return
    end

    if actions.backToTitle then
        EnterTitle()
        return
    end

    if actions.selectLevel then
        StartLevel(actions.selectLevel)
        return
    end

    if actions.restartBattle and gameState.currentLevel then
        StartLevel(gameState.currentLevel.id)
        return
    end

    if actions.returnToMenu then
        EnterTitle()
        return
    end

    if gameState.phase ~= "battle" then
        return
    end

    if actions.placeTower then
        local newTower
        newTower, gold_ = Tower.Create(actions.placeTower, actions.placeX, actions.placeY, gold_)
        if newTower then
            print("[Tower] Placed " .. actions.placeTower .. " at " .. actions.placeX .. "," .. actions.placeY)
        end
    end

    if actions.upgradeSelectedTower and Tower.selected then
        local upgraded
        upgraded, gold_ = Tower.Upgrade(Tower.selected, gold_)
        if upgraded then
            print("[Tower] Upgraded selected tower to Lv" .. Tower.selected.level)
        end
    end

    if actions.upgradeSkill then
        local upgraded
        upgraded, gold_ = Skills.Upgrade(actions.upgradeSkill, gold_)
        if upgraded then
            print("[Skill] Upgraded slot " .. actions.upgradeSkill)
        end
    end

    if actions.buyEquipmentSlot then
        local purchased, newGold, itemId = Equipment.BuyNext(actions.buyEquipmentSlot, gold_)
        if purchased then
            gold_ = newGold
            print("[Equipment] Equipped " .. itemId)
        end
    end

    gameState.isBattleFinished = lives_ <= 0 or not Hero.state.alive or WaveManager.allComplete
    if lives_ <= 0 or not Hero.state.alive or WaveManager.allComplete then
        if lives_ < 0 then lives_ = 0 end
        Skills.Update(dt)
        Particle.UpdateAll(dt)
        return
    end

    Hero.state.vx = InputController.state.moveX
    Hero.state.vy = InputController.state.moveY
    Hero.Update(dt)

    if InputController.state.attacking then
        local reward, kills = Hero.Attack(Enemy.list)
        AddBattleRewards(reward, kills)
    end

    if actions.castSkill then
        local casted, reward, kills = Skills.Cast(
            actions.castSkill, actions.castX, actions.castY, Enemy.list, Tower.list)
        if casted then
            AddBattleRewards(reward, kills)
        end
    end

    Skills.Update(dt)

    for i = #Enemy.list, 1, -1 do
        local enemy = Enemy.list[i]
        if enemy.alive then
            local result = Enemy.Update(enemy, dt, Hero.state)
            if result then
                if result == -1 then
                    lives_ = lives_ - 1
                    print("[Enemy] Reached end! Lives: " .. lives_)
                    enemy.alive = false
                else
                    AddBattleRewards(result, 1)
                end
            end
        end
        if not enemy.alive then
            table.remove(Enemy.list, i)
        end
    end

    local towerReward, towerKills = Tower.UpdateAll(dt)
    AddBattleRewards(towerReward, towerKills)

    local projectileReward, projectileKills = Projectile.UpdateAll(dt)
    AddBattleRewards(projectileReward, projectileKills)

    gold_ = WaveManager.Update(dt, gold_)
    Particle.UpdateAll(dt)

    if lives_ <= 0 then
        lives_ = 0
    end
    gameState.isBattleFinished = lives_ <= 0 or not Hero.state.alive or WaveManager.allComplete
end

function HandleNanoVGRender(eventType, eventData)
    if not nvg_ then return end

    local dpr = graphics:GetDPR()
    local screenWidth = graphics:GetWidth() / dpr
    local screenHeight = graphics:GetHeight() / dpr

    nvgBeginFrame(nvg_, screenWidth, screenHeight, dpr)

    -- 设置默认字体
    nvgFontFace(nvg_, "sans")

    nvgBeginPath(nvg_)
    nvgRect(nvg_, 0, 0, screenWidth, screenHeight)
    nvgFillColor(nvg_, nvgRGBA(30, 40, 30, 255))
    nvgFill(nvg_)

    if gameState.phase == "battle" then
        Path.Draw(nvg_)
        Tower.DrawAll(nvg_)
        Enemy.DrawAll(nvg_)
        Hero.Draw(nvg_)
        Projectile.DrawAll(nvg_)
        Particle.DrawAll(nvg_)
    end

    UI.Render(nvg_, {
        phase = gameState.phase,
        gold = gold_,
        lives = lives_,
        wave = WaveManager.currentWave,
        heroState = Hero.state,
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        levels = Config.LEVELS,
        currentLevel = gameState.currentLevel,
        totalWaves = #WaveManager.waves,
    })

    nvgEndFrame(nvg_)
end

function Stop()
    if nvg_ then
        nvgDelete(nvg_)
        nvg_ = nil
    end
    print("[Game] Stopped!")
end
