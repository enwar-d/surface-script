--[[
	Commands/TargetCommands.lua
	Infinite Yield Target Player Commands (Goto, TweenGoto, WalkTo, Spectate, Follow/LoopGoto,
	Orbit, Headsit, Attach/Stand, LoopBring, FlingTarget, StareAt, Highlight/Locate, Copy/Info)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local TargetCommands = {}

TargetCommands.SelectedPlayer = nil
TargetCommands.State = {
	Spectate = false,
	Follow = false,
	Orbit = false,
	Headsit = false,
	AttachBack = false,
	LoopBring = false,
	FlingTarget = false,
	StareAt = false,
	Highlight = false,
	BangV2 = false,
	GetBanged = false,
	Suck = false,
	GetSuc = false,
}

local State = TargetCommands.State
local NotifyFunc = nil
local ActiveHighlight = nil
local ActiveBillboard = nil
local ActiveFunTrack = nil
local ActiveFunMode = nil
local OrbitAngle = 0
local SavedPreFlingCF = nil
local ActiveConnections = {}

function TargetCommands.SetNotifier(fn)
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
-- ONE-SHOT TARGET ACTIONS (Goto, TweenGoto, WalkTo, CopyUsername, AccountInfo)
--------------------------------------------------------------------------------
function TargetCommands.Goto()
	local target = TargetCommands.SelectedPlayer
	local targetRoot = target and target.Character and getRoot(target.Character)
	local myRoot = LocalPlayer and LocalPlayer.Character and getRoot(LocalPlayer.Character)
	if not targetRoot or not myRoot then
		notify("Players", "Select a valid spawned player first")
		return
	end
	myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
	notify("Teleported", "Teleported to " .. target.DisplayName)
end

function TargetCommands.TweenGoto()
	local target = TargetCommands.SelectedPlayer
	local targetRoot = target and target.Character and getRoot(target.Character)
	local myRoot = LocalPlayer and LocalPlayer.Character and getRoot(LocalPlayer.Character)
	if not targetRoot or not myRoot then
		notify("Players", "Select a valid spawned player first")
		return
	end
	local dist = (targetRoot.Position - myRoot.Position).Magnitude
	local duration = math.clamp(dist / 140, 0.25, 3.5)
	TweenService:Create(
		myRoot,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{ CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3) }
	):Play()
	notify("Tween Goto", "Tweening to " .. target.DisplayName)
end

function TargetCommands.WalkTo()
	local target = TargetCommands.SelectedPlayer
	local targetRoot = target and target.Character and getRoot(target.Character)
	local myHum = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not targetRoot or not myHum then
		notify("Players", "Select a valid spawned player first")
		return
	end
	myHum:MoveTo(targetRoot.Position)
	notify("WalkTo", "Walking toward " .. target.DisplayName)
end

function TargetCommands.CopyUsername()
	local target = TargetCommands.SelectedPlayer
	if not target then
		notify("Players", "No player selected")
		return
	end
	pcall(function()
		if type(setclipboard) == "function" then
			setclipboard(target.Name)
		end
	end)
	notify("Username Copied", "@" .. target.Name .. " (ID: " .. tostring(target.UserId) .. ")")
end

function TargetCommands.InspectAccountInfo()
	local target = TargetCommands.SelectedPlayer
	if not target then
		notify("Players", "No player selected")
		return
	end
	notify(
		target.DisplayName,
		string.format("Age: %d days | UserId: %d", target.AccountAge, target.UserId)
	)
end

--------------------------------------------------------------------------------
-- TOGGLE TARGET ACTIONS (Spectate, Highlight/Locate, Fling, Orbit, Headsit, etc.)
--------------------------------------------------------------------------------
function TargetCommands.SetSpectate(enabled)
	State.Spectate = enabled
	local cam = workspace.CurrentCamera
	if not cam then return end
	local target = TargetCommands.SelectedPlayer
	if enabled and target and target.Character then
		local hum = target.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			cam.CameraSubject = hum
			return
		end
	end
	local myHum = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if myHum then
		cam.CameraSubject = myHum
	end
end

function TargetCommands.CleanupLocate()
	if ActiveHighlight then
		ActiveHighlight:Destroy()
		ActiveHighlight = nil
	end
	if ActiveBillboard then
		ActiveBillboard:Destroy()
		ActiveBillboard = nil
	end
end

function TargetCommands.RefreshLocate()
	TargetCommands.CleanupLocate()
	local target = TargetCommands.SelectedPlayer
	if not State.Highlight or not target or not target.Character then
		return
	end

	local hl = Instance.new("Highlight")
	hl.Name = "SurfaceTargetHighlight"
	hl.FillColor = Color3.fromRGB(56, 132, 255)
	hl.FillTransparency = 0.62
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.OutlineTransparency = 0.1
	hl.Adornee = target.Character
	hl.Parent = target.Character
	ActiveHighlight = hl

	local head = target.Character:FindFirstChild("Head")
	if head then
		local bg = Instance.new("BillboardGui")
		bg.Name = "SurfaceLocateBillboard"
		bg.AlwaysOnTop = true
		bg.Size = UDim2.fromOffset(140, 36)
		bg.StudsOffset = Vector3.new(0, 3, 0)
		bg.Adornee = head
		bg.Parent = head

		local lbl = Instance.new("TextLabel", bg)
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		lbl.TextStrokeTransparency = 0.3
		lbl.TextSize = 12
		lbl.Text = target.DisplayName .. "\n@" .. target.Name
		ActiveBillboard = bg
	end
end

function TargetCommands.SetHighlight(enabled)
	State.Highlight = enabled
	TargetCommands.RefreshLocate()
end

function TargetCommands.SetFlingTarget(enabled)
	State.FlingTarget = enabled
	local myChar = LocalPlayer and LocalPlayer.Character
	local myRoot = getRoot(myChar)
	if enabled then
		if myRoot then
			SavedPreFlingCF = myRoot.CFrame
		end
	else
		if myRoot then
			myRoot.Velocity = Vector3.zero
			myRoot.RotVelocity = Vector3.zero
			if SavedPreFlingCF then
				myRoot.CFrame = SavedPreFlingCF
				SavedPreFlingCF = nil
			end
		end
	end
end

local FUN_MODES = {
	BangV2 = {
		R6 = { Id = "189854234", Speed = 1.8 },
		R15 = { Id = "10714068222", Speed = 2.0 },
		PlatformStand = false,
	},
	GetBanged = {
		R6 = { Id = "189854234", Speed = 1.8 },
		R15 = { Id = "10714360343", Speed = 1.5 },
		PlatformStand = false,
	},
	Suck = {
		R6 = { Id = "178130996", Speed = 1.0 },
		R15 = { Id = "5918726674", Speed = 1.0 },
		PlatformStand = true,
	},
	GetSuc = {
		R6 = { Id = "148840371", Speed = 3.0 },
		R15 = { Id = "5918726674", Speed = 1.0 },
		PlatformStand = true,
	},
}

local function stopFunTrack()
	if ActiveFunTrack then
		pcall(function()
			ActiveFunTrack:Stop()
			ActiveFunTrack:Destroy()
		end)
		ActiveFunTrack = nil
	end
end

local function startFunTrack(modeName)
	stopFunTrack()
	local spec = FUN_MODES[modeName]
	if not spec then return end
	local myChar = LocalPlayer and LocalPlayer.Character
	local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
	if not myHum then return end

	local animSpec = (myHum.RigType == Enum.HumanoidRigType.R6) and spec.R6 or spec.R15
	local animator = myHum:FindFirstChildOfClass("Animator") or Instance.new("Animator", myHum)
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. animSpec.Id
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	anim:Destroy()
	if ok and track then
		track.Looped = true
		track.Priority = Enum.AnimationPriority.Action
		track:Play()
		track:AdjustSpeed(animSpec.Speed)
		ActiveFunTrack = track
	end
	if spec.PlatformStand then
		myHum.PlatformStand = true
	end
end

function TargetCommands.SetFunMode(modeName, enabled)
	for k, _ in pairs(FUN_MODES) do
		State[k] = false
	end
	stopFunTrack()
	ActiveFunMode = nil

	local myChar = LocalPlayer and LocalPlayer.Character
	local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
	if not enabled then
		if myHum then
			myHum.PlatformStand = false
		end
		return
	end

	local target = TargetCommands.SelectedPlayer
	if not target or target == LocalPlayer or not target.Character then
		notify("Players", "Select another spawned player first")
		return
	end

	State[modeName] = true
	ActiveFunMode = modeName
	startFunTrack(modeName)
end

function TargetCommands.SetSelectedPlayer(plr)
	TargetCommands.SelectedPlayer = plr
	if State.Spectate then
		TargetCommands.SetSpectate(true)
	end
	TargetCommands.RefreshLocate()
end

--------------------------------------------------------------------------------
-- CONTINUOUS HEARTBEAT / STEPPED LOOPS FOR TARGET MODES
--------------------------------------------------------------------------------
local hbConn = RunService.Heartbeat:Connect(function()
	local target = TargetCommands.SelectedPlayer
	if not target or not target.Character or target == LocalPlayer then
		return
	end
	local targetRoot = getRoot(target.Character)
	local myChar = LocalPlayer and LocalPlayer.Character
	local myRoot = getRoot(myChar)
	local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")

	if not targetRoot or not myRoot then
		return
	end

	-- 1. LoopGoto / Follow
	if State.Follow then
		myRoot.Velocity = Vector3.zero
		myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3.8)
	end

	-- 2. Orbit Player (IY orbit)
	if State.Orbit then
		OrbitAngle = (OrbitAngle + 3.5) % 360
		myRoot.Velocity = Vector3.zero
		local orbitPos = (CFrame.new(targetRoot.Position) * CFrame.Angles(0, math.rad(OrbitAngle), 0) * CFrame.new(6.5, 0, 0)).Position
		myRoot.CFrame = CFrame.lookAt(orbitPos, Vector3.new(targetRoot.Position.X, orbitPos.Y, targetRoot.Position.Z))
	end

	-- 3. Headsit (IY headsit)
	if State.Headsit then
		if myHum then myHum.Sit = true end
		myRoot.Velocity = Vector3.zero
		myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 1.6, 0.4)
	end

	-- 4. Stand / Attach Back (IY stand / bang position)
	if State.AttachBack then
		myRoot.Velocity = Vector3.zero
		myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0.5, 1.6)
	end

	-- 5. Client LoopBring (IY loopbring)
	if State.LoopBring then
		targetRoot.Velocity = Vector3.zero
		targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -4.5)
	end

	-- 6. Fling Selected Player
	if State.FlingTarget then
		myRoot.CFrame = targetRoot.CFrame
		myRoot.Velocity = Vector3.new(9000, 9000, 9000)
		myRoot.RotVelocity = Vector3.new(9000, 9000, 9000)
	end

	-- 7. StareAt (IY stareat)
	if State.StareAt then
		myRoot.CFrame = CFrame.lookAt(
			myRoot.Position,
			Vector3.new(targetRoot.Position.X, myRoot.Position.Y, targetRoot.Position.Z)
		)
	end

	-- 8. Fun Time Friday modes (cleanly welded in Heartbeat without blocking tweens or gravity hacks)
	if ActiveFunMode then
		if not ActiveFunTrack or not ActiveFunTrack.IsPlaying then
			startFunTrack(ActiveFunMode)
		end
		myRoot.Velocity = Vector3.zero
		myRoot.RotVelocity = Vector3.zero

		local t = os.clock()
		if State.BangV2 then
			local z = 1.65 + math.sin(t * 11) * 0.55
			myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, z)
		elseif State.GetBanged then
			local z = -1.6 + math.sin(t * 11) * 0.45
			myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, z)
		elseif State.Suck then
			local targetTorso = target.Character:FindFirstChild("LowerTorso")
				or target.Character:FindFirstChild("Torso")
				or targetRoot
			myRoot.CFrame = targetTorso.CFrame * CFrame.new(0, -2.3, -1.0) * CFrame.Angles(0, math.pi, 0)
		elseif State.GetSuc then
			myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2.3, -1.1) * CFrame.Angles(0, math.pi, 0)
		end
	end
end)
table.insert(ActiveConnections, hbConn)

function TargetCommands.ResetAllCommands()
	TargetCommands.SetSpectate(false)
	TargetCommands.SetHighlight(false)
	TargetCommands.SetFlingTarget(false)
	TargetCommands.SetFunMode(nil, false)
	State.Follow = false
	State.Orbit = false
	State.Headsit = false
	State.AttachBack = false
	State.LoopBring = false
	State.StareAt = false
end

function TargetCommands.CleanupAll()
	TargetCommands.ResetAllCommands()
	for _, conn in ipairs(ActiveConnections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	ActiveConnections = {}
end

return TargetCommands
