--[[
	Commands/PlayerCommands.lua
	Infinite Yield LocalPlayer Commands (Movement, Flight, Character Physics, World/Visuals, Utility)
	Persists across character respawns automatically and supports clean session removal.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer

local PlayerCommands = {}

PlayerCommands.State = {
	-- Speed & Movement
	SpeedBoost = false,
	SpeedAmount = 50,
	DefaultWalkSpeed = 16,
	TPWalk = false,
	TPWalkSpeed = 2,

	-- Jump
	JumpBoost = false,
	JumpAmount = 100,
	DefaultJumpPower = 50,
	DefaultJumpHeight = 7.2,
	InfiniteJump = false,
	FlyJump = false,

	-- Flight (Infinite Yield)
	Fly = false,
	FlySpeed = 60,
	CFrameFly = false,
	Float = false,
	Swim = false,

	-- Character & Physics (Infinite Yield)
	Noclip = false,
	Spin = false,
	SpinSpeed = 25,
	WalkFling = false,
	AntiFling = false,
	AntiVoid = false,
	FreezeSelf = false,

	-- World, Camera & Visuals (Infinite Yield)
	Fullbright = false,
	NoFog = false,
	XRay = false,
	ESPAll = false,
	Gravity = 196.2,
	FOV = 70,
	MaxZoom = 128,
	NoclipCamera = false,

	-- Utility
	ClickTP = false,
	AntiAFK = false,
	InstantPrompts = false,
}

local State = PlayerCommands.State
local NotifyFunc = nil
local ActiveConnections = {}

local function trackConn(conn)
	table.insert(ActiveConnections, conn)
	return conn
end

function PlayerCommands.SetNotifier(fn)
	NotifyFunc = fn
end

local function notify(title, subtitle)
	if NotifyFunc then
		NotifyFunc({ Title = title, Subtitle = subtitle, Type = "Regular", Duration = 2.2 })
	end
end

local function getRoot(char)
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("Torso")
		or char:FindFirstChild("UpperTorso")
end

--------------------------------------------------------------------------------
-- 1. SPEED & JUMP
--------------------------------------------------------------------------------
function PlayerCommands.ApplyMovement()
	local char = LocalPlayer and LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	if State.SpeedBoost then
		hum.WalkSpeed = State.SpeedAmount
	else
		hum.WalkSpeed = State.DefaultWalkSpeed
	end

	if State.JumpBoost then
		pcall(function()
			hum.UseJumpPower = true
			hum.JumpPower = State.JumpAmount
		end)
	else
		pcall(function()
			hum.JumpPower = State.DefaultJumpPower
			hum.JumpHeight = State.DefaultJumpHeight
		end)
	end
end

-- Infinite Jump & Fly Jump (IY infjump / flyjump)
trackConn(UserInputService.JumpRequest:Connect(function()
	if not State.InfiniteJump and not State.FlyJump then return end
	local char = LocalPlayer and LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end))

--------------------------------------------------------------------------------
-- 2. FLIGHT: VELOCITY FLY, CFRAME FLY, FLOAT PLATFORM, SWIM IN AIR (IY)
--------------------------------------------------------------------------------
local FlyBodyVelocity = nil
local FlyBodyGyro = nil

function PlayerCommands.StopVelocityFly()
	if FlyBodyVelocity then
		FlyBodyVelocity:Destroy()
		FlyBodyVelocity = nil
	end
	if FlyBodyGyro then
		FlyBodyGyro:Destroy()
		FlyBodyGyro = nil
	end
	local char = LocalPlayer and LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and not State.CFrameFly then
		hum.PlatformStand = false
	end
end

local CFFlyLoop = nil
function PlayerCommands.SetCFrameFly(enabled)
	State.CFrameFly = enabled
	if CFFlyLoop then
		CFFlyLoop:Disconnect()
		CFFlyLoop = nil
	end
	local char = LocalPlayer and LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local head = char and char:FindFirstChild("Head")

	if not enabled then
		if hum then hum.PlatformStand = false end
		if head then head.Anchored = false end
		return
	end

	if hum then hum.PlatformStand = true end
	if head then head.Anchored = true end

	CFFlyLoop = RunService.Heartbeat:Connect(function(dt)
		local c = LocalPlayer and LocalPlayer.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local hd = c and c:FindFirstChild("Head")
		local cam = workspace.CurrentCamera
		if not c or not h or not hd or not cam then return end

		h.PlatformStand = true
		hd.Anchored = true

		local moveDir = h.MoveDirection * (State.FlySpeed * dt)
		local headCF = hd.CFrame
		local camCF = cam.CFrame
		local camOffset = headCF:ToObjectSpace(camCF).Position
		camCF = camCF * CFrame.new(-camOffset.X, -camOffset.Y, -camOffset.Z + 1)
		local camPos = camCF.Position
		local headPos = headCF.Position

		local objVel = CFrame.new(camPos, Vector3.new(headPos.X, camPos.Y, headPos.Z)):VectorToObjectSpace(moveDir)
		hd.CFrame = CFrame.new(headPos) * (camCF - camPos) * CFrame.new(objVel)
	end)
end

-- IY Float / Platform underneath feet (Q = down, E = up)
local FloatPart = nil
local FloatPoint = -3.1
local FloatConn = nil
local FloatKeyBegan = nil
local FloatKeyEnded = nil

function PlayerCommands.SetFloat(enabled)
	State.Float = enabled
	if FloatConn then FloatConn:Disconnect(); FloatConn = nil end
	if FloatKeyBegan then FloatKeyBegan:Disconnect(); FloatKeyBegan = nil end
	if FloatKeyEnded then FloatKeyEnded:Disconnect(); FloatKeyEnded = nil end
	if FloatPart then FloatPart:Destroy(); FloatPart = nil end

	if not enabled then return end

	FloatPoint = -3.1
	FloatPart = Instance.new("Part")
	FloatPart.Name = "SurfaceFloatPlatform"
	FloatPart.Transparency = 1
	FloatPart.Size = Vector3.new(3, 0.2, 3)
	FloatPart.Anchored = true
	FloatPart.CanCollide = true
	FloatPart.Parent = workspace

	FloatKeyBegan = UserInputService.InputBegan:Connect(function(key, gp)
		if gp then return end
		if key.KeyCode == Enum.KeyCode.Q then
			FloatPoint = FloatPoint - 0.5
		elseif key.KeyCode == Enum.KeyCode.E then
			FloatPoint = FloatPoint + 1.5
		end
	end)

	FloatKeyEnded = UserInputService.InputEnded:Connect(function(key, gp)
		if gp then return end
		if key.KeyCode == Enum.KeyCode.Q then
			FloatPoint = FloatPoint + 0.5
		elseif key.KeyCode == Enum.KeyCode.E then
			FloatPoint = FloatPoint - 1.5
		end
	end)

	FloatConn = RunService.Heartbeat:Connect(function()
		local char = LocalPlayer and LocalPlayer.Character
		local root = getRoot(char)
		if root and FloatPart and FloatPart.Parent then
			FloatPart.CFrame = root.CFrame * CFrame.new(0, FloatPoint, 0)
		end
	end)
end

-- IY Swim in Air
local SwimConn = nil
local SavedGravityBeforeSwim = nil

function PlayerCommands.SetSwim(enabled)
	State.Swim = enabled
	if SwimConn then SwimConn:Disconnect(); SwimConn = nil end

	local char = LocalPlayer and LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")

	if not enabled then
		if SavedGravityBeforeSwim then
			workspace.Gravity = SavedGravityBeforeSwim
			SavedGravityBeforeSwim = nil
		end
		if hum then
			for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
				if st ~= Enum.HumanoidStateType.None then
					pcall(function() hum:SetStateEnabled(st, true) end)
				end
			end
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		return
	end

	SavedGravityBeforeSwim = workspace.Gravity
	workspace.Gravity = 0

	if hum then
		for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
			if st ~= Enum.HumanoidStateType.None then
				pcall(function() hum:SetStateEnabled(st, false) end)
			end
		end
		hum:ChangeState(Enum.HumanoidStateType.Swimming)
	end

	SwimConn = RunService.Heartbeat:Connect(function()
		local c = LocalPlayer and LocalPlayer.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local r = getRoot(c)
		if h and r then
			if h:GetState() ~= Enum.HumanoidStateType.Swimming then
				h:ChangeState(Enum.HumanoidStateType.Swimming)
			end
			if h.MoveDirection == Vector3.zero and not UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				r.Velocity = Vector3.zero
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- 3. CHARACTER & PHYSICS: NOCLIP, SPIN, WALKFLING, ANTIFLING, ANTIVOID, SIT/LAY
--------------------------------------------------------------------------------
local NoclipParts = {}

function PlayerCommands.SetNoclip(enabled)
	State.Noclip = enabled
	if not enabled then
		for part, _ in pairs(NoclipParts) do
			if part and part.Parent then
				pcall(function() part.CanCollide = true end)
			end
		end
		NoclipParts = {}
	end
end

function PlayerCommands.UpdateSpin()
	local char = LocalPlayer and LocalPlayer.Character
	local root = getRoot(char)
	if not root then return end

	for _, child in ipairs(root:GetChildren()) do
		if child.Name == "IYSpinning" then
			child:Destroy()
		end
	end

	if State.Spin then
		local bav = Instance.new("BodyAngularVelocity")
		bav.Name = "IYSpinning"
		bav.MaxTorque = Vector3.new(0, math.huge, 0)
		bav.AngularVelocity = Vector3.new(0, State.SpinSpeed, 0)
		bav.Parent = root
	end
end

-- IY WalkFling
function PlayerCommands.SetWalkFling(enabled)
	State.WalkFling = enabled
	if enabled then
		PlayerCommands.SetNoclip(true)
		task.spawn(function()
			local movel = 0.1
			while State.WalkFling do
				RunService.Heartbeat:Wait()
				local char = LocalPlayer and LocalPlayer.Character
				local root = getRoot(char)
				if char and root then
					local vel = root.Velocity
					root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
					RunService.RenderStepped:Wait()
					if root and root.Parent then
						root.Velocity = vel
					end
					RunService.Stepped:Wait()
					if root and root.Parent then
						root.Velocity = vel + Vector3.new(0, movel, 0)
						movel = movel * -1
					end
				end
			end
		end)
	end
end

function PlayerCommands.SetFreezeSelf(enabled)
	State.FreezeSelf = enabled
	local char = LocalPlayer and LocalPlayer.Character
	local root = getRoot(char)
	if root then
		root.Anchored = enabled
	end
end

function PlayerCommands.Sit()
	local char = LocalPlayer and LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Sit = true
	end
end

function PlayerCommands.LayDown()
	local char = LocalPlayer and LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = getRoot(char)
	if hum and root then
		hum.Sit = true
		task.wait(0.08)
		root.CFrame = root.CFrame * CFrame.Angles(math.pi * 0.5, 0, 0)
		for _, v in ipairs(hum:GetPlayingAnimationTracks()) do
			v:Stop()
		end
	end
end

function PlayerCommands.ResetCharacter()
	local char = LocalPlayer and LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Health = 0
	end
end

--------------------------------------------------------------------------------
-- 4. WORLD, LIGHTING, X-RAY, ESP ALL PLAYERS & CAMERA (IY)
--------------------------------------------------------------------------------
local OrigLighting = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows,
	OutdoorAmbient = Lighting.OutdoorAmbient,
}

function PlayerCommands.SetFullbright(enabled)
	State.Fullbright = enabled
	if not enabled then
		pcall(function()
			Lighting.Brightness = OrigLighting.Brightness
			Lighting.ClockTime = OrigLighting.ClockTime
			Lighting.FogEnd = OrigLighting.FogEnd
			Lighting.GlobalShadows = OrigLighting.GlobalShadows
			Lighting.OutdoorAmbient = OrigLighting.OutdoorAmbient
		end)
	end
end

function PlayerCommands.SetNoFog(enabled)
	State.NoFog = enabled
	if enabled then
		Lighting.FogEnd = 100000
		for _, v in ipairs(Lighting:GetDescendants()) do
			if v:IsA("Atmosphere") then
				v.Density = 0
			end
		end
	else
		Lighting.FogEnd = OrigLighting.FogEnd
	end
end

function PlayerCommands.SetXRay(enabled)
	State.XRay = enabled
	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and not v.Parent:FindFirstChildOfClass("Humanoid") and not (v.Parent.Parent and v.Parent.Parent:FindFirstChildOfClass("Humanoid")) then
			v.LocalTransparencyModifier = enabled and 0.5 or 0
		end
	end
end

-- IY ESP All Players
local ESPHighlights = {}

local function clearAllESP()
	for _, hl in pairs(ESPHighlights) do
		if hl and hl.Parent then
			hl:Destroy()
		end
	end
	ESPHighlights = {}
end

local function refreshAllESP()
	clearAllESP()
	if not State.ESPAll then return end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hl = Instance.new("Highlight")
			hl.Name = "SurfaceIY_ESP"
			hl.FillColor = (plr.TeamColor and plr.TeamColor.Color) or Color3.fromRGB(56, 132, 255)
			hl.FillTransparency = 0.65
			hl.OutlineColor = Color3.fromRGB(255, 255, 255)
			hl.OutlineTransparency = 0.1
			hl.Adornee = plr.Character
			hl.Parent = plr.Character
			ESPHighlights[plr] = hl
		end
	end
end

function PlayerCommands.SetESPAll(enabled)
	State.ESPAll = enabled
	refreshAllESP()
end

function PlayerCommands.SetGravity(val)
	State.Gravity = val
	workspace.Gravity = val
end

function PlayerCommands.SetFOV(val)
	State.FOV = val
	if workspace.CurrentCamera then
		workspace.CurrentCamera.FieldOfView = val
	end
end

function PlayerCommands.SetMaxZoom(val)
	State.MaxZoom = val
	if LocalPlayer then
		LocalPlayer.CameraMaxZoomDistance = val
	end
end

function PlayerCommands.SetNoclipCamera(enabled)
	State.NoclipCamera = enabled
	if LocalPlayer then
		pcall(function()
			LocalPlayer.DevCameraOcclusionMode = enabled
				and Enum.DevCameraOcclusionMode.Invisicam
				or Enum.DevCameraOcclusionMode.Zoom
		end)
	end
end

--------------------------------------------------------------------------------
-- 5. UTILITY & SERVER (ClickTP, Anti-AFK, Instant Prompts, Rejoin, ServerHop)
--------------------------------------------------------------------------------
-- Click Teleport (Ctrl + LeftClick, from IY clickteleport)
trackConn(UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not State.ClickTP then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
			local mouse = LocalPlayer and LocalPlayer:GetMouse()
			local char = LocalPlayer and LocalPlayer.Character
			local root = getRoot(char)
			if mouse and mouse.Hit and root then
				root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
			end
		end
	end
end))

-- Anti-AFK (IY antiafk)
if LocalPlayer then
	trackConn(LocalPlayer.Idled:Connect(function()
		if State.AntiAFK then
			pcall(function()
				local vu = game:GetService("VirtualUser")
				vu:CaptureController()
				vu:ClickButton2(Vector2.zero)
			end)
		end
	end))
end

-- Instant ProximityPrompts (IY instantpp)
trackConn(ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	if State.InstantPrompts then
		pcall(function()
			if type(fireproximityprompt) == "function" then
				fireproximityprompt(prompt)
			else
				prompt.HoldDuration = 0
			end
		end)
	end
end))

