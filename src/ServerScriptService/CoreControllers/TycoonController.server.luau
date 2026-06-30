local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Configs = ReplicatedStorage:WaitForChild("Configs")
local ButtonConfig = require(Configs:WaitForChild("ButtonDependencyGraph"))

local Plots = CollectionService:GetTagged("Plots")
local Buttons = CollectionService:GetTagged("Buttons")

local StarterAssetsTemplate = ServerStorage:WaitForChild("StarterPlot")
local TycoonAssets = ServerStorage:WaitForChild("TycoonAssets")
local Droppers = TycoonAssets:WaitForChild("Droppers")

local purchasedObjects = {}

local function claimPlot(plot)
	local claimDoor = plot:WaitForChild("ClaimDoor", 5)

	if not claimDoor then
		return
	end

	claimDoor.Touched:Connect(function(otherPart)
		local character = otherPart.Parent
		local humanoid = character:FindFirstChild("Humanoid")

		if not humanoid then
			return
		end

		local player = game.Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local playerId = player.UserId
		local ownerId = plot:GetAttribute("OwnerId")
		local isClaimed = plot:GetAttribute("IsClaimed")

		if isClaimed then
			return
		end

		if ownerId == nil or ownerId == 0 then
			plot:SetAttribute("OwnerId", playerId)
			plot:SetAttribute("OwnerName", player.Name)
			plot:SetAttribute("IsClaimed", true)
			player:SetAttribute("HasPlot", true)

			claimDoor:Destroy()
		end
	end)
end

local function initializePlot(plot)
	plot:GetAttributeChangedSignal("IsClaimed"):Connect(function()
		local isClaimed = plot:GetAttribute("IsClaimed")

		if not isClaimed then
			return
		end

		local clonedModel = StarterAssetsTemplate:Clone()
		for _, asset in ipairs(clonedModel:GetDescendants()) do
			if asset:GetAttribute("IsActive") ~= nil then
				asset:SetAttribute("IsActive", true)
			end
		end

		if plot.PrimaryPart then
			clonedModel:PivotTo(plot.PrimaryPart.CFrame)
		end

		clonedModel.Parent = plot
	end)
end

local function purchaseObject(button, plot)
	local ButtonData = ButtonConfig[button.Name]

	if not ButtonData then
		warn("[DEBUG] Data tidak ditemukan untuk: " .. button.Name)
		return
	end

	local purchasedObjectsFolder = plot:FindFirstChild("PurchasedObjects")
	local isProcessing = false
	if ButtonData.Dependency ~= nil then
		button.Transparency = 1
		button.CanCollide = false
		local priceGui = button:FindFirstChild("ButtonPrice")
		if priceGui then
			priceGui.Enabled = false
		end

		coroutine.resume(coroutine.create(function()
			local ButtonType = ButtonData.Type
			local dependencyTarget = ButtonConfig[ButtonData.Dependency].Target

			if purchasedObjectsFolder:WaitForChild(ButtonType):FindFirstChild(dependencyTarget) then
				button.Transparency = 0
				button.CanCollide = true
				if priceGui then
					priceGui.Enabled = true
				end
			end
		end))
	end

	button.Touched:Connect(function(otherPart)
		print(1)
		if isProcessing then
			return
		end
		print(2)
		if button.CanCollide == false then
			return
		end
		print(3)

		local character = otherPart.Parent
		local player = Players:GetPlayerFromCharacter(character)

		if not player then
			return
		end
		print(4)
		if plot:GetAttribute("OwnerId") ~= player.UserId then
			return
		end
		print(5)

		local leaderstats = player:FindFirstChild("leaderstats")
		print(6)
		if not leaderstats then
			return
		end
		print(7)
		local coins = leaderstats:FindFirstChild("Coins")
		print(8)

		if coins.Value >= ButtonData.Price then
			isProcessing = true
			print(9)
			coins.Value -= ButtonData.Price
			print(10)

			local ButtonType = ButtonData.Type
			local ButtonTarget = ButtonData.Target

			local templateFolder = TycoonAssets:FindFirstChild(ButtonType)
			print(11)
			local templateItem = templateFolder and templateFolder:FindFirstChild(ButtonTarget)
			print(12)

			if templateItem then
				local newObject = templateItem:Clone()
				newObject.Parent = purchasedObjectsFolder:FindFirstChild(ButtonType)
				print(13)
			end

			button:Destroy()
			print(14)
		end
	end)
end

for _, plot in ipairs(Plots) do
	claimPlot(plot)
	initializePlot(plot)
end

for _, button in ipairs(Buttons) do
	local plot = button.Parent:FindFirstAncestorOfClass("Model")
	if plot then
		purchaseObject(button, plot)
	end
end

CollectionService:GetInstanceAddedSignal("Buttons"):Connect(function(newButton)
	task.wait(0.1)
	local plot = newButton.Parent:FindFirstAncestorOfClass("Model")
	if plot then
		purchaseObject(newButton, plot)
		print("[DEBUG-SETUP] 📡 Radar menangkap tombol baru: " .. newButton.Name .. " di " .. plot.Name)
	else
		warn("[DEBUG-SETUP] ⚠️ Tombol baru " .. newButton.Name .. " tidak berada di dalam Plot!")
	end
end)
