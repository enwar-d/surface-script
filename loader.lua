--[[
	loader.lua
	Lightweight Modular Loader for Surface Script (Core/, Commands/, UI/, init.client.lua)
	Loads modules from your GitHub repository folders or your Executor's workspace/ folder.
]]

-- 1. Set this to your GitHub repository's raw URL after uploading this folder to a Public repo:
--    Example: "https://raw.githubusercontent.com/YourGitHubName/Surface-Scripts/main/"
local GITHUB_RAW_BASE = _G.SURFACE_GITHUB_RAW or "https://raw.githubusercontent.com/enwar-d/surface-script/refs/heads/main/"

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

local function fetchFile(relativePath)
	-- Option A: Load directly from local folders if placed in the Executor's workspace/ folder
	local okLocal, localContent = pcall(function()
		if type(isfile) == "function" and type(readfile) == "function" then
			local localPaths = {
				"Surface Scripts/" .. relativePath,
				"SurfaceScript/" .. relativePath,
				relativePath,
			}
			for _, p in ipairs(localPaths) do
				if isfile(p) then
					return readfile(p)
				end
			end
		end
		return nil
	end)
	if okLocal and type(localContent) == "string" and #localContent > 0 then
		return localContent
	end

	-- Option B: Load from GitHub repository folders
	if string.find(GITHUB_RAW_BASE, "YOUR_USERNAME", 1, true) then
		error(
			"[SurfaceScript Loader] Please set GITHUB_RAW_BASE in loader.lua to your GitHub raw URL, "
			.. "or place the 'Surface Scripts' folder inside your executor's workspace/ folder!"
		)
	end

	local base = GITHUB_RAW_BASE
	if string.sub(base, -1) ~= "/" then
		base = base .. "/"
	end

	local candidateUrls = {
		base .. relativePath,
		base .. "Surface%20Scripts/" .. relativePath,
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

	error("[SurfaceScript Loader] Failed to fetch '" .. relativePath .. "' from: " .. base .. relativePath)
end

-- Build the folder & ModuleScript hierarchy dynamically from the fetched folder files
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
