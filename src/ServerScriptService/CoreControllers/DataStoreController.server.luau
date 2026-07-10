local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage") 
local Players = game:GetService("Players")

local playerData = DataStoreService:GetDataStore("PlayerDataTest")

local Bindable = ServerStorage:WaitForChild("Bindable")
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
		return sessionData[playerKey].Purchased or {}
	else
		warn("[DATA-WARNING] Skrip Tycoon meminta data sebelum DataStore selesai memuat untuk " .. player.Name)
		return {}
	end
end

Players.PlayerAdded:Connect(function(player)
	-- PERINGATAN: Pastikan skrip pembuat leaderstats tidak ikut menunggu DataStore, 
	-- agar tidak terjadi infinite loading (deadlock)
	player:WaitForChild("leaderstats")

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats:FindFirstChild("Coins")

	local playerKey = "Player_" .. player.UserId
	local success, savedData = pcall(function()
		return playerData:GetAsync(playerKey)
	end)

	if success then
		if savedData ~= nil then
			sessionData[playerKey] = savedData

			if not sessionData[playerKey].Purchased then
				sessionData[playerKey].Purchased = {}
			end
			if not sessionData[playerKey].Coins then
				sessionData[playerKey].Coins = 0
			end

			coins.Value = sessionData[playerKey].Coins
		else
			sessionData[playerKey] = {
				Coins = 0,
				Purchased = {},
			}
			coins.Value = sessionData[playerKey].Coins
		end
	else
		warn("[DATA-ERROR] Gagal memuat data milik " .. player.Name)
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
		task.spawn(function()
			local playerKey = "Player_" .. player.UserId
			local leaderstats = player:FindFirstChild("leaderstats")

			if leaderstats and sessionData[playerKey] then
				sessionData[playerKey].Coins = leaderstats:FindFirstChild("Coins").Value
				local success, errorMessage = pcall(function()
					playerData:SetAsync(playerKey, sessionData[playerKey])
				end)
		
				if not success then
					warn("Failed to emergency save for " .. player.Name .. ": " .. errorMessage)
				end
			end
		end)
	end
end)