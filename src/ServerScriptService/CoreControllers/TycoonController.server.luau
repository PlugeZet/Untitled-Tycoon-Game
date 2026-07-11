local CollectionService = game:GetService("CollectionService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Configs = ReplicatedStorage:WaitForChild("Configs")
local ButtonConfig = require(Configs:WaitForChild("ButtonDependencyGraph"))

local Bindable = ServerStorage:WaitForChild("Bindable")
local BindEvents = Bindable:WaitForChild("Event")
local BindFunctions = Bindable:WaitForChild("Function")

local Plots = CollectionService:GetTagged("Plots")
local Buttons = CollectionService:GetTagged("Buttons")

local StarterPlotTemplate = ServerStorage:WaitForChild("StarterPlot", 5)
local TycoonAssets = ServerStorage:WaitForChild("TycoonAssets", 5)

local playersPurchased = {}

local function claimPlot(plot)
	local claimDoor = plot:WaitForChild("ClaimDoor", 5)

	if not claimDoor then
		warn("[WARN] ClaimDoor not found for plot: " .. tostring(plot.Name))
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

			local plotBillboard = plot:FindFirstChild("PlotBillboard")
			if plotBillboard then
				plotBillboard.PlotLabel.Text = player.Name .. "'s Plot"
				plotBillboard.Enabled = true
			end

			
			local coinSounds = SoundService:WaitForChild("PurchaseSounds")
			local randomSound = coinSounds:GetChildren()[math.random(1, #coinSounds:GetChildren())]
			randomSound:Play()

			claimDoor:Destroy()

			local GetAllPurchase = BindFunctions:WaitForChild("GetAllPurchase")
				if GetAllPurchase then
					local oldPurchaseData = GetAllPurchase:Invoke(player) or {}
                	playersPurchased["Player_" .. player.UserId] = oldPurchaseData
            	end
			end
			plot:SetAttribute("IsClaimed", true)
			player:SetAttribute("HasPlot", true)
	end)
end

local function applyPlotColor(model, color)
	local canApplyColor = model:GetAttribute("CanApplyColor")
	if canApplyColor == nil then
		return
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			if part:IsA("UnionOperation") then
				part.UsePartColor = true
			end

			if part.Material ~= Enum.Material.Neon then
				if part.Material == Enum.Material.Plastic then
					part.Color = color
				end
			end
		end
	end
end

local function initializePlot(plot)
	plot:GetAttributeChangedSignal("IsClaimed"):Connect(function()
		local isClaimed = plot:GetAttribute("IsClaimed")
		if not isClaimed then
			return
		end

		local masterClone = StarterPlotTemplate:Clone()
		local plotColor = plot:GetAttribute("PlotColor")

		if plotColor then
			applyPlotColor(masterClone, plotColor)
		end

		if plot.PrimaryPart and masterClone.PrimaryPart then
			masterClone:PivotTo(plot.PrimaryPart.CFrame)
		else
			warn("[WARN] Missing PrimaryPart on plot or template for " .. plot.Name)
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
					warn(
						"[WARN] Target folder destination '"
							.. tostring(targetFolder)
							.. "' not found in plot. Destroying asset: "
							.. clonedChild.Name
					)
					clonedChild:Destroy()
				end
			else
				local defaultFolder = plot:FindFirstChild("PurchasedObjects")
				if defaultFolder then
					clonedChild.Parent = defaultFolder
				else
					warn("[WARN] PurchasedObjects fallback folder not found. Destroying asset: " .. clonedChild.Name)
					clonedChild:Destroy()
				end
			end
		end
		
		local buttonFolder = plot:FindFirstChild("Buttons")
		
		local playerKey = "Player_" .. plot:GetAttribute("OwnerId")
		local savedList = playersPurchased[playerKey] or {}
		for _, asset in ipairs(TycoonAssets:GetChildren()) do 
			local assetName = asset.Name

			if table.find(savedList, assetName) then
				local ButtonData = ButtonConfig[assetName]
				if not ButtonData then continue end

				local templateFolder = TycoonAssets:FindFirstChild(ButtonData.Type)
				local templateItem = templateFolder and templateFolder:FindFirstChild(ButtonData.Target)

				if templateItem then 
					local newObject = templateItem:Clone()
					newObject.Name = assetName .. "_Asset"
					
					local PlacementNodesFolder = plot:FindFirstChild("PlacementNodes")
					local targetNode = PlacementNodesFolder and PlacementNodesFolder:FindFirstChild("Node_" .. assetName)
					
					if targetNode then
						newObject:PivotTo(targetNode.CFrame)
					end
	
					newObject:SetAttribute("IsActive", true)
					newObject.Parent = plot:FindFirstChild("PurchasedObjects"):FindFirstChild(ButtonData.Type)
					local destFolder = plot:FindFirstChild("PurchasedObjects")
                    if destFolder then
                        newObject.Parent = destFolder:FindFirstChild(ButtonData.Type) or destFolder
                    end
				end

				if buttonFolder and buttonFolder:FindFirstChild(assetName) then
                    buttonFolder:FindFirstChild(assetName):Destroy()
                end
			else
				local buttonSpecific = buttonFolder and buttonFolder:FindFirstChild(assetName)
                
                if buttonSpecific and assetName ~= "BtnDropper1" then
                    buttonSpecific.Transparency = 1
                    buttonSpecific.CanCollide = false
                    if buttonSpecific:FindFirstChild("ButtonPrice") then
                        buttonSpecific.ButtonPrice.Enabled = false
                    end
                end
			end
		end
		masterClone:Destroy()
	end)
end


local function setupButton(buttons)
	for _, button in ipairs(buttons) do
		local buttonData = ButtonConfig[button.Name]
		if buttonData == nil then
			print("[WARN] Configuration data missing for button name: " .. tostring(button.Name))
			return
		end
		local priceTag = button:FindFirstChild("ButtonPrice"):FindFirstChild("ButtonFrame")
		local buttonLabel = priceTag:FindFirstChild("ButtonLabel")
		local priceLabel = priceTag:FindFirstChild("ButtonPriceLabel")
		if priceLabel ~= nil and buttonLabel ~= nil then
			buttonLabel.Text = buttonData.Name
			priceLabel.Text = "$" .. buttonData.Price
		else
			print("[WARN] Visual text elements missing inside ButtonPrice for: " .. button.Name)
		end
	end
end

local function purchaseObject(button, plot)
	if not plot:IsDescendantOf(workspace) then
		return
	end
	local ButtonData = ButtonConfig[button.Name]

	if not ButtonData then
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

		task.spawn(function()
			local dependencyData = ButtonConfig[ButtonData.Dependency]
			local dependencyType = dependencyData.Type
			local UniqueObjectName = ButtonData.Dependency .. "_Asset"

			local categoryFolder = purchasedObjectsFolder:WaitForChild(dependencyType, math.huge)
			local readyObject = categoryFolder:WaitForChild(UniqueObjectName, math.huge)

			if readyObject then
				button.Transparency = 0
				button.CanCollide = true
				if priceGui then
					priceGui.Enabled = true
				end
			end
		end)
	end

	local ownerId = plot:GetAttribute("OwnerId")
	local player = Players:GetPlayerByUserId(ownerId)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins then
		if coins.Value >= ButtonData.Price then
			button.BrickColor = BrickColor.new("Lime green")
		else
			button.BrickColor = BrickColor.new("Really red")
		end

		coins.Changed:Connect(function(newValue)
			if newValue >= ButtonData.Price then
				button.BrickColor = BrickColor.new("Lime green")
			else
				button.BrickColor = BrickColor.new("Really red")
			end
		end)
	end

	button.Touched:Connect(function(otherPart)
		if isProcessing then
			return
		end
		if button.CanCollide == false then
			return
		end

		local character = otherPart.Parent
		local player = Players:GetPlayerFromCharacter(character)

		if not player then
			return
		end
		if plot:GetAttribute("OwnerId") ~= player.UserId then
			return
		end

		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then
			return
		end

		local coins = leaderstats:FindFirstChild("Coins")

		if coins.Value >= ButtonData.Price then
			isProcessing = true
			coins.Value -= ButtonData.Price

			local templateFolder = TycoonAssets:FindFirstChild(ButtonData.Type)
			local templateItem = templateFolder and templateFolder:FindFirstChild(ButtonData.Target)

			if templateItem then
				local newObject = templateItem:Clone()
				newObject.Name = button.Name .. "_Asset"

				local plotColor = plot:GetAttribute("PlotColor")
				if plotColor then
					applyPlotColor(newObject, plotColor)
				end

				local PlacementNodesFolder = plot:FindFirstChild("PlacementNodes")
				local targetNode = PlacementNodesFolder and PlacementNodesFolder:FindFirstChild("Node_" .. button.Name)

				if targetNode then
					newObject:PivotTo(targetNode.CFrame)
				else
					newObject:PivotTo(button.CFrame)
				end

				newObject:SetAttribute("IsActive", true)
				newObject.Parent = purchasedObjectsFolder:FindFirstChild(ButtonData.Type)

				local PurchaseEvent = BindEvents:WaitForChild("GetPurchaseData")
				if PurchaseEvent then
					print("Button " .. button.Name .. " Purchased")
					PurchaseEvent:Fire(player, button.Name)
				end

				local coinSounds = SoundService:WaitForChild("PurchaseSounds")
				local randomSound = coinSounds:GetChildren()[math.random(1, #coinSounds:GetChildren())]
				randomSound:Play()
			end

			button:Destroy()
		end
	end)
end

local function setupLaserGate(gateModel)
	local toggleButtonPart = gateModel:WaitForChild("ToggleButton")
	local clickDetector = toggleButtonPart:WaitForChild("ClickDetector")

	gateModel:SetAttribute("IsActive", false)
	local lasers = {}

	for _, laser in ipairs(gateModel:GetChildren()) do
		if laser:IsA("BasePart") and laser.Name ~= "ToggleButton" then
			laser.CanCollide = false
			table.insert(lasers, laser)

			laser.Touched:Connect(function(otherPart)
				if gateModel:GetAttribute("IsActive") == false then
					return
				end
				local character = otherPart.Parent
				local humanoid = character:FindFirstChild("Humanoid")

				if humanoid and humanoid.Health > 0 then
					local player = Players:GetPlayerFromCharacter(character)
					if not player then
						return
					end

					local plot = gateModel
					while plot and plot ~= workspace do
						if plot:GetAttribute("OwnerId") ~= nil then
							break
						end
						plot = plot.Parent
					end

					if plot and plot:GetAttribute("OwnerId") ~= player.UserId then
						humanoid.Health = 0
					end
				end
			end)
		end
	end

	local isDebounce = false

	clickDetector.MouseClick:Connect(function(playerClicker)
		if isDebounce then
			return
		end

		local plot = gateModel
		while plot and plot ~= workspace do
			if plot:GetAttribute("OwnerId") ~= nil then
				break
			end
			plot = plot.Parent
		end

		if plot and plot:GetAttribute("OwnerId") == playerClicker.UserId then
			isDebounce = true

			local isActive = gateModel:GetAttribute("IsActive")
			local newState = not isActive
			gateModel:SetAttribute("IsActive", newState)

			for _, laser in ipairs(lasers) do
				if newState == true then
					laser.BrickColor = BrickColor.new("Really red")
				else
					laser.BrickColor = BrickColor.new("Lime green")
				end
			end

			if newState == true then
				toggleButtonPart.Color = Color3.fromRGB(0, 255, 0)
			else
				toggleButtonPart.Color = Color3.fromRGB(255, 0, 0)
			end

			task.wait(1)
			isDebounce = false
		end
	end)
end

local function takeWeapon(weaponTube)
	local plot = weaponTube
	while plot and plot ~= workspace do
		if plot:GetAttribute("OwnerId") ~= nil then
			break
		end
		plot = plot.Parent
	end

	if not plot or plot == workspace then
		return
	end
	local giverButton = weaponTube:FindFirstChild("Giverpart") or weaponTube:FindFirstChild("GiverPart")
	if giverButton == nil then
		return
	end

	local weaponName = weaponTube:GetAttribute("WeaponName")
	local weaponTemplate = TycoonAssets:FindFirstChild("Weapons"):FindFirstChild(weaponName)
	local playerCooldowns = {}

	giverButton.Touched:Connect(function(otherPart)
		local character = otherPart.Parent
		local humanoid = character:FindFirstChild("Humanoid")
		local player = Players:GetPlayerFromCharacter(character)

		if not player or not humanoid or humanoid.Health <= 0 then
			return
		end

		if playerCooldowns[player.UserId] then
			return
		end

		local backpack = player:FindFirstChild("Backpack")
		local hasInHand = character:FindFirstChild(weaponName)
		local hasInBackpack = backpack and backpack:FindFirstChild(weaponName)

		if not hasInHand and not hasInBackpack then
			if weaponTemplate then
				playerCooldowns[player.UserId] = true

				local newWeapon = weaponTemplate:Clone()
				newWeapon.Parent = backpack

				task.wait(2)

				playerCooldowns[player.UserId] = nil
			else
			end
		else
		end
	end)
end

for _, plot in ipairs(Plots) do
	task.spawn(function()
		claimPlot(plot)
		initializePlot(plot)
	end)
end

setupButton(Buttons)

for _, button in ipairs(Buttons) do
	local plot = button.Parent:FindFirstAncestorOfClass("Model")
	if plot then
		purchaseObject(button, plot)
	end
end

CollectionService:GetInstanceAddedSignal("Buttons"):Connect(function(newButton)
	task.wait(0.1)
	setupButton({ newButton })
	local plot = newButton.Parent:FindFirstAncestorOfClass("Model")
	if plot then
		purchaseObject(newButton, plot)
	end
end)

for _, gate in ipairs(CollectionService:GetTagged("OwnerDoors")) do
	task.spawn(function()
		setupLaserGate(gate)
	end)
end

CollectionService:GetInstanceAddedSignal("OwnerDoors"):Connect(function(newGate)
	task.spawn(function()
		setupLaserGate(newGate)
	end)
end)

CollectionService:GetInstanceAddedSignal("Weapons"):Connect(function(newWeapon)
	task.defer(function()
		takeWeapon(newWeapon)
	end)
end)
