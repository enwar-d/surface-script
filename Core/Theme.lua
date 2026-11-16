--[[
	Core/Theme.lua
	Liquid Glass UI vs Solid UI surfaces, world BlurEffect, and iOS spring press animations.

	Liquid Glass recipe (layered per surface):
	  1. Tinted translucent fill with a vertical "lens" gradient (light top, clear middle, deeper bottom)
	  2. Specular rim: UIStroke + gradient whose bright edge follows the mouse (light catching the glass)
	  3. Inner rim: a 1px inset hairline that gives the glass visible thickness
	  4. Top specular sheen: soft white highlight fading downward
	  5. Bottom caustic: faint cool refraction glow along the bottom edge
	  + World BlurEffect behind the window acts as the frosted backdrop
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(script.Parent:WaitForChild("Config"))
local COLORS = Config.COLORS
local IOS_TIMING = Config.IOS_TIMING
local UISettings = Config.UISettings

local Theme = {}

local RegisteredSurfaces = {}
local RegisteredControls = {}
local RimConnection = nil

local OVERLAY_Z = 0 -- below any content (content defaults to ZIndex 1+)

--------------------------------------------------------------------------------
-- PER-UI FROSTED GLASS BACKING (no whole-screen BlurEffect, no 3D part glitches)
--------------------------------------------------------------------------------
local function cleanupWorldBlurEffect()
	local blur = Lighting:FindFirstChild("SurfaceScriptWorldBlur")
	if blur then
		blur:Destroy()
	end
	local cam = workspace.CurrentCamera
	if cam then
		local oldParts = cam:FindFirstChild("SurfaceGlassBlurParts")
		if oldParts then
			oldParts:Destroy()
		end
	end
end

function Theme.UpdateWorldBlur(_windowActive)
	cleanupWorldBlurEffect()
	Theme.Refresh()
end

--------------------------------------------------------------------------------
-- GRADIENT PRESETS
--------------------------------------------------------------------------------
local function rimTransparency(brightness)
	-- brightness 0..1 scales how strong the specular edge is
	local function t(v)
		return 1 - (1 - v) * brightness
	end
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, t(0.00)),
		NumberSequenceKeypoint.new(0.22, t(0.55)),
		NumberSequenceKeypoint.new(0.50, t(0.88)),
		NumberSequenceKeypoint.new(0.78, t(0.60)),
		NumberSequenceKeypoint.new(1.00, t(0.25)),
	})
end

local RIM_COLOR = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(205, 220, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 225, 255)),
})

local FILL_TRANSPARENCY = NumberSequence.new({
	NumberSequenceKeypoint.new(0.00, 0.00),
	NumberSequenceKeypoint.new(0.45, 0.22),
	NumberSequenceKeypoint.new(1.00, 0.04),
})

local SHEEN_TRANSPARENCY = NumberSequence.new({
	NumberSequenceKeypoint.new(0.00, 0.80),
	NumberSequenceKeypoint.new(0.35, 0.91),
	NumberSequenceKeypoint.new(1.00, 1.00),
})

local CAUSTIC_TRANSPARENCY = NumberSequence.new({
	NumberSequenceKeypoint.new(0.00, 1.00),
	NumberSequenceKeypoint.new(0.70, 0.96),
	NumberSequenceKeypoint.new(1.00, 0.86),
})

local INNER_RIM_TRANSPARENCY = NumberSequence.new({
	NumberSequenceKeypoint.new(0.00, 0.55),
	NumberSequenceKeypoint.new(0.40, 0.92),
	NumberSequenceKeypoint.new(1.00, 0.80),
})

local function insetCorner(corner, inset)
	if corner.Scale > 0 then
		return corner
	end
	return UDim.new(0, math.max(corner.Offset - inset, 0))
end

