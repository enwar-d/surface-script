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
	RefractionFollowsCursor = false,
	SmallerWindow = false,
	SwipeToDismiss = true,
	CompactNotifications = true,
	AdvancedMode = false,
}

Config.UISettings = {
	GlassUI = Config.DefaultSettings.GlassUI,
	BackgroundBlur = Config.DefaultSettings.BackgroundBlur,
	RefractionFollowsCursor = Config.DefaultSettings.RefractionFollowsCursor,
	SmallerWindow = Config.DefaultSettings.SmallerWindow,
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

	-- Liquid Glass (see Core/Theme.lua for the layer recipe)
	GlassWindowTop = Color3.fromRGB(58, 68, 94),
	GlassWindowBottom = Color3.fromRGB(10, 12, 20),
	GlassWindowTrans = 0.42,

	GlassCardTop = Color3.fromRGB(195, 210, 240),
	GlassCardBottom = Color3.fromRGB(105, 120, 155),
	GlassCardTrans = 0.84,

	GlassCaustic = Color3.fromRGB(170, 205, 255),
	GlassWorldBlur = 18,

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
		RefractionFollowsCursor = Config.UISettings.RefractionFollowsCursor,
		SmallerWindow = Config.UISettings.SmallerWindow,
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
