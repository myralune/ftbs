local vide = require "./vide"
vide.strict = true

local connect = require "./connect"
local core = require "./core/core"

local mount = vide.mount
local step = vide.step

local root

step(0)
connect(game:GetService("RunService").Heartbeat:Connect(function(dt)
	debug.profilebegin("ftlseditor/vide")
	task.defer(step, dt)
	debug.profileend()
end))

plugin.Unloading:Connect(function()
	connect(nil, true)
	if root then
		root()
	end
end)

local mainWindow = plugin:CreateDockWidgetPluginGuiAsync("scopebeam.ftlseditor.window", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Bottom,
	true,
	false,
	600,
	200,
	538,
	100
))

mainWindow.Title = "Flood Timelines Build System"
mainWindow.Name = "ftlseditor"
mainWindow.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

root = mount(function()
	return require("./components/app")(plugin, mainWindow)
end, mainWindow)

local toolbar = plugin:CreateToolbar("FTLS Build System")

local action_wcreate = toolbar:CreateButton("scopebeam.ftlseditor.open", "Open the FTLS build system widget", "rbxassetid://14921831705", "FTBS")
action_wcreate.ClickableWhenViewportHidden = true
connect(action_wcreate.Click:Connect(function()
	mainWindow.Enabled = not mainWindow.Enabled
end))

core.configurePlugin(plugin)