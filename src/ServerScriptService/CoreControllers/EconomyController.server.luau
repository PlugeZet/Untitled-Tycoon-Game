-- =================================
-- Initialize
-- =================================

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
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
	if not nozzle then return end

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
		task.wait(2)		
	end	
end

local function setupConveyor(conveyor)
	local texture = conveyor:WaitForChild("ConveyorTexture", 5)
	if texture then
		texture.StudsPerTileU = conveyor.Size.Z
		texture.StudsPerTileV = conveyor.Size.Z

		conveyor.Anchored = true
		conveyor.AssemblyLinearVelocity = conveyor.CFrame.RightVector * -conveyorSpeed

		local info = TweenInfo.new(60, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1)
		local tween = TweenService:Create(texture, info, {OffsetStudsU = conveyorSpeed * -60})
		tween:Play()
	end
end

local function setupUpgrader(upgrader)
	local upgraderRay = upgrader:WaitForChild("UpgraderRay", 5)
	if upgraderRay then
		upgraderRay.Touched:Connect(function(otherPart)
			local ownerId = otherPart:GetAttribute("OwnerId")
			local price = otherPart:GetAttribute("Price")
			local isUpgraded = otherPart:GetAttribute("UpgradedBy_" .. upgrader.Name)

			if ownerId and price and not isUpgraded then
				otherPart:SetAttribute("UpgradedBy_" .. upgrader.Name, true)

				local player = Players:GetPlayerByUserId(ownerId)
				if player then
					local priceMultiplier = upgrader:GetAttribute("PriceMultiplier")
					local sizeMultiplier = upgrader:GetAttribute("SizeMultiplier")
					
					otherPart.Size *= sizeMultiplier
					otherPart:SetAttribute("Price", price * priceMultiplier)
				end
			end
		end)
	end
end

local function setupCollector(collector)
	local collectPart = collector:WaitForChild("CollectPart", 5)
	if not collectPart then return end
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
	task.spawn(function() spawnItem(dropper) end)
end

local function activateConveyor(conveyor)
	local isActive = conveyor:GetAttribute("IsActive")
	if isActive then
		task.spawn(function() setupConveyor(conveyor) end)
	end

	conveyor:GetAttributeChangedSignal("IsActive"):Connect(function()
		if conveyor:GetAttribute("IsActive") then
			setupConveyor(conveyor)
		end
	end)
end

local function activateUpgrader(upgrader)
	task.spawn(function() setupUpgrader(upgrader) end)
end

local function activateCollector(collector)
	task.spawn(function() setupCollector(collector) end)
end

-- =================================
-- Master Loop
-- =================================

for _, dropper in ipairs(Droppers) do activateDropper(dropper) end
CollectionService:GetInstanceAddedSignal("Droppers"):Connect(activateDropper)

for _, conveyor in ipairs(Conveyors) do activateConveyor(conveyor) end
CollectionService:GetInstanceAddedSignal("Conveyors"):Connect(activateConveyor)

for _, upgrader in ipairs(Upgraders) do activateUpgrader(upgrader) end
CollectionService:GetInstanceAddedSignal("Upgraders"):Connect(activateUpgrader)

for _, collector in ipairs(Collectors) do activateCollector(collector) end
CollectionService:GetInstanceAddedSignal("Collectors"):Connect(activateCollector)