--[[
	SurfaceScript/loader.lua
	Universal Executor & GitHub Modular Loader
	- Checks your GitHub raw URL (if set) or local executor workspace files first
	- Automatically falls back to built-in module sources so it NEVER fails with HTTP 404!
]]

-- Optional: If you uploaded the folder to GitHub, set your raw repo URL here:
local GITHUB_RAW_BASE = _G.SURFACE_GITHUB_RAW or ""

local MODULE_TREE = {
	Core = {
		"Config",
		"Theme",
		"Icons",
		"Notifications",
	},
	Commands = {
		"PlayerCommands",
		"TargetCommands",
		"ScriptDatabase",
	},
	UI = {
		"Components",
		"ScriptsPage",
		"PlayerPage",
		"PlayersPage",
		"SettingsPage",
	},
}

local EMBEDDED_FILES = {}
EMBEDDED_FILES["Core/Config.lua"] = [====[
--[[
	Core/Config.lua
	Shared configuration, colors, iOS animation timings, SVG logo circles, and client settings persistence.
]]

local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Config = {}

Config.SETTINGS_FILE_NAME = "SurfaceScript_Settings.json"
Config.REGULAR_WINDOW_POS = UDim2.new(1, -84, 0.5, 0)

Config.DefaultSettings = {
	GlassUI = true,
	BackgroundBlur = true,
	SwipeToDismiss = true,
	CompactNotifications = true,
	AdvancedMode = false,
}

Config.UISettings = {
	GlassUI = Config.DefaultSettings.GlassUI,
	BackgroundBlur = Config.DefaultSettings.BackgroundBlur,
	SwipeToDismiss = Config.DefaultSettings.SwipeToDismiss,
	CompactNotifications = Config.DefaultSettings.CompactNotifications,
	AdvancedMode = Config.DefaultSettings.AdvancedMode,
}

Config.SVG_CIRCLES = {
	-- Row 1 (cy = 4)
	{ cx = 20, cy = 4,  r = 2.2, opacity = 0.50 },
	{ cx = 13, cy = 4,  r = 1.4, opacity = 0.32 },
	{ cx = 27, cy = 4,  r = 1.4, opacity = 0.32 },
	-- Row 2 (cy = 11)
	{ cx = 7,  cy = 11, r = 1.7, opacity = 0.38 },
	{ cx = 13, cy = 11, r = 3.0, opacity = 0.70 },
	{ cx = 20, cy = 11, r = 3.8, opacity = 0.86 },
	{ cx = 27, cy = 11, r = 3.0, opacity = 0.70 },
	{ cx = 33, cy = 11, r = 1.7, opacity = 0.38 },
	-- Row 3 (cy = 18 - center row)
	{ cx = 7,  cy = 18, r = 2.7, opacity = 0.56 },
	{ cx = 13, cy = 18, r = 4.2, opacity = 1.00 },
	{ cx = 20, cy = 18, r = 5.0, opacity = 1.00 },
	{ cx = 27, cy = 18, r = 4.2, opacity = 1.00 },
	{ cx = 33, cy = 18, r = 2.7, opacity = 0.56 },
	-- Row 4 (cy = 25)
	{ cx = 7,  cy = 25, r = 2.1, opacity = 0.44 },
	{ cx = 13, cy = 25, r = 3.5, opacity = 0.80 },
	{ cx = 20, cy = 25, r = 4.2, opacity = 0.90 },
	{ cx = 27, cy = 25, r = 3.5, opacity = 0.80 },
	{ cx = 33, cy = 25, r = 2.1, opacity = 0.44 },
	-- Row 5 (cy = 32)
	{ cx = 13, cy = 32, r = 2.7, opacity = 0.56 },
	{ cx = 20, cy = 32, r = 3.2, opacity = 0.70 },
	{ cx = 27, cy = 32, r = 2.7, opacity = 0.56 },
}

Config.IOS_TIMING = {
	Present = TweenInfo.new(0.48, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Dismiss = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
	SwipeDismiss = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	SnapBack = TweenInfo.new(0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	ColorFill = TweenInfo.new(0.36, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
	ContentFade = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	BannerDrop = TweenInfo.new(0.48, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	BannerDismiss = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
	SwipeSnapBack = TweenInfo.new(0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	FillExpand = TweenInfo.new(0.36, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
	PressDown = TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	PressBounce = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	PanelOpen = TweenInfo.new(0.46, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	PanelClose = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
	TabSlide = TweenInfo.new(0.34, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
	PageTransition = TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	SwitchToggle = TweenInfo.new(0.24, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
}

Config.COLORS = {
	NotifTop = Color3.fromRGB(36, 38, 43),
	NotifBottom = Color3.fromRGB(10, 11, 14),
	NotifBody = Color3.fromRGB(14, 15, 19),
	NotifCapGrey = Color3.fromRGB(78, 79, 83),
	NotifCancelRed = Color3.fromRGB(224, 86, 84),
	NotifConfirmGreen = Color3.fromRGB(52, 199, 89),
	CheckGray = Color3.fromRGB(78, 79, 83),
	CheckGrayHover = Color3.fromRGB(96, 98, 103),
	CancelRed = Color3.fromRGB(224, 86, 84),
	CancelRedHover = Color3.fromRGB(240, 104, 102),
	SubText = Color3.fromRGB(205, 210, 220),

	GlassWindowTop = Color3.fromRGB(28, 34, 48),
	GlassWindowBottom = Color3.fromRGB(14, 17, 26),
	GlassWindowTrans = 0.16,

	GlassCardTop = Color3.fromRGB(46, 54, 74),
	GlassCardBottom = Color3.fromRGB(26, 31, 44),
	GlassCardTrans = 0.24,

	GlassStrokeColor = Color3.fromRGB(165, 185, 220),
	GlassStrokeTrans = 0.62,

	SolidWindowBg = Color3.fromRGB(15, 18, 25),
	SolidCardBg = Color3.fromRGB(24, 28, 38),
	SolidStrokeColor = Color3.fromRGB(45, 52, 68),
	SolidStrokeTrans = 0.25,

	SwitchOn = Color3.fromRGB(48, 209, 88),
	SwitchOff = Color3.fromRGB(58, 62, 74),
	ButtonPill = Color3.fromRGB(48, 56, 74),
	ButtonPillHover = Color3.fromRGB(66, 76, 100),
	DangerRed = Color3.fromRGB(255, 69, 58),
	White = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(150, 158, 175),
	IconLight = Color3.fromRGB(230, 235, 245),
}

function Config.SaveSettings()
	local payload = {
		GlassUI = Config.UISettings.GlassUI,
		BackgroundBlur = Config.UISettings.BackgroundBlur,
		SwipeToDismiss = Config.UISettings.SwipeToDismiss,
		CompactNotifications = Config.UISettings.CompactNotifications,
		AdvancedMode = Config.UISettings.AdvancedMode,
	}
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(payload)
	end)
	if not ok or not encoded then
		return
	end

	pcall(function()
		if type(writefile) == "function" then
			writefile(Config.SETTINGS_FILE_NAME, encoded)
		end
	end)

	pcall(function()
		if LocalPlayer then
			LocalPlayer:SetAttribute("SurfaceScript_Settings", encoded)
		end
		Lighting:SetAttribute("SurfaceScript_Settings", encoded)
	end)
end

function Config.LoadSettings()
	local rawJson = nil

	pcall(function()
		if type(isfile) == "function" and type(readfile) == "function" then
			if isfile(Config.SETTINGS_FILE_NAME) then
				rawJson = readfile(Config.SETTINGS_FILE_NAME)
			end
		end
	end)

	if not rawJson or #rawJson == 0 then
		pcall(function()
			if LocalPlayer then
				rawJson = LocalPlayer:GetAttribute("SurfaceScript_Settings")
			end
			if not rawJson or #rawJson == 0 then
				rawJson = Lighting:GetAttribute("SurfaceScript_Settings")
			end
		end)
	end

	if type(rawJson) == "string" and #rawJson > 0 then
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(rawJson)
		end)
		if ok and type(decoded) == "table" then
			for k, _ in pairs(Config.DefaultSettings) do
				if type(decoded[k]) == "boolean" then
					Config.UISettings[k] = decoded[k]
				end
			end
		end
	end
end

function Config.ResetToDefaults()
	for k, v in pairs(Config.DefaultSettings) do
		Config.UISettings[k] = v
	end
	Config.SaveSettings()
end

return Config

]====]
EMBEDDED_FILES["Core/Theme.lua"] = [====[
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

]====]
EMBEDDED_FILES["Core/Icons.lua"] = [====[
--[[
	Core/Icons.lua
	4x Supersampled EditableImage Rasterizer for SVG_CIRCLES Logo and SDF Vector Icons
]]

local AssetService = game:GetService("AssetService")

local Config = require(script.Parent:WaitForChild("Config"))
local COLORS = Config.COLORS
local SVG_CIRCLES = Config.SVG_CIRCLES

local Icons = {}
local CachedLogoContent = nil
local CachedIconContents = {}

local function distToSegment(px, py, ax, ay, bx, by)
	local vx, vy = bx - ax, by - ay
	local wx, wy = px - ax, py - ay
	local c1 = wx * vx + wy * vy
	if c1 <= 0 then
		return math.sqrt(wx * wx + wy * wy)
	end
	local c2 = vx * vx + vy * vy
	if c2 <= c1 then
		local dx, dy = px - bx, py - by
		return math.sqrt(dx * dx + dy * dy)
	end
	local b = c1 / c2
	local pbx, pby = ax + b * vx, ay + b * vy
	local dx, dy = px - pbx, py - pby
	return math.sqrt(dx * dx + dy * dy)
end

local function distToCircleRing(px, py, cx, cy, r)
	local dx, dy = px - cx, py - cy
	return math.abs(math.sqrt(dx * dx + dy * dy) - r)
end

function Icons.GetLogoContent()
	if CachedLogoContent then
		return CachedLogoContent
	end
	local ok, content = pcall(function()
		local w, h = 160, 144
		local scale = 4.0
		local editable = AssetService:CreateEditableImage({ Size = Vector2.new(w, h) })
		local pixels = table.create(w * h * 4, 0)
		local radiusFactor = 0.64

		for py = 0, h - 1 do
			local svgY = (py + 0.5) / scale
			for px = 0, w - 1 do
				local svgX = (px + 0.5) / scale
				local maxAlpha = 0

				for _, c in ipairs(SVG_CIRCLES) do
					local dx = svgX - c.cx
					local dy = svgY - c.cy
					local dist = math.sqrt(dx * dx + dy * dy)
					local rSvg = c.r * radiusFactor
					local edgeDistPx = (rSvg - dist) * scale
					if edgeDistPx > -0.6 then
						local cov = math.clamp(edgeDistPx + 0.6, 0, 1)
						local a = cov * c.opacity
						if a > maxAlpha then
							maxAlpha = a
						end
					end
				end

				local idx = (py * w + px) * 4
				pixels[idx + 1] = 255
				pixels[idx + 2] = 255
				pixels[idx + 3] = 255
				pixels[idx + 4] = math.floor(math.clamp(maxAlpha, 0, 1) * 255 + 0.5)
			end
		end

		local b = buffer.create(w * h * 4)
		for i = 1, w * h * 4 do
			buffer.writeu8(b, i - 1, pixels[i])
		end
		editable:WritePixelsBuffer(Vector2.zero, Vector2.new(w, h), b)
		return Content.fromObject(editable)
	end)
	if ok and content then
		CachedLogoContent = content
	end
	return CachedLogoContent
end

function Icons.CreateSvgLogo(parent, pixelSize, position, anchorPoint, zIndex)
	local content = Icons.GetLogoContent()
	if content then
		local img = Instance.new("ImageLabel")
		img.Name = "SvgLogo"
		img.Size = UDim2.fromOffset(pixelSize, math.floor(pixelSize * (36 / 40) + 0.5))
		img.Position = position or UDim2.fromScale(0.5, 0.5)
		img.AnchorPoint = anchorPoint or Vector2.new(0.5, 0.5)
		img.BackgroundTransparency = 1
		img.ImageContent = content
		img.ImageColor3 = COLORS.White
		img.ScaleType = Enum.ScaleType.Fit
		img.ZIndex = zIndex or 5
		img.Parent = parent
		return img
	end

	local holder = Instance.new("Frame")
	holder.Name = "SvgLogo"
	holder.Size = UDim2.fromOffset(pixelSize, pixelSize)
	holder.Position = position or UDim2.fromScale(0.5, 0.5)
	holder.AnchorPoint = anchorPoint or Vector2.new(0.5, 0.5)
	holder.BackgroundTransparency = 1
	holder.ZIndex = zIndex or 5
	holder.Parent = parent

	for _, c in ipairs(SVG_CIRCLES) do
		local dot = Instance.new("Frame")
		local dScale = (c.r * 1.28) / 40
		dot.Size = UDim2.fromScale(dScale, dScale)
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(c.cx / 40, c.cy / 36)
		dot.BackgroundColor3 = COLORS.White
		dot.BackgroundTransparency = math.clamp(1 - c.opacity, 0, 1)
		dot.BorderSizePixel = 0
		dot.ZIndex = (zIndex or 5) + 1
		dot.Parent = holder
		Instance.new("UIAspectRatioConstraint", dot).AspectRatio = 1
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	end
	return holder
end

function Icons.GetVectorIconContent(iconName)
	if CachedIconContents[iconName] then
		return CachedIconContents[iconName]
	end

	local ok, content = pcall(function()
		local size = 64
		local editable = AssetService:CreateEditableImage({ Size = Vector2.new(size, size) })
		local buf = buffer.create(size * size * 4)
		local strokeHalf = 2.1

		for py = 0, size - 1 do
			local y = py + 0.5
			for px = 0, size - 1 do
				local x = px + 0.5
				local d = 999

				if iconName == "Settings" then
					local dx, dy = x - 32, y - 32
					local r = math.sqrt(dx * dx + dy * dy)
					local angle = math.atan2(dy, dx)
					local toothWave = math.clamp(math.cos(angle * 8) * 1.6, -1, 1)
					local outerR = 20.5 + toothWave * 3.2
					local innerR = 10.5
					if r >= innerR and r <= outerR then
						d = -math.min(r - innerR, outerR - r)
					elseif r < innerR then
						d = innerR - r
					else
						d = r - outerR
					end

				elseif iconName == "Player" then
					local dHead = distToCircleRing(x, y, 32, 19, 9.0) - strokeHalf
					local dArch = 999
					if y >= 33 and y <= 49 then
						dArch = distToCircleRing(x, y, 32, 50, 15.5) - strokeHalf
					elseif y > 49 then
						local dLeft = math.sqrt((x - 16.5)^2 + (y - 49)^2) - strokeHalf
						local dRight = math.sqrt((x - 47.5)^2 + (y - 49)^2) - strokeHalf
						dArch = math.min(dLeft, dRight)
					end
					d = math.min(dHead, dArch)

				elseif iconName == "Players" then
					local dHead1 = distToCircleRing(x, y, 25, 20, 8.2) - strokeHalf
					local dArch1 = 999
					if y >= 34 and y <= 49 then
						dArch1 = distToCircleRing(x, y, 25, 50, 14.0) - strokeHalf
					elseif y > 49 then
						local dL = math.sqrt((x - 11.0)^2 + (y - 49)^2) - strokeHalf
						local dR = math.sqrt((x - 39.0)^2 + (y - 49)^2) - strokeHalf
						dArch1 = math.min(dL, dR)
					end

					local dHead2 = 999
					if x >= 31 then
						dHead2 = distToCircleRing(x, y, 42, 21.5, 6.8) - (strokeHalf * 0.92)
					end
					local dArch2 = 999
					if x >= 39 and y >= 35 and y <= 49 then
						dArch2 = distToCircleRing(x, y, 42, 50, 11.5) - (strokeHalf * 0.92)
					end
					d = math.min(math.min(dHead1, dArch1), math.min(dHead2, dArch2))

				elseif iconName == "Scripts" then
					local bx = math.max(math.abs(x - 32) - 14, 0)
					local by = math.max(math.abs(y - 32) - 11, 0)
					local boxDist = math.sqrt(bx * bx + by * by) - 8
					local dBox = math.abs(boxDist) - strokeHalf

					local dChev1 = distToSegment(x, y, 20, 26, 27, 32) - strokeHalf
					local dChev2 = distToSegment(x, y, 27, 32, 20, 38) - strokeHalf
					local dUnder = distToSegment(x, y, 33, 38, 43, 38) - strokeHalf

					d = math.min(dBox, math.min(math.min(dChev1, dChev2), dUnder))

				elseif iconName == "ChevronRight" then
					local d1 = distToSegment(x, y, 26, 18, 39, 32) - (strokeHalf * 1.05)
					local d2 = distToSegment(x, y, 39, 32, 26, 46) - (strokeHalf * 1.05)
					d = math.min(d1, d2)

				elseif iconName == "Search" then
					local dCircle = distToCircleRing(x, y, 27, 27, 13) - strokeHalf
					local dHandle = distToSegment(x, y, 37, 37, 50, 50) - strokeHalf
					d = math.min(dCircle, dHandle)
				end

				local alpha = math.clamp(0.65 - d, 0, 1)
				local idx = (py * size + px) * 4
				buffer.writeu8(buf, idx, 255)
				buffer.writeu8(buf, idx + 1, 255)
				buffer.writeu8(buf, idx + 2, 255)
				buffer.writeu8(buf, idx + 3, math.floor(alpha * 255 + 0.5))
			end
		end

		editable:WritePixelsBuffer(Vector2.zero, Vector2.new(size, size), buf)
		return Content.fromObject(editable)
	end)

	if ok and content then
		CachedIconContents[iconName] = content
	end
	return CachedIconContents[iconName]
end

function Icons.CreateVectorIcon(parent, iconName, color, scaleSize)
	color = color or COLORS.IconLight
	scaleSize = scaleSize or 22
	local content = Icons.GetVectorIconContent(iconName)
	if content then
		local img = Instance.new("ImageLabel")
		img.Name = "Icon_" .. iconName
		img.Size = UDim2.fromOffset(scaleSize, scaleSize)
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.Position = UDim2.fromScale(0.5, 0.5)
		img.BackgroundTransparency = 1
		img.ImageContent = content
		img.ImageColor3 = color
		img.ZIndex = (parent.ZIndex or 20) + 1
		img.Parent = parent
		return img
	end

	local fallback = Instance.new("Frame")
	fallback.Size = UDim2.fromOffset(scaleSize, scaleSize)
	fallback.AnchorPoint = Vector2.new(0.5, 0.5)
	fallback.Position = UDim2.fromScale(0.5, 0.5)
	fallback.BackgroundTransparency = 1
	fallback.Parent = parent
	return fallback
end

function Icons.CreateCircleIcon(parent, iconType, zIndex, circleSize)
	circleSize = circleSize or 23
	local circle = Instance.new("Frame")
	circle.Name = "CircleIcon_" .. iconType
	circle.Size = UDim2.fromOffset(circleSize, circleSize)
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.fromScale(0.5, 0.5)
	circle.BackgroundTransparency = 1
	circle.ZIndex = zIndex or 10
	circle.Parent = parent

	Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

	local stroke = Instance.new("UIStroke", circle)
	stroke.Color = COLORS.White
	stroke.Thickness = 1.8
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	if iconType == "Check" then
		local leg1 = Instance.new("Frame", circle)
		leg1.Size = UDim2.fromOffset(5, 1.8)
		leg1.AnchorPoint = Vector2.new(0.5, 0.5)
		leg1.Position = UDim2.new(0.5, -2.6, 0.5, 1.5)
		leg1.Rotation = 45
		leg1.BackgroundColor3 = COLORS.White
		leg1.BorderSizePixel = 0
		leg1.ZIndex = (zIndex or 10) + 1
		Instance.new("UICorner", leg1).CornerRadius = UDim.new(1, 0)

		local leg2 = Instance.new("Frame", circle)
		leg2.Size = UDim2.fromOffset(9.5, 1.8)
		leg2.AnchorPoint = Vector2.new(0.5, 0.5)
		leg2.Position = UDim2.new(0.5, 1.8, 0.5, 0.2)
		leg2.Rotation = -45
		leg2.BackgroundColor3 = COLORS.White
		leg2.BorderSizePixel = 0
		leg2.ZIndex = (zIndex or 10) + 1
		Instance.new("UICorner", leg2).CornerRadius = UDim.new(1, 0)
	elseif iconType == "X" then
		for _, rot in ipairs({ 45, -45 }) do
			local bar = Instance.new("Frame", circle)
			bar.Size = UDim2.fromOffset(10.5, 1.8)
			bar.AnchorPoint = Vector2.new(0.5, 0.5)
			bar.Position = UDim2.fromScale(0.5, 0.5)
			bar.Rotation = rot
			bar.BackgroundColor3 = COLORS.White
			bar.BorderSizePixel = 0
			bar.ZIndex = (zIndex or 10) + 1
			Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
		end
	end

	return circle
end

return Icons

]====]
EMBEDDED_FILES["Core/Notifications.lua"] = [====[
--[[
	Core/Notifications.lua
	iOS Top Pill Notification System (Swipe-to-Dismiss, Full Pill Color Fill, No Outline)
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(script.Parent:WaitForChild("Config"))
local Icons = require(script.Parent:WaitForChild("Icons"))

local COLORS = Config.COLORS
local IOS_TIMING = Config.IOS_TIMING
local UISettings = Config.UISettings

local Notifications = {}
local ActiveNotifications = {}
local ScreenGuiRef = nil

local BASE_TOP_Y = 16
local NOTIF_WIDTH = 280
local NOTIF_HEIGHT = 44
local NOTIF_GAP = 8

function Notifications.Init(screenGui)
	ScreenGuiRef = screenGui
end

local function restackNotifications()
	for index, item in ipairs(ActiveNotifications) do
		if not item.Dismissing and not item.Dragging then
			local targetY = BASE_TOP_Y + (index - 1) * (NOTIF_HEIGHT + NOTIF_GAP)
			item.TargetY = targetY
			TweenService:Create(
				item.Wrapper,
				IOS_TIMING.Present,
				{ Position = UDim2.new(0.5, 0, 0, targetY) }
			):Play()
		end
	end
end

local function removeNotificationFromStack(notifObj)
	for i, item in ipairs(ActiveNotifications) do
		if item == notifObj then
			table.remove(ActiveNotifications, i)
			break
		end
	end
	restackNotifications()
end

function Notifications.Notify(options)
	if not ScreenGuiRef then
		return nil
	end
	options = options or {}
	local titleText = options.Title or "Surface Script"
	local subtitleText = options.Subtitle or "Want to load everything?"
	local notifType = options.Type or "Regular"
	local pillWidth = NOTIF_WIDTH
	local pillHeight = NOTIF_HEIGHT
	local checkBtnWidth = 46
	local cancelBtnWidth = 44

	local wrapper = Instance.new("Frame")
	wrapper.Name = "NotificationWrapper"
	wrapper.Size = UDim2.fromOffset(pillWidth, pillHeight)
	wrapper.AnchorPoint = Vector2.new(0.5, 0)
	wrapper.Position = UDim2.new(0.5, 0, 0, -pillHeight - 25)
	wrapper.BackgroundTransparency = 1
	wrapper.Parent = ScreenGuiRef

	local targetScale = UISettings.CompactNotifications and 0.90 or 1.0
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = targetScale * 0.92
	uiScale.Parent = wrapper

	local pillCanvas = Instance.new("CanvasGroup")
	pillCanvas.Name = "PillCanvas"
	pillCanvas.Size = UDim2.fromScale(1, 1)
	pillCanvas.BackgroundTransparency = 1
	pillCanvas.BorderSizePixel = 0
	pillCanvas.ClipsDescendants = true
	pillCanvas.Parent = wrapper

	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(1, 0)
	pillCorner.Parent = pillCanvas

	local bgFrame = Instance.new("Frame")
	bgFrame.Name = "PillBackground"
	bgFrame.Size = UDim2.fromScale(1, 1)
	bgFrame.BackgroundColor3 = COLORS.White
	bgFrame.BackgroundTransparency = UISettings.GlassUI and 0.12 or 0
	bgFrame.BorderSizePixel = 0
	bgFrame.ZIndex = 1
	bgFrame.Parent = pillCanvas

	local bgGradient = Instance.new("UIGradient")
	bgGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.NotifTop),
		ColorSequenceKeypoint.new(1, COLORS.NotifBottom),
	})
	bgGradient.Rotation = 90
	bgGradient.Parent = bgFrame

	local logoWidget = Icons.CreateSvgLogo(
		pillCanvas,
		26,
		UDim2.new(0, 25, 0.5, 0),
		Vector2.new(0.5, 0.5),
		4
	)

	local rightReserved = (notifType == "Confirm") and (checkBtnWidth + cancelBtnWidth) or checkBtnWidth
	local textContainer = Instance.new("Frame")
	textContainer.Name = "TextContainer"
	textContainer.Size = UDim2.new(1, -rightReserved - 50, 1, 0)
	textContainer.Position = UDim2.fromOffset(45, 0)
	textContainer.BackgroundTransparency = 1
	textContainer.ZIndex = 3
	textContainer.Parent = pillCanvas

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 16)
	titleLabel.Position = UDim2.fromOffset(0, 7)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = titleText
	titleLabel.TextColor3 = COLORS.White
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.ZIndex = 3
	titleLabel.Parent = textContainer

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.Size = UDim2.new(1, 0, 0, 15)
	subtitleLabel.Position = UDim2.fromOffset(0, 22)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Font = Enum.Font.Gotham
	subtitleLabel.Text = subtitleText
	subtitleLabel.TextColor3 = COLORS.SubText
	subtitleLabel.TextSize = 11
	subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	subtitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	subtitleLabel.ZIndex = 3
	subtitleLabel.Parent = textContainer

	local fillOverlay = Instance.new("Frame")
	fillOverlay.Name = "FillOverlay"
	fillOverlay.BackgroundTransparency = 1
	fillOverlay.BorderSizePixel = 0
	fillOverlay.ZIndex = 8
	fillOverlay.Parent = pillCanvas

	local checkBtn = Instance.new("TextButton")
	checkBtn.Name = "CheckButton"
	checkBtn.Size = UDim2.new(0, checkBtnWidth, 1, 0)
	checkBtn.Position = UDim2.new(1, -checkBtnWidth, 0, 0)
	checkBtn.BackgroundColor3 = COLORS.CheckGray
	checkBtn.BorderSizePixel = 0
	checkBtn.Text = ""
	checkBtn.AutoButtonColor = false
	checkBtn.ZIndex = 5
	checkBtn.Parent = pillCanvas

	local checkIconHolder = Instance.new("Frame")
	checkIconHolder.Name = "CheckIconHolder"
	checkIconHolder.Size = UDim2.new(0, checkBtnWidth, 1, 0)
	checkIconHolder.Position = UDim2.new(1, -checkBtnWidth, 0, 0)
	checkIconHolder.BackgroundTransparency = 1
	checkIconHolder.ZIndex = 12
	checkIconHolder.Parent = pillCanvas
	local checkIcon = Icons.CreateCircleIcon(checkIconHolder, "Check", 12, 23)

	local cancelBtn, cancelIconHolder, cancelIcon
	if notifType == "Confirm" then
		cancelBtn = Instance.new("TextButton")
		cancelBtn.Name = "CancelButton"
		cancelBtn.Size = UDim2.new(0, cancelBtnWidth, 1, 0)
		cancelBtn.Position = UDim2.new(1, -(checkBtnWidth + cancelBtnWidth), 0, 0)
		cancelBtn.BackgroundColor3 = COLORS.CancelRed
		cancelBtn.BorderSizePixel = 0
		cancelBtn.Text = ""
		cancelBtn.AutoButtonColor = false
		cancelBtn.ZIndex = 5
		cancelBtn.Parent = pillCanvas

		cancelIconHolder = Instance.new("Frame")
		cancelIconHolder.Name = "CancelIconHolder"
		cancelIconHolder.Size = UDim2.new(0, cancelBtnWidth, 1, 0)
		cancelIconHolder.Position = UDim2.new(1, -(checkBtnWidth + cancelBtnWidth), 0, 0)
		cancelIconHolder.BackgroundTransparency = 1
		cancelIconHolder.ZIndex = 12
		cancelIconHolder.Parent = pillCanvas
		cancelIcon = Icons.CreateCircleIcon(cancelIconHolder, "X", 12, 23)
	end

	local notifObj = {
		Wrapper = wrapper,
		TargetY = BASE_TOP_Y,
		Dismissing = false,
		Dragging = false,
	}
	table.insert(ActiveNotifications, notifObj)

	local myIndex = #ActiveNotifications
	local initialTargetY = BASE_TOP_Y + (myIndex - 1) * (NOTIF_HEIGHT + NOTIF_GAP)
	notifObj.TargetY = initialTargetY

	TweenService:Create(wrapper, IOS_TIMING.Present, {
		Position = UDim2.new(0.5, 0, 0, initialTargetY),
	}):Play()
	TweenService:Create(uiScale, IOS_TIMING.Present, {
		Scale = targetScale,
	}):Play()

	local function fadeElement(rootInst, duration)
		if not rootInst then return end
		local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if rootInst:IsA("ImageLabel") then
			TweenService:Create(rootInst, info, { ImageTransparency = 1 }):Play()
		end
		for _, desc in ipairs(rootInst:GetDescendants()) do
			if desc:IsA("UIStroke") then
				TweenService:Create(desc, info, { Transparency = 1 }):Play()
			elseif desc:IsA("Frame") then
				TweenService:Create(desc, info, { BackgroundTransparency = 1 }):Play()
			elseif desc:IsA("ImageLabel") then
				TweenService:Create(desc, info, { ImageTransparency = 1 }):Play()
			end
		end
	end

	local function dismissUpward(useFastSwipe)
		if notifObj.Dismissing then return end
		notifObj.Dismissing = true
		removeNotificationFromStack(notifObj)

		local tweenInfo = useFastSwipe and IOS_TIMING.SwipeDismiss or IOS_TIMING.Dismiss
		local t1 = TweenService:Create(wrapper, tweenInfo, {
			Position = UDim2.new(0.5, 0, 0, -pillHeight - 30),
		})
		TweenService:Create(uiScale, tweenInfo, {
			Scale = targetScale * 0.92,
		}):Play()
		TweenService:Create(pillCanvas, tweenInfo, {
			GroupTransparency = 0.15,
		}):Play()
		t1:Play()
		t1.Completed:Connect(function()
			wrapper:Destroy()
		end)
	end

	local function triggerButtonFillAndDismiss(buttonFrame, fillColor, otherIcon, callback)
		if notifObj.Dismissing then return end
		notifObj.Dismissing = true

		fillOverlay.BackgroundColor3 = fillColor
		fillOverlay.BackgroundTransparency = 0
		fillOverlay.Size = buttonFrame.Size
		fillOverlay.Position = buttonFrame.Position

		if otherIcon then
			fadeElement(otherIcon, 0.14)
		end
		fadeElement(logoWidget, 0.14)
		TweenService:Create(titleLabel, IOS_TIMING.ContentFade, { TextTransparency = 1 }):Play()
		TweenService:Create(subtitleLabel, IOS_TIMING.ContentFade, { TextTransparency = 1 }):Play()

		TweenService:Create(uiScale, IOS_TIMING.PressDown, { Scale = targetScale * 0.96 }):Play()
		task.delay(0.10, function()
			if uiScale.Parent then
				TweenService:Create(uiScale, IOS_TIMING.ColorFill, { Scale = targetScale }):Play()
			end
		end)

		local fillTween = TweenService:Create(fillOverlay, IOS_TIMING.ColorFill, {
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0, 0),
		})
		fillTween:Play()

		fillTween.Completed:Connect(function()
			if callback then
				task.spawn(callback)
			end
			task.wait(0.15)
			removeNotificationFromStack(notifObj)
			local exitTween = TweenService:Create(wrapper, IOS_TIMING.Dismiss, {
				Position = UDim2.new(0.5, 0, 0, -pillHeight - 30),
			})
			TweenService:Create(uiScale, IOS_TIMING.Dismiss, { Scale = targetScale * 0.92 }):Play()
			exitTween.Completed:Connect(function()
				wrapper:Destroy()
			end)
			exitTween:Play()
		end)
	end

	checkBtn.MouseEnter:Connect(function()
		if not notifObj.Dismissing then
			TweenService:Create(checkBtn, IOS_TIMING.PressDown, { BackgroundColor3 = COLORS.CheckGrayHover }):Play()
		end
	end)
	checkBtn.MouseLeave:Connect(function()
		if not notifObj.Dismissing then
			TweenService:Create(checkBtn, IOS_TIMING.PressDown, { BackgroundColor3 = COLORS.CheckGray }):Play()
		end
	end)
	checkBtn.Activated:Connect(function()
		if notifObj.Dragging then return end
		triggerButtonFillAndDismiss(checkBtn, COLORS.CheckGray, cancelIcon, options.OnConfirm)
	end)

	if cancelBtn then
		cancelBtn.MouseEnter:Connect(function()
			if not notifObj.Dismissing then
				TweenService:Create(cancelBtn, IOS_TIMING.PressDown, { BackgroundColor3 = COLORS.CancelRedHover }):Play()
			end
		end)
		cancelBtn.MouseLeave:Connect(function()
			if not notifObj.Dismissing then
				TweenService:Create(cancelBtn, IOS_TIMING.PressDown, { BackgroundColor3 = COLORS.CancelRed }):Play()
			end
		end)
		cancelBtn.Activated:Connect(function()
			if notifObj.Dragging then return end
			triggerButtonFillAndDismiss(cancelBtn, COLORS.CancelRed, checkIcon, options.OnCancel)
		end)
	end

	local dragStartPos = nil
	local startWrapperY = 0
	local lastDragY = 0
	local lastDragTime = 0
	local velocityY = 0

	pillCanvas.InputBegan:Connect(function(input)
		if notifObj.Dismissing or not UISettings.SwipeToDismiss then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragStartPos = input.Position
			startWrapperY = wrapper.Position.Y.Offset
			lastDragY = input.Position.Y
			lastDragTime = os.clock()
			velocityY = 0
		end
	end)

	local inputChangedConn
	local inputEndedConn

	inputChangedConn = UserInputService.InputChanged:Connect(function(input)
		if not dragStartPos or notifObj.Dismissing or not UISettings.SwipeToDismiss then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local deltaY = input.Position.Y - dragStartPos.Y
			if math.abs(deltaY) > 5 then
				notifObj.Dragging = true
			end
			if notifObj.Dragging then
				local now = os.clock()
				local dt = math.max(now - lastDragTime, 0.001)
				velocityY = (input.Position.Y - lastDragY) / dt
				lastDragY = input.Position.Y
				lastDragTime = now

				local newY
				if deltaY < 0 then
					newY = startWrapperY + deltaY
				else
					newY = startWrapperY + (deltaY * 0.28)
				end
				wrapper.Position = UDim2.new(0.5, 0, 0, newY)
			end
		end
	end)

	inputEndedConn = UserInputService.InputEnded:Connect(function(input)
		if not dragStartPos then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local wasDragging = notifObj.Dragging
			local deltaY = input.Position.Y - dragStartPos.Y
			dragStartPos = nil

			if wasDragging then
				task.delay(0.05, function()
					notifObj.Dragging = false
				end)
				if deltaY < -18 or velocityY < -320 then
					dismissUpward(true)
				else
					TweenService:Create(wrapper, IOS_TIMING.SnapBack, {
						Position = UDim2.new(0.5, 0, 0, notifObj.TargetY),
					}):Play()
				end
			end
		end
	end)

	wrapper.Destroying:Connect(function()
		if inputChangedConn then inputChangedConn:Disconnect() end
		if inputEndedConn then inputEndedConn:Disconnect() end
	end)

	if options.Duration and options.Duration > 0 then
		task.delay(options.Duration, function()
			if wrapper.Parent and not notifObj.Dismissing then
				dismissUpward(false)
			end
		end)
	end

	return notifObj
end

return Notifications

]====]
EMBEDDED_FILES["Commands/PlayerCommands.lua"] = [====[
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

]====]
EMBEDDED_FILES["Commands/TargetCommands.lua"] = [====[
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
}

local State = TargetCommands.State
local NotifyFunc = nil
local ActiveHighlight = nil
local ActiveBillboard = nil
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
end)
table.insert(ActiveConnections, hbConn)

function TargetCommands.ResetAllCommands()
	TargetCommands.SetSpectate(false)
	TargetCommands.SetHighlight(false)
	TargetCommands.SetFlingTarget(false)
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

]====]
EMBEDDED_FILES["Commands/ScriptDatabase.lua"] = [====[
--[[
	Commands/ScriptDatabase.lua
	Manages Universal Scripts & Place-Specific Scripts + Remote JSON Database Fetching
	Prompts an iOS Confirm (X / Checkmark) notification before executing a script.
]]

local HttpService = game:GetService("HttpService")

local ScriptDatabase = {}

ScriptDatabase.DATABASE_URL = ""

ScriptDatabase.Data = {
	Universal = {
		{
			Name = "Infinite Yield Admin",
			Url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
		},
		{
			Name = "Dex Explorer",
			Url = "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua",
		},
		{
			Name = "SimpleSpy V3",
			Url = "https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua",
		},
	},
	Places = {
		-- ["PLACE_ID"] = {
		--     { Name = "Script Name", Url = "https://..." }
		-- }
	},
}

local OnDatabaseChangedCallback = nil

function ScriptDatabase.SetOnChanged(fn)
	OnDatabaseChangedCallback = fn
end

function ScriptDatabase.TriggerRefresh()
	if OnDatabaseChangedCallback then
		OnDatabaseChangedCallback()
	end
end

local function runEntryNow(entry, notifyFn)
	if notifyFn then
		notifyFn({
			Title = entry.Name or "Script Executed",
			Subtitle = "Loading script...",
			Type = "Regular",
			Duration = 2.2,
		})
	end

	task.spawn(function()
		if type(entry.Callback) == "function" then
			pcall(entry.Callback)
		elseif type(entry.Source) == "string" and #entry.Source > 0 then
			pcall(function()
				local fn = loadstring(entry.Source)
				if fn then fn() end
			end)
		elseif type(entry.Url) == "string" and #entry.Url > 0 then
			pcall(function()
				local body = game:HttpGet(entry.Url)
				if type(body) == "string" and #body > 0 then
					local fn = loadstring(body)
					if fn then fn() end
				end
			end)
		end
	end)
end

function ScriptDatabase.ExecuteEntry(entry, notifyFn)
	if not entry then return end
	if notifyFn then
		notifyFn({
			Title = "Confirm action?",
			Subtitle = "Execute " .. (entry.Name or "game script"),
			Type = "Confirm",
			OnConfirm = function()
				runEntryNow(entry, notifyFn)
			end,
			OnCancel = function() end,
		})
	else
		runEntryNow(entry, nil)
	end
end

function ScriptDatabase.LoadFromUrl(url)
	if type(url) ~= "string" or #url == 0 then
		return false
	end
	local ok, decoded = pcall(function()
		local raw = game:HttpGet(url)
		return HttpService:JSONDecode(raw)
	end)
	if ok and type(decoded) == "table" then
		if type(decoded.Universal) == "table" then
			ScriptDatabase.Data.Universal = decoded.Universal
		end
		if type(decoded.Places) == "table" then
			ScriptDatabase.Data.Places = decoded.Places
		end
		ScriptDatabase.TriggerRefresh()
		return true
	end
	return false
end

function ScriptDatabase.AddUniversalScript(name, urlOrCallback)
	local entry = { Name = name }
	if type(urlOrCallback) == "function" then
		entry.Callback = urlOrCallback
	else
		entry.Url = tostring(urlOrCallback)
	end
	table.insert(ScriptDatabase.Data.Universal, entry)
	ScriptDatabase.TriggerRefresh()
end

function ScriptDatabase.AddGameScript(placeId, name, urlOrCallback)
	local key = tostring(placeId)
	ScriptDatabase.Data.Places[key] = ScriptDatabase.Data.Places[key] or {}
	local entry = { Name = name }
	if type(urlOrCallback) == "function" then
		entry.Callback = urlOrCallback
	else
		entry.Url = tostring(urlOrCallback)
	end
	table.insert(ScriptDatabase.Data.Places[key], entry)
	ScriptDatabase.TriggerRefresh()
end

return ScriptDatabase

]====]
EMBEDDED_FILES["UI/Components.lua"] = [====[
--[[
	UI/Components.lua
	Shared iOS Settings-Style Grouped Card Builder (Used by Player, Players, and Settings pages)
]]

local TweenService = game:GetService("TweenService")

local CoreFolder = script.Parent.Parent:WaitForChild("Core")
local Config = require(CoreFolder:WaitForChild("Config"))
local Theme = require(CoreFolder:WaitForChild("Theme"))
local Icons = require(CoreFolder:WaitForChild("Icons"))

local COLORS = Config.COLORS
local IOS_TIMING = Config.IOS_TIMING

local Components = {}

function Components.CreateIosGroup(parentScroll, order, groupTitle, rowsSpec)
	local wrap = Instance.new("Frame")
	wrap.Name = "GroupWrap_" .. tostring(order)
	wrap.LayoutOrder = order
	wrap.Size = UDim2.new(1, 0, 0, 26 + #rowsSpec * 46)
	wrap.BackgroundTransparency = 1
	wrap.Parent = parentScroll

	local headerLbl = Instance.new("TextLabel", wrap)
	headerLbl.Size = UDim2.new(1, -12, 0, 18)
	headerLbl.Position = UDim2.fromOffset(6, 0)
	headerLbl.BackgroundTransparency = 1
	headerLbl.Font = Enum.Font.GothamBold
	headerLbl.Text = string.upper(groupTitle)
	headerLbl.TextColor3 = COLORS.TextMuted
	headerLbl.TextSize = 11
	headerLbl.TextXAlignment = Enum.TextXAlignment.Left

	local groupCard = Instance.new("Frame")
	groupCard.Name = "IosGroupCard"
	groupCard.Size = UDim2.new(1, 0, 0, #rowsSpec * 46)
	groupCard.Position = UDim2.fromOffset(0, 22)
	groupCard.ClipsDescendants = false
	groupCard.Parent = wrap
	Theme.RegisterSurface(groupCard, UDim.new(0, 16), "Card")

	local rowControllers = {}

	for idx, spec in ipairs(rowsSpec) do
		local rowFrame = Instance.new("TextButton")
		rowFrame.Name = "Row_" .. spec.Title
		rowFrame.Size = UDim2.new(1, 0, 0, 46)
		rowFrame.Position = UDim2.fromOffset(0, (idx - 1) * 46)
		rowFrame.BackgroundColor3 = COLORS.White
		rowFrame.BackgroundTransparency = 1
		rowFrame.BorderSizePixel = 0
		rowFrame.Text = ""
		rowFrame.AutoButtonColor = false
		rowFrame.Parent = groupCard
		Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 16)

		local titleLbl = Instance.new("TextLabel", rowFrame)
		titleLbl.Size = UDim2.new(1, -110, 1, 0)
		titleLbl.Position = UDim2.fromOffset(16, 0)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = spec.Destructive and Enum.Font.GothamBold or Enum.Font.GothamMedium
		titleLbl.Text = spec.Title
		titleLbl.TextColor3 = spec.Destructive and COLORS.DangerRed or COLORS.White
		titleLbl.TextSize = 13
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left

		if idx < #rowsSpec then
			local div = Instance.new("Frame", rowFrame)
			div.Size = UDim2.new(1, -32, 0, 1)
			div.Position = UDim2.new(0, 16, 1, -1)
			div.BackgroundColor3 = COLORS.White
			div.BackgroundTransparency = 0.90
			div.BorderSizePixel = 0
		end

		if spec.Kind == "Toggle" then
			local switchTrack = Instance.new("Frame", rowFrame)
			switchTrack.Size = UDim2.fromOffset(44, 24)
			switchTrack.AnchorPoint = Vector2.new(1, 0.5)
			switchTrack.Position = UDim2.new(1, -14, 0.5, 0)
			switchTrack.BackgroundColor3 = spec.Default and COLORS.SwitchOn or COLORS.SwitchOff
			switchTrack.BorderSizePixel = 0
			Instance.new("UICorner", switchTrack).CornerRadius = UDim.new(1, 0)

			local knob = Instance.new("Frame", switchTrack)
			knob.Size = UDim2.fromOffset(20, 20)
			knob.AnchorPoint = Vector2.new(0, 0.5)
			knob.Position = spec.Default and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
			knob.BackgroundColor3 = COLORS.White
			knob.BorderSizePixel = 0
			Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

			local state = spec.Default or false
			local function setToggleVisual(newState, silent)
				state = newState
				TweenService:Create(switchTrack, IOS_TIMING.SwitchToggle, {
					BackgroundColor3 = state and COLORS.SwitchOn or COLORS.SwitchOff,
				}):Play()
				TweenService:Create(knob, IOS_TIMING.SwitchToggle, {
					Size = UDim2.fromOffset(20, 20),
					Position = state and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
				}):Play()
				if not silent and spec.Callback then
					spec.Callback(state)
				end
			end

			rowFrame.MouseButton1Down:Connect(function()
				TweenService:Create(rowFrame, IOS_TIMING.PressDown, { BackgroundTransparency = 0.92 }):Play()
				TweenService:Create(knob, IOS_TIMING.PressDown, { Size = UDim2.fromOffset(23, 20) }):Play()
			end)
			rowFrame.MouseLeave:Connect(function()
				TweenService:Create(rowFrame, IOS_TIMING.PressDown, { BackgroundTransparency = 1 }):Play()
				TweenService:Create(knob, IOS_TIMING.PressDown, { Size = UDim2.fromOffset(20, 20) }):Play()
			end)
			rowFrame.Activated:Connect(function()
				TweenService:Create(rowFrame, IOS_TIMING.SwitchToggle, { BackgroundTransparency = 1 }):Play()
				setToggleVisual(not state, false)
			end)

			rowControllers[spec.Title] = { SetState = setToggleVisual }

		elseif spec.Kind == "Input" then
			local inputWrap = Instance.new("Frame", rowFrame)
			inputWrap.Size = UDim2.fromOffset(72, 28)
			inputWrap.AnchorPoint = Vector2.new(1, 0.5)
			inputWrap.Position = UDim2.new(1, -14, 0.5, 0)
			inputWrap.BackgroundColor3 = COLORS.ButtonPill
			inputWrap.BackgroundTransparency = 0.2
			inputWrap.BorderSizePixel = 0
			Instance.new("UICorner", inputWrap).CornerRadius = UDim.new(0, 8)

			local inputStroke = Instance.new("UIStroke", inputWrap)
			inputStroke.Color = COLORS.GlassStrokeColor
			inputStroke.Thickness = 1
			inputStroke.Transparency = 0.55

			local box = Instance.new("TextBox", inputWrap)
			box.Name = "AmountBox"
			box.Size = UDim2.new(1, -12, 1, 0)
			box.Position = UDim2.fromOffset(6, 0)
			box.BackgroundTransparency = 1
			box.Font = Enum.Font.GothamBold
			box.Text = tostring(spec.Default or 50)
			box.PlaceholderText = tostring(spec.Default or 50)
			box.TextColor3 = COLORS.White
			box.PlaceholderColor3 = COLORS.TextMuted
			box.TextSize = 12
			box.ClearTextOnFocus = false

			box.Focused:Connect(function()
				TweenService:Create(inputStroke, IOS_TIMING.PressDown, {
					Color = COLORS.White,
					Transparency = 0.15,
				}):Play()
			end)

			box.FocusLost:Connect(function()
				TweenService:Create(inputStroke, IOS_TIMING.SwitchToggle, {
					Color = COLORS.GlassStrokeColor,
					Transparency = 0.55,
				}):Play()
				local num = tonumber(box.Text)
				if num then
					num = math.clamp(num, spec.Min or 1, spec.Max or 2000)
					box.Text = tostring(num)
					if spec.Callback then
						spec.Callback(num)
					end
				else
					box.Text = tostring(spec.Default or 50)
				end
			end)

			rowFrame.Activated:Connect(function()
				box:CaptureFocus()
			end)

			rowControllers[spec.Title] = {
				SetValue = function(val)
					box.Text = tostring(val)
				end,
			}

		elseif spec.Kind == "Button" then
			local pillColor = spec.Destructive and COLORS.NotifCancelRed or COLORS.ButtonPill
			local pillBtn = Instance.new("TextButton", rowFrame)
			pillBtn.Size = UDim2.fromOffset(78, 28)
			pillBtn.AnchorPoint = Vector2.new(1, 0.5)
			pillBtn.Position = UDim2.new(1, -14, 0.5, 0)
			pillBtn.BackgroundColor3 = pillColor
			pillBtn.BorderSizePixel = 0
			pillBtn.Font = Enum.Font.GothamBold
			pillBtn.Text = spec.ButtonText or "Execute"
			pillBtn.TextColor3 = COLORS.White
			pillBtn.TextSize = 11
			pillBtn.AutoButtonColor = false
			Instance.new("UICorner", pillBtn).CornerRadius = UDim.new(0, 9)

			local pStroke = Instance.new("UIStroke", pillBtn)
			pStroke.Color = COLORS.GlassStrokeColor
			pStroke.Thickness = 1
			pStroke.Transparency = 0.55

			Theme.AttachSpringPress(pillBtn, 0.92, 1.04)

			pillBtn.MouseEnter:Connect(function()
				TweenService:Create(pillBtn, IOS_TIMING.PressDown, {
					BackgroundColor3 = spec.Destructive and COLORS.DangerRed or COLORS.ButtonPillHover,
				}):Play()
			end)
			pillBtn.MouseLeave:Connect(function()
				TweenService:Create(pillBtn, IOS_TIMING.PressDown, { BackgroundColor3 = pillColor }):Play()
			end)
			pillBtn.Activated:Connect(function()
				if spec.Callback then
					spec.Callback()
				end
			end)

		else
			local chevWrap = Instance.new("Frame", rowFrame)
			chevWrap.Size = UDim2.fromOffset(16, 16)
			chevWrap.AnchorPoint = Vector2.new(1, 0.5)
			chevWrap.Position = UDim2.new(1, -14, 0.5, 0)
			chevWrap.BackgroundTransparency = 1
			Icons.CreateVectorIcon(chevWrap, "ChevronRight", spec.Destructive and COLORS.DangerRed or COLORS.TextMuted, 16)

			rowFrame.MouseButton1Down:Connect(function()
				TweenService:Create(rowFrame, IOS_TIMING.PressDown, { BackgroundTransparency = 0.90 }):Play()
			end)
			rowFrame.MouseLeave:Connect(function()
				TweenService:Create(rowFrame, IOS_TIMING.PressDown, { BackgroundTransparency = 1 }):Play()
			end)
			rowFrame.Activated:Connect(function()
				TweenService:Create(rowFrame, IOS_TIMING.SwitchToggle, { BackgroundTransparency = 1 }):Play()
				if spec.Callback then
					spec.Callback()
				end
			end)
		end
	end

	return wrap, rowControllers
end

return Components

]====]
EMBEDDED_FILES["UI/ScriptsPage.lua"] = [====[
--[[
	UI/ScriptsPage.lua
	Scripts Tab: Compact Universal Script Cards + Place-Specific Script Cards
]]

local TweenService = game:GetService("TweenService")

local Root = script.Parent.Parent
local CoreFolder = Root:WaitForChild("Core")
local CommandsFolder = Root:WaitForChild("Commands")

local Config = require(CoreFolder:WaitForChild("Config"))
local Theme = require(CoreFolder:WaitForChild("Theme"))
local Notifications = require(CoreFolder:WaitForChild("Notifications"))
local ScriptDatabase = require(CommandsFolder:WaitForChild("ScriptDatabase"))

local COLORS = Config.COLORS
local IOS_TIMING = Config.IOS_TIMING

local ScriptsPage = {}

function ScriptsPage.Build(pagesHolder)
	local pageWrap = Instance.new("CanvasGroup")
	pageWrap.Name = "Page_Scripts"
	pageWrap.Size = UDim2.fromScale(1, 1)
	pageWrap.BackgroundTransparency = 1
	pageWrap.BorderSizePixel = 0
	pageWrap.Visible = false
	pageWrap.Parent = pagesHolder

	local pageScale = Instance.new("UIScale", pageWrap)
	pageScale.Scale = 1

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "ScriptsScroll"
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

	local layout = Instance.new("UIListLayout", scroll)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)

	local function createScriptCard(parent, order, scriptEntry)
		local card = Instance.new("Frame")
		card.Name = "ScriptCard_" .. (scriptEntry.Name or tostring(order))
		card.LayoutOrder = order
		card.Size = UDim2.new(1, 0, 0, 48)
		card.ClipsDescendants = false
		card.Parent = parent
		Theme.RegisterSurface(card, UDim.new(0, 14), "Card")

		local nameLbl = Instance.new("TextLabel", card)
		nameLbl.Size = UDim2.new(1, -104, 1, 0)
		nameLbl.Position = UDim2.fromOffset(16, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.GothamMedium
		nameLbl.Text = scriptEntry.Name or "Unnamed Script"
		nameLbl.TextColor3 = COLORS.White
		nameLbl.TextSize = 13
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

		local execBtn = Instance.new("TextButton", card)
		execBtn.Name = "ExecuteButton"
		execBtn.Size = UDim2.fromOffset(76, 30)
		execBtn.AnchorPoint = Vector2.new(1, 0.5)
		execBtn.Position = UDim2.new(1, -12, 0.5, 0)
		execBtn.BackgroundColor3 = COLORS.ButtonPill
		execBtn.BorderSizePixel = 0
		execBtn.Font = Enum.Font.GothamBold
		execBtn.Text = "Execute"
		execBtn.TextColor3 = COLORS.White
		execBtn.TextSize = 12
		execBtn.AutoButtonColor = false
		Instance.new("UICorner", execBtn).CornerRadius = UDim.new(0, 9)

		local btnStroke = Instance.new("UIStroke", execBtn)
		btnStroke.Color = COLORS.GlassStrokeColor
		btnStroke.Thickness = 1
		btnStroke.Transparency = 0.50

		Theme.AttachSpringPress(execBtn, 0.90, 1.05)

		execBtn.MouseEnter:Connect(function()
			TweenService:Create(execBtn, IOS_TIMING.PressDown, { BackgroundColor3 = COLORS.ButtonPillHover }):Play()
		end)
		execBtn.MouseLeave:Connect(function()
			TweenService:Create(execBtn, IOS_TIMING.PressDown, { BackgroundColor3 = COLORS.ButtonPill }):Play()
		end)
		execBtn.Activated:Connect(function()
			ScriptDatabase.ExecuteEntry(scriptEntry, Notifications.Notify)
		end)

		return card
	end

	local function populateScriptsScroll()
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		local orderCounter = 1

		local uniHeader = Instance.new("TextLabel", scroll)
		uniHeader.Name = "UniversalHeader"
		uniHeader.LayoutOrder = orderCounter
		orderCounter = orderCounter + 1
		uniHeader.Size = UDim2.new(1, -8, 0, 20)
		uniHeader.BackgroundTransparency = 1
		uniHeader.Font = Enum.Font.GothamBold
		uniHeader.Text = "UNIVERSAL"
		uniHeader.TextColor3 = COLORS.TextMuted
		uniHeader.TextSize = 11
		uniHeader.TextXAlignment = Enum.TextXAlignment.Left

		local universalList = ScriptDatabase.Data.Universal or {}
		if #universalList > 0 then
			for _, entry in ipairs(universalList) do
				createScriptCard(scroll, orderCounter, entry)
				orderCounter = orderCounter + 1
			end
		else
			local emptyUni = Instance.new("Frame", scroll)
			emptyUni.LayoutOrder = orderCounter
			orderCounter = orderCounter + 1
			emptyUni.Size = UDim2.new(1, 0, 0, 48)
			emptyUni.ClipsDescendants = false
			Theme.RegisterSurface(emptyUni, UDim.new(0, 14), "Card")

			local lbl = Instance.new("TextLabel", emptyUni)
			lbl.Size = UDim2.new(1, -24, 1, 0)
			lbl.Position = UDim2.fromOffset(12, 0)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.Gotham
			lbl.Text = "No universal scripts loaded"
			lbl.TextColor3 = COLORS.TextMuted
			lbl.TextSize = 12
		end

		local spacer = Instance.new("Frame", scroll)
		spacer.LayoutOrder = orderCounter
		orderCounter = orderCounter + 1
		spacer.Size = UDim2.new(1, 0, 0, 6)
		spacer.BackgroundTransparency = 1

		local gameHeaderWrap = Instance.new("Frame", scroll)
		gameHeaderWrap.Name = "GameScriptHeaderWrap"
		gameHeaderWrap.LayoutOrder = orderCounter
		orderCounter = orderCounter + 1
		gameHeaderWrap.Size = UDim2.new(1, 0, 0, 32)
		gameHeaderWrap.BackgroundTransparency = 1

		local gameHeader = Instance.new("TextLabel", gameHeaderWrap)
		gameHeader.Size = UDim2.new(1, 0, 0, 16)
		gameHeader.Position = UDim2.fromOffset(0, 0)
		gameHeader.BackgroundTransparency = 1
		gameHeader.Font = Enum.Font.GothamBold
		gameHeader.Text = "SCRIPT FOR THIS GAME"
		gameHeader.TextColor3 = COLORS.TextMuted
		gameHeader.TextSize = 11
		gameHeader.TextXAlignment = Enum.TextXAlignment.Left

		local placeIdSub = Instance.new("TextLabel", gameHeaderWrap)
		placeIdSub.Size = UDim2.new(1, 0, 0, 14)
		placeIdSub.Position = UDim2.fromOffset(0, 16)
		placeIdSub.BackgroundTransparency = 1
		placeIdSub.Font = Enum.Font.Gotham
		placeIdSub.Text = "Place ID: " .. tostring(game.PlaceId)
		placeIdSub.TextColor3 = COLORS.TextMuted
		placeIdSub.TextSize = 11
		placeIdSub.TextXAlignment = Enum.TextXAlignment.Left

		local placeKey = tostring(game.PlaceId)
		local placesTbl = ScriptDatabase.Data.Places or {}
		local gameScripts = placesTbl[placeKey] or placesTbl[game.PlaceId] or {}

		if type(gameScripts) == "table" and #gameScripts > 0 then
			for _, entry in ipairs(gameScripts) do
				createScriptCard(scroll, orderCounter, entry)
				orderCounter = orderCounter + 1
			end
		else
			local noScriptCard = Instance.new("Frame", scroll)
			noScriptCard.Name = "NoScriptsForPlaceCard"
			noScriptCard.LayoutOrder = orderCounter
			orderCounter = orderCounter + 1
			noScriptCard.Size = UDim2.new(1, 0, 0, 56)
			noScriptCard.ClipsDescendants = false
			Theme.RegisterSurface(noScriptCard, UDim.new(0, 14), "Card")

			local emptyLbl = Instance.new("TextLabel", noScriptCard)
			emptyLbl.Size = UDim2.new(1, -28, 1, 0)
			emptyLbl.Position = UDim2.fromOffset(14, 0)
			emptyLbl.BackgroundTransparency = 1
			emptyLbl.Font = Enum.Font.GothamMedium
			emptyLbl.Text = "There's no scripts for this place or for this game"
			emptyLbl.TextColor3 = COLORS.TextMuted
			emptyLbl.TextSize = 12
			emptyLbl.TextWrapped = true
			emptyLbl.TextXAlignment = Enum.TextXAlignment.Center
		end
	end

	ScriptDatabase.SetOnChanged(populateScriptsScroll)
	populateScriptsScroll()

	return pageWrap
end

return ScriptsPage

]====]
EMBEDDED_FILES["UI/PlayerPage.lua"] = [====[
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
	}

	if adv then
		table.insert(flightRows, {
			Title = "CFrame Fly (CFly)",
			Kind = "Toggle",
			Default = State.CFrameFly,
			Callback = function(enabled)
				PlayerCommands.SetCFrameFly(enabled)
			end,
		})
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

]====]
EMBEDDED_FILES["UI/PlayersPage.lua"] = [====[
--[[
	UI/PlayersPage.lua
	Players Tab: Selected Player Banner + Basic/Advanced Infinite Yield Target Actions + Live Server Player List
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Root = script.Parent.Parent
local CoreFolder = Root:WaitForChild("Core")
local CommandsFolder = Root:WaitForChild("Commands")

local Config = require(CoreFolder:WaitForChild("Config"))
local Theme = require(CoreFolder:WaitForChild("Theme"))
local Icons = require(CoreFolder:WaitForChild("Icons"))
local TargetCommands = require(CommandsFolder:WaitForChild("TargetCommands"))
local Components = require(script.Parent:WaitForChild("Components"))

local COLORS = Config.COLORS
local IOS_TIMING = Config.IOS_TIMING
local UISettings = Config.UISettings
local State = TargetCommands.State

local PlayersPage = {}

local RebuildTargetGroupsFn = nil

function PlayersPage.Rebuild()
	if RebuildTargetGroupsFn then
		RebuildTargetGroupsFn()
	end
end

function PlayersPage.Build(pagesHolder)
	local pageWrap = Instance.new("CanvasGroup")
	pageWrap.Name = "Page_Players"
	pageWrap.Size = UDim2.fromScale(1, 1)
	pageWrap.BackgroundTransparency = 1
	pageWrap.BorderSizePixel = 0
	pageWrap.Visible = false
	pageWrap.Parent = pagesHolder

	local pageScale = Instance.new("UIScale", pageWrap)
	pageScale.Scale = 1

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "PlayersScroll"
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
	listLayout.Padding = UDim.new(0, 10)

	local PlayerCardSelectButtons = {}

	-- Top Section: Selected Player Profile Banner
	local topHeaderLbl = Instance.new("TextLabel", scroll)
	topHeaderLbl.LayoutOrder = 1
	topHeaderLbl.Size = UDim2.new(1, -12, 0, 16)
	topHeaderLbl.BackgroundTransparency = 1
	topHeaderLbl.Font = Enum.Font.GothamBold
	topHeaderLbl.Text = "SELECTED PLAYER"
	topHeaderLbl.TextColor3 = COLORS.TextMuted
	topHeaderLbl.TextSize = 11
	topHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left

	local selectedBanner = Instance.new("Frame", scroll)
	selectedBanner.Name = "SelectedPlayerBanner"
	selectedBanner.LayoutOrder = 2
	selectedBanner.Size = UDim2.new(1, 0, 0, 56)
	selectedBanner.ClipsDescendants = false
	Theme.RegisterSurface(selectedBanner, UDim.new(0, 16), "Card")

	local selAvatar = Instance.new("ImageLabel", selectedBanner)
	selAvatar.Size = UDim2.fromOffset(38, 38)
	selAvatar.AnchorPoint = Vector2.new(0, 0.5)
	selAvatar.Position = UDim2.new(0, 12, 0.5, 0)
	selAvatar.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
	selAvatar.BorderSizePixel = 0
	Instance.new("UICorner", selAvatar).CornerRadius = UDim.new(1, 0)

	local selDisplayName = Instance.new("TextLabel", selectedBanner)
	selDisplayName.Size = UDim2.new(1, -70, 0, 18)
	selDisplayName.Position = UDim2.fromOffset(60, 10)
	selDisplayName.BackgroundTransparency = 1
	selDisplayName.Font = Enum.Font.GothamBold
	selDisplayName.Text = "No Player Selected"
	selDisplayName.TextColor3 = COLORS.White
	selDisplayName.TextSize = 13
	selDisplayName.TextXAlignment = Enum.TextXAlignment.Left
	selDisplayName.TextTruncate = Enum.TextTruncate.AtEnd

	local selUsername = Instance.new("TextLabel", selectedBanner)
	selUsername.Size = UDim2.new(1, -70, 0, 15)
	selUsername.Position = UDim2.fromOffset(60, 28)
	selUsername.BackgroundTransparency = 1
	selUsername.Font = Enum.Font.Gotham
	selUsername.Text = "Select a player from the list below"
	selUsername.TextColor3 = COLORS.TextMuted
	selUsername.TextSize = 11
	selUsername.TextXAlignment = Enum.TextXAlignment.Left
	selUsername.TextTruncate = Enum.TextTruncate.AtEnd

	-- Container for Target Action Groups (rebuilt when Advanced Mode toggles)
	local targetActionsContainer = Instance.new("Frame", scroll)
	targetActionsContainer.Name = "TargetActionsContainer"
	targetActionsContainer.LayoutOrder = 3
	targetActionsContainer.Size = UDim2.new(1, 0, 0, 0)
	targetActionsContainer.AutomaticSize = Enum.AutomaticSize.Y
	targetActionsContainer.BackgroundTransparency = 1

	local targetActionsLayout = Instance.new("UIListLayout", targetActionsContainer)
	targetActionsLayout.FillDirection = Enum.FillDirection.Vertical
	targetActionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	targetActionsLayout.Padding = UDim.new(0, 10)

	local activeControllerTables = {}

	RebuildTargetGroupsFn = function()
		activeControllerTables = {}
		for _, child in ipairs(targetActionsContainer:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		local adv = UISettings.AdvancedMode

		local group1Rows = {
			{
				Title = "Teleport to Player (Goto)",
				Kind = "Button",
				ButtonText = "Teleport",
				Callback = function()
					TargetCommands.Goto()
				end,
			},
		}

		if adv then
			table.insert(group1Rows, {
				Title = "Tween to Player",
				Kind = "Button",
				ButtonText = "Tween",
				Callback = function()
					TargetCommands.TweenGoto()
				end,
			})
			table.insert(group1Rows, {
				Title = "Walk to Player",
				Kind = "Button",
				ButtonText = "WalkTo",
				Callback = function()
					TargetCommands.WalkTo()
				end,
			})
		end

		table.insert(group1Rows, {
			Title = "Spectate / View Player",
			Kind = "Toggle",
			Default = State.Spectate,
			Callback = function(enabled)
				TargetCommands.SetSpectate(enabled)
			end,
		})
		table.insert(group1Rows, {
			Title = "Highlight / Locate Player",
			Kind = "Toggle",
			Default = State.Highlight,
			Callback = function(enabled)
				TargetCommands.SetHighlight(enabled)
			end,
		})

		local _, ctrl1 = Components.CreateIosGroup(
			targetActionsContainer,
			1,
			adv and "Target Teleport & Camera" or "Target Actions",
			group1Rows
		)
		table.insert(activeControllerTables, ctrl1)

		if adv then
			local _, ctrl2 = Components.CreateIosGroup(targetActionsContainer, 2, "Target Actions (Infinite Yield)", {
				{
					Title = "Loop Goto / Follow",
					Kind = "Toggle",
					Default = State.Follow,
					Callback = function(enabled)
						State.Follow = enabled
					end,
				},
				{
					Title = "Orbit Player",
					Kind = "Toggle",
					Default = State.Orbit,
					Callback = function(enabled)
						State.Orbit = enabled
					end,
				},
				{
					Title = "Headsit",
					Kind = "Toggle",
					Default = State.Headsit,
					Callback = function(enabled)
						State.Headsit = enabled
					end,
				},
				{
					Title = "Attach Behind (Stand)",
					Kind = "Toggle",
					Default = State.AttachBack,
					Callback = function(enabled)
						State.AttachBack = enabled
					end,
				},
				{
					Title = "Client Bring (LoopBring)",
					Kind = "Toggle",
					Default = State.LoopBring,
					Callback = function(enabled)
						State.LoopBring = enabled
					end,
				},
				{
					Title = "Fling Player",
					Kind = "Toggle",
					Default = State.FlingTarget,
					Callback = function(enabled)
						TargetCommands.SetFlingTarget(enabled)
					end,
				},
				{
					Title = "Stare At Player",
					Kind = "Toggle",
					Default = State.StareAt,
					Callback = function(enabled)
						State.StareAt = enabled
					end,
				},
				{
					Title = "Copy Username",
					Kind = "Button",
					ButtonText = "Copy",
					Callback = function()
						TargetCommands.CopyUsername()
					end,
				},
				{
					Title = "Account Age & Info",
					Kind = "Button",
					ButtonText = "Info",
					Callback = function()
						TargetCommands.InspectAccountInfo()
					end,
				},
			})
			table.insert(activeControllerTables, ctrl2)
		end
	end

	RebuildTargetGroupsFn()

	local function selectPlayer(plr)
		TargetCommands.SetSelectedPlayer(plr)
		if plr then
			selDisplayName.Text = plr.DisplayName
			selUsername.Text = "@" .. plr.Name
			task.spawn(function()
				local ok, thumb = pcall(function()
					return Players:GetUserThumbnailAsync(
						plr.UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size100x100
					)
				end)
				if ok and thumb and TargetCommands.SelectedPlayer == plr then
					selAvatar.Image = thumb
				end
			end)
		else
			selDisplayName.Text = "No Player Selected"
			selUsername.Text = "Select a player from the list below"
			selAvatar.Image = ""
		end

		for p, btnData in pairs(PlayerCardSelectButtons) do
			if btnData.Button and btnData.Button.Parent then
				local isSel = (p == TargetCommands.SelectedPlayer)
				btnData.Button.Text = isSel and "Selected" or "Select"
				TweenService:Create(btnData.Button, IOS_TIMING.SwitchToggle, {
					BackgroundColor3 = isSel and COLORS.SwitchOn or COLORS.ButtonPill,
				}):Play()
			end
		end
	end

	-- Bottom Section: Players in Server Header & Search
	local listHeaderLbl = Instance.new("TextLabel", scroll)
	listHeaderLbl.LayoutOrder = 5
	listHeaderLbl.Size = UDim2.new(1, -12, 0, 18)
	listHeaderLbl.BackgroundTransparency = 1
	listHeaderLbl.Font = Enum.Font.GothamBold
	listHeaderLbl.Text = "PLAYERS IN SERVER"
	listHeaderLbl.TextColor3 = COLORS.TextMuted
	listHeaderLbl.TextSize = 11
	listHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left

	local searchBar = Instance.new("Frame", scroll)
	searchBar.Name = "PlayerSearchBar"
	searchBar.LayoutOrder = 6
	searchBar.Size = UDim2.new(1, 0, 0, 38)
	searchBar.ClipsDescendants = false
	Theme.RegisterSurface(searchBar, UDim.new(0, 12), "Card")

	local searchIconWrap = Instance.new("Frame", searchBar)
	searchIconWrap.Size = UDim2.fromOffset(18, 18)
	searchIconWrap.AnchorPoint = Vector2.new(0, 0.5)
	searchIconWrap.Position = UDim2.new(0, 12, 0.5, 0)
	searchIconWrap.BackgroundTransparency = 1
	Icons.CreateVectorIcon(searchIconWrap, "Search", COLORS.TextMuted, 16)

	local searchBox = Instance.new("TextBox", searchBar)
	searchBox.Size = UDim2.new(1, -44, 1, 0)
	searchBox.Position = UDim2.fromOffset(36, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.Font = Enum.Font.Gotham
	searchBox.PlaceholderText = "Search player..."
	searchBox.Text = ""
	searchBox.TextColor3 = COLORS.White
	searchBox.PlaceholderColor3 = COLORS.TextMuted
	searchBox.TextSize = 12
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false

	local playersListHolder = Instance.new("Frame", scroll)
	playersListHolder.Name = "PlayersListHolder"
	playersListHolder.LayoutOrder = 7
	playersListHolder.Size = UDim2.new(1, 0, 0, 0)
	playersListHolder.AutomaticSize = Enum.AutomaticSize.Y
	playersListHolder.BackgroundTransparency = 1

	local playersListLayout = Instance.new("UIListLayout", playersListHolder)
	playersListLayout.FillDirection = Enum.FillDirection.Vertical
	playersListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	playersListLayout.Padding = UDim.new(0, 8)

	local function rebuildPlayerCards()
		PlayerCardSelectButtons = {}
		for _, child in ipairs(playersListHolder:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		local query = string.lower(searchBox.Text or "")
		local allPlayers = Players:GetPlayers()

		if not TargetCommands.SelectedPlayer or not TargetCommands.SelectedPlayer.Parent then
			if allPlayers[1] then
				selectPlayer(allPlayers[1])
			end
		end

		for idx, plr in ipairs(allPlayers) do
			local matchName = string.find(string.lower(plr.Name), query, 1, true)
				or string.find(string.lower(plr.DisplayName), query, 1, true)

			if query == "" or matchName then
				local pCard = Instance.new("Frame", playersListHolder)
				pCard.Name = "PlayerCard_" .. plr.Name
				pCard.LayoutOrder = idx
				pCard.Size = UDim2.new(1, 0, 0, 52)
				pCard.ClipsDescendants = false
				Theme.RegisterSurface(pCard, UDim.new(0, 14), "Card")

				local avatar = Instance.new("ImageLabel", pCard)
				avatar.Size = UDim2.fromOffset(36, 36)
				avatar.AnchorPoint = Vector2.new(0, 0.5)
				avatar.Position = UDim2.new(0, 10, 0.5, 0)
				avatar.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
				avatar.BorderSizePixel = 0
				Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

				task.spawn(function()
					local ok, thumb = pcall(function()
						return Players:GetUserThumbnailAsync(
							plr.UserId,
							Enum.ThumbnailType.HeadShot,
							Enum.ThumbnailSize.Size100x100
						)
					end)
					if ok and thumb and avatar.Parent then
						avatar.Image = thumb
					end
				end)

				local dispLbl = Instance.new("TextLabel", pCard)
				dispLbl.Size = UDim2.new(1, -142, 0, 17)
				dispLbl.Position = UDim2.fromOffset(54, 9)
				dispLbl.BackgroundTransparency = 1
				dispLbl.Font = Enum.Font.GothamBold
				dispLbl.Text = plr.DisplayName
				dispLbl.TextColor3 = COLORS.White
				dispLbl.TextSize = 13
				dispLbl.TextXAlignment = Enum.TextXAlignment.Left
				dispLbl.TextTruncate = Enum.TextTruncate.AtEnd

				local userLbl = Instance.new("TextLabel", pCard)
				userLbl.Size = UDim2.new(1, -142, 0, 15)
				userLbl.Position = UDim2.fromOffset(54, 26)
				userLbl.BackgroundTransparency = 1
				userLbl.Font = Enum.Font.Gotham
				userLbl.Text = "@" .. plr.Name
				userLbl.TextColor3 = COLORS.TextMuted
				userLbl.TextSize = 11
				userLbl.TextXAlignment = Enum.TextXAlignment.Left
				userLbl.TextTruncate = Enum.TextTruncate.AtEnd

				local isSel = (plr == TargetCommands.SelectedPlayer)
				local selBtn = Instance.new("TextButton", pCard)
				selBtn.Name = "SelectButton"
				selBtn.Size = UDim2.fromOffset(72, 28)
				selBtn.AnchorPoint = Vector2.new(1, 0.5)
				selBtn.Position = UDim2.new(1, -12, 0.5, 0)
				selBtn.BackgroundColor3 = isSel and COLORS.SwitchOn or COLORS.ButtonPill
				selBtn.BorderSizePixel = 0
				selBtn.Font = Enum.Font.GothamBold
				selBtn.Text = isSel and "Selected" or "Select"
				selBtn.TextColor3 = COLORS.White
				selBtn.TextSize = 11
				selBtn.AutoButtonColor = false
				Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0, 9)

				local selStroke = Instance.new("UIStroke", selBtn)
				selStroke.Color = COLORS.GlassStrokeColor
				selStroke.Thickness = 1
				selStroke.Transparency = 0.55

				Theme.AttachSpringPress(selBtn, 0.90, 1.05)

				PlayerCardSelectButtons[plr] = { Button = selBtn }

				selBtn.Activated:Connect(function()
					selectPlayer(plr)
				end)
			end
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(rebuildPlayerCards)
	Players.PlayerAdded:Connect(function()
		task.wait(0.1)
		rebuildPlayerCards()
	end)
	Players.PlayerRemoving:Connect(function(plr)
		if TargetCommands.SelectedPlayer == plr then
			TargetCommands.SetSelectedPlayer(nil)
			for _, ctrlTbl in ipairs(activeControllerTables) do
				for _, ctrl in pairs(ctrlTbl) do
					if ctrl.SetState then
						ctrl.SetState(false, false)
					end
				end
			end
		end
		task.wait(0.05)
		rebuildPlayerCards()
	end)

	rebuildPlayerCards()

	return pageWrap
end

return PlayersPage

]====]
EMBEDDED_FILES["UI/SettingsPage.lua"] = [====[
--[[
	UI/SettingsPage.lua
	Settings Tab: Appearance, Commands (Advanced Mode), Notifications, Window, Reset to Default, and Remove Script from Session
]]

local TweenService = game:GetService("TweenService")

local Root = script.Parent.Parent
local CoreFolder = Root:WaitForChild("Core")
local Config = require(CoreFolder:WaitForChild("Config"))
local Theme = require(CoreFolder:WaitForChild("Theme"))
local Notifications = require(CoreFolder:WaitForChild("Notifications"))
local Components = require(script.Parent:WaitForChild("Components"))
local PlayerPage = require(script.Parent:WaitForChild("PlayerPage"))
local PlayersPage = require(script.Parent:WaitForChild("PlayersPage"))

local UISettings = Config.UISettings
local IOS_TIMING = Config.IOS_TIMING

local SettingsPage = {}

function SettingsPage.Build(pagesHolder, mainWindowFrame, onBlurChanged, onMinimizeToEdge, onUnloadSession)
	local pageWrap = Instance.new("CanvasGroup")
	pageWrap.Name = "Page_Settings"
	pageWrap.Size = UDim2.fromScale(1, 1)
	pageWrap.BackgroundTransparency = 1
	pageWrap.BorderSizePixel = 0
	pageWrap.Visible = false
	pageWrap.Parent = pagesHolder

	local pageScale = Instance.new("UIScale", pageWrap)
	pageScale.Scale = 1

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "IosSettingsScroll"
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

	-- 1. APPEARANCE
	local _, appearanceCtrl = Components.CreateIosGroup(scroll, 1, "Appearance", {
		{
			Title = "Glass UI",
			Kind = "Toggle",
			Default = UISettings.GlassUI,
			Callback = function(enabled)
				UISettings.GlassUI = enabled
				Theme.Refresh()
				if onBlurChanged then
					onBlurChanged()
				end
				Config.SaveSettings()
			end,
		},
		{
			Title = "Background Blur",
			Kind = "Toggle",
			Default = UISettings.BackgroundBlur,
			Callback = function(enabled)
				UISettings.BackgroundBlur = enabled
				if onBlurChanged then
					onBlurChanged()
				end
				Config.SaveSettings()
			end,
		},
	})

	-- 2. COMMANDS (Basic vs Advanced Mode)
	local _, commandsCtrl = Components.CreateIosGroup(scroll, 2, "Commands", {
		{
			Title = "Advanced Mode",
			Kind = "Toggle",
			Default = UISettings.AdvancedMode,
			Callback = function(enabled)
				UISettings.AdvancedMode = enabled
				Config.SaveSettings()
				PlayerPage.Rebuild()
				PlayersPage.Rebuild()
			end,
		},
	})

	-- 3. NOTIFICATIONS
	local _, notifCtrl = Components.CreateIosGroup(scroll, 3, "Notifications", {
		{
			Title = "Swipe to Dismiss",
			Kind = "Toggle",
			Default = UISettings.SwipeToDismiss,
			Callback = function(enabled)
				UISettings.SwipeToDismiss = enabled
				Config.SaveSettings()
			end,
		},
		{
			Title = "Compact Notifications",
			Kind = "Toggle",
			Default = UISettings.CompactNotifications,
			Callback = function(enabled)
				UISettings.CompactNotifications = enabled
				Config.SaveSettings()
			end,
		},
	})

	-- 4. WINDOW & SESSION
	Components.CreateIosGroup(scroll, 4, "Window & Session", {
		{
			Title = "Reset Menu Position",
			Kind = "Action",
			Callback = function()
				TweenService:Create(mainWindowFrame, IOS_TIMING.PanelOpen, {
					Position = Config.REGULAR_WINDOW_POS,
				}):Play()
			end,
		},
		{
			Title = "Minimize to Edge",
			Kind = "Action",
			Callback = function()
				if onMinimizeToEdge then
					onMinimizeToEdge(true)
				end
			end,
		},
		{
			Title = "Reset Settings to Default",
			Kind = "Action",
			Callback = function()
				Config.ResetToDefaults()
				if appearanceCtrl["Glass UI"] then
					appearanceCtrl["Glass UI"].SetState(UISettings.GlassUI, true)
				end
				if appearanceCtrl["Background Blur"] then
					appearanceCtrl["Background Blur"].SetState(UISettings.BackgroundBlur, true)
				end
				if commandsCtrl["Advanced Mode"] then
					commandsCtrl["Advanced Mode"].SetState(UISettings.AdvancedMode, true)
				end
				if notifCtrl["Swipe to Dismiss"] then
					notifCtrl["Swipe to Dismiss"].SetState(UISettings.SwipeToDismiss, true)
				end
				if notifCtrl["Compact Notifications"] then
					notifCtrl["Compact Notifications"].SetState(UISettings.CompactNotifications, true)
				end
				Theme.Refresh()
				if onBlurChanged then
					onBlurChanged()
				end
				PlayerPage.Rebuild()
				PlayersPage.Rebuild()
				TweenService:Create(mainWindowFrame, IOS_TIMING.PanelOpen, {
					Position = Config.REGULAR_WINDOW_POS,
				}):Play()
				Notifications.Notify({
					Title = "Settings Reset",
					Subtitle = "Restored all settings to default",
					Type = "Regular",
					Duration = 2.2,
				})
			end,
		},
		{
			Title = "Remove Script from Session",
			Kind = "Action",
			Destructive = true,
			Callback = function()
				Notifications.Notify({
					Title = "Remove Script?",
					Subtitle = "Unload from current session",
					Type = "Confirm",
					OnConfirm = function()
						if onUnloadSession then
							onUnloadSession()
						end
					end,
					OnCancel = function() end,
				})
			end,
		},
	})

	return pageWrap
end

return SettingsPage

]====]
EMBEDDED_FILES["init.client.lua"] = [====[
--[[
	SurfaceScript/init.client.lua
	Main Entry Point & Window/Dock Shell Controller
	Organizes Core/, Commands/, and UI/ modules cleanly into folders.
	Persists across character deaths/respawns without breaking or resetting.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- Resolve safe UI parent for both Executors and Studio
local function getGuiParent()
	local ok, hui = pcall(function()
		if type(gethui) == "function" then
			return gethui()
		end
		return nil
	end)
	if ok and hui then
		return hui
	end
	local okCore, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if okCore and coreGui then
		local testOk = pcall(function()
			local f = Instance.new("Folder")
			f.Parent = coreGui
			f:Destroy()
		end)
		if testOk then
			return coreGui
		end
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local guiParent = getGuiParent()

-- Respawn Persistence Fix:
-- If placed in StarterGui, Roblox's engine tracks the top-level instance cloned into PlayerGui
-- and destroys it on character respawn even if reparented. By cloning the LocalScript once into
-- PlayerScripts (or ResetOnSpawn=false ScreenGui) with SurfacePersistent=true, the running script
-- is never tracked by StarterGui's respawn cleaner and never breaks when the player dies.
if script and script:IsA("LocalScript") and script:GetAttribute("SurfacePersistent") ~= true then
	if script.Parent and script.Parent:IsA("PlayerGui") then
		if _G.SurfaceScript and _G.SurfaceScript._ScreenGui and _G.SurfaceScript._ScreenGui.Parent then
			return
		end
		local playerScripts = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerScripts")
		local persistentClone = script:Clone()
		persistentClone:SetAttribute("SurfacePersistent", true)
		persistentClone.Parent = playerScripts or guiParent
		return
	end
end

-- Clean up any previous session UI if re-executed manually
if _G.SurfaceScript and type(_G.SurfaceScript.UnloadSession) == "function" then
	pcall(function()
		_G.SurfaceScript.UnloadSession(true)
	end)
end

local existingGui = guiParent:FindFirstChild("SurfaceScriptUI")
if existingGui then
	existingGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SurfaceScriptUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = guiParent

--------------------------------------------------------------------------------
-- LOAD MODULAR FOLDERS (Core, Commands, UI)
--------------------------------------------------------------------------------
local CoreFolder = script:WaitForChild("Core")
local CommandsFolder = script:WaitForChild("Commands")
local UIFolder = script:WaitForChild("UI")

local Config = require(CoreFolder:WaitForChild("Config"))
Config.LoadSettings()

local Theme = require(CoreFolder:WaitForChild("Theme"))
local Icons = require(CoreFolder:WaitForChild("Icons"))
local Notifications = require(CoreFolder:WaitForChild("Notifications"))
Notifications.Init(ScreenGui)

local PlayerCommands = require(CommandsFolder:WaitForChild("PlayerCommands"))
local TargetCommands = require(CommandsFolder:WaitForChild("TargetCommands"))
local ScriptDatabase = require(CommandsFolder:WaitForChild("ScriptDatabase"))

PlayerCommands.SetNotifier(Notifications.Notify)
TargetCommands.SetNotifier(Notifications.Notify)

local ScriptsPage = require(UIFolder:WaitForChild("ScriptsPage"))
local PlayerPage = require(UIFolder:WaitForChild("PlayerPage"))
local PlayersPage = require(UIFolder:WaitForChild("PlayersPage"))
local SettingsPage = require(UIFolder:WaitForChild("SettingsPage"))

local COLORS = Config.COLORS
local IOS_TIMING = Config.IOS_TIMING
local REGULAR_WINDOW_POS = Config.REGULAR_WINDOW_POS

--------------------------------------------------------------------------------
-- DOCK & MAIN WINDOW SHELL
--------------------------------------------------------------------------------
local SuiteBuilt = false
local SuiteVisible = false
local DockHiddenToEdge = false
local WindowOpen = true
local ActiveTabId = "Scripts"

local DockFrame = nil
local MainWindowFrame = nil
local RestoreButton = nil
local SlidingActiveBox = nil
local TabButtons = {}
local TabPages = {}
local HeaderTitleLabel = nil
local HeaderIconContainer = nil
local ActiveInputConnections = {}

local setHiddenToEdge -- forward declaration
local unloadSession -- forward declaration

local function syncWorldBlur()
	Theme.UpdateWorldBlur(SuiteVisible and not DockHiddenToEdge and WindowOpen)
end

local function buildExecutorSuite()
	if SuiteBuilt and DockFrame and DockFrame.Parent then
		return
	end
	SuiteBuilt = true

	local dockWidth = 58
	local dockHeight = 310

	DockFrame = Instance.new("Frame")
	DockFrame.Name = "RightVerticalDock"
	DockFrame.Size = UDim2.fromOffset(dockWidth, dockHeight)
	DockFrame.AnchorPoint = Vector2.new(1, 0.5)
	DockFrame.Position = UDim2.new(1, 90, 0.5, 0)
	DockFrame.ClipsDescendants = false
	DockFrame.ZIndex = 20
	DockFrame.Parent = ScreenGui
	Theme.RegisterSurface(DockFrame, UDim.new(1, 0), "Window")

	local logoBadge = Instance.new("Frame")
	logoBadge.Name = "LogoBadge"
	logoBadge.Size = UDim2.fromOffset(42, 42)
	logoBadge.AnchorPoint = Vector2.new(0.5, 0)
	logoBadge.Position = UDim2.new(0.5, 0, 0, 9)
	logoBadge.ClipsDescendants = false
	logoBadge.ZIndex = 21
	logoBadge.Parent = DockFrame
	Theme.RegisterSurface(logoBadge, UDim.new(1, 0), "Card")

	Icons.CreateSvgLogo(logoBadge, 27, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), 22)

	local navContainer = Instance.new("Frame")
	navContainer.Name = "NavContainer"
	navContainer.Size = UDim2.new(1, 0, 1, -110)
	navContainer.Position = UDim2.fromOffset(0, 60)
	navContainer.BackgroundTransparency = 1
	navContainer.ZIndex = 21
	navContainer.Parent = DockFrame

	SlidingActiveBox = Instance.new("Frame")
	SlidingActiveBox.Name = "SlidingActiveBox"
	SlidingActiveBox.Size = UDim2.fromOffset(42, 40)
	SlidingActiveBox.AnchorPoint = Vector2.new(0.5, 0)
	SlidingActiveBox.Position = UDim2.new(0.5, 0, 0, 0)
	SlidingActiveBox.BackgroundColor3 = Color3.fromRGB(110, 118, 136)
	SlidingActiveBox.BackgroundTransparency = 0.62
	SlidingActiveBox.BorderSizePixel = 0
	SlidingActiveBox.ClipsDescendants = false
	SlidingActiveBox.ZIndex = 21
	SlidingActiveBox.Parent = navContainer
	Instance.new("UICorner", SlidingActiveBox).CornerRadius = UDim.new(0, 13)

	local activeBoxStroke = Instance.new("UIStroke", SlidingActiveBox)
	activeBoxStroke.Color = Color3.fromRGB(195, 205, 225)
	activeBoxStroke.Thickness = 1.2
	activeBoxStroke.Transparency = 0.25
	activeBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local leftPill = Instance.new("Frame", SlidingActiveBox)
	leftPill.Name = "LeftActivePill"
	leftPill.Size = UDim2.fromOffset(3.5, 14)
	leftPill.AnchorPoint = Vector2.new(0.5, 0.5)
	leftPill.Position = UDim2.new(0, 1, 0.5, 0)
	leftPill.BackgroundColor3 = COLORS.White
	leftPill.BorderSizePixel = 0
	leftPill.ZIndex = 24
	Instance.new("UICorner", leftPill).CornerRadius = UDim.new(1, 0)

	local bottomDivider = Instance.new("Frame")
	bottomDivider.Size = UDim2.fromOffset(28, 1)
	bottomDivider.AnchorPoint = Vector2.new(0.5, 1)
	bottomDivider.Position = UDim2.new(0.5, 0, 1, -44)
	bottomDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	bottomDivider.BackgroundTransparency = 0.84
	bottomDivider.BorderSizePixel = 0
	bottomDivider.ZIndex = 21
	bottomDivider.Parent = DockFrame

	local hideDockBtn = Instance.new("TextButton")
	hideDockBtn.Name = "HideDockButton"
	hideDockBtn.Size = UDim2.fromOffset(42, 34)
	hideDockBtn.AnchorPoint = Vector2.new(0.5, 1)
	hideDockBtn.Position = UDim2.new(0.5, 0, 1, -6)
	hideDockBtn.BackgroundTransparency = 1
	hideDockBtn.Text = ""
	hideDockBtn.ZIndex = 22
	hideDockBtn.Parent = DockFrame
	Icons.CreateVectorIcon(hideDockBtn, "ChevronRight", COLORS.IconLight, 20)
	Theme.AttachSpringPress(hideDockBtn, 0.82, 1.08)

	RestoreButton = Instance.new("TextButton")
	RestoreButton.Name = "RestoreSidebarBtn"
	RestoreButton.Size = UDim2.fromOffset(44, 44)
	RestoreButton.AnchorPoint = Vector2.new(1, 0.5)
	RestoreButton.Position = UDim2.new(1, 60, 0.5, 0)
	RestoreButton.Text = ""
	RestoreButton.AutoButtonColor = false
	RestoreButton.ClipsDescendants = false
	RestoreButton.ZIndex = 25
	RestoreButton.Parent = ScreenGui
	Theme.RegisterSurface(RestoreButton, UDim.new(1, 0), "Window")
	Icons.CreateSvgLogo(RestoreButton, 26, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), 26)
	Theme.AttachSpringPress(RestoreButton, 0.86, 1.06)

	MainWindowFrame = Instance.new("Frame")
	MainWindowFrame.Name = "MainContentWindow"
	MainWindowFrame.Size = UDim2.fromOffset(340, 430)
	MainWindowFrame.AnchorPoint = Vector2.new(1, 0.5)
	MainWindowFrame.Position = REGULAR_WINDOW_POS
	MainWindowFrame.ClipsDescendants = false
	MainWindowFrame.ZIndex = 18
	MainWindowFrame.Parent = ScreenGui
	Theme.RegisterSurface(MainWindowFrame, UDim.new(0, 24), "Window")

	local winScale = Instance.new("UIScale")
	winScale.Scale = 0.92
	winScale.Parent = MainWindowFrame

	local draggingWin = false
	local winDragStart = nil
	local winStartPos = nil

	local topGrabArea = Instance.new("Frame")
	topGrabArea.Name = "TopGrabArea"
	topGrabArea.Size = UDim2.new(1, 0, 0, 52)
	topGrabArea.BackgroundTransparency = 1
	topGrabArea.ZIndex = 22
	topGrabArea.Parent = MainWindowFrame

	local grabberPill = Instance.new("Frame")
	grabberPill.Size = UDim2.fromOffset(40, 4)
	grabberPill.AnchorPoint = Vector2.new(0.5, 0)
	grabberPill.Position = UDim2.new(0.5, 0, 0, 8)
	grabberPill.BackgroundColor3 = Color3.fromRGB(200, 210, 228)
	grabberPill.BackgroundTransparency = 0.55
	grabberPill.BorderSizePixel = 0
	grabberPill.ZIndex = 22
	grabberPill.Parent = topGrabArea
	Instance.new("UICorner", grabberPill).CornerRadius = UDim.new(1, 0)

	local headerHolder = Instance.new("Frame")
	headerHolder.Name = "HeaderHolder"
	headerHolder.Size = UDim2.new(1, 0, 0, 26)
	headerHolder.Position = UDim2.fromOffset(0, 20)
	headerHolder.BackgroundTransparency = 1
	headerHolder.ZIndex = 22
	headerHolder.Parent = topGrabArea

	local headerLayout = Instance.new("UIListLayout", headerHolder)
	headerLayout.FillDirection = Enum.FillDirection.Horizontal
	headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	headerLayout.Padding = UDim.new(0, 8)

	HeaderIconContainer = Instance.new("Frame", headerHolder)
	HeaderIconContainer.Size = UDim2.fromOffset(22, 22)
	HeaderIconContainer.BackgroundTransparency = 1
	HeaderIconContainer.LayoutOrder = 1
	HeaderIconContainer.ZIndex = 22

	HeaderTitleLabel = Instance.new("TextLabel", headerHolder)
	HeaderTitleLabel.Size = UDim2.fromOffset(0, 22)
	HeaderTitleLabel.AutomaticSize = Enum.AutomaticSize.X
	HeaderTitleLabel.BackgroundTransparency = 1
	HeaderTitleLabel.Font = Enum.Font.GothamBold
	HeaderTitleLabel.Text = "SCRIPTS"
	HeaderTitleLabel.TextColor3 = COLORS.White
	HeaderTitleLabel.TextSize = 15
	HeaderTitleLabel.LayoutOrder = 2
	HeaderTitleLabel.ZIndex = 22

	topGrabArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingWin = true
			winDragStart = input.Position
			winStartPos = MainWindowFrame.Position
		end
	end)
	table.insert(ActiveInputConnections, UserInputService.InputChanged:Connect(function(input)
		if draggingWin and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - winDragStart
			MainWindowFrame.Position = UDim2.new(
				winStartPos.X.Scale,
				winStartPos.X.Offset + delta.X,
				winStartPos.Y.Scale,
				winStartPos.Y.Offset + delta.Y
			)
		end
	end))
	table.insert(ActiveInputConnections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingWin = false
		end
	end))

	local pagesHolder = Instance.new("Frame")
	pagesHolder.Name = "PagesHolder"
	pagesHolder.Size = UDim2.new(1, -24, 1, -64)
	pagesHolder.Position = UDim2.fromOffset(12, 54)
	pagesHolder.BackgroundTransparency = 1
	pagesHolder.ClipsDescendants = true
	pagesHolder.ZIndex = 19
	pagesHolder.Parent = MainWindowFrame

	-- Build the 4 modular pages
	TabPages["Scripts"] = ScriptsPage.Build(pagesHolder)
	TabPages["Player"] = PlayerPage.Build(pagesHolder)
	TabPages["Players"] = PlayersPage.Build(pagesHolder)
	TabPages["Settings"] = SettingsPage.Build(
		pagesHolder,
		MainWindowFrame,
		syncWorldBlur,
		function(h)
			setHiddenToEdge(h)
		end,
		function()
			unloadSession(false)
		end
	)

	local function selectTab(tabId, headerTitle)
		ActiveTabId = tabId
		if HeaderTitleLabel then
			HeaderTitleLabel.Text = string.upper(headerTitle or tabId)
		end
		if HeaderIconContainer then
			HeaderIconContainer:ClearAllChildren()
			Icons.CreateVectorIcon(HeaderIconContainer, tabId, COLORS.White, 20)
		end

		local targetBtn = TabButtons[tabId]
		if targetBtn and SlidingActiveBox then
			SlidingActiveBox.Visible = WindowOpen
			TweenService:Create(SlidingActiveBox, IOS_TIMING.TabSlide, {
				Position = UDim2.new(0.5, 0, 0, targetBtn.YOffset),
			}):Play()
		end

		for id, pageWrap in pairs(TabPages) do
			if id == tabId then
				pageWrap.Visible = true
				pageWrap.GroupTransparency = 0.45
				local pScale = pageWrap:FindFirstChildOfClass("UIScale")
				if pScale then
					pScale.Scale = 0.95
					TweenService:Create(pScale, IOS_TIMING.PageTransition, { Scale = 1 }):Play()
				end
				TweenService:Create(pageWrap, IOS_TIMING.PageTransition, { GroupTransparency = 0 }):Play()
			else
				pageWrap.Visible = false
			end
		end
	end

	-- Sidebar Button Order: Scripts -> Player -> Players -> Settings
	local sidebarTabs = {
		{ Id = "Scripts",  Title = "SCRIPTS" },
		{ Id = "Player",   Title = "PLAYER" },
		{ Id = "Players",  Title = "PLAYERS" },
		{ Id = "Settings", Title = "SETTINGS" },
	}

	local slotHeight = 42
	local slotGap = 6

	for index, tab in ipairs(sidebarTabs) do
		local yOffset = (index - 1) * (slotHeight + slotGap)
		local slot = Instance.new("TextButton")
		slot.Name = "Tab_" .. tab.Id
		slot.Size = UDim2.fromOffset(42, slotHeight)
		slot.AnchorPoint = Vector2.new(0.5, 0)
		slot.Position = UDim2.new(0.5, 0, 0, yOffset)
		slot.BackgroundTransparency = 1
		slot.Text = ""
		slot.AutoButtonColor = false
		slot.ZIndex = 23
		slot.Parent = navContainer

		Icons.CreateVectorIcon(slot, tab.Id, COLORS.White, 22)
		Theme.AttachSpringPress(slot, 0.82, 1.08)

		TabButtons[tab.Id] = {
			Slot = slot,
			YOffset = yOffset,
		}

		slot.Activated:Connect(function()
			local winScaleObj = MainWindowFrame:FindFirstChildOfClass("UIScale")

			if ActiveTabId == tab.Id then
				if WindowOpen then
					WindowOpen = false
					if SlidingActiveBox then
						SlidingActiveBox.Visible = false
					end
					syncWorldBlur()
					if winScaleObj then
						TweenService:Create(winScaleObj, IOS_TIMING.PanelClose, { Scale = 0.88 }):Play()
					end
					task.delay(0.24, function()
						if not WindowOpen and MainWindowFrame then
							MainWindowFrame.Visible = false
						end
					end)
				else
					WindowOpen = true
					if SlidingActiveBox then
						SlidingActiveBox.Visible = true
					end
					MainWindowFrame.Visible = true
					TweenService:Create(MainWindowFrame, IOS_TIMING.PanelOpen, {
						Position = REGULAR_WINDOW_POS,
					}):Play()
					if winScaleObj then
						TweenService:Create(winScaleObj, IOS_TIMING.PanelOpen, { Scale = 1 }):Play()
					end
					syncWorldBlur()
				end
			else
				WindowOpen = true
				if SlidingActiveBox then
					SlidingActiveBox.Visible = true
				end
				MainWindowFrame.Visible = true
				TweenService:Create(MainWindowFrame, IOS_TIMING.PanelOpen, {
					Position = REGULAR_WINDOW_POS,
				}):Play()
				if winScaleObj then
					TweenService:Create(winScaleObj, IOS_TIMING.PanelOpen, { Scale = 1 }):Play()
				end
				selectTab(tab.Id, tab.Title)
				syncWorldBlur()
			end
		end)
	end

	selectTab("Scripts", "SCRIPTS")

	hideDockBtn.Activated:Connect(function()
		setHiddenToEdge(true)
	end)
	RestoreButton.Activated:Connect(function()
		setHiddenToEdge(false)
	end)
end

local function setPanelVisible(visible)
	buildExecutorSuite()
	SuiteVisible = visible
	DockHiddenToEdge = false
	WindowOpen = visible
	if SlidingActiveBox then
		SlidingActiveBox.Visible = visible
	end
	local winScale = MainWindowFrame:FindFirstChildOfClass("UIScale")
	syncWorldBlur()

	if visible then
		DockFrame.Visible = true
		MainWindowFrame.Visible = true
		TweenService:Create(DockFrame, IOS_TIMING.PanelOpen, {
			Position = UDim2.new(1, -14, 0.5, 0),
		}):Play()
		TweenService:Create(MainWindowFrame, IOS_TIMING.PanelOpen, {
			Position = REGULAR_WINDOW_POS,
		}):Play()
		if winScale then
			TweenService:Create(winScale, IOS_TIMING.PanelOpen, { Scale = 1 }):Play()
		end
		TweenService:Create(RestoreButton, IOS_TIMING.PanelClose, {
			Position = UDim2.new(1, 60, 0.5, 0),
		}):Play()
	else
		TweenService:Create(DockFrame, IOS_TIMING.PanelClose, {
			Position = UDim2.new(1, 90, 0.5, 0),
		}):Play()
		if winScale then
			TweenService:Create(winScale, IOS_TIMING.PanelClose, { Scale = 0.88 }):Play()
		end
		TweenService:Create(RestoreButton, IOS_TIMING.PanelClose, {
			Position = UDim2.new(1, 60, 0.5, 0),
		}):Play()
		task.delay(0.28, function()
			if not SuiteVisible and MainWindowFrame then
				MainWindowFrame.Visible = false
			end
		end)
	end
end

setHiddenToEdge = function(hidden)
	buildExecutorSuite()
	DockHiddenToEdge = hidden
	local winScale = MainWindowFrame:FindFirstChildOfClass("UIScale")
	syncWorldBlur()

	if hidden then
		TweenService:Create(DockFrame, IOS_TIMING.PanelClose, {
			Position = UDim2.new(1, 90, 0.5, 0),
		}):Play()
		if winScale then
			TweenService:Create(winScale, IOS_TIMING.PanelClose, { Scale = 0.88 }):Play()
		end
		task.delay(0.25, function()
			if DockHiddenToEdge and MainWindowFrame then
				MainWindowFrame.Visible = false
			end
		end)
		TweenService:Create(RestoreButton, IOS_TIMING.PanelOpen, {
			Position = UDim2.new(1, -12, 0.5, 0),
		}):Play()
	else
		SuiteVisible = true
		TweenService:Create(RestoreButton, IOS_TIMING.PanelClose, {
			Position = UDim2.new(1, 60, 0.5, 0),
		}):Play()
		TweenService:Create(DockFrame, IOS_TIMING.PanelOpen, {
			Position = UDim2.new(1, -14, 0.5, 0),
		}):Play()
		if WindowOpen then
			if SlidingActiveBox then
				SlidingActiveBox.Visible = true
			end
			MainWindowFrame.Visible = true
			TweenService:Create(MainWindowFrame, IOS_TIMING.PanelOpen, {
				Position = REGULAR_WINDOW_POS,
			}):Play()
			if winScale then
				TweenService:Create(winScale, IOS_TIMING.PanelOpen, { Scale = 1 }):Play()
			end
		end
	end
end

unloadSession = function(silent)
	pcall(function()
		PlayerCommands.CleanupAll()
	end)
	pcall(function()
		TargetCommands.CleanupAll()
	end)
	for _, conn in ipairs(ActiveInputConnections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	ActiveInputConnections = {}
	pcall(function()
		Theme.Cleanup()
	end)
	_G.SurfaceScript = nil
	shared.SurfaceScript = nil
	pcall(function()
		if type(getgenv) == "function" then
			getgenv().SurfaceScript = nil
		end
	end)
	if ScreenGui and ScreenGui.Parent then
		ScreenGui:Destroy()
	end
	if not silent and script and script.Parent then
		pcall(function()
			script:Destroy()
		end)
	end
end

local SurfaceScriptAPI = {
	_ScreenGui = ScreenGui,
	SessionExecuted = false,
	Settings = Config.UISettings,
	PlayerCommands = PlayerCommands,
	TargetCommands = TargetCommands,
	Database = ScriptDatabase.Data,
	Notify = Notifications.Notify,
	SetPanelVisible = setPanelVisible,
	SetHiddenToEdge = setHiddenToEdge,
	SaveSettings = Config.SaveSettings,
	ResetSettings = Config.ResetToDefaults,
	UnloadSession = unloadSession,
	LoadDatabaseFromUrl = ScriptDatabase.LoadFromUrl,
	RefreshScripts = ScriptDatabase.TriggerRefresh,
	AddUniversalScript = ScriptDatabase.AddUniversalScript,
	AddGameScript = ScriptDatabase.AddGameScript,
	TogglePanel = function()
		if DockHiddenToEdge then
			setHiddenToEdge(false)
		else
			setPanelVisible(not SuiteVisible)
		end
	end,
}

function SurfaceScriptAPI.ExecuteSession(forceFirstTime)
	if forceFirstTime then
		SurfaceScriptAPI.SessionExecuted = false
		if SuiteBuilt then
			setPanelVisible(false)
		end
	end

	-- Always prompt with the iOS Confirm notification (X / Checkmark) to execute or not
	if not SurfaceScriptAPI.SessionExecuted then
		Notifications.Notify({
			Title = "Confirm action?",
			Subtitle = "Execute game script",
			Type = "Confirm",
			OnConfirm = function()
				SurfaceScriptAPI.SessionExecuted = true
				setPanelVisible(true)
			end,
			OnCancel = function() end,
		})
	else
		setPanelVisible(true)
		Notifications.Notify({
			Title = "Surface Script",
			Subtitle = "Want to load everything?",
			Type = "Regular",
		})
	end
end

_G.SurfaceScript = SurfaceScriptAPI
shared.SurfaceScript = SurfaceScriptAPI
pcall(function()
	if type(getgenv) == "function" then
		getgenv().SurfaceScript = SurfaceScriptAPI
	end
end)

if type(ScriptDatabase.DATABASE_URL) == "string" and #ScriptDatabase.DATABASE_URL > 0 then
	task.spawn(function()
		ScriptDatabase.LoadFromUrl(ScriptDatabase.DATABASE_URL)
	end)
end

task.delay(0.4, function()
	SurfaceScriptAPI.ExecuteSession(true)
end)

]====]

local function fetchFile(relativePath)
	-- 1. Try local executor workspace folder first if present
	local okLocal, localContent = pcall(function()
		if type(isfile) == "function" and type(readfile) == "function" then
			if isfile("SurfaceScript/" .. relativePath) then
				return readfile("SurfaceScript/" .. relativePath)
			elseif isfile(relativePath) then
				return readfile(relativePath)
			end
		end
		return nil
	end)
	if okLocal and type(localContent) == "string" and #localContent > 0 then
		return localContent
	end

	-- 2. Try GitHub Raw URL if configured (wrapped in pcall so it never crashes on 404)
	if type(GITHUB_RAW_BASE) == "string" and #GITHUB_RAW_BASE > 0 and not string.find(GITHUB_RAW_BASE, "YOUR_USERNAME", 1, true) then
		local base = GITHUB_RAW_BASE
		if string.sub(base, -1) ~= "/" then
			base = base .. "/"
		end

		local candidateUrls = {
			base .. relativePath,
			base .. "SurfaceScript/" .. relativePath,
		}

		for _, url in ipairs(candidateUrls) do
			local okHttp, res = pcall(function()
				return game:HttpGet(url)
			end)
			if okHttp and type(res) == "string" and #res > 0 and not string.find(res, "^404:") then
				return res
			end
		end
	end

	-- 3. Built-in fallback so the script always loads in any executor without HTTP 404
	return EMBEDDED_FILES[relativePath]
end

local VirtualRoot = Instance.new("LocalScript")
VirtualRoot.Name = "SurfaceExecutorScript"
VirtualRoot:SetAttribute("SurfacePersistent", true)

local ModuleSources = {}
local ModuleCache = {}

for folderName, modList in pairs(MODULE_TREE) do
	local folder = Instance.new("Folder")
	folder.Name = folderName
	folder.Parent = VirtualRoot

	for _, modName in ipairs(modList) do
		local modInstance = Instance.new("ModuleScript")
		modInstance.Name = modName
		modInstance.Parent = folder

		local relPath = folderName .. "/" .. modName .. ".lua"
		local src = fetchFile(relPath)
		ModuleSources[modInstance] = src
		pcall(function()
			modInstance.Source = src
		end)
	end
end

local realRequire = require
local function customRequire(target)
	if ModuleCache[target] ~= nil then
		return ModuleCache[target]
	end
	if ModuleSources[target] then
		local wrappedSrc = "local script, require = ...\n" .. ModuleSources[target]
		local chunk, err = loadstring(wrappedSrc, "@" .. target:GetFullName())
		if not chunk then
			error(err)
		end
		local res = chunk(target, customRequire)
		ModuleCache[target] = res
		return res
	end
	return realRequire(target)
end

local initSource = "local script, require = ...\n" .. fetchFile("init.client.lua")
local mainChunk, mainErr = loadstring(initSource, "@SurfaceScript/init.client.lua")
if not mainChunk then
	error(mainErr)
end

mainChunk(VirtualRoot, customRequire)
