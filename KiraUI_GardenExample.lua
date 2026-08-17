-- Kira UI - Garden Tablet example
-- Upload KiraUI.lua to GitHub, then replace this URL with the RAW file URL.

local KiraUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/AkiyamaKira2003/KiraUI/main/KiraUI.lua"
))()

local State = {
    AutoBuy = false,
    AutoPlant = false,
    BuyRarity = "ALL",
    BuyDelay = 0.15,
    PlantSeed = "Fig",
    Fertilizer = "Magic",
    GrowWait = 5,
}

local Window = KiraUI:CreateWindow({
    SingletonName = "KiraGardenUI",
    Title = "Garden Tablet",
    Subtitle = "Coordinated automation controller",
    Size = Vector2.new(940, 560),
    MinSize = Vector2.new(560, 390),
    MaxSize = Vector2.new(1280, 820),
    ToggleKey = Enum.KeyCode.RightShift,
    LauncherText = "Open Garden UI",
    Status = "Garden controller ready",
    Phase = "IDLE",
})

local Automation = Window:AddTab("Automation", "⚙")
local Garden = Window:AddTab("Garden", "✦")
local Settings = Window:AddTab("Settings", "☰")

local SeedSection = Automation:AddSection("Seed Conveyor")
local AutoBuyToggle = SeedSection:AddToggle({
    Text = "Auto Buy Seeds",
    Default = State.AutoBuy,
})

local RarityDropdown = SeedSection:AddDropdown({
    Text = "Rarity",
    Values = {
        "ALL",
        "COMMON",
        "UNCOMMON",
        "RARE",
        "EPIC",
        "LEGENDARY",
        "MYTHIC",
    },
    Default = State.BuyRarity,
})

local BuyDelaySlider = SeedSection:AddSlider({
    Text = "Buy Delay",
    Min = 0.05,
    Max = 1.00,
    Default = State.BuyDelay,
    Step = 0.05,
    Suffix = "s",
})

local PlantSection = Automation:AddSection("Planting Controller")
local AutoPlantToggle = PlantSection:AddToggle({
    Text = "Auto Plant",
    Default = State.AutoPlant,
})

local SeedDropdown = PlantSection:AddDropdown({
    Text = "Seed",
    Provider = function()
        -- Replace with your own getAvailableSeeds()
        return {
            "Fig",
            "Oak",
            "Lemon",
        }
    end,
    Default = State.PlantSeed,
})

local FertilizerDropdown = PlantSection:AddDropdown({
    Text = "Fertilizer",
    Values = {
        "Basic",
        "Better",
        "Premium",
        "Super",
        "Magic",
    },
    Default = State.Fertilizer,
})

local GrowWaitSlider = PlantSection:AddSlider({
    Text = "Temporary Grow Wait",
    Min = 1,
    Max = 30,
    Default = State.GrowWait,
    Step = 1,
    Suffix = "s",
})

PlantSection:AddButton({
    Text = "Plant Once + Verify",
    Callback = function()
        Window:SetPhase("PLANTING", "warning")
        Window:SetStatus("Plant transaction requested...")
        -- plantOnce(...)
    end,
})

local MutationSection = Garden:AddSection("My Fruit Mutations", {
    Span = "full",
})

local MutationInfo = MutationSection:AddLabel({
    Text = "Mutation scanner is ready to be connected to your own-plot scanner.",
    Wrap = true,
    Muted = true,
    Height = 42,
})

MutationSection:AddButton({
    Text = "Refresh Mutations",
    Callback = function()
        -- local data = scanMyMutations()
        -- MutationInfo:SetText(...)
        Window:SetStatus("Mutation refresh requested")
    end,
})

local SystemSection = Settings:AddSection("System")
SystemSection:AddButton({
    Text = "Stop All",
    Danger = true,
    Callback = function()
        AutoBuyToggle:SetValue(false)
        AutoPlantToggle:SetValue(false)
        Window:SetPhase("IDLE")
        Window:SetStatus("All automation stopped", "warning")
    end,
})

if type(SystemSection.AddKeybind) == "function" then
    SystemSection:AddKeybind({
        Text = "Show / Hide Key",
        WindowToggle = true,
    })
end

SystemSection:AddLabel({
    Text = "Set your own show/hide key above. The × button hides the window and shows an Open UI button on screen.",
    Wrap = true,
    Muted = true,
    Height = 46,
})

-- Recommended: UI is created first; behavior is attached afterward.
AutoBuyToggle:OnChanged(function(value)
    State.AutoBuy = value
    Window:SetStatus("Auto Buy: " .. (value and "ON" or "OFF"))
    -- SetAutoBuy(value)
end)

AutoPlantToggle:OnChanged(function(value)
    State.AutoPlant = value
    Window:SetStatus("Auto Plant: " .. (value and "ON" or "OFF"))
    -- SetAutoPlant(value)
end)

RarityDropdown:OnChanged(function(value)
    State.BuyRarity = value
end)

BuyDelaySlider:OnChanged(function(value)
    State.BuyDelay = value
end)

SeedDropdown:OnChanged(function(value)
    State.PlantSeed = value
end)

FertilizerDropdown:OnChanged(function(value)
    State.Fertilizer = value
end)

GrowWaitSlider:OnChanged(function(value)
    State.GrowWait = value
end)

Window:SetStatus("Kira UI loaded")
