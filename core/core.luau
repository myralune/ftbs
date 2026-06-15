local core = {}

local changeHistoryService = game:GetService("ChangeHistoryService")
local scriptEditorService = game:GetService("ScriptEditorService")
local studioService = game:GetService("StudioService")
local selection = game:GetService("Selection")

local httpService = game:GetService("HttpService")

local build = require(script.Parent.build)
local bake = require(script.Parent.bake)
local srclist = require(script.Parent.srclist)
local codegen = require(script.Parent.codegen)

local status = require(script.Parent.Parent.components.status)

local FTBS_HEADER = "--$ftbs01"

local template = script.Parent.Parent.scripts["template.ftbs"]:Clone()
local cheatsheetSrc = string.match(script.Parent.Parent.scripts.cheatsheet.Source, "%-%-%[===%[%s*(.+)%s*%]===%]")

core.cheatsheetText = cheatsheetSrc or "cheatsheet unavailable"

local plugin: Plugin

local newScriptMenu: PluginMenu
local editScriptMenu: PluginMenu

function core.configurePlugin(i: Plugin)
	plugin = i

	newScriptMenu = plugin:FindFirstChild("scopebeam.ftlseditor.new")
	if not newScriptMenu then
		local menu = plugin:CreatePluginMenu("scopebeam.ftlseditor.new")
		menu.Name = "scopebeam.ftlseditor.new"
		menu.Parent = plugin

		menu:AddNewAction("scopebeam.ftlseditor.new.bscr", "Blank")
		menu:AddSeparator()

		menu:AddNewAction("scopebeam.ftlseditor.template.basic", "Introduction Template")

		local templates = plugin:CreatePluginMenu("scopebeam.ftlseditor.template", "Templates")
		templates:AddNewAction("scopebeam.ftlseditor.template.mapkit", "FE2 Map Kit")
		menu:AddMenu(templates)
		newScriptMenu = menu
	end

	editScriptMenu = plugin:FindFirstChild("scopebeam.ftlseditor.bscr")
	if not editScriptMenu then
		local menu = plugin:CreatePluginMenu("scopebeam.ftlseditor.bscr")
		menu.Name = "scopebeam.ftlseditor.bscr"
		menu.Parent = plugin

		menu:AddNewAction("scopebeam.ftlseditor.bscr.build", "Build")
		menu:AddSeparator()
		menu:AddNewAction("scopebeam.ftlseditor.bscr.duplicate", "Duplicate")
		menu:AddNewAction("scopebeam.ftlseditor.bscr.delete", "Delete")
		menu:AddSeparator()
		menu:AddNewAction("scopebeam.ftlseditor.bscr.editconf", "Edit Configuration Script")
		menu:AddNewAction("scopebeam.ftlseditor.bscr.select", "Show in Explorer")
		menu:AddNewAction("scopebeam.ftlseditor.bscr.export", "Export...")
		editScriptMenu = menu
	end
end

function core.recordRandomWaypoint()
	changeHistoryService:SetWaypoint(httpService:GenerateGUID(false))
end

function core.openScriptDocument(moduleScript: ModuleScript)
	task.spawn(function()
		scriptEditorService:OpenScriptDocumentAsync(moduleScript)
	end)
end

function core.showInExplorer(inst: Instance?)
	if inst then
		selection:Set({ inst })
	end
end

function core.createTemplate()
	local clone = template:Clone()
	clone.Parent = workspace
	selection:Set({clone})
	core.recordRandomWaypoint()

	local success, err = scriptEditorService:OpenScriptDocumentAsync(clone, {
		Temporary = false,
		HighlightRange  = {
			Start = {
				Line = 7,
				Character = 1
			},
			End = {
				Line = 7,
				Character = 0
			}
		}
	})

	srclist.refresh()
end

function core.duplicateScript(entry: srclist.Entry)
	local clone = entry.script:Clone()
	clone.Name = entry.script.Name .. " - Copy"
	clone.Parent = entry.script.Parent
	selection:Set({ clone })
	core.recordRandomWaypoint()
	srclist.refresh()
end

function core.deleteScript(entry: srclist.Entry)
	entry.script:Destroy()
	core.recordRandomWaypoint()
	status.status(`Deleted {entry.objectName}`)
	srclist.refresh()
end

