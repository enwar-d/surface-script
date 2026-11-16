--[[
	Core/Notifications.lua
	iOS Top Pill Notification System (Swipe-to-Dismiss, Full Pill Color Fill, No Outline)
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(script.Parent:WaitForChild("Config"))
local Theme = require(script.Parent:WaitForChild("Theme"))
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
	bgFrame.Size = UISettings.GlassUI and UDim2.new(1, -2, 1, -2) or UDim2.fromScale(1, 1)
	bgFrame.Position = UISettings.GlassUI and UDim2.fromOffset(1, 1) or UDim2.fromOffset(0, 0)
	bgFrame.BackgroundColor3 = COLORS.White
	bgFrame.BackgroundTransparency = UISettings.GlassUI and 0.12 or 0
	bgFrame.BorderSizePixel = 0
	bgFrame.ZIndex = 1
	bgFrame.Parent = pillCanvas

	if UISettings.GlassUI then
		Theme.RegisterSurface(bgFrame, UDim.new(1, 0), "Notification")
	else
		local bgGradient = Instance.new("UIGradient")
		bgGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, COLORS.NotifTop),
			ColorSequenceKeypoint.new(1, COLORS.NotifBottom),
		})
		bgGradient.Rotation = 90
		bgGradient.Parent = bgFrame
	end

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
	Instance.new("UICorner", fillOverlay).CornerRadius = UDim.new(1, 0)

	if UISettings.GlassUI then
		local fillGrad = Instance.new("UIGradient", fillOverlay)
		fillGrad.Rotation = 90
		fillGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(215, 225, 245)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(165, 180, 210)),
		})
		fillGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(0.5, 0.25),
			NumberSequenceKeypoint.new(1, 0.08),
		})
	end

	local checkBtn = Instance.new("TextButton")
	checkBtn.Name = "CheckButton"
	checkBtn.Size = UDim2.new(0, checkBtnWidth, 1, 0)
	checkBtn.Position = UDim2.new(1, -checkBtnWidth, 0, 0)
	checkBtn.BackgroundColor3 = UISettings.GlassUI and Color3.fromRGB(165, 185, 220) or COLORS.CheckGray
	checkBtn.BackgroundTransparency = UISettings.GlassUI and 0.72 or 0
	checkBtn.BorderSizePixel = 0
	checkBtn.Text = ""
	checkBtn.AutoButtonColor = false
	checkBtn.ZIndex = 5
	checkBtn.Parent = pillCanvas

	local checkDiv = nil
	if UISettings.GlassUI then
		checkDiv = Instance.new("Frame", checkBtn)
		checkDiv.Size = UDim2.new(0, 1, 1, -12)
		checkDiv.Position = UDim2.new(0, 0, 0, 6)
		checkDiv.BackgroundColor3 = COLORS.White
		checkDiv.BackgroundTransparency = 0.82
		checkDiv.BorderSizePixel = 0
		checkDiv.ZIndex = 6
	end

	local checkIconHolder = Instance.new("Frame")
	checkIconHolder.Name = "CheckIconHolder"
	checkIconHolder.Size = UDim2.new(0, checkBtnWidth, 1, 0)
	checkIconHolder.Position = UDim2.new(1, -checkBtnWidth, 0, 0)
	checkIconHolder.BackgroundTransparency = 1
	checkIconHolder.ZIndex = 12
	checkIconHolder.Parent = pillCanvas
	local checkIcon = Icons.CreateCircleIcon(checkIconHolder, "Check", 12, 23)

	local cancelBtn, cancelIconHolder, cancelIcon, cancelDiv
	if notifType == "Confirm" then
		cancelBtn = Instance.new("TextButton")
		cancelBtn.Name = "CancelButton"
		cancelBtn.Size = UDim2.new(0, cancelBtnWidth, 1, 0)
		cancelBtn.Position = UDim2.new(1, -(checkBtnWidth + cancelBtnWidth), 0, 0)
		cancelBtn.BackgroundColor3 = COLORS.CancelRed
		cancelBtn.BackgroundTransparency = UISettings.GlassUI and 0.42 or 0
		cancelBtn.BorderSizePixel = 0
		cancelBtn.Text = ""
		cancelBtn.AutoButtonColor = false
		cancelBtn.ZIndex = 5
		cancelBtn.Parent = pillCanvas

		if UISettings.GlassUI then
			cancelDiv = Instance.new("Frame", cancelBtn)
			cancelDiv.Size = UDim2.new(0, 1, 1, -12)
			cancelDiv.Position = UDim2.new(0, 0, 0, 6)
			cancelDiv.BackgroundColor3 = COLORS.White
			cancelDiv.BackgroundTransparency = 0.82
			cancelDiv.BorderSizePixel = 0
			cancelDiv.ZIndex = 6
		end

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

		-- Immediately clear the button backgrounds so they never bleed through the expanding fill
		if checkBtn then checkBtn.BackgroundTransparency = 1 end
		if cancelBtn then cancelBtn.BackgroundTransparency = 1 end
		if checkDiv then checkDiv.Visible = false end
		if cancelDiv then cancelDiv.Visible = false end

		fillOverlay.BackgroundColor3 = fillColor
		fillOverlay.BackgroundTransparency = UISettings.GlassUI and 0.08 or 0
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
			if UISettings.GlassUI then
				TweenService:Create(checkBtn, IOS_TIMING.PressDown, { BackgroundTransparency = 0.56 }):Play()
			else
				TweenService:Create(checkBtn, IOS_TIMING.PressDown, { BackgroundColor3 = COLORS.CheckGrayHover }):Play()
			end
		end
	end)
	checkBtn.MouseLeave:Connect(function()
		if not notifObj.Dismissing then
			if UISettings.GlassUI then
				TweenService:Create(checkBtn, IOS_TIMING.PressDown, { BackgroundTransparency = 0.72 }):Play()
			else
				TweenService:Create(checkBtn, IOS_TIMING.PressDown, { BackgroundColor3 = COLORS.CheckGray }):Play()
			end
		end
	end)
	checkBtn.Activated:Connect(function()
		if notifObj.Dragging then return end
		local fillCol = UISettings.GlassUI and Color3.fromRGB(145, 170, 215) or COLORS.CheckGray
		triggerButtonFillAndDismiss(checkBtn, fillCol, cancelIcon, options.OnConfirm)
	end)

	if cancelBtn then
		cancelBtn.MouseEnter:Connect(function()
			if not notifObj.Dismissing then
				if UISettings.GlassUI then
					TweenService:Create(cancelBtn, IOS_TIMING.PressDown, { BackgroundTransparency = 0.25 }):Play()
				else
					TweenService:Create(cancelBtn, IOS_TIMING.PressDown, { BackgroundColor3 = COLORS.CancelRedHover }):Play()
				end
			end
		end)
		cancelBtn.MouseLeave:Connect(function()
			if not notifObj.Dismissing then
				if UISettings.GlassUI then
					TweenService:Create(cancelBtn, IOS_TIMING.PressDown, { BackgroundTransparency = 0.42 }):Play()
				else
					TweenService:Create(cancelBtn, IOS_TIMING.PressDown, { BackgroundColor3 = COLORS.CancelRed }):Play()
				end
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
