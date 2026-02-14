-- ════════════════════════════════════════════════════════════════
-- WindUI Chat & Morph Script - ОПТИМИЗИРОВАННАЯ ВЕРСИЯ
-- Полный функционал + система конфигов + защита от крашей
-- ════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════
-- ЗАЩИТА ОТ ПОВТОРНОГО ЗАПУСКА
-- ════════════════════════════════════════════════════════════════
if _G.ChatMorphHubLoaded then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "⚠️ Уже запущено!",
            Text = "Скрипт уже активен",
            Duration = 3,
        })
    end)
    return
end

_G.ChatMorphHubLoaded = true

-- ════════════════════════════════════════════════════════════════
-- СЕРВИСЫ И ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════════
-- СИСТЕМА УПРАВЛЕНИЯ CONNECTIONS (ЗАЩИТА ОТ УТЕЧЕК ПАМЯТИ)
-- ════════════════════════════════════════════════════════════════
local Connections = {}

local function addConnection(name, connection)
    if Connections[name] then
        pcall(function() Connections[name]:Disconnect() end)
    end
    Connections[name] = connection
end

local function cleanupConnections()
    for _, conn in pairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
end

-- ════════════════════════════════════════════════════════════════
-- СОСТОЯНИЕ СКРИПТА
-- ════════════════════════════════════════════════════════════════
local State = {
    -- Система
    _running = true,
    
    -- Chat
    chatEnabled = false,
    chatMessage = "workby!88!",
    originalDisplayName = player.DisplayName ~= "" and player.DisplayName or player.Name,
    
    -- Name Changers
    usernameChangerEnabled = false,
    displayNameChangerEnabled = false,
    rankChangerEnabled = false,
    gameUsername = "",
    gameDisplayName = "",
    gameRank = "",
    
    -- Avatar
    avatarUsername = "",
    avatarAutoApply = true,
    savedAvatarUsername = "",
    
    -- Rainbow
    rainbowEnabled = false,
    rainbowSpeed = 1,
    rainbowCustomColor = Color3.fromRGB(255, 80, 80),
    rainbowUseCustomColor = false,
    
    -- UI Toggles
    uiHidden = false,
    killfeedHidden = false,
    globalKillfeedEnabled = true,
    hpBarEnabled = false,
    hpBarColor = Color3.fromRGB(0, 255, 0),
    
    -- Keybinds
    menuKeybind = "Insert",
    
    -- Kill Notifier
    killNotifierEnabled = false,
    killNotifierDuration = 2,
    
    -- Misc / Time Control
    freezeTime = false,
    customTime = 12,
    
    -- ACS Advanced
    acsAnimPatchApplied = false,
    acsAmmoPatchApplied = false,
    acsMedPatchApplied = false,
    acsHitSoundEnabled = false,
}

-- ════════════════════════════════════════════════════════════════
-- ЗАГРУЗКА WINDUI
-- ════════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- ════════════════════════════════════════════════════════════════
-- ПРОВЕРКА ВОЗМОЖНОСТЕЙ ЭКЗЕКУТОРА
-- ════════════════════════════════════════════════════════════════
local ExecutorCapabilities = {
    hookfunction = type(hookfunction) == "function",
    hookmetamethod = type(hookmetamethod) == "function",
    getrawmetatable = type(getrawmetatable) == "function",
    setreadonly = type(setreadonly) == "function",
    newcclosure = type(newcclosure) == "function",
    checkcaller = type(checkcaller) == "function",
    getcustomasset = type(getcustomasset) == "function" or type(getsynasset) == "function",
}

local function getACSSupport()
    local features, unsupported = {}, {}
    
    if ExecutorCapabilities.hookfunction then
        table.insert(features, "✓ Ускорение анимаций")
    else
        table.insert(unsupported, "✗ Ускорение анимаций")
    end
    
    if ExecutorCapabilities.hookmetamethod and ExecutorCapabilities.newcclosure and ExecutorCapabilities.checkcaller then
        table.insert(features, "✓ Бесконечные патроны")
    else
        table.insert(unsupported, "✗ Бесконечные патроны")
    end
    
    if ExecutorCapabilities.getrawmetatable and ExecutorCapabilities.setreadonly then
        table.insert(features, "✓ Медицина на ходу")
    else
        table.insert(unsupported, "✗ Медицина на ходу")
    end
    
    if ExecutorCapabilities.getcustomasset then
        table.insert(features, "✓ Кастомный HitSound")
    else
        table.insert(unsupported, "✗ Кастомный HitSound")
    end
    
    return features, unsupported
end

-- ════════════════════════════════════════════════════════════════
-- УТИЛИТЫ
-- ════════════════════════════════════════════════════════════════

-- TextChat канал
local channel
pcall(function()
    channel = TextChatService:WaitForChild("TextChannels", 5):WaitForChild("RBXGeneral", 5)
end)

