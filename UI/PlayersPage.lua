--[[
	UI/PlayersPage.lua
	Players Tab:
	  1. Player selector dropdown at the top (tap to open, search inside, tap a player to select)
	  2. Target actions below (Basic / Advanced Infinite Yield commands)
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

local LocalPlayer = Players.LocalPlayer

local PlayersPage = {}

local RebuildTargetGroupsFn = nil

-- Dropdown sizing
local HEADER_H = 60
local SEARCH_H = 34
local ROW_H = 44
local MAX_VISIBLE_ROWS = 5
local DROPDOWN_TWEEN = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local ThumbCache = {}

local function getThumb(userId, callback)
	if ThumbCache[userId] then
		callback(ThumbCache[userId])
		return
	end
	task.spawn(function()
		local ok, thumb = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok and thumb then
			ThumbCache[userId] = thumb
			callback(thumb)
		end
	end)
end

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

	----------------------------------------------------------------------------
	-- 1. PLAYER SELECTOR DROPDOWN
	----------------------------------------------------------------------------
	local topHeaderLbl = Instance.new("TextLabel", scroll)
	topHeaderLbl.LayoutOrder = 1
	topHeaderLbl.Size = UDim2.new(1, -12, 0, 14)
	topHeaderLbl.BackgroundTransparency = 1
	topHeaderLbl.Font = Enum.Font.GothamBold
	topHeaderLbl.Text = "  TARGET PLAYER"
	topHeaderLbl.TextColor3 = COLORS.TextMuted
	topHeaderLbl.TextSize = 11
	topHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left

	local dropdown = Instance.new("Frame", scroll)
	dropdown.Name = "PlayerDropdown"
	dropdown.LayoutOrder = 2
	dropdown.Size = UDim2.new(1, 0, 0, HEADER_H)
	dropdown.ClipsDescendants = true
	Theme.RegisterSurface(dropdown, UDim.new(0, 16), "Card")

	local dropdownOpen = false

	-- Header (always visible, tap to open/close)
	local header = Instance.new("TextButton", dropdown)
	header.Name = "DropdownHeader"
	header.Size = UDim2.new(1, 0, 0, HEADER_H)
	header.BackgroundTransparency = 1
	header.Text = ""
	header.AutoButtonColor = false
	header.ZIndex = 2

	local selAvatar = Instance.new("ImageLabel", header)
	selAvatar.Size = UDim2.fromOffset(38, 38)
	selAvatar.AnchorPoint = Vector2.new(0, 0.5)
	selAvatar.Position = UDim2.new(0, 12, 0.5, 0)
	selAvatar.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
	selAvatar.BackgroundTransparency = 0.3
	selAvatar.BorderSizePixel = 0
	selAvatar.ZIndex = 2
	Instance.new("UICorner", selAvatar).CornerRadius = UDim.new(1, 0)
	local avatarRing = Instance.new("UIStroke", selAvatar)
	avatarRing.Color = COLORS.White
	avatarRing.Transparency = 0.6
	avatarRing.Thickness = 1.2

	local selDisplayName = Instance.new("TextLabel", header)
	selDisplayName.Size = UDim2.new(1, -150, 0, 18)
	selDisplayName.Position = UDim2.fromOffset(60, 12)
	selDisplayName.BackgroundTransparency = 1
	selDisplayName.Font = Enum.Font.GothamBold
	selDisplayName.Text = "Select a player"
	selDisplayName.TextColor3 = COLORS.White
	selDisplayName.TextSize = 13
	selDisplayName.TextXAlignment = Enum.TextXAlignment.Left
	selDisplayName.TextTruncate = Enum.TextTruncate.AtEnd
	selDisplayName.ZIndex = 2

	local selUsername = Instance.new("TextLabel", header)
	selUsername.Size = UDim2.new(1, -150, 0, 15)
	selUsername.Position = UDim2.fromOffset(60, 31)
	selUsername.BackgroundTransparency = 1
	selUsername.Font = Enum.Font.Gotham
	selUsername.Text = "Tap to choose a target"
	selUsername.TextColor3 = COLORS.TextMuted
	selUsername.TextSize = 11
	selUsername.TextXAlignment = Enum.TextXAlignment.Left
	selUsername.TextTruncate = Enum.TextTruncate.AtEnd
	selUsername.ZIndex = 2

	local countPill = Instance.new("TextLabel", header)
	countPill.Size = UDim2.fromOffset(0, 22)
	countPill.AutomaticSize = Enum.AutomaticSize.X
	countPill.AnchorPoint = Vector2.new(1, 0.5)
	countPill.Position = UDim2.new(1, -40, 0.5, 0)
	countPill.BackgroundColor3 = COLORS.White
	countPill.BackgroundTransparency = 0.88
	countPill.Font = Enum.Font.GothamBold
	countPill.Text = "0"
	countPill.TextColor3 = COLORS.SubText
	countPill.TextSize = 11
	countPill.ZIndex = 2
	Instance.new("UICorner", countPill).CornerRadius = UDim.new(1, 0)
	local countPad = Instance.new("UIPadding", countPill)
	countPad.PaddingLeft = UDim.new(0, 9)
	countPad.PaddingRight = UDim.new(0, 9)

	local chevWrap = Instance.new("Frame", header)
	chevWrap.Size = UDim2.fromOffset(18, 18)
	chevWrap.AnchorPoint = Vector2.new(1, 0.5)
	chevWrap.Position = UDim2.new(1, -14, 0.5, 0)
	chevWrap.BackgroundTransparency = 1
	chevWrap.ZIndex = 2
	local chevron = Icons.CreateVectorIcon(chevWrap, "ChevronRight", COLORS.IconLight, 16)
	chevron.Rotation = 90 -- points down when closed

	-- Body (search + list), revealed when the dropdown expands
	local body = Instance.new("Frame", dropdown)
	body.Name = "DropdownBody"
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Position = UDim2.fromOffset(0, HEADER_H)
	body.BackgroundTransparency = 1
	body.ZIndex = 2

	local bodyDivider = Instance.new("Frame", body)
	bodyDivider.Size = UDim2.new(1, -24, 0, 1)
	bodyDivider.Position = UDim2.fromOffset(12, 0)
	bodyDivider.BackgroundColor3 = COLORS.White
	bodyDivider.BackgroundTransparency = 0.88
	bodyDivider.BorderSizePixel = 0
	bodyDivider.ZIndex = 2

	local searchBar = Instance.new("Frame", body)
	searchBar.Name = "PlayerSearchBar"
	searchBar.Size = UDim2.new(1, -24, 0, SEARCH_H)
	searchBar.Position = UDim2.fromOffset(12, 9)
	searchBar.BackgroundColor3 = COLORS.White
	searchBar.BackgroundTransparency = 0.9
	searchBar.BorderSizePixel = 0
	searchBar.ZIndex = 2
	Instance.new("UICorner", searchBar).CornerRadius = UDim.new(0, 10)
	local searchStroke = Instance.new("UIStroke", searchBar)
	searchStroke.Color = COLORS.White
	searchStroke.Transparency = 0.82
	searchStroke.Thickness = 1

	local searchIconWrap = Instance.new("Frame", searchBar)
	searchIconWrap.Size = UDim2.fromOffset(16, 16)
	searchIconWrap.AnchorPoint = Vector2.new(0, 0.5)
	searchIconWrap.Position = UDim2.new(0, 10, 0.5, 0)
	searchIconWrap.BackgroundTransparency = 1
	searchIconWrap.ZIndex = 2
	Icons.CreateVectorIcon(searchIconWrap, "Search", COLORS.TextMuted, 15)

	local searchBox = Instance.new("TextBox", searchBar)
	searchBox.Size = UDim2.new(1, -40, 1, 0)
	searchBox.Position = UDim2.fromOffset(32, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.Font = Enum.Font.Gotham
	searchBox.PlaceholderText = "Search players..."
	searchBox.Text = ""
	searchBox.TextColor3 = COLORS.White
	searchBox.PlaceholderColor3 = COLORS.TextMuted
	searchBox.TextSize = 12
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.ZIndex = 2

	searchBox.Focused:Connect(function()
		TweenService:Create(searchStroke, IOS_TIMING.PressDown, { Transparency = 0.45 }):Play()
	end)
	searchBox.FocusLost:Connect(function()
		TweenService:Create(searchStroke, IOS_TIMING.SwitchToggle, { Transparency = 0.82 }):Play()
	end)

	local playerList = Instance.new("ScrollingFrame", body)
	playerList.Name = "PlayerList"
	playerList.Size = UDim2.new(1, -24, 0, ROW_H)
	playerList.Position = UDim2.fromOffset(12, 9 + SEARCH_H + 6)
	playerList.BackgroundTransparency = 1
	playerList.BorderSizePixel = 0
	playerList.ScrollBarThickness = 2
	playerList.ScrollBarImageColor3 = Color3.fromRGB(170, 180, 205)
	playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
	playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	playerList.ScrollingDirection = Enum.ScrollingDirection.Y
	playerList.ZIndex = 2

	local playerListLayout = Instance.new("UIListLayout", playerList)
	playerListLayout.FillDirection = Enum.FillDirection.Vertical
	playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local currentListHeight = ROW_H

	local function openHeight()
		return HEADER_H + 9 + SEARCH_H + 6 + currentListHeight + 8
	end

	local function setDropdownOpen(open)
		dropdownOpen = open
		TweenService:Create(dropdown, DROPDOWN_TWEEN, {
			Size = UDim2.new(1, 0, 0, open and openHeight() or HEADER_H),
		}):Play()
		TweenService:Create(chevron, DROPDOWN_TWEEN, { Rotation = open and 270 or 90 }):Play()
		if not open and searchBox:IsFocused() then
			searchBox:ReleaseFocus()
		end
	end

	header.Activated:Connect(function()
		setDropdownOpen(not dropdownOpen)
	end)
	header.MouseButton1Down:Connect(function()
		TweenService:Create(header, IOS_TIMING.PressDown, { BackgroundTransparency = 0.94 }):Play()
	end)
	header.MouseButton1Up:Connect(function()
		TweenService:Create(header, IOS_TIMING.SwitchToggle, { BackgroundTransparency = 1 }):Play()
	end)
	header.MouseLeave:Connect(function()
		TweenService:Create(header, IOS_TIMING.SwitchToggle, { BackgroundTransparency = 1 }):Play()
	end)
	header.BackgroundColor3 = COLORS.White

	----------------------------------------------------------------------------
	-- 2. TARGET ACTIONS (rebuilt when Advanced Mode toggles)
	----------------------------------------------------------------------------
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

		-- Fun Time Friday section (mutually exclusive toggles)
		local funCtrl = nil
		local funSpecs = {
			{ Title = "🎯 Bang V2", Mode = "BangV2" },
			{ Title = "🎉 Get Banged", Mode = "GetBanged" },
			{ Title = "💥 Suck", Mode = "Suck" },
			{ Title = "🔥 Get Suc", Mode = "GetSuc" },
		}
		local funRows = {}
		for _, fs in ipairs(funSpecs) do
			table.insert(funRows, {
				Title = fs.Title,
				Kind = "Toggle",
				Default = State[fs.Mode],
				Callback = function(enabled)
					TargetCommands.SetFunMode(fs.Mode, enabled)
					if funCtrl then
						for _, other in ipairs(funSpecs) do
							if funCtrl[other.Title] then
								funCtrl[other.Title].SetState(State[other.Mode], true)
							end
						end
					end
				end,
			})
		end
		local _, ctrlFun = Components.CreateIosGroup(targetActionsContainer, 2, "Fun Time Friday", funRows)
		funCtrl = ctrlFun
		table.insert(activeControllerTables, ctrlFun)

		if adv then
			local _, ctrl2 = Components.CreateIosGroup(targetActionsContainer, 3, "Target Actions (Infinite Yield)", {
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

	----------------------------------------------------------------------------
	-- SELECTION + LIST BUILDING
	----------------------------------------------------------------------------
	local rebuildPlayerList -- forward declaration

	local function selectPlayer(plr)
		TargetCommands.SetSelectedPlayer(plr)
		if plr then
			selDisplayName.Text = plr.DisplayName .. (plr == LocalPlayer and "  (You)" or "")
			selUsername.Text = "@" .. plr.Name
			selAvatar.Image = ThumbCache[plr.UserId] or ""
			getThumb(plr.UserId, function(thumb)
				if TargetCommands.SelectedPlayer == plr then
					selAvatar.Image = thumb
				end
			end)
		else
			selDisplayName.Text = "Select a player"
			selUsername.Text = "Tap to choose a target"
			selAvatar.Image = ""
		end
	end

	local function makePlayerRow(plr, order, isLast)
		local isSel = (plr == TargetCommands.SelectedPlayer)

		local row = Instance.new("TextButton")
		row.Name = "PlayerRow_" .. plr.Name
		row.LayoutOrder = order
		row.Size = UDim2.new(1, 0, 0, ROW_H)
		row.BackgroundColor3 = COLORS.White
		row.BackgroundTransparency = isSel and 0.88 or 1
		row.BorderSizePixel = 0
		row.Text = ""
		row.AutoButtonColor = false
		row.ZIndex = 2
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 11)

		local avatar = Instance.new("ImageLabel", row)
		avatar.Size = UDim2.fromOffset(30, 30)
		avatar.AnchorPoint = Vector2.new(0, 0.5)
		avatar.Position = UDim2.new(0, 8, 0.5, 0)
		avatar.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
		avatar.BackgroundTransparency = 0.3
		avatar.BorderSizePixel = 0
		avatar.Image = ThumbCache[plr.UserId] or ""
		avatar.ZIndex = 2
		Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
		getThumb(plr.UserId, function(thumb)
			if avatar.Parent then
				avatar.Image = thumb
			end
		end)

		local dispLbl = Instance.new("TextLabel", row)
		dispLbl.Size = UDim2.new(1, -110, 0, 16)
		dispLbl.Position = UDim2.fromOffset(46, 6)
		dispLbl.BackgroundTransparency = 1
		dispLbl.Font = Enum.Font.GothamBold
		dispLbl.Text = plr.DisplayName .. (plr == LocalPlayer and "  (You)" or "")
		dispLbl.TextColor3 = COLORS.White
		dispLbl.TextSize = 12
		dispLbl.TextXAlignment = Enum.TextXAlignment.Left
		dispLbl.TextTruncate = Enum.TextTruncate.AtEnd
		dispLbl.ZIndex = 2

		local userLbl = Instance.new("TextLabel", row)
		userLbl.Size = UDim2.new(1, -110, 0, 14)
		userLbl.Position = UDim2.fromOffset(46, 22)
		userLbl.BackgroundTransparency = 1
		userLbl.Font = Enum.Font.Gotham
		userLbl.Text = "@" .. plr.Name
		userLbl.TextColor3 = COLORS.TextMuted
		userLbl.TextSize = 10
		userLbl.TextXAlignment = Enum.TextXAlignment.Left
		userLbl.TextTruncate = Enum.TextTruncate.AtEnd
		userLbl.ZIndex = 2

		if isSel then
			local selDot = Instance.new("Frame", row)
			selDot.Size = UDim2.fromOffset(8, 8)
			selDot.AnchorPoint = Vector2.new(1, 0.5)
			selDot.Position = UDim2.new(1, -14, 0.5, 0)
			selDot.BackgroundColor3 = COLORS.SwitchOn
			selDot.BorderSizePixel = 0
			selDot.ZIndex = 2
			Instance.new("UICorner", selDot).CornerRadius = UDim.new(1, 0)
			local glow = Instance.new("UIStroke", selDot)
			glow.Color = COLORS.SwitchOn
			glow.Thickness = 3
			glow.Transparency = 0.7
		end

		if not isLast then
			local div = Instance.new("Frame", row)
			div.Size = UDim2.new(1, -54, 0, 1)
			div.Position = UDim2.new(0, 46, 1, -1)
			div.BackgroundColor3 = COLORS.White
			div.BackgroundTransparency = 0.92
			div.BorderSizePixel = 0
			div.ZIndex = 2
		end

		row.MouseEnter:Connect(function()
			if plr ~= TargetCommands.SelectedPlayer then
				TweenService:Create(row, IOS_TIMING.PressDown, { BackgroundTransparency = 0.94 }):Play()
			end
		end)
		row.MouseLeave:Connect(function()
			if plr ~= TargetCommands.SelectedPlayer then
				TweenService:Create(row, IOS_TIMING.PressDown, { BackgroundTransparency = 1 }):Play()
			end
		end)
		row.Activated:Connect(function()
			selectPlayer(plr)
			rebuildPlayerList()
			setDropdownOpen(false)
		end)

		row.Parent = playerList
		return row
	end

	rebuildPlayerList = function()
		for _, child in ipairs(playerList:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		local allPlayers = Players:GetPlayers()
		countPill.Text = tostring(#allPlayers) .. (#allPlayers == 1 and " player" or " players")

		-- Auto-select: prefer someone other than yourself
		if not TargetCommands.SelectedPlayer or not TargetCommands.SelectedPlayer.Parent then
			local pick = nil
			for _, p in ipairs(allPlayers) do
				if p ~= LocalPlayer then
					pick = p
					break
				end
			end
			pick = pick or allPlayers[1]
			if pick then
				selectPlayer(pick)
			end
		end

		-- Sort: others alphabetically, yourself last
		table.sort(allPlayers, function(a, b)
			if (a == LocalPlayer) ~= (b == LocalPlayer) then
				return b == LocalPlayer
			end
			return string.lower(a.DisplayName) < string.lower(b.DisplayName)
		end)

		local query = string.lower(searchBox.Text or "")
		local matches = {}
		for _, plr in ipairs(allPlayers) do
			if query == ""
				or string.find(string.lower(plr.Name), query, 1, true)
				or string.find(string.lower(plr.DisplayName), query, 1, true)
			then
				table.insert(matches, plr)
			end
		end

		for i, plr in ipairs(matches) do
			makePlayerRow(plr, i, i == #matches)
		end

		if #matches == 0 then
			local empty = Instance.new("TextLabel", playerList)
			empty.Size = UDim2.new(1, 0, 0, ROW_H)
			empty.BackgroundTransparency = 1
			empty.Font = Enum.Font.GothamMedium
			empty.Text = "No players match \"" .. (searchBox.Text or "") .. "\""
			empty.TextColor3 = COLORS.TextMuted
			empty.TextSize = 12
			empty.TextTruncate = Enum.TextTruncate.AtEnd
			empty.ZIndex = 2
		end

		local visibleRows = math.clamp(#matches, 1, MAX_VISIBLE_ROWS)
		currentListHeight = visibleRows * ROW_H
		playerList.Size = UDim2.new(1, -24, 0, currentListHeight)

		if dropdownOpen then
			TweenService:Create(dropdown, DROPDOWN_TWEEN, {
				Size = UDim2.new(1, 0, 0, openHeight()),
			}):Play()
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(rebuildPlayerList)
	Players.PlayerAdded:Connect(function()
		task.wait(0.1)
		rebuildPlayerList()
	end)
	Players.PlayerRemoving:Connect(function(plr)
		ThumbCache[plr.UserId] = nil
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
		rebuildPlayerList()
	end)

	rebuildPlayerList()

	return pageWrap
end

return PlayersPage
