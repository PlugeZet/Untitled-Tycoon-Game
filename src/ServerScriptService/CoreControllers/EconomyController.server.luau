-- =================================
-- Initialize
-- =================================

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Droppers = CollectionService:GetTagged("Droppers")
local Conveyors = CollectionService:GetTagged("Conveyors")
local Upgraders = CollectionService:GetTagged("Upgraders")
local Collectors = CollectionService:GetTagged("Collectors")

local ItemTemplate = ServerStorage.TycoonAssets:WaitForChild("Drops").Drop
local conveyorSpeed = 10

-- =================================
-- Functions
-- =================================

local function spawnItem(dropper)
	local nozzle = dropper:WaitForChild("Nozzle", 5)
	if not nozzle then
		return
	end

	while true do
		local isActive = dropper:GetAttribute("IsActive")

		if isActive then
			local clonedItem = ItemTemplate:Clone()
			local ownerId = dropper.Parent.Parent.Parent:GetAttribute("OwnerId")
			local price = dropper:GetAttribute("DropPrice")
			local PriceLabel = clonedItem:FindFirstChild("DropPrice").PriceLabel

			clonedItem:SetAttribute("OwnerId", ownerId)
			clonedItem:SetAttribute("Price", price)
			PriceLabel.Text = "$" .. price

			clonedItem.CFrame = nozzle.CFrame
			clonedItem.Parent = workspace:WaitForChild("DropHandler")
			Debris:AddItem(clonedItem, 20)
		end
		task.wait(5)
	end
end

local function setupConveyor(conveyor)
	local texture = conveyor:WaitForChild("ConveyorTexture", 5)
	conveyor.Anchored = true
	conveyor.AssemblyLinearVelocity = conveyor.CFrame.RightVector * -conveyorSpeed

	if texture then
		texture.StudsPerTileU = conveyor.Size.Z
		texture.StudsPerTileV = conveyor.Size.Z
	end
end

local function setupUpgrader(upgrader)
	local upgraderRay = upgrader:WaitForChild("UpgraderRay", 5)
	if not upgraderRay then
		return
	end

	local priceMultiplier = upgrader:GetAttribute("PriceMultiplier") or 2
	local sizeMultiplier = upgrader:GetAttribute("SizeMultiplier") or 1.2

	upgraderRay.Touched:Connect(function(otherPart)
		local ownerId = otherPart:GetAttribute("OwnerId")
		local currentPrice = otherPart:GetAttribute("Price")

		if not ownerId or not currentPrice then
			return
		end

		local upgraderKey = "UpgradedBy_" .. upgrader.Name
		local isUpgraded = otherPart:GetAttribute(upgraderKey)

		if not isUpgraded then
			otherPart:SetAttribute(upgraderKey, true)

			local player = Players:GetPlayerByUserId(ownerId)

			if player then
				local newPrice = currentPrice * priceMultiplier

				otherPart.Size *= sizeMultiplier
				otherPart:SetAttribute("Price", newPrice)

				local dropPriceGUI = otherPart:FindFirstChild("DropPrice")
				if dropPriceGUI then
					local priceLabel = dropPriceGUI:FindFirstChild("PriceLabel")
					if priceLabel then
						priceLabel.Text = "$" .. tostring(newPrice)
					end
				end
			end
		end
	end)
end

local function setupCollector(collector)
	local collectPart = collector:WaitForChild("CollectPart", 5)
	if not collectPart then
		return
	end
	collectPart.Touched:Connect(function(otherPart)
		local ownerId = otherPart:GetAttribute("OwnerId")
		local price = otherPart:GetAttribute("Price")

		if ownerId and price then
			local player = Players:GetPlayerByUserId(ownerId)
			if player then
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats then
					local coins = leaderstats:FindFirstChild("Coins")
					if coins then
						coins.Value += price
					end
				end
			end
			otherPart:Destroy()
		end
	end)
end

-- =================================
-- Activators
-- =================================

local function activateDropper(dropper)
	task.spawn(function()
		spawnItem(dropper)
	end)
end

local function activateConveyor(conveyor)
	local isActive = conveyor:GetAttribute("IsActive")
	if isActive then
		task.spawn(function()
			setupConveyor(conveyor)
		end)
	end

	conveyor:GetAttributeChangedSignal("IsActive"):Connect(function()
		if conveyor:GetAttribute("IsActive") then
			task.spawn(function()
				setupConveyor(conveyor)
			end)
		end
	end)
end

local function activateUpgrader(upgrader)
	task.spawn(function()
		setupUpgrader(upgrader)
	end)
end

local function activateCollector(collector)
	task.spawn(function()
		setupCollector(collector)
	end)
end

-- =================================
-- Master Loop
-- =================================

for _, dropper in ipairs(Droppers) do
	activateDropper(dropper)
end
CollectionService:GetInstanceAddedSignal("Droppers"):Connect(activateDropper)

for _, conveyor in ipairs(Conveyors) do
	activateConveyor(conveyor)
end
CollectionService:GetInstanceAddedSignal("Conveyors"):Connect(activateConveyor)

for _, upgrader in ipairs(Upgraders) do
	activateUpgrader(upgrader)
end
CollectionService:GetInstanceAddedSignal("Upgraders"):Connect(activateUpgrader)

for _, collector in ipairs(Collectors) do
	activateCollector(collector)
end
CollectionService:GetInstanceAddedSignal("Collectors"):Connect(activateCollector)
