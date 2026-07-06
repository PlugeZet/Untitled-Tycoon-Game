local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Configs = ReplicatedStorage:WaitForChild("Configs")
local ButtonConfig = require(Configs:WaitForChild("ButtonDependencyGraph"))

local Plots = CollectionService:GetTagged("Plots")
local Buttons = CollectionService:GetTagged("Buttons")

local StarterPlotTemplate = ServerStorage:WaitForChild("StarterPlot", 5)
local TycoonAssets = ServerStorage:WaitForChild("TycoonAssets", 5)

local function claimPlot(plot)
    print("[INIT] Setting up claim logic for plot: " .. tostring(plot.Name))
    local claimDoor = plot:WaitForChild("ClaimDoor", 5)

    if not claimDoor then 
        warn("[WARN] ClaimDoor not found for plot: " .. tostring(plot.Name))
        return 
    end

    claimDoor.Touched:Connect(function(otherPart)
        local character = otherPart.Parent
        local humanoid = character:FindFirstChild("Humanoid")

        if not humanoid then return end

        local player = game.Players:GetPlayerFromCharacter(character)
        if not player then return end

        local playerId = player.UserId
        local ownerId = plot:GetAttribute("OwnerId")
        local isClaimed = plot:GetAttribute("IsClaimed")
        
        if isClaimed then return end
        
        if ownerId == nil or ownerId == 0 then
            print("[CLAIM] Player " .. player.Name .. " is attempting to claim " .. plot.Name)
            plot:SetAttribute("OwnerId", playerId)
            plot:SetAttribute("OwnerName", player.Name)
            
            local plotBillboard = plot:FindFirstChild("PlotBillboard")
            if plotBillboard then
                plotBillboard.PlotLabel.Text = player.Name .. "'s Plot"
                plotBillboard.Enabled = true
            end

            plot:SetAttribute("IsClaimed", true)
            player:SetAttribute("HasPlot", true)

            print("[CLAIM] Successfully registered claim for " .. player.Name)
            claimDoor:Destroy()
        end
    end)
end

local function applyPlotColor(model, color)
    local canApplyColor = model:GetAttribute("CanApplyColor")
    if canApplyColor == nil then return end
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
        print("[PLOT-INIT] IsClaimed changed to " .. tostring(isClaimed) .. " for " .. plot.Name)
        if not isClaimed then return end

        print("[PLOT-INIT] Spawning master clone for " .. plot.Name)
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

        local buttonFolder = masterClone:FindFirstChild("Buttons")
        if buttonFolder then
            print("[PLOT-INIT] Initializing button visibilities inside template")
            for _, button in ipairs(buttonFolder:GetChildren()) do
                if button.Name ~= "BtnDropper1" then
                    button.Transparency = 1
                    button.CanCollide = false
                    button.ButtonPrice.Enabled = false
                end
            end
        end

        print("[PLOT-INIT] Distributing assets from master template to destinations")
        for _, clonedChild in ipairs(masterClone:GetChildren()) do
            local targetFolder = clonedChild:GetAttribute("Destination")
            
            if targetFolder == "Plot" or targetFolder == "plot" then
                clonedChild.Parent = plot
            elseif targetFolder ~= nil then
                local destination = plot:FindFirstChild(targetFolder)
                if destination then
                    clonedChild.Parent = destination
                else
                    warn("[WARN] Target folder destination '" .. tostring(targetFolder) .. "' not found in plot. Destroying asset: " .. clonedChild.Name)
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
        masterClone:Destroy()
        print("[PLOT-INIT] Master template distribution completed for " .. plot.Name)
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
        print("[PURCHASE] Blocked instantiation. Button " .. button.Name .. " is not inside workspace hierarchy.")
        return 
    end
    local ButtonData = ButtonConfig[button.Name]

    if not ButtonData then 
        print("[PURCHASE] Aborted. No matching data entry for button: " .. tostring(button.Name))
        return 
    end

    local purchasedObjectsFolder = plot:FindFirstChild("PurchasedObjects")
    local isProcessing = false
    
    if ButtonData.Dependency ~= nil then
        print("[DEPENDENCY] Hiding " .. button.Name .. " until requirement is met: " .. tostring(ButtonData.Dependency))
        button.Transparency = 1
        button.CanCollide = false
        local priceGui = button:FindFirstChild("ButtonPrice")

        if priceGui then priceGui.Enabled = false end

        task.spawn(function()
            local dependencyData = ButtonConfig[ButtonData.Dependency]
            local dependencyType = dependencyData.Type
            local UniqueObjectName = ButtonData.Dependency .. "_Asset"

            local categoryFolder = purchasedObjectsFolder:WaitForChild(dependencyType, math.huge)
            local readyObject = categoryFolder:WaitForChild(UniqueObjectName, math.huge)

            if readyObject then
                print("[DEPENDENCY] Conditions verified. Unlocking button: " .. button.Name)
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
        if isProcessing then return end
        if button.CanCollide == false then return end
        
        local character = otherPart.Parent
        local player = Players:GetPlayerFromCharacter(character)

        if not player then return end
        if plot:GetAttribute("OwnerId") ~= player.UserId then return end

        local leaderstats = player:FindFirstChild("leaderstats")
        if not leaderstats then 
            print("[WARN] Verification failed. Player leaderstats folder missing.")
            return 
        end
        
        local coins = leaderstats:FindFirstChild("Coins")

        if coins.Value >= ButtonData.Price then
            isProcessing = true
            print("[TRANSACTION] Processing purchase. Player: " .. player.Name .. " | Button: " .. button.Name .. " | Cost: " .. tostring(ButtonData.Price))
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
                    print("[DEPLOYMENT] Object " .. newObject.Name .. " snapped to targeted Node placement structure.")
                else
                    newObject:PivotTo(button.CFrame)
                    print("[DEPLOYMENT] Node not found. Defaulting " .. newObject.Name .. " to button footprint position.")
                end
                
                newObject:SetAttribute("IsActive", true)
                newObject.Parent = purchasedObjectsFolder:FindFirstChild(ButtonData.Type)
                print("[DEPLOYMENT] Successfully spawned and parented: " .. newObject.Name)
            else
                warn("[WARN] Critical failure. Target source item missing inside TycoonAssets location: " .. tostring(ButtonData.Target))
            end

            button:Destroy()
        end
    end)
