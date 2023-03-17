GNIL.AntiSkid["_whitelist_cache"] = GNIL.AntiSkid["_whitelist_cache"] or {}

local Whitelist = GNIL.Thirdparty.middleclass("SkidWhitelist")
function Whitelist:Initialize(parent_check)
    self.parent_check = parent_check
end

-- Read the check whitelist, Will use cache past first read/write.
function Whitelist:Read()

    -- Use cache if it exists
    if GNIL.AntiSkid["_whitelist_cache"][self.parent_check.name] then
        return GNIL.AntiSkid["_whitelist_cache"][self.parent_check.name]
    end

    -- Validate existance
    local path = "gnil/antiskid/whitelists/" .. self.parent_check.name .. ".txt"
    if not file.Exists(path, "DATA") then
        return nil
    end

    -- Read + cache (ensure its assoc).
    local out = util.JSONToTable(file.Read(path, "DATA"))
    if table.IsSequential(out) then
        local assoc_out = {}
        for _, v in ipairs(out) do
            assoc_out[v] = true
        end
        out = assoc_out
    end
    if out then
        GNIL.AntiSkid["_whitelist_cache"][self.parent_check.name] = out
    end
    return out
end

-- Write a new whitelist for the parent check + cache. 
function Whitelist:Write(data)
    GNIL.AntiSkid["_whitelist_cache"][self.parent_check.name] = data
    file.Write("gnil/antiskid/whitelists/" .. self.parent_check.name .. ".txt", util.TableToJSON(data))
end

-- Is a user data set accepted by the whitelist? This will find commands
-- that are in the user set, but not the stored whitelist for detecting
-- cheater modified tables. WOOOOOO!!!!! YYEEAEEAAAHH!!!!
function Whitelist:IsAccepted(udata)
    assert(not table.IsSequential(udata), "The Whitelist input User Data must be a sequential list of strings.")

    local wdata = self:Read()
    if not wdata then
        return false
    end
    for _, v in ipairs(udata) do
        if not wdata[v] then
            return false, v
        end
    end
    return true, nil
end

GNIL.Utils.CreateDataPath("gnil/antiskid/whitelists")
GNIL.AntiSkid.Whitelist = Whitelist