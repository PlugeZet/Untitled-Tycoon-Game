local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local playerData = DataStoreService:GetDataStore("PlayerData")

local Bindable = ReplicatedStorage:WaitForChild("Bindable")
local BindEvents = Bindable:WaitForChild("Event")
local BindFunctions = Bindable:WaitForChild("Function")

local sessionData = {}

BindEvents:WaitForChild("GetPurchaseData").Event:Connect(function(player, objectName)
	local playerKey = "Player_" .. player.UserId
	if sessionData[playerKey] then
		table.insert(sessionData[playerKey].Purchased, objectName)
	end
end)

BindFunctions:WaitForChild("GetAllPurchase").OnInvoke = function(player)
    local playerKey = "Player_" .. player.UserId
    if sessionData[playerKey] then
        local purchaseData = sessionData[playerKey].Purchase
		return purchaseData
	end
end

Players.PlayerAdded:Connect(function(player)
	player:WaitForChild("leaderstats")

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats:FindFirstChild("Coins")

	local playerKey = "Player_" .. player.UserId
	local success, savedData = pcall(function()
		return playerData:GetAsync(playerKey[playerKey])
	end)

	if success then
		if savedData ~= nil then
			coins.Value = savedData.Coins
			sessionData[playerKey] = savedData
		else
			sessionData[playerKey] = {
				Coins = 0,
				Purchased = {},
			}
			coins.Value = sessionData[playerKey].Coins
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local playerKey = "Player_" .. player.UserId
    local leaderstats = player:FindFirstChild("leaderstats")

    if leaderstats and sessionData[playerKey] then
        sessionData[playerKey].Coins = leaderstats:FindFirstChild("Coins").Value
        local success, errorMessage = pcall(function()
            playerData:SetAsync(playerKey, sessionData[playerKey])
        end)
    
        if not success then
            warn("Failed to save player data for " .. player.Name .. ": " .. errorMessage)
        end

        sessionData[playerKey] = nil
    end

end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
	local playerKey = "Player_" .. player.UserId
    local leaderstats = player:FindFirstChild("leaderstats")

    if leaderstats and sessionData[playerKey] then
        sessionData[playerKey].Coins = leaderstats:FindFirstChild("Coins").Value
        local success, errorMessage = pcall(function()
            playerData:SetAsync(playerKey, sessionData[playerKey])
        end)
    
        if not success then
            warn("Failed to save player data for " .. player.Name .. ": " .. errorMessage)
        end

        sessionData[playerKey] = nil
    end
	end
end)
