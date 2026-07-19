--!strict
--[[
	ObjectPool.luau
	Generic object pool for reusing instances (VFX, hitboxes, damage numbers, etc.)
	Prevents garbage collection pressure from frequent create/destroy cycles.
	
	Usage:
		local pool = ObjectPool.new(function() return Instance.new("Part") end, 20)
		local part = pool:Get()
		-- use part
		pool:Return(part)
]]

local ObjectPool = {}
ObjectPool.__index = ObjectPool

export type ObjectPool<T> = typeof(setmetatable(
	{} :: {
		_factory: () -> T,
		_pool: { T },
		_active: { [T]: boolean },
		_maxSize: number,
		_onGet: ((T) -> ())?,
		_onReturn: ((T) -> ())?,
	},
	ObjectPool
))

function ObjectPool.new<T>(factory: () -> T, initialSize: number, maxSize: number?): ObjectPool<T>
	local self = setmetatable({}, ObjectPool) :: any
	self._factory = factory
	self._pool = {}
	self._active = {}
	self._maxSize = maxSize or initialSize * 2
	self._onGet = nil
	self._onReturn = nil

	-- Pre-allocate
	for _ = 1, initialSize do
		local obj = factory()
		table.insert(self._pool, obj)
	end

	return self
end

--- Set a callback to run when an object is retrieved from the pool.
function ObjectPool.SetOnGet(self: ObjectPool<any>, callback: (any) -> ())
	self._onGet = callback
end

--- Set a callback to run when an object is returned to the pool.
function ObjectPool.SetOnReturn(self: ObjectPool<any>, callback: (any) -> ())
	self._onReturn = callback
end

--- Get an object from the pool. Creates a new one if pool is empty.
function ObjectPool.Get(self: ObjectPool<any>): any
	local obj: any
	if #self._pool > 0 then
		obj = table.remove(self._pool, #self._pool)
	else
		obj = self._factory()
	end

	self._active[obj] = true

	if self._onGet then
		self._onGet(obj)
	end

	return obj
end

--- Return an object to the pool for reuse.
function ObjectPool.Return(self: ObjectPool<any>, obj: any)
	if not self._active[obj] then
		return -- Already returned or not from this pool
	end

	self._active[obj] = nil

	if self._onReturn then
		self._onReturn(obj)
	end

	if #self._pool < self._maxSize then
		table.insert(self._pool, obj)
	else
		-- Pool is full, discard (let GC handle it)
		if typeof(obj) == "Instance" then
			(obj :: Instance):Destroy()
		end
	end
end

--- Get the number of available objects in the pool.
function ObjectPool.Available(self: ObjectPool<any>): number
	return #self._pool
end

--- Get the number of currently active (checked out) objects.
function ObjectPool.ActiveCount(self: ObjectPool<any>): number
	local count = 0
	for _ in self._active do
		count += 1
	end
	return count
end

--- Destroy the pool and all objects in it.
function ObjectPool.Destroy(self: ObjectPool<any>)
	for _, obj in self._pool do
		if typeof(obj) == "Instance" then
			(obj :: Instance):Destroy()
		end
	end
	for obj in self._active do
		if typeof(obj) == "Instance" then
			(obj :: Instance):Destroy()
		end
	end
	table.clear(self._pool)
	table.clear(self._active)
end

return ObjectPool
