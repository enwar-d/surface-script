--[[
	UI/PlayerPage.lua
	Player Tab: Basic Mode vs Advanced Mode (Infinite Yield LocalPlayer Commands)
]]

local Root = script.Parent.Parent
local CoreFolder = Root:WaitForChild("Core")
local CommandsFolder = Root:WaitForChild("Commands")

local Config = require(CoreFolder:WaitForChild("Config"))
local PlayerCommands = require(CommandsFolder:WaitForChild("PlayerCommands"))
local Components = require(script.Parent:WaitForChild("Components"))

local State = PlayerCommands.State
local UISettings = Config.UISettings

local PlayerPage = {}

local ScrollFrameRef = nil

function PlayerPage.Rebuild()
	if not ScrollFrameRef or not ScrollFrameRef.Parent then
		return
	end

	for _, child in ipairs(ScrollFrameRef:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local adv = UISettings.AdvancedMode

	-- 1. SPEED & MOVEMENT
	local speedRows = {
		{
			Title = "Speed Boost",
			Kind = "Toggle",
			Default = State.SpeedBoost,
			Callback = function(enabled)
				State.SpeedBoost = enabled
				PlayerCommands.ApplyMovement()
			end,
		},
		{
			Title = "Speed Amount",
			Kind = "Input",
			Default = State.SpeedAmount,
			Min = 1,
			Max = 500,
			Callback = function(val)
				State.SpeedAmount = val
				PlayerCommands.ApplyMovement()
			end,
		},
	}

	if adv then
		table.insert(speedRows, {
			Title = "Teleport Walk (TPWalk)",
			Kind = "Toggle",
			Default = State.TPWalk,
			Callback = function(enabled)
				State.TPWalk = enabled
			end,
		})
		table.insert(speedRows, {
			Title = "TPWalk Speed",
			Kind = "Input",
			Default = State.TPWalkSpeed,
			Min = 1,
			Max = 50,
			Callback = function(val)
				State.TPWalkSpeed = val
			end,
		})
	end
	Components.CreateIosGroup(ScrollFrameRef, 1, "Speed & Movement", speedRows)

	-- 2. JUMP
	Components.CreateIosGroup(ScrollFrameRef, 2, "Jump", {
		{
			Title = "Jump Boost",
			Kind = "Toggle",
			Default = State.JumpBoost,
			Callback = function(enabled)
				State.JumpBoost = enabled
				PlayerCommands.ApplyMovement()
			end,
		},
		{
			Title = "Jump Boost Amount",
			Kind = "Input",
			Default = State.JumpAmount,
			Min = 1,
			Max = 1000,
			Callback = function(val)
				State.JumpAmount = val
				PlayerCommands.ApplyMovement()
			end,
		},
		{
			Title = "Infinite Jump",
			Kind = "Toggle",
			Default = State.InfiniteJump,
			Callback = function(enabled)
				State.InfiniteJump = enabled
			end,
		},
	})

	-- 3. FLIGHT
	local flightRows = {
		{
			Title = "Fly",
			Kind = "Toggle",
			Default = State.Fly,
			Callback = function(enabled)
				State.Fly = enabled
				if not enabled then
					PlayerCommands.StopVelocityFly()
				end
			end,
		},
		{
			Title = "Fly Speed",
			Kind = "Input",
			Default = State.FlySpeed,
			Min = 1,
			Max = 500,
			Callback = function(val)
				State.FlySpeed = val
			end,
		},
		{
			Title = "CFrame Fly (CFly)",
			Kind = "Toggle",
			Default = State.CFrameFly,
			Callback = function(enabled)
				PlayerCommands.SetCFrameFly(enabled)
			end,
		},
	}

	if adv then
		table.insert(flightRows, {
			Title = "Float Platform (Q / E)",
			Kind = "Toggle",
			Default = State.Float,
			Callback = function(enabled)
				PlayerCommands.SetFloat(enabled)
			end,
		})
		table.insert(flightRows, {
			Title = "Air Swim",
			Kind = "Toggle",
			Default = State.Swim,
			Callback = function(enabled)
				PlayerCommands.SetSwim(enabled)
			end,
		})
	end
	Components.CreateIosGroup(ScrollFrameRef, 3, "Flight", flightRows)

	-- 4. CHARACTER & PHYSICS
	local charRows = {
		{
			Title = "Noclip",
			Kind = "Toggle",
			Default = State.Noclip,
			Callback = function(enabled)
				PlayerCommands.SetNoclip(enabled)
			end,
		},
	}

	if adv then
		table.insert(charRows, {
			Title = "Spin Character",
			Kind = "Toggle",
			Default = State.Spin,
			Callback = function(enabled)
				State.Spin = enabled
				PlayerCommands.UpdateSpin()
			end,
		})
		table.insert(charRows, {
			Title = "Spin Speed",
			Kind = "Input",
			Default = State.SpinSpeed,
			Min = 1,
			Max = 500,
			Callback = function(val)
				State.SpinSpeed = val
				if State.Spin then
					PlayerCommands.UpdateSpin()
				end
			end,
		})
		table.insert(charRows, {
			Title = "WalkFling",
			Kind = "Toggle",
			Default = State.WalkFling,
			Callback = function(enabled)
				PlayerCommands.SetWalkFling(enabled)
			end,
		})
		table.insert(charRows, {
			Title = "Anti-Fling",
			Kind = "Toggle",
			Default = State.AntiFling,
			Callback = function(enabled)
				State.AntiFling = enabled
			end,
		})
		table.insert(charRows, {
			Title = "Anti-Void",
			Kind = "Toggle",
			Default = State.AntiVoid,
			Callback = function(enabled)
				State.AntiVoid = enabled
			end,
		})
		table.insert(charRows, {
			Title = "Freeze / Anchor Self",
			Kind = "Toggle",
			Default = State.FreezeSelf,
			Callback = function(enabled)
				PlayerCommands.SetFreezeSelf(enabled)
			end,
		})
		table.insert(charRows, {
			Title = "Sit",
			Kind = "Button",
			ButtonText = "Sit",
			Callback = function()
				PlayerCommands.Sit()
			end,
		})
		table.insert(charRows, {
			Title = "Lay Down",
			Kind = "Button",
			ButtonText = "Lay",
			Callback = function()
				PlayerCommands.LayDown()
			end,
		})
	end

	table.insert(charRows, {
		Title = "Jerk Tool",
		Kind = "Button",
		ButtonText = "Give",
		Callback = function()
			PlayerCommands.GiveJerkTool()
		end,
	})
	table.insert(charRows, {
		Title = "Respawn / Reset",
		Kind = "Button",
		ButtonText = "Reset",
		Callback = function()
			PlayerCommands.ResetCharacter()
		end,
	})
	Components.CreateIosGroup(ScrollFrameRef, 4, adv and "Character & Physics" or "Character", charRows)

	-- 5 & 6. ADVANCED GROUPS (World & Visuals, Utility & Server)
	if adv then
		Components.CreateIosGroup(ScrollFrameRef, 5, "World & Visuals", {
			{
				Title = "Fullbright",
				Kind = "Toggle",
				Default = State.Fullbright,
				Callback = function(enabled)
					PlayerCommands.SetFullbright(enabled)
				end,
			},
			{
				Title = "No Fog",
				Kind = "Toggle",
				Default = State.NoFog,
				Callback = function(enabled)
					PlayerCommands.SetNoFog(enabled)
				end,
			},
			{
				Title = "X-Ray Map",
				Kind = "Toggle",
				Default = State.XRay,
				Callback = function(enabled)
					PlayerCommands.SetXRay(enabled)
				end,
			},
			{
				Title = "ESP All Players",
				Kind = "Toggle",
				Default = State.ESPAll,
				Callback = function(enabled)
					PlayerCommands.SetESPAll(enabled)
				end,
			},
			{
				Title = "Noclip Camera",
				Kind = "Toggle",
				Default = State.NoclipCamera,
				Callback = function(enabled)
					PlayerCommands.SetNoclipCamera(enabled)
				end,
			},
			{
				Title = "Gravity",
				Kind = "Input",
				Default = math.floor(State.Gravity),
				Min = 0,
				Max = 1000,
				Callback = function(val)
					PlayerCommands.SetGravity(val)
				end,
			},
			{
				Title = "Field of View (FOV)",
				Kind = "Input",
				Default = State.FOV,
				Min = 30,
				Max = 120,
				Callback = function(val)
					PlayerCommands.SetFOV(val)
				end,
			},
			{
				Title = "Max Camera Zoom",
				Kind = "Input",
				Default = State.MaxZoom,
				Min = 10,
				Max = 2000,
				Callback = function(val)
					PlayerCommands.SetMaxZoom(val)
				end,
			},
		})

		Components.CreateIosGroup(ScrollFrameRef, 6, "Utility & Server", {
			{
				Title = "Ctrl + Click Teleport",
				Kind = "Toggle",
				Default = State.ClickTP,
				Callback = function(enabled)
					State.ClickTP = enabled
				end,
			},
			{
				Title = "Anti-AFK",
				Kind = "Toggle",
				Default = State.AntiAFK,
				Callback = function(enabled)
					State.AntiAFK = enabled
				end,
			},
			{
				Title = "Instant ProximityPrompts",
				Kind = "Toggle",
				Default = State.InstantPrompts,
				Callback = function(enabled)
					State.InstantPrompts = enabled
				end,
			},
			{
				Title = "Rejoin Server",
				Kind = "Button",
				ButtonText = "Rejoin",
				Callback = function()
					PlayerCommands.RejoinServer()
				end,
			},
			{
				Title = "Server Hop",
				Kind = "Button",
				ButtonText = "Hop",
				Callback = function()
					PlayerCommands.ServerHop()
				end,
			},
		})
	end
end

function PlayerPage.Build(pagesHolder)
	local pageWrap = Instance.new("CanvasGroup")
	pageWrap.Name = "Page_Player"
	pageWrap.Size = UDim2.fromScale(1, 1)
	pageWrap.BackgroundTransparency = 1
	pageWrap.BorderSizePixel = 0
	pageWrap.Visible = false
	pageWrap.Parent = pagesHolder

	local pageScale = Instance.new("UIScale", pageWrap)
	pageScale.Scale = 1

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "PlayerScroll"
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 2
	scroll.ScrollBarImageColor3 = Color3.fromRGB(140, 150, 175)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = pageWrap

	local pad = Instance.new("UIPadding", scroll)
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 18)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingRight = UDim.new(0, 8)

	local listLayout = Instance.new("UIListLayout", scroll)
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 12)

	ScrollFrameRef = scroll
	PlayerPage.Rebuild()

	return pageWrap
end

return PlayerPage