end

local function setupLaserGate(gateModel)
    print("[LASER-INIT] Initiating setup configuration routines for gate: " .. tostring(gateModel.Name))
    local toggleButtonPart = gateModel:WaitForChild("ToggleButton")
    local clickDetector = toggleButtonPart:WaitForChild("ClickDetector")
    
    gateModel:SetAttribute("IsActive", false)
    local lasers = {}

    for _, laser in ipairs(gateModel:GetChildren()) do
        if laser:IsA("BasePart") and laser.Name ~= "ToggleButton" then
            laser.CanCollide = false
            table.insert(lasers, laser)

            laser.Touched:Connect(function(otherPart)
                if gateModel:GetAttribute("IsActive") == false then return end
                local character = otherPart.Parent
                local humanoid = character:FindFirstChild("Humanoid")
                
                if humanoid and humanoid.Health > 0 then
                    local player = Players:GetPlayerFromCharacter(character)
                    if not player then return end
                    
                    local plot = gateModel
                    while plot and plot ~= workspace do
                        if plot:GetAttribute("OwnerId") ~= nil then break end
                        plot = plot.Parent
                    end

                    if plot and plot:GetAttribute("OwnerId") ~= player.UserId then 
                        print("[LASER-KILL] Intruder eliminated: " .. player.Name .. " crossed gate on plot owned by User ID " .. tostring(plot:GetAttribute("OwnerId")))
                        humanoid.Health = 0
                    end
                end
            end)
        end
    end

    local isDebounce = false
    
    clickDetector.MouseClick:Connect(function(playerClicker)
        print("[LASER-INTERACT] Interaction click received from player: " .. playerClicker.Name)
        if isDebounce then return end

        local plot = gateModel
        while plot and plot ~= workspace do
            if plot:GetAttribute("OwnerId") ~= nil then break end
            plot = plot.Parent
        end

        if plot and plot:GetAttribute("OwnerId") == playerClicker.UserId then
            isDebounce = true
            
            local isActive = gateModel:GetAttribute("IsActive")
            local newState = not isActive
            gateModel:SetAttribute("IsActive", newState)
            print("[LASER-TOGGLE] Authorization match verified. Power toggled to state value: " .. tostring(newState))
            
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
        else
            print("[LASER-INTERACT] Denied. Player " .. playerClicker.Name .. " does not match system owner validation credentials.")
        end 
    end)
end

