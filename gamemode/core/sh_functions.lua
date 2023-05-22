
function IsPlayer(ply)
    return IsValid(ply) && IsEntity(ply) && ply:IsPlayer()
end

function IsClass(obj, name)
    if not obj or not obj.name then return false end
    return obj.name == name
end
