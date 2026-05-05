# Tiny Swords 动作 RPG + 塔防混合游戏开发指南

**UrhoX 2D + Lua + NanoVG | 英雄操控 + 塔防建造 | 完整版**

基于 Pixel Frog 素材包的《Orcs Must Die!》像素版完整实现方案

2026 年 5 月

---

## 目录

- [一、游戏核心机制拆解](#一游戏核心机制拆解)
- [二、游戏流程总览](#二游戏流程总览)
- [三、项目结构设计](#三项目结构设计)
- [四、核心代码实现](#四核心代码实现)
  - [4.1 英雄系统 Hero.lua](#41-英雄系统-herolua)
  - [4.2 英雄技能系统 Skills.lua](#42-英雄技能系统-skillslua)
  - [4.3 装备系统 Equipment.lua](#43-装备系统-equipmentlua)
  - [4.4 路径系统 Path.lua](#44-路径系统-pathlua)
  - [4.5 敌人系统 Enemy.lua](#45-敌人系统-enemylua)
  - [4.6 防御塔系统 Tower.lua](#46-防御塔系统-towerlua)
  - [4.7 子弹与特效 Projectile.lua](#47-子弹与特效-projectilelua)
  - [4.8 波次管理器 WaveManager.lua](#48-波次管理器-wavemanagerlua)
  - [4.9 输入控制 InputController.lua](#49-输入控制-inputcontrollerlua)
  - [4.10 UI 渲染 UI.lua](#410-ui-渲染-uilua)
  - [4.11 入口文件 Main.lua](#411-入口文件-mainlua)
- [五、Tiny Swords 素材映射方案](#五tiny-swords-素材映射方案)
- [六、数值平衡设计](#六数值平衡设计)
- [七、关卡设计模板](#七关卡设计模板)
- [八、开发路线图（分 6 个阶段）](#八开发路线图分-6-个阶段)
- [九、UrhoX 开发注意事项](#九urhox-开发注意事项)

---

## 一、游戏核心机制拆解

动作 RPG + 塔防混合游戏由以下 **9 个核心系统** 组成：

| 系统 | 作用 | UrhoX 实现方式 |
|------|------|---------------|
| **英雄系统** | 玩家直接控制的角色，移动/攻击/施法 | 输入驱动 + 碰撞检测 |
| **技能系统** | 英雄主动/被动技能，可升级 | 冷却计时器 + 效果系统 |
| **装备系统** | 武器/护甲/饰品，提升英雄属性 | 背包 + 属性叠加 |
| **路径系统** | 敌人行进路线（可多条） | 路径点数组 + 分支 |
| **敌人系统** | 沿路径行进，有血量/速度/技能 | AI 状态机 |
| **防御塔系统** | 放置在路径旁，自动攻击 | 范围检测 + 自动射击 |
| **子弹与特效** | 投射物、爆炸、粒子效果 | 运动学 + NanoVG 粒子 |
| **波次管理** | 多波敌人浪潮，逐步加难 | 配置表 + 生成队列 |
| **经济系统** | 击杀金币 → 建塔/买装备 | 金币流转 |

### 与纯塔防 / 纯 RPG 的区别

| 维度 | 纯塔防 | 纯 ARPG | **ARPG + 塔防混合** |
|------|--------|---------|-------------------|
| 玩家角色 | 无 / 上帝视角 | 主角全程战斗 | **英雄 + 塔协同防守** |
| 操作方式 | 点击放塔 | WASD + 技能键 | **WASD 移动 + 点击放塔 + 技能键** |
| 策略深度 | 塔的位置和类型 | 装备和技能搭配 | **英雄站位 + 塔布局 + 技能时机** |
| 失败条件 | 敌人到达终点 | 角色死亡 | **英雄死亡 或 敌人到达终点** |
| 核心乐趣 | 阵地规划 | 操作爽感 | **操作 + 策略的双重满足** |

---

## 二、游戏流程总览

```
┌──────────────────────────────────────────────────────────────┐
│                      一局游戏流程                             │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐ │
│  │ 关卡选择  │→ │ 准备阶段  │→ │ 战斗阶段  │→ │ 结算阶段  │ │
│  │          │   │ (15秒)   │   │ (核心)   │   │          │ │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘ │
│       ↑                                        │            │
│       └────────────────────────────────────────┘            │
│                                                              │
│  准备阶段：                                                  │
│  • 查看关卡信息（路径、敌人类型、波数）                         │
│  • 选择/升级英雄技能                                         │
│  • 购买/装备物品                                             │
│  • 预放置防御塔                                              │
│                                                              │
│  战斗阶段（核心玩法）：                                        │
│  • WASD 控制英雄移动                                         │
│  • 鼠标左键攻击 / 右键放塔                                    │
│  • 1-4 键释放技能                                            │
│  • 敌人沿路径行进，英雄和塔协同消灭                            │
│  • 波次间短暂间歇（可放塔/升级）                               │
│                                                              │
│  结算阶段：                                                  │
│  • 统计击杀数、存活时间、金币获取                              │
│  • 评级（S/A/B/C）                                           │
│  • 解锁新关卡 / 获得装备奖励                                  │
│                                                              │
│  失败条件：                                                  │
│  • 英雄生命值归零                                             │
│  • 累计 N 个敌人到达终点（通常 N = 关卡生命值）                │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 三、项目结构设计

```
action-tower-defense/
├── game.json
├── README.md
├── preview/
│   └── icon.png
├── assets/
│   ├── units/             # Tiny Swords 4种单位（英雄用）
│   ├── enemies/           # Tiny Swords 敌人精灵图
│   ├── buildings/         # 防御塔和建筑
│   ├── terrain/           # 地形瓦片（路径、草地、水）
│   ├── effects/           # 粒子特效（火焰、爆炸、灰尘）
│   └── ui/                # UI 元素（血条、按钮、图标）
└── scripts/
    ├── Main.lua           # 入口文件
    ├── Config.lua         # 全局配置
    ├── Hero.lua           # 英雄系统
    ├── Skills.lua         # 技能系统
    ├── Equipment.lua      # 装备系统
    ├── Path.lua           # 路径系统
    ├── Enemy.lua          # 敌人系统
    ├── Tower.lua          # 防御塔系统
    ├── Projectile.lua     # 子弹与特效
    ├── WaveManager.lua    # 波次管理
    ├── Economy.lua        # 经济系统
    ├── InputController.lua# 输入控制
    ├── Camera.lua         # 摄像机跟随
    ├── Particle.lua       # 粒子效果
    ├── UI.lua             # UI 渲染
    └── Utils.lua          # 工具函数
```

---

## 四、核心代码实现

### 4.1 英雄系统 Hero.lua

英雄是玩家直接控制的角色，拥有移动、攻击、血量、法力等属性。

```lua
local Hero = {}

-- ===== 英雄配置 =====
Hero.config = {
    -- 使用 Tiny Swords Warrior 作为英雄基础
    moveSpeed = 200,          -- 像素/秒
    baseHP = 500,
    baseATK = 40,
    baseDEF = 15,
    attackRange = 60,         -- 近战范围
    attackSpeed = 1.5,        -- 每秒攻击次数
    attackCooldown = 0,
    maxMana = 100,
    manaRegen = 5,            -- 每秒法力回复
    invincibleTime = 0.5,     -- 受伤无敌帧（秒）
    size = 28,
}

-- ===== 英雄状态 =====
Hero.state = {
    x = 400,
    y = 400,
    vx = 0, vy = 0,          -- 速度分量
    hp = Hero.config.baseHP,
    maxHP = Hero.config.baseHP,
    mana = 0,
    alive = true,
    facing = 1,               -- 1=右, -1=左
    animState = "idle",       -- idle/run/attack/skill/hit/die
    animTimer = 0,
    invincibleTimer = 0,
    -- 装备加成
    bonusATK = 0,
    bonusDEF = 0,
    bonusHP = 0,
    bonusSpeed = 0,
    -- 统计
    killCount = 0,
    totalDamage = 0,
    -- 技能
    skills = {},
    skillSlots = { nil, nil, nil, nil },  -- 4 个技能槽
}

-- ===== 初始化英雄 =====
function Hero.Init()
    local s = Hero.state
    s.hp = s.maxHP
    s.mana = 0
    s.alive = true
    s.killCount = 0
    s.totalDamage = 0
    s.invincibleTimer = 0
    s.vx = 0
    s.vy = 0
    s.animState = "idle"
end

-- ===== 更新英雄 =====
function Hero.Update(dt)
    local s = Hero.state
    if not s.alive then return end

    -- 无敌帧
    if s.invincibleTimer > 0 then
        s.invincibleTimer = s.invincibleTimer - dt
    end

    -- 法力回复
    s.mana = math.min(Hero.config.maxMana, s.mana + Hero.config.manaRegen * dt)

    -- 攻击冷却
    s.attackCooldown = s.attackCooldown - dt

    -- 动画计时器
    s.animTimer = s.animTimer - dt
    if s.animTimer <= 0 and s.animState ~= "idle" and s.animState ~= "run" then
        s.animState = "idle"
    end

    -- 移动
    local speed = Hero.config.moveSpeed + s.bonusSpeed
    s.x = s.x + s.vx * speed * dt
    s.y = s.y + s.vy * speed * dt

    -- 边界限制
    s.x = math.max(20, math.min(s.x, 1400))
    s.y = math.max(20, math.min(s.y, 800))

    -- 移动动画
    if math.abs(s.vx) > 0.01 or math.abs(s.vy) > 0.01 then
        s.animState = "run"
        if s.vx > 0.1 then s.facing = 1
        elseif s.vx < -0.1 then s.facing = -1
        end
    elseif s.animState == "run" then
        s.animState = "idle"
    end
end

-- ===== 英雄攻击 =====
function Hero.Attack(enemies)
    local s = Hero.state
    if s.attackCooldown > 0 then return end

    local totalATK = Hero.config.baseATK + s.bonusATK

    -- 找最近敌人
    local closest = nil
    local closestDist = Hero.config.attackRange
    for _, enemy in ipairs(enemies) do
        if enemy.alive then
            local dx = enemy.x - s.x
            local dy = enemy.y - s.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < closestDist then
                closestDist = dist
                closest = enemy
            end
        end
    end

    if closest then
        Enemy.Damage(closest, totalATK)
        s.attackCooldown = 1.0 / Hero.config.attackSpeed
        s.animState = "attack"
        s.animTimer = 0.25
        s.totalDamage = s.totalDamage + totalATK

        -- 攻击方向
        if closest.x > s.x then s.facing = 1
        else s.facing = -1 end

        -- 攻击特效
        Particle.Spawn("slash", closest.x, closest.y, s.facing)
    end
end

-- ===== 英雄受伤 =====
function Hero.TakeDamage(amount)
    local s = Hero.state
    if not s.alive or s.invincibleTimer > 0 then return end

    local totalDEF = Hero.config.baseDEF + s.bonusDEF
    local reduction = totalDEF / (totalDEF + 80)
    local damage = math.floor(amount * (1 - reduction))

    s.hp = s.hp - damage
    s.invincibleTimer = Hero.config.invincibleTime
    s.animState = "hit"
    s.animTimer = 0.2

    Particle.Spawn("hit", s.x, s.y - 10, 0)

    if s.hp <= 0 then
        s.hp = 0
        s.alive = false
        s.animState = "die"
        s.animTimer = 1.0
        Particle.Spawn("death", s.x, s.y, 0)
    end
end

-- ===== 英雄治疗 =====
function Hero.Heal(amount)
    local s = Hero.state
    if not s.alive then return end
    s.hp = math.min(s.maxHP + s.bonusHP, s.hp + amount)
end

-- ===== 重新计算属性（装备变更后调用）=====
function Hero.RecalcStats()
    local s = Hero.state
    s.maxHP = Hero.config.baseHP + s.bonusHP
    -- 不回满血，只更新上限
    s.bonusATK = 0
    s.bonusDEF = 0
    s.bonusHP = 0
    s.bonusSpeed = 0
    for _, itemId in ipairs(s.equipment or {}) do
        local item = Equipment.items[itemId]
        if item and item.stats then
            if item.stats.atk then s.bonusATK = s.bonusATK + item.stats.atk end
            if item.stats.def then s.bonusDEF = s.bonusDEF + item.stats.def end
            if item.stats.hp then s.bonusHP = s.bonusHP + item.stats.hp end
            if item.stats.speed then s.bonusSpeed = s.bonusSpeed + item.stats.speed end
        end
    end
    s.maxHP = Hero.config.baseHP + s.bonusHP
end

return Hero
```

---

### 4.2 英雄技能系统 Skills.lua

英雄拥有 4 个技能槽，技能可升级，消耗法力释放。

```lua
local Skills = {}

-- ===== 技能定义 =====
Skills.definitions = {
    -- 技能1：旋风斩（近战 AOE）
    whirlwind = {
        name = "旋风斩",
        icon = "ui/skill_whirlwind",
        manaCost = 30,
        cooldown = 6.0,
        maxLevel = 5,
        range = 80,
        desc = "对周围敌人造成伤害",
        levelDesc = {
            "80% 攻击力伤害",
            "100% 攻击力伤害",
            "120% 攻击力伤害",
            "150% 攻击力伤害 + 击退",
            "200% 攻击力伤害 + 击退",
        },
        damageMultiplier = { 0.8, 1.0, 1.2, 1.5, 2.0 },
        knockback = { 0, 0, 0, 30, 50 },
    },

    -- 技能2：冲锋
    charge = {
        name = "冲锋",
        icon = "ui/skill_charge",
        manaCost = 25,
        cooldown = 8.0,
        maxLevel = 5,
        range = 200,
        desc = "向前冲刺，撞击敌人",
        levelDesc = {
            "150% 伤害，冲刺 120px",
            "175% 伤害，冲刺 140px",
            "200% 伤害，冲刺 160px",
            "225% 伤害，冲刺 180px",
            "300% 伤害，冲刺 200px + 眩晕",
        },
        damageMultiplier = { 1.5, 1.75, 2.0, 2.25, 3.0 },
        chargeDist = { 120, 140, 160, 180, 200 },
        stunDuration = { 0, 0, 0, 0, 1.0 },
    },

    -- 技能3：战吼（Buff）
    war_cry = {
        name = "战吼",
        icon = "ui/skill_warcry",
        manaCost = 40,
        cooldown = 15.0,
        maxLevel = 5,
        range = 0,
        desc = "提升自身和附近防御塔属性",
        levelDesc = {
            "攻击+20%，持续5秒",
            "攻击+25%，持续6秒",
            "攻击+30%，持续7秒",
            "攻击+35%，防御+20%，持续8秒",
            "攻击+50%，防御+30%，持续10秒",
        },
        atkBonus = { 0.20, 0.25, 0.30, 0.35, 0.50 },
        defBonus = { 0, 0, 0, 0.20, 0.30 },
        duration = { 5, 6, 7, 8, 10 },
    },

    -- 技能4：陨石（远程 AOE）
    meteor = {
        name = "陨石",
        icon = "ui/skill_meteor",
        manaCost = 60,
        cooldown = 20.0,
        maxLevel = 5,
        range = 150,
        desc = "在目标区域召唤陨石",
        levelDesc = {
            "200% 伤害，范围 60px",
            "250% 伤害，范围 70px",
            "300% 伤害，范围 80px",
            "400% 伤害，范围 90px",
            "500% 伤害，范围 100px + 灼烧",
        },
        damageMultiplier = { 2.0, 2.5, 3.0, 4.0, 5.0 },
        aoeRadius = { 60, 70, 80, 90, 100 },
        burn = { false, false, false, false, true },
    },
}

-- ===== 技能状态管理 =====
Skills.slots = {
    { id = "whirlwind", level = 1, cooldownTimer = 0 },
    { id = "charge", level = 1, cooldownTimer = 0 },
    { id = "war_cry", level = 0, cooldownTimer = 0 },  -- 0 = 未解锁
    { id = "meteor", level = 0, cooldownTimer = 0 },
}

-- ===== 更新冷却 =====
function Skills.Update(dt)
    for i, slot in ipairs(Skills.slots) do
        if slot.level > 0 and slot.cooldownTimer > 0 then
            slot.cooldownTimer = slot.cooldownTimer - dt
        end
    end
end

-- ===== 释放技能 =====
function Skills.Cast(slotIndex, targetX, targetY, enemies, towers)
    local slot = Skills.slots[slotIndex]
    if not slot or slot.level <= 0 then return false end
    if slot.cooldownTimer > 0 then return false end

    local def = Skills.definitions[slot.id]
    if Hero.state.mana < def.manaCost then return false end

    -- 消耗法力
    Hero.state.mana = Hero.state.mana - def.manaCost
    slot.cooldownTimer = def.cooldown

    local level = slot.level
    local heroATK = Hero.config.baseATK + Hero.state.bonusATK

    -- 执行技能效果
    if slot.id == "whirlwind" then
        Skills.Whirlwind(heroATK, def, level, enemies)

    elseif slot.id == "charge" then
        Skills.Charge(heroATK, def, level, enemies)

    elseif slot.id == "war_cry" then
        Skills.WarCry(def, level, towers)

    elseif slot.id == "meteor" then
        Skills.Meteor(heroATK, def, level, targetX, targetY, enemies)
    end

    return true
end

-- ===== 旋风斩实现 =====
function Skills.Whirlwind(heroATK, def, level, enemies)
    local mult = def.damageMultiplier[level]
    local damage = math.floor(heroATK * mult)
    local range = def.range
    local knockback = def.knockback[level]

    for _, enemy in ipairs(enemies) do
        if enemy.alive then
            local dx = enemy.x - Hero.state.x
            local dy = enemy.y - Hero.state.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < range then
                Enemy.Damage(enemy, damage)
                Hero.state.totalDamage = Hero.state.totalDamage + damage
                -- 击退
                if knockback > 0 and dist > 0 then
                    enemy.x = enemy.x + (dx / dist) * knockback
                    enemy.y = enemy.y + (dy / dist) * knockback
                end
            end
        end
    end

    Particle.Spawn("whirlwind", Hero.state.x, Hero.state.y, Hero.state.facing)
    Hero.state.animState = "skill"
    Hero.state.animTimer = 0.5
end

-- ===== 冲锋实现 =====
function Skills.Charge(heroATK, def, level, enemies)
    local mult = def.damageMultiplier[level]
    local damage = math.floor(heroATK * mult)
    local dist = def.chargeDist[level]
    local stun = def.stunDuration[level]

    -- 沿朝向冲刺
    local startX = Hero.state.x
    Hero.state.x = Hero.state.x + Hero.state.facing * dist

    -- 冲刺路径上的敌人受伤
    for _, enemy in ipairs(enemies) do
        if enemy.alive then
            local minX = math.min(startX, Hero.state.x) - 30
            local maxX = math.max(startX, Hero.state.x) + 30
            if enemy.x >= minX and enemy.x <= maxX
                and math.abs(enemy.y - Hero.state.y) < 40 then
                Enemy.Damage(enemy, damage)
                Hero.state.totalDamage = Hero.state.totalDamage + damage
                if stun > 0 then
                    enemy.stunTimer = stun
                end
            end
        end
    end

    Particle.Spawn("charge", startX, Hero.state.y, Hero.state.facing)
    Hero.state.animState = "skill"
    Hero.state.animTimer = 0.4
end

-- ===== 战吼实现 =====
function Skills.WarCry(def, level, towers)
    local atkBonus = def.atkBonus[level]
    local defBonus = def.defBonus[level]
    local duration = def.duration[level]

    -- Buff 英雄自身
    Hero.state._warCryATK = atkBonus
    Hero.state._warCryDEF = defBonus
    Hero.state._warCryTimer = duration

    -- Buff 附近防御塔
    for _, tower in ipairs(towers) do
        tower._warCryATK = atkBonus
        tower._warCryTimer = duration
    end

    Particle.Spawn("buff", Hero.state.x, Hero.state.y, 0)
    Hero.state.animState = "skill"
    Hero.state.animTimer = 0.6
end

-- ===== 陨石实现 =====
function Skills.Meteor(heroATK, def, level, targetX, targetY, enemies)
    local mult = def.damageMultiplier[level]
    local damage = math.floor(heroATK * mult)
    local radius = def.aoeRadius[level]
    local burn = def.burn[level]

    for _, enemy in ipairs(enemies) do
        if enemy.alive then
            local dx = enemy.x - targetX
            local dy = enemy.y - targetY
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < radius then
                Enemy.Damage(enemy, damage)
                Hero.state.totalDamage = Hero.state.totalDamage + damage
                if burn then
                    enemy.burnTimer = 3.0
                    enemy.burnDamage = math.floor(heroATK * 0.3)
                end
            end
        end
    end

    Particle.Spawn("meteor", targetX, targetY, 0)
end

-- ===== 升级技能 =====
function Skills.Upgrade(slotIndex)
    local slot = Skills.slots[slotIndex]
    if not slot then return false end
    local def = Skills.definitions[slot.id]
    if slot.level >= def.maxLevel then return false end
    local cost = 50 + slot.level * 30  -- 升级费用递增
    if gold_ < cost then return false end
    gold_ = gold_ - cost
    slot.level = slot.level + 1
    return true
end

return Skills
```

---

### 4.3 装备系统 Equipment.lua

```lua
local Equipment = {}

-- ===== 装备定义 =====
Equipment.items = {
    -- === 武器 ===
    iron_sword = {
        name = "铁剑", type = "weapon", slot = "weapon",
        stats = { atk = 10 }, desc = "+10 攻击", price = 80,
    },
    steel_sword = {
        name = "钢剑", type = "weapon", slot = "weapon",
        stats = { atk = 25 }, desc = "+25 攻击", price = 200,
    },
    flame_blade = {
        name = "烈焰之刃", type = "weapon", slot = "weapon",
        stats = { atk = 40 }, desc = "+40 攻击，攻击附带灼烧",
        special = "burn", price = 500,
    },
    -- === 护甲 ===
    leather_armor = {
        name = "皮甲", type = "armor", slot = "armor",
        stats = { def = 8, hp = 50 }, desc = "+8 防御 +50 生命", price = 60,
    },
    chain_mail = {
        name = "锁子甲", type = "armor", slot = "armor",
        stats = { def = 20, hp = 100 }, desc = "+20 防御 +100 生命", price = 180,
    },
    dragon_armor = {
        name = "龙鳞甲", type = "armor", slot = "armor",
        stats = { def = 40, hp = 300 }, desc = "+40 防御 +300 生命",
        special = "thorns", price = 450,
    },
    -- === 饰品 ===
    speed_boots = {
        name = "疾风靴", type = "accessory", slot = "accessory",
        stats = { speed = 50 }, desc = "+50 移动速度", price = 100,
    },
    mana_ring = {
        name = "法力之环", type = "accessory", slot = "accessory",
        stats = { hp = 80 }, desc = "+80 生命，法力回复+50%",
        special = "mana_regen", price = 150,
    },
    life_steal = {
        name = "吸血鬼之牙", type = "accessory", slot = "accessory",
        stats = { atk = 15 }, desc = "+15 攻击，攻击回复 10% 伤害",
        special = "lifesteal", price = 350,
    },
}

-- ===== 英雄装备栏 =====
Hero.state.equipment = {}  -- { weapon=nil, armor=nil, accessory=nil }

function Equipment.Equip(itemId)
    local item = Equipment.items[itemId]
    if not item then return false end
    if gold_ < item.price then return false end

    gold_ = gold_ - item.price
    Hero.state.equipment[item.slot] = itemId
    Hero.RecalcStats()
    return true
end

function Equipment.Unequip(slot)
    Hero.state.equipment[slot] = nil
    Hero.RecalcStats()
end

return Equipment
```

---

### 4.4 路径系统 Path.lua

支持多路径分支，敌人随机选择一条路径行进。

```lua
local Path = {}

-- ===== 路径定义（支持多条路径）=====
Path.routes = {
    -- 路径 A：左侧入口
    {
        { x = -50,  y = 200 },
        { x = 150,  y = 200 },
        { x = 150,  y = 400 },
        { x = 400,  y = 400 },
        { x = 400,  y = 250 },
        { x = 700,  y = 250 },
        { x = 700,  y = 500 },
        { x = 1000, y = 500 },
        { x = 1000, y = 350 },
        { x = 1300, y = 350 },
        { x = 1450, y = 350 },  -- 终点
    },
    -- 路径 B：右侧入口
    {
        { x = 1450, y = 600 },
        { x = 1200, y = 600 },
        { x = 1200, y = 450 },
        { x = 900,  y = 450 },
        { x = 900,  y = 650 },
        { x = 600,  y = 650 },
        { x = 600,  y = 500 },
        { x = 300,  y = 500 },
        { x = 300,  y = 650 },
        { x = -50,  y = 650 },  -- 终点
    },
}

-- 获取路径总长度
function Path.GetRouteLength(route)
    local total = 0
    for i = 2, #route do
        local dx = route[i].x - route[i-1].x
        local dy = route[i].y - route[i-1].y
        total = total + math.sqrt(dx*dx + dy*dy)
    end
    return total
end

-- 根据进度获取路径上的位置
function Path.GetPosition(route, progress)
    if progress <= 0 then return route[1].x, route[1].y end
    if progress >= 1 then
        local last = route[#route]
        return last.x, last.y
    end
    local totalLen = Path.GetRouteLength(route)
    local targetDist = progress * totalLen
    local accumulated = 0
    for i = 2, #route do
        local dx = route[i].x - route[i-1].x
        local dy = route[i].y - route[i-1].y
        local segLen = math.sqrt(dx*dx + dy*dy)
        if accumulated + segLen >= targetDist then
            local t = (targetDist - accumulated) / segLen
            return route[i-1].x + dx * t, route[i-1].y + dy * t
        end
        accumulated = accumulated + segLen
    end
    return route[#route].x, route[#route].y
end

-- 随机选择一条路径
function Path.RandomRoute()
    return Path.routes[math.random(#Path.routes)]
end

return Path
```

---

### 4.5 敌人系统 Enemy.lua

敌人沿路径行进，有不同类型和特殊能力。

```lua
local Enemy = {}
Enemy.list = {}

-- ===== 敌人类型 =====
Enemy.types = {
    -- 普通小兵
    grunt = {
        name = "哥布林", hp = 80, speed = 70, reward = 5,
        damage = 5, size = 20, color = {200, 50, 50},
    },
    -- 快速单位
    runner = {
        name = "暗影跑者", hp = 50, speed = 140, reward = 8,
        damage = 3, size = 18, color = {150, 50, 200},
    },
    -- 重型单位
    brute = {
        name = "石巨人", hp = 400, speed = 35, reward = 20,
        damage = 15, size = 34, color = {80, 80, 80},
    },
    -- 远程单位
    archer = {
        name = "暗黑弓手", hp = 60, speed = 60, reward = 10,
        damage = 8, size = 22, color = {50, 150, 50},
        ranged = true, attackRange = 150, attackSpeed = 0.8,
    },
    -- Boss
    boss = {
        name = "魔王", hp = 2000, speed = 40, reward = 100,
        damage = 30, size = 44, color = {180, 30, 30},
        skills = {"summon", "aoe_slam"},
    },
}

function Enemy.Create(typeName, route)
    local config = Enemy.types[typeName]
    if not config then return nil end

    local enemy = {
        typeName = typeName,
        config = config,
        hp = config.hp,
        maxHP = config.hp,
        progress = 0,
        x = 0, y = 0,
        alive = true,
        route = route,
        stunTimer = 0,
        burnTimer = 0,
        burnDamage = 0,
        attackCooldown = 0,
        -- 远程攻击
        canAttack = config.ranged or false,
    }

    enemy.x, enemy.y = Path.GetPosition(route, 0)
    table.insert(Enemy.list, enemy)
    return enemy
end

function Enemy.UpdateAll(dt, heroState)
    for i = #Enemy.list, 1, -1 do
        local e = Enemy.list[i]
        if not e.alive then
            table.remove(Enemy.list, i)
        else
            Enemy.Update(e, dt, heroState)
        end
    end
end

function Enemy.Update(enemy, dt, heroState)
    -- 眩晕
    if enemy.stunTimer > 0 then
        enemy.stunTimer = enemy.stunTimer - dt
        return
    end

    -- 灼烧 DOT
    if enemy.burnTimer > 0 then
        enemy.burnTimer = enemy.burnTimer - dt
        enemy.hp = enemy.hp - enemy.burnDamage * dt
        if enemy.hp <= 0 then
            enemy.alive = false
            gold_ = gold_ + enemy.config.reward
            Hero.state.killCount = Hero.state.killCount + 1
            Particle.Spawn("death", enemy.x, enemy.y, 0)
            return
        end
    end

    -- 远程敌人：攻击英雄
    if enemy.canAttack then
        local dx = heroState.x - enemy.x
        local dy = heroState.y - enemy.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < enemy.config.attackRange then
            enemy.attackCooldown = enemy.attackCooldown - dt
            if enemy.attackCooldown <= 0 then
                Hero.TakeDamage(enemy.config.damage)
                enemy.attackCooldown = 1.0 / enemy.config.attackSpeed
                Projectile.Create(enemy.x, enemy.y, heroState,
                    enemy.config.damage, 200, {200, 50, 50})
            end
            return  -- 攻击时不移动
        end
    end

    -- 沿路径移动
    local speed = enemy.config.speed
    local totalLen = Path.GetRouteLength(enemy.route)
    enemy.progress = enemy.progress + (speed * dt) / totalLen
    enemy.x, enemy.y = Path.GetPosition(enemy.route, enemy.progress)

    -- 接触英雄造成伤害
    if heroState.alive then
        local dx = heroState.x - enemy.x
        local dy = heroState.y - enemy.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < (Hero.config.size + enemy.config.size) * 0.5 then
            Hero.TakeDamage(enemy.config.damage * 0.5)
        end
    end

    -- 到达终点
    if enemy.progress >= 1.0 then
        enemy.alive = false
        lives_ = (lives_ or 20) - 1
    end
end

function Enemy.Damage(enemy, amount)
    if not enemy.alive then return end
    enemy.hp = enemy.hp - amount
    Particle.Spawn("hit", enemy.x, enemy.y - 5, 0)
    if enemy.hp <= 0 then
        enemy.alive = false
        gold_ = gold_ + enemy.config.reward
        Hero.state.killCount = Hero.state.killCount + 1
        Particle.Spawn("death", enemy.x, enemy.y, 0)
    end
end

return Enemy
```

---

### 4.6 防御塔系统 Tower.lua

```lua
local Tower = {}
Tower.list = {}

Tower.types = {
    archer_tower = {
        name = "弓箭塔", cost = 50, damage = 20, range = 160,
        fireRate = 1.2, projectileSpeed = 350,
        color = {100, 150, 255}, size = 24,
    },
    cannon_tower = {
        name = "火炮塔", cost = 100, damage = 60, range = 200,
        fireRate = 0.5, projectileSpeed = 250,
        color = {200, 100, 50}, size = 28,
        splash = 50,
    },
    frost_tower = {
        name = "冰霜塔", cost = 75, damage = 10, range = 140,
        fireRate = 0.8, projectileSpeed = 200,
        color = {100, 200, 255}, size = 24,
        slow = true, slowDuration = 2.0, slowFactor = 0.4,
    },
    lightning_tower = {
        name = "闪电塔", cost = 150, damage = 35, range = 180,
        fireRate = 1.5, projectileSpeed = 999,
        color = {255, 255, 100}, size = 26,
        chain = 3,  -- 链式闪电跳跃 3 个目标
    },
}

function Tower.Create(typeName, x, y)
    local config = Tower.types[typeName]
    if not config or gold_ < config.cost then return nil end
    gold_ = gold_ - config.cost
    local tower = {
        type = typeName, config = config,
        x = x, y = y, cooldown = 0,
        level = 1, target = nil,
        _warCryATK = 0, _warCryTimer = 0,
    }
    table.insert(Tower.list, tower)
    return tower
end

function Tower.UpdateAll(dt)
    for _, tower in ipairs(Tower.list) do
        Tower.Update(tower, dt)
    end
end

function Tower.Update(tower, dt)
    tower.cooldown = tower.cooldown - dt

    -- 战吼 Buff 计时
    if tower._warCryTimer > 0 then
        tower._warCryTimer = tower._warCryTimer - dt
    else
        tower._warCryATK = 0
    end

    -- 寻找范围内最近的敌人
    local closest = nil
    local closestDist = tower.config.range
    for _, enemy in ipairs(Enemy.list) do
        if enemy.alive then
            local dx = enemy.x - tower.x
            local dy = enemy.y - tower.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < closestDist then
                closestDist = dist
                closest = enemy
            end
        end
    end

    if closest and tower.cooldown <= 0 then
        tower.cooldown = 1.0 / tower.config.fireRate
        local dmg = tower.config.damage * (1 + tower._warCryATK)

        if tower.config.chain then
            -- 链式闪电
            Tower.ChainLightning(tower, closest, dmg)
        else
            Projectile.Create(
                tower.x, tower.y, closest, dmg,
                tower.config.projectileSpeed,
                tower.config.color,
                tower.config.slow or false,
                tower.config.slowDuration or 0,
                tower.config.slowFactor or 1.0,
                tower.config.splash or 0
            )
        end
    end
end

function Tower.ChainLightning(tower, firstTarget, damage)
    local hit = { firstTarget }
    Enemy.Damage(firstTarget, damage)
    Particle.Spawn("lightning", tower.x, tower.y, 0)
    Particle.Spawn("lightning", firstTarget.x, firstTarget.y, 0)

    local current = firstTarget
    for i = 2, tower.config.chain do
        local nextTarget = nil
        local nextDist = 120  -- 链式跳跃范围
        for _, enemy in ipairs(Enemy.list) do
            if enemy.alive then
                local alreadyHit = false
                for _, h in ipairs(hit) do
                    if h == enemy then alreadyHit = true; break end
                end
                if not alreadyHit then
                    local dx = enemy.x - current.x
                    local dy = enemy.y - current.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist < nextDist then
                        nextDist = dist
                        nextTarget = enemy
                    end
                end
            end
        end
        if nextTarget then
            Enemy.Damage(nextTarget, damage * 0.7)  -- 跳跃衰减
            Particle.Spawn("lightning", nextTarget.x, nextTarget.y, 0)
            table.insert(hit, nextTarget)
            current = nextTarget
        else
            break
        end
    end
end

-- 升级防御塔
function Tower.Upgrade(tower)
    local cost = tower.config.cost * tower.level
    if gold_ < cost or tower.level >= 3 then return false end
    gold_ = gold_ - cost
    tower.level = tower.level + 1
    tower.config.damage = math.floor(tower.config.damage * 1.4)
    tower.config.range = tower.config.range * 1.1
    return true
end

return Tower
```

---

### 4.7 子弹与特效 Projectile.lua

```lua
local Projectile = {}
Projectile.list = {}

function Projectile.Create(x, y, target, damage, speed, color,
                            slow, slowDuration, slowFactor, splash)
    local p = {
        x = x, y = y, target = target,
        damage = damage, speed = speed,
        color = color or {255, 255, 255},
        slow = slow or false,
        slowDuration = slowDuration or 0,
        slowFactor = slowFactor or 1.0,
        splash = splash or 0,
        alive = true,
    }
    table.insert(Projectile.list, p)
    return p
end

function Projectile.UpdateAll(dt)
    for i = #Projectile.list, 1, -1 do
        local p = Projectile.list[i]
        if not p.target or not p.target.alive then
            table.remove(Projectile.list, i)
        else
            local dx = p.target.x - p.x
            local dy = p.target.y - p.y
            local dist = math.sqrt(dx*dx + dy*dy)

            if dist < 12 then
                -- 命中
                if p.target.hp then
                    -- 是敌人
                    Enemy.Damage(p.target, p.damage)
                    if p.slow then
                        p.target.stunTimer = 0
                        p.target._slowFactor = p.slowFactor
                        p.target._slowTimer = p.slowDuration
                    end
                else
                    -- 是英雄（敌人远程子弹）
                    Hero.TakeDamage(p.damage)
                end

                -- 溅射
                if p.splash > 0 then
                    for _, enemy in ipairs(Enemy.list) do
                        if enemy ~= p.target and enemy.alive then
                            local sdx = enemy.x - p.target.x
                            local sdy = enemy.y - p.target.y
                            if math.sqrt(sdx*sdx + sdy*sdy) < p.splash then
                                Enemy.Damage(enemy, p.damage * 0.5)
                            end
                        end
                    end
                    Particle.Spawn("explosion", p.target.x, p.target.y, 0)
                end

                table.remove(Projectile.list, i)
            else
                p.x = p.x + (dx / dist) * p.speed * dt
                p.y = p.y + (dy / dist) * p.speed * dt
            end
        end
    end
end

return Projectile
```

---

### 4.8 波次管理器 WaveManager.lua

```lua
local WaveManager = {}

WaveManager.waves = {
    -- 第1波：入门
    {
        prepTime = 10,
        groups = {
            { type = "grunt", count = 6, interval = 1.2, route = "random" },
        },
    },
    -- 第2波：引入快速单位
    {
        prepTime = 15,
        groups = {
            { type = "grunt", count = 8, interval = 1.0, route = "random" },
            { type = "runner", count = 4, interval = 1.5, route = "A" },
        },
    },
    -- 第3波：双路径压力
    {
        prepTime = 15,
        groups = {
            { type = "grunt", count = 5, interval = 1.0, route = "A" },
            { type = "runner", count = 5, interval = 1.0, route = "B" },
            { type = "grunt", count = 5, interval = 1.0, route = "B" },
        },
    },
    -- 第4波：引入重型
    {
        prepTime = 20,
        groups = {
            { type = "grunt", count = 10, interval = 0.7, route = "random" },
            { type = "brute", count = 2, interval = 4.0, route = "A" },
            { type = "archer", count = 3, interval = 2.0, route = "B" },
        },
    },
    -- 第5波：混合压力
    {
        prepTime = 20,
        groups = {
            { type = "runner", count = 8, interval = 0.6, route = "random" },
            { type = "brute", count = 3, interval = 3.0, route = "A" },
            { type = "archer", count = 5, interval = 1.5, route = "B" },
        },
    },
    -- 第6波：远程火力
    {
        prepTime = 20,
        groups = {
            { type = "archer", count = 10, interval = 1.0, route = "random" },
            { type = "grunt", count = 5, interval = 1.5, route = "A" },
        },
    },
    -- 第7波：高强度
    {
        prepTime = 25,
        groups = {
            { type = "grunt", count = 15, interval = 0.5, route = "random" },
            { type = "brute", count = 4, interval = 2.5, route = "random" },
            { type = "runner", count = 6, interval = 0.8, route = "B" },
        },
    },
    -- 第8波：Boss 波
    {
        prepTime = 30,
        groups = {
            { type = "boss", count = 1, interval = 0, route = "A" },
            { type = "grunt", count = 10, interval = 0.6, route = "B" },
            { type = "brute", count = 3, interval = 3.0, route = "A" },
        },
    },
}

WaveManager.currentWave = 0
WaveManager.spawnQueue = {}
WaveManager.spawnTimer = 0
WaveManager.waveActive = false
WaveManager.prepTimer = 0
WaveManager.allComplete = false

function WaveManager.Update(dt)
    if WaveManager.allComplete then return end

    if not WaveManager.waveActive then
        WaveManager.prepTimer = WaveManager.prepTimer - dt
        if WaveManager.prepTimer <= 0 then
            WaveManager.StartNextWave()
        end
        return
    end

    WaveManager.spawnTimer = WaveManager.spawnTimer - dt
    if WaveManager.spawnTimer <= 0 and #WaveManager.spawnQueue > 0 then
        local next = table.remove(WaveManager.spawnQueue, 1)
        local route
        if next.route == "random" then
            route = Path.RandomRoute()
        elseif next.route == "A" then
            route = Path.routes[1]
        else
            route = Path.routes[2]
        end
        Enemy.Create(next.type, route)
        WaveManager.spawnTimer = next.interval
    end

    if #WaveManager.spawnQueue == 0 and #Enemy.list == 0 then
        WaveManager.waveActive = false
        local nextWave = WaveManager.waves[WaveManager.currentWave + 1]
        if nextWave then
            WaveManager.prepTimer = nextWave.prepTime
        else
            WaveManager.allComplete = true
        end
    end
end

function WaveManager.StartNextWave()
    WaveManager.currentWave = WaveManager.currentWave + 1
    local wave = WaveManager.waves[WaveManager.currentWave]
    if not wave then WaveManager.allComplete = true; return end

    WaveManager.spawnQueue = {}
    for _, group in ipairs(wave.groups) do
        for j = 1, group.count do
            table.insert(WaveManager.spawnQueue, {
                type = group.type,
                interval = group.interval,
                route = group.route,
            })
        end
    end
    WaveManager.spawnTimer = 0
    WaveManager.waveActive = true
end

function WaveManager.Init()
    WaveManager.prepTimer = WaveManager.waves[1].prepTime
end

return WaveManager
```

---

### 4.9 输入控制 InputController.lua

支持键盘（PC）和触屏（移动端）双端操作。

```lua
local InputController = {}

-- ===== 输入状态 =====
InputController.state = {
    moveX = 0, moveY = 0,       -- 移动方向 (-1 ~ 1)
    attacking = false,           -- 是否在攻击
    placingTower = nil,          -- 正在放置的塔类型
    skillTarget = nil,           -- 技能目标位置
}

-- ===== 键盘输入（PC）=====
function InputController.HandleKeyboard(dt)
    local s = InputController.state
    s.moveX = 0
    s.moveY = 0

    if Input.IsKeyDown(KEY_A) or Input.IsKeyDown(KEY_LEFT) then
        s.moveX = s.moveX - 1
    end
    if Input.IsKeyDown(KEY_D) or Input.IsKeyDown(KEY_RIGHT) then
        s.moveX = s.moveX + 1
    end
    if Input.IsKeyDown(KEY_W) or Input.IsKeyDown(KEY_UP) then
        s.moveY = s.moveY - 1
    end
    if Input.IsKeyDown(KEY_S) or Input.IsKeyDown(KEY_DOWN) then
        s.moveY = s.moveY + 1
    end

    -- 归一化对角线移动
    if s.moveX ~= 0 and s.moveY ~= 0 then
        local len = math.sqrt(s.moveX*s.moveX + s.moveY*s.moveY)
        s.moveX = s.moveX / len
        s.moveY = s.moveY / len
    end

    -- 攻击（鼠标左键 / 空格）
    s.attacking = Input.IsKeyDown(KEY_SPACE) or Input.GetMouseButtonDown(MOUSEB_LEFT)

    -- 技能快捷键 1-4
    if Input.IsKeyDown(KEY_1) then
        Skills.Cast(1, Hero.state.x, Hero.state.y, Enemy.list, Tower.list)
    end
    if Input.IsKeyDown(KEY_2) then
        Skills.Cast(2, Hero.state.x, Hero.state.y, Enemy.list, Tower.list)
    end
    if Input.IsKeyDown(KEY_3) then
        local mx, my = Input.GetMousePosition()
        Skills.Cast(3, mx, my, Enemy.list, Tower.list)
    end
    if Input.IsKeyDown(KEY_4) then
        local mx, my = Input.GetMousePosition()
        Skills.Cast(4, mx, my, Enemy.list, Tower.list)
    end

    -- 放塔（鼠标右键）
    if Input.GetMouseButtonDown(MOUSEB_RIGHT) then
        local mx, my = Input.GetMousePosition()
        if InputController.state.placingTower then
            Tower.Create(InputController.state.placingTower, mx, my)
        end
    end
end

-- ===== 触屏输入（移动端）=====
-- 左侧虚拟摇杆控制移动
-- 右侧攻击按钮 + 技能按钮
-- 点击空地放塔
InputController.joystick = { active = false, startX = 0, startY = 0, dx = 0, dy = 0 }
InputController.joystickZone = { x = 0, y = 0, w = 200, h = 300 }  -- 左侧区域

function InputController.HandleTouch()
    -- 触屏逻辑通过 UI 按钮事件绑定实现
    -- 详见 UI.lua 中的触屏按钮处理
end

return InputController
```

---

### 4.10 UI 渲染 UI.lua

```lua
local UI = {}

function UI.Render(nvg, phase, gold, lives, wave, heroState)
    nvgSave(nvg)

    -- ===== 顶部 HUD =====
    nvgFillColor(nvg, 20, 25, 35, 220)
    nvgBeginPath(nvg)
    nvgRect(nvg, 0, 0, graphics.width, 45)
    nvgFill(nvg)

    nvgFontSize(nvg, 18)
    nvgFillColor(nvg, 255, 215, 0, 255)
    nvgText(nvg, 15, 28, "金币: " .. gold)
    nvgFillColor(nvg, 255, 80, 80, 255)
    nvgText(nvg, 160, 28, "生命: " .. lives)
    nvgFillColor(nvg, 255, 255, 255, 255)
    nvgText(nvg, 300, 28, "波次: " .. wave .. "/8")
    nvgFillColor(nvg, 100, 255, 100, 255)
    nvgText(nvg, 450, 28, "击杀: " .. heroState.killCount)

    -- ===== 英雄血条 + 法力条 =====
    UI.DrawHeroBars(nvg, heroState)

    -- ===== 技能栏 =====
    UI.DrawSkillBar(nvg)

    -- ===== 塔选择栏 =====
    UI.DrawTowerBar(nvg, gold)

    -- ===== 波次提示 =====
    if not WaveManager.waveActive and not WaveManager.allComplete then
        local remaining = math.ceil(WaveManager.prepTimer)
        nvgFillColor(nvg, 255, 200, 50, 255)
        nvgFontSize(nvg, 28)
        nvgTextAlign(nvg, NVG_ALIGN_CENTER)
        nvgText(nvg, graphics.width / 2, 80,
            "下一波: " .. remaining .. "秒")
    end

    if WaveManager.allComplete then
        nvgFillColor(nvg, 100, 255, 100, 255)
        nvgFontSize(nvg, 36)
        nvgTextAlign(nvg, NVG_ALIGN_CENTER)
        nvgText(nvg, graphics.width / 2, graphics.height / 2,
            "胜利！")
    end

    nvgRestore(nvg)
end

function UI.DrawHeroBars(nvg, heroState)
    local bx = 15
    local by = 55

    -- 血条背景
    nvgFillColor(nvg, 40, 40, 40, 200)
    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, bx, by, 180, 16, 4)
    nvgFill(nvg)

    -- 血条
    local hpRatio = heroState.hp / heroState.maxHP
    local hpColor = hpRatio > 0.5 and {80, 200, 80}
        or (hpRatio > 0.25 and {220, 180, 40} or {220, 50, 50})
    nvgFillColor(nvg, hpColor[1], hpColor[2], hpColor[3], 255)
    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, bx, by, 180 * hpRatio, 16, 4)
    nvgFill(nvg)

    nvgFillColor(nvg, 255, 255, 255, 255)
    nvgFontSize(nvg, 12)
    nvgTextAlign(nvg, NVG_ALIGN_CENTER)
    nvgText(nvg, bx + 90, by + 12, math.floor(heroState.hp) .. "/" .. heroState.maxHP)

    -- 法力条
    nvgFillColor(nvg, 30, 30, 60, 200)
    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, bx, by + 20, 180, 10, 3)
    nvgFill(nvg)
    nvgFillColor(nvg, 80, 120, 255, 255)
    nvgBeginPath(nvg)
    nvgRoundedRect(nvg, bx, by + 20, 180 * (heroState.mana / Hero.config.maxMana), 10, 3)
    nvgFill(nvg)
end

function UI.DrawSkillBar(nvg)
    local startX = graphics.width / 2 - 120
    local sy = graphics.height - 70

    for i = 1, 4 do
        local slot = Skills.slots[i]
        local sx = startX + (i - 1) * 65

        -- 背景
        local unlocked = slot.level > 0
        local ready = unlocked and slot.cooldownTimer <= 0
            and Hero.state.mana >= Skills.definitions[slot.id].manaCost

        if ready then
            nvgFillColor(nvg, 60, 80, 120, 230)
        elseif unlocked then
            nvgFillColor(nvg, 40, 40, 50, 200)
        else
            nvgFillColor(nvg, 25, 25, 30, 150)
        end
        nvgBeginPath(nvg)
        nvgRoundedRect(nvg, sx, sy, 55, 55, 8)
        nvgFill(nvg)

        -- 冷却遮罩
        if unlocked and slot.cooldownTimer > 0 then
            local cdRatio = slot.cooldownTimer / Skills.definitions[slot.id].cooldown
            nvgFillColor(nvg, 0, 0, 0, 150)
            nvgBeginPath(nvg)
            nvgRoundedRect(nvg, sx, sy, 55, 55 * cdRatio, 8)
            nvgFill(nvg)
        end

        -- 技能名
        if unlocked then
            nvgFillColor(nvg, 255, 255, 255, 255)
            nvgFontSize(nvg, 11)
            nvgTextAlign(nvg, NVG_ALIGN_CENTER)
            nvgText(nvg, sx + 27, sy + 25, Skills.definitions[slot.id].name)
            nvgFillColor(nvg, 150, 180, 255, 255)
            nvgFontSize(nvg, 10)
            nvgText(nvg, sx + 27, sy + 42, "Lv." .. slot.level)
        else
            nvgFillColor(nvg, 100, 100, 100, 200)
            nvgFontSize(nvg, 11)
            nvgTextAlign(nvg, NVG_ALIGN_CENTER)
            nvgText(nvg, sx + 27, sy + 30, "未解锁")
        end

        -- 快捷键提示
        nvgFillColor(nvg, 180, 180, 180, 200)
        nvgFontSize(nvg, 10)
        nvgText(nvg, sx + 20, sy - 5, tostring(i))
    end
end

function UI.DrawTowerBar(nvg, gold)
    local startX = graphics.width - 350
    local ty = graphics.height - 70

    nvgFillColor(nvg, 255, 255, 255, 200)
    nvgFontSize(nvg, 14)
    nvgTextAlign(nvg, NVG_ALIGN_LEFT)
    nvgText(nvg, startX, ty - 8, "防御塔 (右键放置):")

    local towerTypes = { "archer_tower", "cannon_tower", "frost_tower", "lightning_tower" }
    for i, typeName in ipairs(towerTypes) do
        local config = Tower.types[typeName]
        local tx = startX + (i - 1) * 85

        local canAfford = gold >= config.cost
        nvgFillColor(nvg, canAfford and 50 or 30,
                     canAfford and 60 or 30,
                     canAfford and 80 or 40, 220)
        nvgBeginPath(nvg)
        nvgRoundedRect(nvg, tx, ty, 75, 55, 6)
        nvgFill(nvg)

        -- 塔颜色标识
        nvgFillColor(nvg, config.color[1], config.color[2], config.color[3], 255)
        nvgBeginPath(nvg)
        nvgCircle(nvg, tx + 37, ty + 18, 12)
        nvgFill(nvg)

        nvgFillColor(nvg, 255, 255, 255, 255)
        nvgFontSize(nvg, 12)
        nvgTextAlign(nvg, NVG_ALIGN_CENTER)
        nvgText(nvg, tx + 37, ty + 40, config.name)
        nvgFillColor(nvg, 255, 215, 0, 255)
        nvgFontSize(nvg, 10)
        nvgText(nvg, tx + 37, ty + 52, config.cost .. "G")
    end
end

return UI
```

---

### 4.11 入口文件 Main.lua

```lua
require "LuaScripts/Utilities/Sample"

local scene_ = nil
local nvg_ = nil
local gold_ = 200
local lives_ = 20

function Start()
    scene_ = Scene()
    nvg_ = nvgCreate(1)
    if not nvg_ then
        print("[ERROR] Failed to create NanoVG context")
        return
    end

    -- 加载模块
    Config = require("scripts/Config")
    Path = require("scripts/Path")
    Hero = require("scripts/Hero")
    Skills = require("scripts/Skills")
    Equipment = require("scripts/Equipment")
    Enemy = require("scripts/Enemy")
    Tower = require("scripts/Tower")
    Projectile = require("scripts/Projectile")
    WaveManager = require("scripts/WaveManager")
    InputController = require("scripts/InputController")
    Particle = require("scripts/Particle")
    UI = require("scripts/UI")

    -- 初始化
    Hero.Init()
    WaveManager.Init()

    SubscribeToEvent("Update", "HandleUpdate")
end

function HandleUpdate(eventType, eventData)
    local dt = eventData["TimeStep"]:GetFloat()

    -- 输入处理
    InputController.HandleKeyboard(dt)

    -- 更新英雄
    Hero.state.vx = InputController.state.moveX
    Hero.state.vy = InputController.state.moveY
    Hero.Update(dt)

    -- 英雄攻击
    if InputController.state.attacking then
        Hero.Attack(Enemy.list)
    end

    -- 更新技能冷却
    Skills.Update(dt)

    -- 更新敌人
    Enemy.UpdateAll(dt, Hero.state)

    -- 更新防御塔
    Tower.UpdateAll(dt)

    -- 更新子弹
    Projectile.UpdateAll(dt)

    -- 更新波次
    WaveManager.Update(dt)

    -- 更新粒子
    Particle.UpdateAll(dt)

    -- 检查游戏结束
    if not Hero.state.alive or lives_ <= 0 then
        -- 游戏结束逻辑
    end

    -- 渲染
    if nvg_ then
        nvgBeginFrame(nvg_, graphics.width, graphics.height, 1.0)
        -- 绘制路径
        Path.Draw(nvg)
        -- 绘制防御塔
        Tower.DrawAll(nvg)
        -- 绘制敌人
        Enemy.DrawAll(nvg)
        -- 绘制英雄
        Hero.Draw(nvg)
        -- 绘制子弹
        Projectile.DrawAll(nvg)
        -- 绘制粒子
        Particle.DrawAll(nvg)
        -- 绘制 UI
        UI.Render(nvg, "battle", gold_, lives_,
                  WaveManager.currentWave, Hero.state)
        nvgEndFrame(nvg_)
    end
end

function Stop()
    if nvg_ then
        nvgDelete(nvg_)
        nvg_ = nil
    end
end
```

---

## 五、Tiny Swords 素材映射方案

| 游戏元素 | Tiny Swords 素材 | 说明 |
|---------|-----------------|------|
| **英雄** | Warrior（蓝色阵营） | 玩家控制的主角 |
| **弓箭塔** | Archer（蓝/黄/黑） | 远程自动攻击 |
| **火炮塔** | Lancer 改造（红色） | 范围溅射伤害 |
| **冰霜塔** | Monk 改造（冰蓝色） | 减速效果 |
| **闪电塔** | 特殊配色（黄色） | 链式闪电 |
| **哥布林敌人** | Enemy Pack 基础敌人 | 红色阵营 |
| **暗影跑者** | Enemy Pack 快速型 | 紫色阵营 |
| **石巨人** | Enemy Pack 重型 | 黑色阵营 |
| **暗黑弓手** | Enemy Pack 远程型 | 绿色阵营 |
| **魔王 Boss** | Enemy Pack 大型敌人 | 深红色 + 特效 |
| **路径** | Terrain Tiles 平地 | 浅色瓦片铺设 |
| **地形** | Terrain Tiles | 草地、水面、装饰 |
| **UI** | UI Elements | 血条、按钮、图标、横幅 |
| **特效** | Particle FX | 火焰、爆炸、灰尘、水花 |
| **装备图标** | Tiny Swords 武器/道具 | 剑、盾、靴子等 |

---

## 六、数值平衡设计

### 英雄成长曲线

| 阶段 | 血量 | 攻击 | 推荐策略 |
|------|------|------|---------|
| 第 1-2 波 | 500 | 40 | 近战清小兵，攒金币 |
| 第 3-4 波 | 500-700 | 40-65 | 放第一座塔，买装备 |
| 第 5-6 波 | 700-1000 | 65-90 | 多塔配合，技能升级 |
| 第 7-8 波 | 1000-1500 | 90-130 | 全力输出，注意走位 |

### 敌人强度缩放

| 波次 | 敌人数量 | 总血量 | DPS 压力 | 特殊机制 |
|------|---------|--------|---------|---------|
| 1 | 6 | 480 | 低 | 纯近战 |
| 2 | 12 | 680 | 中 | 快速单位 |
| 3 | 15 | 800 | 中高 | 双路径 |
| 4 | 15 | 1400 | 高 | 重型 + 远程 |
| 5 | 16 | 1100 | 高 | 混合快慢 |
| 6 | 15 | 900 | 中高 | 远程火力 |
| 7 | 25 | 2000 | 很高 | 全类型混合 |
| 8 | 14 | 4000+ | 极高 | Boss + 小兵 |

### 防御塔性价比

| 塔 | 费用 | DPS | 单价 DPS | 特殊价值 |
|----|------|-----|---------|---------|
| 弓箭塔 | 50 | 24 | 0.48 | 入门首选 |
| 冰霜塔 | 75 | 8 | 0.11 | 减速控场 |
| 火炮塔 | 100 | 30 | 0.30 | AOE 清群 |
| 闪电塔 | 150 | 52.5 | 0.35 | 多目标链式 |

---

## 七、关卡设计模板

### 关卡 1：森林隘口（入门）

```
特点：单路径，无分支
敌人：纯近战小兵
推荐塔：弓箭塔 × 2
教学目标：移动、攻击、放塔
```

### 关卡 2：双河交汇（双路径）

```
特点：两条路径从左右两侧进入
敌人：快速单位 + 普通小兵
推荐塔：弓箭塔 + 冰霜塔
教学目标：多路径防守、减速配合
```

### 关卡 3：峡谷要塞（长路径）

```
特点：一条很长的 S 形路径
敌人：全类型混合
推荐塔：火炮塔 + 闪电塔
教学目标：塔布局优化、装备选择
```

### 关卡 4：魔王城堡（Boss 关）

```
特点：双路径 + Boss
敌人：Boss 每 5 波出现一次
推荐塔：全类型搭配
教学目标：技能时机、团队配合
```

---

## 八、开发路线图（分 6 个阶段）

### 阶段 1：英雄控制（2-3 天）

- 英雄移动（WASD）
- 英雄攻击（空格/鼠标左键）
- 敌人沿路径行进
- 英雄与敌人碰撞伤害
- 用色块验证

### 阶段 2：塔防系统（2-3 天）

- 4 种防御塔放置（鼠标右键）
- 塔自动攻击 + 子弹飞行
- 冰霜塔减速、火炮塔溅射、闪电塔链式
- 塔升级机制

### 阶段 3：技能系统（2-3 天）

- 4 个技能实现（旋风斩/冲锋/战吼/陨石）
- 技能冷却和法力消耗
- 技能升级
- 技能特效

### 阶段 4：波次与经济（2 天）

- 8 波敌人配置
- 多路径敌人分配
- 金币系统（击杀奖励 + 建塔花费）
- 装备商店

### 阶段 5：内容与打磨（2-3 天）

- 替换 Tiny Swords 精灵图
- 粒子特效系统
- 多关卡支持
- 音效（可选）

### 阶段 6：适配与发布（2 天）

- 移动端虚拟摇杆 + 按钮
- 触屏放塔操作
- 数值平衡微调
- game.json + README

---

## 九、UrhoX 开发注意事项

1. **操作复杂度**：这是三种游戏中操作最复杂的（WASD + 鼠标 + 技能键），移动端适配需要虚拟摇杆 + 多个按钮，务必预留足够的 UI 空间
2. **性能瓶颈**：同屏可能有 20+ 敌人 + 多座塔 + 大量子弹和粒子，建议使用对象池并限制粒子数量
3. **碰撞检测优化**：英雄与敌人的碰撞、子弹与敌人的碰撞每帧都要计算，建议使用简单的距离检测而非物理引擎
4. **摄像机跟随**：如果地图大于屏幕，需要实现摄像机平滑跟随英雄
5. **技能目标指示**：陨石等指向性技能需要显示目标区域预览（半透明圆圈）
6. **战吼 Buff 叠加**：战吼同时 Buff 英雄和塔，需要确保 Buff 计时器正确衰减
7. **敌人远程攻击**：远程敌人会向英雄射击子弹，需要区分"对敌子弹"和"对英雄子弹"

### 参考资源

- UrhoX 塔防示例：https://github.com/taptap/awesome-urhox-games/pull/5
- UrhoX AI Dev Kit：https://urhox-demo-platform.spark.xd.com
- Tiny Swords 素材包：https://pixelfrog-assets.itch.io/tiny-swords
- 《Orcs Must Die!》玩法分析：https://liquipedia.net/orcsmustdie/
