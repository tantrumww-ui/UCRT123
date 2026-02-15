-- Убрали все лишние проверки загрузки и античита
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local hideModeActive = true
local targetGuis = {["MainHUD"] = true, ["Map"] = true, ["TESTING"] = true}

-- Функция скрытия/показа
local function updateState()
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if targetGuis[gui.Name] and gui:IsA("ScreenGui") then
            gui.Enabled = not hideModeActive
        end
    end
end

-- Обработка новых меню (например, после выхода из вертолета)
PlayerGui.ChildAdded:Connect(function(child)
    if targetGuis[child.Name] and child:IsA("ScreenGui") then
        task.wait(0.1) -- Короткая пауза, чтобы игра успела "поставить" меню
        child.Enabled = not hideModeActive
    end
end)

-- Переключение на PageUp
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.PageUp then
        hideModeActive = not hideModeActive
        updateState()
    end
end)

-- Первый запуск сразу после выполнения скрипта
updateState()