--------------------------------------------------------------------------------
-- SURFACE APPLICATION
--------------------------------------------------------------------------------
function Theme.ApplyToEntry(entry)
	local frame = entry.Frame
	if not frame or not frame.Parent then
		return
	end
	local isWindow = (entry.Kind == "Window" or entry.Kind == "Notification")
	local darken = UISettings.BackgroundBlur == true

	if UISettings.GlassUI then
		frame.BackgroundColor3 = COLORS.White
		if isWindow then
			frame.BackgroundTransparency = darken and 0.24 or 0.54
		else
			frame.BackgroundTransparency = darken and 0.78 or 0.86
		end

		entry.Gradient.Enabled = true
		entry.Gradient.Rotation = 90
		entry.Gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, isWindow and COLORS.GlassWindowTop or COLORS.GlassCardTop),
			ColorSequenceKeypoint.new(1, isWindow and COLORS.GlassWindowBottom or COLORS.GlassCardBottom),
		})
		entry.Gradient.Transparency = FILL_TRANSPARENCY

		entry.Stroke.Color = COLORS.White
		entry.Stroke.Transparency = 0
		entry.Stroke.Thickness = isWindow and 1.6 or 1.2
		entry.RimGradient.Enabled = true
		entry.RimGradient.Transparency = rimTransparency(isWindow and 1 or 0.8)

		entry.InnerRim.Visible = true
		entry.Sheen.Visible = true
		entry.Caustic.Visible = true
		entry.Sheen.Size = UDim2.new(1, -2, isWindow and 0.38 or 0.5, 0)
		if entry.Frost then
			entry.Frost.Visible = isWindow and darken
		end
	else
		frame.BackgroundColor3 = isWindow and COLORS.SolidWindowBg or COLORS.SolidCardBg
		if darken then
			frame.BackgroundTransparency = 0.02
			entry.Stroke.Transparency = COLORS.SolidStrokeTrans
		else
			frame.BackgroundTransparency = isWindow and 0.58 or 0.68
			entry.Stroke.Transparency = 0.55
		end
		entry.Gradient.Enabled = false
		entry.Stroke.Color = COLORS.SolidStrokeColor
		entry.Stroke.Thickness = 1
		entry.RimGradient.Enabled = false
		entry.InnerRim.Visible = false
		entry.Sheen.Visible = false
		entry.Caustic.Visible = false
		if entry.Frost then
			entry.Frost.Visible = false
		end
	end
end

function Theme.ApplyToControl(ctrl)
	local obj = ctrl.Object
	if not obj or not obj.Parent then
		return
	end
	if UISettings.GlassUI then
		obj.BackgroundColor3 = ctrl.GlassColor or obj.BackgroundColor3
		obj.BackgroundTransparency = ctrl.GlassTrans
		ctrl.Gradient.Enabled = true
		if ctrl.Stroke then
			ctrl.Stroke.Color = COLORS.White
			ctrl.Stroke.Transparency = 0
			ctrl.Stroke.Thickness = 1.1
			ctrl.StrokeGradient.Enabled = true
		end
	else
		obj.BackgroundColor3 = ctrl.SolidColor or obj.BackgroundColor3
		obj.BackgroundTransparency = ctrl.SolidTrans
		ctrl.Gradient.Enabled = false
		if ctrl.Stroke then
			ctrl.Stroke.Color = COLORS.GlassStrokeColor
			ctrl.Stroke.Transparency = 0.55
			ctrl.Stroke.Thickness = 1
			ctrl.StrokeGradient.Enabled = false
		end
	end
end

function Theme.Refresh()
	for _, entry in ipairs(RegisteredSurfaces) do
		Theme.ApplyToEntry(entry)
	end
	for _, ctrl in ipairs(RegisteredControls) do
		Theme.ApplyToControl(ctrl)
	end
end

--------------------------------------------------------------------------------
-- REFRACTION & SPECULAR RIM TRACKING
-- Default: refracts with background (camera orientation, sun/moon light, window position, world ambient tint).
-- Optional (UISettings.RefractionFollowsCursor): light follows the mouse cursor.
--------------------------------------------------------------------------------
local lastMouse = Vector2.new(-1, -1)
local lastMouseMoveTime = 0

local function lerpAngle(a, b, t)
	local diff = (b - a + 180) % 360 - 180
	return a + diff * t
end

local function computeBackgroundRefraction()
	local cam = workspace.CurrentCamera
	local sunDir = Lighting:GetSunDirection()
	if sunDir.Y < 0 then
		sunDir = Lighting:GetMoonDirection()
	end

	local camX, camY = 0.4, -0.4
	local viewport = Vector2.new(1920, 1080)
	if cam then
		viewport = cam.ViewportSize
		local camLight = cam.CFrame:VectorToObjectSpace(sunDir)
		-- Horizontal & vertical components in camera screen plane
		camX = camLight.X
		camY = -camLight.Y
	end

	-- Blend world ambient/fog color gently into glass caustic
	local worldColor = Lighting.OutdoorAmbient:Lerp(Lighting.FogColor, 0.35)
	local causticTint = COLORS.GlassCaustic:Lerp(worldColor, 0.32)

	return camX, camY, viewport, causticTint
