--[[
	Build script discovery
	======================
	Scans the place for root --$ftbs01 ModuleScripts (nested ones are forks of
	their root and are not listed) and exposes them as a vide source for the UI.
]]

local vide = require "../vide"

local FTBS_HEADER = "--$ftbs01"

export type Entry = {
	script: ModuleScript,
	name: string,        -- display name (map name if available, else script name)
	objectName: string,  -- the ModuleScript's name
	map: Instance?,      -- ancestor Model the script bakes into (nil = workspace)
	mapName: string,
	configs: { string }, -- "$default" plus any named configurations
}

local SCAN_ROOTS = { workspace, game:GetService("ReplicatedStorage"), game:GetService("ServerStorage") }

local srclist = {}

srclist.source = vide.source({} :: { Entry })

local function isBuildScript(inst: Instance): boolean
	return inst:IsA("ModuleScript")
		and string.sub(inst.Source, 1, #FTBS_HEADER) == FTBS_HEADER
end

local function isInsidePluginSource(inst: Instance): boolean
	-- Skip the plugin's own template/dev copy when it lives in the place
	return inst:FindFirstAncestor("ftbseditor") ~= nil
end

-- Reads the configuration names off a build script by requiring a throwaway clone
-- (the same thing a build does, so this is no less safe than building).
local function readConfigs(buildScript: ModuleScript): { string }
	local configs = { "$default" }

	local clone = buildScript:Clone()
	clone:ClearAllChildren() -- forks don't carry configurations; no need to run them
	clone.Parent = buildScript.Parent

	local ok, result = pcall(require, clone)
	clone:Destroy()

	if ok and type(result) == "table" and type(result.conf) == "table" then
		local named = {}
		for key in result.conf do
			if type(key) == "string" and key ~= "$default" and string.sub(key, 1, 1) ~= "$" then
				named[#named + 1] = key
			end
		end
		table.sort(named)
		table.move(named, 1, #named, 2, configs)
	end

	return configs
end

local function toEntry(buildScript: ModuleScript): Entry
	local map = buildScript:FindFirstAncestorWhichIsA("Model")
	return {
		script = buildScript,
		name = map and map.Name or buildScript.Name,
		objectName = buildScript.Name,
		map = map,
		mapName = map and map.Name or "Workspace",
		configs = readConfigs(buildScript),
	}
end

function srclist.refresh()
	local found: { ModuleScript } = {}

	for _, root in SCAN_ROOTS do
		for _, descendant in root:QueryDescendants("ModuleScript") do
			if isBuildScript(descendant) and not isInsidePluginSource(descendant) then
				table.insert(found, descendant)
			end
		end
	end

	-- Drop forks: anything nested under another discovered build script
	local entries: { Entry } = {}
	for _, candidate in found do
		local isRoot = true
		for _, other in found do
			if other ~= candidate and candidate:IsDescendantOf(other) then
				isRoot = false
				break
			end
		end
		if isRoot then
			table.insert(entries, toEntry(candidate))
		end
	end

	table.sort(entries, function(a, b)
		return a.name:lower() < b.name:lower()
	end)

	srclist.source(entries)
	return entries
end

return srclist
