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
			Theme.RegisterControl(inputWrap, nil, 0.45)

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
			local glassColor = spec.Destructive and Color3.fromRGB(255, 95, 85) or Color3.fromRGB(220, 234, 255)
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
			Instance.new("UICorner", pillBtn).CornerRadius = UDim.new(1, 0)

			local pStroke = Instance.new("UIStroke", pillBtn)
			pStroke.Color = COLORS.GlassStrokeColor
			pStroke.Thickness = 1
			pStroke.Transparency = 0.55
			Theme.RegisterControl(pillBtn, pStroke, spec.Destructive and 0.45 or 0.70, glassColor)

			Theme.AttachSpringPress(pillBtn, 0.92, 1.04)

			pillBtn.MouseEnter:Connect(function()
				if Config.UISettings.GlassUI then
					TweenService:Create(pillBtn, IOS_TIMING.PressDown, {
						BackgroundTransparency = spec.Destructive and 0.32 or 0.56,
					}):Play()
				else
					TweenService:Create(pillBtn, IOS_TIMING.PressDown, {
						BackgroundColor3 = spec.Destructive and COLORS.DangerRed or COLORS.ButtonPillHover,
					}):Play()
				end
			end)
			pillBtn.MouseLeave:Connect(function()
				if Config.UISettings.GlassUI then
					TweenService:Create(pillBtn, IOS_TIMING.PressDown, {
						BackgroundTransparency = spec.Destructive and 0.45 or 0.70,
					}):Play()
				else
					TweenService:Create(pillBtn, IOS_TIMING.PressDown, { BackgroundColor3 = pillColor }):Play()
				end
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
