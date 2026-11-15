--[[
	Core/Theme.lua
	Manages Glass UI vs Solid UI surfaces, world BlurEffect, and iOS spring press animations.
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Config = require(script.Parent:WaitForChild("Config"))
local COLORS = Config.COLORS
local IOS_TIMING = Config.IOS_TIMING
local UISettings = Config.UISettings

local Theme = {}

local RegisteredSurfaces = {}

local function getOrCreateWorldBlur()
	local blur = Lighting:FindFirstChild("SurfaceScriptWorldBlur")
	if not blur then
		blur = Instance.new("BlurEffect")
		blur.Name = "SurfaceScriptWorldBlur"
		blur.Size = 0
		blur.Enabled = false
		blur.Parent = Lighting
	end
	return blur
end

function Theme.UpdateWorldBlur(windowActive)
	local blur = getOrCreateWorldBlur()
	local shouldBlur = windowActive and UISettings.BackgroundBlur and UISettings.GlassUI
	if shouldBlur then
		blur.Enabled = true
		TweenService:Create(blur, IOS_TIMING.PageTransition, { Size = 14 }):Play()
	else
		local tw = TweenService:Create(blur, IOS_TIMING.PageTransition, { Size = 0 })
		tw:Play()
		task.delay(0.28, function()
			if blur and blur.Parent and blur.Size <= 0.5 then
				blur.Enabled = false
			end
		end)
	end
end

function Theme.ApplyToEntry(entry)
	local frame = entry.Frame
	if not frame or not frame.Parent then
		return
	end
	local isWindow = (entry.Kind == "Window")
	if UISettings.GlassUI then
		frame.BackgroundColor3 = COLORS.White
		frame.BackgroundTransparency = isWindow and COLORS.GlassWindowTrans or COLORS.GlassCardTrans
		entry.Gradient.Enabled = true
		entry.Gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, isWindow and COLORS.GlassWindowTop or COLORS.GlassCardTop),
			ColorSequenceKeypoint.new(1, isWindow and COLORS.GlassWindowBottom or COLORS.GlassCardBottom),
		})
		entry.Stroke.Color = COLORS.GlassStrokeColor
		entry.Stroke.Transparency = COLORS.GlassStrokeTrans
		entry.Sheen.Visible = isWindow
	else
		frame.BackgroundColor3 = isWindow and COLORS.SolidWindowBg or COLORS.SolidCardBg
		frame.BackgroundTransparency = 0.02
		entry.Gradient.Enabled = false
		entry.Stroke.Color = COLORS.SolidStrokeColor
		entry.Stroke.Transparency = COLORS.SolidStrokeTrans
		entry.Sheen.Visible = false
	end
end

function Theme.Refresh()
	for _, entry in ipairs(RegisteredSurfaces) do
		Theme.ApplyToEntry(entry)
	end
end

function Theme.RegisterSurface(frame, cornerRadius, kind)
	frame.BorderSizePixel = 0

	local corner = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", frame)
	corner.CornerRadius = cornerRadius or UDim.new(0, 16)

	local grad = Instance.new("UIGradient")
	grad.Rotation = 135
	grad.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame

	local sheen = Instance.new("Frame")
	sheen.Name = "GlassTopSheen"
	sheen.Size = UDim2.new(1, -24, 0, 1)
	sheen.AnchorPoint = Vector2.new(0.5, 0)
	sheen.Position = UDim2.new(0.5, 0, 0, 1)
	sheen.BackgroundColor3 = COLORS.White
	sheen.BackgroundTransparency = 0.72
	sheen.BorderSizePixel = 0
	sheen.ZIndex = frame.ZIndex + 1
	sheen.Parent = frame

	local entry = {
		Frame = frame,
		Gradient = grad,
		Stroke = stroke,
		Sheen = sheen,
		Kind = kind or "Card",
	}
	table.insert(RegisteredSurfaces, entry)
	Theme.ApplyToEntry(entry)
	return entry
end

function Theme.AttachSpringPress(button, pressScale, hoverScale)
	local uiScale = button:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Scale = 1
		uiScale.Parent = button
	end
	local downS = pressScale or 0.88
	local upS = hoverScale or 1.04

	button.MouseButton1Down:Connect(function()
		TweenService:Create(uiScale, IOS_TIMING.PressDown, { Scale = downS }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(uiScale, IOS_TIMING.PressBounce, { Scale = 1 }):Play()
	end)
	button.MouseEnter:Connect(function()
		TweenService:Create(uiScale, IOS_TIMING.PressDown, { Scale = upS }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(uiScale, IOS_TIMING.PressBounce, { Scale = 1 }):Play()
	end)
end

function Theme.Cleanup()
	RegisteredSurfaces = {}
	local blur = Lighting:FindFirstChild("SurfaceScriptWorldBlur")
	if blur then
		blur:Destroy()
	end
end

return Theme
