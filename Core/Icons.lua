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
