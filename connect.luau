local connections = {}

local list = {}
local isShutdown = false

return function(rbxconn: RBXScriptConnection, isShuttingDown: boolean?)
	if isShutdown then
		return
	end
	
	if isShuttingDown then
		isShutdown = true
		for conn in list do
			conn:Disconnect()
		end
		return
	end
	
	list[rbxconn] = true
end