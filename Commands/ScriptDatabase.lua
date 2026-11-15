--[[
	Commands/ScriptDatabase.lua
	Manages Universal Scripts & Place-Specific Scripts + Remote JSON Database Fetching
	Prompts an iOS Confirm (X / Checkmark) notification before executing a script.
]]

local HttpService = game:GetService("HttpService")

local ScriptDatabase = {}

ScriptDatabase.DATABASE_URL = ""

ScriptDatabase.Data = {
	Universal = {
		{
			Name = "Infinite Yield Admin",
			Url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
		},
		{
			Name = "Dex Explorer",
			Url = "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua",
		},
		{
			Name = "SimpleSpy V3",
			Url = "https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua",
		},
	},
	Places = {
		-- ["PLACE_ID"] = {
		--     { Name = "Script Name", Url = "https://..." }
		-- }
	},
}

local OnDatabaseChangedCallback = nil

function ScriptDatabase.SetOnChanged(fn)
	OnDatabaseChangedCallback = fn
end

function ScriptDatabase.TriggerRefresh()
	if OnDatabaseChangedCallback then
		OnDatabaseChangedCallback()
	end
end

local function runEntryNow(entry, notifyFn)
	if notifyFn then
		notifyFn({
			Title = entry.Name or "Script Executed",
			Subtitle = "Loading script...",
			Type = "Regular",
			Duration = 2.2,
		})
	end

	task.spawn(function()
		if type(entry.Callback) == "function" then
			pcall(entry.Callback)
		elseif type(entry.Source) == "string" and #entry.Source > 0 then
			pcall(function()
				local fn = loadstring(entry.Source)
				if fn then fn() end
			end)
		elseif type(entry.Url) == "string" and #entry.Url > 0 then
			pcall(function()
				local body = game:HttpGet(entry.Url)
				if type(body) == "string" and #body > 0 then
					local fn = loadstring(body)
					if fn then fn() end
				end
			end)
		end
	end)
end

function ScriptDatabase.ExecuteEntry(entry, notifyFn)
	if not entry then return end
	if notifyFn then
		notifyFn({
			Title = "Confirm action?",
			Subtitle = "Execute " .. (entry.Name or "game script"),
			Type = "Confirm",
			OnConfirm = function()
				runEntryNow(entry, notifyFn)
			end,
			OnCancel = function() end,
		})
	else
		runEntryNow(entry, nil)
	end
end

function ScriptDatabase.LoadFromUrl(url)
	if type(url) ~= "string" or #url == 0 then
		return false
	end
	local ok, decoded = pcall(function()
		local raw = game:HttpGet(url)
		return HttpService:JSONDecode(raw)
	end)
	if ok and type(decoded) == "table" then
		if type(decoded.Universal) == "table" then
			ScriptDatabase.Data.Universal = decoded.Universal
		end
		if type(decoded.Places) == "table" then
			ScriptDatabase.Data.Places = decoded.Places
		end
		ScriptDatabase.TriggerRefresh()
		return true
	end
	return false
end

function ScriptDatabase.AddUniversalScript(name, urlOrCallback)
	local entry = { Name = name }
	if type(urlOrCallback) == "function" then
		entry.Callback = urlOrCallback
	else
		entry.Url = tostring(urlOrCallback)
	end
	table.insert(ScriptDatabase.Data.Universal, entry)
	ScriptDatabase.TriggerRefresh()
end

function ScriptDatabase.AddGameScript(placeId, name, urlOrCallback)
	local key = tostring(placeId)
	ScriptDatabase.Data.Places[key] = ScriptDatabase.Data.Places[key] or {}
	local entry = { Name = name }
	if type(urlOrCallback) == "function" then
		entry.Callback = urlOrCallback
	else
		entry.Url = tostring(urlOrCallback)
	end
	table.insert(ScriptDatabase.Data.Places[key], entry)
	ScriptDatabase.TriggerRefresh()
end

return ScriptDatabase
