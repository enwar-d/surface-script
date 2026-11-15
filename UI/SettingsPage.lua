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
