local Lighting = game:GetService("Lighting")
local isShadow = false
local function enforceLighting()
	Lighting.GlobalShadows = isShadow
	Lighting.FogEnd = 100000 
end

enforceLighting()