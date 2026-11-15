--[[
	SurfaceScript/loader.lua
	GitHub Modular Loader for Roblox Executors
	Fetches the Core/, Commands/, and UI/ modules from your GitHub repository,
	builds the folder hierarchy, and launches SurfaceScript.
]]

-- Replace with your GitHub raw base URL once uploaded (keep the trailing slash):
local GITHUB_RAW_BASE = _G.SURFACE_GITHUB_RAW or "https://raw.githubusercontent.com/YOUR_USERNAME/SurfaceScript/main/"

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
	-- 1. Try local executor workspace folder first if present
	local okLocal, localContent = pcall(function()
		if type(isfile) == "function" and type(readfile) == "function" then
			if isfile("SurfaceScript/" .. relativePath) then
				return readfile("SurfaceScript/" .. relativePath)
			end
		end
		return nil
	end)
	if okLocal and type(localContent) == "string" and #localContent > 0 then
		return localContent
	end

	-- 2. Fetch from GitHub Raw URL
	local url = GITHUB_RAW_BASE .. relativePath
	return game:HttpGet(url)
end

-- Build virtual script hierarchy and custom require cache for executors
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
		local chunk, err = loadstring(ModuleSources[target], "@" .. target:GetFullName())
		if not chunk then
			error(err)
		end
		local env = setmetatable({
			script = target,
			require = customRequire,
		}, { __index = getfenv(0) })
		setfenv(chunk, env)
		local res = chunk()
		ModuleCache[target] = res
		return res
	end
	return realRequire(target)
end

local initSource = fetchFile("init.client.lua")
local mainChunk, mainErr = loadstring(initSource, "@SurfaceScript/init.client.lua")
if not mainChunk then
	error(mainErr)
end

local mainEnv = setmetatable({
	script = VirtualRoot,
	require = customRequire,
}, { __index = getfenv(0) })
setfenv(mainChunk, mainEnv)
mainChunk()
