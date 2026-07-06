local Lighting = game:GetService("Lighting")
local isShadow = false
local function enforceLighting()
	print("[SYSTEM] Memaksa pengaturan Lighting ke mode tanpa bayangan...")
	Lighting.GlobalShadows = isShadow
	Lighting.Technology = Enum.Technology.Voxel
	Lighting.FogEnd = 100000 
end

enforceLighting()