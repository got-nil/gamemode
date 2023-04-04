
-- Set the alpha for a color (returns new, not inplace).
local function setColorAlpha(base, a)
    return Color(base.r, base.g, base.b, a)
end

-- When a prop is picked up change its color and collision group.
hook.Add("PhysgunPickup", "GNIL.Fixes.PropKillPickup", function(ply, ent)
    if ent:GetClass() != "prop_physics" then return end

    -- Previous entity color and material for restoring.
    ent.physPrevious = {
        color = ent:GetColor(),
        material = ent:GetMaterial()
    }

    ent:SetColor(setColorAlpha(ent.physPrevious.color, 150))
    ent:SetMaterial(ent.physPrevious.material)
    ent:SetRenderMode(RENDERMODE_TRANSALPHA)
    ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
end)

-- Freeze the prop, resetting color, render mode and collision group.
local function freezeProp(ent)
    local timer_name = "GNIL.PlayersLeave." .. ent:EntIndex()
    if timer.Exists(timer_name) then timer.Remove(timer_name) end

    ent:SetColor(ent.physPrevious.color)
    ent:SetMaterial(ent.physPrevious.material)
    ent:SetRenderMode(RENDERMODE_NORMAL)
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
end

-- Is a player inside the entity mins and max bounds.
local function isPlayerInEntBox(ent)
    for _, v in ipairs(ents.FindInBox(ent:LocalToWorld(ent:OBBMins()), ent:LocalToWorld(ent:OBBMaxs()))) do
        if v:IsPlayer() then
            return true
        end
    end
    return false
end

-- When the prop is frozen, check to see if anyones inside the
-- prop waiting until the area is clear if there are players.
hook.Add("OnPhysgunFreeze", "GNIL.Fixes.PropkillFreeze", function(_, __, ent, ply)
    if ent:GetClass() != "prop_physics" then return end
    
    if isPlayerInEntBox(ent) then
        timer.Create("GNIL.PlayersLeave." .. ent:EntIndex(), 1, 0, function()
            if isPlayerInEntBox(ent) then return end
            freezeProp(ent)
        end)
        return
    end
    freezeProp(ent)
end)