local function takeWeapon(weaponTube)
    print("[WEAPON-INIT] Registering pickup mechanics for system capsule assembly: " .. tostring(weaponTube.Name))
    local plot = weaponTube
    
    print("[WEAPON-DEBUG] Memulai pelacakan root Plot (Tree Climbing)...")
    while plot and plot ~= workspace do
        print("[WEAPON-DEBUG] Sedang memeriksa leluhur: " .. tostring(plot.Name))
        if plot:GetAttribute("OwnerId") ~= nil then 
            print("[WEAPON-DEBUG] Ditemukan atribut OwnerId pada: " .. tostring(plot.Name))
            break 
        end
        plot = plot.Parent
    end

    print("[WEAPON-DEBUG] Memvalidasi hasil pencarian Plot...")
    if not plot or plot == workspace then 
        warn("[WARN] Aborting setup. Tree tracing could not resolve root plot object for tube source: " .. weaponTube.Name)
        return 
    end
    print("[WEAPON-DEBUG] Plot validasi sukses. Plot name: " .. tostring(plot.Name))

    print("[WEAPON-DEBUG] Mencari komponen GiverPart...")
    local giverButton = weaponTube:FindFirstChild("Giverpart") or weaponTube:FindFirstChild("GiverPart")
    if giverButton == nil then 
        warn("[WARN] Setup halted. No physically interacting touch pad element detected inside model: " .. weaponTube.Name)
        return 
    end
    print("[WEAPON-DEBUG] GiverPart ditemukan.")

    local ownerId = plot:GetAttribute("OwnerId")
    local weaponName = weaponTube:GetAttribute("WeaponName")
    print("[WEAPON-DEBUG] Data diekstraksi - Target Weapon: " .. tostring(weaponName) .. " | OwnerId: " .. tostring(ownerId))
    
    print("[WEAPON-DEBUG] Memeriksa ketersediaan template senjata di ReplicatedStorage...")
    local weaponTemplate = TycoonAssets:FindFirstChild("Weapons"):FindFirstChild(weaponName)
    
    if weaponTemplate then
        print("[WEAPON-DEBUG] Template senjata (" .. tostring(weaponName) .. ") siap digunakan.")
    else
        warn("[WEAPON-DEBUG] Peringatan: Template senjata tidak ditemukan di awal setup!")
    end

    local playerCooldowns = {}
    
    giverButton.Touched:Connect(function(otherPart)
        print("[WEAPON-TOUCH] Sensor disentuh oleh part: " .. tostring(otherPart.Name))
        
        local character = otherPart.Parent
        local humanoid = character:FindFirstChild("Humanoid")
        local player = Players:GetPlayerFromCharacter(character)

        print("[WEAPON-TOUCH] Memvalidasi apakah entitas adalah karakter pemain yang hidup...")
        if not player or not humanoid or humanoid.Health <= 0 then 
            print("[WEAPON-TOUCH] Ditolak: Entitas bukan pemain, atau sudah mati.")
            return 
        end
        print("[WEAPON-TOUCH] Entitas valid: " .. player.Name)
        
        print("[WEAPON-TOUCH] Memeriksa otoritas kepemilikan plot...")
        if player.UserId ~= ownerId then 
            print("[WEAPON-TOUCH] Ditolak: " .. player.Name .. " (ID: " .. player.UserId .. ") bukan pemilik plot (Owner ID: " .. tostring(ownerId) .. ")")
            return 
        end
        print("[WEAPON-TOUCH] Otoritas kepemilikan cocok.")
        
        print("[WEAPON-TOUCH] Memeriksa status cooldown pemain...")
        if playerCooldowns[player.UserId] then 
            print("[WEAPON-TOUCH] Ditolak: " .. player.Name .. " masih dalam masa cooldown.")
            return 
        end
        print("[WEAPON-TOUCH] Pemain bebas dari cooldown.")
        
        local backpack = player:FindFirstChild("Backpack")
        local hasInHand = character:FindFirstChild(weaponName)
        local hasInBackpack = backpack and backpack:FindFirstChild(weaponName)
        
        print("[WEAPON-TOUCH] Memeriksa isi inventory (Backpack & Tangan) untuk senjata: " .. tostring(weaponName))
        if not hasInHand and not hasInBackpack then
            print("[WEAPON-TOUCH] Inventory aman. Pemain belum memiliki senjata ini.")
            
            if weaponTemplate then
                print("[WEAPON-TOUCH] Memulai proses kloning item...")
                playerCooldowns[player.UserId] = true
                
                local newWeapon = weaponTemplate:Clone()
                newWeapon.Parent = backpack
                print("[WEAPON-GIVER] Distributed item " .. weaponName .. " into character inventory for: " .. player.Name)
                
                print("[WEAPON-DEBUG] Menerapkan jeda cooldown 2 detik untuk " .. player.Name)
                task.wait(2)
                
                playerCooldowns[player.UserId] = nil 
                print("[WEAPON-DEBUG] Cooldown selesai dilepas untuk " .. player.Name)
            else
                warn("[WARN] Execution stopped. Item template asset name reference lookup resulted in nil for string target: " .. tostring(weaponName))
            end
        else
            print("[WEAPON-TOUCH] Ditolak: " .. player.Name .. " sudah memegang atau menyimpan senjata ini di dalam tasnya.")
        end
    end)
end

print("[STARTUP] Global environment maps parsing operations initialized")

for _, plot in ipairs(Plots) do
    claimPlot(plot)
    initializePlot(plot)
end

print("[STARTUP] Iterating structural tags for default runtime configuration instances")
setupButton(Buttons)

for _, button in ipairs(Buttons) do
    local plot = button.Parent:FindFirstAncestorOfClass("Model")
    if plot then
        purchaseObject(button, plot)
    end
end

CollectionService:GetInstanceAddedSignal("Buttons"):Connect(function(newButton)
    print("[DYNAMIC-LOAD] Dynamic setup call routed to freshly added instance instance: " .. newButton.Name)
    task.wait(0.1)
    setupButton({newButton})
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
    print("[DYNAMIC-LOAD] Setup pipeline hook routed to newly replicated laser system: " .. newGate.Name)
    task.spawn(function()
        setupLaserGate(newGate)
    end)
end)

CollectionService:GetInstanceAddedSignal("Weapons"):Connect(function(newWeapon)
    print("[DYNAMIC-LOAD] Setup pipeline hook routed to newly replicated equipment supply assembly: " .. newWeapon.Name)
    
    task.defer(function()
        takeWeapon(newWeapon)
    end)
end)

print("[STARTUP] Master framework event maps connection bindings binding pipelines fully complete")