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