-- Поиск игрока
local function findPlayerByName(partialName)
    if not partialName or partialName == "" then return nil end
    local searchName = partialName:lower()
    
    local foundPlayer = nil
    for _, v in ipairs(Players:GetPlayers()) do
        local nameLower = v.Name:lower()
        local dNameLower = v.DisplayName:lower()
        
        if nameLower == searchName or dNameLower == searchName then
            return v
        end
        
        if nameLower:sub(1, #searchName) == searchName or dNameLower:sub(1, #searchName) == searchName then
            foundPlayer = v
        end
    end
    
    if not foundPlayer then
        local success, userId = pcall(function()
            return Players:GetUserIdFromNameAsync(searchName)
        end)
        if success and userId then
            return {UserId = userId, Name = searchName}
        end
    end
    
    return foundPlayer
end

-- Morph к игроку
local function morphToPlayer(target)
    if not target then return end
    
    local userId = target.UserId or (type(target) == "number" and target or target.UserId)
    if userId == player.UserId then return end
    
    pcall(function()
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid then return end

        local desc = Players:GetHumanoidDescriptionFromUserId(userId)
        if not desc then return end

        for _, obj in ipairs(character:GetChildren()) do
            if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or
               obj:IsA("Accessory") or obj:IsA("BodyColors") then
                obj:Destroy()
            end
        end
        
        local head = character:FindFirstChild("Head")
        if head then
            for _, decal in ipairs(head:GetChildren()) do
                if decal:IsA("Decal") then decal:Destroy() end
            end
        end

        humanoid:ApplyDescriptionClientServer(desc)
    end)
end

-- Изменение nametag
local function changeNameTag(displayName, username, rank)
    pcall(function()
        local char = player.Character
        if not char then return end
        
        local head = char:FindFirstChild("Head")
        if not head then return end
        
        local nameTag = head:FindFirstChild("NameTag")
        if not nameTag then return end
        
        local usernameLabel = nameTag:FindFirstChild("Username")
        local displayLabel = nameTag:FindFirstChild("DisplayName")
        local rankLabel = nameTag:FindFirstChild("Rank")
        
        if usernameLabel and usernameLabel:IsA("TextLabel") and State.displayNameChangerEnabled and displayName ~= "" then
            usernameLabel.Text = displayName
        end
        
        if displayLabel and displayLabel:IsA("TextLabel") and State.usernameChangerEnabled and username ~= "" then
            local formattedUsername = username
            if not formattedUsername:match("^@") then
                formattedUsername = "@" .. formattedUsername
            end
            displayLabel.Text = formattedUsername
        end
        
        if rankLabel and rankLabel:IsA("TextLabel") and State.rankChangerEnabled then
            rankLabel.Text = rank or ""
        end
    end)
end

-- Применение всех настроек имени
local function applyAllNameChanges()
    task.wait(0.5)
    changeNameTag(State.gameDisplayName, State.gameUsername, State.gameRank)
end

-- Скрытие UI элементов
local function toggleGameUI()
    pcall(function()
        local ui = player.PlayerGui:WaitForChild("UI", 2):WaitForChild("Container", 2):WaitForChild("HUD", 2)
        if not ui then return end
        
        local map = ui:FindFirstChild("Map")
        local menu = ui:FindFirstChild("Menu")
        local topbar = ui:FindFirstChild("Topbar")
        
        if map then map.Visible = not State.uiHidden end
        if menu then menu.Visible = not State.uiHidden end
        if topbar then topbar.Visible = not State.uiHidden end
    end)
end

-- Скрытие killfeed
local function toggleKillfeed()
    pcall(function()
        local killfeed = player.PlayerGui:WaitForChild("UI", 2):WaitForChild("Container", 2):WaitForChild("HUD", 2):WaitForChild("Killfeed", 2)
        if killfeed then
            killfeed.Visible = not State.killfeedHidden
        end
    end)
end

-- Отправка сообщения в чат
local lastSend = 0
local function safeSend(msg)
    if not channel or not msg or msg == "" then return end
    local now = tick()
    if now - lastSend < 1 then return end
    lastSend = now
    pcall(function() channel:SendAsync(msg) end)
end

-- ════════════════════════════════════════════════════════════════
-- СОЗДАНИЕ CUSTOM UI ЭЛЕМЕНТОВ
-- ════════════════════════════════════════════════════════════════
local CustomUI = Instance.new("ScreenGui")
CustomUI.Name = "CustomScriptElements"
CustomUI.ResetOnSpawn = false
CustomUI.IgnoreGuiInset = true
CustomUI.Parent = CoreGui

-- Контейнер Killfeed (правый верх)
local KillfeedContainer = Instance.new("Frame")
KillfeedContainer.Name = "GlobalKillfeed"
KillfeedContainer.Size = UDim2.new(0, 250, 0, 300)
KillfeedContainer.Position = UDim2.new(1, -260, 0, 180)
KillfeedContainer.BackgroundTransparency = 1
KillfeedContainer.Parent = CustomUI

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 4)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Right
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = KillfeedContainer

-- HP Bar (левый низ)
local HPBack = Instance.new("Frame")
HPBack.Name = "HPBar"
HPBack.Size = UDim2.new(0, 140, 0, 40)
HPBack.Position = UDim2.new(0, 10, 1, -50)
HPBack.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
HPBack.BackgroundTransparency = 0.3
HPBack.BorderSizePixel = 0
HPBack.Visible = false
HPBack.Parent = CustomUI

local HPCorner = Instance.new("UICorner")
HPCorner.CornerRadius = UDim.new(0, 4)
HPCorner.Parent = HPBack

local HPIcon = Instance.new("TextLabel")
HPIcon.Size = UDim2.new(0, 40, 1, 0)
HPIcon.BackgroundTransparency = 1
HPIcon.Font = Enum.Font.GothamBold
HPIcon.TextSize = 24
HPIcon.TextColor3 = Color3.new(1, 1, 1)
HPIcon.Text = "+"
HPIcon.Parent = HPBack

local HPLabel = Instance.new("TextLabel")
HPLabel.Size = UDim2.new(1, -45, 1, 0)
HPLabel.Position = UDim2.new(0, 45, 0, 0)
HPLabel.BackgroundTransparency = 1
HPLabel.Font = Enum.Font.GothamBold
HPLabel.TextSize = 26
HPLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
HPLabel.TextStrokeTransparency = 0
HPLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
HPLabel.Text = "100"
HPLabel.TextXAlignment = Enum.TextXAlignment.Left
HPLabel.Parent = HPBack

