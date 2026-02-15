-- ════════════════════════════════════════════════════════════════
-- VeloHub 2.0 - Оптимизированная версия
-- ════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════
-- ЗАЩИТА ОТ ПОВТОРНОГО ЗАПУСКА
-- ════════════════════════════════════════════════════════════════
if _G.VeloHubLoaded then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "⚠️ Уже запущено!",
            Text = "VeloHub уже активен",
            Duration = 3,
        })
    end)
    return
end

_G.VeloHubLoaded = true

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
-- ЛОКАЛЬНОЕ СОСТОЯНИЕ (для циклов)
-- ════════════════════════════════════════════════════════════════
local Settings = {
    FreezeTime = false,
    CustomTime = 12,
    RainbowEnabled = false,
    RainbowSpeed = 1,
    RainbowUseCustomColor = false,
    RainbowCustomColor = Color3.fromRGB(255, 80, 80),
    HideParachuteEnabled = false,
    HPBarEnabled = false,
    HPBarColor = Color3.fromRGB(0, 255, 0),
    GlobalKillfeedEnabled = true,
    HideIngameUI = false,
    HideKillfeed = false,
    GameDisplayName = "",
    GameUsername = "",
    GameRank = "",
    ChatEnabled = false,
    ChatMessage = "workby!88!",
    AvatarUsername = "",
    AvatarAutoApply = false,
	ACSRecoilEnabled = false,
    ACSGunName = "",
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
        
        if usernameLabel and usernameLabel:IsA("TextLabel") and displayName ~= "" then
            usernameLabel.Text = displayName
        end
        
        if displayLabel and displayLabel:IsA("TextLabel") and username ~= "" then
            local formattedUsername = username
            if not formattedUsername:match("^@") then
                formattedUsername = "@" .. formattedUsername
            end
            displayLabel.Text = formattedUsername
        end
        
        if rankLabel and rankLabel:IsA("TextLabel") then
            rankLabel.Text = rank or ""
        end
    end)
end

-- Применение всех настроек имени
local function applyAllNameChanges(displayName, username, rank)
    task.wait(0.5)
    changeNameTag(displayName, username, rank)
end

-- Скрытие UI элементов
local function toggleGameUI(hidden)
    pcall(function()
        local ui = player.PlayerGui:WaitForChild("UI", 2):WaitForChild("Container", 2):WaitForChild("HUD", 2)
        if not ui then return end
        
        local map = ui:FindFirstChild("Map")
        local menu = ui:FindFirstChild("Menu")
        local topbar = ui:FindFirstChild("Topbar")
        
        if map then map.Visible = not hidden end
        if menu then menu.Visible = not hidden end
        if topbar then topbar.Visible = not hidden end
    end)
end

-- Скрытие killfeed
local function toggleKillfeed(hidden)
    pcall(function()
        local killfeed = player.PlayerGui:WaitForChild("UI", 2):WaitForChild("Container", 2):WaitForChild("HUD", 2):WaitForChild("Killfeed", 2)
        if killfeed then
            killfeed.Visible = not hidden
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
    Title = "VeloHub 2.0  |  by .alowyy1",
    Folder = "velohub",
    Icon = "lucide:messages-square",
    NewElements = true,
    HideSearchBar = false,
    
    OpenButton = {
        Title = "Open VeloHub",
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
    Title = "v2.0",
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
    Value = "workby!88!",
    Placeholder = "Введи сообщение...",
    Callback = function(value)
        Settings.ChatMessage = value
    end
})

ChatTab:Space()

ChatTab:Input({
    Flag = "OriginalDisplayName",
    Title = "Твой родной DisplayName",
    Icon = "lucide:user",
    Value = player.DisplayName ~= "" and player.DisplayName or player.Name,
    Placeholder = "DisplayName...",
})

ChatTab:Space()

ChatTab:Toggle({
    Flag = "ChatEnabled",
    Title = "Включить чат при убийстве",
    Desc = "Автоматически отправляет сообщение когда ты убиваешь",
    Value = false,
    Callback = function(value)
        Settings.ChatEnabled = value
    end
})

