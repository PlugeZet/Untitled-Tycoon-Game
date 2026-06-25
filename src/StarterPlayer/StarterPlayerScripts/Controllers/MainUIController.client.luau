local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local leaderstats = localPlayer:WaitForChild("leaderstats")
local coins = leaderstats:WaitForChild("Coins")

local mainGui = localPlayer:WaitForChild("PlayerGui"):WaitForChild("MainGui")
local currencyFrame = mainGui:WaitForChild("CurrencyFrame")
local coinLabel = currencyFrame:WaitForChild("CoinLabel")

coinLabel.Text = tostring(coins.Value)

coins.Changed:Connect(function(newValue)
    coinLabel.Text = tostring(newValue)
end)