end

local function ensureRimLoop()
	if RimConnection then
		return
	end
	RimConnection = RunService.RenderStepped:Connect(function(dt)
		if not UISettings.GlassUI then
			return
		end
		local now = os.clock()
		local followCursor = UISettings.RefractionFollowsCursor == true
		local useMouse = false
		local mouse = Vector2.zero

		if followCursor then
			mouse = UserInputService:GetMouseLocation()
			if (mouse - lastMouse).Magnitude > 0.5 then
				lastMouse = mouse
				lastMouseMoveTime = now
			end
			useMouse = UserInputService.MouseEnabled and (now - lastMouseMoveTime) < 6
		end

		local camX, camY, viewport, causticTint = computeBackgroundRefraction()
		local alpha = math.clamp(dt * 8, 0, 1)

		local i = 1
		while i <= #RegisteredSurfaces do
			local entry = RegisteredSurfaces[i]
			local frame = entry.Frame
			if not frame or not frame.Parent then
				table.remove(RegisteredSurfaces, i)
			else
				if frame.Visible then
					local target
					if followCursor then
						if useMouse then
							local center = frame.AbsolutePosition + frame.AbsoluteSize * 0.5
							local d = center - mouse
							target = math.deg(math.atan2(d.Y, d.X))
						else
							target = 45 + math.sin(now * 0.6 + entry.Phase) * 25
						end
						entry.Gradient.Offset = Vector2.zero
					else
						-- Background refraction: camera light direction + screen-space lens parallax
						local center = frame.AbsolutePosition + frame.AbsoluteSize * 0.5
						local nx = (center.X / math.max(viewport.X, 1)) - 0.5
						local ny = (center.Y / math.max(viewport.Y, 1)) - 0.5
						local rx = camX + nx * 1.15
						local ry = camY + ny * 1.15
						target = math.deg(math.atan2(ry, rx))

						-- Subtle vertical lens refraction shift & ambient caustic tint
						local yShift = math.clamp(camY * 0.14 + ny * 0.12, -0.14, 0.14)
						entry.Gradient.Offset = Vector2.new(0, yShift)
						entry.Caustic.BackgroundColor3 = causticTint
					end
					entry.RimAngle = lerpAngle(entry.RimAngle, target, alpha)
					entry.RimGradient.Rotation = entry.RimAngle
				end
				i += 1
			end
		end

		local c = 1
		while c <= #RegisteredControls do
			local ctrl = RegisteredControls[c]
			if not ctrl.Object or not ctrl.Object.Parent then
				table.remove(RegisteredControls, c)
			else
				c += 1
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- REGISTRATION
--------------------------------------------------------------------------------
local function makeOverlay(frame, name, corner)
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = COLORS.White
	f.BackgroundTransparency = 0
	f.BorderSizePixel = 0
	f.Active = false
	f.ZIndex = OVERLAY_Z
	Instance.new("UICorner", f).CornerRadius = corner
	f.Parent = frame
	return f
end

function Theme.RegisterSurface(frame, cornerRadius, kind)
	frame.BorderSizePixel = 0
	local corner = cornerRadius or UDim.new(0, 16)

	local uiCorner = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", frame)
	uiCorner.CornerRadius = corner

	-- 1. Lens fill gradient
	local grad = Instance.new("UIGradient")
	grad.Name = "GlassFill"
	grad.Rotation = 90
	grad.Parent = frame

	-- 2. Specular rim
	local stroke = Instance.new("UIStroke")
	stroke.Name = "GlassRim"
	stroke.Thickness = 1.2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame

	local rimGrad = Instance.new("UIGradient")
	rimGrad.Name = "RimSpecular"
	rimGrad.Color = RIM_COLOR
	rimGrad.Rotation = 45
	rimGrad.Parent = stroke

	-- 3. Inner rim (glass thickness)
	local innerRim = Instance.new("Frame")
	innerRim.Name = "GlassInnerRim"
	innerRim.Size = UDim2.new(1, -4, 1, -4)
	innerRim.AnchorPoint = Vector2.new(0.5, 0.5)
	innerRim.Position = UDim2.fromScale(0.5, 0.5)
	innerRim.BackgroundTransparency = 1
	innerRim.BorderSizePixel = 0
	innerRim.Active = false
	innerRim.ZIndex = OVERLAY_Z
	Instance.new("UICorner", innerRim).CornerRadius = insetCorner(corner, 2)
	local innerStroke = Instance.new("UIStroke", innerRim)
	innerStroke.Color = COLORS.White
	innerStroke.Thickness = 1
	innerStroke.Transparency = 0
	local innerGrad = Instance.new("UIGradient", innerStroke)
	innerGrad.Rotation = 90
	innerGrad.Transparency = INNER_RIM_TRANSPARENCY
	innerRim.Parent = frame

	-- 4. Top specular sheen
	local sheen = makeOverlay(frame, "GlassTopSheen", insetCorner(corner, 1))
	sheen.Size = UDim2.new(1, -2, 0.42, 0)
	sheen.AnchorPoint = Vector2.new(0.5, 0)
	sheen.Position = UDim2.new(0.5, 0, 0, 1)
	local sheenGrad = Instance.new("UIGradient", sheen)
	sheenGrad.Rotation = 90
	sheenGrad.Transparency = SHEEN_TRANSPARENCY

	-- 5. Bottom caustic / refraction glow
	local caustic = makeOverlay(frame, "GlassCaustic", insetCorner(corner, 1))
	caustic.BackgroundColor3 = COLORS.GlassCaustic
	caustic.Size = UDim2.new(1, -2, 0.35, 0)
	caustic.AnchorPoint = Vector2.new(0.5, 1)
	caustic.Position = UDim2.new(0.5, 0, 1, -1)
	local causticGrad = Instance.new("UIGradient", caustic)
	causticGrad.Rotation = 90
	causticGrad.Transparency = CAUSTIC_TRANSPARENCY

	-- 6. Per-UI frosted diffusion layer (active on windows/notifications when BackgroundBlur is on)
	local frost = makeOverlay(frame, "GlassFrost", corner)
	frost.BackgroundColor3 = Color3.fromRGB(210, 224, 248)
	frost.BackgroundTransparency = 0.90
	frost.Size = UDim2.fromScale(1, 1)
	local frostGrad = Instance.new("UIGradient", frost)
	frostGrad.Rotation = 115
	frostGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.0),
		NumberSequenceKeypoint.new(0.5, 0.45),
		NumberSequenceKeypoint.new(1.0, 0.15),
	})

	local entry = {
		Frame = frame,
		Gradient = grad,
		Stroke = stroke,
		RimGradient = rimGrad,
		InnerRim = innerRim,
		Sheen = sheen,
		Caustic = caustic,
		Frost = frost,
		Kind = kind or "Card",
		RimAngle = 45,
		Phase = math.random() * math.pi * 2,
	}
	table.insert(RegisteredSurfaces, entry)
	Theme.ApplyToEntry(entry)
	ensureRimLoop()
	return entry
