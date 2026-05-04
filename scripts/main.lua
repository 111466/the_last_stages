-- ============================================================================
-- 2D 俯视角游戏框架 (Top-Down 2D Game Framework)
-- 基于 scaffold-2d.lua 脚手架
-- 功能: 玩家 WASD/方向键移动、HUD 显示、调试面板
-- ============================================================================

local UI = require("urhox-libs/UI")

-- ============================================================================
-- 1. 全局变量
-- ============================================================================
local uiRoot_ = nil
local debugDraw_ = false

-- 游戏配置
local CONFIG = {
    Title = "Top-Down 2D Game",
    -- 地图
    MapWidth = 800,
    MapHeight = 600,
    TileSize = 32,
    BackgroundColor = { 30, 40, 35, 255 },
    GridColor = { 50, 65, 55, 80 },
    -- 玩家
    PlayerSize = 20,
    PlayerSpeed = 180,   -- 像素/秒
    PlayerColor = { 80, 200, 120, 255 },
    PlayerOutline = { 40, 160, 80, 255 },
    -- 方向指示器
    DirectionLen = 14,
    DirectionColor = { 255, 255, 255, 200 },
}

-- 游戏状态
local gameState = {
    score = 0,
    time = 0,
}

-- 玩家状态
local player = {
    x = 400,
    y = 300,
    angle = 0,       -- 朝向角度（弧度）
    speed = CONFIG.PlayerSpeed,
}

-- NanoVG 上下文（独立创建，用于绘制游戏世界）
---@type integer
local vg_ = nil

-- ============================================================================
-- 2. 生命周期
-- ============================================================================

function Start()
    graphics.windowTitle = CONFIG.Title

    -- 1. 创建独立 NanoVG 上下文用于绘制游戏世界
    vg_ = nvgCreate(1)
    if vg_ == nil then
        print("ERROR: Failed to create NanoVG context")
        return
    end
    print("NanoVG context created successfully")

    -- 2. 初始化 UI 系统（HUD 等）
    InitUI()
    CreateGameContent()
    CreateUI()
    SubscribeToEvents()

    print("=== Game Started: " .. CONFIG.Title .. " ===")
    print("Controls: WASD / Arrow Keys to move")
    print("Press Z to toggle debug panel")
end

function Stop()
    -- 清理 NanoVG 上下文
    if vg_ ~= nil then
        nvgDelete(vg_)
        vg_ = nil
    end
    UI.Shutdown()
end

-- ============================================================================
-- 3. 初始化
-- ============================================================================

function InitUI()
    UI.Init({
        fonts = {
            { family = "sans", weights = {
                normal = "Fonts/MiSans-Regular.ttf",
            } }
        },
        scale = UI.Scale.DEFAULT,
    })
end

function SubscribeToEvents()
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("KeyDown", "HandleKeyDown")
    -- ⚠️ NanoVGRender 必须绑定到具体的 nvg 上下文对象
    SubscribeToEvent(vg_, "NanoVGRender", "HandleNanoVGRender")
end

-- ============================================================================
-- 4. 游戏内容初始化
-- ============================================================================

function CreateGameContent()
    -- 玩家初始位置：地图中心
    player.x = CONFIG.MapWidth / 2
    player.y = CONFIG.MapHeight / 2
    player.angle = -math.pi / 2  -- 初始朝上

    print("Player spawned at (" .. player.x .. ", " .. player.y .. ")")
end

-- ============================================================================
-- 5. UI 构建
-- ============================================================================

function CreateUI()
    uiRoot_ = UI.Panel {
        id = "gameUI",
        width = "100%",
        height = "100%",
        pointerEvents = "box-none",
        children = {
            -- 左上角 HUD
            CreateHUDPanel(),
            -- 操作提示（底部）
            UI.Label {
                id = "instructionLabel",
                text = "WASD / Arrow Keys: Move  |  Z: Debug",
                fontSize = 12,
                fontColor = { 255, 255, 255, 150 },
                position = "absolute",
                bottom = 16,
                left = 0,
                right = 0,
                textAlign = "center",
            },
            -- 调试面板（默认隐藏）
            CreateDebugPanel(),
        }
    }
    UI.SetRoot(uiRoot_)
end

