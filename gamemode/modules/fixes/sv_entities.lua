local MODULE = MODULE
if not MODULE:Config():Get("Modules", {Entities = false}).Entities then return end

GNIL.Fixes = GNIL.Fixes or {
    ["setup"] = false,
    ["_entities"] = {}
}

-- Load the config from its seqential form into individual
-- tables for each enum (for quick searching).
function GNIL.Fixes.FromConfig()
    local out = {}
    for i = 1, GNIL_FIXES_ENT_COUNT do
        out[i] = {}
    end
  
    for classname, enums in pairs(MODULE:Config():Get("Entities", {})) do
        for _, enum in ipairs(istable(enums) && enums || {enums}) do
            out[enum][classname] = true         
        end
    end
    return out
end

-- Setup the actual check hooks. This should only be loaded
-- once the config file has been parsed.
local function setupHooks()
    MODULE:AddHook("OnEntityCreated", "bannedEntities", function(ent)
        if not IsValid(ent) then return end 
        local class = ent:GetClass()

        -- If the entity is banned remove it, if it should
        -- be nocolided then set the CustomCollisionCheck.
        if GNIL.Fixes["_entities"][GNIL_FIXES_ENT_BANNED][class] then return ent:Remove() end
        if GNIL.Fixes["_entities"][GNIL_FIXES_ENT_NOCOLIDE][class] then return ent:SetCustomCollisionCheck(true) end
    end)
    MODULE:AddHook("PlayerShouldTakeDamage", "antiDamage", function(ply, ent)
        if IsValid(ent) and GNIL.Fixes["_entities"][GNIL_FIXES_ENT_NODAMAGE][ent:GetClass()] or ent:IsVehicle() then
            return false
        end
    end)
    MODULE:AddHook("ShouldCollide", "antiCollision", function(ent1, ent2) 
        if ((IsValid(ent1) and IsValid(ent2)) and (GNIL.Fixes["_entities"][GNIL_FIXES_ENT_NOCOLIDE][ent1:GetClass()] and GNIL.Fixes["_entities"][GNIL_FIXES_ENT_NOCOLIDE][ent2:GetClass()])) then
            return false
        end
    end)
    MODULE:AddHook("PhysgunPickup", "antiPhysgun", function(_, ent)
        if IsValid(ent) and GNIL.Fixes["_entities"][GNIL_FIXES_ENT_NOPICKUP][ent:GetClass()] then
            return false
        end
    end)
end

-- Load the config if not already setup.
if not GNIL.Fixes["setup"] then
    GNIL.Fixes["setup"] = true
    GNIL.Fixes["_entities"] = GNIL.Fixes.FromConfig()

    -- Once config has been loaded, setup the check hooks.
    MODULE:log("Loaded config, setting up check hooks.", "debug")
    setupHooks()
end