ChatTab:Space()

ChatTab:Button({
    Title = "Протестировать сообщение",
    Icon = "lucide:send",
    Justify = "Center",
    Color = Color3.fromHex("#10C550"),
    Callback = function()
        safeSend(Settings.ChatMessage)
        WindUI:Notify({
            Title = "Тест отправки",
            Content = "Сообщение отправлено: " .. Settings.ChatMessage,
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
    Value = "",
    Placeholder = "Без @...",
    Callback = function(value)
        Settings.GameUsername = value
    end
})

UsernameSection:Space()

UsernameSection:Toggle({
    Flag = "UsernameChangerEnabled",
    Title = "Включить Username Changer",
    Value = false,
})

NameTab:Space()

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
    Value = "",
    Placeholder = "Новый DisplayName...",
    Callback = function(value)
        Settings.GameDisplayName = value
    end
})

DisplayNameSection:Space()

DisplayNameSection:Toggle({
    Flag = "DisplayNameChangerEnabled",
    Title = "Включить DisplayName Changer",
    Value = false,
})

NameTab:Space()

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
    Value = "",
    Placeholder = "Новый Rank...",
    Callback = function(value)
        Settings.GameRank = value
    end
})

RankSection:Space()

RankSection:Toggle({
    Flag = "RankChangerEnabled",
    Title = "Включить Rank Changer",
    Value = false,
})

NameTab:Space()

NameTab:Button({
    Title = "Применить все изменения имени",
    Icon = "lucide:check",
    Justify = "Center",
    Color = Color3.fromHex("#7775F2"),
    Callback = function()
        applyAllNameChanges(Settings.GameDisplayName, Settings.GameUsername, Settings.GameRank)
        WindUI:Notify({
            Title = "Имя обновлено",
            Content = "Все изменения применены!",
            Icon = "lucide:check",
        })
    end
})

NameTab:Space()

local CustomColorSection = NameTab:Section({
    Title = "Кастомный цвет имени",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

CustomColorSection:Colorpicker({
    Flag = "RainbowCustomColor",
    Title = "Цвет имени",
    Default = Color3.fromRGB(255, 80, 80),
    Callback = function(color)
        Settings.RainbowCustomColor = color
        Settings.RainbowUseCustomColor = true
        Settings.RainbowEnabled = false
    end
})

CustomColorSection:Space()

CustomColorSection:Toggle({
    Flag = "RainbowUseCustomColor",
    Title = "Использовать кастомный цвет",
    Value = false,
    Callback = function(value)
        Settings.RainbowUseCustomColor = value
        Settings.RainbowEnabled = false
    end
})

NameTab:Space()

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
        Default = 1,
    },
    Callback = function(value)
        Settings.RainbowSpeed = value
    end
})

RainbowSection:Space()

RainbowSection:Toggle({
    Flag = "RainbowEnabled",
    Title = "Включить LGBT режим",
    Desc = "Радужное имя",
    Value = false,
    Callback = function(value)
        Settings.RainbowEnabled = value
        Settings.RainbowUseCustomColor = false
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
    Value = "",
    Placeholder = "Введи имя игрока...",
    Callback = function(value)
        Settings.AvatarUsername = value
    end
})

AvatarTab:Space()

