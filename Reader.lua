-- Not using slow metatables here because we need it fast
local FLOAT_PRECISION = 24

local Reader = {}

function Reader.new(bytecode)
	local pos = 1
	--
	local self = {}

	function self:len()
		return string.len(bytecode)
	end

	function self:nextByte(peek, customPos)
		local use = customPos and customPos or pos
		local result = string.byte(bytecode, use, use)
		if not peek then
			pos += 1
		end
		return result
	end
	function self:nextBytes(count)
		local result = {}
		for i = 1, count do
			table.insert(result, self:nextByte())
		end
		return result
	end

	function self:nextChar()
		local result = string.char(self:nextByte())
		return result
	end

	function self:nextUInt32()
		local a, b, c, d = self:nextByte(), self:nextByte(), self:nextByte(), self:nextByte()
		local result = bit32.lshift(d, 24) + bit32.lshift(c, 16) + bit32.lshift(b, 8) + a
		return result
	end
	function self:nextInt32(peek)
		if peek then
			local a, b, c, d = self:nextByte(true, pos), self:nextByte(true, pos+1), self:nextByte(true, pos+2), self:nextByte(true, pos+3)
			local result = bit32.lshift(bit32.band(d, 0xFF), 24) + bit32.lshift(bit32.band(c, 0xFF), 16) + bit32.lshift(bit32.band(b, 0xFF), 8) + bit32.band(a, 0xFF)
			return result
		else
			local a, b, c, d = self:nextByte(), self:nextByte(), self:nextByte(), self:nextByte()
			local result = bit32.lshift(bit32.band(d, 0xFF), 24) + bit32.lshift(bit32.band(c, 0xFF), 16) + bit32.lshift(bit32.band(b, 0xFF), 8) + bit32.band(a, 0xFF)
			return result
		end
	end

	function self:nextFloat()
		local a, b, c, d = self:nextChar(), self:nextChar(), self:nextChar(), self:nextChar()
		local result = tonumber(string.format(`%0.{FLOAT_PRECISION}f`, string.unpack("f", a .. b .. c .. d)))
		return result
	end

	function self:nextVarInt()
		local result, shift = 0, 0
		local b
		repeat
			b = self:nextByte()
			result = bit32.bor(result, bit32.lshift(bit32.band(b, 0x7F), shift))
			shift += 7
		until not bit32.btest(b, 0x80)
		return result
	end

	function self:nextString(len)
		len = len or self:nextVarInt()
		local result = ""
		for i = 1, len do
			result ..= self:nextChar()
		end
		return result
	end

	function self:nextDouble()
		local str = ""
		for i = 1, 8 do
			str ..= string.char(self:nextByte())
		end
		local result = string.unpack("<d", str)
		return result
	end

	return self
end

function Reader:Set(...)
	FLOAT_PRECISION = ...
end

return Reader
