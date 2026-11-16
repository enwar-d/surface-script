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
		Instance.new("UICorner", execBtn).CornerRadius = UDim.new(1, 0)

		local btnStroke = Instance.new("UIStroke", execBtn)
		btnStroke.Color = COLORS.GlassStrokeColor
		btnStroke.Thickness = 1
		btnStroke.Transparency = 0.50
		Theme.RegisterControl(execBtn, btnStroke, 0.70, Color3.fromRGB(220, 234, 255))

		Theme.AttachSpringPress(execBtn, 0.90, 1.05)

		execBtn.MouseEnter:Connect(function()
			if Config.UISettings.GlassUI then
				TweenService:Create(execBtn, IOS_TIMING.PressDown, { BackgroundTransparency = 0.56 }):Play()
			else
				TweenService:Create(execBtn, IOS_TIMING.PressDown, { BackgroundColor3 = COLORS.ButtonPillHover }):Play()
			end
		end)
		execBtn.MouseLeave:Connect(function()
			if Config.UISettings.GlassUI then
				TweenService:Create(execBtn, IOS_TIMING.PressDown, { BackgroundTransparency = 0.70 }):Play()
			else
				TweenService:Create(execBtn, IOS_TIMING.PressDown, { BackgroundColor3 = COLORS.ButtonPill }):Play()
			end
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