AvatarTab:Button({
    Title = "Применить аватар",
    Icon = "lucide:user-round-check",
    Justify = "Center",
    Color = Color3.fromHex("#ECA201"),
    Callback = function()
        if Settings.AvatarUsername == "" then
            WindUI:Notify({
                Title = "Ошибка",
                Content = "Введи имя игрока!",
                Icon = "lucide:x",
            })
            return
        end
        
        local target = findPlayerByName(Settings.AvatarUsername)
        if target then
            morphToPlayer(target)
            WindUI:Notify({
                Title = "Скин применён!",
                Content = "Скин игрока \"" .. (target.Name or Settings.AvatarUsername) .. "\" установлен.",
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
    Value = false,
    Callback = function(value)
        Settings.AvatarAutoApply = value
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
    Value = false,
    Callback = function(value)
        Settings.HideIngameUI = value
        toggleGameUI(value)
    end
})

UITab:Space()

UITab:Toggle({
    Flag = "HideKillfeed",
    Title = "Скрыть килфид",
    Desc = "Скрывает список убийств",
    Value = false,
    Callback = function(value)
        Settings.HideKillfeed = value
        toggleKillfeed(value)
    end
})

UITab:Space()

UITab:Section({
    Title = "Custom Killfeed",
})

UITab:Toggle({
    Flag = "GlobalKillfeedEnabled",
    Title = "Показывать кастомный килфид",
    Desc = "Свой килфид справа сверху",
    Value = true,
    Callback = function(value)
        Settings.GlobalKillfeedEnabled = value
    end
})

UITab:Space()

UITab:Section({
    Title = "Custom HP Bar",
})

UITab:Toggle({
    Flag = "HPBarEnabled",
    Title = "Показывать HP Bar (CS:GO стиль)",
    Desc = "Показ здоровья слева снизу",
    Value = false,
    Callback = function(value)
        Settings.HPBarEnabled = value
    end
})

UITab:Space()

UITab:Colorpicker({
    Flag = "HPBarColor",
    Title = "Цвет HP Bar",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(color)
        Settings.HPBarColor = color
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
    Value = "Insert",
})
UITab:Space()

UITab:Button({
    Title = "Скрыть это меню",
    Icon = "lucide:eye-off",
    Justify = "Center",
    Color = Color3.fromHex("#FF5050"),
    Callback = function()
        if Window.fullscreenToggle then
            Window:ToggleWindow()
        end
        WindUI:Notify({
            Title = "Меню скрыто",
            Content = "Нажми Insert чтобы открыть",
            Icon = "lucide:check",
        })
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
    Value = false,
    Callback = function(value)
        Settings.FreezeTime = value
        if value then
            Lighting.ClockTime = Settings.CustomTime
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
        Default = 12,
    },
    Callback = function(value)
        Settings.CustomTime = value
        if Settings.FreezeTime then
            Lighting.ClockTime = value
        end
    end
})

MiscTab:Space()

MiscTab:Section({
    Title = "Other",
})

MiscTab:Button({
    Title = "Fast Use",
    Desc = "Позволяет активировать все кнопки без задержки",
    Icon = "lucide:zap",
    Justify = "Center",
    Color = Color3.fromHex("#FF8030"),
    Callback = function()
        game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(function(prompt)
            prompt.HoldDuration = 0
        end)
        
        WindUI:Notify({
            Title = "Fast Use",
            Content = "Активировано!",
            Icon = "lucide:check",
        })
    end
})

MiscTab:Space()

MiscTab:Toggle({
    Flag = "HideParachuteEnabled",
    Title = "Спрятать парашют",
    Desc = "Скрывает парашют и рюкзак",
    Value = false,
    Callback = function(value)
        Settings.HideParachuteEnabled = value
    end
})

-- ════════════════════════════════════════════════════════════════
-- ВКЛАДКА: ACS
-- ════════════════════════════════════════════════════════════════
local ACSTab = Window:Tab({
    Title = "ACS",
    Icon = "lucide:crosshair",
    IconColor = Color3.fromHex("#FF5050"),
    Border = true,
})

ACSTab:Section({
    Title = "Работает на Velocity и частично Seliware",
    TextSize = 18,
})

ACSTab:Space()

ACSTab:Section({
    Title = "Оружие",
    TextSize = 16,
})

ACSTab:Input({
    Title = "Разброс + Отдача",
    Icon = "lucide:rifle",
    Value = "M17",
    Placeholder = "Напр. AWP, M40 Sniper...",
    Callback = function(value)
        Settings.ACSGunName = value
    end
})

ACSTab:Space()

ACSTab:Button({
    Title = "Применить",
    Icon = "lucide:check",
    Justify = "Center",
    Color = Color3.fromHex("#FF5050"),
    Callback = function()
        if Settings.ACSGunName == "" then
            WindUI:Notify({Title = "Ошибка", Content = "Введите название оружия!", Icon = "lucide:x"})
            return
        end
        
        Settings.ACSRecoilEnabled = true
        
        WindUI:Notify({
            Title = "✅ No Recoil активирован!",
            Content = "Оружие: " .. Settings.ACSGunName,
            Icon = "lucide:check",
        })
    end
})

ACSTab:Space()

ACSTab:Button({
    Title = "Супер Дробовичек",
    Desc = "Модифицирует оружие из текстового поля",
    Icon = "lucide:zap",
    Justify = "Center",
    Color = Color3.fromHex("#FF8030"),
    Callback = function()
        if Settings.ACSGunName == "" then
            WindUI:Notify({Title = "Ошибка", Content = "Введите название оружия!", Icon = "lucide:x"})
            return
        end
        
        if not (ExecutorCapabilities.hookfunction and ExecutorCapabilities.hookmetamethod and ExecutorCapabilities.newcclosure) then
            WindUI:Notify({
                Title = "Возможно не поддерживается твоим инжектором",
                Content = "Попытка активировать...",
                Icon = "lucide:alert-triangle",
            })
        end
        
        local success, err = pcall(function()
            local gunName = Settings.ACSGunName
            local targetGuns = { [gunName] = true }

            local oldIndex
            oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, index)
                if not checkcaller() then
                    if index == "Value" and self.Name == "Ammo" then
                        local p = self.Parent
                        if p and targetGuns[p.Name] then return math.huge end
                    end
                    
                    if index == "Ammo" and self.Name == "Settings" then
                        local p = self.Parent
                        if p and targetGuns[p.Name] then return math.huge end
                    end
                end
                return oldIndex(self, index)
            end))

            task.spawn(function()
                while task.wait(3) do
                    pcall(function()
                        local repo = game:GetService("ReplicatedStorage")
                        local acsGuns = repo:FindFirstChild("Configurations") and repo.Configurations:FindFirstChild("ACS_Guns")
                        
                        if acsGuns and acsGuns:FindFirstChild(gunName) then
                            local config = acsGuns[gunName]:FindFirstChild("Settings")
                            if config then
                                local s = require(config)
                                s.ShootRate = 0.01
                                s.ChamberDelay = 0
                                s.ShootType = 1
                                s.ReloadTime = 0.01
                                s.ShellInsertTime = 0.01 
                                s.ChamberTime = 0.01
                            end
                            
                            local anims = acsGuns[gunName]:FindFirstChild("Animations")
                            if anims then
                                local a = require(anims)
                                local fastFunc = function(...) return end 
                                
                                a.ShellInsertAnim = fastFunc
                                a.ChamberAnim = fastFunc
                                a.ChamberBKAnim = fastFunc
                            end
                        end
                    end)
                end
            end)

            task.spawn(function()
                game:GetService("RunService").Heartbeat:Connect(function()
                    pcall(function()
                        local char = game.Players.LocalPlayer.Character
                        local tool = char and char:FindFirstChild(gunName)
                        if tool then
                            local s = tool:FindFirstChild("Settings") or tool:FindFirstChild("Config")
                            if s and s:IsA("ModuleScript") then
                                local st = require(s)
                                st.ShootRate = 0.01
                                st.ShellInsertTime = 0.01
                                st.ReloadTime = 0.01
                            end
                        end
                    end)
                end)
            end)
        end)
        
        if success then
            WindUI:Notify({
                Title = "Супер Дробовик активирован!",
                Content = Settings.ACSGunName .. " полностью модифицирован",
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

ACSTab:Section({
    Title = "Патроны",
    TextSize = 16,
})

ACSTab:Button({
    Title = "Бесконечные патроны",
    Desc = "Устанавливает бесконечные патроны",
    Icon = "lucide:infinity",
    Justify = "Center",
    Color = Color3.fromHex("#FF5050"),
    Callback = function()
        if not (ExecutorCapabilities.hookmetamethod and ExecutorCapabilities.newcclosure) then
            WindUI:Notify({
                Title = "Возможно не поддерживается твоим инжектором",
                Content = "Попытка активировать...",
                Icon = "lucide:alert-triangle",
            })
        end
        
        local success, err = pcall(function()
            local targetGuns = {
                ["M40 Sniper"] = true,
                ["Remington MSR"] = true, ["Kar98K"] = true,
                ["AWP"] = true, ["Barrett M82"] = true, ["M200 Intervention"] = true,
                ["M1903 Springfield"] = true
            }
            
            local oldIndex
            oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, index)
                if not checkcaller() then
                    if index == "Value" and self.Name == "Ammo" then
                        if self.Parent and targetGuns[self.Parent.Name] then
                            return math.huge
                        end
                    end
                    
                    if index == "Ammo" and self.Name == "Settings" then
                        if self.Parent and targetGuns[self.Parent.Name] then
                            return math.huge
                        end
                    end
                end
                return oldIndex(self, index)
            end))
        end)
        
        if success then
            WindUI:Notify({Title = "Патроны", Content = "Бесконечный боезапас включен!", Icon = "lucide:check"})
        else
            warn("Ошибка патронов: " .. tostring(err))
        end
    end
})

