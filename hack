-- StarterPlayerScripts/DevTools.client.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("DevToolsRemote")

local states = {
	Fly = false,
	Noclip = false,
	ESP = false,
	AimAssist = false,
}

local character
local humanoid
local root

local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
end

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "DeveloperPanel"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(280, 330)
main.Position = UDim2.new(0, 30, 0.5, -165)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 55)
title.BackgroundTransparency = 1
title.Text = "DEV CONTROL"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.Parent = main

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -20, 0, 25)
subtitle.Position = UDim2.fromOffset(10, 45)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Developer Testing Panel"
subtitle.TextColor3 = Color3.fromRGB(160, 160, 170)
subtitle.TextSize = 12
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = main

--==================================================
-- 버튼
--==================================================

local buttons = {}

local function createToggle(name, text, y)
	local button = Instance.new("TextButton")

	button.Name = name
	button.Size = UDim2.new(1, -30, 0, 48)
	button.Position = UDim2.fromOffset(15, y)

	button.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
	button.BorderSizePixel = 0

	button.Text = text .. "    OFF"
	button.TextColor3 = Color3.fromRGB(220, 220, 220)
	button.TextSize = 15
	button.Font = Enum.Font.GothamMedium

	button.AutoButtonColor = false
	button.Parent = main

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = button

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	end)

	button.MouseLeave:Connect(function()
		if states[name] then
			button.BackgroundColor3 = Color3.fromRGB(50, 110, 70)
		else
			button.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
		end
	end)

	button.MouseButton1Click:Connect(function()
		remote:FireServer("Toggle", name)
	end)

	buttons[name] = {
		Button = button,
		Text = text,
	}

	return button
end

createToggle("Fly", "Fly", 85)
createToggle("Noclip", "Noclip", 140)
createToggle("ESP", "ESP", 195)
createToggle("AimAssist", "Aim Assist", 250)

--==================================================
-- 버튼 상태 업데이트
--==================================================

local function updateButton(name)
	local data = buttons[name]

	if not data then
		return
	end

	local button = data.Button
	local state = states[name]

	if state then
		button.Text = data.Text .. "    ON"
		button.BackgroundColor3 = Color3.fromRGB(50, 110, 70)
		button.TextColor3 = Color3.new(1, 1, 1)
	else
		button.Text = data.Text .. "    OFF"
		button.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
		button.TextColor3 = Color3.fromRGB(220, 220, 220)
	end
end

--==================================================
-- FLY
--==================================================

local flyConnection

local function stopFly()
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end

	if root then
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

local function startFly()
	stopFly()

	flyConnection = RunService.RenderStepped:Connect(function()
		if not states.Fly or not root then
			return
		end

		local camera = workspace.CurrentCamera
		local direction = Vector3.zero

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			direction += camera.CFrame.LookVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			direction -= camera.CFrame.LookVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			direction -= camera.CFrame.RightVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			direction += camera.CFrame.RightVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			direction += Vector3.yAxis
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			direction -= Vector3.yAxis
		end

		if direction.Magnitude > 0 then
			direction = direction.Unit
		end

		root.AssemblyLinearVelocity = direction * 60
	end)
end

--==================================================
-- NOCLIP
--==================================================

local noclipConnection

local function stopNoclip()
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end

	if character then
		for _, object in ipairs(character:GetDescendants()) do
			if object:IsA("BasePart") then
				object.CanCollide = true
			end
		end
	end
end

local function startNoclip()
	stopNoclip()

	noclipConnection = RunService.Stepped:Connect(function()
		if not states.Noclip or not character then
			return
		end

		for _, object in ipairs(character:GetDescendants()) do
			if object:IsA("BasePart") then
				object.CanCollide = false
			end
		end
	end)
end

--==================================================
-- ESP
--==================================================

local espObjects = {}

local function clearESP()
	for _, object in pairs(espObjects) do
		if object then
			object:Destroy()
		end
	end

	table.clear(espObjects)
end

local function updateESP()
	clearESP()

	if not states.ESP then
		return
	end

	local folder = workspace:FindFirstChild("AimTargets")

	if not folder then
		return
	end

	for _, target in ipairs(folder:GetChildren()) do
		if target:IsA("Model") then
			local highlight = Instance.new("Highlight")

			highlight.Name = "DeveloperESP"
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.FillTransparency = 0.7
			highlight.OutlineTransparency = 0
			highlight.Parent = target

			espObjects[target] = highlight
		end
	end
end

--==================================================
-- AIM ASSIST
--==================================================

local aimConnection

local function getClosestTarget()
	local folder = workspace:FindFirstChild("AimTargets")

	if not folder or not root then
		return nil
	end

	local camera = workspace.CurrentCamera
	local center = camera.ViewportSize / 2

	local closestTarget
	local closestDistance = math.huge

	for _, target in ipairs(folder:GetChildren()) do
		if target:IsA("Model") then
			local targetRoot =
				target:FindFirstChild("HumanoidRootPart")
				or target.PrimaryPart

			local targetHumanoid =
				target:FindFirstChildOfClass("Humanoid")

			if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
				local position, visible =
					camera:WorldToViewportPoint(targetRoot.Position)

				if visible and position.Z > 0 then
					local screenPosition =
						Vector2.new(position.X, position.Y)

					local distance =
						(screenPosition - center).Magnitude

					if distance < closestDistance then
						closestDistance = distance
						closestTarget = targetRoot
					end
				end
			end
		end
	end

	return closestTarget
end

local function stopAimAssist()
	if aimConnection then
		aimConnection:Disconnect()
		aimConnection = nil
	end
end

local function startAimAssist()
	stopAimAssist()

	aimConnection = RunService.RenderStepped:Connect(function()
		if not states.AimAssist then
			return
		end

		local target = getClosestTarget()

		if not target then
			return
		end

		local camera = workspace.CurrentCamera

		local targetCFrame =
			CFrame.lookAt(
				camera.CFrame.Position,
				target.Position
			)

		camera.CFrame =
			camera.CFrame:Lerp(targetCFrame, 0.12)
	end)
end

--==================================================
-- 기능 ON / OFF
--==================================================

local function setFeature(name, enabled)
	states[name] = enabled

	updateButton(name)

	if name == "Fly" then
		if enabled then
			startFly()
		else
			stopFly()
		end

	elseif name == "Noclip" then
		if enabled then
			startNoclip()
		else
			stopNoclip()
		end

	elseif name == "ESP" then
		updateESP()

	elseif name == "AimAssist" then
		if enabled then
			startAimAssist()
		else
			stopAimAssist()
		end
	end
end

--==================================================
-- 서버 이벤트
--==================================================

remote.OnClientEvent:Connect(function(action, value)
	if action == "Authorized" then
		gui.Enabled = true

	elseif action == "Toggle" then
		setFeature(value, not states[value])
	end
end)