-- Shows the right-click menu for a build script and runs the chosen action.
-- Must be called from a yieldable thread (task.spawn it from UI handlers).
function core.openScriptMenu(entry: srclist.Entry, onExport: ((srclist.Entry) -> ())?)
	local action = editScriptMenu:ShowAsync()
	if not action then
		return
	end

	local id = action.ActionId
	local function is(suffix: string)
		return string.find(id, suffix, 1, true) ~= nil
	end

	if is("bscr.build") then
		core.buildEntry(entry.script, entry.map)
	elseif is("bscr.duplicate") then
		core.duplicateScript(entry)
	elseif is("bscr.delete") then
		core.deleteScript(entry)
	elseif is("bscr.editconf") then
		core.openScriptDocument(entry.script)
	elseif is("bscr.select") then
		core.showInExplorer(entry.script)
	elseif is("bscr.export") then
		if onExport then
			onExport(entry)
		else
			core.exportScript(entry)
		end
	end
end

function core.importScript()
	local ok, files = pcall(function()
		return studioService:PromptImportFilesAsync({ "lua", "luau", "ftbs" })
	end)
	if not ok or files == nil or #files == 0 then
		return
	end

	local parent: Instance = workspace
	local selected = selection:Get()[1]
	if selected and (selected:IsA("Model") or selected:IsA("Folder")) then
		parent = selected
	end

	local imported = {}
	for _, file in files :: { File } do
		local source = file:GetBinaryContents()
		local name = string.gsub(file.Name, "%.luau?$", "")

		if string.sub(source, 1, #FTBS_HEADER) ~= FTBS_HEADER then
			warn(`ftbs: "{file.Name}" is missing the {FTBS_HEADER} header — imported anyway, but it won't be listed as a build script`)
		end

		local moduleScript = Instance.new("ModuleScript")
		moduleScript.Name = name
		moduleScript.Source = source
		moduleScript.Parent = parent
		imported[#imported + 1] = moduleScript
	end

	if #imported > 0 then
		selection:Set(imported)
		core.recordRandomWaypoint()
		status.status(`Imported {#imported} script(s)`)
		srclist.refresh()
	end
end

-- Exports a build script (with its forks) as a Roblox model file.
function core.exportScript(entry: srclist.Entry?)
	local target = entry and entry.script
	if not target then
		local selected = selection:Get()[1]
		if selected and selected:IsA("ModuleScript") and string.sub(selected.Source, 1, #FTBS_HEADER) == FTBS_HEADER then
			target = selected
		end
	end
	if not target then
		status.status("Select a build script to export")
		return warn("ftbs: select a build script (in the list or Explorer) before exporting")
	end

	local previousSelection = selection:Get()
	selection:Set({ target })
	local ok, saved = pcall(function()
		return plugin:PromptSaveSelection(target.Name)
	end)
	selection:Set(previousSelection)

	if ok and saved then
		status.status(`Exported {target.Name}`)
	end
end

local function isBuildScript(inst: Instance?): boolean
	return inst ~= nil
		and inst:IsA("ModuleScript")
		and string.sub(inst.Source, 1, #FTBS_HEADER) == FTBS_HEADER
end

local function resolveTargets(): (ModuleScript?, Instance?)
	local buildScript: ModuleScript?
	local map: Instance?

	for _, inst in selection:Get() do
		if not buildScript and isBuildScript(inst) then
			buildScript = inst
		elseif not map and inst:IsA("Model") then
			map = inst
		end
	end

	if buildScript then
		local root = buildScript
		local ancestor = root.Parent
		while ancestor do
			if isBuildScript(ancestor) then
				root = ancestor :: ModuleScript
			end
			ancestor = ancestor.Parent
		end
		buildScript = root
		map = map or buildScript:FindFirstAncestorWhichIsA("Model") or workspace
	elseif map then
		for _, descendant in map:GetDescendants() do
			if isBuildScript(descendant) then
				buildScript = descendant :: ModuleScript
				break
			end
		end
	end

	return buildScript, map
end

-- Builds one script into its map. Returns true if the build produced timelines.
function core.buildEntry(buildScript: ModuleScript, map: Instance?, configName: string?): boolean
	map = map or buildScript:FindFirstAncestorWhichIsA("Model") or workspace
	local label = configName and `{buildScript.Name} [{configName}]` or buildScript.Name

	core.recordRandomWaypoint()

	local ok, result = pcall(build.fromScript, buildScript, map, configName)
	if not ok then
		core.recordRandomWaypoint()
		status.status(`Build of {label} crashed — see Output`)
		warn(`ftbs: build crashed: {result}`)
		return false
	end

	local timelinesFolder, bakeIssues = bake.apply(map, result)
	core.recordRandomWaypoint()

	local issues = result.issues
	for _, issue in bakeIssues do
		issues[#issues + 1] = issue
	end

	if #issues > 0 then
		warn(`ftbs: build of {map:GetFullName()} reported {#issues} issue(s):`)
		for _, issue in issues do
			warn("  " .. issue)
		end
	end

	if #result.timelines == 0 then
		status.status(`{label}: nothing to bake — no timelines were produced`)
		warn("ftbs: nothing to bake — no timelines were produced")
		return false
	end

	selection:Set({ timelinesFolder })
	local issueNote = #issues > 0 and ` ({#issues} issue(s), see Output)` or ""
	status.status(`Built {#result.timelines} timeline(s) from {label} into {map.Name}.Timelines{issueNote}`)
	print(`ftbs: built {#result.timelines} timeline(s) into {map:GetFullName()}.Timelines`)
	return true
end

-- Selection-based build (toolbar / right-click in Explorer)
function core.buildTimelines(configName: string?)
	local buildScript, map = resolveTargets()
	if not buildScript then
		status.status("Select a build script or map model to build")
		return warn("ftbs: select a build script (or a map Model containing one) before building")
	end
	core.buildEntry(buildScript, map, configName)
end

export type TimelinesCandidate = {
	folder: Instance, -- the Timelines folder
	map: Instance,    -- its parent (map model or a service)
	label: string,
}

-- Finds every Timelines folder in the place that codegen could run on.
function core.findTimelinesCandidates(): { TimelinesCandidate }
	local candidates: { TimelinesCandidate } = {}
	local roots = { workspace, game:GetService("ReplicatedStorage"), game:GetService("ServerStorage") }

	for _, root in roots do
		for _, descendant in root:GetDescendants() do
			if descendant.Name == "Timelines"
				and descendant:FindFirstChildWhichIsA("Configuration", true)
				and descendant:FindFirstAncestor("ftbseditor") == nil
			then
				local map = descendant.Parent :: Instance
				candidates[#candidates + 1] = {
					folder = descendant,
					map = map,
					label = map.Name,
				}
			end
		end
	end

	table.sort(candidates, function(a, b)
		return a.label:lower() < b.label:lower()
	end)
	return candidates
end

local function uniqueChildName(parent: Instance, baseName: string): string
	if not parent:FindFirstChild(baseName) then
		return baseName
	end
	local n = 2
	while parent:FindFirstChild(`{baseName} ({n})`) do
		n += 1
	end
	return `{baseName} ({n})`
end

-- Generates a .ftbs build script (plus fork modules per group folder) from an
-- existing Timelines folder, parents it to the map, and opens it.
function core.generateFromTimelines(candidate: TimelinesCandidate)
	local project = codegen.generateProject(candidate.folder)

	if #project.issues > 0 then
		warn(`ftbs: codegen of {candidate.folder:GetFullName()} reported {#project.issues} issue(s):`)
		for _, issue in project.issues do
			warn("  " .. issue)
		end
	end

	local mainScript = Instance.new("ModuleScript")
	mainScript.Name = uniqueChildName(candidate.map, "GeneratedTimelines.ftbs")
	mainScript.Source = project.main

	local function addForks(parent: Instance, forks)
		for _, fork in forks do
			local forkScript = Instance.new("ModuleScript")
			forkScript.Name = fork.name
			forkScript.Source = fork.source
			forkScript.Parent = parent
			addForks(forkScript, fork.forks)
		end
	end
	addForks(mainScript, project.forks)

	mainScript.Parent = candidate.map
	core.recordRandomWaypoint()

	selection:Set({ mainScript })
	core.openScriptDocument(mainScript)
	srclist.refresh()

	local issueNote = #project.issues > 0 and ` ({#project.issues} issue(s), see Output)` or ""
	status.status(`Generated {mainScript.Name} from {candidate.label}.Timelines{issueNote}`)
	print(`ftbs: generated {mainScript:GetFullName()} from {candidate.folder:GetFullName()}`)
end

-- Builds a list of queue items ({ entry, config }) in order.
function core.buildBatch(items: { { entry: srclist.Entry, config: string } })
	local built = 0
	for _, item in items do
		if core.buildEntry(item.entry.script, item.entry.map, item.config) then
			built += 1
		end
	end
	status.status(`Batch finished: {built}/{#items} build(s) succeeded`)
	return built
end

return core
