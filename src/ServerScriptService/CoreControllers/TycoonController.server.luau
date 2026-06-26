local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Configs = ReplicatedStorage:WaitForChild("Configs")
local ButtonConfig = require(Configs:WaitForChild("ButtonDependencyGraph"))

local StarterAssetsTemplate = ServerStorage:WaitForChild("StarterPlot")
local Plots = CollectionService:GetTagged("Plots")
local Buttons = CollectionService:GetTagged("Buttons")

local plotPurchasedButtons = {
	["RedPlot"] = {},
	["BluePlot"] = {},
	["GreenPlot"] = {},
	["YellowPlot"] = {},
}

local function claimPlot(plot)
	local claimDoor = plot:WaitForChild("ClaimDoor")

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

		if player:GetAttribute("HasPlot") then
			return
		end
		local playerId = player.UserId
		local ownerId = plot:GetAttribute("OwnerId")
		local isClaimed = plot:GetAttribute("IsClaimed")
		-- local plotColor = plot:GetAttribute("PlotColor")

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
		local purchasedObjectsFolder = plot:FindFirstChild("PurchasedObjects")

		if not purchasedObjectsFolder then
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

		clonedModel.Parent = purchasedObjectsFolder
	end)
end

local function purchaseObject(button, plot)
	local buttonName = button:GetAttribute("ButtonId")
	local configData = ButtonConfig[buttonName]

	if not configData then
		warn("Data modul tidak ditemukan untuk: " .. tostring(buttonName))
		return
	end

	local isProcessing = false

	button.Touched:Connect(function(otherPart)
		if isProcessing then
			return
		end
		isProcessing = true

		local character = otherPart.Parent
		local player = Players:GetPlayerFromCharacter(character)

		if not player or plot:GetAttribute("OwnerId") ~= player.UserId then
			isProcessing = false
			return
		end

		local plotName = plot.Name
		local buttonDependencyId = configData.Dependency
		local isValid = false

		if buttonDependencyId == nil then
			isValid = true
		else
			if plotPurchasedButtons[plotName] and plotPurchasedButtons[plotName][buttonDependencyId] == true then
				isValid = true
			end
		end

		if isValid then
			if not plotPurchasedButtons[plotName] then
				plotPurchasedButtons[plotName] = {}
			end
			plotPurchasedButtons[plotName][buttonName] = true

			button:Destroy()
			print("✅ Pembelian sukses tercatat di memori!")
		else
			warn("❌ Syarat dependency belum dibeli!")
			isProcessing = false
		end
	end)
end

for _, plot in ipairs(Plots) do
	claimPlot(plot)
	initializePlot(plot)
end

for _, button in ipairs(Buttons) do
	local plot = button:FindFirstAncestorOfClass("Model")
	purchaseObject(button, plot)
end
