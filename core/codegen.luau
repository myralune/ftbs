--!nonstrict
--[[
	Flood Timelines Codegen
	=======================
	Generates .ftbs build script source from a map's existing Timelines folder —
	the inverse of core/bake.luau.

	Layout mapping (mirrors how bake lays things out, so output round-trips):
	  Timelines folder child Configuration        -> create ("timeline", name)
	  Timelines folder child Folder w/ timelines  -> fork ModuleScript (group)
	  timeline child ObjectValue                  -> create ("xframe", name)
	  timeline child Folder/other w/ xframes      -> folder name / container (class, name)
	  xframe child ObjectValue                    -> create ("pointer", name) targeting a timeline by name
]]

local Codegen = {}

local GENERATED_TAG = "FTBS_Generated"

-- The type-stub footer is lifted from the template so generated scripts get the
-- same autocomplete and stay in sync with template changes.
local templateSource = script.Parent.Parent.scripts["template.ftbs"].Source
local FOOTER = string.match(templateSource, "(%-%- disregard all lines below.+)$")
	or "return {build = build, map = map, conf = conf}"

-- ============================================================== value -> source

local function fmtNumber(n: number): string
	if n ~= n then return "0/0" end
	if n == math.huge then return "math.huge" end
	if n == -math.huge then return "-math.huge" end
	if n == math.floor(n) and math.abs(n) < 1e15 then
		return string.format("%d", n)
	end
	return string.format("%.6g", n)
end

local function isIdentifier(key: string): boolean
	return string.match(key, "^[%a_][%w_]*$") ~= nil
end

local function keyToSource(key: string): string
	if isIdentifier(key) then
		return key
	end
	return string.format("[%q]", key)
end

local function color3ToSource(value: Color3): string
	return string.format("Color3.fromRGB(%d, %d, %d)",
		math.round(value.R * 255), math.round(value.G * 255), math.round(value.B * 255))
end

