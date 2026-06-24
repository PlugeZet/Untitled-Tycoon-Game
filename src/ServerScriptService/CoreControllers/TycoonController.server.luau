local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local StarterAssetsTemplate = ServerStorage:WaitForChild("StarterPlot")
local Plots = CollectionService:GetTagged("Plots")

local function claimPlot(plot)
	local claimDoor = plot:WaitForChild("ClaimDoor")

	claimDoor.Touched:Connect(function(otherPart)
		local character = otherPart.Parent
		local humanoid = character:FindFirstChild("Humanoid")
	
		if not humanoid then return end
		local player = game.Players:GetPlayerFromCharacter(character)

		if not player then return end

		if player:GetAttribute("HasPlot") then return end
		local playerId = player.UserId
		local ownerId = plot:GetAttribute("OwnerId")
		local isClaimed = plot:GetAttribute("IsClaimed")

		if isClaimed then return end
		
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
		local purchasedObjectsFolder = plot:FindFirstChild("PurchasedObjects")

		if not purchasedObjectsFolder then return end
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

for _, plot in ipairs(Plots) do
	claimPlot(plot)
	initializePlot(plot)
end
