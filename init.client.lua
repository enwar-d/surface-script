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
