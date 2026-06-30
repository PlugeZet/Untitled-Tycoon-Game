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
		if not isClaimed then return end

		local masterClone = StarterAssetsTemplate:Clone()

		if plot.PrimaryPart and masterClone.PrimaryPart then
			masterClone:PivotTo(plot.PrimaryPart.CFrame)
		else
			warn("[DEBUG-ASSET] ⚠️ StarterPlot atau Plot tidak memiliki PrimaryPart yang disetel!")
		end

		for _, clonedChild in ipairs(masterClone:GetChildren()) do
			local targetFolder = clonedChild:GetAttribute("Destination")
			
			if targetFolder == "Plot" or targetFolder == "plot" then
				clonedChild.Parent = plot
				
			elseif targetFolder ~= nil then
				local destination = plot:FindFirstChild(targetFolder)
				if destination then
					clonedChild.Parent = destination
				else
					warn("[DEBUG-ROUTE] ⚠️ Folder tujuan '" .. targetFolder .. "' tidak ditemukan di " .. plot.Name)
					clonedChild:Destroy()
				end
				
			else
				local defaultFolder = plot:FindFirstChild("PurchasedObjects")
				if defaultFolder then
					clonedChild.Parent = defaultFolder
				else
					clonedChild:Destroy()
				end
			end
		end
		masterClone:Destroy()
	end)
end

local function purchaseObject(button, plot)
	local ButtonData = ButtonConfig[button.Name]
	print("button name = ", button.Name)

	if not ButtonData then
		warn("[DEBUG] Data tidak ditemukan untuk: " .. button.Name)
		return
	end

	local purchasedObjectsFolder = plot:FindFirstChild("PurchasedObjects")
	local isProcessing = false

	if ButtonData.Dependency ~= nil then
		print("Dependency found", ButtonData.Dependency)
		button.Transparency = 1
		button.CanCollide = false
		local priceGui = button:FindFirstChild("ButtonPrice")
		
		if priceGui then
			print("priceGui found")
			priceGui.Enabled = false
		end

	coroutine.resume(coroutine.create(function()
				local dependencyData = ButtonConfig[ButtonData.Dependency]
				local dependencyType = dependencyData.Type
				local UniqueObjectName = ButtonData.Dependency .. "_Asset"
				
				print("[DEBUG-WAIT] ⏳ Tombol " .. button.Name .. " sedang menunggu " .. UniqueObjectName .. " muncul...")
				local categoryFolder = purchasedObjectsFolder:WaitForChild(dependencyType)
				local readyObject = categoryFolder:WaitForChild(UniqueObjectName)

				if readyObject then
					print("[DEBUG-WAIT] ✅ Syarat terpenuhi! Membuka kunci:", button.Name)
					button.Transparency = 0
					button.CanCollide = true
					if priceGui then
						priceGui.Enabled = true
					end
				end
		end))
	end

	button.Touched:Connect(function(otherPart)
		print("Button touched by " , otherPart.Name)
		if isProcessing then
			print("Button not processing")
			return
		end
		if button.CanCollide == false then
			print("Button not clickable")
			return
		end
		local character = otherPart.Parent
		local player = Players:GetPlayerFromCharacter(character)

		if not player then
			print("Player not found")
			return
		end
		print("Player found", player.Name)
		if plot:GetAttribute("OwnerId") ~= player.UserId then
			print("Player not owner")
			return
		end
		print("Player is owner")

		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then
			print("Leaderstats not found")
			return
		end
		print("Leaderstats found")
		local coins = leaderstats:FindFirstChild("Coins")
		print("Coins found", coins.Value)

		if coins.Value >= ButtonData.Price then
			isProcessing = true
			print("Button processing")
			coins.Value -= ButtonData.Price
			print("Coins deducted")

			local templateFolder = TycoonAssets:FindFirstChild(ButtonData.Type)
			print("Template folder found", ButtonData.Type)
			local templateItem = templateFolder and templateFolder:FindFirstChild(ButtonData.Target)
			print("Template item found", ButtonData.Target)

			if templateItem then
				local newObject = templateItem:Clone()
				newObject.Name = button.Name .. "_Asset"

				local PlacementNodesFolder = plot:FindFirstChild("PlacementNodes")
				local targetNode = PlacementNodesFolder and PlacementNodesFolder:FindFirstChild("Node_" .. button.Name)

				if targetNode then
					newObject:PivotTo(targetNode.CFrame)
					print("[DEBUG-ASSET] 📍 " .. button.Name .. " ditempatkan sesuai Node Koordinat.")
				else
					newObject:PivotTo(button.CFrame)
					warn("[DEBUG-ASSET] ⚠️ Node tidak ditemukan untuk ".. button.Name.. ", menggunakan posisi tombol.")
				end
				newObject:SetAttribute("IsActive", true)
				newObject.Parent = purchasedObjectsFolder:FindFirstChild(ButtonData.Type)
				print("Object placed", newObject.Name)
			end

			button:Destroy()
			print("Button destroyed")
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