ACSTab:Space()

ACSTab:Section({
    Title = "Анимации",
    TextSize = 16,
})

ACSTab:Button({
    Title = "Ускорить доставание (0.5s)",
    Desc = "Скорость доставания оружия",
    Icon = "lucide:zap",
    Justify = "Center",
    Color = Color3.fromHex("#FF8030"),
    Callback = function()
        if not ExecutorCapabilities.hookfunction then
            WindUI:Notify({
                Title = "Возможно не поддерживается твоим инжектором",
                Content = "Попытка активировать...",
                Icon = "lucide:alert-triangle",
            })
            return
        end
        
        local success, err = pcall(function()
            local animSpeed = 0.5
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
                        
                        task.wait(0.1 * animSpeed)
                        
                        local settings = require(module.Parent.Settings)
                        ts:Create(p4[2], TweenInfo.new(0.4 * animSpeed), { ["C1"] = settings.RightPos }):Play()
                        ts:Create(p4[3], TweenInfo.new(0.4 * animSpeed), { ["C1"] = settings.LeftPos }):Play()
                        
                        task.wait(0.4 * animSpeed)
                    end
                end
                
                return result
            end)
        end)
        
        if success then
            WindUI:Notify({
                Title = "Патч применен",
                Content = "Скорость анимаций: 0.5 секунды",
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

ACSTab:Section({
    Title = "Персонаж",
    TextSize = 16,
})

ACSTab:Button({
    Title = "Медицина на ходу",
    Desc = "Позволяет хилиться без остановки",
    Icon = "lucide:heart-pulse",
    Justify = "Center",
    Color = Color3.fromHex("#FF5050"),
    Callback = function()
        if not (ExecutorCapabilities.getrawmetatable and ExecutorCapabilities.setreadonly) then
            WindUI:Notify({
                Title = "Возможно не поддерживается твоим инжектором",
                Content = "Попытка активировать...",
                Icon = "lucide:alert-triangle",
            })
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

ACSTab:Section({
    Title = "Звуки",
    TextSize = 16,
})

ACSTab:Button({
    Title = "Включить HitSound",
    Desc = "Замена звука попадания (/sound/hit.mp3)",
    Icon = "lucide:volume-2",
    Justify = "Center",
    Color = Color3.fromHex("#FF5050"),
    Callback = function()
        if not ExecutorCapabilities.getcustomasset then
            WindUI:Notify({
                Title = "Возможно не поддерживается твоим инжектором",
                Content = "Попытка активировать...",
                Icon = "lucide:alert-triangle",
            })
        end
        
        local success, err = pcall(function()
            local CUSTOM_SOUND_FILE = "hit.mp3"
            local SOUNDS_FOLDER = "sound"
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

ACSTab:Space()

ACSTab:Button({
    Title = "Включить Kill Sound",
    Desc = "Замена звука при убийстве (/sound/kill.mp3)",
    Icon = "lucide:volume-2",
    Justify = "Center",
    Color = Color3.fromHex("#FF5050"),
    Callback = function()
        if not ExecutorCapabilities.getcustomasset then
            WindUI:Notify({
                Title = "Возможно не поддерживается твоим инжектором",
                Content = "Попытка активировать...",
                Icon = "lucide:alert-triangle",
            })
        end
        
        local success, err = pcall(function()
            local filePath = "sound/kill.mp3"
            local targetPath = player:WaitForChild("PlayerGui"):WaitForChild("UI").Container.Overlay.KillMoney.Sound

            local originalSoundId = targetPath.SoundId
            local customSoundId = getcustomasset(filePath)
            local useCustom = true

            local function updateSound()
                local desiredId = useCustom and customSoundId or originalSoundId
                if targetPath.SoundId ~= desiredId then
                    targetPath.SoundId = desiredId
                end
            end

            targetPath:GetPropertyChangedSignal("SoundId"):Connect(updateSound)
            updateSound()
        end)
        
        if success then
            WindUI:Notify({
                Title = "Kill Sound активирован",
                Content = "Кастомный звук убийства включен!",
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
    Placeholder = "Введи название...",
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
            AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
        end
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
            AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
        end
    end
})

ConfigTab:Space()

ConfigTab:Button({
    Title = "Создать новый конфиг",
    Icon = "lucide:file-plus",
    Justify = "Center",
    Color = Color3.fromHex("#FF8030"),
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
        ConfigNameInput:Set("")
    end
})
-- ════════════════════════════════════════════════════════════════
-- ОПТИМИЗИРОВАННЫЕ СИСТЕМНЫЕ ЦИКЛЫ
-- ════════════════════════════════════════════════════════════════

-- Управление временем
addConnection("TimeControl", RunService.Heartbeat:Connect(function()
    if Settings.FreezeTime then
        Lighting.ClockTime = Settings.CustomTime
    end
end))

-- Rainbow эффект
addConnection("RainbowLoop", RunService.RenderStepped:Connect(function()
    pcall(function()
        local char = player.Character
        if not char then return end
        
        local head = char:FindFirstChild("Head")
        if not head then return end
        
        local nameTag = head:FindFirstChild("NameTag")
        if not nameTag then return end
        
        local usernameLabel = nameTag:FindFirstChild("Username")
        if not usernameLabel or not usernameLabel:IsA("TextLabel") then return end
        
        if Settings.RainbowEnabled then
            local hue = (tick() * Settings.RainbowSpeed * 50) % 360
            usernameLabel.TextColor3 = Color3.fromHSV(hue / 360, 1, 1)
        elseif Settings.RainbowUseCustomColor then
            usernameLabel.TextColor3 = Settings.RainbowCustomColor
        end
    end)
end))
-- ════════════════════════════════════════════════════════════════
-- СИСТЕМА ACS NO RECOIL
-- ════════════════════════════════════════════════════════════════
task.spawn(function()
    while wait() do
        if Settings.ACSRecoilEnabled and Settings.ACSGunName ~= "" then
            pcall(function()
                local function BGun(gun)
                    if player.Backpack:FindFirstChild(gun) then
                        player.Backpack[gun]:SetAttribute("HRecoil", Vector2.new(0, 0))
                        player.Backpack[gun]:SetAttribute("VRecoil", Vector2.new(0, 0))
                        player.Backpack[gun]:SetAttribute("MaxSpread", 0)
                        player.Backpack[gun]:SetAttribute("MinSpread", 0)
                        player.Backpack[gun]:SetAttribute("SwayBase", 0)
                    end
                    
                    local char = player.Character
                    if char and char:FindFirstChild(gun) then
                        char[gun]:SetAttribute("HRecoil", Vector2.new(0, 0))
                        char[gun]:SetAttribute("VRecoil", Vector2.new(0, 0))
                        char[gun]:SetAttribute("MaxSpread", 0)
                        char[gun]:SetAttribute("MinSpread", 0)
                        char[gun]:SetAttribute("SwayBase", 0)
                    end
                end

                BGun(Settings.ACSGunName)
            end)
        end
    end
end)
-- ════════════════════════════════════════════════════════════════
-- ОБРАБОТЧИК КЛАВИШИ INSERT
-- ════════════════════════════════════════════════════════════════
local menuVisible = true

addConnection("InsertToggle", UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        menuVisible = not menuVisible
        Window:Toggle(menuVisible)
    end
end))
-- Система скрытия парашюта
addConnection("ParachuteHide", RunService.Heartbeat:Connect(function()
    if not Settings.HideParachuteEnabled then return end
    
    pcall(function()
        local targets = {
            ["Backpack"] = true,
            ["Mesh"] = true,
            ["RightLeg"] = true,
            ["LeftLeg"] = true
        }
        
        local function hide(obj)
            if targets[obj.Name] and obj:IsA("BasePart") then
                obj.Transparency = 1
                obj.LocalTransparencyModifier = 1
            end
        end
        
        local char = player.Character
        if char then
            for _, desc in ipairs(char:GetDescendants()) do
                hide(desc)
            end
        end
    end)
end))

-- HP Bar и Killfeed видимость
addConnection("UIUpdate", RunService.RenderStepped:Connect(function()
    pcall(function()
        HPBack.Visible = Settings.HPBarEnabled
        KillfeedContainer.Visible = Settings.GlobalKillfeedEnabled
        
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        
        if hum then
            local hp = math.floor(hum.Health)
            HPLabel.Text = tostring(hp)
            HPLabel.TextColor3 = Settings.HPBarColor
            HPIcon.TextColor3 = Settings.HPBarColor
        end
    end)
end))

-- Автоматическое скрытие UI
task.spawn(function()
    while true do
        pcall(function()
            task.wait(3)
            
            if Settings.HideIngameUI then
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
            
            if Settings.HideKillfeed then
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
    if not Settings.GlobalKillfeedEnabled then return end
    
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

        if isMyKill and Settings.ChatEnabled then
            safeSend(Settings.ChatMessage)
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
        addConnection("Killfeed Watch", gameKillfeed.ChildAdded:Connect(function(child)
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
        
        if Settings.AvatarAutoApply and Settings.AvatarUsername ~= "" then
            local target = findPlayerByName(Settings.AvatarUsername)
            if target then
                morphToPlayer(target)
                task.wait(0.2)
            end
        end
        
        applyAllNameChanges(Settings.GameDisplayName, Settings.GameUsername, Settings.GameRank)
    end)
end))

-- ════════════════════════════════════════════════════════════════
-- ЗАЩИТА ОТ УТЕЧЕК ПАМЯТИ
-- ════════════════════════════════════════════════════════════════
CoreGui.DescendantRemoving:Connect(function(obj)
    if obj == CustomUI then
        cleanupConnections()
    end
end)

-- ════════════════════════════════════════════════════════════════
-- ЗАВЕРШЕНИЕ ЗАГРУЗКИ
-- ════════════════════════════════════════════════════════════════
WindUI:Notify({
    Title = "VeloHub 2.0 загружен!",
    Content = "Скрипт успешно инициализирован. Нажми Insert чтобы открыть меню",
    Icon = "lucide:check-circle",
    Duration = 5,
})

print("═══════════════════════════════════════════════")
print("VeloHub 2.0 - ОПТИМИЗИРОВАННАЯ ВЕРСИЯ")
print("Все системы защиты активны")
print("Наслаждайся!")
print("═══════════════════════════════════════════════")