function PlayerCommands.RejoinServer()
	notify("Rejoining", "Rejoining current server...")
	pcall(function()
		if #Players:GetPlayers() <= 1 then
			LocalPlayer:Kick("\nRejoining...")
			task.wait()
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		else
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		end
	end)
end

function PlayerCommands.ServerHop()
	notify("Server Hop", "Searching for another server...")
	task.spawn(function()
		local ok, res = pcall(function()
			local url = string.format(
				"https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true",
				game.PlaceId
			)
			return HttpService:JSONDecode(game:HttpGet(url))
		end)
		if ok and res and type(res.data) == "table" then
			local servers = {}
			for _, v in ipairs(res.data) do
				if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) then
					if v.playing < v.maxPlayers and v.id ~= game.JobId then
						table.insert(servers, v.id)
					end
				end
			end
			if #servers > 0 then
				TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
			else
				notify("Server Hop", "No other servers found")
			end
		else
			notify("Server Hop", "Unable to fetch server list in this environment")
		end
	end)
end

--------------------------------------------------------------------------------
-- MAIN STEPPED & RENDERSTEPPED LOOPS
--------------------------------------------------------------------------------
trackConn(RunService.Stepped:Connect(function()
	local char = LocalPlayer and LocalPlayer.Character
	if State.Noclip and char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				part.CanCollide = false
				NoclipParts[part] = true
			end
		end
	end

	if State.AntiFling then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				for _, part in ipairs(plr.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end
	end
end))

trackConn(RunService.RenderStepped:Connect(function(dt)
	local char = LocalPlayer and LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = getRoot(char)

	if hum then
		if State.SpeedBoost and hum.WalkSpeed ~= State.SpeedAmount then
			hum.WalkSpeed = State.SpeedAmount
		end
		if State.JumpBoost then
			pcall(function()
				if not hum.UseJumpPower then hum.UseJumpPower = true end
				if hum.JumpPower ~= State.JumpAmount then
					hum.JumpPower = State.JumpAmount
				end
			end)
		end
		if State.TPWalk and hum.MoveDirection.Magnitude > 0 and root then
			char:TranslateBy(hum.MoveDirection * State.TPWalkSpeed * dt * 10)
		end
	end

	if State.AntiVoid and root then
		local destroyHeight = workspace.FallenPartsDestroyHeight
		if root.Position.Y < (destroyHeight + 25) then
			root.Velocity = Vector3.new(root.Velocity.X, 120, root.Velocity.Z)
			root.CFrame = root.CFrame + Vector3.new(0, 60, 0)
		end
	end

	if State.Fullbright then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	end

	-- Velocity Fly Step
	if not State.Fly then
		if FlyBodyVelocity or FlyBodyGyro then
			PlayerCommands.StopVelocityFly()
		end
	elseif root and hum and workspace.CurrentCamera then
		local cam = workspace.CurrentCamera
		if not FlyBodyVelocity or FlyBodyVelocity.Parent ~= root then
			if FlyBodyVelocity then FlyBodyVelocity:Destroy() end
			FlyBodyVelocity = Instance.new("BodyVelocity")
			FlyBodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
			FlyBodyVelocity.Velocity = Vector3.zero
			FlyBodyVelocity.Parent = root
		end
		if not FlyBodyGyro or FlyBodyGyro.Parent ~= root then
			if FlyBodyGyro then FlyBodyGyro:Destroy() end
			FlyBodyGyro = Instance.new("BodyGyro")
			FlyBodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
			FlyBodyGyro.P = 9000
			FlyBodyGyro.CFrame = cam.CFrame
			FlyBodyGyro.Parent = root
		end

		hum.PlatformStand = true
		FlyBodyGyro.CFrame = cam.CFrame

		local moveVec = Vector3.zero
		if not UserInputService:GetFocusedTextBox() then
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec = moveVec + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				moveVec = moveVec - Vector3.new(0, 1, 0)
			end
		end

		if moveVec.Magnitude > 0 then
			FlyBodyVelocity.Velocity = moveVec.Unit * State.FlySpeed
		else
			FlyBodyVelocity.Velocity = Vector3.zero
		end
	end
end))

if LocalPlayer then
	trackConn(LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.25)
		PlayerCommands.ApplyMovement()
		if State.Spin then PlayerCommands.UpdateSpin() end
		if State.CFrameFly then PlayerCommands.SetCFrameFly(true) end
		if State.Swim then PlayerCommands.SetSwim(true) end
		if State.FreezeSelf then PlayerCommands.SetFreezeSelf(true) end
	end))
end

function PlayerCommands.ResetAllCommands()
	State.SpeedBoost = false
	State.TPWalk = false
	State.JumpBoost = false
	State.InfiniteJump = false
	State.FlyJump = false
	State.Fly = false
	PlayerCommands.StopVelocityFly()
	PlayerCommands.SetCFrameFly(false)
	PlayerCommands.SetFloat(false)
	PlayerCommands.SetSwim(false)
	PlayerCommands.SetNoclip(false)
	State.Spin = false
	PlayerCommands.UpdateSpin()
	State.WalkFling = false
	State.AntiFling = false
	State.AntiVoid = false
	PlayerCommands.SetFreezeSelf(false)
	PlayerCommands.SetFullbright(false)
	PlayerCommands.SetNoFog(false)
	if State.XRay then PlayerCommands.SetXRay(false) end
	PlayerCommands.SetESPAll(false)
	PlayerCommands.SetNoclipCamera(false)
	State.ClickTP = false
	State.AntiAFK = false
	State.InstantPrompts = false
	PlayerCommands.ApplyMovement()
end

function PlayerCommands.CleanupAll()
	PlayerCommands.ResetAllCommands()
	for _, conn in ipairs(ActiveConnections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	ActiveConnections = {}
end

return PlayerCommands
