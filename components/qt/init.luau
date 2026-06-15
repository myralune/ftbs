-- qt-roblox

local qt = {}

local vide = require "@self/extern/vide"

function qt:Base()                return require "@self/base" end
function qt:Button()              return require "@self/button" end
function qt:HorizontalScrollBox() return require "@self/hscroll" end
function qt:VerticalScrollBox()   return require "@self/vscroll" end
function qt:OmniScrollBox()       return require "@self/hvscroll" end
function qt:Padding()             return require "@self/padding" end
function qt:ScrollBar()           return require "@self/scrollbar" end
function qt:Table()               return require "@self/table" end
function qt:Text()                return require "@self/text" end
function qt:Color()               return require "@self/theme" end

function qt:Plugin(plugin: Plugin)
	
end

function qt:PluginMenu()
	
end

function qt:PluginAction()
	
end

function qt:PluginSeparator()
	
end

function qt:Widget()
	
end

function qt:Toolbar()
	
end

function qt:ToolbarButton()
	
end

function qt:ShowPluginMenuAsync()
	
end

return qt