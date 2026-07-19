--!strict
--[[
	Signal.luau
	Lightweight event/signal system. Replaces Roblox BindableEvents for in-code communication.
	Usage:
		local signal = Signal.new()
		local connection = signal:Connect(function(data) print(data) end)
		signal:Fire("hello")
		connection:Disconnect()
]]

export type Connection = {
	Disconnect: (self: Connection) -> (),
	Connected: boolean,
}

export type Signal<T...> = {
	Fire: (self: Signal<T...>, T...) -> (),
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Wait: (self: Signal<T...>) -> T...,
	DisconnectAll: (self: Signal<T...>) -> (),
	Destroy: (self: Signal<T...>) -> (),
}

local Signal = {}
Signal.__index = Signal

type CallbackEntry = {
	callback: (...any) -> (),
	connected: boolean,
}

function Signal.new(): Signal<...any>
	local self = setmetatable({}, Signal)
	self._listeners = {} :: { CallbackEntry }
	self._destroyed = false
	return self :: any
end

function Signal:Fire(...: any)
	if self._destroyed then
		return
	end

	for _, entry in self._listeners do
		if entry.connected then
			task.spawn(entry.callback, ...)
		end
	end
end

function Signal:Connect(callback: (...any) -> ()): Connection
	assert(not self._destroyed, "Cannot connect to destroyed signal")

	local entry: CallbackEntry = {
		callback = callback,
		connected = true,
	}
	table.insert(self._listeners, entry)

	local connection = {
		Connected = true,
		Disconnect = function(conn: any)
			if not entry.connected then
				return
			end
			entry.connected = false
			conn.Connected = false

			local index = table.find(self._listeners, entry)
			if index then
				table.remove(self._listeners, index)
			end
		end,
	}

	return connection :: any
end

function Signal:Once(callback: (...any) -> ()): Connection
	local connection: Connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)
	return connection
end

function Signal:Wait(): ...any
	local thread = coroutine.running()
	local connection: Connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	for _, entry in self._listeners do
		entry.connected = false
	end
	table.clear(self._listeners)
end

function Signal:Destroy()
	self:DisconnectAll()
	self._destroyed = true
end

return Signal
