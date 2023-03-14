GNIL.Properties["_last_known"] = {}

local function isPositionInIndex(set, index, target)

    -- Check to see if the current segment is correct.
    if ((target > set[index]) && ((set[index] + GNIL.Properties["_map"]["width"]) > target)) then
        return true
    end
end

local function binarySearchSet(set, pos, is_row)
    local max = GNIL.Properties["_map"]["max"][is_row && "x" || "y"]
    local target = (is_row && pos.x || pos.y)
    local minIndex, maxIndex, mid = 1, #set, 0

    -- Keep searching until the index underflows.
    while minIndex <= maxIndex do
        mid = math.floor((maxIndex+minIndex) / 2)

        -- If the position is correct, return current mid.
        if isPositionInIndex(set, mid, target) then
            return mid
        end

        -- If its not, adjust the scale and try again.
        if target > set[mid] then
			minIndex = mid + 1
		else
			maxIndex = mid - 1
		end
    end

    -- Return the last mid, incase player is not in world space.
    return mid
end

function GNIL.Properties.GetCoordinates(pos, name)
    local rowset = GNIL.Properties["_map"]["sets"]["row"]
    local colset = GNIL.Properties["_map"]["sets"]["col"]

    -- If there is a name provided, and the name has a last known position
    -- we should check that position first before continuing with the normal
    -- search. This should be better for preformance when constantly polled.
    if name and GNIL.Properties["_last_known"][name] then
        local last = GNIL.Properties["_last_known"][name]

        -- If the position is still the same as last, return last.
        if isPositionInIndex(rowset, last.x, pos.x) and isPositionInIndex(colset, last.y, pos.y) then
            return last
        end
    end

    -- Find the players current coordinates.
    out = {
        x = binarySearchSet(rowset, pos, true),
        y = binarySearchSet(colset, pos, false)
    }

    -- If there is an associated name, store it with the collected output.
    if name then
        GNIL.Properties["_last_known"][name] = out
    end
    return out
end

-- These functions cache the players last known location, using that to check
-- before continuing with the search (more efficient for constant checks). This
-- should ALWAYS be used instead of feeding GetCoordinates with the player pos.
if CLIENT then
    function GNIL.Properties.GetMyCoordinates()
        return GNIL.Properties.GetCoordinates(LocalPlayer():GetPos(), "me")
    end
else
    function GNIL.Properties.GetPlayerCoordinates(ply)
        return GNIL.Properties.GetCoordinates(ply:GetPos(), ply:SteamID64())
    end
end