-- ════════════════════════════════════════════════════════════════
-- СОЗДАНИЕ WINDUI ОКНА
-- ════════════════════════════════════════════════════════════════
local Window = WindUI:CreateWindow({
    Title = "ДЦПХАБ  |  by .alowyy1",
    Folder = "ChatMorphHub",
    Icon = "lucide:messages-square",
    NewElements = true,
    HideSearchBar = false,
    
    OpenButton = {
        Title = "Open Chat Hub",
        CornerRadius = UDim.new(0, 8),
        StrokeThickness = 2,
        Enabled = false,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.5,
        Color = ColorSequence.new(
            Color3.fromHex("#FF5050"), 
            Color3.fromHex("#FF8030")
        )
    },
    
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

Window:Tag({
    Title = "v1.1",
    Icon = "lucide:sparkles",
    Color = Color3.fromHex("#FF5050"),
    Border = true,
})

-- ════════════════════════════════════════════════════════════════
-- ВКЛАДКА: CHAT
-- ════════════════════════════════════════════════════════════════
local ChatTab = Window:Tab({
    Title = "Chat",
    Icon = "lucide:message-square",
    IconColor = Color3.fromHex("#10C550"),
    Border = true,
})

ChatTab:Section({
    Title = "Чат настройки",
    TextSize = 18,
})

ChatTab:Input({
    Flag = "ChatMessage",
    Title = "Сообщение в чат",
    Icon = "lucide:message-circle",
    Value = State.chatMessage,
    Placeholder = "Введи сообщение...",
    Callback = function(value)
        State.chatMessage = value
    end
})

ChatTab:Space()

ChatTab:Input({
    Flag = "OriginalDisplayName",
    Title = "Твой родной DisplayName",
    Icon = "lucide:user",
    Value = State.originalDisplayName,
    Placeholder = "DisplayName...",
    Callback = function(value)
        State.originalDisplayName = value
    end
})

ChatTab:Space()

ChatTab:Toggle({
    Flag = "ChatEnabled",
    Title = "Включить чат при убийстве",
    Desc = "Автоматически отправляет сообщение когда ты убиваешь",
    Value = State.chatEnabled,
    Callback = function(value)
        State.chatEnabled = value
    end
})

ChatTab:Space()

ChatTab:Button({
    Title = "Протестировать сообщение",
    Icon = "lucide:send",
    Justify = "Center",
    Color = Color3.fromHex("#10C550"),
    Callback = function()
        safeSend(State.chatMessage)
        WindUI:Notify({
            Title = "Тест отправки",
            Content = "Сообщение отправлено: " .. State.chatMessage,
            Icon = "lucide:check",
        })
    end
})

-- ════════════════════════════════════════════════════════════════
-- ВКЛАДКА: NAME
-- ════════════════════════════════════════════════════════════════
local NameTab = Window:Tab({
    Title = "Name",
    Icon = "lucide:user-round",
    IconColor = Color3.fromHex("#7775F2"),
    Border = true,
})

-- Username Section
local UsernameSection = NameTab:Section({
    Title = "Username (@username)",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

UsernameSection:Input({
    Flag = "GameUsername",
    Title = "Username",
    Icon = "lucide:at-sign",
    Value = State.gameUsername,
    Placeholder = "Без @...",
    Callback = function(value)
        State.gameUsername = value
        if State.usernameChangerEnabled then
            applyAllNameChanges()
        end
    end
})

UsernameSection:Space()

UsernameSection:Toggle({
    Flag = "UsernameChangerEnabled",
    Title = "Включить Username Changer",
    Value = State.usernameChangerEnabled,
    Callback = function(value)
        State.usernameChangerEnabled = value
        applyAllNameChanges()
    end
})

NameTab:Space()

-- DisplayName Section
local DisplayNameSection = NameTab:Section({
    Title = "DisplayName (главное имя)",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

DisplayNameSection:Input({
    Flag = "GameDisplayName",
    Title = "DisplayName",
    Icon = "lucide:user",
    Value = State.gameDisplayName,
    Placeholder = "Новый DisplayName...",
    Callback = function(value)
        State.gameDisplayName = value
        if State.displayNameChangerEnabled then
            applyAllNameChanges()
        end
    end
})

DisplayNameSection:Space()

DisplayNameSection:Toggle({
    Flag = "DisplayNameChangerEnabled",
    Title = "Включить DisplayName Changer",
    Value = State.displayNameChangerEnabled,
    Callback = function(value)
        State.displayNameChangerEnabled = value
        applyAllNameChanges()
    end
})

NameTab:Space()

-- Rank Section
local RankSection = NameTab:Section({
    Title = "Rank (звание/статус)",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

RankSection:Input({
    Flag = "GameRank",
    Title = "Rank",
    Icon = "lucide:crown",
    Value = State.gameRank,
    Placeholder = "Новый Rank...",
    Callback = function(value)
        State.gameRank = value
        if State.rankChangerEnabled then
            applyAllNameChanges()
        end
    end
})

RankSection:Space()

RankSection:Toggle({
    Flag = "RankChangerEnabled",
    Title = "Включить Rank Changer",
    Value = State.rankChangerEnabled,
    Callback = function(value)
        State.rankChangerEnabled = value
        applyAllNameChanges()
    end
})

NameTab:Space()

-- Apply Button
NameTab:Button({
    Title = "Применить все изменения имени",
    Icon = "lucide:check",
    Justify = "Center",
    Color = Color3.fromHex("#7775F2"),
    Callback = function()
        applyAllNameChanges()
        WindUI:Notify({
            Title = "Имя обновлено",
            Content = "Все изменения применены!",
            Icon = "lucide:check",
        })
    end
})

NameTab:Space()

-- Custom Color Section
local CustomColorSection = NameTab:Section({
    Title = "Кастомный цвет имени",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

CustomColorSection:Colorpicker({
    Flag = "RainbowCustomColor",
    Title = "Цвет имени",
    Default = State.rainbowCustomColor,
    Callback = function(color)
        State.rainbowCustomColor = color
        State.rainbowUseCustomColor = true
        State.rainbowEnabled = false
    end
})

CustomColorSection:Space()

CustomColorSection:Toggle({
    Flag = "RainbowUseCustomColor",
    Title = "Использовать кастомный цвет",
    Value = State.rainbowUseCustomColor,
    Callback = function(value)
        State.rainbowUseCustomColor = value
        State.rainbowEnabled = false
    end
})

NameTab:Space()

-- Rainbow Section
local RainbowSection = NameTab:Section({
    Title = "Rainbow эффект",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

RainbowSection:Slider({
    Flag = "RainbowSpeed",
    Title = "Скорость радуги",
    Step = 0.1,
    IsTooltip = true,
    Value = {
        Min = 0.1,
        Max = 5,
        Default = State.rainbowSpeed,
    },
    Callback = function(value)
        State.rainbowSpeed = value
    end
})

RainbowSection:Space()

RainbowSection:Toggle({
    Flag = "RainbowEnabled",
    Title = "Включить LGBT режим",
    Desc = "Радужное имя",
    Value = State.rainbowEnabled,
    Callback = function(value)
        State.rainbowEnabled = value
        State.rainbowUseCustomColor = false
    end
})

-- ════════════════════════════════════════════════════════════════
-- ВКЛАДКА: AVATAR
-- ════════════════════════════════════════════════════════════════
local AvatarTab = Window:Tab({
    Title = "Avatar",
    Icon = "lucide:user-round-cog",
    IconColor = Color3.fromHex("#ECA201"),
    Border = true,
})

AvatarTab:Section({
    Title = "Avatar Changer",
    TextSize = 18,
})

AvatarTab:Input({
    Flag = "AvatarUsername",
    Title = "Username игрока",
    Icon = "lucide:user-search",
    Value = State.avatarUsername,
    Placeholder = "Введи имя игрока...",
    Callback = function(value)
        State.avatarUsername = value
    end
})

AvatarTab:Space()

AvatarTab:Button({
    Title = "Применить аватар",
    Icon = "lucide:user-round-check",
    Justify = "Center",
    Color = Color3.fromHex("#ECA201"),
    Callback = function()
        if State.avatarUsername == "" then
            WindUI:Notify({
                Title = "Ошибка",
                Content = "Введи имя игрока!",
                Icon = "lucide:x",
            })
            return
        end
        
        local target = findPlayerByName(State.avatarUsername)
        if target then
            State.savedAvatarUsername = target.Name or State.avatarUsername
            morphToPlayer(target)
            
            WindUI:Notify({
                Title = "Скин применён!",
                Content = "Скин игрока \"" .. (target.Name or State.avatarUsername) .. "\" установлен.",
                Icon = "lucide:check",
            })
        else
            WindUI:Notify({
                Title = "Игрок не найден",
                Content = "Не удалось найти игрока",
                Icon = "lucide:x",
            })
        end
    end
})

AvatarTab:Space()

AvatarTab:Toggle({
    Flag = "AvatarAutoApply",
    Title = "Auto Apply при респавне",
    Desc = "Автоматически применяет аватар после смерти",
    Value = State.avatarAutoApply,
    Callback = function(value)
        State.avatarAutoApply = value
    end
})

-- ════════════════════════════════════════════════════════════════
-- ВКЛАДКА: UI
-- ════════════════════════════════════════════════════════════════
local UITab = Window:Tab({
    Title = "UI",
    Icon = "lucide:eye-off",
    IconColor = Color3.fromHex("#257AF7"),
    Border = true,
})

UITab:Section({
    Title = "Скрытие элементов интерфейса",
    TextSize = 18,
})

UITab:Toggle({
    Flag = "HideIngameUI",
    Title = "Скрыть игровой UI",
    Desc = "Скрывает карту, меню и topbar",
    Value = State.uiHidden,
    Callback = function(value)
        State.uiHidden = value
        toggleGameUI()
    end
})

UITab:Space()

UITab:Toggle({
    Flag = "HideKillfeed",
    Title = "Скрыть килфид",
    Desc = "Скрывает список убийств",
    Value = State.killfeedHidden,
    Callback = function(value)
        State.killfeedHidden = value
        toggleKillfeed()
    end
})

UITab:Space()

UITab:Section({
    Title = "Custom Killfeed",
    TextSize = 18,
})

UITab:Toggle({
    Flag = "GlobalKillfeedEnabled",
    Title = "Показывать кастомный килфид",
    Desc = "Свой килфид справа сверху",
    Value = State.globalKillfeedEnabled,
    Callback = function(value)
        State.globalKillfeedEnabled = value
    end
})

UITab:Space()

UITab:Section({
    Title = "Custom HP Bar",
    TextSize = 18,
})

UITab:Toggle({
    Flag = "HPBarEnabled",
    Title = "Показывать HP Bar (CS:GO стиль)",
    Desc = "Показ здоровья слева снизу",
    Value = State.hpBarEnabled,
    Callback = function(value)
        State.hpBarEnabled = value
    end
})

UITab:Space()

UITab:Colorpicker({
    Flag = "HPBarColor",
    Title = "Цвет HP Bar",
    Default = State.hpBarColor,
    Callback = function(color)
        State.hpBarColor = color
    end
})

UITab:Space()

UITab:Section({
    Title = "Управление меню",
    TextSize = 18,
})

UITab:Keybind({
    Flag = "MenuKeybind",
    Title = "Клавиша открытия меню",
    Value = State.menuKeybind,
    Callback = function(value)
        State.menuKeybind = value
        Window:SetToggleKey(Enum.KeyCode[value])
    end
})

UITab:Section({
    Title = "Kill Notifier",
    TextSize = 18,
})

UITab:Toggle({
    Flag = "KillNotifierEnabled",
    Title = "Показывать уведомление",
    Desc = "Ник умершего 'died' зеленым цветом",
    Value = State.killNotifierEnabled,
    Callback = function(value)
        State.killNotifierEnabled = value
    end
})

UITab:Slider({
    Flag = "KillNotifierDuration",
    Title = "Время отображения",
    Step = 0.5,
    Value = {
        Min = 1,
        Max = 10,
        Default = 3,
    },
    Callback = function(value)
        State.killNotifierDuration = value
    end
})

-- ════════════════════════════════════════════════════════════════
-- ВКЛАДКА: MISC
-- ════════════════════════════════════════════════════════════════
local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "lucide:layers",
    Border = true,
})

MiscTab:Section({
    Title = "Окружение (Time Control)",
})

MiscTab:Toggle({
    Flag = "FreezeTime",
    Title = "Заморозить время",
    Desc = "Удерживает выбранное время суток",
    Value = State.freezeTime,
    Callback = function(value)
        State.freezeTime = value
        if value then
            Lighting.ClockTime = State.customTime
        end
    end
})

MiscTab:Slider({
    Flag = "CustomTime",
    Title = "Установить время",
    Step = 0.1,
    Value = {
        Min = 0,
        Max = 24,
        Default = State.customTime,
    },
    Callback = function(value)
        State.customTime = value
        if State.freezeTime then
            Lighting.ClockTime = value
        end
    end
})

-- ════════════════════════════════════════════════════════════════
-- ВКЛАДКА: ACS ADVANCED
-- ════════════════════════════════════════════════════════════════
local ACSTab = Window:Tab({
    Title = "ACS Advanced",
    Icon = "lucide:crosshair",
    IconColor = Color3.fromHex("#FF5050"),
    Border = true,
})

-- Проверка совместимости
local supportedFeatures, unsupportedFeatures = getACSSupport()

ACSTab:Section({
    Title = "Совместимость. Тестировалось на Velocity 0.7.8. Может не работать на Xeno",
    TextSize = 18,
})

for _, feature in ipairs(supportedFeatures) do
    ACSTab:Paragraph({
        Title = feature,
        Content = "",
    })
end

if #unsupportedFeatures > 0 then
    ACSTab:Space()
    for _, feature in ipairs(unsupportedFeatures) do
        ACSTab:Paragraph({
            Title = feature,
            Content = "",
        })
    end
end

ACSTab:Space()

-- ════════════════════════════════════════════════════════════════
-- ГРУППА: ОРУЖИЕ
-- ════════════════════════════════════════════════════════════════
ACSTab:Section({
    Title = "Оружие",
    TextSize = 16,
})

local WeaponGroup = ACSTab:Group()

WeaponGroup:Button({
    Flag = "ACSAnimPatch",
    Title = State.acsAnimPatchApplied and "✓ Анимации ускорены" or "Ускорить доставание",
    Desc = "Патч анимаций",
    Icon = "lucide:zap",
    Justify = "Left",
    Color = State.acsAnimPatchApplied and Color3.fromHex("#10C550") or Color3.fromHex("#FF5050"),
    Callback = function()
        if State.acsAnimPatchApplied then
            WindUI:Notify({
                Title = "Уже применено",
                Content = "Патч анимаций уже активен!",
                Icon = "lucide:info",
            })
            return
        end
        
        if not ExecutorCapabilities.hookfunction then
            WindUI:Notify({
                Title = "Не поддерживается",
                Content = "Твой экзекутор не поддерживает hookfunction",
                Icon = "lucide:x",
            })
            return
        end
        
        local success, err = pcall(function()
            local gunsList = {
                "AWP", "Barrett M82", "Kar98K", "Remington MSR",
                "M200 Intervention", "M1903 Springfield", "M40 Sniper"
            }
            
            for _, gunName in pairs(gunsList) do
                if player.Backpack:FindFirstChild(gunName) or 
                   (player.Character and player.Character:FindFirstChild(gunName)) then
                    error("Сначала убери " .. gunName .. " из инвентаря!")
                end
            end
            
            local targetModules = {}
            for _, gunName in pairs(gunsList) do
                local path = ReplicatedStorage.Configurations.ACS_Guns:FindFirstChild(gunName)
                if path and path:FindFirstChild("Animations") then
                    targetModules[path.Animations] = true
                end
            end
            
            local oldRequire
            oldRequire = hookfunction(require, function(module)
                local result = oldRequire(module)
                
                if targetModules[module] and type(result) == "table" then
                    result["EquipAnim"] = function(_, _, p4)
                        local ts = TweenService
                        
                        ts:Create(p4[2], TweenInfo.new(0), {
                            ["C1"] = CFrame.new(-0.875, -0.2, -1.25) * CFrame.Angles(-1.0471975511965976, 0, 0)
                        }):Play()
                        ts:Create(p4[3], TweenInfo.new(0), {
                            ["C1"] = CFrame.new(1.2, -0.05, -1.65) * CFrame.Angles(-1.5707963267948966, 0.6108652381980153, -0.4363323129985824)
                        }):Play()
                        
                        task.wait(0.1)
                        
                        local settings = require(module.Parent.Settings)
                        ts:Create(p4[2], TweenInfo.new(0.4), { ["C1"] = settings.RightPos }):Play()
                        ts:Create(p4[3], TweenInfo.new(0.4), { ["C1"] = settings.LeftPos }):Play()
                        
                        task.wait(0.4)
                    end
                end
                
                return result
            end)
            
            State.acsAnimPatchApplied = true
        end)
        
        if success then
            WindUI:Notify({
                Title = "Патч применен",
                Content = "Анимации доставания ускорены!",
                Icon = "lucide:check",
            })
        else
            WindUI:Notify({
                Title = "Ошибка",
                Content = tostring(err),
                Icon = "lucide:alert-triangle",
            })
        end
    end
})

WeaponGroup:Space()

WeaponGroup:Button({
    Flag = "ACSAmmoPatch",
    Title = State.acsAmmoPatchApplied and "✓ Патроны бесконечные" or "Бесконечные патроны",
    Desc = "inf ammo",
    Icon = "lucide:infinity",
    Justify = "Left",
    Color = State.acsAmmoPatchApplied and Color3.fromHex("#10C550") or Color3.fromHex("#FF5050"),
    Callback = function()
        if State.acsAmmoPatchApplied then return end
        
        if not (ExecutorCapabilities.hookmetamethod and ExecutorCapabilities.newcclosure) then
            WindUI:Notify({Title = "Ошибка", Content = "Экзекутор не поддерживает хуки", Icon = "lucide:x"})
            return
        end
        
        local success, err = pcall(function()
            local targetGuns = {
                ["Remington MSR"] = true, ["M40 Sniper"] = true, ["Kar98K"] = true,
                ["AWP"] = true, ["Barrett M82"] = true, ["M200 Intervention"] = true,
                ["M1903 Springfield"] = true
            }
            
            -- Безопасное число, которое ACS не сломает
            -- Большинство UI в Roblox превращают 2^63 в "inf" или просто не могут его уменьшить
            local safeInf = 999999999 

            local oldIndex
            oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, index)
                if not checkcaller() then
                    if index == "Value" and self.Name == "Ammo" then
                        if self.Parent and targetGuns[self.Parent.Name] then
                            return safeInf
                        end
                    end
                    
                    if index == "Ammo" and self.Name == "Settings" then
                        if self.Parent and targetGuns[self.Parent.Name] then
                            return safeInf
                        end
                    end
                end
                return oldIndex(self, index)
            end))
            
            State.acsAmmoPatchApplied = true
        end)
        
        if success then
            WindUI:Notify({Title = "ACS", Content = "Безопасный бесконечный боезапас включен!", Icon = "lucide:check"})
        else
            warn("Ошибка патронов: " .. tostring(err))
        end
    end
})

ACSTab:Space()

-- ════════════════════════════════════════════════════════════════
-- ГРУППА: ПЕРСОНАЖ
-- ════════════════════════════════════════════════════════════════
ACSTab:Section({
    Title = "Персонаж",
    TextSize = 16,
})

local CharacterGroup = ACSTab:Group()

CharacterGroup:Button({
    Flag = "ACSMedPatch",
    Title = State.acsMedPatchApplied and "✓ Медицина на ходу" or "Медицина на ходу",
    Desc = "Позволяет хилиться без остановки",
    Icon = "lucide:heart-pulse",
    Justify = "Left",
    Color = State.acsMedPatchApplied and Color3.fromHex("#10C550") or Color3.fromHex("#FF5050"),
    Callback = function()
        if State.acsMedPatchApplied then
            WindUI:Notify({
                Title = "Уже применено",
                Content = "Патч медицины уже активен!",
                Icon = "lucide:info",
            })
            return
        end
        
        if not (ExecutorCapabilities.getrawmetatable and ExecutorCapabilities.setreadonly) then
            WindUI:Notify({
                Title = "Не поддерживается",
                Content = "Твой экзекутор не поддерживает getrawmetatable",
                Icon = "lucide:x",
            })
            return
        end
        
        local success, err = pcall(function()
            local function patchCharacter(char)
                local hum = char:WaitForChild("Humanoid", 10)
                if not hum then return end
                
                char.AttributeChanged:Connect(function(attr)
                    if attr == "NoMovement" and char:GetAttribute("NoMovement") == true then
                        char:SetAttribute("NoMovement", false)
                    end
                end)
                
                local mt = getrawmetatable(game)
                local oldNewIndex = mt.__newindex
                setreadonly(mt, false)
                
                mt.__newindex = newcclosure(function(t, k, v)
                    if not checkcaller() and t == hum then
                        if (k == "WalkSpeed" and v == 0) or (k == "JumpPower" and v == 0) then
                            return
                        end
                    end
                    return oldNewIndex(t, k, v)
                end)
                setreadonly(mt, true)
            end
            
            if player.Character then patchCharacter(player.Character) end
            player.CharacterAdded:Connect(patchCharacter)
            
            State.acsMedPatchApplied = true
        end)
        
        if success then
            WindUI:Notify({
                Title = "Патч применен",
                Content = "Теперь можно хилиться в движении!",
                Icon = "lucide:check",
            })
        else
            WindUI:Notify({
                Title = "Ошибка",
                Content = tostring(err),
                Icon = "lucide:alert-triangle",
            })
        end
    end
})

ACSTab:Space()

-- ════════════════════════════════════════════════════════════════
-- ГРУППА: АУДИО
-- ════════════════════════════════════════════════════════════════
ACSTab:Section({
    Title = "Аудио",
    TextSize = 16,
})

local AudioGroup = ACSTab:Group()

AudioGroup:Button({
    Flag = "ACSHitSound",
    Title = State.acsHitSoundEnabled and "✓ HitSound активен" or "Включить кастомный HitSound",
    Desc = "Замена звука попадания (требуется workspace/hit_sound/head.mp3)",
    Icon = "lucide:volume-2",
    Justify = "Left",
    Color = State.acsHitSoundEnabled and Color3.fromHex("#10C550") or Color3.fromHex("#FF5050"),
    Callback = function()
        if State.acsHitSoundEnabled then
            WindUI:Notify({
                Title = "Уже активен",
                Content = "HitSound уже включен! Требуется перезагрузка для отключения",
                Icon = "lucide:info",
            })
            return
        end
        
        if not ExecutorCapabilities.getcustomasset then
            WindUI:Notify({
                Title = "Не поддерживается",
                Content = "Твой экзекутор не поддерживает getcustomasset",
                Icon = "lucide:x",
            })
            return
        end
        
        local success, err = pcall(function()
            local CUSTOM_SOUND_FILE = "head.mp3"
            local SOUNDS_FOLDER = "hit_sound"
            _G.HitmarkerVolume = _G.HitmarkerVolume or 1.5
            
            local MIN_DIST = 50
            local MAX_DIST = 200
            
            local function getAsset(path)
                if not isfile or not isfile(path) then return nil end
                local func = getcustomasset or getsynasset
                if type(func) == "function" then
                    return func(path)
                end
                return nil
            end
            
            local myId = getAsset(SOUNDS_FOLDER .. "/" .. CUSTOM_SOUND_FILE) or getAsset(CUSTOM_SOUND_FILE)
            
            local BANNED_IDS = {
                ["363818432"] = true, ["363818488"] = true, ["363818567"] = true,
                ["363818611"] = true, ["363818653"] = true
            }
            
            local function handleSound(sound)
                if not sound:IsA("Sound") then return end
                
                task.spawn(function()
                    local id = sound.SoundId:match("%d+")
                    
                    if id and BANNED_IDS[id] then
                        sound.Volume = 0
                        sound:Stop()
                        
                        if myId then
                            local newSound = Instance.new("Sound")
                            newSound.SoundId = myId
                            newSound.Volume = _G.HitmarkerVolume
                            newSound.RollOffMinDistance = MIN_DIST
                            newSound.RollOffMaxDistance = MAX_DIST
                            
                            newSound.Parent = sound.Parent or SoundService
                            newSound:Play()
                            
                            Debris:AddItem(newSound, 2)
                        end
                        
                        task.wait(0.1)
                        if sound then sound:Destroy() end
                    end
                end)
            end
            
            game.DescendantAdded:Connect(handleSound)
            State.acsHitSoundEnabled = true
        end)
        
        if success then
            WindUI:Notify({
                Title = "HitSound активирован",
                Content = "Кастомный звук попадания включен!",
                Icon = "lucide:volume-2",
            })
        else
            WindUI:Notify({
                Title = "Ошибка",
                Content = tostring(err),
                Icon = "lucide:alert-triangle",
            })
        end
    end
})


-- ════════════════════════════════════════════════════════════════
-- ВКЛАДКА: CONFIG
-- ════════════════════════════════════════════════════════════════
local ConfigTab = Window:Tab({
    Title = "Config",
    Icon = "lucide:settings",
    IconColor = Color3.fromHex("#83889E"),
    Border = true,
})

local ConfigManager = Window.ConfigManager
local ConfigName = "default"

ConfigTab:Section({
    Title = "Система конфигов",
    TextSize = 18,
})

local ConfigNameInput = ConfigTab:Input({
    Title = "Название конфига",
    Icon = "lucide:file-cog",
    Value = ConfigName,
    Callback = function(value)
        ConfigName = value
    end
})

ConfigTab:Space()

local AllConfigs = ConfigManager:AllConfigs()
local DefaultValue = table.find(AllConfigs, ConfigName) and ConfigName or nil

local AllConfigsDropdown = ConfigTab:Dropdown({
    Title = "Выбрать конфиг",
    Desc = "Выбери существующий конфиг",
    Values = AllConfigs,
    Value = DefaultValue,
    Callback = function(value)
        ConfigName = value
        ConfigNameInput:Set(value)
    end
})

ConfigTab:Space()

local ConfigButtonsGroup = ConfigTab:Group()

ConfigButtonsGroup:Button({
    Title = "Загрузить",
    Icon = "lucide:download",
    Justify = "Center",
    Color = Color3.fromHex("#10C550"),
    Callback = function()
        Window.CurrentConfig = ConfigManager:CreateConfig(ConfigName)
        if Window.CurrentConfig:Load() then
            WindUI:Notify({
                Title = "Конфиг загружен",
                Content = "Конфиг '" .. ConfigName .. "' успешно загружен",
                Icon = "lucide:check",
            })
        end
        
        AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
    end
})

ConfigButtonsGroup:Space()

ConfigButtonsGroup:Button({
    Title = "Сохранить",
    Icon = "lucide:save",
    Justify = "Center",
    Color = Color3.fromHex("#257AF7"),
    Callback = function()
        Window.CurrentConfig = ConfigManager:Config(ConfigName)
        if Window.CurrentConfig:Save() then
            WindUI:Notify({
                Title = "Конфиг сохранён",
                Content = "Конфиг '" .. ConfigName .. "' успешно сохранён",
                Icon = "lucide:check",
            })
        end
        
        AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
    end
})

ConfigTab:Space()

ConfigTab:Button({
    Title = "Создать новый конфиг",
    Icon = "lucide:file-plus",
    Justify = "Center",
    Callback = function()
        if ConfigName == "" then
            WindUI:Notify({
                Title = "Ошибка",
                Content = "Введи название конфига!",
                Icon = "lucide:x",
            })
            return
        end
        
        Window.CurrentConfig = ConfigManager:Config(ConfigName)
        Window.CurrentConfig:Save()
        
        WindUI:Notify({
            Title = "Конфиг создан",
            Content = "Конфиг '" .. ConfigName .. "' создан!",
            Icon = "lucide:check",
        })
        
        AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
    end
})

-- ════════════════════════════════════════════════════════════════
-- ОПТИМИЗИРОВАННЫЕ СИСТЕМНЫЕ ЦИКЛЫ
-- ════════════════════════════════════════════════════════════════

-- Управление временем
addConnection("TimeControl", RunService.Heartbeat:Connect(function()
    if not State._running or not State.freezeTime then return end
    pcall(function()
        Lighting.ClockTime = State.customTime
    end)
end))

-- Rainbow эффект
addConnection("RainbowLoop", RunService.RenderStepped:Connect(function()
    if not State._running then return end
    
    pcall(function()
        local char = player.Character
        if not char then return end
        
        local head = char:FindFirstChild("Head")
        if not head then return end
        
        local nameTag = head:FindFirstChild("NameTag")
        if not nameTag then return end
        
        local usernameLabel = nameTag:FindFirstChild("Username")
        if not usernameLabel or not usernameLabel:IsA("TextLabel") then return end
        
        if State.rainbowEnabled then
            local hue = (tick() * State.rainbowSpeed * 50) % 360
            usernameLabel.TextColor3 = Color3.fromHSV(hue / 360, 1, 1)
        elseif State.rainbowUseCustomColor then
            usernameLabel.TextColor3 = State.rainbowCustomColor
        end
    end)
end))

-- HP Bar и Killfeed видимость
addConnection("UIUpdate", RunService.RenderStepped:Connect(function()
    if not State._running then return end
    
    pcall(function()
        HPBack.Visible = State.hpBarEnabled
        KillfeedContainer.Visible = State.globalKillfeedEnabled
        
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        
        if hum then
            local hp = math.floor(hum.Health)
            HPLabel.Text = tostring(hp)
            HPLabel.TextColor3 = State.hpBarColor
            HPIcon.TextColor3 = State.hpBarColor
        end
    end)
end))

-- Автоматическое скрытие UI
task.spawn(function()
    while State._running do
        pcall(function()
            task.wait(3)
            
            if not State._running then return end
            
            if State.uiHidden then
                local success, ui = pcall(function()
                    return player.PlayerGui:WaitForChild("UI", 1):WaitForChild("Container", 1):WaitForChild("HUD", 1)
                end)
                
                if success and ui then
                    local map = ui:FindFirstChild("Map")
                    local menu = ui:FindFirstChild("Menu")
                    local topbar = ui:FindFirstChild("Topbar")
                    
                    if map and map.Visible then map.Visible = false end
                    if menu and menu.Visible then menu.Visible = false end
                    if topbar and topbar.Visible then topbar.Visible = false end
                end
            end
            
            if State.killfeedHidden then
                local success, killfeed = pcall(function()
                    return player.PlayerGui:WaitForChild("UI", 1):WaitForChild("Container", 1):WaitForChild("HUD", 1):WaitForChild("Killfeed", 1)
                end)
                
                if success and killfeed and killfeed.Visible then
                    killfeed.Visible = false
                end
            end
        end)
    end
end)

-- ════════════════════════════════════════════════════════════════
-- СИСТЕМА KILLFEED
-- ════════════════════════════════════════════════════════════════
local function createKillEntry(killer, victim)
    if not State.globalKillfeedEnabled or not State._running then return end
    
    pcall(function()
        local isMyKill = (killer == player.DisplayName or killer == player.Name)
        
        local tempText = Instance.new("TextLabel")
        tempText.Font = Enum.Font.GothamMedium
        tempText.TextSize = 15
        tempText.RichText = true
        tempText.Text = string.format("<b>%s</b> <font color='#888888'>></font> <b>%s</b>", killer, victim)
        tempText.Parent = CoreGui
        
        local textWidth = tempText.TextBounds.X
        tempText:Destroy()
        
        local entry = Instance.new("Frame")
        entry.Size = UDim2.new(0, textWidth + 20, 0, 24)
        entry.BackgroundColor3 = Color3.new(0, 0, 0)
        entry.BackgroundTransparency = 0.7
        entry.BorderSizePixel = 0
        entry.Parent = KillfeedContainer
        
        Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 4)
        
        if isMyKill then
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(255, 50, 50)
            stroke.Thickness = 2
            stroke.Parent = entry
        end

        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, -10, 1, 0)
        text.Position = UDim2.new(0, 5, 0, 0)
        text.BackgroundTransparency = 1
        text.Font = Enum.Font.GothamMedium
        text.TextColor3 = Color3.new(1, 1, 1)
        text.TextSize = 15
        text.TextStrokeTransparency = 0
        text.TextStrokeColor3 = Color3.new(0, 0, 0)
        text.RichText = true
        text.TextXAlignment = Enum.TextXAlignment.Right
        text.Text = string.format("<b>%s</b> <font color='#888888'>></font> <b>%s</b>", killer, victim)
        text.Parent = entry

        if isMyKill and State.chatEnabled then
            safeSend(State.chatMessage)
        end

        task.delay(5, function()
            if not entry or not entry.Parent then return end
            
            pcall(function()
                TweenService:Create(entry, TweenInfo.new(0.5), {BackgroundTransparency = 1, Size = UDim2.new(0,0,0,0)}):Play()
                TweenService:Create(text, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
            end)
            
            task.wait(0.5)
            
            pcall(function()
                if entry and entry.Parent then
                    entry:Destroy()
                end
            end)
        end)
    end)
end

-- Подключение к игровому killfeed
task.spawn(function()
    local success, gameKillfeed = pcall(function()
        local pg = player:WaitForChild("PlayerGui", 10)
        local ui = pg:WaitForChild("UI", 10)
        local container = ui:WaitForChild("Container", 10)
        local hud = container:WaitForChild("HUD", 10)
        local killfeed = hud:WaitForChild("Killfeed", 10)
        return killfeed:WaitForChild("Feed", 10)
    end)
    
    if success and gameKillfeed then
        addConnection("KillfeedWatch", gameKillfeed.ChildAdded:Connect(function(child)
            if not State._running then return end
            
            pcall(function()
                local killerLabel = child:WaitForChild("Killer", 2)
                local victimLabel = child:WaitForChild("Died", 2)
                
                if killerLabel and victimLabel then
                    createKillEntry(killerLabel.Text, victimLabel.Text)
                end
            end)
        end))
    end
end)

-- ════════════════════════════════════════════════════════════════
-- АВТОМАТИЧЕСКОЕ ПРИМЕНЕНИЕ ПРИ РЕСПАВНЕ
-- ════════════════════════════════════════════════════════════════
addConnection("CharacterAdded", player.CharacterAdded:Connect(function(char)
    pcall(function()
        char:WaitForChild("HumanoidRootPart", 10)
        char:WaitForChild("Head", 10)
        
        task.wait(0.5)
        
        if State.avatarAutoApply and State.savedAvatarUsername ~= "" then
            local target = findPlayerByName(State.savedAvatarUsername)
            if target then
                morphToPlayer(target)
                task.wait(0.2)
            end
        end
        
        applyAllNameChanges()
    end)
end))

-- ════════════════════════════════════════════════════════════════
-- ЗАЩИТА ОТ УТЕЧЕК ПАМЯТИ
-- ════════════════════════════════════════════════════════════════
CoreGui.DescendantRemoving:Connect(function(obj)
    if obj == CustomUI then
        State._running = false
        cleanupConnections()
    end
end)

-- ════════════════════════════════════════════════════════════════
-- ЗАВЕРШЕНИЕ ЗАГРУЗКИ
-- ════════════════════════════════════════════════════════════════
WindUI:Notify({
    Title = "DCPHub загружен!",
    Content = "Скрипт успешно инициализирован. Нажми " .. State.menuKeybind .. " чтобы открыть меню",
    Icon = "lucide:check-circle",
    Duration = 5,
})

print("═══════════════════════════════════════════════")
print("ДЦП ХАБ v1.1 - ОПТИМИЗИРОВАННАЯ ВЕРСИЯ")
print("Все системы защиты активны")
print("Наслаждайся!")
print("═══════════════════════════════════════════════")
