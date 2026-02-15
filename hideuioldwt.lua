-- ЗАЩИТА ОТ ПОВТОРНОГО ЗАПУСКА
if _G.GuiHiderLoaded then 
    return 
end
_G.GuiHiderLoaded = true

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local hideModeActive = true
local targetGuis = {["MainHUD"] = true, ["Map"] = true, ["TESTING"] = true}

-- Флаг, чтобы избежать рекурсии (краша)
local isUpdating = false

local function setGuiEnabled(gui, state)
    if isUpdating then return end -- Если мы уже в процессе смены, выходим
    isUpdating = true
    gui.Enabled = state
    isUpdating = false
end

local function setupGui(gui)
    if targetGuis[gui.Name] and gui:IsA("ScreenGui") then
        -- Устанавливаем начальное состояние
        setGuiEnabled(gui, not hideModeActive)

        -- Безопасное отслеживание изменений
        gui:GetPropertyChangedSignal("Enabled"):Connect(function()
            if isUpdating then return end
            if hideModeActive and gui.Enabled == true then
                setGuiEnabled(gui, false)
            end
        end)
    end
end

-- Слежка за новыми и текущими GUI
for _, child in pairs(PlayerGui:GetChildren()) do
    setupGui(child)
end

PlayerGui.ChildAdded:Connect(setupGui)

-- Переключение на PageUp
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.PageUp then
        hideModeActive = not hideModeActive
        
        -- Массовое обновление без краша
        for _, child in pairs(PlayerGui:GetChildren()) do
            if targetGuis[child.Name] and child:IsA("ScreenGui") then
                setGuiEnabled(child, not hideModeActive)
            end
        end
    end
end)
