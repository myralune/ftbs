--[[
	Build queue
	===========
	Holds (build script, configuration) pairs waiting to be built together.
]]

local vide = require "../vide"

local srclist = require "./srclist"

export type Item = {
	id: number,
	entry: srclist.Entry,
	config: string,
	selected: vide.source<boolean>,
}

local queue = {}

local nextId = 0

queue.source = vide.source({} :: { Item })

local function items(): { Item }
	return queue.source()
end

function queue.add(entry: srclist.Entry, config: string)
	-- The same script+config pair only queues once
	for _, item in items() do
		if item.entry.script == entry.script and item.config == config then
			return
		end
	end

	nextId += 1
	local list = table.clone(items())
	list[#list + 1] = {
		id = nextId,
		entry = entry,
		config = config,
		selected = vide.source(true),
	}
	queue.source(list)
end

function queue.remove(item: Item)
	local list = {}
	for _, existing in items() do
		if existing.id ~= item.id then
			list[#list + 1] = existing
		end
	end
	queue.source(list)
end

function queue.clear()
	queue.source({})
end

function queue.selectAll(selected: boolean)
	for _, item in items() do
		item.selected(selected)
	end
end

function queue.selectedItems(): { Item }
	local out = {}
	for _, item in items() do
		if item.selected() then
			out[#out + 1] = item
		end
	end
	return out
end

function queue.count(): number
	return #items()
end

return queue
