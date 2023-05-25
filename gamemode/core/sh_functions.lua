
function IsPlayer(ply)
    return IsValid(ply) && IsEntity(ply) && ply:IsPlayer()
end

function IsClass(obj, name)
    if not obj or not obj.class or not obj.class.name then return false end
    return obj.class.name == name
end
