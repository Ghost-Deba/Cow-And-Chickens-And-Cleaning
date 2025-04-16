local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

local Window = Rayfield:CreateWindow({
    Name = "Animal Farm Automation",
    LoadingTitle = "Farm Helper",
    LoadingSubtitle = "by YourName",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FarmAutomation",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    }
})

-- Main Toggle
local MainToggle = Window:CreateTab("Main Controls", 4483362458)

-- Cow Milking Section
local CowSection = MainToggle:CreateSection("Cow Milking")
local CowToggle = MainToggle:CreateToggle({
    Name = "Auto Milk Cows",
    CurrentValue = false,
    Flag = "CowToggle",
    Callback = function(Value)
        if Value then
            StartCowMilking()
        else
            StopCowMilking()
        end
    end,
})

-- Chicken Section
local ChickenSection = MainToggle:CreateSection("Chicken Eggs")
local ChickenToggle = MainToggle:CreateToggle({
    Name = "Auto Collect Eggs",
    CurrentValue = false,
    Flag = "ChickenToggle",
    Callback = function(Value)
        if Value then
            StartEggCollection()
        else
            StopEggCollection()
        end
    end,
})

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 4483362458)
local SettingsSection = SettingsTab:CreateSection("Configuration")

local CowInterval = SettingsTab:CreateInput({
    Name = "Cow Check Interval (seconds)",
    PlaceholderText = "60",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        CowCheckInterval = tonumber(Text) or 60
    end,
})

local ChickenInterval = SettingsTab:CreateSection("Chicken Check Interval (seconds)")
local ChickenIntervalInput = SettingsTab:CreateInput({
    Name = "Chicken Check Interval (seconds)",
    PlaceholderText = "60",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        ChickenCheckInterval = tonumber(Text) or 60
    end,
})

-- Initialize variables
local CowCheckInterval = 60
local ChickenCheckInterval = 60
local CowMilkingRunning = false
local EggCollectionRunning = false

-- Cow Milking Functions
function StartCowMilking()
    if CowMilkingRunning then return end
    CowMilkingRunning = true
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Larry = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Larry")
    local Animals = workspace:WaitForChild("Animals")
    local Barn = workspace:WaitForChild("Buildings"):WaitForChild("AutoWoodenBarn")

    -- Get all 12 gates
    local gates = {}
    for i = 1, 12 do
        table.insert(gates, Barn:WaitForChild("AnimalContainer"):WaitForChild("Spots"):WaitForChild(tostring(i)):WaitForChild("Gate"))
    end

    -- Table to store entered cows
    local enteredCows = {}

    -- Function to milk cows
    local function milkCows()
        enteredCows = {}
        local cowsToEnter = {}

        -- Check compatible cows
        for _, cow in pairs(Animals:GetChildren()) do
            if cow.Name == "Cow" then
                local config = cow:FindFirstChild("Configurations")
                if config and config:FindFirstChild("Production") and config.Production.Value == 300 then
                    table.insert(cowsToEnter, cow)
                end
            end
        end

        -- Enter first 12 cows
        for i = 1, 12 do
            if cowsToEnter[i] then
                local enterArgs = {
                    [1] = {
                        [1] = cowsToEnter[i]
                    },
                    [2] = Barn
                }
                Larry:WaitForChild("EVTHerdRequest"):FireServer(unpack(enterArgs))
                table.insert(enteredCows, cowsToEnter[i])
            end
        end

        -- Milk all cows at once
        for _, cow in pairs(enteredCows) do
            local milkArgs = {
                [1] = "Milk",
                [2] = cow
            }
            Larry:WaitForChild("EVTCollectAnimalProduction"):FireServer(unpack(milkArgs))
        end

        wait(1)

        -- Open gates to release cows
        for i = 1, 12 do
            local gateArgs = {
                [1] = gates[i]
            }
            Larry:WaitForChild("EVTOpenBarnGate"):FireServer(unpack(gateArgs))
        end

        wait(2)

        -- Enter remaining 8 cows
        local enteredSecondBatch = {}
        for i = 13, 20 do
            if cowsToEnter[i] then
                local enterArgs = {
                    [1] = {
                        [1] = cowsToEnter[i]
                    },
                    [2] = Barn
                }
                Larry:WaitForChild("EVTHerdRequest"):FireServer(unpack(enterArgs))
                table.insert(enteredSecondBatch, cowsToEnter[i])
            end
        end

        wait(2)

        -- Milk remaining cows
        for _, cow in pairs(enteredSecondBatch) do
            local milkArgs = {
                [1] = "Milk",
                [2] = cow
            }
            Larry:WaitForChild("EVTCollectAnimalProduction"):FireServer(unpack(milkArgs))
        end

        wait(1)

        -- Release remaining cows
        for i = 1, #enteredSecondBatch do
            local gateArgs = {
                [1] = gates[i]
            }
            Larry:WaitForChild("EVTOpenBarnGate"):FireServer(unpack(gateArgs))
        end
    end

    -- Main loop
    while CowMilkingRunning do
        milkCows()
        wait(CowCheckInterval)
    end
end

function StopCowMilking()
    CowMilkingRunning = false
end

-- Chicken Egg Collection Functions
function StartEggCollection()
    if EggCollectionRunning then return end
    EggCollectionRunning = true
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Larry = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Larry")
    local Buildings = workspace:WaitForChild("Buildings")
    local coopTypeName = "MediumChickenCoop"
    local maxEggCapacity = 72

    local function collectEggsWhenFull()
        for _, coop in ipairs(Buildings:GetChildren()) do
            if coop.Name == coopTypeName then
                local config = coop:FindFirstChild("Configurations")
                if config and config:FindFirstChild("EggCapacity") then
                    local eggCapacity = config.EggCapacity.Value
                    if eggCapacity >= maxEggCapacity then
                        local args = {
                            [1] = "Eggs",
                            [2] = coop
                        }
                        Larry:WaitForChild("EVTCollectAnimalProduction"):FireServer(unpack(args))
                        Rayfield:Notify({
                            Title = "Eggs Collected",
                            Content = "Collected eggs from "..coop:GetFullName(),
                            Duration = 3,
                            Image = 4483362458,
                        })
                    end
                end
            end
        end
    end

    while EggCollectionRunning do
        collectEggsWhenFull()
        wait(ChickenCheckInterval)
    end
end

function StopEggCollection()
    EggCollectionRunning = false
end

-- Initialize default values
CowInterval:Set("60")
ChickenIntervalInput:Set("60")

Rayfield:Notify({
    Title = "Farm Helper Loaded",
    Content = "Ready to automate your farming!",
    Duration = 5,
    Image = 4483362458,
})
