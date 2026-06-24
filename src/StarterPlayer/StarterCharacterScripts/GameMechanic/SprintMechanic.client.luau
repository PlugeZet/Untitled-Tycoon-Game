local UserInputService = game:GetService("UserInputService")

local character = script.Parent.Parent
local humanoid = character:WaitForChild("Humanoid")

local sprintKey = Enum.KeyCode.LeftShift

local defaultSpeed = 16
local sprintSpeed = 24
local stamina = 100
local staminaCap = 100

local isSprinting = false

task.spawn(function()
	while true do
		if isSprinting then
			if stamina > 0 then
				stamina -= 1
				task.wait(.15)
			else
				isSprinting = false
				humanoid.WalkSpeed = defaultSpeed
			end
		else 
			if stamina < staminaCap then
				stamina += 1
			end
			task.wait(0.35)	
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	
	if input.KeyCode == sprintKey then
		isSprinting = true
		humanoid.WalkSpeed = sprintSpeed
	end
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == sprintKey then
		isSprinting = false
		humanoid.WalkSpeed = defaultSpeed
	end
end)