local function valueToSource(value: any, report): string
	local t = typeof(value)
	if t == "string" then
		return string.format("%q", value)
	elseif t == "number" then
		return fmtNumber(value)
	elseif t == "boolean" then
		return tostring(value)
	elseif t == "Color3" then
		return color3ToSource(value)
	elseif t == "Vector3" then
		return string.format("Vector3.new(%s, %s, %s)",
			fmtNumber(value.X), fmtNumber(value.Y), fmtNumber(value.Z))
	elseif t == "Vector2" then
		return string.format("Vector2.new(%s, %s)", fmtNumber(value.X), fmtNumber(value.Y))
	elseif t == "CFrame" then
		local parts = {}
		for _, n in { value:GetComponents() } do
			parts[#parts + 1] = fmtNumber(n)
		end
		return "CFrame.new(" .. table.concat(parts, ", ") .. ")"
	elseif t == "UDim" then
		return string.format("UDim.new(%s, %s)", fmtNumber(value.Scale), fmtNumber(value.Offset))
	elseif t == "UDim2" then
		return string.format("UDim2.new(%s, %s, %s, %s)",
			fmtNumber(value.X.Scale), fmtNumber(value.X.Offset),
			fmtNumber(value.Y.Scale), fmtNumber(value.Y.Offset))
	elseif t == "NumberRange" then
		return string.format("NumberRange.new(%s, %s)", fmtNumber(value.Min), fmtNumber(value.Max))
	elseif t == "BrickColor" then
		return string.format("BrickColor.new(%q)", value.Name)
	elseif t == "Rect" then
		return string.format("Rect.new(%s, %s, %s, %s)",
			fmtNumber(value.Min.X), fmtNumber(value.Min.Y),
			fmtNumber(value.Max.X), fmtNumber(value.Max.Y))
	elseif t == "EnumItem" then
		return tostring(value)
	elseif t == "NumberSequence" then
		local kps = {}
		for _, kp in value.Keypoints do
			kps[#kps + 1] = string.format("NumberSequenceKeypoint.new(%s, %s, %s)",
				fmtNumber(kp.Time), fmtNumber(kp.Value), fmtNumber(kp.Envelope))
		end
		return "NumberSequence.new({ " .. table.concat(kps, ", ") .. " })"
	elseif t == "ColorSequence" then
		local kps = {}
		for _, kp in value.Keypoints do
			kps[#kps + 1] = string.format("ColorSequenceKeypoint.new(%s, %s)",
				fmtNumber(kp.Time), color3ToSource(kp.Value))
		end
		return "ColorSequence.new({ " .. table.concat(kps, ", ") .. " })"
	elseif t == "Font" then
		return string.format("Font.new(%q, Enum.FontWeight.%s, Enum.FontStyle.%s)",
			value.Family, value.Weight.Name, value.Style.Name)
	end
	report(`unsupported value type "{t}" — emitted as nil`)
	return `nil --[[ unsupported {t} ]]`
end

-- Path expression like map.Interactives.Door, relative to the map
local function instanceToSource(instance: Instance?, map: Instance, report): string
	if instance == nil then
		return "nil"
	end
	if instance == map then
		return "map"
	end
	local segments = {}
	local current: Instance? = instance
	while current and current ~= map do
		local name = current.Name
		if isIdentifier(name) then
			table.insert(segments, 1, "." .. name)
		else
			table.insert(segments, 1, string.format("[%q]", name))
		end
		current = current.Parent
	end
	if current ~= map then
		report(`{instance:GetFullName()} is not inside the map — emitted as nil`)
		return `nil --[[ {instance:GetFullName()} ]]`
	end
	return "map" .. table.concat(segments)
end

-- ============================================================== source writer

local function newWriter()
	local lines = {}
	local indent = 0
	local writer = {}
	function writer.push() indent += 1 end
	function writer.pop() indent -= 1 end
	function writer.line(text: string)
		lines[#lines + 1] = if text == "" then "" else string.rep("\t", indent) .. text
	end
	function writer.result(): string return table.concat(lines, "\n") end
	return writer
end

-- ============================================================== classification

local function isTimeline(inst: Instance): boolean
	return inst:IsA("Configuration")
end

local function isXFrame(inst: Instance): boolean
	return inst:IsA("ObjectValue")
end

local function containsTimeline(inst: Instance): boolean
	for _, descendant in inst:GetDescendants() do
		if isTimeline(descendant) then
			return true
		end
	end
	return false
end

local function containsXFrame(inst: Instance): boolean
	for _, descendant in inst:GetDescendants() do
		if isXFrame(descendant) then
			return true
		end
	end
	return false
end

-- ============================================================== emitters

-- attributes = { ... }, inline when short
local function emitAttributes(writer, inst: Instance, report)
	local keys = {}
	local attrs = inst:GetAttributes()
	attrs[GENERATED_TAG] = nil
	for key in attrs do
		keys[#keys + 1] = key
	end
	if #keys == 0 then
		return
	end
	table.sort(keys)

	if #keys <= 2 then
		local parts = {}
		for _, key in keys do
			parts[#parts + 1] = `{keyToSource(key)} = {valueToSource(attrs[key], report)}`
		end
		writer.line("attributes = { " .. table.concat(parts, ", ") .. " },")
	else
		writer.line("attributes = {")
		writer.push()
		for _, key in keys do
			writer.line(`{keyToSource(key)} = {valueToSource(attrs[key], report)},`)
		end
		writer.pop()
		writer.line("},")
	end
end

local function emitPointer(writer, pointer: ObjectValue, report)
	writer.line(`create ("pointer", {string.format("%q", pointer.Name)}) \{`)
	writer.push()
	local target = pointer.Value
	if target == nil then
		report(`pointer "{pointer:GetFullName()}" has no target — emitted as nil`)
		writer.line("target = nil,")
	else
		writer.line(`target = {string.format("%q", target.Name)},`)
	end
	writer.pop()
	writer.line("},")
end

local function emitXFrame(writer, xframe: ObjectValue, map: Instance, report)
	writer.line(`create ("xframe", {string.format("%q", xframe.Name)}) \{`)
	writer.push()

	emitAttributes(writer, xframe, report)

	if xframe.Value ~= nil then
		writer.line(`target = {instanceToSource(xframe.Value, map, report)},`)
	end

	for _, child in xframe:GetChildren() do
		if child:IsA("ObjectValue") then
			writer.line("")
			emitPointer(writer, child, report)
		else
			report(`skipped {child:GetFullName()} ({child.ClassName}) — xframes can only hold pointers`)
		end
	end

	writer.pop()
	writer.line("},")
end

-- Children of a timeline (or of a cosmetic container inside one)
local function emitTimelineChildren(writer, parent: Instance, map: Instance, report)
	for _, child in parent:GetChildren() do
		if isXFrame(child) then
			emitXFrame(writer, child, map, report)
		elseif containsXFrame(child) then
			if child.ClassName == "Folder" then
				writer.line(`folder {string.format("%q", child.Name)} \{`)
			else
				writer.line(`container ({string.format("%q", child.ClassName)}, {string.format("%q", child.Name)}) \{`)
			end
			writer.push()
			emitAttributes(writer, child, report)
			emitTimelineChildren(writer, child, map, report)
			writer.pop()
			writer.line("},")
		else
			report(`skipped {child:GetFullName()} ({child.ClassName}) — not an xframe or container of xframes`)
		end
	end
end

local function emitTimeline(writer, timeline: Configuration, map: Instance, report)
	writer.line(`create ("timeline", {string.format("%q", timeline.Name)}) \{`)
	writer.push()
	emitAttributes(writer, timeline, report)

	if #timeline:GetChildren() > 0 then
		writer.line("")
	end
	emitTimelineChildren(writer, timeline, map, report)

	writer.pop()
	writer.line("}")
	writer.line("")
end

-- ============================================================== module assembly

local function writeHeader(writer, originName: string, isFork: boolean)
	writer.line("--$ftbs01")
	writer.line("")
	writer.line(`-- Generated by the Flood Timelines Build System from {originName}`)
	writer.line("-- Review the output and back up the original Timelines folder before rebuilding.")
	if isFork then
		writer.line("-- This fork mirrors a timeline group folder; its baked timelines are grouped")
		writer.line("-- under a folder path matching this module's location beneath the main script.")
	else
		writer.line("-- Note: configurations cannot be recovered from baked timelines, so `conf` is empty.")
	end
	writer.line("")
	writer.line('local map = script:FindFirstAncestorWhichIsA("Model") or workspace')
	writer.line("local conf")
	writer.line("")
	writer.line("function build(create: create, macro: macro, folder: folder, container: container, config: {[string]: any})")
	writer.push()
end

local function writeFooter(writer)
	writer.pop()
	writer.line("end")
	writer.line("")
	for line in string.gmatch(FOOTER, "([^\n]*)\n?") do
		writer.line(line)
	end
end

export type GeneratedModule = {
	name: string,
	source: string,
	forks: { GeneratedModule },
}

export type GeneratedProject = {
	main: string,
	forks: { GeneratedModule },
	issues: { string },
}

-- Emits every timeline directly inside `container` into one module body, and
-- returns fork descriptors for nested group folders.
local function generateModuleBody(writer, container: Instance, map: Instance, originName: string, report): ({ Instance }, number)
	local groupFolders = {}
	local emitted = 0

	for _, child in container:GetChildren() do
		if isTimeline(child) then
			emitTimeline(writer, child, map, report)
			emitted += 1
		elseif isXFrame(child) then
			report(`skipped stray xframe {child:GetFullName()} (xframes belong inside a timeline)`)
		elseif containsTimeline(child) then
			groupFolders[#groupFolders + 1] = child
		else
			report(`skipped {child:GetFullName()} ({child.ClassName})`)
		end
	end

	if emitted == 0 then
		writer.line("-- (no timelines at this level)")
	end

	return groupFolders, emitted
end

local function generateModule(container: Instance, map: Instance, originName: string, isFork: boolean, report): (string, { GeneratedModule })
	local writer = newWriter()
	writeHeader(writer, originName, isFork)
	local groupFolders = generateModuleBody(writer, container, map, originName, report)
	writeFooter(writer)

	local forks = {}
	for _, groupFolder in groupFolders do
		local source, nested = generateModule(groupFolder, map, originName, true, report)
		forks[#forks + 1] = {
			name = groupFolder.Name, -- exact folder name, so the baked group path round-trips
			source = source,
			forks = nested,
		}
	end

	return writer.result(), forks
end

function Codegen.generateProject(timelinesFolder: Instance): GeneratedProject
	local map = timelinesFolder.Parent or timelinesFolder
	local issues = {}
	local function report(message: string)
		issues[#issues + 1] = `[FTBS Codegen] {message}`
	end

	local originName = `{map.Name}.{timelinesFolder.Name}`
	local main, forks = generateModule(timelinesFolder, map, originName, false, report)

	return {
		main = main,
		forks = forks,
		issues = issues,
	}
end

return Codegen