--- HUD 面板：分数 + 时间
function CreateHUDPanel()
    return UI.Panel {
        id = "hud",
        position = "absolute",
        top = 16,
        left = 16,
        padding = 12,
        gap = 6,
        backgroundColor = { 0, 0, 0, 160 },
        borderRadius = 8,
        pointerEvents = "none",
        children = {
            UI.Label {
                id = "scoreLabel",
                text = "Score: 0",
                fontSize = 16,
                fontColor = { 255, 255, 255, 255 },
            },
            UI.Label {
                id = "timeLabel",
                text = "Time: 0s",
                fontSize = 14,
                fontColor = { 200, 200, 200, 220 },
            },
        }
    }
end

--- 调试面板
function CreateDebugPanel()
    return UI.Panel {
        id = "debugPanel",
        visible = false,
        position = "absolute",
        top = 16,
        right = 16,
        padding = 10,
        gap = 4,
        backgroundColor = { 0, 0, 0, 180 },
        borderRadius = 6,
        pointerEvents = "none",
        children = {
            UI.Label {
                id = "debugPosLabel",
                text = "Pos: 0, 0",
                fontSize = 12,
                fontColor = { 150, 255, 150, 255 },
            },
            UI.Label {
                id = "debugAngleLabel",
                text = "Angle: 0",
                fontSize = 12,
                fontColor = { 150, 255, 150, 255 },
            },
            UI.Label {
                id = "debugFPSLabel",
                text = "FPS: 0",
                fontSize = 12,
                fontColor = { 150, 255, 150, 255 },
            },
        }
    }
end

-- ============================================================================
-- 6. 游戏逻辑更新
-- ============================================================================

---@param eventType string
---@param eventData UpdateEventData
function HandleUpdate(eventType, eventData)
    local dt = eventData["TimeStep"]:GetFloat()

    -- 更新游戏时间
    gameState.time = gameState.time + dt

    -- 处理玩家移动
    UpdatePlayerMovement(dt)

    -- 更新 HUD
    UpdateHUD()

    -- 更新调试信息
    if debugDraw_ then
        UpdateDebugInfo()
    end
end

--- 玩家移动（WASD / 方向键）
function UpdatePlayerMovement(dt)
    local dx, dy = 0, 0

    if input:GetKeyDown(KEY_W) or input:GetKeyDown(KEY_UP) then
        dy = -1
    end
    if input:GetKeyDown(KEY_S) or input:GetKeyDown(KEY_DOWN) then
        dy = 1
    end
    if input:GetKeyDown(KEY_A) or input:GetKeyDown(KEY_LEFT) then
        dx = -1
    end
    if input:GetKeyDown(KEY_D) or input:GetKeyDown(KEY_RIGHT) then
        dx = 1
    end

    -- 对角线移动归一化
    if dx ~= 0 and dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        dx = dx / len
        dy = dy / len
    end

    -- 更新位置
    if dx ~= 0 or dy ~= 0 then
        player.x = player.x + dx * player.speed * dt
        player.y = player.y + dy * player.speed * dt
        -- 更新朝向
        player.angle = math.atan(dy, dx)
    end

    -- 边界限制
    local half = CONFIG.PlayerSize / 2
    player.x = math.max(half, math.min(CONFIG.MapWidth - half, player.x))
    player.y = math.max(half, math.min(CONFIG.MapHeight - half, player.y))
end

--- 更新 HUD 显示
function UpdateHUD()
    local scoreLabel = uiRoot_:FindById("scoreLabel")
    if scoreLabel then
        scoreLabel:SetText("Score: " .. gameState.score)
    end
    local timeLabel = uiRoot_:FindById("timeLabel")
    if timeLabel then
        timeLabel:SetText("Time: " .. math.floor(gameState.time) .. "s")
    end
end

--- 更新调试信息
function UpdateDebugInfo()
    local posLabel = uiRoot_:FindById("debugPosLabel")
    if posLabel then
        posLabel:SetText(string.format("Pos: %.0f, %.0f", player.x, player.y))
    end
    local angleLabel = uiRoot_:FindById("debugAngleLabel")
    if angleLabel then
        angleLabel:SetText(string.format("Angle: %.1f°", math.deg(player.angle)))
    end
    local fpsLabel = uiRoot_:FindById("debugFPSLabel")
    if fpsLabel then
        fpsLabel:SetText("FPS: " .. math.floor(1.0 / time.timeStep + 0.5))
    end
end

-- ============================================================================
-- 7. NanoVG 渲染（游戏世界绘制）
-- ============================================================================

