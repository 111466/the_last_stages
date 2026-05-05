
local Config = {}

Config.SCREEN_WIDTH = 1280
Config.SCREEN_HEIGHT = 720

Config.INITIAL_GOLD = 200
Config.INITIAL_LIVES = 20

Config.LEVELS = {
    {
        id = "greenfield",
        name = "草原前线",
        tag = "推荐入门",
        description = "资源充足、路线均衡，适合熟悉英雄与防御塔的基础配合。",
        initialGold = 220,
        initialLives = 20,
        heroSpawn = { x = 640, y = 360 },
        waves = {
            {
                prepTime = 10,
                groups = {
                    { type = "grunt", count = 6, interval = 1.2, route = "random" },
                },
            },
            {
                prepTime = 14,
                groups = {
                    { type = "grunt", count = 8, interval = 1.0, route = "random" },
                    { type = "runner", count = 4, interval = 1.5, route = "A" },
                },
            },
            {
                prepTime = 15,
                groups = {
                    { type = "grunt", count = 5, interval = 1.0, route = "A" },
                    { type = "runner", count = 5, interval = 1.0, route = "B" },
                    { type = "grunt", count = 5, interval = 1.0, route = "B" },
                },
            },
            {
                prepTime = 18,
                groups = {
                    { type = "grunt", count = 10, interval = 0.7, route = "random" },
                    { type = "brute", count = 2, interval = 4.0, route = "A" },
                    { type = "archer", count = 3, interval = 2.0, route = "B" },
                },
            },
            {
                prepTime = 20,
                groups = {
                    { type = "runner", count = 8, interval = 0.6, route = "random" },
                    { type = "brute", count = 3, interval = 3.0, route = "A" },
                    { type = "archer", count = 5, interval = 1.5, route = "B" },
                },
            },
            {
                prepTime = 22,
                groups = {
                    { type = "archer", count = 10, interval = 1.0, route = "random" },
                    { type = "grunt", count = 5, interval = 1.5, route = "A" },
                },
            },
            {
                prepTime = 25,
                groups = {
                    { type = "grunt", count = 15, interval = 0.5, route = "random" },
                    { type = "brute", count = 4, interval = 2.5, route = "random" },
                    { type = "runner", count = 6, interval = 0.8, route = "B" },
                },
            },
            {
                prepTime = 30,
                groups = {
                    { type = "boss", count = 1, interval = 0, route = "A" },
                    { type = "grunt", count = 10, interval = 0.6, route = "B" },
                    { type = "brute", count = 3, interval = 3.0, route = "A" },
                },
            },
        },
    },
    {
        id = "frost_pass",
        name = "霜谷关隘",
        tag = "中等强度",
        description = "初始资源偏少，快攻敌人与远程敌人混编，更考验前期布局。",
        initialGold = 180,
        initialLives = 16,
        heroSpawn = { x = 560, y = 320 },
        waves = {
            {
                prepTime = 8,
                groups = {
                    { type = "runner", count = 8, interval = 0.9, route = "random" },
                },
            },
            {
                prepTime = 12,
                groups = {
                    { type = "grunt", count = 8, interval = 0.9, route = "A" },
                    { type = "runner", count = 6, interval = 0.8, route = "B" },
                },
            },
            {
                prepTime = 14,
                groups = {
                    { type = "archer", count = 6, interval = 1.2, route = "random" },
                    { type = "runner", count = 6, interval = 0.75, route = "random" },
                },
            },
            {
                prepTime = 18,
                groups = {
                    { type = "brute", count = 3, interval = 3.2, route = "A" },
                    { type = "grunt", count = 12, interval = 0.6, route = "B" },
                },
            },
            {
                prepTime = 18,
                groups = {
                    { type = "archer", count = 8, interval = 1.1, route = "A" },
                    { type = "runner", count = 8, interval = 0.7, route = "B" },
                    { type = "grunt", count = 6, interval = 0.8, route = "random" },
                },
            },
            {
                prepTime = 22,
                groups = {
                    { type = "brute", count = 4, interval = 2.6, route = "random" },
                    { type = "archer", count = 8, interval = 1.0, route = "random" },
                },
            },
            {
                prepTime = 24,
                groups = {
                    { type = "runner", count = 12, interval = 0.55, route = "random" },
                    { type = "grunt", count = 12, interval = 0.55, route = "random" },
                },
            },
            {
                prepTime = 28,
                groups = {
                    { type = "boss", count = 1, interval = 0, route = "B" },
                    { type = "archer", count = 8, interval = 0.9, route = "A" },
                    { type = "brute", count = 4, interval = 2.8, route = "random" },
                },
            },
        },
    },
    {
        id = "ember_siege",
        name = "余烬围城",
        tag = "高压挑战",
        description = "高起始金币但波次凶猛，适合喜欢速建塔与爆发清场的打法。",
        initialGold = 300,
        initialLives = 12,
        heroSpawn = { x = 720, y = 420 },
        waves = {
            {
                prepTime = 8,
                groups = {
                    { type = "grunt", count = 10, interval = 0.75, route = "random" },
                    { type = "runner", count = 4, interval = 0.8, route = "B" },
                },
            },
            {
                prepTime = 10,
                groups = {
                    { type = "archer", count = 6, interval = 1.0, route = "A" },
                    { type = "runner", count = 8, interval = 0.65, route = "random" },
                },
            },
            {
                prepTime = 12,
                groups = {
                    { type = "brute", count = 3, interval = 2.5, route = "random" },
                    { type = "grunt", count = 12, interval = 0.55, route = "random" },
                },
            },
            {
                prepTime = 14,
                groups = {
                    { type = "archer", count = 10, interval = 0.9, route = "random" },
                    { type = "runner", count = 10, interval = 0.55, route = "random" },
                },
            },
            {
                prepTime = 16,
                groups = {
                    { type = "brute", count = 5, interval = 2.1, route = "A" },
                    { type = "grunt", count = 10, interval = 0.45, route = "B" },
                    { type = "runner", count = 8, interval = 0.5, route = "random" },
                },
            },
            {
                prepTime = 20,
                groups = {
                    { type = "archer", count = 12, interval = 0.85, route = "random" },
                    { type = "brute", count = 5, interval = 2.2, route = "random" },
                },
            },
            {
                prepTime = 22,
                groups = {
                    { type = "runner", count = 16, interval = 0.45, route = "random" },
                    { type = "grunt", count = 16, interval = 0.45, route = "random" },
                    { type = "archer", count = 6, interval = 0.9, route = "B" },
                },
            },
            {
                prepTime = 24,
                groups = {
                    { type = "boss", count = 1, interval = 0, route = "A" },
                    { type = "brute", count = 6, interval = 2.1, route = "random" },
                    { type = "archer", count = 10, interval = 0.8, route = "random" },
                },
            },
        },
    },
}

function Config.GetLevelById(levelId)
    for _, level in ipairs(Config.LEVELS) do
        if level.id == levelId then
            return level
        end
    end
    return Config.LEVELS[1]
end

return Config
