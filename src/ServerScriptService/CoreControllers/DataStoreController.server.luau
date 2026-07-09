local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local playerData = DataStoreService:GetDataStore("PlayerData")

local sessionData = {}
local defaultData = {
    Coins = 0,
    Purchased = {},
}

--[[
    dataSession = {
        ["Player_" .. player.UserId] = {
            Coins = number
            Purchased = {
                "ObjectName",
                "AnotherObjectName",
            }
        }
    }
]]

Players.PlayerAdded:Connect(function(player)
    player:WaitForChild("leaderstats")

    local leaderstats = player:FindFirstChild("leaderstats")
    local coins = leaderstats:FindFirstChild("Coins")

    local playerKey = "Player_" .. player.UserId
    local success, savedData = pcall(function()
        return playerData:GetAsync(playerKey)
    end)

    if success then
        if savedData ~= nil then
            coins.Value = savedData.Coins
            sessionData[playerKey] = savedData
        else
            sessionData[playerKey] = defaultData
            coins.Value = defaultData.Coins
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local playerKey = "Player_" .. player.UserId
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        
        local success, errorMessage = pcall(function()
            playerData:SetAsync(playerKey, coins.Value)
        end)

        if not success then
            warn("Failed to save player data for " .. player.Name .. ": " .. errorMessage)
        end
    end
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        local playerKey = "Player_" .. player.UserId
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats and leaderstats:FindFirstChild("Coins") then
			pcall(function()
				playerData:SetAsync(playerKey, leaderstats.Coins.Value)
			end)
		end
    end
end)