-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Debris = game:GetService("Debris")

-- local GunConfig = ReplicatedStorage.Configs:WaitForChild("GunConfig")
-- local ShootingEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GunShootingEvent")

-- local GUN_NAME = GunConfig.Pistol.Name
-- local GUN_DAMAGE = GunConfig.Pistol.Damage
-- local BULLET_SPEED = GunConfig.Pistol.BulletSpeed
-- local BULLET_COLOR = GunConfig.Pistol.BulletColor

-- ShootingEvent.OnServerEvent:Connect(function(player,weaponName, originalPos, targetPos)
-- 	local shooterChar = player.Character
-- 	if not shooterChar then return end

-- 	local bullet = Instance.new("Part")
-- 	bullet.Size = Vector3.new(0.6, 0.6, 0.6)
-- 	bullet.Shape = Enum.PartType.Ball
-- 	bullet.Material = Enum.Material.Neon
-- 	bullet.Color = Color3.fromRGB(255, 230, 50)
	
-- 	local anchor = Instance.new("Attachment")
-- 	anchor.Parent = bullet

-- 	local antiGravity = Instance.new("VectorForce")
-- 	antiGravity.Attachment0 = anchor
-- 	antiGravity.RelativeTo = Enum.ActuatorRelativeTo.World

-- 	local liftForce = bullet.Mass * workspace.Gravity
-- 	antiGravity.Force = Vector3.new(0, liftForce, 0)
-- 	antiGravity.Parent = bullet

-- 	bullet.CanCollide = false
-- 	bullet.Position = originalPos
-- 	bullet.Parent = workspace

-- 	local direction = (targetPos - originalPos).Unit
-- 	bullet.AssemblyLinearVelocity = direction * BULLET_SPEED

-- 	Debris:AddItem(bullet, 3)

-- 	bullet.Touched:Connect(function(otherPart)
-- 		local targetChar = otherPart.Parent
-- 		local humanoid = targetChar:FindFirstChildOfClass("Humanoid")

-- 		if not humanoid and targetChar.Parent then
-- 			humanoid = targetChar.Parent:FindFirstChildOfClass("Humanoid")
-- 			targetChar = targetChar.Parent
-- 		end

-- 		if humanoid and targetChar.Name ~= player.Name then
-- 			humanoid.Health -= GUN_DAMAGE

-- 			bullet:Destroy()
-- 		end
-- 	end)
-- end)