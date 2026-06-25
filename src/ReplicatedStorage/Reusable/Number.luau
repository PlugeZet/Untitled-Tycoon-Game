local Number = {}

function Number.add(number, amount)
    number.Value += amount
end

function Number.subtract(number, amount)
    number.Value -= amount
end

function Number.multiply(number, amount)
    number.Value *= amount
end

function Number.divide(number, amount)
    number.Value /= amount
end

function Number.formatNumber(number)
	local formatted = tostring(number)
	while true do  
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
		if k == 0 then break end
	end
	return "$ " .. formatted
end

return Number