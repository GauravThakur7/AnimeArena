--!strict
--[[
	Container.luau
	Lightweight dependency injection container.
	Services/Controllers register themselves, then resolve dependencies at startup.
	
	Usage:
		local container = Container.new()
		container:Register("NetworkManager", NetworkManager.new())
		local nm = container:Resolve("NetworkManager")
]]

local Container = {}
Container.__index = Container

export type Container = typeof(setmetatable(
	{} :: {
		_registry: { [string]: any },
		_initialized: boolean,
	},
	Container
))

function Container.new(): Container
	local self = setmetatable({}, Container) :: any
	self._registry = {}
	self._initialized = false
	return self
end

--[[
	Register a named dependency in the container.
	@param name — Unique string key
	@param instance — The object to store
]]
function Container.Register(self: Container, name: string, instance: any)
	assert(self._registry[name] == nil, `Dependency "{name}" is already registered`)
	self._registry[name] = instance
end

--[[
	Resolve (retrieve) a dependency by name.
	@param name — The key used during Register
	@return The registered instance
]]
function Container.Resolve(self: Container, name: string): any
	local instance = self._registry[name]
	assert(instance ~= nil, `Dependency "{name}" is not registered`)
	return instance
end

--[[
	Check if a dependency is registered.
]]
function Container.Has(self: Container, name: string): boolean
	return self._registry[name] ~= nil
end

--[[
	Get all registered dependency names.
]]
function Container.GetAll(self: Container): { string }
	local names = {}
	for name in self._registry do
		table.insert(names, name)
	end
	return names
end

--[[
	Initialize all registered services/controllers that have an :Init() method.
	Called once during bootstrap.
]]
function Container.InitAll(self: Container)
	assert(not self._initialized, "Container already initialized")
	self._initialized = true

	for name, instance in self._registry do
		if typeof(instance) == "table" and typeof(instance.Init) == "function" then
			instance:Init(self)
		end
	end
end

--[[
	Start all registered services/controllers that have a :Start() method.
	Called after InitAll.
]]
function Container.StartAll(self: Container)
	for _, instance in self._registry do
		if typeof(instance) == "table" and typeof(instance.Start) == "function" then
			task.spawn(instance.Start, instance)
		end
	end
end

return Container
