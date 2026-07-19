--!strict
--[[
	Network.luau
	Abstraction over Roblox RemoteEvents and RemoteFunctions.
	Provides a clean API for registering/firing remotes with built-in validation hooks.
	
	Server usage:
		Network:RegisterEvent("AttackRequest")
		Network:OnEvent("AttackRequest", function(player, data) ... end)
	
	Client usage:
		Network:FireServer("AttackRequest", data)
		Network:OnClientEvent("HitConfirm", function(data) ... end)
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IS_SERVER = RunService:IsServer()

local Network = {}
Network.__index = Network

export type Network = typeof(setmetatable(
	{} :: {
		_remoteFolder: Folder,
		_events: { [string]: RemoteEvent },
		_functions: { [string]: RemoteFunction },
		_unreliableEvents: { [string]: UnreliableRemoteEvent },
	},
	Network
))

function Network.new(): Network
	local self = setmetatable({}, Network) :: any
	self._events = {}
	self._functions = {}
	self._unreliableEvents = {}

	if IS_SERVER then
		local folder = Instance.new("Folder")
		folder.Name = "NetworkRemotes"
		folder.Parent = ReplicatedStorage
		self._remoteFolder = folder
	else
		self._remoteFolder = ReplicatedStorage:WaitForChild("NetworkRemotes") :: Folder
	end

	return self
end

-- ═══════════════════════════════════════════════════
-- SERVER METHODS
-- ═══════════════════════════════════════════════════

--[[
	Register a reliable RemoteEvent. Server only.
]]
function Network.RegisterEvent(self: Network, name: string)
	assert(IS_SERVER, "RegisterEvent can only be called on the server")
	assert(self._events[name] == nil, `Remote event "{name}" already registered`)

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = self._remoteFolder
	self._events[name] = remote
end

--[[
	Register an unreliable RemoteEvent (for position sync, etc). Server only.
]]
function Network.RegisterUnreliableEvent(self: Network, name: string)
	assert(IS_SERVER, "RegisterUnreliableEvent can only be called on the server")
	assert(self._unreliableEvents[name] == nil, `Unreliable remote "{name}" already registered`)

	local remote = Instance.new("UnreliableRemoteEvent")
	remote.Name = name
	remote.Parent = self._remoteFolder
	self._unreliableEvents[name] = remote
end

--[[
	Register a RemoteFunction. Server only.
]]
function Network.RegisterFunction(self: Network, name: string)
	assert(IS_SERVER, "RegisterFunction can only be called on the server")
	assert(self._functions[name] == nil, `Remote function "{name}" already registered`)

	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = self._remoteFolder
	self._functions[name] = remote
end

--[[
	Listen to a RemoteEvent from clients. Server only.
]]
function Network.OnServerEvent(self: Network, name: string, callback: (player: Player, ...any) -> ())
	assert(IS_SERVER, "OnServerEvent can only be called on the server")
	local remote = self:_getEvent(name)
	remote.OnServerEvent:Connect(callback)
end

--[[
	Fire a RemoteEvent to a specific client. Server only.
]]
function Network.FireClient(self: Network, name: string, player: Player, ...: any)
	assert(IS_SERVER, "FireClient can only be called on the server")
	local remote = self:_getEvent(name)
	remote:FireClient(player, ...)
end

--[[
	Fire a RemoteEvent to all clients. Server only.
]]
function Network.FireAllClients(self: Network, name: string, ...: any)
	assert(IS_SERVER, "FireAllClients can only be called on the server")
	local remote = self:_getEvent(name)
	remote:FireAllClients(...)
end

--[[
	Fire an unreliable event to a specific client. Server only.
]]
function Network.FireClientUnreliable(self: Network, name: string, player: Player, ...: any)
	assert(IS_SERVER, "FireClientUnreliable can only be called on the server")
	local remote = self:_getUnreliableEvent(name)
	remote:FireClient(player, ...)
end

--[[
	Set handler for a RemoteFunction invocation. Server only.
]]
function Network.OnServerInvoke(self: Network, name: string, callback: (player: Player, ...any) -> ...any)
	assert(IS_SERVER, "OnServerInvoke can only be called on the server")
	local remote = self:_getFunction(name)
	remote.OnServerInvoke = callback
end

-- ═══════════════════════════════════════════════════
-- CLIENT METHODS
-- ═══════════════════════════════════════════════════

--[[
	Fire a RemoteEvent to the server. Client only.
]]
function Network.FireServer(self: Network, name: string, ...: any)
	assert(not IS_SERVER, "FireServer can only be called on the client")
	local remote = self:_getEvent(name)
	remote:FireServer(...)
end

--[[
	Listen to a RemoteEvent from the server. Client only.
]]
function Network.OnClientEvent(self: Network, name: string, callback: (...any) -> ())
	assert(not IS_SERVER, "OnClientEvent can only be called on the client")
	local remote = self:_getEvent(name)
	remote.OnClientEvent:Connect(callback)
end

--[[
	Listen to an unreliable RemoteEvent from the server. Client only.
]]
function Network.OnClientUnreliableEvent(self: Network, name: string, callback: (...any) -> ())
	assert(not IS_SERVER, "OnClientUnreliableEvent can only be called on the client")
	local remote = self:_getUnreliableEvent(name)
	remote.OnClientEvent:Connect(callback)
end

--[[
	Invoke a RemoteFunction on the server. Client only.
]]
function Network.InvokeServer(self: Network, name: string, ...: any): ...any
	assert(not IS_SERVER, "InvokeServer can only be called on the client")
	local remote = self:_getFunction(name)
	return remote:InvokeServer(...)
end

-- ═══════════════════════════════════════════════════
-- PRIVATE
-- ═══════════════════════════════════════════════════

function Network._getEvent(self: Network, name: string): RemoteEvent
	if self._events[name] then
		return self._events[name]
	end

	-- Client: wait for remote
	if not IS_SERVER then
		local remote = self._remoteFolder:WaitForChild(name, 10)
		assert(remote and remote:IsA("RemoteEvent"), `RemoteEvent "{name}" not found`)
		self._events[name] = remote :: RemoteEvent
		return remote :: RemoteEvent
	end

	error(`RemoteEvent "{name}" not registered`)
end

function Network._getUnreliableEvent(self: Network, name: string): UnreliableRemoteEvent
	if self._unreliableEvents[name] then
		return self._unreliableEvents[name]
	end

	if not IS_SERVER then
		local remote = self._remoteFolder:WaitForChild(name, 10)
		assert(remote and remote:IsA("UnreliableRemoteEvent"), `UnreliableRemoteEvent "{name}" not found`)
		self._unreliableEvents[name] = remote :: UnreliableRemoteEvent
		return remote :: UnreliableRemoteEvent
	end

	error(`UnreliableRemoteEvent "{name}" not registered`)
end

function Network._getFunction(self: Network, name: string): RemoteFunction
	if self._functions[name] then
		return self._functions[name]
	end

	if not IS_SERVER then
		local remote = self._remoteFolder:WaitForChild(name, 10)
		assert(remote and remote:IsA("RemoteFunction"), `RemoteFunction "{name}" not found`)
		self._functions[name] = remote :: RemoteFunction
		return remote :: RemoteFunction
	end

	error(`RemoteFunction "{name}" not registered`)
end

return Network