end

-- Glassify small controls (iOS pill buttons, input boxes). stroke is optional.
function Theme.RegisterControl(obj, stroke, glassTrans, glassColor)
	local grad = Instance.new("UIGradient")
	grad.Name = "GlassPillFill"
	grad.Rotation = 90
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(220, 232, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(165, 185, 220)),
	})
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.5, 0.25),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	grad.Parent = obj

	local strokeGrad = nil
	if stroke then
		strokeGrad = Instance.new("UIGradient")
		strokeGrad.Rotation = 90
		strokeGrad.Color = RIM_COLOR
		strokeGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.12),
			NumberSequenceKeypoint.new(0.5, 0.78),
			NumberSequenceKeypoint.new(1, 0.42),
		})
		strokeGrad.Parent = stroke
	end

	local ctrl = {
		Object = obj,
		Gradient = grad,
		Stroke = stroke,
		StrokeGradient = strokeGrad,
		GlassTrans = glassTrans or 0.68,
		GlassColor = glassColor,
		SolidTrans = obj.BackgroundTransparency,
		SolidColor = obj.BackgroundColor3,
	}
	table.insert(RegisteredControls, ctrl)
	Theme.ApplyToControl(ctrl)
	return ctrl
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
	if RimConnection then
		RimConnection:Disconnect()
		RimConnection = nil
	end
	RegisteredSurfaces = {}
	RegisteredControls = {}
	cleanupWorldBlurEffect()
end

return Theme
