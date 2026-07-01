local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local conveyorSpeed = 10

RunService.RenderStepped:Connect(function(deltaTime)
	local belts = CollectionService:GetTagged("Conveyors")
	for _, belt in ipairs(belts) do
		local texture = belt:FindFirstChild("ConveyorTexture")
		if texture then
			texture.OffsetStudsU = texture.OffsetStudsU - (conveyorSpeed * deltaTime)
		end
	end
end)