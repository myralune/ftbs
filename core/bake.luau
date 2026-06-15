--!nonstrict
--[[
	Flood Timelines Baker
	================
	Turns a Builder.BuildResult into the Configuration / ObjectValue instances
	the Timelines engine reads.
	
	Keeps timelines/xframes not generated with this tool untouched
]]

local Bake = {}

local GENERATED_TAG = "FTBS_Generated"

-- Gets (or creates) a child of parent with the given name and class
local function ensureChild(parent: Instance, className: string, name: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end

	local created
	local ok = pcall(function()
		created = Instance.new(className)
	end)
	if not ok or not created then
		created = Instance.new("Folder") -- fall back if the class name was bad
	end
	created.Name = name
	created.Parent = parent
	created:SetAttribute(GENERATED_TAG, true)
	return created
end

local function resolveFolder(timeline: Instance, folderPath): Instance
	local parent: Instance = timeline
	for _, ref in folderPath do
		parent = ensureChild(parent, ref.className or "Folder", ref.name)
	end
	return parent
end

-- Fork group nesting under the Timelines folder
local function resolveGroupFolder(timelinesFolder: Instance, group): Instance
	local parent: Instance = timelinesFolder
	for _, name in group or {} do
		parent = ensureChild(parent, "Folder", name)
	end
	return parent
end

local function applyAttributes(instance: Instance, attributes, report)
	if type(attributes) ~= "table" then return end
	for key, value in attributes do
		if value == nil then continue end
		local ok = pcall(function()
			instance:SetAttribute(key, value)
		end)
		if not ok then
			report(`could not set attribute "{key}" on {instance:GetFullName()} (value type "{typeof(value)}")`)
		end
	end
end

local function resetAttributes(instance: Instance)
	for key in instance:GetAttributes() do
		if key ~= GENERATED_TAG then
			instance:SetAttribute(key, nil)
		end
	end
end

-- Removes generated instances depth-first
local function clearGenerated(instance: Instance): boolean
	local keptSomething = false
	for _, child in instance:GetChildren() do
		if not clearGenerated(child) then
			keptSomething = true
		end
	end

	if instance:GetAttribute(GENERATED_TAG) and not keptSomething then
		instance:Destroy()
		return true
	end
	return false
end

-- Applies a BuildResult to map
function Bake.apply(map: Instance, buildResult): (Instance, { string })
	local issues = {}
	local function report(message: string)
		issues[#issues + 1] = `[FTBS Bake] {message}`
	end

	local timelinesFolder = map:FindFirstChild("Timelines")
	if not timelinesFolder then
		timelinesFolder = Instance.new("Folder")
		timelinesFolder.Name = "Timelines"
		timelinesFolder.Parent = map
	end

	-- Remove previous generated output
	for _, child in timelinesFolder:GetChildren() do
		clearGenerated(child)
	end

	-- create every timeline Configuration
	local configByName = {}
	for _, timeline in buildResult.timelines do
		local groupFolder = resolveGroupFolder(timelinesFolder, timeline.group)

		local config = groupFolder:FindFirstChild(timeline.name)
		if config and not config:IsA("Configuration") then
			report(`"{timeline.name}" already exists as a {config.ClassName}, not a Configuration — created a separate one`)
			config = nil
		end
		if not config then
			config = Instance.new("Configuration")
			config.Name = timeline.name
			config.Parent = groupFolder
		end

		config:SetAttribute(GENERATED_TAG, true)
		resetAttributes(config)
		applyAttributes(config, timeline.attributes, report)

		if configByName[timeline.name] then
			report(`duplicate timeline "{timeline.name}" — later one overwrites references`)
		end
		configByName[timeline.name] = config
	end

	-- xframes and their pointers
	for _, timeline in buildResult.timelines do
		local config = configByName[timeline.name]
		for _, xframe in timeline.xframes do
			local folder = resolveFolder(config, xframe.folderPath)

			local objectValue = Instance.new("ObjectValue")
			objectValue.Name = xframe.name
			objectValue:SetAttribute(GENERATED_TAG, true)
			if xframe.target ~= nil then
				local ok = pcall(function()
					objectValue.Value = xframe.target
				end)
				if not ok then
					report(`xframe "{xframe.name}" target is not an Instance (type "{typeof(xframe.target)}")`)
				end
			end
			applyAttributes(objectValue, xframe.attributes, report)
			objectValue.Parent = folder

			for _, pointer in xframe.pointers do
				if pointer.ref == nil then continue end
				local target = configByName[pointer.ref]
				if not target then
					report(`pointer "{pointer.name}" on "{xframe.name}" points to missing timeline "{pointer.ref}"`)
				else
					local link = Instance.new("ObjectValue")
					link.Name = pointer.name
					link:SetAttribute(GENERATED_TAG, true)
					link.Value = target
					link.Parent = objectValue
				end
			end
		end
	end

	return timelinesFolder, issues
end

return Bake