---@param eventType string
---@param eventData table
function HandleNanoVGRender(eventType, eventData)
    if vg_ == nil then return end

    local gfx = GetGraphics()
    local w = gfx:GetWidth()
    local h = gfx:GetHeight()

    nvgBeginFrame(vg_, w, h, 1.0)

    -- 计算地图在屏幕上的偏移（居中显示）
    local offsetX = (w - CONFIG.MapWidth) / 2
    local offsetY = (h - CONFIG.MapHeight) / 2

    -- 绘制背景
    DrawBackground(offsetX, offsetY)

    -- 绘制网格
    DrawGrid(offsetX, offsetY)

    -- 绘制玩家
    DrawPlayer(offsetX, offsetY)

    nvgEndFrame(vg_)
end

--- 绘制地图背景
function DrawBackground(ox, oy)
    nvgBeginPath(vg_)
    nvgRect(vg_, ox, oy, CONFIG.MapWidth, CONFIG.MapHeight)
    nvgFillColor(vg_, nvgRGBA(
        CONFIG.BackgroundColor[1], CONFIG.BackgroundColor[2],
        CONFIG.BackgroundColor[3], CONFIG.BackgroundColor[4]))
    nvgFill(vg_)

    -- 边框
    nvgStrokeColor(vg_, nvgRGBA(80, 100, 90, 120))
    nvgStrokeWidth(vg_, 2)
    nvgStroke(vg_)
end

--- 绘制网格
function DrawGrid(ox, oy)
    local ts = CONFIG.TileSize
    nvgBeginPath(vg_)
    nvgStrokeColor(vg_, nvgRGBA(
        CONFIG.GridColor[1], CONFIG.GridColor[2],
        CONFIG.GridColor[3], CONFIG.GridColor[4]))
    nvgStrokeWidth(vg_, 1)

    -- 垂直线
    for x = ts, CONFIG.MapWidth - 1, ts do
        nvgMoveTo(vg_, ox + x, oy)
        nvgLineTo(vg_, ox + x, oy + CONFIG.MapHeight)
    end
    -- 水平线
    for y = ts, CONFIG.MapHeight - 1, ts do
        nvgMoveTo(vg_, ox, oy + y)
        nvgLineTo(vg_, ox + CONFIG.MapWidth, oy + y)
    end
    nvgStroke(vg_)
end

--- 绘制玩家（圆形 + 方向指示器）
function DrawPlayer(ox, oy)
    local px = ox + player.x
    local py = oy + player.y
    local r = CONFIG.PlayerSize / 2

    -- 玩家圆形
    nvgBeginPath(vg_)
    nvgCircle(vg_, px, py, r)
    nvgFillColor(vg_, nvgRGBA(
        CONFIG.PlayerColor[1], CONFIG.PlayerColor[2],
        CONFIG.PlayerColor[3], CONFIG.PlayerColor[4]))
    nvgFill(vg_)
    nvgStrokeColor(vg_, nvgRGBA(
        CONFIG.PlayerOutline[1], CONFIG.PlayerOutline[2],
        CONFIG.PlayerOutline[3], CONFIG.PlayerOutline[4]))
    nvgStrokeWidth(vg_, 2)
    nvgStroke(vg_)

    -- 方向指示线
    local dirX = math.cos(player.angle) * CONFIG.DirectionLen
    local dirY = math.sin(player.angle) * CONFIG.DirectionLen
    nvgBeginPath(vg_)
    nvgMoveTo(vg_, px, py)
    nvgLineTo(vg_, px + dirX, py + dirY)
    nvgStrokeColor(vg_, nvgRGBA(
        CONFIG.DirectionColor[1], CONFIG.DirectionColor[2],
        CONFIG.DirectionColor[3], CONFIG.DirectionColor[4]))
    nvgStrokeWidth(vg_, 2.5)
    nvgLineCap(vg_, NVG_ROUND)
    nvgStroke(vg_)
end

-- ============================================================================
-- 8. 按键处理
-- ============================================================================

---@param eventType string
---@param eventData KeyDownEventData
function HandleKeyDown(eventType, eventData)
    local key = eventData["Key"]:GetInt()

    if key == KEY_Z then
        debugDraw_ = not debugDraw_
        local debugPanel = uiRoot_:FindById("debugPanel")
        if debugPanel then
            debugPanel:SetVisible(debugDraw_)
        end
        print("Debug: " .. (debugDraw_ and "ON" or "OFF"))
    end
end
